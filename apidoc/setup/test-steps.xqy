xquery version "1.0-ml";

import module namespace setup = "http://marklogic.com/rundmc/api/setup"
       at "common.xqy";

(: Convenient for development purposes to call these scripts
   individually; this wrapper is necessary to provide the
   external variable values :)

(: E.g., to re-render the HTML TOC from the XML, make this request:

    http://localhost:8008/apidoc/setup/test-steps.xqy?step=render-toc

  (replacing the port with the port of a maintenance-only app server)
:)

declare variable $step    := xdmp:get-request-field("step");

if ($step eq 'pull-function-docs') then
  xdmp:invoke("pull-function-docs.xqy") else

if ($step eq 'create-toc') then
  xdmp:invoke("create-toc.xqy") else

if ($step eq 'render-toc') then
  xdmp:invoke("render-toc.xqy", (xs:QName("toc-url"), $toc-url,
                                 xs:QName("toc-xml-url"), $toc-xml-url)) else

if ($step eq 'make-list-pages') then
  xdmp:invoke("make-list-pages.xqy", (xs:QName("toc-xml-url"), $toc-xml-url))

else 
  "You didn't provide a recognized 'step' value."
