xquery version "1.0-ml";

module namespace api="http://marklogic.com/rundmc/api";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace u="http://marklogic.com/rundmc/util"
  at "/lib/util-2.xqy";
import module namespace ml="http://developer.marklogic.com/site/internal"
  at "/model/data-access.xqy";
import module namespace toc="http://marklogic.com/rundmc/api/toc"
  at "/apidoc/setup/toc.xqm";

import module namespace c="http://marklogic.com/rundmc/api/controller"
  at "/apidoc/controller/controller.xqm";

declare namespace apidoc="http://marklogic.com/xdmp/apidoc";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";

declare variable $MODE-JAVASCRIPT := 'javascript' ;
declare variable $MODE-REST := 'REST' ;
declare variable $MODE-XPATH := 'xquery' ;
declare variable $MODES := ($MODE-JAVASCRIPT, $MODE-REST, $MODE-XPATH) ;

declare variable $NAMESPACE := "http://marklogic.com/rundmc/api" ;

declare variable $DEFAULT-VERSION as xs:string  := $ml:default-version ;

declare private variable $DOCUMENT-LIST-CACHED := () ;

declare private variable $GUIDES-MAP := () ;

(: Used by page.xsl to write ajax URL for toc_filter.js :)
declare variable $TOC-URI-DEFAULT := "/apidoc/private/toc-uri.xml" ;

declare variable $M-NAMESPACES as map:map := (
  let $m := map:map()
  let $_ := (
    for $ns in u:get-doc(
      "/apidoc/config/namespace-mappings.xml")/namespaces/namespace
    let $_ := map:put($m, $ns/(@lib | @object), $ns)
    return ())
  return $m) ;

declare variable $M-OBJECTS := (
  u:get-doc(
      "/apidoc/config/namespace-mappings.xml")/namespaces/namespace/@object )
;


declare private variable $REST-COMPLEXTYPE-MAPPINGS := () ;

(: Replace "?" in the names of REST resources
 : with a character that will work in doc URIs
 :)
declare variable $REST-URI-QUESTIONMARK-SUBSTITUTE := "@";

declare variable $TYPE-JS-PAT := '(.+[^\?\*\+])([\?\*\+])?' ;

declare function api:version-dir($version as xs:string)
as xs:string
{
  if (matches($version, '^\d+\.\d+$')) then concat("/apidoc/", $version, "/")
  else error((), 'APIDOC-BADVERSION', xdmp:describe($version))
};

(: TODO move to toc.xqm? :)
declare function api:toc-uri-location(
  $version-specified as xs:string)
as xs:string
{
  concat(
    "/apidoc/private/",
    $version-specified,
    (if ($version-specified) then '/' else ''),
    "toc-uri.xml")
};

declare function api:toc-uri-location-alternative(
  $version as xs:string,
  $version-specified as xs:string?)
{
  if ($version eq $DEFAULT-VERSION) then $TOC-URI-DEFAULT
  else if (not($version-specified)) then $TOC-URI-DEFAULT
  else api:toc-uri-location($version-specified)
};

(: Using the alternative TOC location for now.
 : So if current version is the default,
 : regardless of whether it was explicit,
 : don't include the version number in links.
 : See also $version-prefix in page.xsl, delete-old-toc.xqy.
 :)
declare function api:toc-uri(
  $version as xs:string,
  $version-specified as xs:string?)
as xs:string
{
  doc(api:toc-uri-location-alternative($version, $version-specified))
};

(: Specifically for page.xsl via HTTP request. :)
declare function api:toc-uri()
as xs:string
{
  let $version-specified as xs:string? := c:http-request-version()
  return api:toc-uri(
    c:version($version-specified), $version-specified)
};

declare function api:query-by-mode(
  $mode as xs:string)
as cts:query
{
  cts:element-attribute-value-query(
    xs:QName('api:function-page'), xs:QName('mode'), $mode)
};

declare function api:query-by-version(
  $version as xs:string,
  $extra as cts:query*)
as cts:query
{
  cts:directory-query(api:version-dir($version), "infinity")
  ! (if (empty($extra)) then .
    else cts:and-query((., $extra)))
};

declare function api:query-for-functions(
  $version as xs:string,
  $extra as cts:query*)
as cts:query
{
  api:query-by-version(
    $version,
    (cts:element-query(xs:QName("api:function"), cts:and-query(())),
      $extra))
};

declare function api:query-for-functions(
  $version as xs:string,
  $mode as xs:string,
  $extra as cts:query*)
