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

declare variable $INPUT-NAME-API := 'api' ;

declare variable $INPUT-NAME-API-VERSION := 'v' ;

declare variable $VERSION-DEFAULT := $ml:default-version ;

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
  $value as xs:string)
as xs:string
{
  concat($name, '=', encode-for-uri($value))
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
      (ss:param('q', $query),
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
      ml:external-uri-for-string(ss:rewrite-html-links($uri))),
    (: Add the highlight param if needed.
     : The external-uri-main function never adds a query string,
     : so we have a free hand.
     :)
    if (not($highlight-query)) then ''
    else concat('?', ss:query-string(ss:param('hq', $highlight-query))))
};

(: Search result values. TODO move into XML file? :)
declare function ss:facet-value-display($e as element())
  as xs:string
{
  typeswitch($e)
  case element(search:response) return 'All categories'
  default return (
    switch($e/@name)
    case 'blog' return 'Blog posts'
    case 'code' return 'Open-source projects'
    case 'event' return 'Events'
    case 'rest-api' return 'REST API docs'

    case 'function' return 'Function pages'
    case 'function/javascript' return 'JavaScript'
    case 'function/xquery' return 'XQuery/XSLT'

    case 'help' return 'Admin help pages'

    case 'guide' return 'User guides'

    case 'guide/admin' return 'Admin'
    case 'guide/admin-api' return 'Admin API'
    case 'guide/app-builder' return 'App Builder'
    case 'guide/app-dev' return 'Application Development'
    case 'guide/cluster' return 'Clusters'
    case 'guide/concepts' return 'Concepts'
    case 'guide/copyright' return 'Glossary'
    case 'guide/cpf' return 'CPF'
    case 'guide/database-replication' return 'Database Replication'
    case 'guide/ec2' return 'EC2'
    case 'guide/flexrep' return 'Flexible Replication'
    case 'guide/getting-started' return 'Getting Started'
    case 'guide/infostudio' return 'Info Studio'
    case 'guide/ingestion' return 'Ingestion'
    case 'guide/installation' return 'Installation'
    case 'guide/java' return 'Java'
    case 'guide/jsref' return 'JavaScript'
    case 'guide/mapreduce' return 'Hadoop'
    case 'guide/messages' return 'Messages'
    case 'guide/monitoring' return 'Monitoring'
    case 'guide/node-dev' return 'Node.js'
    case 'guide/performance' return 'Performance'
    case 'guide/qconsole' return 'Query Console'
    case 'guide/ref-arch' return 'Reference Architecture'
    case 'guide/relnotes' return 'Release Notes'
    case 'guide/rest-dev' return 'REST Development'
    case 'guide/search-dev' return 'Search Development'
    case 'guide/security' return 'Security'
    case 'guide/semantics' return 'Semantics'
    case 'guide/sharepoint' return 'Sharepoint'
    case 'guide/sql' return 'SQL'
    case 'guide/temporal' return 'Temporal'
    case 'guide/xcc' return 'XCC'
    case 'guide/xquery' return 'XQuery'

    case 'news' return 'News items'
    case 'tutorial' return 'Tutorials'
    case 'xcc' return 'XCC Connector API docs'
    case 'java-api' return 'Java Client API docs'
    case 'hadoop' return 'Hadoop Connector API docs'
    case 'xccn' return 'XCC Connector .Net docs'
    case 'other' return 'Miscellaneous pages'
    case 'cpp' return 'C++ API docs'
    default return $e/@name)
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

declare function ss:search-path(
  $url as xs:string,
  $q as xs:string,
  $version as xs:string?,
  $is-api as xs:boolean?)
as xs:string
{
  $url||'?q='||$q||(
    if (not($version)) then ''
    else '&amp;v='||$version)||(
    if (not($is-api)) then ''
    else '&amp;api='||$is-api)
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

(: search.xqm :)