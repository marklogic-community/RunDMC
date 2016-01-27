(xdmp:set-response-code(301, "Moved permanently"),
 xdmp:redirect-response(xdmp:get-request-field("__ml_redirect__")))