as cts:query
{
  api:query-for-functions(
    $version,
    (api:query-by-mode($mode),
      $extra))
};

declare function api:query-for-functions(
  $version as xs:string)
as cts:query
{
  api:query-for-functions(
    $version, ())
};

declare function api:query-for-builtin-functions(
  $version as xs:string,
  $mode as xs:string)
as cts:query
{
  api:query-for-functions(
    $version, $mode,
    cts:element-attribute-value-query(
      xs:QName("api:function"), xs:QName("type"), "builtin"))
};

declare function api:query-for-user-functions(
  $version as xs:string,
  $mode as xs:string)
as cts:query
{
  api:query-for-functions(
    $version, $mode,
    cts:not-query(
      cts:element-attribute-value-query(
        xs:QName("api:function"), xs:QName("type"), "builtin")))
};

declare function api:query-for-lib-functions(
  $version as xs:string,
  $mode as xs:string,
  $lib as xs:string)
as cts:query
{
  api:query-for-functions(
    $version, $mode,
    cts:element-attribute-value-query(
      xs:QName("api:function"), xs:QName("lib"), $lib))
};

(: Used to associate library containers under the "API" tab
 : with corresponding "Categories" tab TOC container.
 :)
declare function api:get-bucket-for-lib(
  $version as xs:string,
  $mode as xs:string,
  $lib as xs:string)
as xs:string
{
let $bucket :=
  cts:search(
    collection(), api:query-for-lib-functions($version, $mode, $lib))[1]
  /api:function-page/api:function[1]/@bucket
return
if (fn:empty($bucket)) then 'MarkLogic Built-In Functions' else $bucket
};

(: TODO this seems convoluted and expensive. Really a group-by? :)
declare function api:get-libs(
  $version as xs:string,
  $mode as xs:string,
  $extra as cts:query*,
  $builtin as xs:boolean)
as element(api:lib)*
{
  if ($mode eq $MODE-JAVASCRIPT and number($version) lt 8) then ()
  else
  let $q := api:query-for-functions($version, $mode, $extra)
  let $list := cts:element-attribute-values(
    xs:QName("api:function"), (xs:QName("lib"), xs:QName("object")),
    (), "ascending", $q)
  for $lib in $list
  return element api:lib {
    attribute mode { $mode },
    if (not($builtin)) then ()
    else attribute built-in { true() },
    attribute category-bucket {
      api:get-bucket-for-lib($version, $mode, $lib) },
    $lib }
};

declare function api:libs-all(
  $version as xs:string,
  $mode as xs:string)
as element(api:lib)*
{
  (: TODO Does it cause any problems to set builtin when we want both? :)
  api:get-libs($version, $mode, (), true())
};

declare function api:libs-user(
  $version as xs:string,
  $mode as xs:string)
as element(api:lib)*
{
  api:get-libs(
    $version, $mode,
    api:query-for-user-functions($version, $mode), false())
};

declare function api:libs-builtin(
  $version as xs:string,
  $mode as xs:string)
as element(api:lib)*
{
  api:get-libs(
    $version, $mode,
    api:query-for-builtin-functions($version, $mode), true())
};

declare function api:functions-all(
  $version as xs:string)
as document-node()+
{
  cts:search(
    collection(),
    api:query-for-functions($version),
    "unfiltered")
};

(: Returns the namespace associated with the given lib name. :)
declare function api:namespace(
  $lib as xs:string)
