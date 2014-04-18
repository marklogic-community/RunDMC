xquery version "1.0-ml";
(: sample test module :)

module namespace t="http://github.com/robwhitby/xray/test";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace at="http://github.com/robwhitby/xray/assertions"
  at "/xray/src/assertions.xqy";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";

import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "/apidoc/setup/raw-docs-access.xqy";

declare %t:case function t:invoke-ok()
{
  at:empty(
    raw:invoke-function(function() { () }))
};

declare %t:case function t:javascript-name()
{
  at:equal(
    "fooBarBaz",
    api:javascript-name('foo-bar-baz'))
};

(: test/apidoc-setup.xqm :)