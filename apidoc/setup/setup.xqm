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

declare variable $TITLE-ALIASES := u:get-doc(
  '/apidoc/config/title-aliases.xml')/aliases ;

declare variable $toc-dir     := concat("/media/apiTOC/",$api:version,"/");
declare variable $toc-xml-uri := concat($toc-dir,"toc.xml");
declare variable $toc-uri     := concat($toc-dir,"apiTOC_", current-dateTime(), ".html");

declare variable $toc-default-dir         := concat("/media/apiTOC/default/");
declare variable $toc-uri-default-version := concat($toc-default-dir,"apiTOC_", current-dateTime(), ".html");

declare variable $processing-default-version := $api:version eq $api:default-version;

declare variable $LEGAL-VERSIONS as xs:string+ := u:get-doc(
  "/config/server-versions.xml")/*/version/@number ;

(: TODO must not assume HTTP environment. :)
declare variable $errorCheck := (
  if (not($api:version-specified)) then stp:error(
    "ERROR", "You must specify a 'version' param.")
  else ()) ;

(: TODO must not assume HTTP environment. :)
(: used in create-toc.xqy / toc-help.xsl :)
declare variable $helpXsdCheck := (
  if (not(xdmp:get-request-field("help-xsd-dir"))) then stp:error(
    "ERROR", "You must specify a 'help-xsd-dir' param.")
  else ()) ;

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
  stp:log($label, $list, 'fine')
};

declare function stp:debug(
  $label as xs:string,
  $list as xs:anyAtomicType*)
as empty-sequence()
{
  stp:log($label, $list, 'debug')
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

declare function stp:static-uri-rewrite($uri as xs:string)
as xs:string
{
  if (starts-with($uri,"/javaclient"))
  then replace($uri,"/javaclient/javadoc/", "/javadoc/client/")
  else if (starts-with($uri,"/hadoop/"))
  then replace($uri,"/hadoop/javadoc/","/javadoc/hadoop/")
  (: Move "/javadoc" to the beginning of the URI :)
  else if (starts-with($uri,"/javadoc/"))
  then replace($uri,"/javadoc/","/javadoc/xcc/")
  else if (starts-with($uri,"/dotnet/"))
  then replace($uri,"/dotnet/",  "/dotnet/xcc/")
  else if (starts-with($uri,"/c++/"))
  then replace($uri,"/c\+\+/", "/cpp/udf/")

  (: ASSUMPTION: the java docs don't include any PDFs :)
  else if (ends-with($uri,".pdf")) then stp:pdf-uri($uri)

  (: By default, don't change the URI (e.g., for C++ docs) :)
  else stp:error("UNEXPECTED", ('path', $uri))
};

declare function stp:pdf-uri($uri as xs:string)
as xs:string?
{
  let $pdf-name      := replace($uri, ".*/(.*).pdf", "$1"),
      $guide-configs := u:get-doc("/apidoc/config/document-list.xml")//guide,
      $url-name      := $guide-configs[(@pdf-name,@source-name)[1] eq $pdf-name]
                          /@url-name
  return
  (
    if (not($url-name))
    then stp:error("ERROR", concat("The configuration for ",$uri,
          " is missing in /apidoc/config/document-list.xml"))
    else (),
    concat("/guide/",$url-name,".pdf")
  )
};

(: look at document-list.xml to change url names based on that list :)
declare function stp:fix-guide-names(
  $s as xs:string,
  $num as xs:integer)
{
  let $x := xdmp:document-get(
    concat(xdmp:modules-root(), "/apidoc/config/document-list.xml"))
  let $source := $x//guide[@url-name ne @source-name]/@source-name/string()
  let $url := $x//guide[@url-name ne @source-name]/@url-name/string()
  let $count := count($source)
  return (
    if ($num eq $count + 1) then (xdmp:set($num, 9999), $s)
    else if ($num eq 9999) then $s
    else stp:fix-guide-names(replace($s, $source[$num], $url[$num]),
      $num + 1))
};

declare function stp:function-extract(
  $function as element(apidoc:function),
  $uris-seen as map:map)
