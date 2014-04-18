xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
  at "../model/data-access.xqy";

import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "raw-docs-access.xqy";

import module namespace setup="http://marklogic.com/rundmc/api/setup"
  at "common.xqy";

(: Make sure the version param was specified :)
$setup:errorCheck,

xdmp:log(text { "Deleting all", $api:version, "raw docs" }),
raw:invoke-function(
  function() {
    xdmp:directory-delete(concat("/", $api:version, "/")),
    xdmp:commit() },
  true()),
concat("Finished deleting all ",$api:version," raw docs")

(: delete-raw-docs.xqy :)