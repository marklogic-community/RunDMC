xquery version "1.0-ml";
(: Test module for apidoc/controller/rewrite.xqm :)

module namespace t="http://github.com/robwhitby/xray/test";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace at="http://github.com/robwhitby/xray/assertions"
  at "/xray/src/assertions.xqy";

import module namespace rw="http://marklogic.com/rundmc/rewrite"
  at "/controller/rewrite.xqm";
import module namespace rwa="http://marklogic.com/rundmc/apidoc/rewrite"
  at "/apidoc/controller/rewrite.xqm";

declare %t:case function t:js-all()
{
  xdmp:set($rwa:PATH-ORIG, '/js/all'),
  xdmp:set($rwa:URL-ORIG, 'http://localhost:8011'||$rwa:PATH-ORIG),
  at:equal(
    rwa:rewrite(),
    '/apidoc/controller/transform.xqy?src=/apidoc/'
    ||$rw:API-VERSION
    ||'/js/all.xml&amp;version=&amp;')
};

declare %t:case function t:js-static()
{
  xdmp:set($rwa:PATH-ORIG, '/js/fubar.js'),
  xdmp:set($rwa:URL-ORIG, 'http://localhost:8011'||$rwa:PATH-ORIG),
  at:equal(
    rwa:rewrite(),
    '/js/fubar.js')
};

declare %t:case function t:message-XDMP-BAD()
{
  xdmp:set($rwa:PATH-ORIG, '/guide/messages/XDMP-en/XDMP-BAD'),
  xdmp:set($rwa:URL-ORIG, 'http://localhost:8011'||$rwa:PATH-ORIG),
  at:equal(
    rwa:rewrite(),
    '/controller/redirect.xqy?path=/'
    ||$rw:API-VERSION
    ||'/guide/messages/XDMP-en%23XDMP-BAD')
};

declare %t:case function t:root()
{
  xdmp:set($rwa:PATH-ORIG, '/'),
  xdmp:set($rwa:URL-ORIG, 'http://localhost:8011'||$rwa:PATH-ORIG),
  at:equal(
    rwa:rewrite(),
    '/apidoc/controller/transform.xqy?src=/apidoc/'
    ||$rw:API-VERSION
    ||'/index.xml&amp;version=&amp;')
};

(: test/apidoc-rewrite.xqm :)