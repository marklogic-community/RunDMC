(: This script applies the API page-rendering XSLT to the given document path,
   passing all GET and POST parameters from the client to the stylesheet.
:)
import module namespace param="http://marklogic.com/rundmc/params"
       at "../../controller/modules/params.xqy";

declare namespace map = "http://marklogic.com/xdmp/map";

let $map     := map:map()
let $params  := param:params()
let $doc-url := concat($params[@name eq 'src'], ".xml")

return
  xdmp:xslt-invoke("../view/page.xsl", doc($doc-url), (map:put($map,"params",$params),$map))
