xquery version "1.0-ml";
(: search controller library module. :)

module namespace ss="http://developer.marklogic.com/site/search" ;

declare default function namespace "http://www.w3.org/2005/xpath-functions" ;

import module namespace search="http://marklogic.com/appservices/search"
  at "/MarkLogic/appservices/search/search.xqy" ;

import module namespace ml="http://developer.marklogic.com/site/internal"
  at "/model/data-access.xqy" ;
import module namespace srv="http://marklogic.com/rundmc/server-urls"
  at "/controller/server-urls.xqy" ;

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";

declare namespace xh="http://www.w3.org/1999/xhtml" ;

declare variable $INPUT-NAME-ADVANCED := 'advanced' ;

declare variable $INPUT-NAME-API := 'api' ;

declare variable $INPUT-NAME-API-VERSION := 'v' ;

declare variable $INPUT-NAME-QUERY := 'q' ;

declare variable $ML-VERSION := xs:integer(
  substring-before(xdmp:version(), '.')) ;

declare variable $VERSION-DEFAULT := $ml:default-version ;

(: TODO Load from file or database document? :)
declare variable $CATEGORIES as map:map := map:new(
  (map:entry('blog', 'Blog posts'),
    map:entry('code', 'Open-source projects'),
    map:entry('event', 'Events'),
    map:entry('rest-api', 'REST API docs'),
    map:entry('function', 'Function pages'),
    map:entry('function/javascript', 'JavaScript'),
    map:entry('function/xquery', 'XQuery/XSLT'),
    map:entry('help', 'Admin help pages'),
    map:entry('guide', 'User guides'),
    map:entry('guide/admin', 'Admin'),
    map:entry('guide/admin-api', 'Admin API'),
    map:entry('guide/app-builder', 'App Builder'),
    map:entry('guide/app-dev', 'Application Development'),
    map:entry('guide/cluster', 'Clusters'),
    map:entry('guide/concepts', 'Concepts'),
    map:entry('guide/copyright', 'Glossary'),
    map:entry('guide/cpf', 'CPF'),
    map:entry('guide/database-replication', 'Database Replication'),
    map:entry('guide/ec2', 'EC2'),
    map:entry('guide/flexrep', 'Flexible Replication'),
    map:entry('guide/getting-started', 'Getting Started'),
    map:entry('guide/infostudio', 'Info Studio'),
    map:entry('guide/ingestion', 'Ingestion'),
    map:entry('guide/installation', 'Installation'),
    map:entry('guide/java', 'Java'),
    map:entry('guide/jsref', 'JavaScript'),
    map:entry('guide/mapreduce', 'Hadoop'),
    map:entry('guide/messages', 'Messages'),
    map:entry('guide/monitoring', 'Monitoring'),
    map:entry('guide/node-dev', 'Node.js'),
    map:entry('guide/performance', 'Performance'),
    map:entry('guide/qconsole', 'Query Console'),
    map:entry('guide/ref-arch', 'Reference Architecture'),
    map:entry('guide/relnotes', 'Release Notes'),
    map:entry('guide/rest-dev', 'REST Development'),
    map:entry('guide/search-dev', 'Search Development'),
    map:entry('guide/security', 'Security'),
    map:entry('guide/semantics', 'Semantics'),
    map:entry('guide/sharepoint', 'Sharepoint'),
    map:entry('guide/sql', 'SQL'),
    map:entry('guide/temporal', 'Temporal'),
    map:entry('guide/xcc', 'XCC'),
    map:entry('guide/xquery', 'XQuery'),
    map:entry('news', 'News items'),
    map:entry('tutorial', 'Tutorials'),
    map:entry('xcc', 'XCC Connector API docs'),
    map:entry('java-api', 'Java Client API docs'),
    map:entry('hadoop', 'Hadoop Connector API docs'),
    map:entry('xccn', 'XCC Connector .Net docs'),
    map:entry('other', 'Miscellaneous pages'),
    map:entry('cpp', 'C++ API docs'))) ;

(: If applicable, translate URIs for XHTML-Tidy'd docs
 : back to the original HTML URI.
 :)
