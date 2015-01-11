xquery version "1.0-ml";
(: This script applies the API page-rendering XSLT to the given document path,
 : passing all GET and POST parameters from the client to the stylesheet.
 :)
import module namespace param="http://marklogic.com/rundmc/params"
  at "/controller/modules/params.xqy" ;

declare variable $PARAMS := param:params() ;

declare variable $URI as xs:string := concat(
  $PARAMS[@name eq 'src']) ;

(: Use the main site template for the search results page,
 : otherwise use the apidoc template.
 :)
declare variable $XSLT := (
  if ($URI eq '/apidoc/do-search.xml') then "/view/page.xsl"
  else "/apidoc/view/page.xsl") ;

xdmp:xslt-invoke(
  $XSLT,
  doc($URI) treat as node(),
  map:new((map:entry("params", $PARAMS))))

(: transform.xqy :)