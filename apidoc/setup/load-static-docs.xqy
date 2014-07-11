xquery version "1.0-ml";

import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

declare variable $ZIP as xs:string external ;
declare variable $VERSION as xs:string external ;

stp:zip-static-docs-insert($VERSION, $ZIP)

(: load-static-docs.xqy :)