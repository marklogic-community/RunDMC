xquery version "1.0-ml";

import module namespace raw = "http://marklogic.com/rundmc/raw-docs-access"
       at "raw-docs-access.xqy";

import module namespace api = "http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

for $guide in $raw:guide-docs
order by base-uri($guide) (: order doesn't matter but it helps when assessing progress from the logs :)
return
(
  xdmp:log(concat("Converting ",base-uri($guide))),

  let $converted := xdmp:xslt-invoke("convert-guide.xsl",$guide)
  return xdmp:document-insert(base-uri($converted), $converted),

  xdmp:log("Done.")
)

, "Done converting guides."
