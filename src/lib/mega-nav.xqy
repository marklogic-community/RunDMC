xquery version "1.0-ml";

module namespace mn = "http://mlu.marklogic.com/mega-nav";

import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";
import module namespace config = "http://developer.marklogic.com/roxy/config" at "/app/config/config.xqy";

declare namespace mljson = "http://marklogic.com/xdmp/json/basic";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace mnt = "http://mlu.marklogic.com/mega-nav/tracking";
declare namespace mnm = "http://mlu.marklogic.com/mega-nav/markup";

(: the service (minus the last part, the key) that we hit to return the markup :)
declare variable $url := (
    (: if hosted via modules db, then this should get filled up via roxy deployer :)
    if (fn:contains($config:MLAPI-SRC, "${")) then ()
    else $config:MLAPI-SRC
    ,
    (: if hosted via filesystem, then this would have to be adjusted manually 
     : if needed to be pointed to another instance 
     :)
    "https://mlwebdevel.wpengine.com/wp-json/mlapi/v2/json/"
  )[1];
declare variable $search-flag := (
    (: if hosted via modules db, then this should get filled up via roxy deployer :)
    if (fn:contains($config:MLAPI-FLAG, "${")) then ()
    else $config:MLAPI-FLAG
    ,
    (: if hosted via filesystem, then this would have to be adjusted manually 
     : if needed to be pointed to another instance 
     :)
    "search=true"
  )[1];

(: enter the role name associated with your default user :)
declare variable $default-user-role := "dmc-user";

(: enter the role name associated with an authenticated user :)
declare variable $authenticated-user-role := "dmc-user";


declare function mn:mega-nav-controller(
  $key as xs:string
) as node()* {
    (: 
        This function runs the show. You call it from your template where you wish to inject the markup for the mega-nav.
        Pass it the key for the markup that you wish to inject: "scripts", "stylesheets", "header" or "footer".
        Example function call: mn:mega-nav-controller("scripts")
    :)
    let $current-date := fn:current-date()
    return if (mn:date-check($current-date, $key) eq fn:true())
    then 
        (: markup HAS been stored in the database today, get the markup from the database :)
        mn:get-markup($key)
    else 
        (: markup HAS NOT been stored in the database today, update the database with the latest markup and then return the markup :)
        mn:create-markup($current-date, $key)    

};

declare function mn:date-check (
  $current-date as xs:date,
  $key as xs:string
) as xs:boolean {
    (: 
        This function checks to see if we have already written the markup to the database for today. 
    :)
    let $current-day-number := fn:day-from-date($current-date)
    let $tracking-doc-day-number := xdmp:invoke-function(
        function() {
          /mnt:mega-nav-tracking[mnt:type = $key]/mnt:update-tracking/mnt:day/string()
        }
        ,
        <options xmlns="xdmp:eval">
          <transaction-mode>query</transaction-mode>
        </options>
      )
    return
        if ($current-day-number eq xs:integer($tracking-doc-day-number))
        then 
            (fn:true())
        else 
            (fn:false())
};

declare function mn:invoke-create-tracking-document(
  $today as xs:date,
  $current-day-number as xs:string,
  $key as xs:string
) as empty-sequence() {
    (: 
        This function creates (or updates) the tracking doc that is used to determine when to grab a new version of the mega-nav markup.
    :)
    xdmp:document-insert(
        fn:concat("/mega-nav/update-tracking/", $key, ".xml"),
        <mega-nav-tracking xmlns="http://mlu.marklogic.com/mega-nav/tracking">
            <type>{$key}</type>
            <update-tracking>
                <day>{$current-day-number}</day>
                <current-date>{fn:current-date()}</current-date>
            </update-tracking>    
        </mega-nav-tracking>,
        (
            xdmp:permission($default-user-role, "read"), 
            xdmp:permission($default-user-role, "update"), 
            xdmp:permission($authenticated-user-role, "read"), 
            xdmp:permission($authenticated-user-role, "update"),
            xdmp:default-permissions()
        ),
        ("mega-nav")
    )

};

declare function mn:get-markup(
  $key as xs:string
) as node()* {
    
  (: 
   : This function will get the markup based on the key from the appropriate document in the database 
   :)
  let $markup-doc := xdmp:invoke-function(
    function() {
      cts:search(fn:collection("mega-nav"), cts:element-value-query(xs:QName("mnm:type"), $key))
    }
    ,
    <options xmlns="xdmp:eval">
      <transaction-mode>query</transaction-mode>
    </options>
  )
  let $markup-to-inject :=
    if ($key eq "scripts") then
      $markup-doc//xhtml:script
    else if ($key eq "stylesheets") then
      $markup-doc//xhtml:link
    else if ($key eq "header") then
      $markup-doc//mnm:markup/*
    else if ($key eq "footer") then
      $markup-doc//mnm:markup/*
    else
      ()
  return
    $markup-to-inject
};

