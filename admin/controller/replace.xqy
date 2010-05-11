(: This query replaces an existing document with a newly edited one,
   submitted from the Edit page for the original document.
:)
import module namespace param="http://marklogic.com/rundmc/params"
       at "../../controller/modules/params.xqy";

let $params  := param:params()
let $map     := map:map()

return
(
  (: Create the new XML from the POST parameters :)
  let $new-doc := xdmp:xslt-invoke("edit-doc.xsl", document{ <empty/> }, (map:put($map, "params", $params),$map))

  let $existing-doc-path := $params[@name eq '~existing_doc_uri']
  return
    if (normalize-space($existing-doc-path) and doc-available($existing-doc-path))
    then (
           (: Replace the existing document :)
           xdmp:document-insert($existing-doc-path, $new-doc),

           (: Redirect right back to the Edit page for the newly replaced document :)
           xdmp:redirect-response(concat($params[@name eq '~edit_form_url'],
                                         "?~doc_path=",
                                         $existing-doc-path,
                                         "&amp;~updated=",
                                         current-dateTime())
                                 )
         )
    else error((),"You're trying to overwrite a document that doesn't exist...")
)
