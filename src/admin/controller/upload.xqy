xquery version "1.0-ml";

import module namespace admin-ops = "http://marklogic.com/rundmc/admin-ops"
       at "modules/admin-ops.xqy";

declare variable $content := xdmp:get-request-field("content");

declare variable $uri := "/media/" || xdmp:get-request-field("uri");

declare variable $overwrite := fn:boolean(xdmp:get-request-field("overwrite"));

if (fn:doc-available($uri) and fn:not($overwrite)) then
  fn:error(xs:QName("Conflict"), "Something already exists at URI " || $uri)
else (
  admin-ops:document-insert(
    $uri,
    $content,
    "media"
  ),
  xdmp:redirect-response("/media")
)