as element(namespace)?
{
  map:get($M-NAMESPACES, $lib)
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

declare function api:maybe-init-guides-map(
  $version as xs:string,
  $content-uri-external as xs:string)
as empty-sequence()
{
  if (exists($GUIDES-MAP)) then () else xdmp:set(
    $GUIDES-MAP,
    let $docs-page as element(api:docs-page) := doc(
      api:internal-uri($version, '/'))/*
    return map:new(
      (map:map($docs-page/auto-links/map:map),
        (: TODO build map during setup, without breaking api:guide-info. :)
        let $other-guide-listings as element(api:user-guide)+ := (
          $docs-page/api:user-guide[
            not(@href eq $content-uri-external) ][
            @display|alias ])
        for $n in $other-guide-listings
        return $n/(@display|alias)/map:entry(
          u:string-normalize(.), $n/@href/string()))))
};

declare function api:config-for-title(
  $link as xs:string)
as xs:string?
{
  map:get($GUIDES-MAP, u:string-normalize($link))
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

declare function api:camel-case($toks as xs:string+)
  as xs:string
{
  string-join(
    ($toks[1],
      subsequence($toks, 2)
      ! concat(
        upper-case(substring(., 1, 1)),
        substring(., 2))),
    '')
};

(: This handles the local-name or full name. :)
declare function api:javascript-name(
  $name as xs:string,
  $override as xs:string?)
as xs:string
{
  if ($override) then $override
  else translate(
    api:camel-case(tokenize($name, '[\-]+')[.]),
    ':', '.')
};

declare function api:javascript-name(
  $function as element())
as xs:string
{
(: add test because loosened the $function signature :)
if ($function instance of element(apidoc:function)) 
then () 
else if ($function instance of element(apidoc:method))
     then ()
     else (fn:error((), "APIDOC-UNKNOWNELEMENT", "Element must be either 
          element(apidoc:function) or element(apidoc:method)")) ,

  api:javascript-name(
    $function/@name,
    $function/apidoc:name[@class eq 'javascript'])
};

(: Example input:  <function name="/v1/rest-apis/{name}" http-verb="GET"/>
 : Example output: "/v1/rest-apis/[name] (GET)"
 :)
declare function api:REST-fullname(
  $e as element(),
  $prefix as xs:boolean)
as xs:string
{
(: add test because loosened the $e signature :)
if ($e instance of  element(apidoc:function)) 
then () 
else if ($e instance of element(apidoc:method))
     then ()
     else (fn:error((), "APIDOC-UNKNOWNELEMENT", "Element must be either 
          element(apidoc:function) or element(apidoc:method)")) ,

  if ($prefix) then concat(
    ($e/@http-verb, 'GET')[1],
    ':',
    api:translate-REST-resource-name($e/@name))
  else concat(
    api:translate-REST-resource-name($e/@name),
    ' (',
    ($e/@http-verb, 'GET')[1],
    ')')
};

declare function api:REST-fullname(
  $e as element())
as xs:string
{
(: add test because loosened the $e signature :)
if ($e instance of element(apidoc:function)) 
then () 
else if ($e instance of element(apidoc:method))
     then ()
     else (fn:error((), "APIDOC-UNKNOWNELEMENT", "Element must be either 
          element(apidoc:function) or element(apidoc:method)")) ,


  api:REST-fullname($e, false())
};

(: The fullname is a derived value :)
declare function api:fixup-fullname(
  $function as element(),
  $mode as xs:string,
  $prefix as xs:boolean)
as xs:string
{
(: add test because loosened the $function signature :)
if ($function  instance of element(apidoc:function)) 
then () 
else if ($function instance of element(apidoc:method))
     then ()
     else (fn:error((), "APIDOC-UNKNOWNELEMENT", "Element must be either 
          element(apidoc:function) or element(apidoc:method)")) ,


  (: REST docs (lib="manage" in the raw source)
   : should not have a namespace prefix in the full name.
   :)
  switch($mode)
  case $MODE-REST return api:REST-fullname($function, $prefix)
  case $MODE-JAVASCRIPT return concat(
    (: should have exactly one of @lib or @object :)
    $function/@lib, $function/@object,  '.', api:javascript-name($function))
  (: Covers MODE-XPATH and any unknown values. :)
  default return concat(
    $function/@lib, ':', $function/@name)
};

declare function api:fixup-fullname(
  $function as element(),
  $mode as xs:string)
as xs:string
{
(: add test because loosened the $function signature :)
if ($function instance of element(apidoc:function)) 
then () 
else if ($function instance of element(apidoc:method))
     then ()
     else (fn:error((), "APIDOC-UNKNOWNELEMENT", "Element must be either 
          element(apidoc:function) or element(apidoc:method)")) ,


  api:fixup-fullname($function, $mode, false())
};

(: As long as we have complete information,
 : we can detect the mode of the function element.
 :)
declare function api:function-detect-mode(
  $function as element())
as xs:string
{
(: add test because loosened the $function signature :)
if ($function instance of element(apidoc:function)) 
then () 
else if ($function instance of element(apidoc:method))
     then ()
     else (fn:error((), "APIDOC-UNKNOWNELEMENT", "Element must be either 
          element(apidoc:function) or element(apidoc:method)")) ,


  $function/parent::apidoc:function-page/@mode
};

(: Determine the document URI for a function page. :)
declare function api:external-uri(
  $function as element(),
  $mode as xs:string?)
as xs:string
{
(: add test because loosened the $function signature :)
if ($function instance of element(apidoc:function)) 
then () 
else if ($function instance of element(apidoc:method))
     then ()
     else (fn:error((), "APIDOC-UNKNOWNELEMENT", "Element must be either 
          element(apidoc:function) or element(apidoc:method)")) ,


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
  case element(apidoc:method) return error((), 'UNEXPECTED', $n)
  default return ml:external-uri-api($n)
};

(: ASSUMPTION: This is only called on version-less paths,
 : as they appear in the XML TOCs.
 :)
declare function api:internal-uri(
  $version as xs:string,
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

(: This might be a hot-spot,
 : so cache the filesystem document in a module variable.
 : ASSUMPTION = We only process one version per request.
 :)
declare function api:rest-complextype-mappings(
  $version as xs:string)
as element(resource)+
{
  if ($REST-COMPLEXTYPE-MAPPINGS) then $REST-COMPLEXTYPE-MAPPINGS else (
    let $resources := (
      (: This is sensitive to a bug in 7.0-2.3 (SUPPORT-13991),
       : so leave the expression alone until the bug is fixed.
       :)
      let $r := u:get-doc(
        '/apidoc/config/REST-complexType-mappings.xml')/resources
      return switch($version)
      case '5.0' (: No ML5 in config file, so fall through to ML6. :)
      case '6.0' return $r/marklogic6/resource
      case '7.0' return $r/marklogic7/resource[complexType/@name ne 'woops']
      (: TODO just a copy of ML7 for now. :)
      case '8.0' return $r/marklogic7/resource[complexType/@name ne 'woops']
      default return error((), 'UNEXPECTED', ('unknown version', $version)))
    let $_ := xdmp:set($REST-COMPLEXTYPE-MAPPINGS, $resources)
    return $resources)
};

declare function api:lookup-REST-complexType(
  $version as xs:string,
  $resource-name as xs:string)
as xs:string?
{
  api:rest-complextype-mappings($version)[
    @name eq $resource-name]/complexType/@name
};

declare function api:has-mode-class(
  $e as element(),
  $mode as xs:string+)
as xs:boolean
{
  (: Test for mode-specific content, ignoring unknown classes.
   :)
  let $includes := xs:NMTOKENS($e/@class)[. eq $api:MODES]
  return empty($includes) or $includes = $mode
};

declare function api:function-appears-in-mode(
  $function as element(),
  $mode as xs:string)
as xs:boolean
{
(: add test because loosened the $function signature :)
if ($function instance of element(apidoc:function)) 
then () 
else if ($function instance of element(apidoc:method))
     then ()
     else (fn:error((), "APIDOC-UNKNOWNELEMENT", "Element must be either 
          element(apidoc:function) or element(apidoc:method)")) ,

  (switch($mode)
    case $MODE-JAVASCRIPT return ( 
       $function/@bucket = (
        'MarkLogic Built-In Functions',
        'W3C-Standard Functions',
        'XQuery Library Modules',
        'JavaScript Library Modules')  )
    case $MODE-REST return starts-with($function/@name, '/')
    (: needs to return false for js-only libraries and for REST :)
    case $MODE-XPATH return 
         not(starts-with($function/@name, '/')) and
         not($function/@bucket eq 'JavaScript Library Modules')
    default return error((), 'UNEXPECTED', ($mode)))
  (: Also apply class exclusion rules. :)
  and api:has-mode-class($function, $mode)
};

(: Used by setup.xqm
 : This fakes mode=javascript so we can test for it later on.
 :)
declare function api:function-fake-javascript(
  $function as element())
as element(apidoc:function)?
{
(: add test because loosened the $function signature :)
if ($function instance of element(apidoc:function)) 
then () 
else if ($function instance of element(apidoc:method))
     then ()
     else (fn:error((), "APIDOC-UNKNOWNELEMENT", "Element must be either 
          element(apidoc:function) or element(apidoc:method)")) ,

  element apidoc:function {
    attribute mode { $MODE-JAVASCRIPT },
    $function/@*,
    $function/node() }
};

(: Used by stp:function-docs to determine which functions are in a mode. :)
declare function api:module-extractable-functions(
  $module as element(apidoc:module),
  $mode as xs:string)
as element()*
{
(: 
   the return type is actually a combination of apidoc:function and 
   apidoc:method element, so I loosened up the return type 
:)
  if (not(api:has-mode-class($module, $mode))) then () else
  switch($mode)
  (: Fake a raw module doc, creating all the necessary context.
   : Return the fake module only if it contains at least one function.
   :)
  case $MODE-JAVASCRIPT return document {
    element apidoc:module {
      attribute xml:base { base-uri($module) },
      attribute mode { $MODE-JAVASCRIPT },
      api:function-fake-javascript(
        $module/(apidoc:function | apidoc:method)[
          not(@name eq '') ][
          not(api:fixup-fullname(., ()) =
            (preceding-sibling::apidoc:function/api:fixup-fullname(., ()),
             preceding-sibling::apidoc:method/api:fixup-fullname(., ()) ) ) ]
          [api:function-appears-in-mode(., $mode) ])
      } }/apidoc:module/(apidoc:function | apidoc:method)
  case $MODE-REST
  case $MODE-XPATH return $module/apidoc:function[
    not(@name eq '') ][
    not(api:fixup-fullname(., ()) =
      preceding-sibling::apidoc:function/api:fixup-fullname(., ()) ) ]
    [api:function-appears-in-mode(., $mode) ]
  default return error((), 'UNEXPECTED', ('Unexpected mode', $mode))
};

(: transformation used in api:module-extactable-inherited-functions :)
declare function api:transform-attr-values(
  $nodes as node()*, $object, $category ) as node()*
{
for $n in $nodes return
typeswitch($n)
  case text() return $n
  case element (subtype) return 
     api:transform-attr-values($n/node(), $object, $category)
  case element (apidoc:method) return 
     element apidoc:method {$n/(@* except (@object|@category)), 
      attribute object {$object} ,
      attribute category {$category}, 
      api:transform-attr-values($n/node(), $object, $category)}
  default return element {fn:node-name($n)} {$n/@*, 
     api:transform-attr-values($n/node(), $object, $category)}
};

(: 
   Used by stp:function-docs to generate the inherited functions based on
   object subtype-of attribute (to show the inherited methods/functions).
:)
declare function api:module-extractable-inherited-functions(
  $module as element(apidoc:module))
as element()*
{
  for $object in $module//apidoc:object[@subtype-of]
  (: there can be more than one subtype :)
  for $subtype in fn:tokenize(fn:normalize-space(
                     $object/@subtype-of/fn:string()), " ")
  return
  api:transform-attr-values(
    element subtype { attribute object { $object/@name }, 
        attribute subtype { $subtype },
        attribute category { $object/@category },
   (: add a sentence to the apidoc:summary saying this comes from a subtype :)
  let $funcs := $module//(apidoc:method | apidoc:function)[@object eq $subtype]
  for $node in $funcs
  return
  element {fn:node-name($node)} {$node/@*, 
    for $child in $node/node() return
    typeswitch($child)
      case text() return $child
      case element(apidoc:summary) return 
        element apidoc:summary { $child/@*, 
           element xhtml:p {"This is inherited from the ", 
                 element xhtml:a {
                   attribute href {
                         toc:category-href(
                               $subtype, "", 
                               fn:true(), fn:true(), "javascript", 
                               $subtype, "") }, $subtype }, " object." }, 
           $child/node()} 
      default return $child
      } 
    },
    $object/@name/fn:string(), $object/@category/fn:string())
};

declare function api:external-uri-with-prefix(
  $version-prefix as xs:string,
  $internal-uri as xs:string)
as xs:string
{
  $version-prefix
  ||ml:external-uri-for-string($internal-uri)
};

(: Used by page.xsl for toc_filter.js :)
declare function api:toc-section-link-selector(
  $version as xs:string,
  $version-prefix as xs:string,
  $e as element())
as xs:string
{
  if (1) then () else xdmp:log(
    text {
      'api:toc-section-link-selector', $version, $version-prefix,
      xdmp:describe($e), 'guide-uri', xdmp:describe($e/@guide-uri/string()) }),
  typeswitch($e)
  (: function lib page link, eg '/8.0/js/xdmp' :)
  case element(api:function-page) return (
    ".scrollable_section a[href='"
    ||$version-prefix
    ||(switch($e/@mode)
      case $MODE-JAVASCRIPT return '/js/'
      default return '/')
    ||$e/api:function[1]/@lib
    ||"']")
  case element(api:help-page) return (
    '#'
    ||$e/@container-toc-section-id
    ||' >:first-child')
  case element(api:list-page) return (
    (switch($e/@mode)
      case $MODE-JAVASCRIPT return '#js_'
      default return '#')
    ||$e/@container-toc-section-id
    ||' >:first-child')
  case element(chapter) return (
    ".scrollable_section a[href='"
    ||api:external-uri-with-prefix($version-prefix, $e/@guide-uri)
    ||"']")
  case element(guide) return (
    ".scrollable_section a[href='"
    ||api:external-uri-with-prefix($version-prefix, $e/@guide-uri)
    ||"']")
  (: Message page for error code, without any TOC data.
   : #277 Display TOC for corresponding guide page.
   :)
  case element(message) return (
    ".scrollable_section a[href='"
    ||api:external-uri-with-prefix($version-prefix, $e/@guide-uri)
    ||"']")
  (: On the main docs page, just let the first tab be selected by default. :)
  case element(api:docs-page) return ''
  default return error((), 'UNEXPECTED', xdmp:describe($e))
};

declare function api:document-list(
  $version as xs:string)
as element(apidoc:docs)
{
  (: Lazy init of module variable.
   : ASSUMPTION = We only process one version per request.
   :)
  if ($DOCUMENT-LIST-CACHED) then $DOCUMENT-LIST-CACHED
  else (
    (: Prefer database document if present.
     : Fall back to version-specific copy from filesystem.
     :)
    let $v := doc('/apidoc/'||$version||'/document-list.xml')
    let $v as element(apidoc:docs) := (
      if ($v) then $v/* else u:get-doc(
        '/apidoc/config/'||$version||'/document-list.xml')/apidoc:docs)
    let $_ := xdmp:set($DOCUMENT-LIST-CACHED, $v)
    return $v)
};

declare function api:type-javascript(
  $type as xs:string)
as xs:string
{
  switch($type)

  case 'document-node()'
  case 'element()'
  case 'node()' return 'Node'

  case 'empty-sequence()' return 'null'

  case 'item()'
  case 'xs:anyURI'
  case 'xs:string'
  case 'xs:time'
  (: we map unsignedLong to String because Number can lose precision for some
     unsignedLong values (gotta love javascript) :)
  case 'xs:unsignedLong' return 'String'

  case 'json:array' return 'Array'

  case 'json:object'
  case 'map:map' return 'Object'

  case 'xdmp:function' return 'function'

  case 'xs:boolean' return 'Boolean'

  case 'xs:date'
  case 'xs:dateTime' return 'Date'

  case 'xs:decimal'
  case 'xs:double'
  case 'xs:float'
  case 'xs:long'
  case 'xs:positiveInteger'
  case 'xs:unsignedInt' return 'Number'

  case 'xs:integer' return 'Number'
  case 'numeric' return 'Number'

  (: #318 Translate any namespaced type names too. :)
  default return api:javascript-name($type, ())
};

declare function api:type-expr-javascript(
  $context as xs:string?,
  $type as xs:string,
  $quantifier as xs:string)
as xs:string
{
  if (not($quantifier = ('*', '+'))) then concat(
    api:type-javascript($type), $quantifier)
  (: #317 for params with item()* :)
  else if ($context = 'return') then 'ValueIterator'
  else switch($type)
  (: Overrides for specific parameter types. :)
  case 'cts:query' return concat(api:type-javascript($type), '[]')
  case 'item()' return 'ValueIterator'
  case 'xs:anyAtomicType' return '(String | Number | Boolean | null)[]'
  default return (api:type-javascript($type)||'[]')
};

declare function api:type-expr-javascript(
  $context as xs:string?,
  $expr as xs:string)
as xs:string
{
  switch($expr)
  (: #262 for xdmp.invoke et. al. :)
  case '(element()|map:map)?' return 'Object?'
  (: #301 cts.search :)
  case '(cts:order|xs:string)*' return 'String[]'

  default return (
    (: If there is a quantifier, tokenize and handle it. :)
    if (matches($expr, $TYPE-JS-PAT)) then api:type-expr-javascript(
      $context,
      replace($expr, $TYPE-JS-PAT, '$1'),
      replace($expr, $TYPE-JS-PAT, '$2'))
    (: No quantifier. :)
    else api:type-javascript($expr))
};

(: Translate XDM types to JavaScript types. :)
declare function api:type(
  $mode as xs:string,
  $context as xs:string?,
  $expr as xs:string)
as xs:string
{
  switch($mode)
  case $MODE-JAVASCRIPT return api:type-expr-javascript(
    $context,
    normalize-space($expr))
  default return normalize-space($expr)
};

(: apidoc/model/data-access.xqy :)
