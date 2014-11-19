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

declare variable $URL-BASE := 'http://localhost:8011' ;

declare function t:setup($path as xs:string)
  as empty-sequence()
{
  xdmp:set($rwa:PATH-ORIG, $path),
  xdmp:set($rwa:QUERY-STRING, ''),
  xdmp:set($rwa:QUERY-STRING-FIELDS, ()),
  xdmp:set($rwa:URL-ORIG, $URL-BASE||$path)
};

(: This test requires database content to succeed. :)
declare %t:case function t:js-all()
{
  t:setup('/js/all'),
  at:equal(
    rwa:rewrite(),
    if ($rw:API-VERSION lt '8.0') then $rw:NOTFOUND
    else ('/apidoc/controller/transform.xqy?src=/apidoc/'
      ||$rw:API-VERSION
      ||'/js/all.xml&amp;version=&amp;'))
};

declare %t:case function t:js-static()
{
  t:setup('/js/fubar.js'),
  at:equal(
    rwa:rewrite(),
    '/js/fubar.js')
};

declare %t:case function t:guide-message-XDMP-BAD()
{
  t:setup('/guide/messages/XDMP-en/XDMP-BAD'),
  at:equal(
    rwa:rewrite(),
    '/controller/redirect.xqy?path=/'
    ||$rw:API-VERSION
    ||'/guide/messages/XDMP-en%23XDMP-BAD')
};

declare %t:case function t:issue-304()
{
  t:setup('/guide/app-dev/aggregateUDFs/+%E8'),
  at:equal(
    rwa:rewrite(),
    $rw:NOTFOUND)
};

declare %t:case function t:issue-316()
{
  t:setup('/apidoc/7.0/fn:doc'),
  at:equal(
    rwa:rewrite(),
    '/controller/redirect.xqy?path=/7.0/fn%3adoc'),
  (: We want a permanent redirect. :)
  at:equal(xdmp:get-response-code(), (301, 'Moved Permanently')),
  (: Override the reponse code for xray. :)
  xdmp:set-response-code(200, "OK")
};

declare %t:case function t:issue-316-static()
{
  (: Make sure the fix for #316 does not break static resources. :)
  t:setup('/apidoc/js/toc_filter.js'),
  at:equal(
    rwa:rewrite(),
    $rwa:PATH-ORIG)
};

declare %t:case function t:message-XDMP-en-XDMP-BAD()
{
  t:setup('/messages/XDMP-en/XDMP-BAD'),
  at:equal(
    rwa:rewrite(),
    '/controller/redirect.xqy?path=/'
    ||$rw:API-VERSION||'/messages/XDMP-en/XDMP-BAD')
};

declare %t:case function t:message-XDMP-BAD()
{
  t:setup('/messages/XDMP-BAD'),
  at:equal(
    rwa:rewrite(),
    '/controller/redirect.xqy?path=/'
    ||$rw:API-VERSION||'/messages/XDMP-en/XDMP-BAD')
};

declare %t:case function t:message-SVC-CANCELED()
{
  t:setup('/messages/SVC-CANCELED'),
  at:equal(
    rwa:rewrite(),
    '/controller/redirect.xqy?path=/'
    ||$rw:API-VERSION||'/messages/SVC-en/SVC-CANCELED')
};

declare %t:case function t:message-SVC-CANCELED-with-version()
{
  t:setup('/'||$rw:API-VERSION||'/messages/SVC-CANCELED'),
  at:equal(
    rwa:rewrite(),
    '/controller/redirect.xqy?path=/'
    ||$rw:API-VERSION||'/messages/SVC-en/SVC-CANCELED')
};

declare %t:case function t:root()
{
  t:setup('/'),
  at:equal(
    rwa:rewrite(),
    '/apidoc/controller/transform.xqy?src=/apidoc/'
    ||$rw:API-VERSION
    ||'/index.xml&amp;version=&amp;')
};

(: test/apidoc-rewrite.xqm :)