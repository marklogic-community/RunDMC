xquery version "1.0-ml";

import module namespace raw = "http://marklogic.com/rundmc/raw-docs-access"
       at "raw-docs-access.xqy";

import module namespace api = "http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

declare variable $converted-guides := 
  for $guide in $raw:guide-docs return (xdmp:log(concat("Converting ",base-uri($guide))),
                                        xdmp:xslt-invoke("convert-guide.xsl",$guide),
                                        xdmp:log("Done."));

$converted-guides/xdmp:document-insert(base-uri(.), .),
"Done converting guides."
