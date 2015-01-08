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

declare variable $INPUT-NAME-API := 'api' ;

declare variable $INPUT-NAME-API-VERSION := 'v' ;

(: If applicable, translate URIs for XHTML-Tidy'd docs
 : back to the original HTML URI.
 :)
declare function ss:rewrite-html-links($uri as xs:string)
as xs:string
{
  if (not(ends-with($uri, '_html.xhtml'))) then $uri
  else replace($uri, '_html\.xhtml$', '.html')
};

declare function ss:options(
  $version as xs:string,
  $is-api as xs:boolean,
  $facets as xs:boolean,
  $query as xs:boolean,
  $results as xs:boolean)
as element(search:options)
{
  element search:options {
    element search:additional-query {
      ml:search-corpus-query($version, $is-api)
    },

    <search:constraint name="cat">
      <search:collection prefix="{ $ml:CATEGORY-PREFIX }"/>
    </search:constraint>
    ,
    <search:constraint name="param">
      <search:value>
        <search:element ns="{ $api:NAMESPACE }" name="param-type"/>
      </search:value>
    </search:constraint>
    ,
    <search:constraint name="return">
      <search:value>
        <search:element ns="{ $api:NAMESPACE }" name="return"/>
      </search:value>
    </search:constraint>
    ,

    element search:return-facets { $facets },
    element search:return-query { $query },
    element search:return-results { $results },

    element search:search-option { 'unfiltered' }
  }
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

declare function ss:qtext-without-constraints(
  $response as element(search:response),
  $options as element(search:options))
as xs:string
{
  ss:remove-constraints(
    $response/search:qtext, $response/search:query//@qtextconst, $options)
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

declare function ss:href(
  $version as xs:string,
  $query as xs:string,
  $is-api as xs:boolean,
  $page as xs:integer?)
as xs:string
{
  concat(
    $srv:search-page-url,
    '?',
    string-join(
      (ss:param('q', $query),
        if (not($is-api)) then ()
        else ss:param($ss:INPUT-NAME-API, xs:string($is-api)),
        ss:param($ss:INPUT-NAME-API-VERSION, $version),
        ss:param('p', xs:string($page))),
      '&amp;'))
};

declare function ss:href(
  $version as xs:string,
  $query as xs:string,
  $is-api as xs:boolean)
as xs:string
{
  ss:href($version, $query, $is-api, ())
};

(: search.xqm :)