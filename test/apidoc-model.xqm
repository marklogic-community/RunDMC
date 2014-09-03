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

(: test/apidoc-model.xqm :)