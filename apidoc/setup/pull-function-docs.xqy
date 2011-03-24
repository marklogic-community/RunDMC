xquery version "1.0-ml";

(: This script creates one function document per function found in the docapp database :)

import module namespace ml="http://developer.marklogic.com/site/internal"
       at "../../model/data-access.xqy";

import module namespace docapp="http://marklogic.com/rundmc/docapp-data-access"
       at "docapp-data-access.xqy";

"Inserting function docs and associated comment thread containers...",
for $doc in $docapp:docs return 
  for $func in xdmp:xslt-invoke("extract-functions.xsl", $doc) return
  (
    xdmp:document-insert(fn:base-uri($func), $func),
    ml:insert-comment-doc(fn:base-uri($func))
  )
