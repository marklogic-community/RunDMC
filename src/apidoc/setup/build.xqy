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
declare variable $HELP-XSD-DIR as xs:string? := xdmp:get-request-field(
  'help-xsd-dir',
  (: NB - Undocumented function. :)
  xdmp:install-directory()||'/Config') ;
declare variable $VERSION as xs:string := xdmp:get-request-field(
  'version') ;
declare variable $ZIP as xs:string := xdmp:get-request-field(
  'zip') ;

declare variable $ACTIONS as xs:string+ := (
  if ($ACTION) then $ACTION
  else (
    (: Load and build everything :)
    "load-static-docs",
    "load-raw-docs",
    "setup-guides",
    "setup",
    "/setup/collection-tagger",
    "make-standalone-search-page")) ;

declare variable $ACTIONS-NEEDING-XSD := (
  "create-toc",
  'setup',
  'setup-guides',
  ()) ;

declare variable $ACTIONS-NEEDING-ZIP := (
  'load-static-docs',
  'load-raw-docs',
  ()) ;

declare variable $ACTIONS-SPAWN-OK := (
  "load-static-docs",
  ()) ;

declare variable $VARS := (
  if (not($ACTIONS = $ACTIONS-NEEDING-XSD)) then ()
  else (xs:QName('HELP-XSD-DIR'), $HELP-XSD-DIR treat as xs:string),
  xs:QName('VERSION'), $VERSION,
  if (not($ACTIONS = $ACTIONS-NEEDING-ZIP)) then ()
  else (xs:QName('ZIP'), $ZIP)) ;

if ($VERSION = $stp:LEGAL-VERSIONS) then () else stp:error(
  "ERROR",
  ("You must specify a 'version' param with one of these values:",
    string-join($stp:LEGAL-VERSIONS,", "))),

if (xdmp:filesystem-file-exists($HELP-XSD-DIR)) then () else stp:error(
  "ERROR",
  ('help-xsd-dir does not exist', xdmp:describe($HELP-XSD-DIR))),

(: This may take some time to run :)
xdmp:set-request-time-limit(1800),
stp:info(
  'build.xqy',
  ($VERSION, 'starting', 'clean', $CLEAN,
    'actions', count($ACTIONS), xdmp:describe($ACTIONS))),

(: If "clean" is specified, delete everything first. :)
if (not($CLEAN)) then ()
else xdmp:invoke('clean.xqy', (xs:QName('VERSION'), $VERSION))
,

(: as well as these params,
 : used in load-raw-docs.xqy and load-static-docs.xqy
 :)
for $action at $x in $ACTIONS
let $start := xdmp:elapsed-time()
let $xqy := $action||'.xqy'
let $_ := stp:info('build.xqy', ($VERSION, 'starting', $action, $start))
let $_ := (
  if ($action = $ACTIONS-SPAWN-OK) then xdmp:spawn($xqy, $VARS)
  else xdmp:invoke($xqy, $VARS))
return text { $action, $VERSION, xdmp:elapsed-time() - $start }
,
text { 'build', $VERSION, xdmp:elapsed-time() },
text { '' }

(: apidoc/setup/build.xqy :)