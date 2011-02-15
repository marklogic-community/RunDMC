(: This script creates a preview of document edits, whether new or existing, published or draft.

   It creates an XML document annotated as a preview-only document, so it's not discoverable
   in the public site or Admin UI. The XML document is meant to be temporary; some other process
   will need to delete these periodically.
:)
import module namespace param="http://marklogic.com/rundmc/params"
       at "../../controller/modules/params.xqy";

(: Import the definition of $srv:draft-server :)
import module namespace srv="http://marklogic.com/rundmc/server-urls"
       at "../../controller/server-urls.xqy";

let $params  := param:params()
let $map     := map:map()

(: Where we'll store the temporary XML document. :)
let $doc-url := concat('/preview/', current-dateTime(), '.xml')

let $external-uri := concat($srv:draft-server, substring-before($doc-url, '.xml'))

return
(
  (: Construct the XML based on the submitted parameters :)
  let $new-doc := xdmp:xslt-invoke("../model/form2xml.xsl", document{ <empty/> }, (map:put($map,"params",$params),$map))
  let $map := map:map()

    return
    (
      (: Insert the document, after marking it as "preview-only" :)
      xdmp:document-insert($doc-url, xdmp:xslt-invoke("../model/set-doc-attribute.xsl", $new-doc, (map:put($map, "att-name", "preview-only"),
                                                                                                   map:put($map, "att-value", "yes"),
                                                                                                   $map))),

      (: Render the document on the draft server, utilizing contextual navigation rendering if possible (i.e. if it's an edit to an existing document) :)
      xdmp:redirect-response(concat($external-uri, "?preview-as-if-at=", substring-before($params[@name eq "~existing_doc_uri"], '.xml')))
    )
)
