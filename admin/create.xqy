import module namespace param="http://marklogic.com/rundmc/params"
       at "../controller/modules/params.xqy";

let $params      := param:params()
let $new-doc-url := concat($params[@name eq '~uri_prefix'],
                           $params[@name eq '~new_doc_slug'],
                           '.xml')
let $map         := map:map()

return
(
    map:put($map, "params", $params),
    let $new-doc := xdmp:xslt-invoke("edit-doc.xsl", document{ <empty/> }, $map)
    return
    (
      if (doc-available($new-doc-url))
      then error((), concat("There is already a document at this location:! - ", $new-doc-url, ". Go back and pick a different path."))
      else ( xdmp:document-insert($new-doc-url, $new-doc),
             xdmp:redirect-response(concat($params[@name eq '~edit_form_url'],
                                           "?~doc_path=",
                                           $new-doc-url,
                                           "&amp;~updated=",
                                           current-dateTime())
                                   )
           )
    )
)
