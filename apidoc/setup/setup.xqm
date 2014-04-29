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

declare variable $toc-dir     := concat("/media/apiTOC/",$api:version,"/");
declare variable $toc-xml-uri := concat($toc-dir,"toc.xml");
declare variable $toc-uri     := concat($toc-dir,"apiTOC_", current-dateTime(), ".html");

declare variable $toc-default-dir         := concat("/media/apiTOC/default/");
declare variable $toc-uri-default-version := concat($toc-default-dir,"apiTOC_", current-dateTime(), ".html");

declare variable $processing-default-version := $api:version eq $api:default-version;

(: TODO must not assume HTTP environment. :)
declare variable $errorCheck := (
  if (not($api:version-specified)) then error(
    (), "ERROR", "You must specify a 'version' param.")
  else ()) ;

(: TODO must not assume HTTP environment. :)
(: used in create-toc.xqy / toc-help.xsl :)
declare variable $helpXsdCheck := (
  if (not(xdmp:get-request-field("help-xsd-dir"))) then error(
    (), "ERROR", "You must specify a 'help-xsd-dir' param.")
  else ()) ;

declare variable $GOOGLE-ANALYTICS as element() :=
(: google analytics script goes just before the closing the </head> tag :)
<script type="text/javascript"><![CDATA[
  var is_prod = document.location.hostname == 'docs.marklogic.com';
  var acct = is_prod ? 'UA-6638631-1' : 'UA-6638631-3';
  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', acct], ['_setDomainName', 'marklogic.com'],
            ['_trackPageview']);

  (function() {
      var ga = document.createElement('script');
      ga.type = 'text/javascript'; ga.async = true;
      ga.src = ('https:' == document.location.protocol ? 'https://ssl'
               : 'http://www') + '.google-analytics.com/ga.js';
      var s = document.getElementsByTagName('script')[0];
      s.parentNode.insertBefore(ga, s);
            })();]]>
</script> ;

declare variable $MARKETO as element() :=
(: marketo script goes just before the closing the </body> tag :)
<script type="text/javascript"><![CDATA[
 (function() {
      function initMunchkin() {
      Munchkin.init('371-XVQ-609');
    }
    var s = document.createElement('script');
    s.type = 'text/javascript';
    s.async = true;
    s.src = document.location.protocol + '//munchkin.marketo.net/munchkin.js';
    s.onreadystatechange = function() {
        if (this.readyState == 'complete' || this.readyState == 'loaded') {
            initMunchkin();
          }
        };
    s.onload = initMunchkin;
    document.getElementsByTagName('body')[0].appendChild(s);
    })();]]>
</script> ;

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
  case element(head) return stp:element-rewrite($n, $GOOGLE-ANALYTICS)
  case element(HEAD) return stp:element-rewrite($n, $GOOGLE-ANALYTICS)
  case element(body) return stp:element-rewrite($n, $MARKETO)
  case element(BODY) return stp:element-rewrite($n, $MARKETO)
  (: Any other element may have head or body children. :)
  case element() return element {fn:node-name($n)} {
    $n/@*,
    stp:static-add-scripts($n/node()) }
  (: Text, binary, comments, etc. :)
  default return $n
};

declare function stp:static-uri-rewrite($uri) {
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
  else error((), "UNEXPECTED", ('path', $uri))
};

declare function stp:pdf-uri($uri)
{
  let $pdf-name      := replace($uri, ".*/(.*).pdf", "$1"),
      $guide-configs := u:get-doc("/apidoc/config/document-list.xml")//guide,
      $url-name      := $guide-configs[(@pdf-name,@source-name)[1] eq $pdf-name]
                          /@url-name
  return
  (
    if (not($url-name))
    then error((), "ERROR", concat("The configuration for ",$uri,
          " is missing in /apidoc/config/document-list.xml"))
    else (),
    concat("/guide/",$url-name,".pdf")
  )
};

(: look at document-list.xml to change url names based on that list :)
declare function stp:fix-guide-names($s as xs:string, $num as xs:integer) {

let $x := xdmp:document-get(concat(xdmp:modules-root(),
              "/apidoc/config/document-list.xml"))
let $source := $x//guide[@url-name ne @source-name]/@source-name/string()
let $url := $x//guide[@url-name ne @source-name]/@url-name/string()
let $count := count($source)
return
if ($num eq $count + 1)
then (xdmp:set($num, 9999), $s)
else if ($num eq 9999)
     then $s
     else stp:fix-guide-names(replace($s, $source[$num], $url[$num]),
             $num + 1)

};

