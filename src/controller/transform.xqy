xquery version "1.0-ml" ;

import module namespace param="http://marklogic.com/rundmc/params"
  at "modules/params.xqy";
import module namespace users="users"
  at "/lib/users.xqy";

declare namespace html="http://www.w3.org/1999/xhtml";
declare namespace ml="http://developer.marklogic.com/site/internal";

let $params  := param:params()
let $doc-url := concat($params[@name eq 'src'], ".xml")
let $ext-url as xs:string? := doc($doc-url)//ml:external-link/@href

return (
  if (exists($ext-url)) then xdmp:redirect-response($ext-url)
  else xdmp:xslt-invoke(
    "/view/page.xsl",
    doc($doc-url) treat as node(),
    map:new(map:entry('params', $params))))

(: transform.xqy :)