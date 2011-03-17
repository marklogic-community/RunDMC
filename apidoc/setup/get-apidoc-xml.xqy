xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

declare namespace apidoc="http://marklogic.com/xdmp/apidoc";

declare variable $query := '
  declare namespace apidoc="http://marklogic.com/xdmp/apidoc";
  fn:collection()[apidoc:module]
';

declare variable $raw-docs := xdmp:eval($query, (), <options xmlns="xdmp:eval">
                                                      <database>{xdmp:database("docapp")}</database>
                                                    </options>);

declare variable $all-functions := $raw-docs/*/apidoc:function;

declare function local:make-list-page($functions) {
  document {
    (: Being careful to avoid the element name "api:function", which we've reserved already :)
    <api:function-list-page>{

      for $func in $functions order by $func/@fullname return
        <api:function-listing>
          <api:name>{$func/@fullname}</api:name>
          <api:description>{
            (: Use the same code that docapp uses for extracting the summary (first line) :)
            fn:concat(fn:tokenize($func/apidoc:summary,"\.(\s+|\s*$)")[1], ".")
          }</api:description>
        </api:function-listing>

    }</api:function-list-page>
  }
};

(
"Inserting function docs...",
for $doc in $raw-docs return 
  for $func in xdmp:xslt-invoke("extract-functions.xsl", $doc) return
    xdmp:document-insert(fn:base-uri($func), $func),

"Inserting master list...",
xdmp:document-insert("/apidoc/index.xml", local:make-list-page($all-functions)),

"Inserting list for each module...",

"Inserting built-in master list...",

"Inserting library master list...",
()
)
