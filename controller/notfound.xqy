xquery version "1.0-ml";

xdmp:set-response-code(404, "Not Found"),
xdmp:invoke("error-handler.xqy", (xs:QName("error:errors"),<nothing/>))
