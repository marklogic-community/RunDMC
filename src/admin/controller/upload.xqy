xquery version "1.0-ml";

declare variable $content := xdmp:get-request-field("content");

declare variable $uri := xdmp:get-request-field("uri");

declare variable $overwrite := fn:boolean(xdmp:get-request-field("overwrite"));

if (fn:doc-available($uri) and fn:not($overwrite)) then
  ()
else (
  xdmp:document-insert(
    "/media/" || $uri,
    $content,
    xdmp:default-permissions(),
    "media"
  ),
  xdmp:redirect-response("/media")
)
