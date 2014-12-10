xquery version "1.0-ml";

declare variable $uri := xdmp:get-request-field("uri");

if (fn:doc-available($uri)) then
  xdmp:document-delete($uri)
else (
  fn:error(xs:QName("NotFound"), "Failed to delete; no document at " || $uri)
),

xdmp:redirect-response("/media")
