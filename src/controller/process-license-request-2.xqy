xquery version "1.0-ml";

import module namespace users="users" at "/lib/users.xqy";
import module namespace util="http://markmail.org/util" at "/lib/util.xqy";
import module namespace param="http://marklogic.com/rundmc/params" at "modules/params.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace json = "http://marklogic.com/json" at "/lib/mljson/lib/json.xqy";

declare option xdmp:output "method=html";

let $orig-url       := xdmp:get-request-url()
let $query-string   := substring-after($orig-url, '?')
let $valid-url      := xdmp:get-request-field("r")
let $invalid-url    := "/license/default.xqy"

let $params         := for $p in param:trimmed-params()
                       where not($p/@name/string() = ("r", "password", "password_conf"))
                       return concat($p/@name/string(), "=", xdmp:url-encode($p/string()))

let $string-params := string-join($params, "&amp;")

let $version := xdmp:get-request-field("version")
let $name := xdmp:get-request-field("name")
let $email := xdmp:get-request-field("email")
let $passwd := xdmp:get-request-field("password")
let $conf_passwd := xdmp:get-request-field("password_conf")
let $signup := xdmp:get-request-field("signup") eq "1"
let $type := xdmp:get-request-field("type")

let $cpus := xdmp:get-request-field("cpus")
let $platform := xdmp:get-request-field("platform")
let $hostname := xdmp:get-request-field("hostname")
let $target := xdmp:get-request-field("target") 

let $company := xdmp:get-request-field("company")
let $school := xdmp:get-request-field("school")
let $yog := xdmp:get-request-field("yog")

let $passwd := functx:trim($passwd)
let $conf_passwd := functx:trim($conf_passwd)
let $company := functx:trim($company)
let $school := functx:trim($school)
let $name := functx:trim($name)
let $email := functx:trim($email)


let $valid-type := if ($type eq 'express') then
        xdmp:get-request-field("company")
    else
        xdmp:get-request-field("yog") and xdmp:get-request-field("school")

let $valid := 
    if ($signup) then
        $name and $email and $passwd and ($passwd eq $conf_passwd)
        and fn:string-length($email) le 255
        and fn:string-length($passwd) le 255
        and util:validateEmail($email)
        and not(users:emailInUse($email))
        and $valid-type
        and $platform 
        and $hostname 
    else
        $email and
        $passwd and
        $platform and
        $hostname and
        users:checkCreds($email, $passwd) and
        $valid-type 

let $error := if ($signup) then
        if (users:emailInUse($email)) then
            ("INVALID_USER","signup failed: email address is already in use")
        else if (not(util:validateEmail($email))) then
            ("INVALID_EMAIL","signup failed: invalid email address")
        else if (fn:string-length($email) gt 255) then
            ("INVALID_EMAIL","signup failed: email address is too long")
        else if (fn:string-length($passwd) gt 255) then
            ("INVALID_CREDENTIAL","signup failed: password is too long")
        else
            if ($passwd ne $conf_passwd) then
               ("INVALID_CREDENTIAL","signup failed: password mismatch")
            else
                ("OPERATION_FAILED","signup failed: most likely there are missing fields")
    else
        if (not(users:checkCreds($email, $passwd))) then
            let $_ := xdmp:log(concat("Failed credential check for ", $email))
            return ("INVALID_USER_AUTHENTICATION","signin failed: bad password or nonexistent user")
        else
            ("OPERATION_FAILED","signin failed: most likely there are missing fields")


let $meta := (
    <cpus>{$cpus}</cpus>,
    <platform>{$platform}</platform>,
    <hostname>{$hostname}</hostname>
)

let $name := if ($valid) then
    if ($signup) then
        let $list := xdmp:get-request-field("dev-list") 
        let $mktg-list := xdmp:get-request-field("mktg-list") 

        return 
        users:createUserAndRecordLicense($name, $email, $passwd, $list, $mktg-list, $company, $school, $yog, $meta)/name/string()
    else
        if ($type eq 'express') then
            users:recordExpressLicense($email, $company, $meta)/name/string()
        else
            users:recordAcademicLicense($email, $school, $yog, $meta)/name/string()
else
    $name


(: We use the synchronous version of the ga snippet on purpose since we want it to load before redirecting :)
(: and we redirect to a redirector so that the referrer header is predictable :)
return
    if ($valid) then
        <user>
	    <name>{$name}</name>
	</user>
    else
	<error>
	    <reason>{$error[1]}</reason>
	    <message>{$error[2]}</message>
	</error>
