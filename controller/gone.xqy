xquery version "1.0-ml";

xdmp:set-response-code(410, "Gone"),
xdmp:invoke("error-handler.xqy", (xs:QName("error:errors"),<nothing/>))
