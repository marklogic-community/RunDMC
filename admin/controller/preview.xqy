(: This query creates a preview of document edits, whether new or existing, published or draft.

   It creates an XML document annotated as a preview-only document, so it's not discoverable
   in the public site or Admin UI. The XML document is meant to be temporary; some other process
   will need to delete these periodically.
:)
import module namespace param="http://marklogic.com/rundmc/params"
       at "../../controller/modules/params.xqy";

let $params  := param:params()
let $map     := map:map()

(: Where we'll store the temporary XML document. :)
let $doc-url := concat('/preview/', current-dateTime(), '.xml')

(: Consult the config file for the staging server URL :)
let $config  := xdmp:document-get(concat(xdmp:modules-root(),'/admin/config/navigation.xml'))
let $external-uri := concat($config/*/@staging-server, substring-before($doc-url, '.xml'))

return
(
  (: Construct the XML based on the submitted parameters :)
  let $new-doc := xdmp:xslt-invoke("../model/construct-xml.xsl", document{ <empty/> }, (map:put($map,"params",$params),$map))
  let $map := map:map()

    return
    (
      (: Insert the document, after marking it as "preview-only" :)
      xdmp:document-insert($doc-url, xdmp:xslt-invoke("../model/set-doc-attribute.xsl", $new-doc, (map:put($map, "att-name", "preview-only"),
                                                                                                   map:put($map, "att-value", "yes"),
                                                                                                   $map))),

      (: Render the document on the staging server, utilizing contextual navigation rendering if possible (i.e. if it's an edit to an existing document) :)
      xdmp:redirect-response(concat($external-uri, "?preview-as-if-at=", substring-before($params[@name eq "~existing_doc_uri"], '.xml')))
    )
)
