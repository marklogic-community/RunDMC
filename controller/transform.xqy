import module namespace param="http://marklogic.com/rundmc/params"
       at "modules/params.xqy";

declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace ml = "http://developer.marklogic.com/site/internal";

let $params  := param:params()
let $doc-url := concat($params[@name eq 'src'], ".xml")
let $ext-url := doc($doc-url)//ml:external-link/@href

let $_ := xdmp:log($ext-url)

return
if (exists($ext-url)) then
    xdmp:redirect-response($ext-url)
else
(
  xdmp:xslt-invoke("/view/page.xsl", doc($doc-url),
    map:map(
      <map:map xmlns:map="http://marklogic.com/xdmp/map">
        <map:entry>
          <map:key>params</map:key>
          <map:value>{ $params }</map:value>
        </map:entry>
      </map:map>
    )
  )
)
