import module namespace param="http://marklogic.com/rundmc/params"
       at "modules/params.xqy";

let $params  := param:params()
let $doc-url := concat($params[@name eq 'src'], ".xml")

return
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
