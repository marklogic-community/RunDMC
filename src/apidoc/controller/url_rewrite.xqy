xquery version "1.0-ml";
(: URL rewriter.
 : This is a thin wrapper around the rewrite.xqm library.
 :)
import module namespace rw="http://marklogic.com/rundmc/apidoc/rewrite" at "/apidoc/controller/rewrite.xqm";

let $request_port := xdmp:get-request-port()
let $shared_key := fn:replace(xdmp:filesystem-file("/space/ea_shared_key"), "\n", "")
let $ea_login := if($request_port != 80) then "http://marklogicea.staging.wpengine.com/account/login" else "https://ea.marklogic.com/account/login"

let $docs_domain := if($request_port != 80) then "http://docs-ea.marklogic.com:8011" else "http://docs-ea.marklogic.com"

let $_ := if(fn:exists(xdmp:get-request-field("eahash")))
	then xdmp:set-session-field("hash", xdmp:get-request-field("eahash"))
	else ()

let $_ := if(fn:exists(xdmp:get-request-field("user")))
	then xdmp:set-session-field("username", xdmp:get-request-field("user"))
	else ()


return if (fn:compare(xdmp:hmac-sha256($shared_key, xdmp:get-session-field("username")), xdmp:get-session-field("hash")) eq 0 ) then
	if(fn:exists(xdmp:get-request-field("eahash")) or fn:exists(xdmp:get-request-field("user"))) then 
		let $qseq := 
			for $param in xdmp:get-request-field-names()
				return if($param != "eahash" and $param != "user") then fn:concat($param, "=", fn:string(xdmp:get-request-field($param)))
				else ()

		let $query := fn:string-join($qseq, "&amp;")
		let $ruri := fn:concat(xdmp:get-request-path(), if ($query = "") then "" else fn:concat("?", $query) )
		
		return fn:concat("/apidoc/controller/ea-redirect.xqy?__ml_redirect__=", $ruri)
	else rw:rewrite()
else fn:concat("/apidoc/controller/ea-redirect.xqy?__ml_redirect__=", $ea_login, "?redirect_to=", $docs_domain, xdmp:get-request-path())
	

(: url_rewrite.xqy :)
