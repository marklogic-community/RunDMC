xquery version "1.0-ml";

(: This script handles the creation of new On Demand documents from the Admin
 : UI. This includes running xdmp:document-filter on an uploaded PowerPoint
 : file.

 : NOTE: the URL rewriter ensures that, if we get this far, that means
 : there won't be any conflict with storing the new document at the
 : given URI.
 :)
import module namespace param = "http://marklogic.com/rundmc/params"
  at "../../controller/modules/params.xqy";

import module namespace ml = "http://developer.marklogic.com/site/internal"
  at "../../model/data-access.xqy";

import module namespace admin-ops = "http://marklogic.com/rundmc/admin-ops"
 at "modules/admin-ops.xqy";

declare namespace html = "http://www.w3.org/1999/xhtml";

let $params      := param:params()
let $new-doc-url := $params[@name eq '~uri_prefix'] || $params[@name eq '~new_doc_slug'] || '.xml'
let $map         := map:map()
let $tags := $params[fn:matches(@name, "tag")]/fn:string()
let $name := $params[@name eq "name"]/fn:string()
let $url := $params[@name eq "url"]/fn:string()
let $ppt := xdmp:get-request-field("upload")
let $filtered := xdmp:document-filter($ppt)
let $body := $filtered/html:html/html:body
(: Create the XML from the given POST parameters :)
let $new-doc :=
  document {
    <ml:OnDemand status="Draft" url="{$url}">
      <ml:name>{$name}</ml:name>
      <ml:created>{fn:current-dateTime()}</ml:created>
      <ml:last-updated>{fn:current-dateTime()}</ml:last-updated>
      <ml:url>{$url}</ml:url>
      <ml:tags>
        {
          for $tag in $tags
          return
            <ml:tag>{$tag}</ml:tag>
        }
      </ml:tags>
      <ml:body>{$body/*}</ml:body>
    </ml:OnDemand>
  }
let $collections := fn:string-join(ml:category-for-doc(
    $new-doc-url, $new-doc) ! concat($ml:CATEGORY-PREFIX, .), "; ")
return
(
  (: Insert the new document :)
  admin-ops:document-insert($new-doc-url, $new-doc, $collections),

  (: Invalidate the navigation cache :)
  ml:invalidate-cached-navigation(),

  (: Redirect to the Edit page for the newly created document :)
  xdmp:redirect-response(concat($params[@name eq '~edit_form_url'],
                                "?~doc_path=", $new-doc-url,

                                (: Include a timestamp showing when
                                   the document was last saved :)
                                "&amp;~updated=", current-dateTime())
                        )
)
