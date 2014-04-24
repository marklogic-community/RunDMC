xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";
import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "raw-docs-access.xqy";

(: The slowest conversion is messages/XDMP-en.xml,
 : which always finishes last.
 :)
for $g in $raw:GUIDE-DOCS
let $start := xdmp:elapsed-time()
let $converted := xdmp:xslt-invoke("convert-guide.xsl", $g)
let $uri := base-uri($converted)
let $_ := xdmp:document-insert($uri, $converted)
let $_ := xdmp:log(
  text {
    "convert-guides", (base-uri($g), '=>', $uri,
      'in', xdmp:elapsed-time() - $start) }, 'debug')
return $uri
,

text {
  'Converted', count($raw:GUIDE-DOCS), 'guides',
  'in', xdmp:elapsed-time() }

(: convert-guides.xqy :)