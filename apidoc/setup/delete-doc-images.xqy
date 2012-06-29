xquery version "1.0-ml";

import module namespace api = "http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

import module namespace setup = "http://marklogic.com/rundmc/api/setup"
       at "common.xqy";

(: Make sure the version param was specified :)
$setup:errorCheck,

xdmp:log(concat("Deleting all images for ",$api:version," docs")),

let $dir := concat('/media/apidoc/',$api:version,'/') return
(
  (: Wipe out the entire version directory :)
  xdmp:directory-delete($dir),
  xdmp:log(concat("Done deleting: ", $dir))
),

concat("Finished deleting all images for ",$api:version," docs")
