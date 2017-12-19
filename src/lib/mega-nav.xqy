xquery version "1.0-ml";

module namespace mn = "http://mlu.marklogic.com/mega-nav";

import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace mljson = "http://marklogic.com/xdmp/json/basic";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";

declare variable $JS-KEY     := "scripts";
declare variable $CSS-KEY    := "stylesheets";
declare variable $HEADER-KEY := "header";
declare variable $FOOTER-KEY := "footer";

declare variable $url := "https://www.marklogic.orbit-websites.com/wp-json/mlapi/v1/json/";

declare function mn:get-javascript(){

  let $endpoint := fn:concat($url, $JS-KEY, "/")
  let $response := json:transform-from-json(xdmp:from-json(xdmp:http-get($endpoint)[2]))
  for $item in $response//mljson:scripts/*
  let $path := $item/string()
  return
    <script xmlns="http://www.w3.org/1999/xhtml" src="{$path}"></script>

};

declare function mn:get-css(){
  let $endpoint := fn:concat($url, $CSS-KEY, "/")
  let $response := json:transform-from-json(xdmp:from-json(xdmp:http-get($endpoint)[2]))
  for $item in $response//mljson:stylesheets/*
  let $path := $item/string()
  let $_ := xdmp:log("mn:get-css: " || $path)
  return
    <link href="{$path}" type="text/css" media="all" rel="stylesheet" />

};

declare function mn:get-header(){

  let $endpoint := fn:concat($url, $HEADER-KEY, "/")
  let $response := json:transform-from-json(xdmp:from-json(xdmp:http-get($endpoint)[2]))
  return
    xdmp:tidy($response//*:markup/text())[2]//*:body/*:div

};

declare function mn:get-footer(){

  let $endpoint := fn:concat($url, $FOOTER-KEY, "/")
  let $response := json:transform-from-json(xdmp:from-json(xdmp:http-get($endpoint)[2]))
  return
    xdmp:tidy($response//*:markup/text())[2]//*:body/*:div

};
