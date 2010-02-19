xquery version "1.0-ml";

module namespace qp="http://www.marklogic.com/ps/lib/queryparams";

(: queryparams parses URI request name/value pairs
 :
 : @author Norman Walsh, norman.walsh@marklogic.com
 : @date 8 Sep 2009
 :)

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare option xdmp:mapping "false"; 

(: ============================================================ :)
(: qp:load-params translates all URI name=value pairs into 
 : elements containing values. The function only works for 
 : parameter names that are valid XML element names.
 :
 : uri?a=b&c=d&123=bad => <qp:params>
 :                          <qp:a>b</qp:a>
 :                          <pq:c>d</pq:c>
 :                        </qp:params>
 :
 : @return A qp:params element containing the parsed values
 :)
declare function qp:load-params() as element(qp:params) {
  <qp:params>
    { for $i in xdmp:get-request-field-names()
      return
        for $j in xdmp:get-request-field($i)
        return
          if ($i castable as xs:NCName)
          then
            element {QName("http://www.marklogic.com/ps/lib/queryparams", $i)} {$j}
          else
            xdmp:log(concat("queryparams: not a valid field name: '", $i, "' ('", $j, "')"))
    }
  </qp:params>
};
