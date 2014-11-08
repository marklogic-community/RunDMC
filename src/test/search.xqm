xquery version "1.0-ml";
(: Test module for search controller code :)

module namespace t="http://github.com/robwhitby/xray/test";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace at="http://github.com/robwhitby/xray/assertions"
  at "/xray/src/assertions.xqy";

declare %t:case function t:search-300()
{
  at:not-empty(
    xdmp:xslt-invoke(
      "/view/page.xsl",
      doc("/apidoc/do-search.xml"),
      map:new(
        map:entry(
          'params',
          (<param name="src">/apidoc/do-search.xml</param>,
            <param name="version"/>,
            <param name="v">7.0</param>,
            <param name="v"/>)))))
};

(: test/search.xqm :)