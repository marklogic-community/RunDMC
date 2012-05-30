xquery version "1.0-ml";

import module namespace raw = "http://marklogic.com/rundmc/raw-docs-access"
       at "raw-docs-access.xqy";

import module namespace api="http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

for $doc in $raw:guide-docs,
    $img-path in distinct-values($doc//IMAGE/@href)
let $base-dir   := string($doc/(guide|chapter)/@original-dir)
let $source-uri := resolve-uri($img-path, $base-dir)
let $dest-uri   := concat(api:guide-image-dir(raw:target-guide-doc-uri($doc)), $img-path)
return
  (xdmp:log(concat("Getting image doc ",$source-uri," and writing to ", $dest-uri)),
   xdmp:document-insert($dest-uri, raw:get-doc($source-uri))
  )

, "Done copying guide images."
