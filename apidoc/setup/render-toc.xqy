xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";

import module namespace setup="http://marklogic.com/rundmc/api/setup"
  at "common.xqy";
import module namespace toc="http://marklogic.com/rundmc/api/toc"
  at "toc.xqm";

declare function local:save-url-location($toc-url, $toc-url-location) {
  xdmp:log(
    text {
      "Recording current TOC URL", $toc-url, "at", $toc-url-location}),
  xdmp:document-insert(
    $toc-url-location,
    document { element api:toc-url { $toc-url } })
};

declare function local:save-rendered-toc(
  $toc-url as xs:string,
  $is-default-toc as xs:boolean)
{
  xdmp:log(
    text {
      "Rendering", "default"[$is-default-toc], "HTML TOC at", $toc-url }),
  xdmp:xslt-invoke(
    "render-toc.xsl",
    doc($setup:toc-xml-url) treat as node(),
    map:new(
      (map:entry('toc-url', $toc-url),
        map:entry(
          'prefix-for-hrefs',
          if ($is-default-toc) then ()
          else concat("/",$api:version)),
        map:entry(
          'version', $api:version))))/
  xdmp:document-insert(base-uri(.), .),
  xdmp:log("Done.")
};

(: Make sure the version param was specified :)
$setup:errorCheck,

(: Save the TOC filename :)
local:save-url-location($setup:toc-url, $api:toc-url-location),
(: Render the HTML TOC :)
local:save-rendered-toc($setup:toc-url, false()),

(: If we are processing the default version,
 : then we need to render another copy of the TOC
 : that does not include version numbers in its href links.
 :)
if (not($setup:processing-default-version)) then ()
else (
  local:save-url-location(
    $setup:toc-url-default-version,
    $api:toc-url-default-version-location),
  local:save-rendered-toc($setup:toc-url-default-version, true()))
,

text {
  "Rendered the HTML TOC(s) and recorded their URL(s) in ",
  xdmp:elapsed-time() },
text { '' }

(: apidoc/setup/render-toc.xqy :)