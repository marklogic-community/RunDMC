xquery version "1.0-ml";

declare namespace error="http://marklogic.com/xdmp/error";

declare variable $xhtml := xdmp:get-request-field("xhtml");

(: Determine if some XHTML is valid.  Wrap it in a document wrapper and see if it can be unquoted.
    This will generate meaningful errors of the XHTML is invalid :)
let $test-xhtml :=
  try {
    let $quoted-doc := fn:concat("&lt;ml:docWrapper xmlns:ml='http://developer.marklogic.com/site/internal'>", $xhtml, "&lt;/ml:docWrapper>")
    return xdmp:unquote($quoted-doc, "http://www.w3.org/1999/xhtml")
  }
  catch($exception) {
    $exception
  }

return
  if(fn:node-name($test-xhtml) = xs:QName("error:error")) then
    $test-xhtml
  else
    ()
