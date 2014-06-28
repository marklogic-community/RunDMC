xquery version "1.0-ml";

(: Create the new XML TOC :)

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy" ;
import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm" ;
import module namespace toc="http://marklogic.com/rundmc/api/toc"
  at "toc.xqm" ;

toc:toc($api:version, xdmp:get-request-field('help-xsd-dir')),
text {
  "Created the XML-based TOC at ",$stp:toc-xml-uri, " in ",
  xdmp:elapsed-time() }

(: create-toc.xqy :)