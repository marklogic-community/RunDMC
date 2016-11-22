xquery version "1.0-ml";
(: Library module for URL rewrite.
 : It is cleaner to do everything here, so it can be tested.
 : This is controller code.
 :)
module namespace m="http://marklogic.com/rundmc/apidoc/rewrite";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace rw="http://marklogic.com/rundmc/rewrite"
 at "/controller/rewrite.xqm";
import module namespace srv="http://marklogic.com/rundmc/server-urls"
  at "/controller/server-urls.xqy";
import module namespace ml="http://developer.marklogic.com/site/internal"
  at "/model/data-access.xqy";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";
import module namespace c="http://marklogic.com/rundmc/api/controller"
  at "/apidoc/controller/controller.xqm";

declare namespace x="http://www.w3.org/1999/xhtml";

declare variable $DEBUG as xs:boolean? := xs:boolean(
  xdmp:get-request-field('debug')[. castable as xs:boolean]) ;

(: $PATH is just the original path, unless this is a REST doc, in which
 case we also might have to look at the query string (translating
 "?" to "@") :)
declare variable $PATH := (
  if (contains($PATH-ORIG, '/REST/') and $QUERY-STRING) then $REST-DOC-PATH
  else $PATH-ORIG ) ;

declare variable $PATH-ORIG := try {
  xdmp:url-decode(xdmp:get-request-path()) } catch ($ex) {
  xdmp:get-request-path() };

declare variable $PATH-PREFIX := (
  if ($VERSION-SPECIFIED) then concat("/", $VERSION-SPECIFIED, "/")
  else "/") ;
declare variable $PATH-PLUS-INDEX := concat(
  '/apidoc', $PATH, '/index.xml');
declare variable $PATH-TAIL := substring-after($PATH, $PATH-PREFIX) ;

declare variable $PATH-WITHOUT-VERSION := concat(
  '/', $PATH-TAIL) ;
declare variable $PATH-WITH-VERSION := concat(
  '/', $VERSION, $PATH-WITHOUT-VERSION) ;

declare variable $URL-ORIG := xdmp:get-request-url();
declare variable $QUERY-STRING := substring-after($URL-ORIG, '?');
declare variable $QUERY-STRING-FIELDS := xdmp:get-request-field-names() ;

declare variable $VERSION-SPECIFIED := (
  if (matches($PATH, '^/\d\.\d$')) then substring-after($PATH, '/')
  else if (matches($PATH, '^/\d\.\d/')) then substring-before(
    substring-after($PATH, '/'), '/')
  else "") ;

declare variable $VERSION := c:version($VERSION-SPECIFIED) ;

declare variable $ROOT-DOC-URL := concat(
  '/apidoc/', $api:DEFAULT-VERSION, '/index.xml');
(: when version is unspecified in path :)
declare variable $DOC-URL-DEFAULT := concat(
  '/apidoc/', $api:DEFAULT-VERSION, $PATH, '.xml');
(: when version is specified in path :)
declare variable $DOC-URL := concat(
  '/apidoc', $PATH, '.xml');

(: For REST doc URIs, translate "?" to "@",
 : ignore trailing ampersands, and ignore unknown parameters.
 :)
declare variable $REST-DOC-PATH := (
  (: TODO sounds expensive. :)
  let $candidate-uris := (
    cts:uri-match(
      concat(
        '/apidoc/', $api:DEFAULT-VERSION, $PATH-ORIG,
        $api:REST-URI-QUESTIONMARK-SUBSTITUTE, "*")),
    cts:uri-match(
      concat('/apidoc/',
        $PATH-ORIG, $api:REST-URI-QUESTIONMARK-SUBSTITUTE, "*")))

  let $canonicalized-query-string := m:query-string(
    (: TODO use function mapping? :)
    distinct-values(
      for $uri in $candidate-uris
      return m:REST-doc-query-param($uri))[string(.)])
  return (
    if ($canonicalized-query-string)
    then concat(
      $PATH-ORIG,
      $api:REST-URI-QUESTIONMARK-SUBSTITUTE,
      $canonicalized-query-string)
    else $PATH-ORIG))
;

declare variable $MATCHING-FUNCTIONS := ml:get-matching-functions(
  $PATH-TAIL, $VERSION) ;

declare variable $MATCHING-FUNCTION-COUNT := count($MATCHING-FUNCTIONS) ;

