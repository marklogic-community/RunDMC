xquery version "1.0-ml";
(: Serve a document directly from the database.
 :)
import module namespace dates="http://xqdev.com/dateparser"
  at "/lib/date-parser.xqy" ;

declare namespace xh="http://www.w3.org/1999/xhtml" ;

declare variable $IF-MODIFIED-SINCE := xdmp:get-request-header(
  "If-Modified-Since") ;
declare variable $URI as xs:string := xdmp:get-request-field("uri") ;

declare variable $DOC as document-node()? := doc($URI) ;
declare variable $LAST-MODIFIED := (
  if (empty($DOC)) then () else fn:adjust-dateTime-to-timezone(
  xdmp:document-get-properties($URI, xs:QName("prop:last-modified")),
  xs:dayTimeDuration("PT0H"))) ;
declare variable $URI-NORMALIZED := lower-case($URI) ;

(: Use default content-type. :)
typeswitch($DOC/*)
case element(xh:html) return xdmp:set-response-content-type(
  'application/xhtml+xml')
default return xdmp:set-response-content-type(
  xdmp:uri-content-type($URI))
,

$LAST-MODIFIED ! xdmp:add-response-header(
  "Last-Modified",
  fn:format-dateTime(
    $LAST-MODIFIED,
    "[FNn,*-3], [D01] [MNn,*-3] [Y0001] [H01]:[m01]:[s01] GMT","en","AD","US"))
,

if (empty($DOC)) then (
  xdmp:set-response-code(404, "Not found"),
  text { "404 Not found" })
else if (empty($IF-MODIFIED-SINCE) or empty($LAST-MODIFIED)
  (: Sat, 18 Dec 2010 01:10:43 GMT :)
  (: xdmp:parse-dateTime isn't ready for prime time :)
  or $LAST-MODIFIED gt dates:parseDateTime($IF-MODIFIED-SINCE)) then $DOC
else xdmp:set-response-code(304, "Not modified")

(: get-db-file.xqy :)