as element()*
{
  if ($function/@hidden/xs:boolean(.)) then () else
  (: These are raw functions, so only javascript will have a mode. :)
  let $mode as xs:string := (
    if ($function/@mode) then $function/@mode
    else if (starts-with($function/@name, '/')) then $api:MODE-REST
    else $api:MODE-XPATH)[1]
  let $external-uri := api:external-uri($function, $mode)
  let $internal-uri := api:internal-uri($external-uri)
  let $seen := map:contains($uris-seen, $internal-uri)
  let $lib as xs:string := $function/@lib
  let $name as xs:string := $function/@name
  let $_ := stp:debug(
    'stp:function-extract',
    ('mode', $mode,
      'external', $external-uri,
      'internal', $internal-uri,
      'seen', $seen))
  (: This wrapper is necessary because the *:polygon() functions
   : are each (dubiously) documented as two separate functions so
   : that raises the possibility of needing to include two different
   : api:function elements in the same page.
   : Likewise process all functions having the same name in the same lib.
   : However this means that the resulting xml:base values may conflict,
   : so we have to check $uris-seen.
   :)
  where not($seen)
  return element api:function-page {
    attribute xml:base { $internal-uri },
    attribute mode { $mode },
    map:put($uris-seen, $internal-uri, $internal-uri),
    (: For word search purposes. :)
    element api:function-name { api:fixup-fullname($function, $mode) },
    stp:fixup(
      $function/../apidoc:function[@name eq $name][@lib eq $lib],
      $mode) }
};

declare function stp:function-docs(
  $version as xs:string,
  $doc as document-node())
as element()*
{
  (: create XQuery/XSLT function pages - and REST? :)
  stp:function-extract(
    api:module-extractable-functions($doc/apidoc:module, $api:MODE-XPATH),
    map:map()),
  (: create JavaScript function pages :)
  if (number($api:version) lt 8) then ()
  else stp:function-extract(
    api:module-extractable-functions($doc/apidoc:module, $api:MODE-JAVASCRIPT),
    map:map())
};

declare function stp:function-docs(
  $version as xs:string)