declare function stp:function-docs-extract(
  $version as xs:string)
as empty-sequence()
{
  stp:info('stp:function-docs-extract', ('starting', $version)),

  for $doc in $raw:API-DOCS
  let $_ := stp:info(
    "stp:function-docs-extract", ('starting', xdmp:describe($doc)))
  for $func in xdmp:xslt-invoke(
    "extract-functions.xsl", $doc,
    map:new(map:entry('VERSION', $version)))
  let $uri := base-uri($func)
  let $_ := stp:info(
    "stp:function-docs-extract",
    ("inserting", xdmp:describe($doc), 'at', $uri))
  return xdmp:document-insert($uri, $func)
  ,
  xdmp:log("[stp:function-docs-extract] ok")
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

(: Generate and insert a list page for each TOC container :)
declare function stp:list-pages-render()
as empty-sequence()
{
  stp:info('stp:list-pages-render', "starting"),
  xdmp:xslt-invoke(
    "make-list-pages.xsl",
    doc($toc-xml-uri))
  /xdmp:document-insert(base-uri(.), .),
  stp:info('stp:list-pages-render', ("ok", xdmp:elapsed-time()))
};

(: Recursively load all files
 : TODO too long - refactor.
 :)
declare function stp:static-entries-insert(
  $version as xs:string,
  $entries as element(dir:entry)*,
  $pubs-dir as xs:string)
as empty-sequence()
{
  for $e in $entries return
  switch($e/dir:type)
  case 'file' return stp:static-file-insert(
    $version, $e/dir:pathname, $pubs-dir)
  case 'directory' return stp:static-entries-insert(
    $version,
    xdmp:filesystem-directory($e/dir:pathname)/dir:entry,
    $pubs-dir)
  default return ()
};

(: Load a static file.
 : TODO too long and too ugly - refactor.
 :)
declare function stp:static-file-insert(
  $version as xs:string,
  $path as xs:string,
  $pubs-dir as xs:string)
as empty-sequence()
{
  let $uri := concat("/apidoc/", $version,
    stp:static-uri-rewrite(
      translate(substring-after($path,
          $pubs-dir),"\","/")))
  let $is-mangled-html := ends-with($uri,'-members.html')
  let $is-html := ends-with($uri,'.html')
  let $is-jdoc := contains($uri,'/javadoc/') and $is-html
  let $is-js   := ends-with($uri,'.js')
  let $is-css  := ends-with($uri,'.css')
  let $tidy-options := <options xmlns="xdmp:tidy">
  <input-encoding>utf8</input-encoding>
  <output-encoding>utf8</output-encoding>
  <clean>true</clean>
  </options>

  (: If the document is JavaDoc HTML, then read it as text;
   if it's other HTML, repair it as XML (.NET docs)
   Also, add the ga and marketo scripts to the javadoc  :)
  (: don't tidy index.html because tidy throws away the frameset :)
  let $doc := if ( $is-jdoc and not(contains($uri, '/index.html')) )
  then xdmp:tidy(xdmp:document-get($path,
        <options xmlns="xdmp:document-get">
          <format>text</format>
          <encoding>auto</encoding>
        </options>), <options xmlns="xdmp:tidy">
                               <input-encoding>utf8</input-encoding>
                               <output-encoding>utf8</output-encoding>
                               <output-xhtml>no</output-xhtml>
                               <output-xml>no</output-xml>
                               <output-html>yes</output-html>
                             </options>)[2]
  else if ($is-mangled-html) then try {
    xdmp:log("TRYING FULL TIDY CONVERSION", 'fine'),
    let $unparsed := xdmp:document-get($path,
               <options xmlns="xdmp:document-get">
                 <format>text</format>
               </options>)/string(),
                   $replaced := replace($unparsed, '"class="', '" class="')
               return
               xdmp:unquote($replaced, "", "repair-full") }
             catch($e) { xdmp:log(fn:concat("Tidy FAILED for ", $path,
                                            " so loading as text")),
               xdmp:document-get($path, <options xmlns="xdmp:document-get">
                                           <encoding>auto</encoding>
                                         </options>)}
             else if ($is-html) then
            try {
             xdmp:log("TRYING FULL CONVERSION", 'fine'),
             xdmp:document-get($path, <options xmlns="xdmp:document-get">
                                        <format>xml</format>
                                        <repair>full</repair>
                                        <encoding>UTF-8</encoding>
                                      </options>) }
            catch($e){ if ($e/*:code eq 'XDMP-DOCUTF8SEQ') then
             xdmp:document-get($path, <options xmlns="xdmp:document-get">
                                        <format>xml</format>
                                        <repair>full</repair>
                                        <encoding>ISO-8859-1</encoding>
                                       </options>)
                        else error((),"Load error", xdmp:quote($e)) }
             else
               xdmp:document-get($path, <options xmlns="xdmp:document-get">
                                           <encoding>auto</encoding>
                                         </options>)

  (: Otherwise, just load the document normally :)
  (: Exclude these HTML and javascript documents from the search corpus
   (search the Tidy'd XHTML instead; see below) :)
  let $collection := "hide-from-search"[ $is-jdoc or $is-js or $is-css ]
  return (
    xdmp:document-insert(
      $uri,
      stp:static-add-scripts($doc),
      xdmp:default-permissions(),
      $collection),
    stp:debug("static-file-insert", ($path, "to", $uri)),

    (: If the document is HTML, then store an additional copy,
     : converted to XHTML using Tidy.
     : This is using the same mechanism as the CPF "convert-html" action,
     : except that this is done synchronously. This XHTML copy is
     : used for search, snippeting, etc.
     :)
    if (not($is-jdoc)) then () else (
      let  $xhtml := try {
        stp:fine(
          'static-file-insert',
          "TRYING FULL TIDY CONVERSION with xhtml:clean"),
        xhtml:clean(xdmp:tidy($doc, $tidy-options)[2]) }
      catch($e) {
        stp:info(
          'stp:static-file-insert',
          ($path, "failed tidy conversion with", $e/*:code)),
        $doc }
      let $xhtml-uri := replace($uri, "\.html$", "_html.xhtml")
      let $_ := stp:fine(
        'static-file-insert', ("Tidying", $path, "to", $xhtml-uri))
      return xdmp:document-insert($xhtml-uri, stp:static-add-scripts($xhtml))))
};

declare function stp:static-docs-insert(
  $src-dir as xs:string)
as empty-sequence()
{
  let $config := u:get-doc("/apidoc/config/static-docs.xml")/static-docs
  let $subdirs-to-load := $config/include/string()
  let $pubs-dir := concat($src-dir, '/pubs')
  (: Set the version outside the task server, before we spawn.
   : Otherwise the api library code will not see the request field.
   : TODO refactor.
   :)
  let $version := $api:version
  (: Load only the included directories :)
  for $included-dir in xdmp:filesystem-directory($pubs-dir)/dir:entry[
    dir:type eq 'directory'][
    dir:filename = $subdirs-to-load]/dir:pathname/string()
  let $_ := stp:info(
    "stp:static-docs-insert", ("including directory", $included-dir))
  return stp:static-entries-insert(
    $version,
    xdmp:filesystem-directory($included-dir)/dir:entry,
    $pubs-dir)
  ,
  (: Why load the zip? To support downloads? :)
  let $zip-file-name := concat(tokenize($src-dir,"/")[last()],".zip")
  let $zip-file-path := concat($src-dir, ".zip")
  let $zip-file      := xdmp:document-get($zip-file-path)
  let $zip-file-uri  := concat("/apidoc/",$zip-file-name)
  let $_ := stp:info(
    "stp:static-docs-insert", ("zip", $zip-file-name, "as", $zip-file-uri))
  return xdmp:document-insert($zip-file-uri, $zip-file)
  ,

  stp:info(
    'stp:static-docs-insert',
    ("Loaded static docs in", xdmp:elapsed-time()))
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

declare function stp:guide-convert(
  $version as xs:string,
  $guide as document-node()*)
as node()
{
  xdmp:xslt-invoke(
    "convert-guide.xsl", $guide,
    map:new(
      (map:entry('OUTPUT-URI', raw:target-guide-doc-uri($guide)),
        map:entry("VERSION", $version))))
};

declare function stp:guides-convert(
  $version as xs:string,
  $guides as document-node()*)
as empty-sequence()
{
  (: The slowest conversion is messages/XDMP-en.xml,
   : which always finishes last.
   :)
  for $g in $guides
  (:order by ends-with(xdmp:node-uri($g), '/XDMP-en.xml') descending:)
  let $start := xdmp:elapsed-time()
  let $converted := stp:guide-convert($version, $g)
  let $uri := base-uri($converted)
  let $_ := xdmp:document-insert($uri, $converted)
  let $_ := stp:debug(
    "stp:convert-guides", (base-uri($g), '=>', $uri,
      'in', xdmp:elapsed-time() - $start))
  return $uri
};

(: apidoc/setup/setup.xqm :)