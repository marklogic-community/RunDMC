xquery version "1.0-ml";

(: This script creates one function document per function
 : found in the raw database.
 :)

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy" ;
import module namespace ml="http://developer.marklogic.com/site/internal"
  at "/model/data-access.xqy" ;
import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "raw-docs-access.xqy" ;
import module namespace u="http://marklogic.com/rundmc/util"
  at "/lib/util-2.xqy" ;

xdmp:log(text { "[pull-function-docs.xqy] starting", $api:version }),

for $doc in $raw:API-DOCS
let $_ := xdmp:log(
  text {
    "[pull-function-docs.xqy] starting", xdmp:describe($doc) })
for $func in xdmp:xslt-invoke("extract-functions.xsl", $doc)
let $_ := xdmp:log(
  text {
    "[pull-function-docs.xqy] inserting",
    xdmp:describe($doc), 'at', base-uri($func) })
return xdmp:document-insert(base-uri($func), $func)
,
xdmp:log("[pull-function-docs.xqy] ok"),
"Inserted function docs and comment containers."

(: pull-function-docs.xqy :)