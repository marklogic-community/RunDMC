xquery version "1.0-ml";

import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "/apidoc/setup/raw-docs-access.xqy";

import module namespace u="http://marklogic.com/rundmc/util"
  at "/lib/util-2.xqy";

declare variable $srcdir  := xdmp:get-request-field("srcdir");
declare variable $version := xdmp:get-request-field("version"); (: e.g., 4.1 :)
declare variable $rawdir  := fn:concat($srcdir, "/pubs/raw");

declare variable $legal-versions  := u:get-doc("/config/server-versions.xml")/*/version/@number;

(: Recursively load all files, retaining the subdir structure :)
declare function local:load-docs($dir) {
  let $entries := xdmp:filesystem-directory($dir)/dir:entry return
  (
    (: Load files in this directory :)
    for $file in $entries[dir:type eq 'file']
    let $path := $file/dir:pathname
    let $uri  := concat(
      "/", $version,
      translate(substring-after($path, $rawdir),"\","/"))
    return (
      raw:invoke-function(
        function() {
          xdmp:log(
            text { '[load-raw-docs.xqy]', $path, '=>', $uri },
            'fine'),
          xdmp:document-insert($uri, xdmp:document-get($path)),
          xdmp:commit() },
        true()),
      xdmp:log(
        text { "[apidoc/setup/load-raw-docs.xqy]", $path, "to", $uri },
        'debug')),

    (: Process sub-directories :)
    for $subdir in $entries[dir:type eq 'directory'] return
      local:load-docs($subdir/dir:pathname)
  )
};

if (not($version = $legal-versions)) then
  error((), "ERROR", concat("You must specify a 'version' param with one of these values: ",
                                  string-join($legal-versions,", ")))
else
  (
    local:load-docs($rawdir),
    "Documents loaded. See log for details."
  )
