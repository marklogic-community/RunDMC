xquery version "1.0-ml";

import module namespace u = "http://marklogic.com/rundmc/util" at "../../lib/util-2.xqy";

declare variable $path            := xdmp:get-request-path();
declare variable $orig-url        := xdmp:get-request-url();
declare variable $query-string    := substring-after($orig-url, '?');

declare variable $default-version := fn:string(u:get-doc("/apidoc/config/server-versions.xml")/*/version[@default eq 'yes']/@number);

declare variable $version-specified := if (matches($path, '^/[0-9]\.[0-9]$')) then substring-after($path,'/')
                                  else if (matches($path, '^/[0-9]\.[0-9]/')) then substring-before(substring-after($path,'/'),'/')
                                  else "";

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


(: SCENARIO 1: External redirect :)
  (: Externally redirect paths with trailing slashes :)
  if (($path ne '/') and ends-with($path, '/')) then
      concat('/controller/redirect.xqy?path=', substring($path, 1, string-length($path) - 1),
              if ($query-string) then concat('?', $query-string) else ())


(: SCENARIO 2: Internal rewrite :)

  (: SCENARIO 2A: Serve content from database :)
    (: Respond with DB contents for /media :)
    else if (starts-with($path, '/media/')) then 
      concat("/controller/get-db-file.xqy?uri=", $path)

    (: Ignore URLs starting with "/private/" :)
    else if (starts-with($path,'/private/')) then
      "/controller/notfound.xqy"

    (: Root request: "/" means "index.xml" inside the default version's directory :)
    else if ($path eq '/') then 
      local:transform($root-doc-url)

    (: If the version is specified in the path, then proceed accordingly :)
    else if ($version-specified) then

        (: If the version-specific doc path requested, e.g., /4.2/foo, is available, then serve it :)
        if (doc-available($doc-url)) then
          local:transform($doc-url)

        (: Otherwise, we assume it must be a version-specific root request, e.g., /4.2 :)
        else local:transform($path-plus-index)

    (: Otherwise, look in the default version directory :)
    else if (doc-available($doc-url-default)) then
      local:transform($doc-url-default)


  (: SCENARIO 2B: Serve content from file system :)
    (: Control the visibility of files in the code base :)
    else if (not(u:get-doc("/controller/access.xml")/paths/prefix[starts-with($path,.)])) then
        "/controller/notfound.xqy"

    (: Remove version from the URL for versioned assets :)
    else if (matches($path, '^/(js|css|images)/v-[0-9]*/.*'))  then 
      replace($path, '/v-[0-9]*', '')

    (: Static files or 404 :)
    else
        $orig-url
