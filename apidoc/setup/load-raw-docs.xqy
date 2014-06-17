xquery version "1.0-ml";

import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

declare variable $ZIP as xs:string := xdmp:get-request-field("zip") ;
(: e.g., 4.1 :)
declare variable $VERSION as xs:string := xdmp:get-request-field("version") ;

if ($VERSION = $stp:LEGAL-VERSIONS) then () else stp:error(
  "ERROR",
  ("You must specify a 'version' param with one of these values:",
    string-join($stp:LEGAL-VERSIONS,", ")))
,
stp:zip-load-raw-docs(xdmp:document-get($ZIP)/node()),

text { "Loaded raw docs for", $VERSION, xdmp:elapsed-time() }

(: load-raw-docs.xqy :)