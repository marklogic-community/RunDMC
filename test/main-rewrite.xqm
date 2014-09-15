xquery version "1.0-ml";
(: Test module for controller/rewrite.xqm :)

module namespace t="http://github.com/robwhitby/xray/test";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace at="http://github.com/robwhitby/xray/assertions"
  at "/xray/src/assertions.xqy";

import module namespace rw="http://marklogic.com/rundmc/rewrite"
  at "/controller/rewrite.xqm";

declare %t:case function t:guide-296()
{
  at:equal(
    rw:rewrite(
      'GET',
      '/pubs/3.2/books/install.pdf',
      'http://developer.marklogic.com/pubs/3.2/books/install.pdf',
      ''),
    '/controller/301redirect.xqy?path=/controller/notfound.xqy')
};

(: test/apidoc-rewrite.xqm :)