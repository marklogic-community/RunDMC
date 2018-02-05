xquery version "1.0-ml";

module namespace mn = "http://mlu.marklogic.com/mega-nav";

import module namespace json = "http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace mljson = "http://marklogic.com/xdmp/json/basic";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace mnt = "http://mlu.marklogic.com/mega-nav/tracking";
declare namespace mnm = "http://mlu.marklogic.com/mega-nav/markup";

(: the service (minus the last part, the key) that we hit to return the markup :)
declare variable $url := "https://www.marklogic.com/wp-json/mlapi/v1/json/";

(: enter the role name associated with your default user :)
declare variable $default-user-role := "dmc-user";

(: enter the role name associated with an authenticated user :)
declare variable $authenticated-user-role := "dmc-user";

declare function mn:mega-nav-controller($key){
    (:
        This function runs the show. You call it from your template where you wish to inject the markup for the mega-nav.
        Pass it the key for the markup that you wish to inject: "scripts", "stylesheets", "header" or "footer".
        Example function call: mn:mega-nav-controller("scripts")
    :)

    if (mn:date-check(fn:current-date(), $key) eq fn:true())
    then
        (: markup HAS been stored in the database today, get the markup from the database :)
        mn:get-markup($key)
    else
        (: markup HAS NOT been stored in the database today, update the database with the latest markup and then return the markup :)
        try {
            mn:create-markup($key)
        }
        catch ($e) {
            xdmp:log("Failed to get updated mega-nav! " || xdmp:quote($e), "error"),
            (: old stuff is better than no stuff :)
            mn:get-markup($key)
        }
};

declare function mn:date-check($today, $key){
    (:
        This function checks to see if we have already written the markup to the database for today.
        If we have not, or if a tracking document does not exist, it will invoke the function that creates the tracking document.
    :)
    let $current-day-number := fn:tokenize(xs:string($today), "-")[3]
    let $tracking-doc-day-number := /mnt:mega-nav[mnt:type = $key]/mnt:update-tracking/mnt:day/string()
    return
        if ($current-day-number eq $tracking-doc-day-number)
        then
            fn:true()
        else
            (xdmp:invoke-function(
                function() { mn:invoke-create-tracking-document($key), xdmp:commit() },
                <options xmlns="xdmp:eval">
                    <transaction-mode>update</transaction-mode>
                </options>)
            ),
            fn:false()

};

declare function mn:invoke-create-tracking-document($key){
    (:
        This function creates (or updates) the tracking doc that is used to determine when to grab a new version of the mega-nav markup.
    :)
    xdmp:document-insert(
        fn:concat("/mega-nav/update-tracking/", $key, ".xml"),
        <mega-nav-tracking xmlns="http://mlu.marklogic.com/mega-nav/tracking">
            <type>{$key}</type>
            <update-tracking>
                <day>{fn:tokenize(xs:string(fn:current-date()), "-")[3]}</day>
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

declare function mn:get-markup($key){

    (:
        This function will get the markup based on the key from the appropriate document in the database
    :)
    let $markup-doc := cts:search(fn:collection("mega-nav"), cts:element-value-query(xs:QName("mnm:type"), $key))
    let $markup-to-inject :=
        if ($key eq "scripts")
        then $markup-doc//xhtml:script
        else
            if ($key eq "stylesheets")
            then $markup-doc//xhtml:link
            else
                if ($key eq "header")
                then $markup-doc//mnm:markup/*
                else
                    if ($key eq "footer")
                    then $markup-doc//mnm:markup/*
                    else ()
    return
        $markup-to-inject

};

declare function mn:create-markup($key){
    (:
        This function will build the markup for the key type and then invoke a function that will write that markup to the database.
    :)
    let $endpoint := fn:concat($url, $key, "/")
    let $response := json:transform-from-json(
      if (xs:int(fn:substring-before(xdmp:version(),".")) > 7)
      then xdmp:from-json-string(xdmp:http-get($endpoint)[2])
      else xdmp:from-json(xdmp:http-get($endpoint)[2]))
    let $response-result := $response//mljson:flag/string()
    let $processed-markup :=
        if ($response-result eq "SUCCESS")
        then
            if ($key eq "scripts")
            then
                for $item in $response//mljson:scripts/*
                let $path := $item/string()
                return
                    <script xmlns="http://www.w3.org/1999/xhtml" src="{$path}"></script>
            else
                if ($key eq "stylesheets")
                then
                    for $item in $response//mljson:stylesheets/*
                    let $path := $item/string()
                    return
                        <link xmlns="http://www.w3.org/1999/xhtml" href="{$path}" type="text/css" media="all" rel="stylesheet" />
                else
                    if ($key eq "header")
                    then
                        xdmp:tidy($response//*:markup/text())[2]//*:body/*:div
                    else
                        if ($key eq "footer")
                        then
                            <footer id="mlbs4-footer">
                                { xdmp:tidy($response//*:markup/text())[2]//*:body/*:div }
                            </footer>
                        else ()
        else
            mn:get-markup($key)
    let $document :=
            <mega-nav-markup xmlns="http://mlu.marklogic.com/mega-nav/markup">
                <type>{$key}</type>
                <markup>
                    {$processed-markup}
                </markup>
            </mega-nav-markup>
    return
        (xdmp:invoke-function(
            function() { mn:invoke-create-markup-document($document, fn:concat("/mega-nav/", $key, ".xml")), xdmp:commit() },
            <options xmlns="xdmp:eval">
                <transaction-mode>update</transaction-mode>
            </options>)
        ),
        mn:get-markup($key)

};

declare function mn:invoke-create-markup-document($doc, $uri){
    xdmp:log($uri),
    (:
        This function writes the markup to the database.
    :)
    xdmp:document-insert(
        $uri,
        $doc,
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
