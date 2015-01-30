xquery version "1.0-ml";
(: Test module for search controller code :)

module namespace t="http://github.com/robwhitby/xray/test";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace at="http://github.com/robwhitby/xray/assertions"
  at "/xray/src/assertions.xqy";

import module namespace ss="http://developer.marklogic.com/site/search"
  at "/controller/search.xqm";

declare %t:case function t:search-300()
{
  at:not-empty(
    xdmp:xslt-invoke(
      "/view/page.xsl",
      doc("/apidoc/do-search.xml"),
      map:new(
        map:entry(
          'params',
          (<param name="src">/apidoc/do-search.xml</param>,
            <param name="version"/>,
            <param name="v">7.0</param>,
            <param name="v"/>)))))
};

declare %t:case function t:query-0c-unconstrained()
{
  let $query := 'fubar'
  let $version := "8.0"
  let $is-api := false()
  let $response := <search:response
  snippet-format="snippet" total="0" start="1" page-length="10"
  xmlns:search="http://marklogic.com/appservices/search">
  <search:qtext>fubar</search:qtext>
  <search:query>
    <cts:word-query qtextref="cts:text" xmlns:cts="http://marklogic.com/cts">
      <cts:text>fubar</cts:text>
    </cts:word-query>
  </search:query>
  </search:response>
  let $unconstrained := ss:qtext-without-constraints(
    $response,
    ss:options(
      $version, $is-api, not(contains($query, 'cat:')), true(), true()))
  return at:equal(
    $unconstrained,
    'fubar')
};

declare %t:case function t:query-1c-unconstrained()
{
  let $query := 'cat:guide/admin fubar'
  let $version := "8.0"
  let $is-api := false()
  let $response := <search:response
  snippet-format="snippet" total="0" start="1" page-length="10"
  xmlns:search="http://marklogic.com/appservices/search">
  <search:qtext>cat:guide/admin fubar</search:qtext>
  <search:query>
    <cts:and-query strength="20" qtextjoin="" qtextgroup="( )"
     xmlns:cts="http://marklogic.com/cts">
      <cts:collection-query qtextconst="cat:guide/admin">
        <cts:uri>category/guide/admin</cts:uri>
      </cts:collection-query>
      <cts:word-query qtextref="cts:text">
        <cts:text>fubar</cts:text>
      </cts:word-query>
    </cts:and-query>
  </search:query>
  </search:response>
  let $unconstrained := ss:qtext-without-constraints(
    $response,
    ss:options(
      $version, $is-api, not(contains($query, 'cat:')), true(), true()))
  return at:equal(
    $unconstrained,
    'fubar')
};

declare %t:case function t:query-2c-unconstrained()
{
  let $query := '(cat:guide/admin OR cat:guide/search-dev) fubar'
  let $version := "8.0"
  let $is-api := false()
  let $response := <search:response
  snippet-format="snippet" total="0" start="1" page-length="10"
  xmlns:search="http://marklogic.com/appservices/search">
  <search:qtext>(cat:guide/admin OR cat:guide/search-dev) fubar</search:qtext>
  <search:query>
    <cts:and-query strength="20" qtextjoin="" qtextgroup="( )"
     xmlns:cts="http://marklogic.com/cts">
      <cts:or-query qtextjoin="OR" strength="10" qtextgroup="( )">
        <cts:collection-query qtextconst="cat:guide/admin">
          <cts:uri>category/guide/admin</cts:uri>
        </cts:collection-query>
        <cts:collection-query qtextconst="cat:guide/search-dev">
          <cts:uri>category/guide/search-dev</cts:uri>
        </cts:collection-query>
      </cts:or-query>
      <cts:word-query qtextref="cts:text">
        <cts:text>fubar</cts:text>
      </cts:word-query>
    </cts:and-query>
  </search:query>
  </search:response>
  let $unconstrained := ss:qtext-without-constraints(
    $response,
    ss:options(
      $version, $is-api, not(contains($query, 'cat:')), true(), true()))
  return at:equal(
    $unconstrained,
    'fubar')
};

(: test/search.xqm :)