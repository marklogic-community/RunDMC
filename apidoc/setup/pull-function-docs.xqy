xquery version "1.0-ml";

import module namespace ml="http://developer.marklogic.com/site/internal"
       at "../../model/data-access.xqy";

declare variable $query := '
  declare namespace apidoc="http://marklogic.com/xdmp/apidoc";
  fn:collection()[apidoc:module]
';

declare variable $raw-docs := xdmp:eval($query, (), <options xmlns="xdmp:eval">
                                                      <database>{xdmp:database("docapp")}</database>
                                                    </options>);

"Inserting function docs and associated comment thread containers...",
for $doc in $raw-docs return 
  for $func in xdmp:xslt-invoke("extract-functions.xsl", $doc) return
  (
    xdmp:document-insert(fn:base-uri($func), $func),
    ml:insert-comment-doc(fn:base-uri($func))
  )
