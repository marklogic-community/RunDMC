xquery version "1.0-ml";

import module namespace u = "http://marklogic.com/rundmc/util"
       at "../../lib/util-2.xqy";

declare namespace dir = "http://marklogic.com/xdmp/directory";

declare variable $srcdir  := xdmp:get-request-field("srcdir");
declare variable $version := xdmp:get-request-field("version"); (: e.g., 4.1 :)

declare variable $database-name := u:get-doc("/apidoc/config/source-database.xml")/string(.);

declare variable $legal-versions  := u:get-doc("/config/server-versions.xml")/*/version/@number;

(: Recursively load all files, retaining the subdir structure :)
declare function local:load-docs($dir) {
  let $entries := xdmp:filesystem-directory($dir)/dir:entry return
  (
    (: Load files in this directory :)
    for $file in $entries[dir:type eq 'file'] return
      let $path := $file/dir:pathname
      let $uri  := concat("/", $version, translate(substring-after($path, $srcdir),"\","/")) return
      (
        xdmp:eval(
          concat('xdmp:document-insert("',$uri,'", xdmp:document-get("',$path,'"))'),
          (),
          <options xmlns="xdmp:eval">
            <database>{xdmp:database($database-name)}</database>
          </options>),
        xdmp:log(concat("Loading ",$path," to ",$uri))
      ),

    (: Process sub-directories :)
    for $subdir in $entries[dir:type eq 'directory'] return
      local:load-docs($subdir/dir:pathname)
  )
};

if (not($version = $legal-versions)) then
  error(xs:QName("ERROR"), concat("You must specify a 'version' param with one of these values: ",
                                  string-join($legal-versions,", ")))
else 
  (
    local:load-docs($srcdir),
    "Documents loaded. See log for details."
  )
