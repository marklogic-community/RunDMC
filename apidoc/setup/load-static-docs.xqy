xquery version "1.0-ml";

import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

declare variable $ZIP as xs:string := xdmp:get-request-field("zip") ;
(: e.g., 4.1 :)
declare variable $VERSION as xs:string := xdmp:get-request-field("version") ;

$stp:errorCheck,
stp:zip-static-docs-insert($VERSION, $ZIP)

(: load-static-docs.xqy :)