(: This script kicks off a complete build for the docs
 : for a specific server version.
 :
 : See README_FOR_NIGHTLY_BUILD.txt for more details.
 :)
xquery version "1.0-ml";

import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

declare variable $ACTION as xs:string* := xdmp:get-request-field(
  'action') ;

declare variable $CLEAN as xs:boolean? := xdmp:get-request-field(
  "clean") ! xs:boolean(.) ;
declare variable $HELP-XSD-DIR as xs:string := xdmp:get-request-field(
  'help-xsd-dir') ;
declare variable $VERSION as xs:string := xdmp:get-request-field(
  'version') ;
declare variable $ZIP as xs:string := xdmp:get-request-field(
  'zip') ;

declare variable $ACTIONS as xs:string+ := (
  (: Optionally delete everything first (if clean=yes is specified) :)
  if (not($CLEAN)) then ()
  else ("delete-raw-docs", "delete-docs")
  ,
  if ($ACTION) then $ACTION
  else (
    (: Load and build everything :)
    "load-static-docs",
    "load-raw-docs",
    "setup-guides",
    "setup",
    "/setup/collection-tagger",
    "make-standalone-search-page")) ;

declare variable $VARS := (
  xs:QName('HELP-XSD-DIR'), $HELP-XSD-DIR,
  xs:QName('VERSION'), $VERSION,
  xs:QName('ZIP'), $ZIP) ;

if ($VERSION = $stp:LEGAL-VERSIONS) then () else stp:error(
  "ERROR",
  ("You must specify a 'version' param with one of these values:",
    string-join($stp:LEGAL-VERSIONS,", "))),

(: This may take some time to run :)
xdmp:set-request-time-limit(1800),

(: as well as these params,
 : used in load-raw-docs.xqy and load-static-docs.xqy
 :)
for $xqy at $x in $ACTIONS
let $_ := stp:info(
  'build.xqy', ($VERSION, 'starting', $xqy, xdmp:elapsed-time()))
let $_ := xdmp:invoke($xqy||'.xqy', $VARS)
return text { $xqy, $VERSION, xdmp:elapsed-time() }
,
text { ''}

(: apidoc/setup/build.xqy :)