xquery version "1.0-ml";

import module namespace s="http://marklogic.com/rundmc/api/static"
    at "static.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare variable $prefix := xdmp:get-request-field("prefix");
declare variable $version := xdmp:get-request-field("version");

let $doc := doc("/apidoc/" || $version || "/xdmp:document-insert.xml")
return
  if (empty($doc))
  then "There are no documents for " || $version || "."
  else s:static("xquery", $version, $prefix)

