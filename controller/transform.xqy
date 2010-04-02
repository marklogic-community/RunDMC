import module namespace qp="http://www.marklogic.com/ps/lib/queryparams"
       at "modules/queryparams.xqy";

let $params  := qp:load-params()
let $doc-url := concat($params/qp:src, ".xml")
return
(
  xdmp:xslt-invoke("/view/page.xsl", doc($doc-url),
    map:map(
      (: TODO: Ensure there's no cross-site scripting risks :)
      <map:map xmlns:map="http://marklogic.com/xdmp/map">
        <map:entry>
          <map:key>message</map:key>
          <map:value>{ string($params/qp:message) }</map:value>
        </map:entry>
      </map:map>
    )
  )
)
