xquery version "1.0-ml";

import module namespace api = "http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

import module namespace setup = "http://marklogic.com/rundmc/api/setup"
       at "common.xqy";

import module namespace u="http://marklogic.com/rundmc/util"
       at "../../lib/util-2.xqy";

import module namespace raw = "http://marklogic.com/rundmc/raw-docs-access"
       at "raw-docs-access.xqy";

import module namespace xhtml="http://marklogic.com/cpf/xhtml"
   at "/MarkLogic/conversion/xhtml.xqy";

declare variable $config := u:get-doc("/apidoc/config/static-docs.xml")/static-docs;
declare variable $subdirs-to-load            := $config/include/string(.);

declare variable $src-dir  := xdmp:get-request-field("staticdir");
declare variable $pubs-dir := concat($src-dir,'/pubs');
(:
declare variable $version-dir                := $config/version[@number eq $api:version]/@src-dir/string(.);
:)


declare function local:rewrite-uri($uri) {
       if (starts-with($uri,"/javaclient")) then replace($uri,"/javaclient/javadoc/", "/javadoc/client/")
  else if (starts-with($uri,"/javadoc/"))   then replace($uri,"/javadoc/","/javadoc/xcc/")
  else if (starts-with($uri,"/dotnet/"))    then replace($uri,"/dotnet/",  "/dotnet/xcc/")

  (: ASSUMPTION: the java docs don't include any PDFs :)
  else if (ends-with($uri,".pdf"))          then local:pdf-uri($uri)

  (: ASSUMPTION: if it's not PDF and it doesn't start with "/dotnet/", then it's java :)
                                            else concat("/javadoc", replace($uri,"/javadoc","")) (: Move "/javadoc" to the beginning of the URL :)
};

declare function local:pdf-uri($uri) {
  let $pdf-name      := replace($uri, ".*/(.*).pdf", "$1"),
      $guide-configs := u:get-doc("/apidoc/config/document-list.xml")//guide,
      $url-name      := $guide-configs[(@pdf-name,@source-name)[1] eq $pdf-name]/@url-name
  return
  (
    if (not($url-name)) then error(xs:QName("ERROR"), concat("The configuration for ",$uri," is missing in /apidoc/config/document-list.xml")) else (),
    concat("/guide/",$url-name,".pdf")
  )
};

(: Recursively load all files :)
declare function local:load-pubs-docs($dir) {
  let $entries := xdmp:filesystem-directory($dir)/dir:entry return
  (
    (: Load files in this directory :)
    for $file in $entries[dir:type eq 'file']
    let $path    := $file/dir:pathname,
        $uri     := concat("/apidoc/", $api:version, local:rewrite-uri(translate(substring-after($path,$pubs-dir),"\","/"))),

        $is-html := ends-with($uri,'.html'),
        $is-jdoc := contains($uri,'/javadoc/') and $is-html,

        (: If the document is JavaDoc HTML, then read it as text; if it's other HTML, repair it as XML (.NET docs) :)
        $doc := if ($is-jdoc) then xdmp:document-get($path, <options xmlns="xdmp:document-get"><format>text</format><encoding>auto</encoding></options>)
           else if ($is-html) then
                              try{ xdmp:document-get($path, <options xmlns="xdmp:document-get"><format>xml</format><repair>full</repair><encoding>UTF-8</encoding></options>) }
                        catch($e){ if ($e/*:code eq 'XDMP-DOCUTF8SEQ') then
                                   xdmp:document-get($path, <options xmlns="xdmp:document-get"><format>xml</format><repair>full</repair><encoding>ISO-8859-1</encoding></options>)
                                   else error((),"Load error", xdmp:quote($e))
                                 }
           else                    xdmp:document-get($path, <options xmlns="xdmp:document-get"><encoding>auto</encoding></options>), (: Otherwise, just load the document normally :)

        (: Exclude these HTML documents from the search corpus (search the Tidy'd XHTML instead; see below) :)
        $collection := if ($is-jdoc) then "hide-from-search"
                                     else ()
    return
    (
      xdmp:document-insert($uri, $doc, xdmp:default-permissions(), $collection),
      xdmp:log(concat("Loading ",$path," to ",$uri)),

      (: If the document is HTML, then store an additional copy, converted to XHTML using Tidy;
         this is using the same mechanism as the CPF "convert-html" action, except
         that this is done synchronously. This XHTML copy is what's used for search, snippeting, etc. :)
      if ($is-jdoc)
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

let $zip-file-name := concat(tokenize($src-dir,"/")[last()],".zip"),
    $zip-file-path := concat($src-dir,"/",$zip-file-name),
    $zip-file      := xdmp:document-get($zip-file-path),
    $zip-file-uri  := concat("/apidoc/",$zip-file-name)
return
(
  xdmp:log(concat("Loading ",$zip-file-name," to ",$zip-file-uri)),
  xdmp:document-insert($zip-file-uri, $zip-file)
),

xdmp:log("Done.")
