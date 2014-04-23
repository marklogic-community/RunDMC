xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
  at "../model/data-access.xqy";
import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "raw-docs-access.xqy";

import module namespace tb="ns://blakeley.com/taskbot"
  at "/taskbot/src/taskbot.xqm";

(: Set the version outside the task server, before we spawn.
 : Otherwise the api library code will not see the request field.
 : However the xslt-invoke still falls back on the default version!
 :)
let $version := $api:version
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
    (: Ensure code running on the Task Server sees the right version.
     : However this does not affect the invoked stylesheet,
     : so it does little good.
     :)
    xdmp:set($api:version-specified, $version),
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
  $tb:OPTIONS-UPDATE,
  (: Because the task server cannot see http request fields,
   : spawn only works properly if we are building the default version.
   : So if we are building a non-default version, we drop concurrency.
   :)
  if ($api:default-version eq $api:version-specified) then 'spawn'
  else 'invoke',
  'caller-runs', ())
let $_ := (
  if ($api:default-version eq $api:version-specified) then tb:tasks-wait(0)
  else ())
return text {
  'Converted', count($raw:GUIDE-DOCS), 'guides',
  'in', xdmp:elapsed-time() }

(: convert-guides.xqy :)