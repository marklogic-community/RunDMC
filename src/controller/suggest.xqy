xquery version "1.0-ml" ;

import module namespace ss="http://developer.marklogic.com/site/search"
  at "/controller/search.xqm" ;

declare variable $SUBSTR as xs:string? := xdmp:get-request-field('substr') ;
declare variable $COUNT as xs:integer := (
  xs:integer(
    xdmp:get-request-field('count')[. castable as xs:integer]),
  5)[1] ;
declare variable $POS as xs:integer := (
  xs:integer(
    xdmp:get-request-field('pos')[. castable as xs:integer]),
  string-length($SUBSTR))[1];

xdmp:set-response-content-type('application/json; charset=UTF-8'),
xdmp:to-json(
  json:to-array(
    ss:suggest($SUBSTR, $COUNT, $POS)))

(: controller/suggest.xqy :)