declare function ss:rewrite-html-links($uri as xs:string)
as xs:string
{
  if (not(ends-with($uri, '_html.xhtml'))) then $uri
  else replace($uri, '_html\.xhtml$', '.html')
};

(: Title text can appear in a number of places.
 : It might be a good idea for setup to enrich all documents
 : with a canonical title element.
 :)
declare function ss:title-query(
  $constraint-qtext as xs:string,
  $right as schema-element(cts:query))
as schema-element(cts:query)
{
  cts:element-word-query(
    xs:QName(
      ('api:function-name', 'api:title', 'guide-title',
        'title', 'xh:title')),
    string($right//cts:text))
  ! document{ . }/*
  ! element { node-name(.) } {
    attribute qtextconst {
      concat($constraint-qtext, fn:string($right//cts:text)) },
    @*,
    node() }
};

declare function ss:options(
  $version as xs:string?,
  $is-api as xs:boolean,
  $facets as xs:boolean,
  $query as xs:boolean,
  $results as xs:boolean)
as element(search:options)
{
  <options xmlns="http://marklogic.com/appservices/search">
  {
    element return-facets { $facets },
    element return-query { $query },
    element return-results { $results },
    element search-option { 'unfiltered' },
    (: Allow empty version to make highlighting less cumbersome. :)
    if (not($version)) then ()
    else element additional-query {
      ml:search-corpus-query($version, $is-api)
    }
  }

    <constraint name="cat">
      <collection prefix="{ $ml:CATEGORY-PREFIX }"/>
    </constraint>
    <constraint name="param">
      <value>
        <element ns="{ $api:NAMESPACE }" name="param-type"/>
      </value>
    </constraint>
    <constraint name="return">
      <value>
        <element ns="{ $api:NAMESPACE }" name="return"/>
      </value>
    </constraint>

    <constraint name="title">
      <custom facet="false">
        <parse apply="title-query"
  ns="http://developer.marklogic.com/site/search"
  at="/controller/search.xqm"/>
      </custom>
    </constraint>

    <default-suggestion-source>
      <range
  collation="http://marklogic.com/collation/codepoint"
  type="xs:string" facet="true">
        <element ns="http://marklogic.com/rundmc/api" name="suggest"/>
      </range>
    </default-suggestion-source>

  </options>
};

(: Convenience functions for highlighting and suggest. :)
declare function ss:options($version as xs:string?)
as element(search:options)
{
  ss:options($version, false(), false(), false(), false())
};

declare function ss:options()
as element(search:options)
{
  ss:options(())
};

declare function ss:options-check()
as element(search:report)*
{
  search:check-options(ss:options(), true())
};

(: Remove constraints recursively. :)
declare function ss:remove-constraints(
  $q as xs:string,
  $constraints as xs:string*,
  $options as element(search:options))
as xs:string
{
  if (empty($constraints)) then $q else
  let $new-q := search:remove-constraint($q, $constraints[1], $options)
  let $rest := subsequence($constraints, 2)
  return (
    if (empty($rest)) then $new-q
    else ss:remove-constraints($new-q, $rest, $options))
};

(: Remove any faceted constraints. :)
declare function ss:qtext-without-constraints(
  $response as element(search:response),
  $options as element(search:options))
as xs:string
{
  ss:remove-constraints(
    $response/search:qtext,
    $response/search:query//@qtextconst[starts-with(., 'cat:')],
    $options)
};

(: This does some surgery on the response.
 : If the original query containts a category constraint,
 : that means the user selected a facet.
 : We want the constrained results,
 : but the facets should still be unconstrained.
 : To arrange this we search twice and merge the responses.
 : Display uses both totals.
 :)
declare function ss:search-response(
  $version as xs:string,
  $is-api as xs:boolean,
  $query as xs:string+,
  $response as element(search:response))
as element(search:response)
{
  element search:response {
    $response/@* ! (
      typeswitch(.)
      case attribute(total) return attribute facet-total { . }
      default return .),
    attribute query-unconstrained { $query },
    (: We also use the @total from the unconstrained facets,
     : as the value for "All categories".
     : So put that attribute and the facet elements before any other nodes.
     :)
    search:search(
      $query,
      ss:options(
        $version, $is-api, true(), false(), false()))/(@total|search:facet),
    $response/node()
  }
};

declare function ss:search-response(
  $version as xs:string,
  $is-api as xs:boolean,
  $query as xs:string+,
  $options as element(search:options),
  $response as element(search:response))
as element(search:response)
{
  if (xs:boolean($options/search:return-facets)) then $response
  else ss:search-response(
    $version, $is-api,
    ss:qtext-without-constraints($response, $options),
    $response)
};

declare function ss:search(
  $version as xs:string,
  $is-api as xs:boolean,
  $query as xs:string+,
  $start as xs:integer,
  $size as xs:integer,
  $options as element(search:options))
as element(search:response)
{
  ss:search-response(
    $version, $is-api, $query, $options,
    search:search($query, $options, $start, $size))
};

declare function ss:search(
  $version as xs:string,
  $is-api as xs:boolean,
  $query as xs:string+,
  $start as xs:integer,
  $size as xs:integer)
as element(search:response)
{
  ss:search(
    $version, $is-api, $query,
    $start, $size,
    ss:options(
      $version, $is-api, not(contains($query, 'cat:')), true(), true()))
};

declare function ss:param(
  $name as xs:string,
  $value as xs:anySimpleType)
as xs:string
{
  concat($name, '=', encode-for-uri(string($value)))
};

declare function ss:query-string(
  $params as xs:string*)
as xs:string
{
  if (empty($params)) then ''
  else string-join($params, '&amp;')
};

declare function ss:href(
  $version as xs:string,
  $query as xs:string,
  $is-api as xs:boolean,
  $page as xs:integer?)
as xs:string
{
  concat(
    '?',
    ss:query-string(
      (ss:param($INPUT-NAME-QUERY, $query),
        if (not($is-api)) then ()
        else ss:param($ss:INPUT-NAME-API, xs:string($is-api)),
        ss:param($ss:INPUT-NAME-API-VERSION, $version),
        ss:param('p', xs:string($page)))))
};

declare function ss:href(
  $version as xs:string,
  $query as xs:string,
  $is-api as xs:boolean)
as xs:string
{
  ss:href($version, $query, $is-api, ())
};

declare function ss:result-uri(
  $uri as xs:string,
  $highlight-query as xs:string?,
  $is-api-doc as xs:boolean,
  $api-version-prefix as xs:string)
as xs:string
{
  concat(
    if (not($is-api-doc)) then ml:external-uri-main($uri)
    else concat(
      $srv:effective-api-server,
      $api-version-prefix,
      ml:escape-uri(
        ml:external-uri-for-string(ss:rewrite-html-links($uri)))),
    (: Add the highlight param if needed.
     : The external-uri-main function never adds a query string,
     : so we have a free hand.
     :)
    if (not($highlight-query)) then ''
    else concat('?', ss:query-string(ss:param('hq', $highlight-query))))
};

declare function ss:search-path(
  $url as xs:string,
  $q as xs:string,
  $version as xs:string?,
  $is-api as xs:boolean?,
  $is-advanced as xs:boolean?)
as xs:string
{
  $url
  ||'?'
  ||ss:query-string(
    (ss:param('advanced', 1)[$is-advanced],
      ss:param($INPUT-NAME-API, 1)[$is-api],
      ss:param($INPUT-NAME-QUERY, $q)[$q],
      ss:param($INPUT-NAME-API-VERSION, $version)[$version]))
};

declare function ss:search-path(
  $url as xs:string,
  $q as xs:string,
  $version as xs:string?,
  $is-api as xs:boolean?)
as xs:string
{
  ss:search-path($url, $q, $version, $is-api, ())
};

(: Map category keys to human-readable values. :)
declare function ss:facet-value-display($e as element())
  as xs:string
{
  typeswitch($e)
  case element(search:response) return 'All categories'
  default return (map:get($CATEGORIES, $e/@name), $e/@name)[1]
};

(: Search result icon file names. TODO move into XML file? :)
declare function ss:result-img-src($name as xs:string)
as xs:string
{
  switch($name)
  case 'all' return 'i_mag_logo_small'
  case 'blog' return 'i_rss_small'
  case 'code' return 'i_opensource'
  case 'event' return 'i_calendar'
  case 'function' return 'i_function'
  (: TODO give help a different icon :)
  case 'help' return 'i_folder'
  case 'rest-api' return 'i_rest'
  case 'guide' return 'i_documentation'
  case 'news' return 'i_newspaper'
  case 'tutorial' return 'i_monitor'
  case 'xcc' return 'i_java'
  case 'java-api' return 'i_java'
  case 'hadoop' return 'i_java'
  case 'xccn' return 'i_dotnet'
  case 'other' return 'i_folder'
  (: TODO give cpp a different icon :)
  case 'cpp' return 'i_folder'
  default return 'i_folder'
};

(: Search result icon file widths. TODO move into XML file? :)
declare function ss:result-img-width($name as xs:string)
  as xs:int
{
  switch($name)
  case 'guide' return 29
  case 'rest-api' return 28
  (: All other icons are 30px wide. :)
  default return 30
};

(: Search result icon file heights. TODO move into XML file? :)
declare function ss:result-img-height($name as xs:string)
  as xs:int
{
  switch($name)
  case 'all' return 23
  case 'blog' return 23
  case 'code' return 24
  case 'event' return 24
  case 'function' return 27
  case 'help' return 19
  case 'rest-api' return 28
  case 'guide' return 25
  case 'news' return 23
  case 'tutorial' return 21
  case 'xcc' return 26
  case 'java-api' return 26
  case 'hadoop' return 26
  case 'xccn' return 24
  case 'other' return 19
  default return 30
};

declare function ss:highlight(
  $n as node(),
  $query as xs:string)
as node()*
{
  cts:highlight(
    $n,
    cts:query(search:parse($query, ss:options())),
    <span class="hit_highlight" xmlns="http://www.w3.org/1999/xhtml">{
      $cts:text
    }</span>)
};

declare function ss:maybe-highlight(
  $n as node(), $params as element()*)
as node()*
{
  let $hq := string-join($params[@name eq 'hq'], ' ')
  return if (not($hq)) then $n else ss:highlight($n, $hq)
};

(: Given a substring, suggest $count values. :)
declare function ss:suggest(
  $version as xs:string,
  $q as xs:string,
  $count as xs:integer,
  $pos as xs:integer)
as xs:string*
{
  if (string-length($q) lt 3) then ()
  else search:suggest(
    $q, ss:options($version), $count, max((1, $pos)))
};

(: Build query from raw params. :)
declare function ss:query(
  $q as xs:string*,
  $word as xs:string*,
  $category as xs:string*,
  $title as xs:string*)
as xs:string?
{
  string-join(
    ($q[.],
      $category[.] ! ('cat:'||xdmp:quote(.)),
      $title[.] ! ('title:'||xdmp:quote(.)),
      $word[.]),
    ' ')
};

declare function ss:format(
  $m as map:map,
  $format as xs:string?)
as item()
{
  switch($format)
  case 'json' return (
    if ($ML-VERSION lt 8) then xdmp:to-json($m)
    else xdmp:quote($m))
  default return $m
};

declare function ss:query-part(
  $q as element()?,
  $key as xs:string)
as xs:string*
{
  $q//@qtextconst[starts-with(., $key)]
  ! substring-after(., $key)
};

(: Deconstruct a query for the advanced search form.
 : This is not very sophisticated, and does not handle booleans.
 :)
declare function ss:query-parts(
  $q as element()?)
as map:map
{
  map:new(
    (("cat", "title") ! map:entry(., ss:query-part($q, .||':')),
      map:entry("word", $q//@qtextref[. eq "cts:text"]/string(..))))
};

declare function ss:query-parts(
  $q as xs:string,
  $format as xs:string?)
as item()
{
  ss:format(
    ss:query-parts(
      search:parse(
        $q, ss:options(),
        if ($ML-VERSION lt 8) then 'cts:query'
        else 'cts:annotated-query')),
    $format)
};

declare function ss:constraints($format as xs:string?)
as item()
{
  ss:format(
    map:new(
      (map:entry('cat', $CATEGORIES),
        map:entry('title', '_text'),
        map:entry('word', '_text'))),
    $format)
};

(: search.xqm :)