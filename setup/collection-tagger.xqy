xquery version "1.0-ml";

import module namespace ml = "http://developer.marklogic.com/site/internal"
       at "../model/data-access.xqy";

declare namespace api = "http://marklogic.com/rundmc/api";

for $doc in cts:search(collection(), $ml:search-corpus-query)
let $doc-uri := base-uri($doc),
    $facet-value :=
            if ($doc/api:function-page) then "function"
       else if ($doc/guide            ) then "guide"
       else if ($doc/ml:Announcement  ) then "news"
       else if ($doc/ml:Event         ) then "event"
       else if ($doc/ml:Article       ) then "tutorial"
       else if ($doc/ml:Post          ) then "blog"
       else if ($doc/ml:Project       ) then "code"
       else if (contains($doc-uri, "/javadoc/")) then "xcc"
       else if (contains($doc-uri, "/dotnet/" )) then "xccn"
       else ()
return
  if (not($facet-value))
  then ()
  else
    let $tag := concat("category/",$facet-value) return
    (xdmp:log(concat("Adding tag '", $tag, "' to ", $doc-uri)),
     xdmp:document-add-collections($doc-uri, $tag))
