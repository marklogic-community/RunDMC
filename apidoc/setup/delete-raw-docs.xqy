xquery version "1.0-ml";

import module namespace api = "http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

import module namespace raw = "http://marklogic.com/rundmc/raw-docs-access"
       at "raw-docs-access.xqy";

import module namespace setup = "http://marklogic.com/rundmc/api/setup"
       at "common.xqy";

(: Make sure the version param was specified :)
$setup:errorCheck,

xdmp:log(concat("Deleting all ",$api:version," raw docs")),

let $dir := concat("/",$api:version,"/")
let $delete-query := concat("xdmp:directory-delete('", $dir, "')") return
(
  xdmp:log(concat("Running query in ", $raw:db-name, ": ", $delete-query)),
  (: Wipe out the entire version directory :)
  xdmp:eval($delete-query, (), <options xmlns="xdmp:eval">
                                 <database>{xdmp:database($raw:db-name)}</database>
                               </options>),
  xdmp:log(concat("Done deleting: ", $dir))
),

concat("Finished deleting all ",$api:version," raw docs")
