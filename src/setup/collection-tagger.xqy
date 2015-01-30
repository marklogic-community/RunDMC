xquery version "1.0-ml";

import module namespace ml = "http://developer.marklogic.com/site/internal"
       at "../model/data-access.xqy";

declare namespace api = "http://marklogic.com/rundmc/api";

xdmp:set-response-content-type("text/plain"),
(: Prevent download prompt in IE. :)
xdmp:add-response-header("x-content-type-options","nosniff"),

(: Add the category collection URI to all available documents. :)
ml:reset-category-tags(
  cts:uris((), (),
    (: The union of all version-specific search corpuses :)
    ml:search-corpus-query($ml:server-versions)))

,"Finished adding category tags (see ErrorLog for details)."

(: collection-tagger.xqy :)