xquery version "1.0-ml";

import module namespace raw = "http://marklogic.com/rundmc/raw-docs-access"
       at "raw-docs-access.xqy";

import module namespace api="http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

for $guide in $raw:guide-docs,
    $img-path in distinct-values($guide//IMAGE/@href)
let $base-dir   := string($guide/guide/@original-dir)
let $source-uri := resolve-uri($img-path, $base-dir)
let $dest-uri   := concat(api:guide-image-dir(raw:target-guide-uri($guide)), $img-path)
return
  (xdmp:log(concat("Getting image doc ",$source-uri," and writing to ", $dest-uri)),
   xdmp:document-insert($dest-uri, raw:get-doc($source-uri))
  )
