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

declare variable $VERSION := '8.0' ;

declare %t:case function t:function-hide-javascript-specific()
{
  at:empty(
    stp:fixup(
      $VERSION,
      element apidoc:function {
        attribute class { $api:MODE-JAVASCRIPT },
        'Hello world!' },
      $api:MODE-XPATH))
};

declare %t:case function t:function-hide-javascript-specific-example()
{
  at:empty(
    stp:fixup(
      $VERSION,
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
      $VERSION,
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
      $VERSION,
      element apidoc:function {
        attribute class { $api:MODE-XPATH },
        'Hello world!' },
      $api:MODE-JAVASCRIPT))
};

declare %t:case function t:function-hide-xquery-specific-example()
{
  at:empty(
    stp:fixup(
      $VERSION,
      element apidoc:function {
        attribute name { 'test' },
        element apidoc:example { attribute class { $api:MODE-XPATH }, 'fubar' },
        'Hello world!' },
      $api:MODE-JAVASCRIPT)/api:example)
};

declare %t:case function t:function-hide-xquery-specific-param()
{
  at:equal(
    stp:fixup(
      $VERSION,
      element apidoc:function {
        attribute name { 'test' },
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
      $VERSION,
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
       $VERSION,
        element apidoc:function {
          attribute name { 'test' },
          attribute class { $api:MODE-JAVASCRIPT },
          'Hello world!' },
        $api:MODE-JAVASCRIPT)))
};

declare %t:case function t:function-show-javascript-specific-example()
{
  at:equal(
    stp:fixup(
      $VERSION,
      element apidoc:function {
        attribute name { 'test' },
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
      $VERSION,
      element apidoc:function {
        attribute name { 'test' },
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
        $VERSION,
        element apidoc:function {
          attribute class { $api:MODE-XPATH },
          'Hello world!' },
        $api:MODE-XPATH)))
};

declare %t:case function t:function-show-xquery-specific-example()
{
  at:equal(
    stp:fixup(
      $VERSION,
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
      $VERSION,
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

declare %t:case function t:function-name-javascript-noop()
{
  element apidoc:function {
    attribute name { 'fubar' } }
  ! api:javascript-name(.)
  ! at:equal(., 'fubar')
};

declare %t:case function t:function-name-javascript-camelcase()
{
  element apidoc:function {
    attribute name { 'foo-bar-baz' } }
  ! api:javascript-name(.)
  ! at:equal(., "fooBarBaz")
};

declare %t:case function t:function-name-javascript-override()
{
  element apidoc:function {
    attribute name { 'to-json' },
    element apidoc:name {
      attribute class { 'javascript' },
      'toJSON' } }
  ! api:javascript-name(.)
  ! at:equal(., 'toJSON')
};

declare %t:case function t:function-names-REST()
{
  at:equal(
    stp:function-names(
      element apidoc:function {
        attribute http-verb { 'POST' },
        attribute name { '/foo/bar' } }),
    'POST:/foo/bar')
};

declare %t:case function t:function-guide-link()
{
  at:equal(
    stp:fixup-attribute-href(
      '8.0',
      <a xmlns=""
      href="#display.xqy?fname=http://pubs/6.0doc/xml/search-dev-guide/search-api.xml%2341745"/>/@href,
      ())/string(),
    '/guide/search-dev/search-api#id_41745')
};

declare %t:case function t:fixup-href-issue-324()
{
  at:equal(
    stp:fixup-attribute-href(
      $VERSION,
      element a {
        attribute href { '#xdmp:spawn#spawnresultex' } }/@href,
      $api:MODE-XPATH),
    attribute href { './xdmp:spawn#spawnresultex' })
};

declare %t:case function t:fixup-href-xpath-fragment()
{
  document {
    element apidoc:module {
      (: Target function. :)
      element apidoc:function {
        attribute name { 'eval' },
        attribute lib { "xdmp" } },
      (: Link from somewhere else in the same module. :)
      element a {
        attribute href {
          '#xdmp:eval#eval-ex4' } } } }
  ! at:equal(
    stp:fixup-attribute-href(
      $VERSION,
      apidoc:module/a/@href treat as node(),
      $api:MODE-REST),
    attribute href { './xdmp:eval#eval-ex4' })
};

declare %t:case function t:fixup-href-REST-fragment-only-issue-466()
{
  document {
    element apidoc:module {
      (: Target function. :)
      element apidoc:function {
        attribute http-verb { 'POST' },
        attribute name { '/manage/v2/databases/{id|name}' },
        attribute lib { "manage" },
        (: Link within the same page. :)
        element a {
          attribute href {
            '#ValidateBackup' } } } } }
  ! at:equal(
    stp:fixup-attribute-href(
      $VERSION,
      apidoc:module/apidoc:function/a/@href treat as node(),
      $api:MODE-REST),
    attribute href { '#ValidateBackup' })
};

declare %t:case function t:fixup-href-REST-with-fragment-issue-466()
{
  document {
    element apidoc:module {
      (: Target function. :)
      element apidoc:function {
        attribute http-verb { 'POST' },
        attribute name { '/manage/v2/databases/{id|name}' },
        attribute lib { "manage" } },
      (: Link from somewhere else in the same module. :)
      element a {
        attribute href {
          '#POST:/manage/v2/databases/{id|name}#ValidateBackup' } } } }
  ! at:equal(
    stp:fixup-attribute-href(
      $VERSION,
      apidoc:module/a/@href treat as node(),
      $api:MODE-REST),
    attribute href {
      '/../../../../../../..'
      ||'/REST/POST/manage/v2/databases/[id-or-name]#ValidateBackup' })
};

declare %t:case function t:schema-info-description()
{
  stp:schema-info(
    <xs:schema>
      <xs:element ref="forest-id"/>
      <xs:element name="forest-id" type="forest-id">
        <xs:annotation>
          <xs:documentation>
    The unique key of the forest.
          </xs:documentation>
          <xs:appinfo>
          </xs:appinfo>
        </xs:annotation>
      </xs:element>
      </xs:schema>
    ! document { . }/xs:schema/xs:element[@ref eq "forest-id"],
    'test',
    false())
  ! at:equal(
    api:element-description/normalize-space(.),
    'The unique key of the forest.')
};

declare %t:case function t:schema-info-no-camel-case()
{
  stp:schema-info(
    <xs:schema>
      <xs:element ref="forest-id"/>
      <xs:element name="forest-id" type="forest-id">
        <xs:annotation>
          <xs:documentation>
    The unique key of the forest.
          </xs:documentation>
          <xs:appinfo>
          </xs:appinfo>
        </xs:annotation>
      </xs:element>
      </xs:schema>
    ! document { . }/xs:schema/xs:element[@ref eq "forest-id"],
    'test',
    false())
  ! at:equal(api:element-name/string(), 'forest-id')
};

declare %t:case function t:schema-info-with-camel-case()
{
  stp:schema-info(
    <xs:schema>
      <xs:element ref="forest-id"/>
      <xs:element name="forest-id" type="forest-id">
        <xs:annotation>
          <xs:documentation>
    The unique key of the forest.
          </xs:documentation>
          <xs:appinfo>
          </xs:appinfo>
        </xs:annotation>
      </xs:element>
      </xs:schema>
    ! document { . }/xs:schema/xs:element[@ref eq "forest-id"],
    'test',
    true())
  ! at:equal(api:element-name/string(), 'forestId')
};

(: test/apidoc-setup.xqm :)