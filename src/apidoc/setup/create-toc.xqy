xquery version "1.0-ml";

(: Create the new XML TOC :)

import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm" ;
import module namespace toc="http://marklogic.com/rundmc/api/toc"
  at "toc.xqm" ;

declare variable $VERSION as xs:string external ;

declare variable $HELP-XSD-DIR as xs:string external ;

toc:toc($VERSION, $HELP-XSD-DIR)

(: create-toc.xqy :)