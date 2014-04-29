xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";
import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "raw-docs-access.xqy";
import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

(: Make sure the version param was specified :)
$stp:errorCheck,

stp:raw-delete($api:version),

text { "Finished deleting all raw docs for", $api:version }

(: delete-raw-docs.xqy :)