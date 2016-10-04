xquery version "1.0-ml";
(: Test module for apidoc/data-access :)

module namespace t="http://github.com/robwhitby/xray/test";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace at="http://github.com/robwhitby/xray/assertions"
  at "/xray/src/assertions.xqy";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";

declare %t:case function t:type-javascript-param-cts-query()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'cts:query', '8.0'),
    'cts.query')
};

declare %t:case function t:type-javascript-param-cts-query-star()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'cts:query*', '8.0'),
    'cts.query[]')
};

declare %t:case function t:type-javascript-param-cts-query-plus()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'cts:query+', '8.0'),
    'cts.query[]')
};

declare %t:case function t:type-javascript-param-cts-query-question()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'cts:query?', '8.0'),
    'cts.query?')
};

declare %t:case function t:type-javascript-param-element-or-map()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), '(element()|map:map)?', '8.0'),
    'Object?')
};

declare %t:case function t:type-javascript-param-item-star()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'item()*', '8.0'),
    'ValueIterator')
};

declare %t:case function t:type-javascript-param-map-star()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'map:map*', '8.0'),
    'Object[]')
};

declare %t:case function t:type-javascript-param-sem-iri()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'sem:iri', '8.0'),
    'sem.iri')
};

declare %t:case function t:type-javascript-param-xs-unsignedLong()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'xs:unsignedLong', '8.0'),
    'String')
};

declare %t:case function t:type-javascript-param-xs-string-plus()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'xs:string+', '8.0'),
    'String[]')
};

declare %t:case function t:type-javascript-param-xs-string-question()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'xs:string?', '8.0'),
    'String?')
};

declare %t:case function t:type-javascript-param-xs-string-star()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'xs:string*', '8.0'),
    'String[]')
};

declare %t:case function t:type-javascript-param-xs-anyAtomicType-star()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'xs:anyAtomicType*', '8.0'),
    '(String | Number | Boolean | null | Array | Object)[]')
};

declare %t:case function t:type-javascript-return-cts-query-star()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, 'return', 'cts:query*', '8.0'),
    'ValueIterator')
};

declare %t:case function t:type-javascript-return-xs-string-plus()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, 'return', 'xs:string+', '8.0'),
    'ValueIterator')
};

declare %t:case function t:type-javascript-return-xs-string-star()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, 'return', 'xs:string*', '8.0'),
    'ValueIterator')
};

declare %t:case function t:type-xpath-element-or-map()
{
  at:equal(
    api:type($api:MODE-XPATH, (), '(element()|map:map)?', '8.0'),
    '(element()|map:map)?')
};

declare %t:case function t:type-xpath-xs-string-plus()
{
  at:equal(
    api:type($api:MODE-XPATH, (), 'xs:string+', '8.0'),
    'xs:string+')
};

declare %t:case function t:type-xpath-xs-string-question()
{
  at:equal(
    api:type($api:MODE-XPATH, (), 'xs:string?', '8.0'),
    'xs:string?')
};

declare %t:case function t:type-xpath-xs-string-star()
{
  at:equal(
    api:type($api:MODE-XPATH, (), 'xs:string*', '8.0'),
    'xs:string*')
};

declare %t:case function t:type-xpath-xs-unsignedLong()
{
  at:equal(
    api:type($api:MODE-XPATH, (), 'xs:unsignedLong', '8.0'),
    'xs:unsignedLong')
};

(: test/apidoc-model.xqm :)
