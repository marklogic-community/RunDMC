xquery version "1.0-ml";

(: This script handles the creation of new On Demand documents through the
 : RunDMC Admin UI. This includes running xdmp:document-filter on an uploaded
 : PowerPoint file.
 :
 : This script handles both new-document creation and updates of existing
 : documents.
 :)
import module namespace param = "http://marklogic.com/rundmc/params"
  at "../../controller/modules/params.xqy";

import module namespace ml = "http://developer.marklogic.com/site/internal"
  at "../../model/data-access.xqy";

import module namespace admin-ops = "http://marklogic.com/rundmc/admin-ops"
 at "modules/admin-ops.xqy";

declare namespace html = "http://www.w3.org/1999/xhtml";

let $params := param:params()
let $doc-uri as xs:string :=
  if ($params[@name eq '~existing_doc_uri']) then
    $params[@name eq '~existing_doc_uri']
  else
    $params[@name eq '~uri_prefix'] || $params[@name eq '~new_doc_slug'] || '.xml'
let $url as xs:string := $params[@name eq "url"]/fn:string()
let $ppt := xdmp:get-request-field("upload")
(: The user is not required to upload a Power Point with every edit. If one
 : is uploaded, filter it. If one is not uploaded, try to retrieve it from the
 : existing document (assuming that we are doing an edit).
 : It is acceptible to not include a Power Point when initially creating an
 : OnDemand document -- the user may be creating a placeholder and will add a
 : PowerPoint later.
 :)
let $filtered := if ($ppt) then xdmp:document-filter($ppt) else ()
let $body :=
  if (fn:exists($filtered)) then
    $filtered/html:html/html:body/*
  else if (fn:doc-available($doc-uri)) then
    fn:doc($doc-uri)/ml:OnDemand/ml:body/*
  else ()
let $created as xs:dateTime :=
  if (fn:doc-available($doc-uri)) then
    fn:doc($doc-uri)/ml:OnDemand/ml:created
  else
    fn:current-dateTime()
let $new-doc :=
  document {
    <ml:OnDemand status="{$params[fn:matches(@name, "status")]}" url="{$url}">
      <ml:name>{$params[@name eq "name"]/fn:string()}</ml:name>
      <ml:created>{$created}</ml:created>
      <ml:last-updated>{fn:current-dateTime()}</ml:last-updated>
      <ml:url>{$url}</ml:url>
      <ml:tags>
        {
          for $tag in $params[fn:matches(@name, "tag")]/fn:string()
          return
            <ml:tag>{$tag}</ml:tag>
        }
      </ml:tags>
      <ml:body>{$body}</ml:body>
    </ml:OnDemand>
  }
let $collections as xs:string* :=
  ml:category-for-doc($doc-uri, $new-doc) ! concat($ml:CATEGORY-PREFIX, .)
return
(:
  xdmp:log('ondemand.xqy: ' || xdmp:quote($new-doc))
:)
(
  (: Insert the new document :)
  admin-ops:document-insert($doc-uri, $new-doc, $collections),

  (: Invalidate the navigation cache :)
  ml:invalidate-cached-navigation(),

  (: Redirect to the Edit page for the newly created document :)
  xdmp:redirect-response(concat($params[@name eq '~edit_form_url'],
                                "?~doc_path=", $doc-uri,

                                (: Include a timestamp showing when
                                   the document was last saved :)
                                "&amp;~updated=", current-dateTime())
                        )
)
