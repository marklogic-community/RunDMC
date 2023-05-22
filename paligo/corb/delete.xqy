xquery version "1.0-ml";

declare variable $URI as xs:string external;

if (fn:starts-with($URI, '/paligo/')) then
  xdmp:document-delete($URI)
else ()