xquery version "1.0-ml";

import module namespace setup = "http://marklogic.com/rundmc/api/setup"
       at "common.xqy";

import module namespace raw = "http://marklogic.com/rundmc/raw-docs-access"
       at "raw-docs-access.xqy";

(: Make sure the version param was specified :)
$setup:errorCheck,

(: Combine the guide fragments into one document per guide :)
xdmp:invoke("consolidate-guides.xqy", (), <options xmlns="xdmp:eval">
                                            <database>{xdmp:database($raw:db-name)}</database>
                                          </options>),

(: Convert each combined guide into the XML that's convenient to render :)
xdmp:invoke("convert-guides.xqy"),

(:
xdmp:invoke("copy-guide-images.xqy"),
:)

(: TODO: maybe not here, but update the TOC code so that it includes the guide sections;
   for that reason, the guides may need to be set up before the TOC (setup.xqy) :)

xdmp:log("All done!")
