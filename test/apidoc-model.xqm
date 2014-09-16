xquery version "1.0-ml";
(: Test module for apidoc/data-access :)

module namespace t="http://github.com/robwhitby/xray/test";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace at="http://github.com/robwhitby/xray/assertions"
  at "/xray/src/assertions.xqy";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";

declare %t:case function t:type-javascript-xs-unsignedLong()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, 'xs:unsignedLong'),
    'String')
};

declare %t:case function t:type-xpath-xs-unsignedLong()
{
  at:equal(
    api:type($api:MODE-XPATH, 'xs:unsignedLong'),
    'xs:unsignedLong')
};

declare %t:case function t:type-javascript-xs-string-plus()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, 'xs:string+'),
    'ValueIterator')
};

declare %t:case function t:type-xpath-xs-string-plus()
{
  at:equal(
    api:type($api:MODE-XPATH, 'xs:string+'),
    'xs:string+')
};

declare %t:case function t:type-javascript-xs-string-question()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, 'xs:string?'),
    'String?')
};

declare %t:case function t:type-xpath-xs-string-question()
{
  at:equal(
    api:type($api:MODE-XPATH, 'xs:string?'),
    'xs:string?')
};

declare %t:case function t:type-javascript-xs-string-star()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, 'xs:string*'),
    'ValueIterator')
};

declare %t:case function t:type-xpath-xs-string-star()
{
  at:equal(
    api:type($api:MODE-XPATH, 'xs:string*'),
    'xs:string*')
};

declare %t:case function t:type-javascript-element-or-map()
{
  at:equal(
    api:type($api:MODE-JAVASCRIPT, '(element()|map:map)?'),
    'Object?')
};

declare %t:case function t:type-xpath-element-or-map()
{
  at:equal(
    api:type($api:MODE-XPATH, '(element()|map:map)?'),
    '(element()|map:map)?')
};

(: test/apidoc-model.xqm :)