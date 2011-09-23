xquery version "1.0-ml";

import module namespace ml = "http://developer.marklogic.com/site/internal"
       at "../model/data-access.xqy";

declare namespace api = "http://marklogic.com/rundmc/api";

declare variable $existing-tags := cts:collection-match("category/*");

(: The union of all version-specific search corpuses :)
declare variable $search-corpus-query := cts:or-query($ml:server-versions/ml:search-corpus-query(string(.)));

for $doc-uri in cts:uris("",(),$search-corpus-query)
let $category-value :=
            if (contains($doc-uri, "/javadoc/")) then "xcc"
       else if (contains($doc-uri, "/dotnet/" )) then "xccn"
       else let $doc := doc($doc-uri) return
            if ($doc/api:function-page) then "function"
       else if ($doc/guide            ) then "guide"
       else if ($doc/ml:Announcement  ) then "news"
       else if ($doc/ml:Event         ) then "event"
       else if ($doc/ml:Article       ) then "tutorial"
       else if ($doc/ml:Post          ) then "blog"
       else if ($doc/ml:Project       ) then "code"
       else ()
return
(
  (: Start by cleaning up existing collections :)
  xdmp:document-remove-collections($doc-uri, $existing-tags),

  (: Add the category tag :)
  if ($category-value)
  then
    let $category-tag := concat("category/",$category-value)
    return
      (xdmp:log(concat("Adding tag '", $category-tag, "' to ", $doc-uri)),
       xdmp:document-add-collections($doc-uri, $category-tag))
  else ()
)
