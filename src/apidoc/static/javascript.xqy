xquery version "1.0-ml";

import module namespace s="http://marklogic.com/rundmc/api/static"
    at "static.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

s:static("javascript", xdmp:get-request-field("prefix"))
