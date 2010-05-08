import module namespace param="http://marklogic.com/rundmc/params"
       at "../controller/modules/params.xqy";

let $params  := param:params()
let $doc-url := $params[@name eq 'path']/string(.)

return
(
  let $new-doc := xdmp:xslt-invoke("edit-doc.xsl", document{ <empty/> },
                    map:map(
                      <map:map xmlns:map="http://marklogic.com/xdmp/map">
                        <map:entry>
                          <map:key>params</map:key>
                          <map:value>{ $params }</map:value>
                        </map:entry>
                      </map:map>
                    )
                  )
  return
    $new-doc
)
