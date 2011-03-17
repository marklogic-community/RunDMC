xquery version "1.0-ml";
module namespace api = "http://marklogic.com/rundmc/api";

declare variable $api:query-for-builtin-functions :=
  cts:element-attribute-value-query(xs:QName("api:function"),
                                    xs:QName("type"),
                                    "builtin");

(: Every function that's not a built-in function is a library function :)
declare variable $api:query-for-library-functions :=
   cts:element-query(
     xs:QName("api:function"),
     cts:not-query($api:query-for-builtin-functions)
   );

declare variable $api:built-in-function-count  := xdmp:estimate(cts:search(fn:collection(),$api:query-for-builtin-functions));
declare variable $api:library-function-count   := xdmp:estimate(cts:search(fn:collection(),$api:query-for-library-functions));

declare variable $api:built-in-modules := get-modules($api:query-for-builtin-functions, fn:true() );
declare variable $api:library-modules  := get-modules($api:query-for-library-functions, fn:false());

declare function get-modules($query, $builtin) {
  for $m in cts:element-attribute-values(xs:QName("api:function"),
                                         xs:QName("lib"), (), "ascending",
                                         $query)
  return
    <api:module>{
       if ($builtin) then attribute is-built-in { "yes" } else (),
       $m
    }</api:module>
};

declare function function-count-for-module($module, $builtin) {
  let $query := if ($builtin) then $api:query-for-builtin-functions
                              else $api:query-for-library-functions
  return
  xdmp:estimate(cts:search(fn:collection()/api:function[@lib eq $module], $query))
};

declare function function-names-for-module($module, $builtin) {
  let $query := if ($builtin) then $api:query-for-builtin-functions
                              else $api:query-for-library-functions

  let $query := cts:and-query(
                  ($query,
                   cts:element-attribute-value-query(xs:QName("api:function"),
                                                    xs:QName("lib"),
                                                    $module)
                  )
                )
  return
  for $func in cts:element-attribute-values(xs:QName("api:function"),
                                            xs:QName("fullname"), (), "ascending",
                                            $query)
    return
      <api:function-name>{ $func }</api:function-name>
};
