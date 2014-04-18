xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
  at "../model/data-access.xqy";
import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "raw-docs-access.xqy";

import module namespace tb="ns://blakeley.com/taskbot"
  at "/taskbot/src/taskbot.xqm";

let $_ := tb:list-segment-process(
  (: The slowest conversion is messages/XDMP-en.xml,
   : which always finishes last.
   : So ensure that it starts first.
   :)
  for $g in $raw:GUIDE-DOCS
  order by ends-with(xdmp:node-uri($g), '/XDMP-en.xml') descending
  return $g,
  1,
  'convert-guides',
  function(
    $list as item()+,
    $options as map:map?)
  as item()*
  {
    tb:maybe-fatal(),
    for $guide in $list
    let $start := xdmp:elapsed-time()
    let $converted := xdmp:xslt-invoke("convert-guide.xsl", $guide)
    let $uri := base-uri($converted)
    let $_ := xdmp:document-insert($uri, $converted)
    let $_ := tb:debug(
      "convert-guides", (base-uri($guide), '=>', $uri,
        'in', xdmp:elapsed-time() - $start))
    return $uri
    ,
    xdmp:commit() },
    (),
    $tb:OPTIONS-UPDATE)
let $_ := tb:tasks-wait(0)
return text {
  'Converted', count($raw:GUIDE-DOCS), 'guides',
  'in', xdmp:elapsed-time() }

(: convert-guides.xqy :)