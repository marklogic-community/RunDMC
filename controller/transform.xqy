import module namespace qp="http://www.marklogic.com/ps/lib/queryparams"
       at "modules/queryparams.xqy";

let $params  := qp:load-params()
let $doc-url := concat($params/qp:src, ".xml")
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
