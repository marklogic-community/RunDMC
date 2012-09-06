
import module namespace srv = "http://marklogic.com/rundmc/server-urls" at "./server-urls.xqy";
declare namespace h = "xdmp:http";

let $scheme := xdmp:get-request-protocol()
let $method := xdmp:get-request-method()
let $url := concat($scheme, ":", $srv:rapi-server, xdmp:get-request-field("path-and-query"))
let $_ := xdmp:log(concat("rest api executor: original url ", xdmp:get-request-field("path-and-query")))
let $_ := xdmp:log(concat("rest api executor: proxy ", $method, " ", $url))

let $headers := 
    <headers xmlns="xdmp:http">
    {
        for $header in xdmp:get-request-header-names()
        for $value in xdmp:get-request-header($header)
        return <name>{$value}</name>
    }
    </headers>

let $auth := 
    <authentication xmlns="xdmp:http">
        <username></username>
        <password></password>
    </authentication>

let $body := 
    if ($method = ("PUT", "POST")) then (: for now, only these can have proxied request bodies :)
        <data xmlns="xdmp:http">{xdmp:get-request-body()/string()}</data>
    else    
        ()
let $_ := xdmp:log(concat("rest api executor: proxy body ", $body))

let $options := 
    <options xmlns="xdmp:http">
        {$auth}
        {$headers}
        {$body}
    </options>

let $response := 
    if ($method eq 'GET') then
        xdmp:http-get($url, $options)
    else if ($method eq 'PUT') then
        xdmp:http-put($url, $options)
    else if ($method eq 'POST') then
        xdmp:http-post($url, $options)
    else if ($method eq 'DELETE') then
        xdmp:http-delete($url, $options)
    else ()


return
    if (empty($response)) then
        let $_ := xdmp:set-response-code(400, concat("Can't execute method: ", $method)) 
        let $_ := "text/plain"
        return
            concat("No support for method: ", $method)
    else
        let $headers := $response[1]/h:headers
        let $code := xs:integer($response[1]/h:code/string())
        let $message := $response[1]/h:message/string()

        let $_ := xdmp:set-response-code($code, $message)
        let $_ := xdmp:set-response-content-type($headers/h:content-type/string())
        let $_ := 
            for $header in $headers
               return xdmp:add-response-header(local-name($header), $header/string())

        return $response[2]

