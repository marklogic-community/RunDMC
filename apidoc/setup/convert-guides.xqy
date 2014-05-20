xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy" ;
import module namespace guide="http://marklogic.com/rundmc/api/guide"
  at "guide.xqm" ;
import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "raw-docs-access.xqy" ;

let $raw := raw:guide-docs($api:version)
let $_ := guide:render($raw)
return text {
  'Converted', count($raw), 'guides', 'in', xdmp:elapsed-time() }

(: convert-guides.xqy :)