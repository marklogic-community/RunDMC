xquery version "1.0-ml";
(: setup functions. :)

module namespace stp="http://marklogic.com/rundmc/api/setup" ;

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace u="http://marklogic.com/rundmc/util"
  at "/lib/util-2.xqy";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";
import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "raw-docs-access.xqy";
import module namespace toc="http://marklogic.com/rundmc/api/toc"
  at "toc.xqm";

import module namespace xhtml="http://marklogic.com/cpf/xhtml"
  at "/MarkLogic/conversion/xhtml.xqy";

declare namespace apidoc="http://marklogic.com/xdmp/apidoc";

declare namespace xh="http://www.w3.org/1999/xhtml" ;

declare variable $DEBUG := false() ;

declare variable $LEGAL-VERSIONS as xs:string+ := u:get-doc(
  "/apidoc/config/server-versions.xml")/*/version/@number ;

declare variable $RAW-PAT := '^MarkLogic_\d+_pubs/pubs/(raw)/(.+)$' ;

declare variable $REST-LIBS := ('manage', 'rest-client') ;

(: TODO skip for standalone?
 : Right now that works by looking at server-name,
 : which introduces another HTTP dependency.
 :)
declare variable $GOOGLE-TAGMANAGER as node()* := (
<!-- Google Tag Manager -->,
<noscript><iframe src="//www.googletagmanager.com/ns.html?id=GTM-MBC6N2"
height="0" width="0" style="display:none;visibility:hidden"></iframe></noscript>,
<script><![CDATA[if ( document.location.hostname == 'docs.marklogic.com') {
(function(w,d,s,l,i){w[l]=w[l]||[];w[l].push({'gtm.start':
new Date().getTime(),event:'gtm.js'});var f=d.getElementsByTagName(s)[0],
j=d.createElement(s),dl=l!='dataLayer'?'&l='+l:'';j.async=true;j.src=
'//www.googletagmanager.com/gtm.js?id='+i+dl;f.parentNode.insertBefore(j,f);
})(window,document,'script','dataLayer','GTM-MBC6N2'); } ]]> </script>,
<!-- End Google Tag Manager -->
) ;

declare function stp:log(
  $label as xs:string,
  $list as xs:anyAtomicType*,
  $level as xs:string)
as empty-sequence()
{
  xdmp:log(text { '[apidoc/setup/'||$label||']', $list }, $level)
};

declare function stp:fine(
  $label as xs:string,
  $list as xs:anyAtomicType*)
as empty-sequence()
{
  if ($DEBUG) then stp:log($label, $list, 'fine')
  else stp:error('BADDEBUG', 'Modify the caller to check $stp:DEBUG')
};

declare function stp:debug(
  $label as xs:string,
  $list as xs:anyAtomicType*)
as empty-sequence()
{
  if ($DEBUG) then stp:log($label, $list, 'debug')
  else stp:error('BADDEBUG', 'Modify the caller to check $stp:DEBUG')
};

declare function stp:info(
  $label as xs:string,
  $list as xs:anyAtomicType*)
as empty-sequence()
{
  stp:log($label, $list, 'info')
};

declare function stp:warning(
  $label as xs:string,
  $list as xs:anyAtomicType*)
as empty-sequence()
{
  stp:log($label, $list, 'warning')
};

declare function stp:error(
  $code as xs:string,
  $items as item()*)
as empty-sequence()
{
  error((), 'APIDOC-'||$code, $items)
};

declare function stp:assert-timestamp()
as empty-sequence()
{
  if (xdmp:request-timestamp()) then ()
  else stp:error(
    'NOTIMESTAMP',
    text {
      'Request should be read-only but has no timestamp.',
      'Check the code path for update functions.' })
};

declare function stp:element-rewrite(
  $e as element(),
  $new as node()*)
as element()
{
  element { node-name($e) } {
    $e/@*,
    $e/node(),
    $new }
};

(: Prune more? This code seems to expect head//head or body//body. :)
declare function stp:static-add-scripts($n as node())
  as node()*
{
  typeswitch($n)
  case document-node() return document { stp:static-add-scripts($n/node()) }
  case element(body) return stp:element-rewrite($n, $GOOGLE-TAGMANAGER)
  case element(BODY) return stp:element-rewrite($n, $GOOGLE-TAGMANAGER)
  (: Any other element may have head or body children. :)
  case element() return element {fn:node-name($n)} {
    $n/@*,
    stp:static-add-scripts($n/node()) }
  (: Text, binary, comments, etc. :)
  default return $n
};

declare function stp:pdf-uri(
  $document-list as element(apidoc:docs),
  $uri as xs:string)
as xs:string?
{
  let $pdf-name := replace($uri, ".*/(.*).pdf", "$1")
  let $url-name as xs:string := $document-list//apidoc:guide[
    (@pdf-name, @source-name)[1] eq $pdf-name]/@url-name
  return concat("/guide/", $url-name, ".pdf")
};

(: TODO Make this behavior configurable via document-list. :)
declare function stp:static-uri-rewrite(
  $document-list as element(apidoc:docs),
  $uri as xs:string)
