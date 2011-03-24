xquery version "1.0-ml";

(: New transactions to get TOC based on the newly updated DB content :)
  (: Delete the old TOC :)

  xdmp:directory-delete("/media/apiTOC/") (: delete the old TOC doc, whatever it's named :)

; (: Create the new TOC :)

"Generating XML TOC...",
xdmp:document-insert("/media/apiTOC/toc.xml",
                     xdmp:xslt-invoke("toc.xsl", document{ <empty/> }))

; (: New transaction since this depends on toc.xml which we just created :)

import module namespace api="http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

declare variable $toc-url := fn:concat("/media/apiTOC/apiTOC_", fn:current-dateTime(), ".html");

"Resetting the TOC URL (to invalidate browser caches)",
xdmp:document-insert(
  $api:toc-url-location,
  document { <api:toc-url>{$toc-url}</api:toc-url>}
),

"Generating HTML TOC...",
xdmp:document-insert($toc-url,
                     xdmp:xslt-invoke("render-toc.xsl", doc("/media/apiTOC/toc.xml")))
