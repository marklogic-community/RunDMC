xquery version "1.0-ml";

            module namespace api = "http://marklogic.com/rundmc/api";
declare default function namespace "http://marklogic.com/rundmc/api";

declare namespace apidoc = "http://marklogic.com/xdmp/apidoc";

import module namespace u = "http://marklogic.com/rundmc/util"
       at "../../lib/util-2.xqy";

declare variable $api:default-version   as xs:string  := fn:string(u:get-doc("/apidoc/config/server-versions.xml")/*/version[@default eq 'yes']/@number);
declare variable $api:version-specified as xs:string? := xdmp:get-request-field("version"); (: uniformly accessed in both the setup and view code
                                                                                               rather than using $params which only the view code uses :)
declare variable $api:version           as xs:string  := if ($api:version-specified) then $api:version-specified
                                                                                     else $api:default-version;

(: This variable is only used by the setup script, because it's only in the setup scripts that we ever care about more than one TOC URL at a time :)
(: Its value must be the same as $api:toc-url-location when $api:version-specified is empty, so the view code will get the right default TOC. :)
declare variable $api:toc-url-default-version-location := fn:concat("/apidoc/private/",                       "toc-url.xml");
declare variable $api:toc-url-location                 := fn:concat("/apidoc/private/",$api:version-specified,"toc-url.xml");

(: The URL of the current TOC (based on whatever version the user has requested) :)
declare variable $api:toc-url := fn:string(fn:doc($toc-url-location)/*);

declare variable $api:version-dir := fn:concat("/apidoc/",$api:version,"/");
declare variable $api:version-dir-query :=
  cts:directory-query($api:version-dir,"1");

declare variable $api:query-for-builtin-functions :=
  cts:and-query((
    $api:version-dir-query,
    cts:element-attribute-value-query(xs:QName("api:function"),
                                      xs:QName("type"),
                                      "builtin")
  ));

declare variable $api:query-for-library-functions :=
  cts:and-query((
    $api:version-dir-query,
    cts:element-query(
      xs:QName("api:function"),
      (: Every function that's not a built-in function is a library function :)
      cts:not-query($api:query-for-builtin-functions)
    )
  ));

declare variable $api:built-in-function-count  := xdmp:estimate(cts:search(fn:collection(),$api:query-for-builtin-functions));
declare variable $api:library-function-count   := xdmp:estimate(cts:search(fn:collection(),$api:query-for-library-functions));

declare variable $api:built-in-libs := get-libs($api:query-for-builtin-functions, fn:true() );
declare variable $api:library-libs  := get-libs($api:query-for-library-functions, fn:false());

declare function get-libs($query, $builtin) {
  for $lib in cts:element-attribute-values(xs:QName("api:function"),
                                           xs:QName("lib"), (), "ascending",
                                           $query)
  return
    <wrapper> <!-- wrapper necessary for XSLTBUG 13062 workaround re: processing of parentless elements -->
      <api:lib>{
         if ($builtin) then attribute built-in { "yes" } else (),
         $lib
      }</api:lib>
    </wrapper>
    /api:lib
};

declare function function-count-for-lib($lib) {
  let $dir := $api:version-dir return (: This line is necessary as a workaround for Bug #13385 :)
  xdmp:estimate(xdmp:directory($dir,"1")/api:function-page/api:function[@lib eq $lib])
};

declare function function-names-for-lib($lib) {

  let $query := cts:element-attribute-value-query(xs:QName("api:function"),
                                                  xs:QName("lib"),
                                                  $lib)
  return
  for $func in cts:element-attribute-values(xs:QName("api:function"),
                                            xs:QName("fullname"), (), "ascending",
                                            $query)
    return
      <api:function-name>{ $func }</api:function-name>
};


declare variable $namespace-mappings := u:get-doc("/apidoc/config/namespace-mappings.xml")/namespaces/namespace;

(: Returns the namespace URI associated with the given lib name :)
declare function uri-for-lib($lib) {
  fn:string($namespace-mappings[@lib eq $lib]/@uri)
};

(: Normally, just use the lib name as the prefix, unless specially configured to do otherwise :)
declare function prefix-for-lib($lib) {
  fn:string($namespace-mappings[@lib eq $lib]/(if (@prefix) then @prefix else $lib))
};
