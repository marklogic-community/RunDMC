xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";
import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

declare variable $VERSION as xs:string external ;

declare variable $VERSION-DIR := api:version-dir($VERSION) ;

(: Wipe out the entire version directory :)
xdmp:directory-delete($VERSION-DIR)

(: delete-docs.xqy :)