as empty-sequence()
{
  stp:info('stp:function-docs', ('starting', $version)),
  for $doc in raw:api-docs($version)
  let $_ := stp:debug(
    "stp:function-docs", ('starting', xdmp:describe($doc)))
  let $extracted as node()+ := stp:function-docs($version, $doc)
  for $func in $extracted
  let $uri := base-uri($func)
  let $_ := stp:debug(
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

(: Load a static file.
 :)
declare function stp:zip-static-file-get(
  $zip as binary(),
  $path as xs:string,
  $is-html as xs:boolean,
  $is-jdoc as xs:boolean)
as document-node()
{
  let $is-mangled-html := ends-with($path, '-members.html')

  return (
    (: If the document is JavaDoc HTML, then read it as text;
     : if it's other HTML, repair it as XML (.NET docs)
     : Don't tidy index.html because tidy throws away the frameset.
     :)
    (: TODO should this be ends-with rather than contains? :)
    if ($is-jdoc and not(contains($path, '/index.html'))) then xdmp:tidy(
      xdmp:zip-get(
        $zip,
        $path,
        <options xmlns="xdmp:document-get">
          <format>text</format>
          <encoding>auto</encoding>
        </options>
      ),
      <options xmlns="xdmp:tidy">
        <input-encoding>utf8</input-encoding>
        <output-encoding>utf8</output-encoding>
        <output-xhtml>no</output-xhtml>
        <output-xml>no</output-xml>
        <output-html>yes</output-html>
        </options>
      )[2]

    else if ($is-mangled-html) then try {
      stp:fine('stp:zip-static-file-get', ('trying unquote for', $path)),
      let $unparsed as xs:string := xdmp:zip-get(
        $zip,
        $path,
        <options xmlns="xdmp:document-get"
        ><format>text</format></options>)
      let $replaced := replace($unparsed, '"class="', '" class="')
      return xdmp:unquote($replaced, "", "repair-full") }
    catch($e) {
      stp:info(
        'stp:zip-static-file-get',
        ("loading", $path, "with encoding=auto because", $e/error:message)),
      xdmp:zip-get(
        $zip,
        $path,
        <options xmlns="xdmp:document-get"
        ><encoding>auto</encoding></options>) }
    else if ($is-html) then try {
      stp:fine(
        'stp:zip-static-file-get',
        ("trying html as XML UTF8")),
      xdmp:zip-get(
        $zip,
        $path,
        <options xmlns="xdmp:document-get">
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
        <options xmlns="xdmp:document-get">
          <format>xml</format>
          <repair>full</repair>
          <encoding>ISO-8859-1</encoding>
        </options>
      ) }
    (: Otherwise, just load the document normally :)
    else xdmp:zip-get(
      $zip,
      $path,
      <options xmlns="xdmp:document-get"><encoding>auto</encoding></options>))
};

declare function stp:zip-static-file-insert(
  $doc as document-node(),
  $uri as xs:string,
  $is-hidden as xs:boolean,
  $is-jdoc as xs:boolean)
as document-node()
{
  xdmp:document-insert(
    $uri,
    stp:static-add-scripts($doc),
    xdmp:default-permissions(),
    (: Exclude these HTML and javascript documents from the search corpus
     : Instead search the XHTML after tidy - see below.
     :)
    "hide-from-search"[$is-hidden]),
  stp:debug("static-file-insert", $uri),

  (: If the document is HTML, then store an additional copy,
   : converted to XHTML using Tidy.
   : This is using the same mechanism as the CPF "convert-html" action,
   : except that this is done synchronously. This XHTML copy is
   : used for search, snippeting, etc.
   :)
  if (not($is-jdoc)) then () else (
    stp:fine(
      'static-file-insert',
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
    let $_ := stp:fine(
      'stp:zip-static-file-insert', ('Tidying', $uri, 'to', $xhtml-uri))
    return xdmp:document-insert($xhtml-uri, stp:static-add-scripts($xhtml)))
};

declare function stp:zip-static-docs-insert(
  $version as xs:string,
  $zip-path as xs:string,
  $zip as binary())
as empty-sequence()
{
  let $config := u:get-doc("/apidoc/config/static-docs.xml")/static-docs
  let $subdirs-to-load := $config/include/string()
  let $pubs-dir := '/pubs'
  for $e in xdmp:zip-manifest($zip)/*[
    contains(., '_pubs/pubs/') ][
    not(ends-with(., '/')) ][
    some $path in $subdirs-to-load
    satisfies starts-with(., $path) ]
  let $is-html := ends-with($e, '.html')
  let $is-jdoc := $is-html and contains($e, '/javadoc/')
  let $is-js := ends-with($e,'.js')
  let $is-css := ends-with($e,'.css')
  let $uri := concat(
    "/apidoc/", $version,
    '/', stp:static-uri-rewrite(substring-after($e, '_pubs/pubs/')))
  let $is-hidden := $is-jdoc or $is-js or $is-css
  let $doc := stp:zip-static-file-get($zip, $e, $is-html, $is-jdoc)
  return stp:zip-static-file-insert($doc, $uri, $is-hidden, $is-jdoc)
  ,

  (: Load the zip, to support downloads. :)
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
    xdmp:document-get($zip-path)/node())
};

declare function stp:zip-static-docs-insert(
  $zip-path as xs:string)
as empty-sequence()
{
  stp:zip-static-docs-insert(
    $api:version,
    $zip-path)
};

(: Delete all docs for a version. :)
declare function stp:docs-delete($version as xs:string)
as empty-sequence()
{
  stp:info('stp:docs-delete', $version),
  let $dir := concat('/media/apidoc/', $version, '/')
  let $_ := xdmp:directory-delete($dir)
  let $_ := stp:info(
    'stp:docs-delete', ($version, $dir, 'ok', xdmp:elapsed-time()))
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

declare function stp:toc-delete()
as empty-sequence()
{
  stp:info('stp:toc-delete', $api:version),
  let $dir := $toc-dir
  let $prefix := string(doc($api:toc-uri-location))
  for $toc-parts-dir in cts:uri-match(concat($dir,"*.html/"))
  let $main-toc := substring($toc-parts-dir,1,string-length($toc-parts-dir)-1)
  where not(starts-with($toc-parts-dir,$prefix))
  return (
    xdmp:document-delete($main-toc),
    xdmp:directory-delete($toc-parts-dir))
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
    ancestor-or-self::toc:node[@async][1],
    ancestor-or-self::toc:node[@id]   [1] )[1]/@id
};

(: Input parent should be api:function-page. :)
declare function stp:list-entry(
  $function as element(api:function),
  $toc-node as element(toc:node))
as element(api:list-entry)
{
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
  $uri as xs:string,
  $toc-node as element(toc:node))
as element(api:list-page)
{
  element api:list-page {
    attribute xml:base { $uri },
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
    for $leaf in $toc-node//toc:node[not(toc:node)][@type]
    (: For multiple *:polygon() functions, only list the first. :)
    let $href as xs:string := $leaf/@href
    let $_ := stp:fine(
      'stp:list-page-functions',
      ($uri, 'leaf', xdmp:describe($leaf),
        'type', $leaf/@type, 'href', $href))
    let $uri-leaf as xs:string := api:internal-uri($href)
    let $root as document-node() := doc($uri-leaf)
    let $function as element() := ($root/api:function-page/api:function)[1]
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
    stp:node-to-xhtml($toc-node/toc:title),
    (: Help index page is at the top :)
    if (not($toc-node/toc:content/@auto-help-list)) then stp:node-to-xhtml(
      $toc-node/toc:content)
    else element api:content {
      <div xmlns="http://www.w3.org/1999/xhtml">
        <p>
      The following is an alphabetical list of Admin Interface help pages:
        </p>
        <ul>
      {
        stp:list-page-help-items($toc-node)
      }
        </ul>
      </div>
    }
  }
};

(: Set up the docs page for this version. :)
declare function stp:list-page-root(
  $toc as element(toc:root))
as element()+
{
  element api:docs-page {
    attribute xml:base { api:internal-uri('/') },
    attribute disable-comments { true() },
    comment {
      'This page was automatically generated using',
      xdmp:node-uri($toc),
      'and /apidoc/config/document-list.xml' },

    let $guide-nodes as element()+ := $toc/toc:node[
      @id eq 'guides']/toc:node/toc:node[@guide]
    for $guide in $guide-nodes
    let $display as xs:string := lower-case(
      normalize-space($guide/@display))
    let $_ := stp:fine('stp:list-pages', (xdmp:describe($guide), $display))
    return element api:user-guide {
      $guide/@*,
      (: Facilitate automatic link creation at render time.
       : TODO why ../alias ?
       :)
      $stp:TITLE-ALIASES/guide/alias[
        ../alias/normalize-space(lower-case(.)) = $display] }
    ,

    comment { 'copied from /apidoc/config/title-aliases.xml:' },
    $stp:TITLE-ALIASES/auto-link }
};

(: Generate and insert a list page for each TOC container.
 : This may return element()+ with a variety of QNames.
 :)
declare function stp:list-pages-render(
  $toc-document as document-node())
as element()+
{
  stp:info(
    'stp:list-pages-render', ("starting", xdmp:describe($toc-document))),
  stp:list-page-root($toc-document/toc:root),
  (: Find each function list and help page URL. :)
  let $seq as xs:string+ := distinct-values(
    $toc-document//toc:node[@function-list-page or @admin-help-page]/@href)
  for $href in $seq
  (: Any element with intro or help content will have a title.
   : Process the first match.
   :)
  let $toc-node as element(toc:node)? := (
    $toc-document//toc:node[@href eq $href][toc:title])[1]
  where $toc-node
  return (
    if ($toc-node/@admin-help-page) then stp:list-page-help(
      api:internal-uri($href), $toc-node)
    else if ($toc-node/@function-list-page) then stp:list-page-functions(
      api:internal-uri($href), $toc-node)
    else stp:error('UNEXPECTED', xdmp:quote($toc-node)))
  ,
  stp:info('stp:list-pages-render', ("ok", xdmp:elapsed-time()))
};

(: Generate and insert a list page for each TOC container :)
declare function stp:list-pages-render()
as empty-sequence()
{
  for $n in stp:list-pages-render(
    doc($toc-xml-uri) treat as node())
  let $uri as xs:string := base-uri($n)
  let $_ := if ($n/*
    or $n/self::*) then () else stp:error('EMPTY', ($uri, xdmp:quote($n)))
  let $_ := stp:debug(
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
        contains(., '_pubs/pubs/raw/') ][
        not(ends-with(., '/')) ]
      let $uri as xs:string := concat(
        '/', $version,
        '/', substring-after($e, '_pubs/pubs/raw/'))
      let $type := xdmp:uri-content-type($uri)
      let $_ := stp:debug('stp:zip-load-raw-docs', ($e, '=>', $uri, $type))
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

(: Recursively load all files, retaining the subdir structure :)
declare function stp:zip-load-raw-docs(
  $zip as binary())
as empty-sequence()
{
  stp:zip-load-raw-docs($api:version, $zip)
};

declare function stp:fixup-attribute-href(
  $a as attribute(href))
as attribute()?
{
  if (not($a/parent::a or $a/parent::xh:a)) then $a
  else attribute href {
    (: Fixup Linkerator links
     : Change "#display.xqy&fname=http://pubs/5.1doc/xml/admin/foo.xml"
     : to "/guide/admin/foo"
     :)
    if (starts-with(
        $a/../@href, '#display.xqy?fname=')) then (
      let $anchor := replace(
        substring-after($a, '.xml'), '%23', '#id_')
      return stp:fix-guide-names(
        concat('/guide',
          substring-before(
            substring-after($a, 'doc/xml'), '.xml'),
          $anchor), 1))

    (: If a fragment id contains a colon, it is a link to a function page.
     : TODO JavaScript handle fn.abs etc.
     : Change, e.g., #xdmp:tidy to /xdmp:tidy
     :)
    else if (starts-with($a, '#') and contains($a, ':')) then translate(
      $a, '#', '/')

    (: A relative fragment link points somewhere in the same apidoc:module. :)
    else if (starts-with($a, '#')) then (
      let $fid := substring-after($a, '#')
      let $relevant-function := $a/root()/apidoc:module/apidoc:function[
        .//*/@id eq $fid]
      let $result as xs:string := (
        (: Link within same page. :)
        if ($a/ancestor::apidoc:function is $relevant-function) then '.'
        (: If we are on a different page, insert a link to the target page. :)
        else (
          (: REST URLs are written differently than function URLs :)
          (: path to resource page :)
          if ($relevant-function/@lib
            = $api:REST-LIBS) then api:REST-fullname-to-external-uri(
            api:fixup-fullname($relevant-function, $api:MODE-REST))
          (: regular function page :)
          (: path to function page TODO add mode when javascript :)
          else '/'||api:fixup-fullname($relevant-function, ())))
      return $result)

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
    (: Change the "spell" library to "spell-lib"
     : to disambiguate from the built-in "spell" module.
     :)
    if ($a eq 'spell' and not($a/../@type eq 'builtin')) then 'spell-lib'
    (: Similarly, change the "json" library to "json-lib"
     : to disambiguate from the built-in "json" module.
     :)
    else if ($a eq 'json' and not($a/../@type eq 'builtin')) then 'json-lib'
    (: Change the "rest" library to "rest-lib"
     : because we reserve the "/REST/" prefix for the REST API docs.
     : We do not want case to be the only difference.
     :)
    else if ($a eq 'rest') then 'rest-lib'
    (: Change designated values to "REST",
     : so the TOC code treats it like a library with that name.
     :)
    else if ($a = $api:REST-LIBS) then $api:MODE-REST
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
    case $api:MODE-JAVASCRIPT return api:javascript-name($a)
    default return $a }
};

