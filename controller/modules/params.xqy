xquery version "1.0-ml" ;

module namespace param="http://marklogic.com/rundmc/params" ;

import module namespace functx = "http://www.functx.com"
  at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy" ;

declare function param:params()
as element(param)*
{
  for $name  in xdmp:get-request-field-names()
  for $value in xdmp:get-request-field($name)
  return document {
    <params>
      <param name="{$name}">{ $value }</param>
    </params> }/params/param
};

declare function param:trimmed-params() {
  for $name  in xdmp:get-request-field-names(),
      $value in xdmp:get-request-field($name)
    return
       let $doc := document {
                     <params>
                       <param name="{$name}">{ functx:trim($value) }</param>
                     </params>
                   }
       return $doc/params/param
};

declare function param:distinct-trimmed-params() {
  for $name  in fn:distinct-values(xdmp:get-request-field-names()),
      $value in xdmp:get-request-field($name)
    return
       let $doc := document {
                     <params>
                       <param name="{$name}">{ functx:trim($value) }</param>
                     </params>
                   }
       return $doc/params/param
};
