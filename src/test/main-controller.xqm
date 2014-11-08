xquery version "1.0-ml";
(: Test module for controller code :)

module namespace t="http://github.com/robwhitby/xray/test";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace at="http://github.com/robwhitby/xray/assertions"
  at "/xray/src/assertions.xqy";

import module namespace ml="http://developer.marklogic.com/site/internal"
  at "/model/data-access.xqy";

declare %t:case function t:main-controller-300()
{
  at:equal(
    ml:version-select(
      (<param name="v">7.0</param>,
        <param name="v"/>)),
    '7.0')
};

(: test/search.xqm :)