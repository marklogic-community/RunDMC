xquery version "1.0-ml";

import module namespace ml = "http://developer.marklogic.com/site/internal"
       at "../model/data-access.xqy";

declare namespace api = "http://marklogic.com/rundmc/api";

(: The union of all version-specific search corpuses :)
declare variable $search-corpus-query := cts:or-query($ml:server-versions/ml:search-corpus-query(string(.)));

xdmp:set-response-content-type("text/plain"),
xdmp:add-response-header("x-content-type-options","nosniff"), (: to prevent download prompt in IE :)

(: Add the category collection URI :)
for $doc-uri in cts:uris("",(),$search-corpus-query)
return ml:reset-category-tags($doc-uri)

,"Finished adding category tags (see ErrorLog for details)."
