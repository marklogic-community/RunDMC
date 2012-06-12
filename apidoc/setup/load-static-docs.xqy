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
    for $file in $entries[dir:type eq 'file']
    let $path    := $file/dir:pathname,
        $uri     := concat("/pubs/", $api:version, translate(substring-after($path, $pubs-dir),"\","/")),
        $is-html := ends-with($uri,'.html'),

        (: If the document is HTML, then read it as text :)
        $doc := if ($is-html) then xdmp:document-get($path, <options xmlns="xdmp:document-get"><format>text</format><encoding>auto</encoding></options>)
                              else xdmp:document-get($path, <options xmlns="xdmp:document-get">                     <encoding>auto</encoding></options>),

        (: Exclude these HTML documents from the search corpus (search the Tidy'd XHTML instead; see below) :)
        $collection := if ($is-html) then "hide-from-search"
                                     else ()
    return
    (
      xdmp:document-insert($uri, $doc, (), $collection),
      xdmp:log(concat("Loading ",$path," to ",$uri)),

      (: If the document is HTML, then store an additional copy, converted to XHTML using Tidy;
         this is using the same mechanism as the CPF "convert-html" action, except
         that this is done synchronously. This XHTML copy is what's used for search, snippeting, etc. :)
      if ($is-html)
      then
        let $tidy-options := <options xmlns="xdmp:tidy">
                               <input-encoding>utf8</input-encoding>
                               <output-encoding>utf8</output-encoding>
                               <clean>true</clean>
                             </options>,
            $xhtml := xhtml:clean(xdmp:tidy($doc, $tidy-options)[2]),
            $xhtml-uri := replace($uri, "\.html$", "_html.xhtml")
        return
        (
          xdmp:document-insert($xhtml-uri, $xhtml),
          xdmp:log(concat("Tidying ",$path," to ",$xhtml-uri))
        )
      else ()
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
