xquery version "1.0-ml";
(: Test module for apidoc/guide :)

module namespace t="http://github.com/robwhitby/xray/test";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace at="http://github.com/robwhitby/xray/assertions"
  at "/xray/src/assertions.xqy";

import module namespace dates = "http://xqdev.com/dateparser" at "/lib/date-parser.xqy";

declare %t:case function t:_dashParse-with-dashes()
{
  at:equal(
    dates:_dashParse("25-oct-2004 17:06:46 -0500"),
    xs:dateTime("2004-10-25T17:06:46-05:00")
  )
};

declare %t:case function t:_dashParse-without-dashes()
{
  at:empty(dates:_dashParse("131445406060000000"))
};
