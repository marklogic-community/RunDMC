xquery version "1.0-ml";

import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

$stp:errorCheck,
stp:zip-static-docs-insert(
  xdmp:get-request-field("zip"))

(: load-static-docs.xqy :)