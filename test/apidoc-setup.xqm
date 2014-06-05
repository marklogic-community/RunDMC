xquery version "1.0-ml";
(: Test module for apidoc/setup :)

module namespace t="http://github.com/robwhitby/xray/test";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace at="http://github.com/robwhitby/xray/assertions"
  at "/xray/src/assertions.xqy";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";
import module namespace guide="http://marklogic.com/rundmc/api/guide"
  at "/apidoc/setup/guide.xqm";
import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "/apidoc/setup/setup.xqm";
import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "/apidoc/setup/raw-docs-access.xqy";

declare namespace apidoc="http://marklogic.com/xdmp/apidoc";

declare %t:case function t:function-hide-javascript-specific()
{
  at:empty(
    stp:fixup(
      element apidoc:function {
        attribute class { $api:MODE-JAVASCRIPT },
        'Hello world!' },
      $api:MODE-XPATH))
};

declare %t:case function t:function-hide-javascript-specific-example()
{
  at:empty(
    stp:fixup(
      element apidoc:function {
        element apidoc:example {
          attribute class { $api:MODE-JAVASCRIPT }, 'fubar' },
        'Hello world!' },
      $api:MODE-XPATH)/api:example)
};

declare %t:case function t:function-hide-javascript-specific-param()
{
  at:equal(
    stp:fixup(
      element apidoc:function {
        element apidoc:params {
          element apidoc:param {
            attribute class { $api:MODE-JAVASCRIPT }, 'fubar' },
          element apidoc:param { 'snafu' } },
        'Hello world!' },
      $api:MODE-XPATH)/api:params/api:param/string(),
    'snafu')
};

declare %t:case function t:function-hide-xquery-specific()
{
  at:empty(
    stp:fixup(
      element apidoc:function {
        attribute class { $api:MODE-XPATH },
        'Hello world!' },
      $api:MODE-JAVASCRIPT))
};

declare %t:case function t:function-hide-xquery-specific-example()
{
  at:empty(
    stp:fixup(
      element apidoc:function {
        element apidoc:example { attribute class { $api:MODE-XPATH }, 'fubar' },
        'Hello world!' },
      $api:MODE-JAVASCRIPT)/api:example)
};

declare %t:case function t:function-hide-xquery-specific-param()
{
  at:equal(
    stp:fixup(
      element apidoc:function {
        element apidoc:params {
          element apidoc:param {
            attribute class { $api:MODE-XPATH }, 'fubar' },
          element apidoc:param { 'snafu' } },
        'Hello world!' },
      $api:MODE-JAVASCRIPT)/api:params/api:param/string(),
    'snafu')
};

declare %t:case function t:function-ignore-unknown-mode()
{
  at:equal(
    stp:fixup(
      element apidoc:function {
        attribute class { 'fubar' },
        'snafu' },
      $api:MODE-XPATH)/string(),
    'snafu')
};

declare %t:case function t:function-show-javascript-specific()
{
  at:true(
    exists(
      stp:fixup(
        element apidoc:function {
          attribute class { $api:MODE-JAVASCRIPT },
          'Hello world!' },
        $api:MODE-JAVASCRIPT)))
};

declare %t:case function t:function-show-javascript-specific-example()
{
  at:equal(
    stp:fixup(
      element apidoc:function {
        element apidoc:example {
          attribute class { $api:MODE-JAVASCRIPT }, 'fubar' },
        'Hello world!' },
      $api:MODE-JAVASCRIPT)/api:example/string(),
    'fubar')
};

declare %t:case function t:function-show-javascript-specific-param()
{
  at:equal(
    stp:fixup(
      element apidoc:function {
        element apidoc:params {
          element apidoc:param {
            attribute class { $api:MODE-JAVASCRIPT }, 'fubar' },
          element apidoc:param { 'snafu' } },
        'Hello world!' },
      $api:MODE-JAVASCRIPT)/api:params/api:param/string(),
    ('fubar', 'snafu'))
};

declare %t:case function t:function-show-xquery-specific()
{
  at:true(
    exists(
      stp:fixup(
        element apidoc:function {
          attribute class { $api:MODE-XPATH },
          'Hello world!' },
        $api:MODE-XPATH)))
};

declare %t:case function t:function-show-xquery-specific-example()
{
  at:equal(
    stp:fixup(
      element apidoc:function {
        element apidoc:example { attribute class { $api:MODE-XPATH }, 'fubar' },
        'Hello world!' },
      $api:MODE-XPATH)/api:example/string(),
    'fubar')
};

declare %t:case function t:function-show-xquery-specific-param()
{
  at:equal(
    stp:fixup(
      element apidoc:function {
        element apidoc:params {
          element apidoc:param { attribute class { $api:MODE-XPATH }, 'fubar' },
          element apidoc:param { 'snafu' } },
        'Hello world!' },
      $api:MODE-XPATH)/api:params/api:param/string(),
    ('fubar', 'snafu'))
};

declare %t:case function t:raw-invoke-ok()
{
  at:equal(
    1,
    raw:invoke-function(function() { 1 }))
};

declare %t:case function t:javascript-name()
{
  at:equal(
    "fooBarBaz",
    api:javascript-name('foo-bar-baz'))
};

(: test/apidoc-setup.xqm :)