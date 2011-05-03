xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

import module namespace setup = "http://marklogic.com/rundmc/api/setup"
       at "common.xqy";

declare function local:save-url-location($toc-url, $toc-url-location) {
  xdmp:log(concat("Recording current TOC URL (", $toc-url, ") at ", $toc-url-location)),
  xdmp:document-insert(
    $toc-url-location,
    document { <api:toc-url>{$toc-url}</api:toc-url>}
  ),
  xdmp:log("Done.")
};

declare function local:save-rendered-toc($toc-url, $is-default-toc) {
  xdmp:log(concat("Rendering the XML-based TOC to HTML at ",$toc-url,"...")),
  xdmp:document-insert($toc-url,
                       xdmp:xslt-invoke("render-toc.xsl", doc($setup:toc-xml-url),
                                        map:map(<map:map>
                                                  <map:entry>
                                                    <map:key>prefix-for-hrefs</map:key>
                                                    <map:value>{if ($is-default-toc) then () else concat("/",$api:version)}</map:value>
                                                  </map:entry>
                                                </map:map>))),
  xdmp:log("Done.")
};

(: Make sure the version param was specified :)
$setup:errorCheck,

(: Save the TOC filename :)
local:save-url-location($setup:toc-url,
                          $api:toc-url-location),
(: Render the HTML TOC :)
local:save-rendered-toc($setup:toc-url, false()),

(: If we're processing the default version, then we need to render another
   copy of the TOC that doesn't include version numbers in its href links :)
if ($setup:processing-default-version) then ( 
  local:save-url-location($setup:toc-url-default-version,
                            $api:toc-url-default-version-location),
  local:save-rendered-toc($setup:toc-url-default-version, true())
) else (),
  
"Rendered the HTML TOC(s) and recorded their URL(s)."
