xquery version "1.0-ml";

import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

declare variable $VERSION as xs:string external ;

stp:clean($VERSION)

(: apidoc/setup/clean.xqy :)

