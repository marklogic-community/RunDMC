xquery version "1.0-ml";

import module namespace api = "http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

import module namespace setup = "http://marklogic.com/rundmc/api/setup"
       at "common.xqy";

(: Make sure the version param was specified :)
$setup:errorCheck,

xdmp:log(concat("Deleting all ",$api:version," docs")),

(: Wipe out the entire version directory :)
xdmp:directory-delete(concat('/apidoc/',$api:version,'/')),

xdmp:log("Done deleting."),

concat("Finished deleting all ",$api:version," docs")