as xs:string
{
  if (starts-with($uri, "/c++/")) then replace(
    $uri, "/c\+\+/", "/cpp/udf/")
  else if (starts-with($uri, "/dotnet/")) then replace(
    $uri, "/dotnet/",  "/dotnet/xcc/")
  else if (starts-with($uri, "/hadoop/")) then replace(
    $uri, "/hadoop/javadoc/", "/javadoc/hadoop/")
  else if (starts-with($uri, "/javaclient")) then replace(
    $uri, "/javaclient/javadoc/", "/javadoc/client/")
  (: Move "/javadoc" to the beginning of the URI :)
  else if (starts-with($uri, "/javadoc/")) then replace(
    $uri, "/javadoc/", "/javadoc/xcc/")
  else if (starts-with($uri, "/nodeclient/jsdoc/")) then replace(
    $uri, "/nodeclient/jsdoc/", "/jsdoc/")

  (: ASSUMPTION: the java docs don't include any PDFs :)
  else if (ends-with($uri, ".pdf")) then stp:pdf-uri($document-list, $uri)

  (: By default, don't change the URI (e.g., for C++ docs) :)
  else stp:error("UNEXPECTED", ('path', $uri))
};

declare function stp:fix-guide-names(
  $version as xs:string,
  $href as xs:string,
  $guides as element(apidoc:guide)*)
as xs:string
{
  if (empty($guides)) then $href
  else stp:fix-guide-names(
    $version,
    replace($href, $guides[1]/@source-name, $guides[1]/@url-name),
    subsequence($guides, 2))
};

(: Change guide urls according to the data in the document-list. :)
declare function stp:fix-guide-names(
  $version as xs:string,
  $href as xs:string)
as xs:string
{
  stp:fix-guide-names(
    $version, $href,
    api:document-list(
      $version)/apidoc:group/apidoc:entry/apidoc:guide[
      not(xs:boolean(@duplicate))][
      contains($href, @source-name)][
      @url-name ne @source-name])
};

declare function stp:function-children(
  $function as element(apidoc:function))
as element(apidoc:function)*
{
  let $lib as xs:string := $function/@lib
  let $name as xs:string := $function/@name
  let $verb as xs:string? := $function/@http-verb
  return $function/../apidoc:function[
    @name eq $name][
    @lib eq $lib][
    not($verb) or @http-verb eq $verb]
};

(: If a function has an equivalent in another mode,
 : link to it.
 :)
declare function stp:function-link(
  $version as xs:string,
  $mode as xs:string,
  $function as element(apidoc:function))
as element(api:function-link)?
{
  if (($mode eq $api:MODE-JAVASCRIPT and number($version) lt 8.0)
    or not(api:function-appears-in-mode($function, $mode))) then ()
  else element api:function-link {
    attribute mode { $mode },
    attribute fullname { api:fixup-fullname($function, $mode) },
    api:internal-uri($version, api:external-uri($function, $mode)) }
};

declare function stp:function-links(
  $version as xs:string,
  $mode as xs:string,
  $function as element(apidoc:function))
as element(api:function-link)*
{
  switch($mode)
  (: REST endpoints never have equivalents in other modes. :)
  case $api:MODE-REST return ()
  (: JavaScript functions usually have an XPath equivalent. :)
  case $api:MODE-JAVASCRIPT return stp:function-link(
    $version, $api:MODE-XPATH, $function)
  (: XPath functions sometimes have a JavaScript equivalent. :)
  case $api:MODE-XPATH return stp:function-link(
    $version, $api:MODE-JAVASCRIPT, $function)
  default return stp:error('UNEXPECTED', $mode)
};

declare function stp:function-extract(
  $version as xs:string,
  $function as element(apidoc:function),
  $uris-seen as map:map)
as element(api:function-page)*
{
  if ($function/@hidden/xs:boolean(.)) then () else
  (: These are raw functions, so only javascript will have a mode. :)
  let $mode as xs:string := (
    if ($function/@mode) then $function/@mode
    else if (starts-with($function/@name, '/')) then $api:MODE-REST
    else $api:MODE-XPATH)[1]
  let $external-uri := api:external-uri($function, $mode)
  let $internal-uri := api:internal-uri($version, $external-uri)
  let $seen := map:contains($uris-seen, $internal-uri)
  let $children := stp:function-children($function)
  let $_ := (
    if ($mode = ($api:MODE-JAVASCRIPT, $api:MODE-XPATH)
      or count($children) eq 1) then ()
    else stp:error(
      'UNEXPECTED', (count($children), xdmp:describe($children))))
  let $_ := (
    if (api:has-mode-class($function, $mode)) then ()
    else stp:error('NOTINMODE', ($mode, xdmp:quote($function))))
  (: Allow no more than one matching return type.
   : Exclusion of non-matching return types happens in fixup-element.
   :)
  let $_ := zero-or-one(
    $function/apidoc:return[ api:has-mode-class(., $mode) ])
  let $_ := if (not($DEBUG)) then () else stp:debug(
    'stp:function-extract',
    ('mode', $mode,
      'external', $external-uri,
      'internal', $internal-uri,
      'children', count($children),
      'seen', $seen))
  (: This wrapper is necessary because the *:polygon() functions
   : are each (dubiously) documented as two separate functions so
   : that raises the possibility of needing to include two different
   : api:function elements in the same page.
   : Likewise process all functions having the same name in the same lib.
   : However this means that the resulting xml:base values may conflict,
   : so we have to check $uris-seen.
   :)
  let $_ := if (not($seen)) then () else stp:info(
    'Skipping duplicate function', $internal-uri)
  where not($seen)
  return element api:function-page {
    attribute xml:base { $internal-uri },
    attribute generated { current-dateTime() },
    attribute mode { $mode },
    map:put($uris-seen, $internal-uri, $internal-uri),
    (: For word search purposes. :)
    element api:function-name { api:fixup-fullname($function, $mode) },
    stp:function-links($version, $mode, $function),
    stp:fixup($version, $children, $mode) }
};

(: Extract functions from a raw module page. :)
declare function stp:function-docs(
  $version as xs:string,
  $doc as document-node())
as element(api:function-page)*
{
  stp:function-extract(
    $version,
    (api:module-extractable-functions(
      $doc/apidoc:module, ($api:MODE-REST, $api:MODE-XPATH)),
      (: create JavaScript function pages :)
      if (number($version) lt 8) then ()
      else api:module-extractable-functions(
        $doc/apidoc:module, $api:MODE-JAVASCRIPT)),
    map:map())
};

declare function stp:function-docs(
  $version as xs:string)
as empty-sequence()
{
  stp:info('stp:function-docs', ('starting', $version)),
  for $doc in raw:api-docs($version)
  let $_ := if (not($DEBUG)) then () else stp:debug(
    "stp:function-docs", ('starting', xdmp:describe($doc)))
  (: Some stub pages may not have any extractable functions. :)
  let $extracted as node()* := stp:function-docs($version, $doc)
  for $func as element(api:function-page) in $extracted
  let $uri := base-uri($func)
  let $_ := (
    (: Detect bad functions, but allow stubs. :)
    if ($func/api:function/@name/string()[.]
      or not($func/api:function)) then ()
    else stp:error('NONAME', ($uri, xdmp:quote($func))))
  let $_ := if (not($DEBUG)) then () else stp:debug(
    "stp:function-docs",
    ("inserting", xdmp:describe($doc), 'at', $uri))
  return xdmp:document-insert($uri, $func)
  ,
  stp:info("stp:function-docs", xdmp:elapsed-time())
};

declare function stp:search-results-page-insert()
as empty-sequence()
{
  stp:info('stp:search-results-page-insert', 'starting'),
  xdmp:document-insert(
    "/apidoc/do-search.xml",
    <ml:page xmlns:ml="http://developer.marklogic.com/site/internal"
    disable-comments="yes" status="Published"
    xmlns="http://www.w3.org/1999/xhtml" hide-from-search="yes">
      <h1>Search Results</h1>
      <ml:search-results/>
    </ml:page>),
  stp:info('stp:search-results-page-insert', ('ok', xdmp:elapsed-time()))
};

declare function stp:zip-jdoc-get(
  $zip as binary(),
  $path as xs:string)
as document-node()
{
  (: Don't tidy index.html, because tidy
   : throws away the frameset with javadoc
   : and closes the script tags with jsdoc.
   :)
  if (ends-with($path, '/index.html')) then xdmp:zip-get($zip, $path)
  (: Read it as text and tidy, because the HTML may be broken. :)
  else xdmp:tidy(
    xdmp:zip-get(
      $zip,
      $path,
      <options xmlns="xdmp:zip-get">
        <format>text</format>
        <encoding>auto</encoding>
      </options>
    ),
    <options xmlns="xdmp:tidy">
      <input-encoding>utf8</input-encoding>
      <output-encoding>utf8</output-encoding>
      <output-xhtml>yes</output-xhtml>
    </options>
    )[2]
};

declare function stp:zip-mangled-html-get(
  $zip as binary(),
  $path as xs:string)
as document-node()
{
  try {
    if (not($DEBUG)) then () else  stp:fine(
      'stp:zip-mangled-html-get', ('trying unquote for', $path)),
    let $unparsed as xs:string := xdmp:zip-get(
      $zip,
      $path,
      <options xmlns="xdmp:zip-get"
      ><format>text</format></options>)
    let $replaced := replace($unparsed, '"class="', '" class="')
    return xdmp:unquote($replaced, "", "repair-full") }
  catch($e) {
    stp:info(
      'stp:zip-mangled-html-get',
      ("loading", $path, "with encoding=auto because", $e/error:message)),
    xdmp:zip-get(
      $zip,
      $path,
      <options xmlns="xdmp:zip-get"
      ><encoding>auto</encoding></options>) }
};

declare function stp:zip-html-get(
  $zip as binary(),
  $path as xs:string)
as document-node()
{
  try {
    if (not($DEBUG)) then () else stp:fine(
      'stp:zip-html-get',
      ("trying html as XML UTF8")),
    xdmp:zip-get(
      $zip,
      $path,
      <options xmlns="xdmp:zip-get">
        <format>xml</format>
        <repair>full</repair>
        <encoding>UTF-8</encoding>
      </options>
      ) }
  catch($e) {
    if ($e/error:code ne 'XDMP-DOCUTF8SEQ') then xdmp:rethrow()
    else xdmp:zip-get(
      $zip,
      $path,
      <options xmlns="xdmp:zip-get">
        <format>xml</format>
        <repair>full</repair>
        <encoding>ISO-8859-1</encoding>
      </options>
      ) }
};

(: Load a static file from a zip binary node. :)
declare function stp:zip-static-file-get(
  $zip as binary(),
  $path as xs:string,
  $is-binary as xs:boolean,
  $is-html as xs:boolean,
  $is-jdoc as xs:boolean,
  $is-mangled-html as xs:boolean)
as document-node()
{
  if (not($DEBUG)) then () else stp:fine(
    "stp:zip-static-file-get",
    (xdmp:describe($zip), 'path', $path,
      'html', $is-html, 'jdoc', $is-jdoc,
      'mangled', $is-mangled-html)),
  (: Load binary without any options, to preserve integrity. :)
  if ($is-binary) then xdmp:zip-get($zip, $path)
  else if ($is-jdoc) then stp:zip-jdoc-get($zip, $path)
  (: Repair other HTML as XML, including .NET docs. :)
  else if ($is-mangled-html) then stp:zip-mangled-html-get($zip, $path)
  else if ($is-html) then stp:zip-html-get($zip, $path)
  (: Otherwise, just load the document with encoding=auto. :)
  else xdmp:zip-get(
    $zip, $path,
    <options xmlns="xdmp:zip-get"><encoding>auto</encoding></options>)
};

declare function stp:zip-static-file-insert(
  $doc as document-node(),
  $uri as xs:string,
  $is-hidden as xs:boolean,
  $is-jdoc as xs:boolean)
as empty-sequence()
{
  if (not($DEBUG)) then () else stp:debug(
    "stp:zip-static-file-insert",
    (xdmp:describe($doc), $uri, 'hidden', $is-hidden, 'jdoc', $is-jdoc)),
  xdmp:document-insert(
    $uri,
    stp:static-add-scripts($doc),
    xdmp:default-permissions(),
    (: Exclude these HTML and javascript documents from the search corpus
     : Instead search the XHTML after tidy - see below.
     :)
    "hide-from-search"[$is-hidden]),

  (: If the document is HTML, then store an additional copy,
   : converted to XHTML using Tidy.
   : This is using the same mechanism as the CPF "convert-html" action,
   : except that this is done synchronously. This XHTML copy is
   : used for search, snippeting, etc.
   :)
  if ($is-hidden or not($is-jdoc)) then () else (
    if (not($DEBUG)) then () else stp:fine(
      'stp:zip-static-file-insert',
      ($uri, "trying xdmp:tidy with xhtml:clean")),
    let $tidy-options := (
      <options xmlns="xdmp:tidy">
        <input-encoding>utf8</input-encoding>
        <output-encoding>utf8</output-encoding>
        <clean>true</clean>
      </options>
    )
    let $xhtml := try {
      xhtml:clean(xdmp:tidy($doc, $tidy-options)[2]) }
    catch($e) {
      stp:info(
        'stp:zip-static-file-insert',
        ("failed tidy conversion with", $e/error:code)),
      $doc }
    let $xhtml-uri := replace($uri, "\.html$", "_html.xhtml")
    let $_ := if (not($DEBUG)) then () else stp:fine(
      'stp:zip-static-file-insert', ('Tidying', $uri, 'to', $xhtml-uri))
    return xdmp:document-insert($xhtml-uri, stp:static-add-scripts($xhtml)))
};

declare function stp:zip-static-doc-insert(
  $version as xs:string,
  $zip as binary(),
  $document-list as element(apidoc:docs),
  $e as xs:string)
as empty-sequence()
{
  if (not($stp:DEBUG)) then () else stp:debug(
    "stp:zip-static-doc-insert",
    ($version, xdmp:describe($zip), xdmp:describe($document-list), $e)),
  let $is-binary := xdmp:uri-content-type($e) ! (
    not(starts-with(., 'text/'))
    and not(. = ('application/javascript')))
  let $is-html := ends-with($e, '.html')
  let $is-jdoc := $is-html and matches($e, '/(javadoc|jsdoc)/')
  let $uri := concat(
    "/apidoc/", $version,
    stp:static-uri-rewrite(
      $document-list,
      '/'||substring-after($e, '_pubs/pubs/')))
  let $is-hidden := $is-jdoc or matches($e, '\.(css|js)$')
  let $is-mangled-html := ends-with($e, '-members.html')
  let $doc := stp:zip-static-file-get(
    $zip, $e, $is-binary, $is-html, $is-jdoc, $is-mangled-html)
  return stp:zip-static-file-insert($doc, $uri, $is-hidden, $is-jdoc)
};

declare function stp:zip-static-docs-insert(
  $version as xs:string,
  $zip-path as xs:string,
  $zip as binary(),
  $subdirs-to-load as xs:string+,
  $document-list as element(apidoc:docs),
  $document-list-from-zip as xs:boolean)
as empty-sequence()
{
  if (not($stp:DEBUG)) then () else stp:debug(
    "stp:zip-static-docs-insert",
    ($version, $zip-path, xdmp:describe($subdirs-to-load),
      xdmp:describe($document-list), $document-list-from-zip)),

  (: Load document-list.xml if it came from the zip.
   : Otherwise this is probably a dev environment so keep using the filesystem.
   : If we load it, do so as a hidden document.
   :)
  if (not($document-list-from-zip)) then ()
  else stp:zip-static-file-insert(
    $document-list/root(),
    concat('/apidoc/', $version, '/document-list.xml'),
    true(), false()),

  (: Ignore any directory entries,
   : and any file entries that do not match the included subdirs.
   :)
  stp:zip-static-doc-insert(
    $version, $zip, $document-list,
    xdmp:zip-manifest($zip)/*[
      contains(., '_pubs/pubs/') ][
      not(ends-with(., '/')) ][
      some $path in $subdirs-to-load
      satisfies contains(., $path) ])
};

declare function stp:zip-static-docs-insert(
  $version as xs:string,
  $zip-path as xs:string,
  $zip as binary(),
  $subdirs-to-load as xs:string+)
as empty-sequence()
{
  if (not($stp:DEBUG)) then () else stp:debug(
    "stp:zip-static-docs-insert",
    ($version, $zip-path, xdmp:describe($subdirs-to-load, 32))),

  (: Load the document-list XML manifest if present.
   : Older zips may not include it.
   :
   : If the document-list is in the zip, get it directly.
   : Otherwise fall back on the filesystem copy.
   :)
  let $document-list as element()? := xdmp:zip-get(
    $zip,
    xdmp:zip-manifest($zip)/*[
      ends-with(., '_pubs/pubs/document-list.xml')])/*
  let $document-list-from-zip := exists($document-list)
  let $document-list as element(apidoc:docs) := (
    if ($document-list) then $document-list else u:get-doc(
      '/apidoc/config/'||$version||'/document-list.xml')/apidoc:docs)
  return stp:zip-static-docs-insert(
    $version, $zip-path, $zip,
    $subdirs-to-load, $document-list, $document-list-from-zip),

  (: Load the zip itself, to support downloads. :)
  let $zip-uri := concat(
    "/apidoc/", tokenize($zip-path, '/')[last()])
  let $_ := stp:info(
    "stp:zip-static-docs-insert",
    ("zip", $zip-path, "as", $zip-uri))
  return xdmp:document-insert($zip-uri, $zip)
  ,

  stp:info(
    'stp:zip-static-docs-insert',
    ("Loaded static docs in", xdmp:elapsed-time()))
};

declare function stp:zip-static-docs-insert(
  $version as xs:string,
  $zip-path as xs:string)
as empty-sequence()
{
  stp:zip-static-docs-insert(
    $version,
    $zip-path,
    xdmp:document-get($zip-path)/node(),
    (u:get-doc("/apidoc/config/static-docs.xml")/static-docs/include
      /concat('/pubs/', ., '/'))
    treat as xs:string+)
};

(: Delete all static docs for a version. :)
declare function stp:static-docs-delete($version as xs:string)
as empty-sequence()
{
  stp:info('stp:static-docs-delete', $version),
  let $dir := concat('/media/apidoc/', $version, '/')
  let $_ := xdmp:directory-delete($dir)
  let $_ := stp:info(
    'stp:static-docs-delete', ($version, $dir, 'ok', xdmp:elapsed-time()))
  return ()
};

(: Delete all raw docs for a version. :)
declare function stp:raw-delete($version as xs:string)
as empty-sequence()
{
  stp:info('stp:raw-delete', $version),
  raw:invoke-function(
    function() {
      xdmp:directory-delete(concat("/", $version, "/")),
      xdmp:commit() },
    true())
};

(: Delete all api docs for a version. :)
declare function stp:api-docs-delete($version as xs:string)
as empty-sequence()
{
  stp:info('stp:api-docs-delete', $version),
  let $dir := api:version-dir($version)
  let $_ := xdmp:directory-delete($dir)
  let $_ := stp:info(
    'stp:api-docs-delete', ($version, $dir, 'ok', xdmp:elapsed-time()))
  return ()
};

(: TODO move to toc.xqm? :)
declare function stp:toc-docs-delete(
  $version as xs:string)
as empty-sequence()
{
  stp:info('stp:toc-docs-delete', $version),
  let $uri-toc := toc:directory-uri($version)
  let $_ := xdmp:directory-delete($uri-toc)
  let $uri-toc-location := api:toc-uri-location($version)
  let $_ := doc($uri-toc-location) ! xdmp:document-delete($uri-toc-location)
  let $_ := stp:info(
    'stp:toc-docs-delete',
    ($version, $uri-toc, $uri-toc-location, 'ok', xdmp:elapsed-time()))
  return ()
};

declare function stp:clean(
  $version as xs:string)
{
  stp:static-docs-delete($version),
  stp:api-docs-delete($version),
  stp:toc-docs-delete($version),
  if ($version ne $api:DEFAULT-VERSION) then ()
  else stp:toc-docs-delete('default')
};

declare function stp:node-rewrite-namespace(
  $n as node(),
  $ns as xs:string)
as node()
{
  typeswitch($n)
  case document-node() return document {
    stp:node-rewrite-namespace($n/node(), $ns) }
  case element() return element { QName($ns, local-name($n)) } {
    $n/@*,
    stp:node-rewrite-namespace($n/node(), $ns) }
  default return $n
};

declare function stp:node-to-xhtml(
  $n as node())
as node()
{
  stp:node-rewrite-namespace(
    $n, "http://www.w3.org/1999/xhtml")
};

(: The container ID comes from the nearest ancestor (or self)
 : that is marked as asynchronously loaded,
 : unless nothing above this level is marked as such,
 : in which case we use the nearest ID.
 :)
declare function stp:container-toc-section-id(
  $e as element(toc:node))
as xs:string
{
  $e/(
    ancestor-or-self::toc:node[@async/xs:boolean(.)][1],
    ancestor-or-self::toc:node[@id][1])[1]/@id
};

(: Input parent should be api:function-page. :)
declare function stp:list-entry(
  $function as element(api:function),
  $toc-node as element(toc:node))
as element(api:list-entry)
{
  if (not($DEBUG)) then () else stp:fine(
    'stp:list-entry',
    ('function', xdmp:describe($function),
      'toc', xdmp:describe($toc-node))),
  element api:list-entry {
    $toc-node/@href,
    element api:name {
      (: Special-case the cts accessor functions; they should be indented.
       : This handles XQuery and JavaScript naming conventions.
       :)
      if (not($function/@lib eq 'cts'
          and $toc-node/@display ! (
            contains(., '-query-')
            or substring-after(., 'Query')))) then ()
      else attribute indent { true() },

      (: Function name; prefer @list-page-display, if present :)
      ($toc-node/@list-page-display,
        $toc-node/@display)[1]/string() treat as xs:string },
    element api:description {
      (: Extracting the first line from the summary :)
      concat(
        substring-before($function/api:summary, '.'),
        '.') } }
};

declare function stp:list-page-functions(
  $version as xs:string,
  $uri as xs:string,
  $toc-node as element(toc:node))
as element(api:list-page)
{
  element api:list-page {
    attribute xml:base { $uri },
    attribute generated { current-dateTime() },
    attribute disable-comments { true() },
    attribute container-toc-section-id {
      stp:container-toc-section-id($toc-node) },
    $toc-node/@*,

    $toc-node/toc:title ! element api:title {
      @*,
      stp:node-to-xhtml(node()) },
    $toc-node/toc:intro ! element api:intro {
      @*,
      stp:node-to-xhtml(node()) },

    (: Make an entry for document pointed to by
     : each descendant leaf node with a type.
     : This ignores internal guide links, which have no type.
     :)
    for $leaf in $toc-node//toc:node[@type][not(toc:node)]
    (: For multiple *:polygon() functions, only list the first. :)
    let $href as xs:string := $leaf/@href
    let $_ := if (not($DEBUG)) then () else stp:fine(
      'stp:list-page-functions',
      ($uri, 'leaf', xdmp:describe($leaf),
        'type', $leaf/@type, 'href', $href))
    let $uri-leaf as xs:string := api:internal-uri($version, $href)
    let $root as document-node() := doc($uri-leaf)
    let $function as element() := ($root/api:function-page/api:function)[1]
    order by $leaf/@list-page-display, $leaf/@display
    return stp:list-entry($function, $leaf) }
};

declare function stp:list-page-help-items(
  $toc-node as element(toc:node))
as element(xh:li)*
{
  (: TODO removed some weird-looking dedup code here. Did it matter? :)
  for $n in $toc-node//toc:node[@href]
  let $href as xs:string := $n/@href
  let $title as xs:string := $n/toc:title
  order by $title
  return <li xmlns="http://www.w3.org/1999/xhtml">
  {
    element a {
      attribute href { $href },
      $title }
  }
  </li>
};

declare function stp:list-page-help(
  $uri as xs:string,
  $toc-node as element(toc:node))
as element(api:help-page)
{
  element api:help-page {
    attribute xml:base { $uri },
    attribute disable-comments { true() },
    attribute container-toc-section-id {
      stp:container-toc-section-id($toc-node) },
    $toc-node/@*,
    element api:title { $toc-node/toc:title/node() },
    (: Help index page is at the top :)
    element api:content {
      if (not($toc-node/toc:content/@auto-help-list))
      then stp:node-to-xhtml($toc-node/toc:content/node())
      else <div xmlns="http://www.w3.org/1999/xhtml">
      <p>
      The following is an alphabetical list of Admin Interface help pages:
      </p>
      <ul>{ stp:list-page-help-items($toc-node) }</ul>
      </div>
    }
  }
};

declare function stp:list-page-root-guides(
  $toc as element(toc:root),
  $title-aliases as element(aliases),
  $group as element(apidoc:group))
as node()*
{
  let $document-list-guide-entries as node()+ := $group/apidoc:entry
  for $section at $x in (
    $toc/toc:node[@id eq 'guides']/toc:node treat as node()+)
  let $document-list-guides as node()+ := (
    $document-list-guide-entries[$x]/apidoc:guide[
      not(@excluded/xs:boolean(.))])
  return <div xmlns="http://www.w3.org/1999/xhtml">
  {
    attribute class { 'doclist-guide-section' },
    element h3 {
      attribute class { 'docs-page' },
      $section/@display/string() },
    element ul {
      attribute class { 'doclist' },
      for $guide at $y in (
        $section/toc:node[@type eq 'guide'] treat as node()+)
      let $document-list-guide := $document-list-guides[$y]
      let $display as xs:string := lower-case(
        normalize-space($guide/@display))
      (: Facilitate automatic link creation at render time. :)
      let $alias as xs:string? := $title-aliases/guide/alias[
        normalize-space(lower-case(.)) = $display]
      let $body as node()+ := $document-list-guide/node()
      let $_ := if (not($DEBUG)) then () else stp:fine(
        'stp:list-page-root',
        (xdmp:describe($guide), $display, $alias))
      return element li {
        (: At display time page.xsl will rewrite these links a bit. :)
        element a {
          attribute class { 'guide-link' },
          $guide/@href,
          if ($alias) then $alias
          else $guide/@display/string() },
        (: Pull guide description text from document-list.
         : Today this is flat text, but someday it might have structure.
         :)
        element div { $body } } }
  }
  </div>
};

declare function stp:list-page-root-entry-title(
  $entry as element(apidoc:entry))
as node()*
{
  if ($entry/@href) then element xh:a {
    $entry/@href,
    $entry/@title/string() }
  else $entry/@title[.]/element {
    if ($entry/.. instance of element(apidoc:group)) then 'xh:h3'
    else 'xh:div' } {
    string() }
};

declare function stp:list-page-root-entry(
  $entry as element(apidoc:entry))
as node()*
{
  <li xmlns="http://www.w3.org/1999/xhtml">
  {
    stp:list-page-root-entry-title($entry),
    if ($entry/apidoc:entry) then element ul {
      attribute class { "doclist" },
      (: Recurse. :)
      stp:list-page-root-entry($entry/apidoc:entry) }
    else if (not($entry/apidoc:description)) then element div {
      attribute class { "entry-no-description" },
      string($entry) }
    else $entry/apidoc:description/element div {
      attribute class { "entry-description", @class },
      @* except @class,
      node() }
  }
  </li>
};

declare function stp:list-page-root-group(
  $toc as element(toc:root),
  $title-aliases as element(aliases),
  $group as element(apidoc:group))
as node()*
{
  if (not($DEBUG)) then () else stp:debug(
    'stp:list-page-root-group',
    (xdmp:describe($toc),
      xdmp:describe($title-aliases),
      xdmp:describe($group),
      'id', xdmp:describe($group/@id/string()))),
  switch($group/@id)
  case 'guides' return stp:list-page-root-guides(
    $toc, $title-aliases, $group)
  default return
  <div xmlns="http://www.w3.org/1999/xhtml" class="doclist">
  {
    $group/@title/element h3 { . },

    element ul {
      attribute class { "doclist" },
      stp:list-page-root-entry(
        $group/apidoc:entry[
          apidoc:entry
          or not(apidoc:guide/@duplicate/xs:boolean(.)) ]) }
  }
  </div>
};

(: Set up the root docs page for this version.
 :)
declare function stp:list-page-root(
  $version as xs:string,
  $toc as element(toc:root),
  $title-aliases as element(aliases),
  $document-list as element(apidoc:docs))
as element()+
{
  element api:docs-page {
    attribute xml:base { api:internal-uri($version, '/') },
    attribute disable-comments { true() },
    comment {
      'This page was automatically generated using',
      xdmp:node-uri($toc),
      'and', (xdmp:node-uri($document-list), 'document-list.xml')[1] },

    (: Pre-rendered html section. :)
    <div xmlns="http://www.w3.org/1999/xhtml" class="doclist">
    {
      stp:list-page-root-group(
        $toc, $title-aliases,
        $document-list/apidoc:group)
    }
    </div>
    ,

    (: guide data :)
    comment { 'copied from TOC data:' },
    let $guide-nodes as element()+ := $toc/toc:node[
      @id eq 'guides']/toc:node/toc:node[@type eq 'guide']
    for $guide in $guide-nodes
    let $display as xs:string := lower-case(
      normalize-space($guide/@display))
    let $_ := if (not($DEBUG)) then () else stp:fine(
      'stp:list-pages', (xdmp:describe($guide), $display))
    return element api:user-guide {
      $guide/@*,
      (: Facilitate automatic link creation at render time.
       : Copy in aliases with any sibling that matches this display-name.
       :)
      $title-aliases/guide/alias[
        ../alias/normalize-space(lower-case(.)) = $display] },

    comment { 'copied from /apidoc/config/title-aliases.xml:' },
    (: TODO The auto-link elements are in the empty namespace. Change that? :)
    $title-aliases/auto-link }
};

(: Generate and insert a list page for each TOC container.
 : This may return element()+ with a variety of QNames.
 :)
declare function stp:list-pages-render(
  $version as xs:string,
  $toc-document as document-node())
as element()+
{
  stp:info(
    'stp:list-pages-render',
    ("starting", $version, xdmp:describe($toc-document))),
  stp:list-page-root(
    $version, $toc-document/toc:root,
    u:get-doc('/apidoc/config/title-aliases.xml')/aliases,
    api:document-list($version)),

  (: Find each function list and help page URL. :)
  let $seq as xs:string+ := distinct-values(
    $toc-document//toc:node[
      @type = 'function-reference'
      or @function-list-page
      or @admin-help-page]/@href)
  for $href in $seq
  (: Any element with intro or help content will have a title.
   : Process the first match.
   :)
  let $toc-node as element(toc:node)? := (
    $toc-document//toc:node[@href eq $href][toc:title])[1]
  let $_ := if (not($DEBUG)) then () else stp:debug(
    'stp:list-pages-render',
    ('href', $href, 'toc-node', xdmp:describe($toc-node)))
  where $toc-node
  return (
    if ($toc-node/@admin-help-page) then stp:list-page-help(
      api:internal-uri($version, $href), $toc-node)
    else if ($toc-node[
        @type = 'function-reference'
        or @function-list-page]) then stp:list-page-functions(
      $version, api:internal-uri($version, $href), $toc-node)
    else stp:error('UNEXPECTED', xdmp:quote($toc-node)))
  ,
  stp:info('stp:list-pages-render', ("ok", xdmp:elapsed-time()))
};

(: Generate and insert a list page for each TOC container.
 : TOC must exist.
 :)
declare function stp:list-pages-render(
  $version as xs:string)
as empty-sequence()
{
  for $n in stp:list-pages-render(
    $version,
    doc(toc:root-uri($version)) treat as node())
  let $uri as xs:string := base-uri($n)
  let $_ := (
    if ($n/* or $n/self::*) then ()
    else stp:error('EMPTY', ($uri, xdmp:quote($n))))
  let $_ := if (not($DEBUG)) then () else stp:debug(
    'stp:list-pages-render', ($uri))
  return xdmp:document-insert($uri, $n)
};

(: Recursively load all files, retaining the subdir structure :)
declare function stp:zip-load-raw-docs(
  $version as xs:string,
  $zip as binary())
as empty-sequence()
{
  (: Using encoding=auto is necessary for some of the content,
   : especially javadoc.
   : But it messes up binary content and some XML.
   :)
  raw:invoke-function(
    function() {
      for $e in xdmp:zip-manifest($zip)/*[
        not(ends-with(., '/')) ][
        matches(., $RAW-PAT) ]
      let $suffix as xs:string := replace($e, $RAW-PAT, '$2')
      let $uri as xs:string := concat('/', $version, '/', $suffix)
      let $type := xdmp:uri-content-type($uri)
      let $_ := if (not($DEBUG)) then () else stp:debug(
        'stp:zip-load-raw-docs', ($e, '=>', $uri, $type))
      let $opts := (
        if ($type = ('text/xml') or not(starts-with($type, 'text/'))) then ()
        else <options xmlns="xdmp:zip-get"><encoding>auto</encoding></options>)
      return xdmp:document-insert(
        $uri,
        xdmp:zip-get($zip, $e, $opts),
        xdmp:default-permissions(),
        $version)
      ,
      xdmp:commit() },
    true())
};

declare function stp:fixup-attribute-href(
  $version as xs:string,
  $a as attribute(href),
  $context as xs:string*)
as attribute()?
{
  if (not($a/parent::a or $a/parent::xh:a)) then $a
  else attribute href {
    (: Fixup Linkerator links
     : Change "#display.xqy&fname=http://pubs/5.1doc/xml/admin/foo.xml"
     : to "/guide/admin/foo"
     :)
    if (starts-with($a, '#display.xqy?fname=')) then (
      let $anchor := replace(
        substring-after($a, '.xml'), '%23', '#id_')
      return stp:fix-guide-names(
        $version,
        concat('/guide',
          substring-before(
            substring-after($a, 'doc/xml'), '.xml'),
          $anchor)))

    (: If a fragment id contains a colon, it is a link to a function page.
     : #xdmp:tidy => /xdmp:tidy or /xdmp.tidy
     :)
    else if (matches($a, '^#([\w-]+)[:\.]([\w-]+)$')) then translate(
      $a, '#', '/')

    (: A fragment link sometimes points elsewhere in the same apidoc:module,
     : or sometimes elsewhere within the same function.
     :)
    else if (starts-with($a, '#')) then (
      let $fid := substring-after($a, '#')
      let $relevant-function := $a/root()/apidoc:module/apidoc:function[
        @id eq $fid]
      let $result as xs:string := (
        (: Link within same page. :)
        if (empty($relevant-function)) then ''
        else if ($a/ancestor::apidoc:function[1] is $relevant-function) then '.'
        (: If we are on a different page, insert a link to the target page. :)
        else (
          (: REST URLs are written differently than function URLs :)
          (: path to resource page :)
          if ($relevant-function/@lib
            = $REST-LIBS) then api:REST-fullname-to-external-uri(
            api:fixup-fullname($relevant-function, $api:MODE-REST))
          (: path to regular function page :)
          else '/'||api:fixup-fullname(
            $relevant-function, $context[. = $api:MODES])))
      return $result||'#'||$fid)

    (: For an absolute path like http://w3.org leave the value alone. :)
    else if (contains($a, '://')) then $a

    (: Handle some odd corner-cases. TODO maybe dead code? :)
    else if ($a
      eq 'apidocs.xqy?fname=UpdateBuiltins#xdmp:document-delete') then '/xdmp:document-delete'
    (: as we configured in config/category-mappings.xml :)
    else if ($a =
      ('apidocs.xqy?fname=cts:query Constructors',
        'SearchBuiltins&amp;sub=cts:query Constructors')) then '/cts/constructors'

    (: Otherwise, assume a function page with an optional fragment id,
     : so we need only prepend a slash.
     :)
    else concat('/', $a) }
};

declare function stp:fixup-attribute-lib(
  $a as attribute(lib))
as attribute()?
{
  if (not($a/parent::apidoc:function)) then $a
  else attribute lib {
    if ($a eq 'rest') then 'rest-lib'
    (: Change designated values to "REST",
     : so the TOC code treats it like a library with that name.
     :)
    else if ($a = $REST-LIBS) then $api:MODE-REST
    else $a}
};

declare function stp:fixup-attribute-name(
  $a as attribute(name))
as attribute()?
{
  if (not($a/parent::apidoc:function)) then $a
  else attribute name {
    (: fixup apidoc:function/@name for javascript :)
    switch ($a/../@mode/string())
    case $api:MODE-JAVASCRIPT return api:javascript-name(
      $a/.. treat as node())
    default return $a }
};

(: Ported from fixup.xsl,
 : where it was only used by extract-functions.
 :)
declare function stp:fixup-attribute(
  $version as xs:string,
  $a as attribute(),
  $context as xs:string*)
as attribute()?
{
  typeswitch($a)
  case attribute(href) return stp:fixup-attribute-href(
    $version, $a, $context)
  case attribute(lib) return stp:fixup-attribute-lib($a)
  case attribute(name) return stp:fixup-attribute-name($a)
  (: By default, return the input. :)
  default return $a
};

declare function stp:fixup-attributes-new(
  $e as element(),
  $context as xs:string*)
as attribute()*
{
  typeswitch($e)
  case element(apidoc:function) return (
    (($e/@mode, $context)[1] treat as item()) ! (
      (: Add the prefix and namespace URI of the function. :)
      attribute prefix { $e/@lib },
      attribute namespace { api:namespace($e/@lib)/@uri },
      (: Watch for duplicates!
       : Any existing attributes will be copies by the caller.
       :)
      if ($e/@mode) then () else attribute mode { . },
      (: Add the @fullname attribute, which we depend on later.
       : This depends on the @mode attribute,
       : which is faked in api:function-fake-javascript
       : but missing from non-fake raw function XML.
       :)
      attribute fullname { api:fixup-fullname($e, .) }))
  default return ()
};

declare function stp:fixup-element-name($e as element())
as xs:anyAtomicType
{
  (: Move "apidoc" elements to the "api" namespace,
   : to avoid confusion.
   :)
  if ($e/self::apidoc:*) then QName($api:NAMESPACE, local-name($e))
  else node-name($e)
};

declare function stp:schema-info(
  $xse as element(xs:element))
as element(api:element)
{
  (: ASSUMPTION: all the element declarations are global.
   : ASSUMPTION: the schema default namespace is the same as
   : the target namespace (@ref uses no prefix).
   :)
  let $current-ref := $xse/@ref/string()
  let $root := $xse/root()
  let $element-decl := $root/xs:schema/xs:element[
    @name eq $current-ref]
  (: This is natively a QName,
   : but we assume we can ignore namespace prefixes.
   :)
  let $element-decl-type := $element-decl/@type/string()
  let $complexType := $root/xs:schema/xs:complexType[
    @name eq $element-decl-type]
  return element api:element {
    element api:element-name { $current-ref },
    element api:element-description {
      $element-decl/xs:annotation/xs:documentation },
    (: Recursion continues via function mapping.
     : TODO Could this get into a loop?
     :)
    stp:schema-info($complexType//xs:element)
  }
};

declare function stp:fixup-children-apidoc-usage(
  $version as xs:string,
  $e as element(apidoc:usage),
  $context as xs:string*)
as node()*
{
  if (not($e/@schema)) then stp:fixup($version, $e/node(), $context) else (
    let $current-dir := string-join(
      tokenize(base-uri($e), '/')[position() ne last()], '/')
    let $schema-uri := concat(
      $current-dir, '/',
      substring-before($e/@schema,'.xsd'), '.xml')
    (: This logic and attendant assumptions come from the docapp code. :)
    let $function-name := string($e/../@name)
    let $is-REST-resource := starts-with($function-name,'/')
    let $given-name := ($e/@element-name, $e/../@name)[1]/string()
    let $complexType-name := (
      if ($is-REST-resource and not($e/@element-name))
      then api:lookup-REST-complexType($version, $function-name)
      else $given-name)
    let $print-intro-value := (string($e/@print-intro), true())[1]
    where $complexType-name
    return (
      stp:fixup($version, $e/node(), $context),
      element api:schema-info {
        if (not($is-REST-resource)) then () else (
          attribute REST-doc { true() },
          attribute print-intro { $print-intro-value }),
        let $schema := raw:get-doc($schema-uri)/xs:schema
        let $complexType := $schema/xs:complexType[@name eq $complexType-name]
        (: This presumes that all the element declarations are global,
         : and complex type contains only element references.
         :)
        return stp:schema-info($complexType//xs:element) }))
};

declare function stp:fixup-children(
  $version as xs:string,
  $e as element(),
  $context as xs:string*)
as node()*
{
  typeswitch($e)
  case element(apidoc:usage) return stp:fixup-children-apidoc-usage(
    $version, $e, $context)
  default return stp:fixup($version, $e/node(), $context)
};

declare function stp:fixup-element(
  $version as xs:string,
  $e as element(),
  $context as xs:string*)
as element()?
{
  (: Hide mode-specific content from different modes.
   :)
  if (not(api:has-mode-class($e, $context))) then ()
  else element { stp:fixup-element-name($e) } {
    stp:fixup-attribute($version, $e/@*, $context),
    stp:fixup-attributes-new($e, $context),
    stp:fixup-children($version, $e, $context) }
};

(: Ported from fixup.xsl
 : This takes care of fixing internal links and references,
 : and any other transform work.
 :)
declare function stp:fixup(
  $version as xs:string,
  $n as node(),
  $context as xs:string*)
as node()*
{
  if (not($DEBUG)) then () else stp:fine(
    'stp:fixup',
    (xdmp:describe($n), xdmp:describe($context))),
  typeswitch($n)
  case document-node() return document {
    stp:fixup($version, $n/node(), $context) }
  case element() return stp:fixup-element($version, $n, $context)
  case attribute() return stp:fixup-attribute($version, $n, $context)
  (: By default, return the input. :)
  default return $n
};

declare function stp:function-modes(
  $f as element(apidoc:function))
as xs:string+
{
  $api:MODES[
    api:function-appears-in-mode($f, .) ]
};

declare function stp:function-names(
  $f as element(apidoc:function))
as xs:string+
{
  api:fixup-fullname($f, stp:function-modes($f), true())
};

declare function stp:zip-function-names(
  $zip as binary())
as xs:string*
{
  (: Ignore function elements with missing or empty names. :)
  stp:function-names(
    xdmp:zip-manifest($zip)/*[ends-with(., 'xml')]
    /xdmp:zip-get($zip, .)
    /apidoc:module/apidoc:function[@name/string()])
};

declare function stp:zipfile-function-names(
  $zip-path as xs:string)
as xs:string*
{
  stp:zip-function-names(
    xdmp:document-get($zip-path)/binary() treat as node())
};

(: apidoc/setup/setup.xqm :)