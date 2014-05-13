(: This script kicks off a complete build for the docs for a specific server version.
   See README_FOR_NIGHTLY_BUILD.txt for more details. :)
xquery version "1.0-ml";

import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

(: This may take some time to run :)
xdmp:set-request-time-limit(1800),

(: Make sure the version and help-xsd-dir params were specified :)
$stp:errorCheck,
$stp:helpXsdCheck,

(: as well as these params,
 : used in load-raw-docs.xqy and load-static-docs.xqy
 :)
if (xdmp:get-request-field("zip")) then ()
else error((), "ERROR", "You must specify a 'zip' param.")
,

for $xqy at $x in (
  (: Optionally delete everything first (if clean=yes is specified) :)
  if (not(xs:boolean(xdmp:get-request-field("clean")))) then ()
  else ("delete-raw-docs", "delete-docs")
  ,
  (: Load and build everything :)
  "load-static-docs",
  "load-raw-docs",
  "setup-guides",
  "setup",
  "/setup/collection-tagger",
  "make-standalone-search-page")
return xdmp:invoke($xqy||'.xqy')

(: apidoc/setup/build.xqy :)