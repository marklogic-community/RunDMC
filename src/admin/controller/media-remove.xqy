xquery version "1.0-ml";

declare variable $uri := "/media/" || xdmp:get-request-field("uri");

if (fn:doc-available($uri) and fn:not($overwrite)) then
  fn:error(xs:QName("Conflict"), "Something already exists at URI " || $uri)
else (
  xdmp:document-insert(
    $uri,
    $content,
    xdmp:default-permissions(),
    "media"
  ),
  xdmp:redirect-response("/media")
)
