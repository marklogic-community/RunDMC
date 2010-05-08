import module namespace param="http://marklogic.com/rundmc/params"
       at "../controller/modules/params.xqy";
import module namespace mem = "http://xqdev.com/in-mem-update"
       at "/MarkLogic/appservices/utils/in-mem-update.xqy";

let $params  := param:params()
let $doc-url := concat('/preview/', current-dateTime(), '.xml')
let $config  := xdmp:document-get(concat(xdmp:modules-root(),'/config/admin/navigation.xml'))
let $external-uri := concat($config/*/@staging-server, substring-before($doc-url, '.xml'))
let $map     := map:map()

return
(
  map:put($map, "params", $params),
  let $new-doc := xdmp:xslt-invoke("edit-doc.xsl", document{ <empty/> }, $map)
  let $map := map:map()

    return
    (
      map:put($map, "att-name", "preview-only"),
      map:put($map, "att-value", "yes"),

      xdmp:document-insert($doc-url, xdmp:xslt-invoke("set-doc-attribute.xsl", $new-doc, $map)),

      xdmp:redirect-response(concat($external-uri, "?preview-as-if-at=", substring-before($params[@name eq "~existing_doc_uri"], '.xml')))
    )
)
