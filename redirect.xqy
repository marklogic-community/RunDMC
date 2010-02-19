import module namespace qp="http://www.marklogic.com/ps/lib/queryparams"
       at "/modules/queryparams.xqy";

let $params := qp:load-params()
return
  xdmp:redirect-response($params/qp:path)
