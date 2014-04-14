xquery version "1.0-ml";
(: This script applies the API page-rendering XSLT to the given document path,
 : passing all GET and POST parameters from the client to the stylesheet.
 :)
import module namespace param="http://marklogic.com/rundmc/params"
  at "/controller/modules/params.xqy" ;

let $params := param:params()
let $doc-url as xs:string := $params[@name eq 'src']
let $xslt := (
  (: Use the main site template for the search results page :)
  if ($doc-url eq '/apidoc/do-search.xml') then "/view/page.xsl"
  else "../view/page.xsl")
return xdmp:xslt-invoke(
  $xslt,
  doc($doc-url) treat as node(),
  map:new(
    (map:entry("params", $params))))

(: transform.xqy :)