xquery version "1.0-ml";

import module namespace api = "http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

import module namespace setup = "http://marklogic.com/rundmc/api/setup"
       at "common.xqy";

import module namespace u="http://marklogic.com/rundmc/util"
       at "../../lib/util-2.xqy";

import module namespace xhtml="http://marklogic.com/cpf/xhtml"
   at "/MarkLogic/conversion/xhtml.xqy";

declare variable $config := u:get-doc("/apidoc/config/static-docs.xml")/static-docs;

declare variable $base-dir                   := xdmp:get-request-field("basedir");
declare variable $version-dir                := $config/version[@number eq $api:version]/@src-dir/string(.);
declare variable $pubs-dir                   := concat($base-dir, $version-dir,'/pubs');
declare variable $subdirs-to-load            := $config/include/string(.);

(: Recursively load all files :)
declare function local:load-pubs-docs($dir) {
  let $entries := xdmp:filesystem-directory($dir)/dir:entry return
  (
    (: Load files in this directory :)
    for $file in $entries[dir:type eq 'file'] return
      let $path        := $file/dir:pathname,
          $uri         := concat("/pubs/", $api:version, translate(substring-after($path, $pubs-dir),"\","/"))
      return
      (
        (: If the document is HTML, then convert it to XHTML using Tidy;
           this is using the same mechanism as the CPF "convert-html" action, except
           that this is done synchronously and without changing the URI of the document. :)
        let $doc :=
          if (ends-with($uri,'.html') or
              ends-with($uri,'.htm'))
          then 
            let $tidy-options :=
              <options xmlns="xdmp:tidy">
                 <input-encoding>utf8</input-encoding>
                 <output-encoding>utf8</output-encoding>
                 <clean>true</clean>
              </options>
            let $input := xdmp:document-get($path, <options xmlns="xdmp:document-get"><format>text</format><encoding>auto</encoding></options>)
            return
              xhtml:clean(xdmp:tidy($input, $tidy-options)[2])

          else xdmp:document-get($path, <options xmlns="xdmp:document-get"><encoding>auto</encoding></options>)

        return
        (
          xdmp:document-insert($uri, $doc),
          xdmp:log(concat("Loading ",$path," to ",$uri))
        )
      ),

    (: Process sub-directories :)
    for $subdir in $entries[dir:type eq 'directory'] return
      local:load-pubs-docs($subdir/dir:pathname)
  )
};

$setup:errorCheck,

(: TODO: Load only the included directories :)
for $included-dir in xdmp:filesystem-directory($pubs-dir)/dir:entry[dir:type eq 'directory']
                                                                   [dir:filename = $subdirs-to-load]
                                                         /dir:pathname
                                                         /string(.)
return
(
  xdmp:log(concat("Loading static docs from: ", $included-dir)),
  local:load-pubs-docs($included-dir)
),

xdmp:log("Done.")
