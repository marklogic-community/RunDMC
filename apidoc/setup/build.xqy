(: This script kicks off a complete build for the docs for a specific server version.
   See README_FOR_NIGHTLY_BUILD.txt for more details. :)
xquery version "1.0-ml";

import module namespace setup = "http://marklogic.com/rundmc/api/setup"
       at "common.xqy";

(: It may take some time to run :)
xdmp:set-request-time-limit(1800),

(: Make sure the version and help-xsd-dir params were specified :)
$setup:errorCheck,
$setup:helpXsdCheck,

(: as well as these params :)
if (not(xdmp:get-request-field("srcdir")))    then error(xs:QName("ERROR"), "You must specify a 'srcdir' param.")    else (), (: used in load-raw-docs.xqy and load-static-docs.xqy :)

(: Optionally delete everything first (if clean=yes is specified) :)
if (xdmp:get-request-field("clean") eq 'yes') then 
(
  xdmp:invoke("delete-static-docs.xqy"),
  xdmp:invoke("delete-raw-docs.xqy"),
  xdmp:invoke("delete-docs.xqy"),
  xdmp:invoke("delete-doc-images.xqy")
) else (),

(: Load and build everything :)
xdmp:invoke("load-static-docs.xqy"),
xdmp:invoke("load-raw-docs.xqy"),
xdmp:invoke("setup-guides.xqy"),
xdmp:invoke("setup.xqy"),
xdmp:invoke("/setup/collection-tagger.xqy"),
xdmp:invoke("make-standalone-search-page.xqy")
