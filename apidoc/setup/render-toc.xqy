xquery version "1.0-ml";

import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";
import module namespace toc="http://marklogic.com/rundmc/api/toc"
  at "toc.xqm";

(: Make sure the version param was specified :)
$stp:errorCheck,
toc:render(),

text {
  "Rendered the HTML TOC(s) and recorded their URL(s) in ",
  xdmp:elapsed-time() },
text { '' }

(: apidoc/setup/render-toc.xqy :)