xquery version "1.0-ml";

import module namespace u = "http://marklogic.com/rundmc/util" at "../../lib/util-2.xqy";
import module namespace api = "http://marklogic.com/rundmc/api" at "../model/data-access.xqy";
import module namespace ml = "http://developer.marklogic.com/site/internal" at "../../model/data-access.xqy";
import module namespace srv = "http://marklogic.com/rundmc/server-urls" at "../../controller/server-urls.xqy";

declare variable $orig-path       := xdmp:url-decode(xdmp:get-request-path());
declare variable $orig-url        := xdmp:get-request-url();
declare variable $query-string    := substring-after($orig-url, '?');
  (: $path is just the original path, unless this is a REST doc, in which 
     case we also might have to look at the query string (translating 
     "?" to "@") :)
declare variable $path  := 
 if (contains($orig-path,'/REST/') and $query-string) 
 then $REST-doc-path 
 else $orig-path;

declare variable $version-specified := if (matches($path, '^/[0-9]\.[0-9]$')) then substring-after($path,'/')
                                  else if (matches($path, '^/[0-9]\.[0-9]/')) then substring-before(substring-after($path,'/'),'/')
                                  else "";

declare variable $version     := if ($version-specified) then $version-specified else $api:default-version;
declare variable $path-prefix := if ($version-specified) then concat("/",$version-specified,"/") else "/";

declare variable $root-doc-url    := concat('/apidoc/', $api:default-version,        '/index.xml');
declare variable $doc-url-default := concat('/apidoc/', $api:default-version, $path, '.xml'); (: when version is unspecified in path :)
declare variable $doc-url         := concat('/apidoc',                        $path, '.xml'); (: when version is specified in path :)
declare variable $path-plus-index := concat('/apidoc',                        $path, '/index.xml');


(: For REST doc URIs, translate "?" to "@", ignore trailing ampersands, and ignore unknown parameters :)
declare variable $REST-doc-path :=

  let $candidate-uris := (cts:uri-match(concat('/apidoc/', $api:default-version, $orig-path, $api:REST-uri-questionmark-substitute, "*")),
                          cts:uri-match(concat('/apidoc/',                       $orig-path, $api:REST-uri-questionmark-substitute, "*")))

  let $known-query-params :=
    distinct-values(for $uri in $candidate-uris return local:REST-doc-query-param($uri))[string(.)]

  let $canonicalized-query-string :=
    string-join(
      for $name in xdmp:get-request-field-names()
      where $name = $known-query-params
      order by $name
      return
        for $value in xdmp:get-request-field($name)
        return concat($name,'=',$value)
      ,'&amp;')
  return
    if ($canonicalized-query-string)
    then concat($orig-path, $api:REST-uri-questionmark-substitute, $canonicalized-query-string)
    else $orig-path
;

(: ASSUMPTION: each REST doc will have at most one query parameter in its URI :)
declare function local:REST-doc-query-param($doc-uri) {
  substring-before(
    substring-after($doc-uri,$api:REST-uri-questionmark-substitute),
    '=')
};

(: Render a document using XSLT :)
declare function local:transform($source-uri) as xs:string {
  concat("/apidoc/controller/transform.xqy?src=",          $source-uri,
                                          "&amp;version=", $version-specified,
                                          "&amp;", $query-string)
};

(: Grab doc from database :)
declare function local:get-db-file($source-uri) as xs:string {
  concat("/controller/get-db-file.xqy?uri=", $source-uri)
};

declare function local:redirect($new-path) as xs:string {
  concat('/controller/redirect.xqy?path=', $new-path)
};

declare function local:function-url($function as document-node()) as xs:string {
  concat($path-prefix, $function/*/api:function[1]/@fullname)
};

declare variable $matching-functions := ml:get-matching-functions(substring-after($path, $path-prefix), $api:version);

declare variable $matching-function-count := count($matching-functions);

(: SCENARIO 1: External redirect :)
  (: When the user hits Enter in the TOC filter box :)
  if ($path eq '/do-do-search') then
      local:redirect(concat($srv:search-page-url,"?",$query-string))
  (: Externally redirect paths with trailing slashes :)
  else if (($path ne '/') and ends-with($path, '/')) then
      local:redirect(concat(substring($path, 1, string-length($path) - 1),
                            if ($query-string) then concat('&amp;', $query-string) else ()))
  (: Redirect naked /guide and /javadoc to / :)
  else if (substring-after($path,$path-prefix) = ("guide","javadoc")) then
       local:redirect($path-prefix)
  (: Redirect /dotnet to /dotnet/xcc :)
  else if (substring-after($path,$path-prefix) eq "dotnet") then
       local:redirect(concat($path,'/xcc/index.html'))
  (: Redirect /cpp to /cpp/udf :)
  else if (substring-after($path,$path-prefix) eq "cpp") then
       local:redirect(concat($path,'/udf/index.html'))
  (: Redirect path without index.html to index.html :)
  else if (substring-after($path,$path-prefix) = ("javadoc/hadoop",
                                                  "javadoc/client",
                                                  "javadoc/xcc",
                                                  "dotnet/xcc",
                                                  "cpp/udf")) then
       local:redirect(concat($path,'/index.html'))
  (: Redirect requests for older versions back to DMC :)
  else if (starts-with($path,"/4.0")) then
       local:redirect(concat($srv:main-server,"/docs/4.0"))
  else if (starts-with($path,"/3.2")) then
       local:redirect(concat($srv:main-server,"/docs/3.2"))


(: SCENARIO 2: Internal rewrite :)

  (: SCENARIO 2A: Serve up the JavaScript-based docapp redirector :)
    else if (ends-with($path, "docapp.xqy")) then
      "/apidoc/controller/docapp-redirector.xqy"

  (: SCENARIO 2B: Serve content from file system :)
    (: Remove version from the URL for versioned assets :)
    else if (matches($path, '^/(css|images)/v-[0-9]*/.*')) then
      replace($path, '/v-[0-9]*', '')

    (: If the path starts with one of the designated paths in the code base, then serve from filesystem :)
    else if (u:get-doc("/controller/access.xml")/paths/prefix[starts-with($path,.)]) then
      $orig-url


  (: SCENARIO 2C: Serve content from database :)
    (: Respond with DB contents for /media  :)
    else if (starts-with($path, '/media/')) then
      local:get-db-file($path)

    (: For zip file requests, we assume its for the zip file of all docs :)
    else if (ends-with($path, '.zip')) then
      local:get-db-file(concat("/apidoc",$path))

    (: Respond with DB contents for PDF and HTML docs :)
    else if (ends-with($path, '.pdf')
          or contains($path,'/javadoc/')
          or contains($path,'/dotnet/')
          or contains($path,'/cpp/')) then
      let $path-without-version := concat('/',substring-after($path,$path-prefix)),
          $path-with-version    := concat('/', $version, $path-without-version),
          $file-uri := concat('/apidoc', $path-with-version)
      return
        local:get-db-file($file-uri)

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
    else if ($path eq concat('/',$version-specified) and doc-available($path-plus-index)) then
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
      let $function := $matching-functions[1] return
      local:redirect(concat(local:function-url($function),xdmp:url-encode("?show-alternatives=yes")))

(: SCENARIO 4: Not found anywhere :)
  else ("/controller/notfound.xqy", xdmp:log(xdmp:url-decode($doc-url)) )

