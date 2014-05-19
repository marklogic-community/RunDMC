xquery version "1.0-ml";

(: This script creates one function document per function
 : found in the raw database.
 :)

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy" ;
import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm" ;

stp:function-docs($api:version),
"Inserted function docs and comment containers."

(: pull-function-docs.xqy :)