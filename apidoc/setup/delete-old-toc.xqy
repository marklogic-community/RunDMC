xquery version "1.0-ml";

import module namespace setup = "http://marklogic.com/rundmc/api/setup"
       at "common.xqy";

import module namespace api = "http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

declare function local:delete-all-except($dir, $prefix) {
  for $toc-parts-dir in cts:uri-match(concat($dir,"*.html/"))
  let $main-toc := substring($toc-parts-dir,1,string-length($toc-parts-dir)-1)
  where not(starts-with($toc-parts-dir,$prefix))
  return ( xdmp:document-delete($main-toc),
          xdmp:directory-delete($toc-parts-dir)
         )
};

xdmp:log("Deleting old TOC parts."),

(: Delete old TOC parts in the numbered directory :)
local:delete-all-except($setup:toc-dir, string(doc($api:toc-url-location))),

(: If applicable, delete TOC parts in the default (non-numbered) directory :)
if ($setup:processing-default-version) then 
local:delete-all-except($setup:toc-default-dir, $api:toc-url)
else (),

xdmp:log("Done."),

"Finished deleting old TOC parts for this version."
