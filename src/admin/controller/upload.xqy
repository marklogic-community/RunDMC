xquery version "1.0-ml";

import module namespace admin-ops = "http://marklogic.com/rundmc/admin-ops"
       at "modules/admin-ops.xqy";

declare variable $content := xdmp:get-request-field("content");

declare variable $uri :=
  let $uri := xdmp:get-request-field("uri")
  return
    if (fn:starts-with($uri, "/media/")) then
      $uri
    else
      "/media" || $uri;

declare variable $overwrite := fn:boolean(xdmp:get-request-field("overwrite"));

declare variable $redirect := fn:boolean(xdmp:get-request-field("redirect", "true"));

if (fn:doc-available($uri) and fn:not($overwrite)) then
  fn:error(xs:QName("Conflict"), "Something already exists at URI " || $uri)
else (
  admin-ops:document-insert(
    $uri,
    $content,
    "media"
  ),
  if ($redirect) then
    xdmp:redirect-response("/media")
  else ()
)
