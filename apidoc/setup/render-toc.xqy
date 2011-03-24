xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

declare variable $toc-url     as xs:string external;
declare variable $toc-xml-url as xs:string external;

"Resetting the TOC URL (to invalidate browser caches)",
xdmp:document-insert(
  $api:toc-url-location,
  document { <api:toc-url>{$toc-url}</api:toc-url>}
),

"Generating HTML TOC...",
xdmp:document-insert($toc-url,
                     xdmp:xslt-invoke("render-toc.xsl", doc($toc-xml-url)))
