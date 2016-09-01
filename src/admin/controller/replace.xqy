(: This script replaces an existing document with a newly edited one,
   submitted from the Edit page for the original document.
:)
import module namespace param="http://marklogic.com/rundmc/params"
       at "../../controller/modules/params.xqy";

import module namespace ml="http://developer.marklogic.com/site/internal"
       at "../../model/data-access.xqy";

import module namespace admin-ops = "http://marklogic.com/rundmc/admin-ops"
       at "modules/admin-ops.xqy";

let $params  := param:params()
let $map     := map:map()

return
(
  (: Create the new XML from the POST parameters :)
  let $new-doc := xdmp:xslt-invoke("../model/form2xml.xsl", document{ <empty/> }, (map:put($map, "params", $params),$map))

  let $existing-doc-path := $params[@name eq '~existing_doc_uri']
  return
    if (normalize-space($existing-doc-path) and doc-available($existing-doc-path))
    then
      (
        (: Replace the existing document :)
        admin-ops:document-insert($existing-doc-path, $new-doc),

        ml:reset-category-tags($existing-doc-path, $new-doc),

        (: Invalidate the navigation cache :)
        ml:invalidate-cached-navigation(),

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
