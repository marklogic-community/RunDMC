xquery version "1.0-ml";

import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

$stp:errorCheck,
stp:static-docs-insert(
  concat(
    xdmp:get-request-field("srcdir")))

(: load-static-docs.xqy :)