declare variable $GUIDE-MESSAGE-PAT := (
  '^/guide/messages/([A-Z])+\-[a-z][a-z]/([A-Z]+-[A-Z]+)$') ;

declare variable $MESSAGE-PAT := (
  '^/messages/([A-Z])+\-[a-z][a-z]/([A-Z]+-[A-Z]+)$') ;

declare variable $MESSAGE-SHORT-PAT := (
  '^/(\d+\.\d/)?messages/([A-Z]+-[A-Z]+)$') ;

declare function m:log(
  $label as xs:string,
  $list as xs:anyAtomicType*,
  $level as xs:string)
as empty-sequence()
{
  xdmp:log(text { '['||$label||']', $list }, $level)
};

declare function m:fine(
  $label as xs:string,
  $list as xs:anyAtomicType*)
as empty-sequence()
{
  m:log($label, $list, 'fine')
};

declare function m:debug(
  $label as xs:string,
  $list as xs:anyAtomicType*)
as empty-sequence()
{
  m:log($label, $list, 'debug')
};

declare function m:info(
  $label as xs:string,
  $list as xs:anyAtomicType*)
as empty-sequence()
{
  m:log($label, $list, 'info')
};

declare function m:warning(
  $label as xs:string,
  $list as xs:anyAtomicType*)
as empty-sequence()
{
  m:log($label, $list, 'warning')
};

declare function m:error(
  $code as xs:string,
  $items as item()*)
as empty-sequence()
{
  error((), 'REWRITE-'||$code, $items)
};

declare function m:query-string(
  $field-names as xs:string*)
as xs:string?
{
  string-join(
    for $name in $field-names
    order by $name
    return (xdmp:get-request-field($name) ! concat($name, '=', .))
    , '&amp;')
};

declare function m:query-string()
as xs:string?
{
  m:query-string($QUERY-STRING-FIELDS)
};

(: ASSUMPTION: each REST doc will have at most one query parameter in its URI :)
declare function m:REST-doc-query-param($doc-uri as xs:string)
  as xs:string
{
  substring-before(
    substring-after($doc-uri, $api:REST-URI-QUESTIONMARK-SUBSTITUTE),
    '=')
};

(: Path to render a document using XSLT :)
declare function m:transform(
  $source-uri as xs:string,
  $path as xs:string)
as xs:string
{
  if (not($DEBUG)) then () else m:debug(
    'rwa:transform', ('source', $source-uri, 'path', $path)),
  concat(
    "/apidoc/controller/transform.xqy?src=", $source-uri,
    "&amp;version=", $VERSION-SPECIFIED,
    "&amp;", $QUERY-STRING,
    if ($path eq "") then () else "&amp;path=", $path)
};

declare function m:transform($source-uri as xs:string)
  as xs:string
{
  m:transform($source-uri, "")
};

(: Grab doc from database :)
declare function m:get-db-file($source-uri)
 as xs:string
{
  concat("/controller/get-db-file.xqy?uri=", $source-uri)
};

