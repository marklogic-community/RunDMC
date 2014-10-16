import module namespace dateparser="http://marklogic.com/dateparser" at "/lib/date-parser.xqy";

dateparser:parse(xdmp:get-request-field("date"))
