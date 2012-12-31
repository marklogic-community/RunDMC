xquery version "1.0-ml";

xdmp:set-response-code(403, "Forbidden"),
xdmp:invoke("error-handler.xqy", (xs:QName("error:errors"),<nothing/>))
