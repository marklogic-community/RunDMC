import module namespace qp="http://www.marklogic.com/ps/lib/queryparams"
       at "/modules/queryparams.xqy";

let $params  := qp:load-params()
let $doc-url := concat($params/qp:src, ".xml")
return
  xdmp:xslt-invoke("page.xsl", doc($doc-url))
