xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";

import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

(: Make sure the version param was specified :)
$stp:errorCheck,

xdmp:log(concat("Deleting all set-up ",$api:version," docs")),

(: Wipe out the entire version directory :)
xdmp:directory-delete($api:VERSION-DIR),
xdmp:log(text { "Done deleting:", $api:VERSION-DIR }),

concat("Finished deleting all set-up ",$api:version," docs")

(: delete-docs.xqy :)