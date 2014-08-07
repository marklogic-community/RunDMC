xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";
import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

declare variable $VERSION as xs:string external ;

stp:toc-docs-delete($VERSION),
if ($version ne $api:DEFAULT-VERSION) then ()
else stp:toc-docs-delete('default')

(: apidoc/setup/delete-old-toc.xqy :)