(: Ported from fixup.xsl,
 : where it was only used by extract-functions.
 :)
declare function stp:fixup-attribute(
  $a as attribute())
as attribute()?
{
  typeswitch($a)
  case attribute(href) return stp:fixup-attribute-href($a)
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
      attribute namespace { api:uri-for-lib($e/@lib) },
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
  $e as element(apidoc:usage),
  $context as xs:string*)
as node()*
{
  if (not($e/@schema)) then stp:fixup($e/node(), $context) else (
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
      then api:lookup-REST-complexType($function-name)
      else $given-name)
    let $print-intro-value := (string($e/@print-intro), true())[1]
    where $complexType-name
    return (
      stp:fixup($e/node(), $context),
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
  $e as element(),
  $context as xs:string*)
as node()*
{
  typeswitch($e)
  case element(apidoc:usage) return stp:fixup-children-apidoc-usage(
    $e, $context)
  default return stp:fixup($e/node(), $context)
};

declare function stp:fixup-element(
  $e as element(),
  $context as xs:string*)
as element()?
{
  (: Hide mode-specific content unless the correct mode is set.
   : Ignore unknown classes.
   :)
  let $includes := xs:NMTOKENS($e/@class)[. eq $api:MODES]
  where empty($includes) or $includes = $context
  return element { stp:fixup-element-name($e) } {
    stp:fixup-attribute($e/@*),
    stp:fixup-attributes-new($e, $context),
    stp:fixup-children($e, $context) }
};

(: Ported from fixup.xsl
 : This takes care of fixing internal links and references,
 : and any other transform work.
 :)
declare function stp:fixup(
  $n as node(),
  $context as xs:string*)
as node()*
{
  typeswitch($n)
  case document-node() return document { stp:fixup($n/node(), $context) }
  case element() return stp:fixup-element($n, $context)
  case attribute() return stp:fixup-attribute($n)
  (: By default, return the input. :)
  default return $n
};

(: apidoc/setup/setup.xqm :)