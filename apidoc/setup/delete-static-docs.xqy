xquery version "1.0-ml";

import module namespace api = "http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

import module namespace raw = "http://marklogic.com/rundmc/raw-docs-access"
       at "raw-docs-access.xqy";

import module namespace setup = "http://marklogic.com/rundmc/api/setup"
       at "common.xqy";

import module namespace u="http://marklogic.com/rundmc/util"
       at "../../lib/util-2.xqy";

declare variable $config            := u:get-doc("/apidoc/config/static-docs.xml")/static-docs;
declare variable $subdirs-to-delete := $config/include/string(.);

(: Make sure the version param was specified :)
$setup:errorCheck,

xdmp:log(concat("Deleting all ",$api:version," static docs")),

let $base-dir := concat('/pubs/',$api:version,'/')
for $dir in $subdirs-to-delete
let $fulldir := concat($base-dir, $dir, '/')
return
(
  (: Wipe out each sub-directory of the pubs version directory :)
  xdmp:directory-delete($fulldir),
  xdmp:log(concat("Done deleting (if was present): ", $fulldir))
),

concat("Finished deleting all ",$api:version," static docs")
