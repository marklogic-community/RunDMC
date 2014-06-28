xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";
import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

stp:toc-delete(),
text {
  "Finished deleting old TOC parts for", $api:version, xdmp:elapsed-time() }

(: apidoc/setup/delete-old-toc.xqy :)

