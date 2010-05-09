import module namespace param="http://marklogic.com/rundmc/params"
       at "../controller/modules/params.xqy";

let $params      := param:params()
let $new-doc-url := $params[@name eq '~new_doc_url']
let $map         := map:map()
let $new-doc     := xdmp:xslt-invoke("edit-doc.xsl",
                                     document{ <empty/> },
                                     (map:put($map, "params", $params),$map)
                                    )
return
(
  xdmp:document-insert($new-doc-url, $new-doc),

  xdmp:redirect-response(concat($params[@name eq '~edit_form_url'],
                                "?~doc_path=",
                                $new-doc-url,
                                "&amp;~updated=",
                                current-dateTime())
                        )
)
