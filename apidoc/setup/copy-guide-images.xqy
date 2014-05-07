xquery version "1.0-ml";

import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "raw-docs-access.xqy";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";

(: This may be invoked on the task server,
 : where get-request-field will not find the right version.
 :)
declare variable $VERSION as xs:string external ;

(: Restore the correct environment. :)
xdmp:set($api:version-specified, $VERSION),
xdmp:log(
  text {
    "[apidoc/setup/copy-guide-images.xqy]",
    'version', $VERSION, $api:version, $raw:VERSION }),
let $guide-docs as node()+ := raw:guide-docs($VERSION)
for $doc in $guide-docs
for $img-path in distinct-values($doc//IMAGE/@href)
let $base-dir   := string($doc/(guide|chapter)/@original-dir)
let $source-uri := resolve-uri($img-path, $base-dir)
let $dest-uri   := concat(
  api:guide-image-dir(raw:target-guide-doc-uri($doc)),
  $img-path)
let $_ := xdmp:log(
  text {
    "[apidoc/setup/copy-guide-images.xqy]",
    $source-uri, "to", $dest-uri })
return xdmp:document-insert($dest-uri, raw:get-doc($source-uri))

, "Done copying guide images."

(: copy-guide-images.xqy :)