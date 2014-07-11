xquery version "1.0-ml";

import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

declare variable $ZIP as xs:string external ;

declare variable $VERSION as xs:string external ;

stp:zip-load-raw-docs($VERSION, xdmp:document-get($ZIP)/node())

(: load-raw-docs.xqy :)