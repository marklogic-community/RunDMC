
let $params := fn:tokenize(xdmp:get-request-url(), "\?")[2]
let $oid := doc("/private/tracker.xml")//*:oid/text()
let $default-params :=
    string-join((
        concat("oid=", $oid), 
        "Campaign_ID=701400000005uRz",
        "lead_source=Web%20Site%20Inquiry",
        "0N30000000dsa3=Inside%20MarkLogic%20Server%20WP",
        "task_subject=DL%20-%2010%204Q%20-%20Inside%20MarkLogic%20Server%20WP",
        "task_status=Not%20started",
        "task_priority=Normal",
        "member_status=DL%20-%20Inside%20MarkLogic%20Server%20WP"
        ), "&amp;")

let $url := 
    concat(
        "http://salesforce.ringlead.com/cgi-bin/77/1/dedup.pl?", $params, "&amp;", $default-params)

let $_ := xdmp:http-get($url)

return "tracked"
