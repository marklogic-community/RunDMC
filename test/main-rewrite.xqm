xquery version "1.0-ml";
(: Test module for controller/rewrite.xqm :)

module namespace t="http://github.com/robwhitby/xray/test";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace at="http://github.com/robwhitby/xray/assertions"
  at "/xray/src/assertions.xqy";

import module namespace rw="http://marklogic.com/rundmc/rewrite"
  at "/controller/rewrite.xqm";

declare variable $NOTFOUND := (
  '/controller/301redirect.xqy?path=/controller/notfound.xqy') ;

declare %t:case function t:guide-296()
{
  at:equal(
    rw:rewrite(
      'GET',
      '/pubs/3.2/books/install.pdf',
      'http://developer.marklogic.com/pubs/3.2/books/install.pdf',
      ''),
    '/controller/301redirect.xqy?path=//localhost:8809/guide/installation.pdf')
};

declare %t:case function t:guide-299()
{
  at:equal(
    rw:rewrite(
      'GET',
      '/pubs/2.2/books/dev',
      'http://developer.marklogic.com/pubs/2.2/books/dev',
      ''),
    $NOTFOUND)
};

(: test/apidoc-rewrite.xqm :)