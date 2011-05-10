xquery version "1.0-ml";

(: This script creates one function document per function found in the raw database :)

import module namespace ml="http://developer.marklogic.com/site/internal"
       at "../../model/data-access.xqy";

import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
       at "raw-docs-access.xqy";

import module namespace u="http://marklogic.com/rundmc/util"
       at "../../lib/util-2.xqy";

xdmp:log(concat("Pulling function docs from the raw docs database...")),

for $doc in $raw:api-docs return 
  for $func in xdmp:xslt-invoke("extract-functions.xsl", $doc) return
  (
    xdmp:document-insert(fn:base-uri($func), $func),
    (: Comment docs should not be version-specific, so remove the version number :)
    ml:insert-comment-doc(u:strip-version-from-path(fn:base-uri($func)))
  ),

xdmp:log("Done."),
"Inserted function docs and comment containers."