declare function m:function-url($function as document-node())
  as xs:string
{
  concat($PATH-PREFIX, $function/*/api:function[1]/@fullname)
};

declare function m:redirect($path as xs:string)
  as xs:string
{
  (: This is a temporary redirect: 302 not 301. :)
  concat(
    '/controller/redirect.xqy?path=',
    xdmp:url-encode($path))
};

declare function m:redirect-301($path as xs:string)
as xs:string
{
  (: This is a permanent redirect: 301 vs 302. :)
  xdmp:set-response-code(301, "Moved Permanently"),
  xdmp:add-response-header("Location", $path),
  m:redirect($path)
};

(: Redirect to the right place,
 : and rely on the page anchor matching the id.
 :)
declare function m:redirect-for-guide-message(
  $path as xs:string,
  $id as xs:string)
as xs:string
{
  if (not($DEBUG)) then () else m:debug(
    'rwa:redirect-for-guide-message', ('path', $path, 'id', $id)),
  m:redirect(
    concat(
      substring-before($path, '/'||$id),
      '#', $id))
};

(: Redirect to the right page.
 : Preserve any query string.
 :)
declare function m:redirect-for-message(
  $path as xs:string,
  $id as xs:string)
as xs:string
{
  if (not($DEBUG)) then () else m:debug(
    'rwa:redirect-for-message', ('path', $path, 'id', $id)),
  m:redirect($path||(m:query-string()[.] ! ('?'||.)))
};

(: Redirect to the right page.
 : Preserve any query string.
 :)
declare function m:redirect-for-short-message(
  $path as xs:string,
  $id as xs:string)
as xs:string
{
  let $lib := substring-before($id, '-')
  let $path := replace($path, $id, $lib||'-en/'||$id)
  let $_ := if (not($DEBUG)) then () else m:debug(
    'rwa:redirect-for-message', ('path', $path, 'lib', $lib, 'id', $id))
  return m:redirect($path||(m:query-string()[.] ! ('?'||.)))
};

declare function m:redirect-for-version($version as xs:string)
as xs:string
{
  m:redirect-301(substring-after($PATH, "/"||$version))
};

declare function m:xray()
as xs:string
{
  if (not($DEBUG)) then () else m:debug(
    'rwa:xray', ('path', $PATH)),
  concat(
    if ($PATH = ('/xray', '/xray/')) then '/xray/index.xqy'
    else $PATH-ORIG,
    if ($QUERY-STRING) then '?' else '',
    $QUERY-STRING)
};

(: TODO figure out a way to break this up. :)
declare function m:rewrite()
  as xs:string
{
  if (not($DEBUG)) then () else m:debug(
    'rwa:rewrite',
    ('version', $VERSION, 'path-orig', $PATH-ORIG,
      'path', $PATH, 'query', $QUERY-STRING,
      'path-prefix', $PATH-PREFIX, 'path-tail', $PATH-TAIL)),

  (: SCENARIO 1: External redirect :)
  (: When the user hits Enter in the TOC filter box :)
  if ($PATH eq '/do-do-search') then m:redirect(
    concat($srv:search-page-url, "?", $QUERY-STRING))
  (: Externally redirect paths with trailing slashes :)
  else if (($PATH ne '/') and ends-with($PATH, '/')) then m:redirect(
    concat(
      substring($PATH, 1, string-length($PATH) - 1),
      if ($QUERY-STRING) then concat('&amp;', $QUERY-STRING) else ()))
  (: Redirect some naked top-level paths to / :)
  else if ($PATH-TAIL = ("guide", "javadoc", 'jsdoc')) then m:redirect(
    $PATH-PREFIX)
  (: Redirect /dotnet to /dotnet/xcc :)
  else if ($PATH-TAIL eq "dotnet") then m:redirect(
    concat($PATH, '/xcc/index.html'))
  (: Redirect /cpp to /cpp/udf :)
  else if ($PATH-TAIL eq "cpp") then m:redirect(
    concat($PATH, '/udf/index.html'))
  (: Redirect path without index.html to index.html :)
  else if ($PATH-TAIL = ("javadoc/hadoop",
      "javadoc/client",
      "javadoc/xcc",
      "dotnet/xcc",
      "cpp/udf")) then m:redirect(concat($PATH, '/index.html'))

  (: Redirect requests for older versions 301 and go to latest :)
  else if (starts-with($PATH, "/4.2")) then m:redirect-for-version('4.2')
  else if (starts-with($PATH, "/4.1")) then m:redirect-for-version('4.1')
  else if (starts-with($PATH, "/4.0")) then m:redirect-for-version('4.0')
  else if (starts-with($PATH, "/3.2")) then m:redirect-for-version('3.2')
  else if (starts-with($PATH, "/3.1")) then m:redirect-for-version('3.1')

  (: SCENARIO 2: Internal rewrite :)

  else if ($PATH eq '/service/suggest') then concat(
    '/controller/suggest.xqy?', $QUERY-STRING)

  (: SCENARIO 2A: Serve up the JavaScript-based docapp redirector :)
  else if (ends-with($PATH, "docapp.xqy"))
  then "/apidoc/controller/docapp-redirector.xqy"

  (: SCENARIO 2B: Serve content from file system :)
  (: Remove version from the URL for versioned assets :)
  else if (matches($PATH, '^/(css|images|fonts)(/v-\d*)?/.*')) then replace(
    $PATH, '/v-\d*', '')

  (: If the path starts with one of the designated paths in the code base,
   : then serve from filesystem.
   :)
  else if (rw:static-file-path($PATH)) then $PATH-ORIG

  (: SCENARIO 2C: Serve content from database :)
  (: Respond with DB contents for /media  :)
  else if (starts-with($PATH, '/media/')) then m:get-db-file($PATH)

  (: For zip file requests, we assume the zip file of all docs :)
  else if (ends-with($PATH, '.zip')) then m:get-db-file(
    concat("/apidoc", $PATH))

  (: Respond with DB contents for PDF and HTML docs :)
  else if (ends-with($PATH, '.pdf')
    or matches($PATH, '/(cpp|dotnet|javadoc|jsdoc)/')) then (
    let $file-uri := concat('/apidoc', $PATH-WITH-VERSION)
    return m:get-db-file($file-uri))

  (: redirect /package to /pkg because we changed the prefix :)
  else if ($PATH eq "/package") then m:redirect("/pkg")

  (: Handle single-page messages in short form.
   : This expects something like
   : /messages/XDMP-BAD
   : and we want to redirect to something like
   : /apidoc/8.0/messages/XDMP-en/XDMP-BAD.xml
   :)
  else if (matches($PATH, $MESSAGE-SHORT-PAT)) then m:redirect-for-short-message(
    $PATH-WITH-VERSION,
    replace($PATH, $MESSAGE-SHORT-PAT, '$2'))

  (: Handle single-page messages.
   : This expects something like
   : /messages/XDMP-en/XDMP-BAD
   : and we want to redirect to something like
   : /apidoc/8.0/messages/XDMP-en/XDMP-BAD.xml
   :)
  else if (matches($PATH, $MESSAGE-PAT)) then m:redirect-for-message(
    $PATH-WITH-VERSION,
    replace($PATH, $MESSAGE-PAT, '$2'))

  (: Handle deep links into message guides.
   : This expects something like
   : /guide/messages/XDMP-en/XDMP-BAD
   : and we want to redirect to something like
   : /apidoc/7.0/guide/messages/XDMP-en.xml#XDMP-BAD
   :)
  else if (matches($PATH, $GUIDE-MESSAGE-PAT)) then m:redirect-for-guide-message(
    $PATH-WITH-VERSION,
    replace($PATH, $GUIDE-MESSAGE-PAT, '$2'))

  (: Ignore URLs starting with "/private/" :)
  else if (starts-with($PATH, '/private/')) then $rw:NOTFOUND

  else if (starts-with($PATH, '/xray')) then m:xray()

  (: Support retrieving user preferences :)
  else if ($PATH eq "/people/preferences") then "/controller/preferences.xqy"

  (: Root request: "/" means "index.xml" inside the default version directory :)
  else if ($PATH eq '/') then m:transform($ROOT-DOC-URL)

  (: If the version-specific doc path requested, e.g., /4.2/foo, is available,
   : then serve it
   :)
  else if (doc-available($DOC-URL)) then m:transform($DOC-URL)

  (: A version-specific root request, e.g., /4.2 :)
  else if ($PATH eq concat('/', $VERSION-SPECIFIED)
    and doc-available($PATH-PLUS-INDEX)) then m:transform($PATH-PLUS-INDEX)

  (: Otherwise, look in the default version directory.
   : Requests like /all end up here.
   :)
  else if (doc-available($DOC-URL-DEFAULT)) then m:transform($DOC-URL-DEFAULT)

  (: SCENARIO 3: External redirect to matching function page
   : If the path matches exactly one function's local name,
   then redirect to that page.
   :)
  else if ($MATCHING-FUNCTION-COUNT eq 1) then m:redirect(
    m:function-url($MATCHING-FUNCTIONS))

  (: If the path matches more than one function's local name,
   : show the first one.
   :)
  else if ($MATCHING-FUNCTION-COUNT gt 1) then m:redirect(
    concat(
      m:function-url($MATCHING-FUNCTIONS[1]),
      "?show-alternatives=yes"))

  (: #316 redirect legacy prefix.
   : Handle this toward the end to avoid redirecting static resources.
   :)
  else if (starts-with($PATH, '/apidoc/')) then m:redirect-301(
    substring-after($PATH, '/apidoc'))

  (: SCENARIO 4: Not found anywhere :)
  else (
    $rw:NOTFOUND,
    xdmp:log(
      text {
        'NOTFOUND', $PATH,
        (: The URL is easier to read decoded.
         : #304 But sometimes the URL will not decode cleanly.
         :)
        try { xdmp:url-decode($DOC-URL) }
        catch ($ex) { $DOC-URL } }))
};

(: rewrite.xqm :)
