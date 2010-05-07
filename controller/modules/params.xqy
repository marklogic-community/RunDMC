module namespace param="http://marklogic.com/rundmc/params";

declare function param:params() {
  for $name  in xdmp:get-request-field-names(),
      $value in xdmp:get-request-field($name)
    return
       <param name="{$name}">{ $value }</param>
};
