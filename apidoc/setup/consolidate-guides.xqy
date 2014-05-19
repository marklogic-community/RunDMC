xquery version "1.0-ml";

(: This script is run in the raw database, setting up the URLs for the XML
 : files for each guide, and adding a chapter list to the title doc.
 :)

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";
import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

stp:guides-consolidate($api:version),
"Done consolidating guides."

(: apidoc/setup/consolidate-guides.xqy :)