declare function mn:create-markup(
  $current-date as xs:date,
  $key as xs:string
) as node()* {
  (:
   : This function will build the markup for the key type and then invoke a function that will write that markup to the database.
   :)
  let $endpoint := fn:concat($url, $key, "?", $search-flag)
  let $raw-response := xdmp:http-get(
      $endpoint,
      (: not sure why, but adding this resolves the issue where the response is "cut-off" mid-way :)
      <options xmlns="xdmp:http">
        <verify-cert>false</verify-cert>
      </options>
    )
  let $response := try {
      json:transform-from-json(xdmp:from-json(xdmp:unquote(xdmp:quote($raw-response[2]))))
    } catch ($e) {
      xdmp:log(fn:concat('unable to transform: ', $endpoint, ': ', xdmp:quote($e), ', with data: ', xdmp:quote($raw-response)))
    }
  let $response-result := try {
      $response//mljson:flag/string()
    } catch ($e) {
      xdmp:log(fn:concat('unable to get flag: ', $endpoint, ': ', xdmp:quote($e), ', with data: ', xdmp:quote($response)))
    }
  let $processed-markup := 
    if ($response-result eq "SUCCESS") then
      if ($key eq "scripts") then 
        for $item in $response//mljson:scripts/* 
        let $path := $item/string() 
        return <script xmlns="http://www.w3.org/1999/xhtml" src="{$path}"></script> 
      else if ($key eq "stylesheets") then
        for $item in $response//mljson:stylesheets/*
        let $path := $item/string()
        return <link xmlns="http://www.w3.org/1999/xhtml" href="{$path}" type="text/css" media="all" rel="stylesheet" /> 
      else if ($key eq "header") then
        xdmp:unquote($response//*:markup/text(), ("http://www.w3.org/1999/xhtml"), ("repair-full"))/*:div  
      else if ($key eq "footer") then
        <footer id="mlbs4-footer" xmlns="http://www.w3.org/1999/xhtml">
          { xdmp:unquote($response//*:markup/text(), ("http://www.w3.org/1999/xhtml"), ("repair-full"))/*:div  }
        </footer> 
      else
        ()
    else
      mn:get-markup($key)
    
  let $markup-doc :=
    <mega-nav-markup xmlns="http://mlu.marklogic.com/mega-nav/markup">
        <type>{$key}</type>
        <markup>
            {$processed-markup}
        </markup>
    </mega-nav-markup>

  let $markup-doc-uri := fn:concat("/mega-nav/", $key, ".xml")

  let $tracking-doc := 
    <mega-nav-tracking xmlns="http://mlu.marklogic.com/mega-nav/tracking">
        <type>{$key}</type>
        <update-tracking>
            <day>{fn:day-from-date($current-date)}</day>
            <current-date>{$current-date}</current-date>
        </update-tracking>    
    </mega-nav-tracking>

  let $tracking-doc-uri := fn:concat("/mega-nav/update-tracking/", $key, ".xml")
    
  return (
    xdmp:invoke-function(
      function() { 
        mn:create-markup-and-tracking-docs(
            $markup-doc, 
            $markup-doc-uri,
            $tracking-doc,
            $tracking-doc-uri
        )
        , 
        xdmp:commit() 
      }
      ,
      <options xmlns="xdmp:eval">
        <transaction-mode>update</transaction-mode>
      </options>
    )
    ,
    $processed-markup
  )
};

declare function mn:create-markup-and-tracking-docs($markup-doc, $markup-doc-uri, $tracking-doc, $tracking-doc-uri){
    (:
        This function writes the markup and tracking docs to the database.
    :)
    xdmp:document-insert(
        $markup-doc-uri,
        $markup-doc,
        (
            xdmp:permission($default-user-role, "read"), 
            xdmp:permission($default-user-role, "update"), 
            xdmp:permission($authenticated-user-role, "read"), 
            xdmp:permission($authenticated-user-role, "update"),
            xdmp:default-permissions()
        ),
        ("mega-nav")
    ),
    xdmp:document-insert(
        $tracking-doc-uri,
        $tracking-doc,
        (
            xdmp:permission($default-user-role, "read"), 
            xdmp:permission($default-user-role, "update"), 
            xdmp:permission($authenticated-user-role, "read"), 
            xdmp:permission($authenticated-user-role, "update"),
            xdmp:default-permissions()
        ),
        ("mega-nav")
    )

};

declare function mn:current-page(
) as node() {
  <script>$("#menu-item-8668").addClass('current_page')</script>
};