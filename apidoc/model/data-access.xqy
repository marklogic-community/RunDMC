xquery version "1.0-ml";

module namespace api="http://marklogic.com/rundmc/api";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace apidoc="http://marklogic.com/xdmp/apidoc";

import module namespace u="http://marklogic.com/rundmc/util"
  at "/lib/util-2.xqy";
import module namespace ml="http://developer.marklogic.com/site/internal"
  at "/model/data-access.xqy";

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
declare variable $toc-uri-default-version-location := concat(
  "/apidoc/private/", "toc-uri.xml");
declare variable $toc-uri-location := concat(
  "/apidoc/private/",
  $version-specified,
  (if ($version-specified) then '/' else ''),
  "toc-uri.xml");

(: The URL of the current TOC (based on whatever version the user has requested) :)
(:
declare variable $toc-uri := string(doc($toc-uri-location)/*);
:)
(: Using the alternative TOC location for now - i.e. if current version is the default,
   regardless of whether it was explicit, don't include the version number in links; see also $version-prefix in page.xsl; see also delete-old-toc.xqy :)
declare variable $toc-uri := string(doc($toc-uri-location-alternative)/*);

declare variable $toc-uri-location-alternative := if ($version eq $default-version) then $toc-uri-default-version-location
                                                                                                else $toc-uri-location;

declare variable $VERSION-DIR := concat("/apidoc/", $version, "/");

(: Thing is... we always look at every single function. So why search? :)
declare variable $query-for-all-functions :=
  cts:and-query((
    (: REST "function" docs are in sub-directories :)
    cts:directory-query($VERSION-DIR, "infinity"),
    cts:element-query(xs:QName("api:function"), cts:and-query(()))
  ));

declare variable $query-for-builtin-functions := cts:and-query(
  ($query-for-all-functions,
    cts:element-attribute-value-query(
      xs:QName("api:function"), xs:QName("type"),
      "builtin"))) ;

(: Every function that's not a built-in function is a library function :)
declare variable $query-for-library-functions := cts:and-not-query(
  $query-for-all-functions,
  $query-for-builtin-functions) ;

(: Used only by TOC-generating code :)
declare variable $all-function-docs := cts:search(
  collection(), $query-for-all-functions, "unfiltered") ;

(: TODO is the bucket check obsolete? Make it so? :)
declare variable $ALL-FUNCTIONS-JAVASCRIPT := (
  if (number($version) lt 8) then ()
  else $all-function-docs[
    api:function-page[@mode eq 'javascript']/api:function/@bucket = (
      'MarkLogic Built-In Functions',
      'W3C-Standard Functions')]) ;

declare variable $all-functions-count     := xdmp:estimate(
  cts:search(collection(),$query-for-all-functions));
declare variable $built-in-function-count := xdmp:estimate(
  cts:search(collection(),$query-for-builtin-functions));
declare variable $library-function-count  := xdmp:estimate(
  cts:search(collection(),$query-for-library-functions));

declare variable $built-in-libs := api:get-libs(
  $query-for-builtin-functions, true(), 'xpath' );
declare variable $library-libs  := api:get-libs(
  $query-for-library-functions, false(), 'xpath');

declare variable $LIBS-JAVASCRIPT := (
  if (number($version) lt 8) then ()
  else api:get-libs(
    cts:element-attribute-value-query(
      xs:QName('api:function-page'),
      xs:QName('mode'),
      'javascript'),
    true(), 'javascript'));

declare variable $namespace-mappings := u:get-doc(
  "/apidoc/config/namespace-mappings.xml")/namespaces/namespace ;

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

(: TODO this seems convoluted and expensive. Really a group-by? :)
declare function api:get-libs(
  $query as cts:query,
  $builtin as xs:boolean,
  $mode as xs:string)
as element(api:lib)*
{
  for $lib in cts:element-attribute-values(
    xs:QName("api:function"), xs:QName("lib"),
    (), "ascending", $query)
  return element api:lib {
    attribute category-bucket { api:get-bucket-for-lib($lib) },
    if (not($builtin)) then ()
    else attribute built-in { true() },
    attribute mode { $mode },
    $lib }
};

declare function api:query-for-lib-functions(
  $lib as xs:string)
as cts:query
{
  cts:and-query(
    ($query-for-all-functions,
      cts:element-attribute-value-query(
        xs:QName("api:function"), xs:QName("lib"), $lib)))
};

(: Used to associate library containers under the "API" tab
 : with corresponding "Categories" tab TOC container.
 :)
declare function api:get-bucket-for-lib(
  $lib as xs:string)
as xs:string*
{
  cts:search(collection(), api:query-for-lib-functions($lib))[1]
  /api:function-page/api:function[1]/@bucket
};

(: Returns the namespace URI associated with the given lib name :)
declare function api:uri-for-lib($lib)
as xs:string?
{
  $namespace-mappings[@lib eq $lib]/@uri
};

(: Normally just use the lib name as the prefix,
 : unless specially configured to do otherwise.
 :)
declare function api:prefix-for-lib(
  $lib as xs:string)
as xs:string?
{
  $namespace-mappings[@lib eq $lib]/(
    if (@prefix) then @prefix else $lib)
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

(: Example input:  <function name="/v1/rest-apis/{name}" http-verb="GET"/>
 : Example output: "/v1/rest-apis/[name] (GET)"
 :)
declare function api:REST-fullname(
    $e as element())
{
  concat(
    api:translate-REST-resource-name($e/@name),
    ' (',
    ($e/@http-verb, 'GET')[1],
    ')')
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
  case 'REST' return api:REST-fullname($function)
  case 'javascript' return concat(
    $function/@lib, '.', api:javascript-name($function/@name))
  (: Covers mode=xpath and any unknown values. :)
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
  case 'REST' return api:REST-fullname-to-external-uri($fullname)
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
  $fullname)
{
  substring-before( substring-after(
      $fullname,' (' ), ')')
};

(: E.g., "/v1/rest-apis/[name] (GET)"
 : ==> "/v1/rest-apis/[name]"
 :)
declare function api:name-from-REST-fullname(
  $fullname)
{
  substring-before( $fullname,' (' )
};

declare function api:verb-sort-key-from-REST-fullname(
  $fullname)
{
  let $verb-list := ('GET','POST','PUT','HEAD','DELETE')
  let $verb := api:verb-from-REST-fullname($fullname)
  return index-of($verb-list,$verb)
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
    attribute mode { 'javascript' },
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
  case 'javascript' return document {
    element apidoc:module {
      attribute xml:base { base-uri($module) },
      attribute mode { 'javascript' },
      api:function-fake-javascript(
        $module/apidoc:function[
          not(api:fixup-fullname(., ()) =
            preceding-sibling::apidoc:function/api:fixup-fullname(., ()))])
      } }/apidoc:module/apidoc:function
  default return $module/apidoc:function[
    not(api:fixup-fullname(., ()) =
      preceding-sibling::apidoc:function/api:fixup-fullname(., ()))]
};

(: apidoc/model/data-access.xqy :)