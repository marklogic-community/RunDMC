xquery version "1.0-ml";

import module namespace u = "http://marklogic.com/rundmc/util" at "../../lib/util-2.xqy";
import module namespace srv = "http://marklogic.com/rundmc/server-urls" at "../../controller/server-urls.xqy";

declare namespace api = "http://marklogic.com/rundmc/api";

declare variable $path            := xdmp:get-request-path();
declare variable $orig-url        := xdmp:get-request-url();
declare variable $query-string    := substring-after($orig-url, '?');

declare variable $legal-versions  := u:get-doc("/apidoc/config/server-versions.xml")/*/version/@number;
declare variable $default-version := fn:string($legal-versions[../@default eq 'yes']);

declare variable $version-specified := if (matches($path, '^/[0-9]\.[0-9]$')) then substring-after($path,'/')
                                  else if (matches($path, '^/[0-9]\.[0-9]/')) then substring-before(substring-after($path,'/'),'/')
                                  else "";

declare variable $version     := if ($version-specified) then $version-specified else $default-version;
declare variable $path-prefix := if ($version-specified) then concat("/",$version-specified,"/") else "/";

declare variable $pdf-location  := 
  let $guide-configs := u:get-doc("/apidoc/config/document-list.xml")/*/guide,
      $version       := if ($version-specified) then $version-specified else $default-version,
      $guide-name    := substring-before(substring-after($path,"/docs/"),".pdf"),
      $pdf-name      := $guide-configs[@url-name eq $guide-name]/(@pdf-name,@source-name)[1]
  return
    concat("/pubs/",$version,"/books/",$pdf-name,".pdf");

declare variable $root-doc-url    := concat('/apidoc/', $default-version,        '/index.xml');
declare variable $doc-url-default := concat('/apidoc/', $default-version, $path, '.xml'); (: when version is unspecified in path :)
declare variable $doc-url         := concat('/apidoc',                    $path, '.xml'); (: when version is specified in path :)
declare variable $path-plus-index := concat('/apidoc',                    $path, '/index.xml');

(: Render a document using XSLT :)
declare function local:transform($source-doc) as xs:string {
  concat("/apidoc/controller/transform.xqy?src=",          $source-doc,
                                          "&amp;version=", $version-specified,
                                          "&amp;", $query-string)
};

declare function local:redirect($new-path) as xs:string {
  concat('/controller/redirect.xqy?path=', $new-path)
};

declare function local:function-url($function as document-node()) as xs:string {
  concat($path-prefix, $function/*/api:function[1]/@fullname)
};

declare function local:choose-function($functions as document-node()+) as document-node() {
  let $preferred := ("fn","xdmp"),
      $ordered := for $f in $functions,
                      $lib in $f/*/api:function[1]/@lib,
                      $name in $f/*/api:function[1]/@name
                  order by index-of($preferred, $lib),
                           $lib,
                           $name
                  return $f
  return
    $ordered[1]
};

declare variable $matching-function-query :=
  let $dir := concat("/apidoc/",$version,"/"),
      $name := substring-after($path, $path-prefix) return
    cts:and-query((
      cts:directory-query($dir),
      cts:element-attribute-value-query(
        xs:QName("api:function"),
        xs:QName("name"),
        $name,
        "exact")));

declare variable $matching-functions :=
  xdmp:query-trace(true()),

  cts:search(
    collection(),
    $matching-function-query),

  xdmp:query-trace(false());

declare variable $matching-function-count := count($matching-functions);

(: SCENARIO 1: External redirect :)
  (: Externally redirect paths with trailing slashes :)
  if (($path ne '/') and ends-with($path, '/')) then
      local:redirect(concat(substring($path, 1, string-length($path) - 1),
                            if ($query-string) then concat('&amp;', $query-string) else ()))
  (: Redirect requests for older versions back to DMC :)
  else if (starts-with($path,"/4.0")) then
       local:redirect(concat($srv:main-server,"/docs/4.0"))
  else if (starts-with($path,"/3.2")) then
       local:redirect(concat($srv:main-server,"/docs/3.2"))


(: SCENARIO 2: Internal rewrite :)
  (: SCENARIO 2A: Serve content from file system :)
    (: Remove version from the URL for versioned assets :)
    else if (matches($path, '^/(css|images)/v-[0-9]*/.*')) then
      replace($path, '/v-[0-9]*', '')

    (: If the path starts with one of the designated paths in the code base, then serve from filesystem :)
    else if (u:get-doc("/controller/access.xml")/paths/prefix[starts-with($path,.)]) then
      $orig-url


  (: SCENARIO 2B: Serve content from database :)
    (: Respond with DB contents for /media :)
    else if (starts-with($path, '/media/')) then 
      concat("/controller/get-db-file.xqy?uri=", $path)

    (: Map PDF URIs to DMC PDF URIs :)
    else if (ends-with($path, '.pdf')) then
        concat("/controller/get-db-file.xqy?uri=", $pdf-location)

    (: Ignore URLs starting with "/private/" :)
    else if (starts-with($path,'/private/')) then
      "/controller/notfound.xqy"

    (: Root request: "/" means "index.xml" inside the default version's directory :)
    else if ($path eq '/') then 
      local:transform($root-doc-url)

    (: If the version-specific doc path requested, e.g., /4.2/foo, is available, then serve it :)
    else if (doc-available($doc-url)) then
      local:transform($doc-url)

    (: A version-specific root request, e.g., /4.2 :)
    else if ($path eq concat('/',$version-specified) and $version-specified = $legal-versions) then
      local:transform($path-plus-index)

    (: Otherwise, look in the default version directory :)
    else if (doc-available($doc-url-default)) then
      local:transform($doc-url-default)


(: SCENARIO 3: External redirect to matching function page :)
    (: If the path matches exactly one function's local name, then redirect to that page :)
    else if ($matching-function-count eq 1) then
      local:redirect(local:function-url($matching-functions))

    (: If the path matches more than one function's local name, show the first one :)
    else if ($matching-function-count gt 1) then
      let $chosen-function := local:choose-function($matching-functions) return
      local:redirect(concat(local:function-url($chosen-function),xdmp:url-encode("?alt=yes")))


(: SCENARIO 4: Not found anywhere :)
  else "/controller/notfound.xqy"

