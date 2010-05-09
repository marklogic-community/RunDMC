import module namespace param="http://marklogic.com/rundmc/params"
       at "../controller/modules/params.xqy";

let $params  := param:params()
let $doc-url := $params[@name eq 'path']/string(.)
let $map     := map:map()

return
(
  map:put($map, "params", $params),
  let $new-doc := xdmp:xslt-invoke("edit-doc.xsl", document{ <empty/> }, $map)
  let $existing-doc-path := $params[@name eq '~existing_doc_uri']
  return
    if (normalize-space($existing-doc-path) and doc-available($existing-doc-path))
    then ( xdmp:document-insert($existing-doc-path, $new-doc),
           xdmp:redirect-response(concat($params[@name eq '~edit_form_url'],
                                         "&amp;~updated=yes")
                                 )
         )
    else error((),"I haven't handled this scenario yet...")
)
