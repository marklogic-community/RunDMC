xquery version "1.0-ml";

declare namespace error="http://marklogic.com/xdmp/error";

declare namespace ml = "http://developer.marklogic.com/site/internal";

declare variable $xhtml := xdmp:get-request-field("xhtml");

declare variable $last-updated := xdmp:get-request-field("updated");

declare variable $uri := xdmp:get-request-field("uri");

(: Determine if some XHTML is valid.  Wrap it in a document wrapper and see if it can be unquoted.
    This will generate meaningful errors of the XHTML is invalid :)
let $test-xhtml :=
  try {
    let $quoted-doc := fn:concat("&lt;ml:docWrapper xmlns:ml='http://developer.marklogic.com/site/internal'>", $xhtml, "&lt;/ml:docWrapper>")
    let $current :=
      if ($uri != "" and $last-updated != "" and $last-updated != fn:doc($uri)/node()/ml:last-updated/fn:string()) then (
        xdmp:set-response-code(409, "Conflict"),
        fn:error(xs:QName("CONFLICT"), "Content is out of date; saving would overwrite changes.")
      )
      else ()
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
