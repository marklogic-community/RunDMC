xquery version "1.0-ml";

module namespace api="http://marklogic.com/rundmc/api";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace apidoc="http://marklogic.com/xdmp/apidoc";

import module namespace u="http://marklogic.com/rundmc/util"
  at "/lib/util-2.xqy";
import module namespace ml="http://developer.marklogic.com/site/internal"
  at "/model/data-access.xqy";

(: TODO refactor for #230. :)
declare variable $DOCUMENT-LIST as element(docs) := u:get-doc(
  '/apidoc/config/document-list.xml')/docs ;

declare variable $MODE-JAVASCRIPT := 'javascript' ;
declare variable $MODE-REST := 'REST' ;
declare variable $MODE-XPATH := 'xquery' ;
declare variable $MODES := ($MODE-JAVASCRIPT, $MODE-REST, $MODE-XPATH) ;

declare variable $NAMESPACE := "http://marklogic.com/rundmc/api" ;

declare variable $default-version as xs:string  := $ml:default-version ;
(: uniformly accessed in both the setup and view code
 : rather than using $params which only the view code uses
 : TODO refactor this out - does not work properly with spawn or invoke.
 :)
declare variable $version-specified as xs:string? := xdmp:get-request-field(
  "version") ;
declare variable $version as xs:string  := (
  if ($version-specified) then $version-specified
  else $default-version) ;

(: This variable is only used by the setup script,
 : because it's only in the setup scripts that we ever care about
 : more than one TOC URL at a time
 :
 : Its value must be the same as $toc-uri-location
 : when $version-specified is empty,
 : so the view code will get the right default TOC.
 :)
declare variable $toc-uri-default-version-location := "/apidoc/private/toc-uri.xml" ;
declare variable $toc-uri-location := concat(
  "/apidoc/private/",
  $version-specified,
  (if ($version-specified) then '/' else ''),
  "toc-uri.xml");

(: Using the alternative TOC location for now - i.e. if current version is the default,
   regardless of whether it was explicit, don't include the version number in links; see also $version-prefix in page.xsl; see also delete-old-toc.xqy :)
declare variable $toc-uri as xs:string := doc($toc-uri-location-alternative) ;

declare variable $toc-uri-location-alternative := (
  if ($version eq $default-version) then $toc-uri-default-version-location
  else $toc-uri-location) ;

declare variable $built-in-libs := api:get-libs(
  $version,
  api:query-for-builtin-functions($version),
  true(), $MODE-XPATH );
declare variable $library-libs  := api:get-libs(
  $version, api:query-for-library-functions($version),
  false(), $MODE-XPATH);

declare variable $LIBS-JAVASCRIPT := (
  if (number($version) lt 8) then ()
  else api:get-libs(
    $version,
    cts:element-attribute-value-query(
      xs:QName('api:function-page'),
      xs:QName('mode'),
      $MODE-JAVASCRIPT),
    true(), $MODE-JAVASCRIPT));

declare variable $M-NAMESPACES as map:map := (
  let $m := map:map()
  let $_ := (
    for $ns in u:get-doc(
      "/apidoc/config/namespace-mappings.xml")/namespaces/namespace
    let $_ := map:put($m, $ns/@lib, $ns)
    return ())
  return $m) ;

(: Replace "?" in the names of REST resources
 : with a character that will work in doc URIs
 :)
declare variable $REST-URI-QUESTIONMARK-SUBSTITUTE := "@";

(: TODO is XXX a placeholder? :)
declare variable $REST-LIBS := ('manage', 'XXX', 'rest-client') ;

declare variable $REST-COMPLEXTYPE-MAPPINGS := (
  (: This is sensitive to a bug in 7.0-2.3 (SUPPORT-13991),
   : so leave the expression alone until the bug is fixed.
   :)
  let $r := u:get-doc(
    '/apidoc/config/REST-complexType-mappings.xml')/resources
  return switch($version)
  case '5.0' return $r/marklogic6/resource (: TODO bug? :)
  case '6.0' return $r/marklogic6/resource
  case '7.0' return $r/marklogic7/resource[complexType/@name ne 'woops']
  (: TODO just a copy of ML7 for now. :)
  case '8.0' return $r/marklogic7/resource[complexType/@name ne 'woops']
  default return error((), 'UNEXPECTED', ('unknown version', $version))) ;

declare function api:version-dir($version as xs:string)
as xs:string
{
  concat("/apidoc/", $version, "/")
};

(: TODO this seems convoluted and expensive. Really a group-by? :)
declare function api:get-libs(
  $version as xs:string,
  $query as cts:query,
  $builtin as xs:boolean,
  $mode as xs:string)
as element(api:lib)*
{
  for $lib in cts:element-attribute-values(
    xs:QName("api:function"), xs:QName("lib"),
    (), "ascending", $query)
  return element api:lib {
    attribute category-bucket { api:get-bucket-for-lib($version, $lib) },
    if (not($builtin)) then ()
    else attribute built-in { true() },
    attribute mode { $mode },
    $lib }
};

declare function api:query-for-all-functions(
  $version as xs:string)
as cts:query
{
  cts:and-query(
    (cts:directory-query(api:version-dir($version), "infinity"),
      cts:element-query(xs:QName("api:function"), cts:and-query(()))))
};

declare function api:query-for-builtin-functions(
  $version as xs:string)
as cts:query
{
  cts:and-query(
    (api:query-for-all-functions($version),
      cts:element-attribute-value-query(
        xs:QName("api:function"), xs:QName("type"), "builtin")))
};

declare function api:query-for-lib-functions(
  $version as xs:string,
  $lib as xs:string)
as cts:query
{
  cts:and-query(
    (api:query-for-all-functions($version),
      cts:element-attribute-value-query(
        xs:QName("api:function"), xs:QName("lib"), $lib)))
};

(: Every function that is not a built-in function is a library function :)
declare function api:query-for-library-functions(
  $version as xs:string)
as cts:query
{
  cts:and-not-query(
    api:query-for-all-functions($version),
    api:query-for-builtin-functions($version))
};

declare function api:functions(
  $version as xs:string)
as document-node()+
{
  cts:search(
    collection(),
    api:query-for-all-functions($api:version),
    "unfiltered")
};

(: Used to associate library containers under the "API" tab
 : with corresponding "Categories" tab TOC container.
 :)
declare function api:get-bucket-for-lib(
  $version as xs:string,
  $lib as xs:string)
as xs:string*
{
  cts:search(collection(), api:query-for-lib-functions($version, $lib))[1]
  /api:function-page/api:function[1]/@bucket
};

(: Returns the namespace associated with the given lib name. :)
declare function api:namespace(
  $lib as xs:string)
as element(namespace)?
{
  map:get($M-NAMESPACES, $lib)
};

(: Normally just use the lib name as the prefix,
 : unless specially configured to do otherwise.
 :)
declare function api:prefix-for-lib(
  $lib as xs:string)
as xs:string?
{
  (api:namespace($lib)/@prefix,
    $lib)[1]
};

(: E.g., store the images for /apidoc/4.2/guides/performance.xml
 : in /media/apidoc/4.2/guides/performance/
 :)
declare function api:guide-image-dir($page-uri as xs:string)
as xs:string
{
  concat("/media", substring-before($page-uri, ".xml"), "/")
};

declare function api:guide-info(
  $content as node(),
  $url-name as attribute())
as element()?
{
  if (1) then () else xdmp:log(
    text {
      '[api:guide-info]', xdmp:describe($content), $url-name/string() }),
  let $suffix := concat('/', $url-name)
  return $content/*/api:user-guide[ends-with(@href, $suffix)]
};

declare function api:translate-REST-resource-name(
  $name as xs:string)
as xs:string
{
  (: ASSUMPTION: The examples to the right, other than the letters used,
   are the only fixed patterns supported here. A new pattern (such as
   more than two "|" alternatives, or alternatives in a different order)
   would require a code update here.
   :)

  (: Step 1: strip trailing slash :)
  (:      /manage/v1/ => /manage/v1          :)
  let $step1 := replace($name, '/$', '')

  (: Step 2: handle the special parenthesized alternatives
   pattern of this form: (default|{name}) :)
  (: (default|{name}) => ['default'-or-name] :)
  let $step2 := replace(
    $step1,
    '\( ([^|)]+)  \|  \{ ([^}]+) \}  \)',
    "['$1'-or-$2]", 'x')

  (: Step 3: handle the braced alternatives :)
  (:        {id|name} => [id-or-name]        :)
  let $step3 := replace(
    $step2,
    '\{ ([^|}]+)  \|  ([^}]+) \}',
    '[$1-or-$2]', 'x')

  (: Step 4: replace remaining brackets with square brackets :)
  (:           {name} => [name]              :)
  (:           (name) => [name]              :)
  let $step4 := translate($step3, '{}()', '[][]')

  (: Step 4: replace ? with @ :)
  return replace($step4, '\?', $REST-URI-QUESTIONMARK-SUBSTITUTE)
};

(: E.g.,          "/v1/rest-apis/[name] (GET)"
 : ==> "/REST/GET/v1/rest-apis/*"
 :)
declare function api:REST-fullname-to-external-uri(
  $fullname as xs:string)
as xs:string
{
  concat('/REST/',
    api:verb-from-REST-fullname($fullname),
    api:translate-REST-resource-name(
      api:name-from-REST-fullname($fullname)))
};

(: This handles the local-name or full name. :)
declare function api:javascript-name(
  $name as xs:string)
as xs:string
{
  translate(
    (: Underscores are simple, but probably camel-case is better. :)
    if (false()) then translate($name, '-', '_')
    (: camel-case :)
    else (
      let $toks := tokenize($name, '[\-]+')[.]
      return string-join(
        ($toks[1],
        subsequence($toks, 2)
          ! concat(
            upper-case(substring(., 1, 1)),
            substring(., 2))),
        '')),
    ':', '.')
};

(: Example input:  <function name="/v1/rest-apis/{name}" http-verb="GET"/>
 : Example output: "/v1/rest-apis/[name] (GET)"
 :)
declare function api:REST-fullname(
  $e as element(apidoc:function))
{
  concat(
    api:translate-REST-resource-name($e/@name),
    ' (',
    ($e/@http-verb, 'GET')[1],
    ')')
};

(: The fullname is a derived value :)
declare function api:fixup-fullname(
  $function as element(apidoc:function),
  $mode as xs:string)
as xs:string
{
  (: REST docs (lib="manage" in the raw source)
   : should not have a namespace prefix in the full name.
   :)
  switch($mode)
  case $MODE-REST return api:REST-fullname($function)
  case $MODE-JAVASCRIPT return concat(
    $function/@lib, '.', api:javascript-name($function/@name))
  (: Covers MODE-XPATH and any unknown values. :)
  default return concat(
    $function/@lib, ':', $function/@name)
};

(: As long as we have complete information,
 : we can detect the mode of the function element.
 :)
declare function api:function-detect-mode(
  $function as element(apidoc:function))
as xs:string
{
  $function/parent::apidoc:function-page/@mode
};

(: Determine the document URI for a function page. :)
declare function api:external-uri(
  $function as element(apidoc:function),
  $mode as xs:string?)
as xs:string
{
  (: This is sensitive to a bug in 7.0-2.3 (SUPPORT-13991),
   : so leave the expression alone until the bug is fixed.
   :)
  let $fullname := api:fixup-fullname($function, $mode)
  return switch($mode)
  case $MODE-REST return api:REST-fullname-to-external-uri($fullname)
  default return concat('/', $fullname)
};

(: Use this for non-function nodes. :)
declare function api:external-uri($n as node())
  as xs:string
{
  typeswitch($n)
  case element(apidoc:function) return error((), 'UNEXPECTED', $n)
  default return ml:external-uri-api($n)
};

(: ASSUMPTION: This is only called on version-less paths,
 : as they appear in the XML TOCs.
 :)
declare function api:internal-uri(
  $doc-path as xs:string)
as xs:string
{
  concat(
    '/apidoc/', $version,
    if ($doc-path eq '/') then '/index.xml'
    else concat(ml:escape-uri($doc-path), '.xml'))
};

(: E.g.,     "/v1/rest-apis/[name] (GET)"
 : ==> "GET /v1/rest-apis/[name]"
 :)
declare function api:REST-resource-heading(
  $fullname)
{
  concat(
    api:verb-from-REST-fullname($fullname),
    ' ',
    api:reverse-translate-REST-resource-name(
      api:name-from-REST-fullname($fullname)))
};

(: Wildcards (*) provide an easier, consistent way to
 guess the API doc page's URL.
 E.g., /v1/rest-apis/[name]
 : ==>  /v1/rest-apis/*
 :)
declare function api:REST-name-with-wildcards(
  $resource-name)
{
  replace($resource-name,
    '\[ [^\]]+ \]',
    '*',
    'x')
};

(: E.g., "/v1/rest-apis/[name] (GET)"
 : ==> "GET"
 :)
declare function api:verb-from-REST-fullname(
  $fullname as xs:string)
as xs:string
{
  substring-before( substring-after(
      $fullname,' (' ), ')')
};

(: E.g., "/v1/rest-apis/[name] (GET)"
 : ==> "/v1/rest-apis/[name]"
 :)
declare function api:name-from-REST-fullname(
  $fullname as xs:string)
as xs:string
{
  substring-before( $fullname,' (' )
};

declare function api:verb-sort-key-from-REST-fullname(
  $fullname as xs:string)
as xs:integer?
{
  let $verb-list := ('PATCH', 'GET', 'POST', 'PUT', 'HEAD', 'DELETE')
  let $verb := api:verb-from-REST-fullname($fullname)
  return index-of($verb-list, $verb)
};

(: This is intended to be temporary, with the idea that the docs
 : themselves could migrate to using the square-brackets notation
 instead...
 :)
declare function api:reverse-translate-REST-resource-name(
  $name)
{
  (: ASSUMPTION: Same assumption as above.
   : Only these fixed patterns are supported.
   :)

  (: Step 1: convert back to this form: (default|{name}) :)
  (: ['default'-or-name] => (default|{name}) :)
  let $step1 := replace(
    $name,
    "\['  ([^']+)  '-or-  ([^\]]+)  \]",
    '($1|{$2})', 'x')

  (: Step 2: convert back to the braced alternatives :)
  (:        [id-or-name] => {id|name}        :)
  let $step2 := replace(
    $step1,
    '\[ ([^\]\-]+)  -or-  ([^\]]+) \]',
    '{$1|$2}', 'x')

  (: Step 3: replace remaining brackets with braces :)
  (:   [name] => {name}           :)
  let $step3 := translate($step2, '[]', '{}')

  (: Step 4: replace @ with ? :)
  return replace($step3, $REST-URI-QUESTIONMARK-SUBSTITUTE, '?')
};

declare function api:lookup-REST-complexType(
  $resource-name as xs:string)
as xs:string?
{
  $REST-COMPLEXTYPE-MAPPINGS[
    @name eq $resource-name]/complexType/@name
};

(: Used by extract-functions.xsl
 : This fakes mode=javascript so we can test for it on.
 :)
declare function api:function-fake-javascript(
  $function as element(apidoc:function))
as element(apidoc:function)?
{
  if (not($function/@bucket = (
      'MarkLogic Built-In Functions',
      'W3C-Standard Functions'))) then ()
  else element apidoc:function {
    attribute mode { $MODE-JAVASCRIPT },
    $function/@*,
    $function/node() }
};

(: Used by extract-functions.xsl :)
declare function api:module-extractable-functions(
  $module as element(apidoc:module),
  $mode as xs:string?)
as element(apidoc:function)*
{
  switch($mode)
  (: Fake a raw doc, creating all the necessary context.  :)
  case $MODE-JAVASCRIPT return document {
    element apidoc:module {
      attribute xml:base { base-uri($module) },
      attribute mode { $MODE-JAVASCRIPT },
      api:function-fake-javascript(
        $module/apidoc:function[
          not(api:fixup-fullname(., ()) =
            preceding-sibling::apidoc:function/api:fixup-fullname(., ()))])
      } }/apidoc:module/apidoc:function
  default return $module/apidoc:function[
    not(api:fixup-fullname(., ()) =
      preceding-sibling::apidoc:function/api:fixup-fullname(., ()))]
};

declare function api:external-uri-with-prefix(
  $version-prefix as xs:string,
  $internal-uri as xs:string)
as xs:string
{
  $version-prefix
  ||ml:external-uri-for-string($internal-uri)
};

(: Used by page.xsl :)
declare function api:toc-section-link-selector(
  $e as element(),
  $version-prefix as xs:string)
as xs:string
{
  typeswitch($e)
  (: function lib page link :)
  case element(api:function-page) return (
    (: TODO needs to supply parent lib also? :)
    ".scrollable_section a[href='"
    ||$version-prefix
    ||(switch($e/@mode)
      case $api:MODE-JAVASCRIPT return '/js/'
      default return '/')
    ||$e/api:function[1]/@lib
    ||"']")
  case element(guide) return (
    ".scrollable_section a[href='"
    ||api:external-uri-with-prefix($version-prefix, $e/@guide-uri)
    ||"']")
  case element(chapter) return (
    ".scrollable_section a[href='"
    ||api:external-uri-with-prefix($version-prefix, $e/@guide-uri)
    ||"']")
  case element(api:help-page) return (
    '#'
    ||$e/@container-toc-section-id
    ||' >:first-child')
  case element(api:list-page) return (
    (switch($e/@mode)
      case $api:MODE-JAVASCRIPT return '#js_'
      default return '#')
    ||$e/@container-toc-section-id
    ||' >:first-child')
  (: Message page for error code, without any TOC data. :)
  case element(message) return $e/@id
  (: On the main docs page, just let the first tab be selected by default. :)
  case element(api:docs-page) return ''
  default return error((), 'UNEXPECTED', xdmp:describe($e))
};

(: apidoc/model/data-access.xqy :)