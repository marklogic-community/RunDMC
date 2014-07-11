xquery version "1.0-ml";

import module namespace toc="http://marklogic.com/rundmc/api/toc"
  at "toc.xqm";

declare variable $VERSION as xs:string external ;

toc:render($VERSION)

(: apidoc/setup/render-toc.xqy :)