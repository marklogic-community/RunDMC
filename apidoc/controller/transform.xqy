(: This script applies the API page-rendering XSLT to the given document path,
   passing all GET and POST parameters from the client to the stylesheet.
:)
import module namespace param="http://marklogic.com/rundmc/params"
       at "../../controller/modules/params.xqy";

declare namespace map = "http://marklogic.com/xdmp/map";

let $map     := map:map()
let $params  := param:params()
let $doc-url := $params[@name eq 'src']
let $xslt    := if ($doc-url eq '/apidoc/do-search.xml') then "../../view/page.xsl" (: Use the main site template for the search results page :)
                                                         else    "../view/page.xsl"

return
  xdmp:xslt-invoke($xslt, doc($doc-url), (map:put($map,"params",$params),$map))
