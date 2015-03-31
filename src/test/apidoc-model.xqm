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
    api:type($api:MODE-JAVASCRIPT, (), 'cts:query'),
    'cts.query')
};

declare %t:case function t:type-javascript-param-cts-query-star()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'cts:query*'),
    'cts.query[]')
};

declare %t:case function t:type-javascript-param-cts-query-plus()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'cts:query+'),
    'cts.query[]')
};

declare %t:case function t:type-javascript-param-cts-query-question()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'cts:query?'),
    'cts.query?')
};

declare %t:case function t:type-javascript-param-element-or-map()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), '(element()|map:map)?'),
    'Object?')
};

declare %t:case function t:type-javascript-param-item-star()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'item()*'),
    'ValueIterator')
};

declare %t:case function t:type-javascript-param-map-star()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'map:map*'),
    'Object[]')
};

declare %t:case function t:type-javascript-param-sem-iri()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'sem:iri'),
    'sem.iri')
};

declare %t:case function t:type-javascript-param-xs-unsignedLong()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'xs:unsignedLong'),
    'String')
};

declare %t:case function t:type-javascript-param-xs-string-plus()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'xs:string+'),
    'String[]')
};

declare %t:case function t:type-javascript-param-xs-string-question()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'xs:string?'),
    'String?')
};

declare %t:case function t:type-javascript-param-xs-string-star()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'xs:string*'),
    'String[]')
};

declare %t:case function t:type-javascript-param-xs-anyAtomicType-star()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, (), 'xs:anyAtomicType*'),
    '(String | Number | Boolean | null)[]')
};

declare %t:case function t:type-javascript-return-cts-query-star()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, 'return', 'cts:query*'),
    'ValueIterator')
};

declare %t:case function t:type-javascript-return-xs-string-plus()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, 'return', 'xs:string+'),
    'ValueIterator')
};

declare %t:case function t:type-javascript-return-xs-string-star()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, 'return', 'xs:string*'),
    'ValueIterator')
};

declare %t:case function t:type-xpath-element-or-map()
{
  at:equal(
    api:type($api:MODE-XPATH, (), '(element()|map:map)?'),
    '(element()|map:map)?')
};

declare %t:case function t:type-xpath-xs-string-plus()
{
  at:equal(
    api:type($api:MODE-XPATH, (), 'xs:string+'),
    'xs:string+')
};

declare %t:case function t:type-xpath-xs-string-question()
{
  at:equal(
    api:type($api:MODE-XPATH, (), 'xs:string?'),
    'xs:string?')
};

declare %t:case function t:type-xpath-xs-string-star()
{
  at:equal(
    api:type($api:MODE-XPATH, (), 'xs:string*'),
    'xs:string*')
};

declare %t:case function t:type-xpath-xs-unsignedLong()
{
  at:equal(
    api:type($api:MODE-XPATH, (), 'xs:unsignedLong'),
    'xs:unsignedLong')
};

(: test/apidoc-model.xqm :)