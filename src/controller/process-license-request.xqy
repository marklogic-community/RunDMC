xquery version "1.0-ml";

import module namespace users="users" at "/lib/users.xqy";
import module namespace util="http://markmail.org/util" at "/lib/util.xqy";
import module namespace param="http://marklogic.com/rundmc/params" at "modules/params.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";
import module namespace json = "http://marklogic.com/json" at "/lib/mljson/lib/json.xqy";

declare option xdmp:output "method=html";

(: mint has a different name for developer license type :)
declare function local:mint-type($t as xs:string) as xs:string
{
    if ($t = "developer") then
        "development"
    else
        $t
};

let $orig-url       := xdmp:get-request-url()
let $query-string   := substring-after($orig-url, '?')
let $valid-url      := xdmp:get-request-field("r")
let $invalid-url    := "/license/default.xqy"

let $params         := for $p in param:trimmed-params()
                       where not($p/@name/string() = ("r", "password", "password_conf"))
                       return concat($p/@name/string(), "=", xdmp:url-encode($p/string()))

let $string-params := string-join($params, "&amp;")

let $currentUser := users:getCurrentUser()

let $version := xdmp:get-request-field("version")
let $v := fn:tokenize($version, "\.")
let $major := $v[1]
let $name := if ($currentUser) then $currentUser/*:name else xdmp:get-request-field("name")
let $email := if ($currentUser) then $currentUser/*:email else xdmp:get-request-field("email")
let $passwd := xdmp:get-request-field("password")
let $conf_passwd := xdmp:get-request-field("password_conf")
let $signup := xdmp:get-request-field("signup") eq "1"
let $type := xdmp:get-request-field("type")
let $agree := xdmp:get-request-field("agree")

let $cpus := xdmp:get-request-field("cpus")
let $platform := xdmp:get-request-field("platform")
let $target := xdmp:get-request-field("target") 
let $hostname := xdmp:get-request-field("hostname")
let $basepath := xdmp:get-request-field("basepath")

(: in staging, add somehting to the hostname so we can identify easily :)
let $host := xdmp:host-name(xdmp:host())
let $hostname := if ($host eq 'stage-developer.marklogic.com' and not(starts-with($hostname, "STAGE-"))) then 
    concat("STAGE-", $hostname)
        else 
    $hostname

let $company := if ($currentUser) then 
        ($currentUser/*:organization/text(), $currentUser/*:license/*:company/text(), "Unknown")[1]
    else 
        xdmp:get-request-field("company")

let $school := xdmp:get-request-field("school")
let $yog := xdmp:get-request-field("yog")

let $passwd := functx:trim($passwd)
let $conf_passwd := functx:trim($conf_passwd)
let $company := functx:trim($company)
let $school := functx:trim($school)
let $name := functx:trim($name)
let $email := functx:trim($email)

let $industry := functx:trim(xdmp:get-request-field("industry"))
let $phone := functx:trim(xdmp:get-request-field("phone"))
let $country := functx:trim(xdmp:get-request-field("country"))
let $contactme := xdmp:get-request-field("contactme", "off")

let $valid-url := fn:concat($valid-url, "?", 
           "version=", xdmp:url-encode($version),            
           "&amp;hostname=", xdmp:url-encode($hostname),
           "&amp;cpus=", xdmp:url-encode($cpus),            
           "&amp;platform=", xdmp:url-encode($platform),
           "&amp;basepath=", xdmp:url-encode($basepath),
           "&amp;target=", xdmp:url-encode($target),
           "&amp;type=", xdmp:url-encode(local:mint-type($type)),
           "&amp;country=", xdmp:url-encode($country),
           "&amp;company=", xdmp:url-encode(if ($type ne "academic") then $company else $school),
           "&amp;email=", xdmp:url-encode($email))

let $invalid-url := fn:concat($invalid-url, "?", $string-params, "&amp;retrying=1")

let $valid-type := if ($type ne 'academic') then
        (
             (fn:string-length($company) le 255) and
        (not($signup) or (
             (string-length($phone) le 255 and string-length($phone) gt 0) and
             (string-length($industry) le 255 and fn:string-length($industry) gt 0)
            )
          )
        )
    else (
        xdmp:get-request-field("yog") and xdmp:get-request-field("school")
        and (fn:string-length($school) le 255)
    )

let $valid := 
    if ($signup) then
        $name and $email and $passwd and ($passwd eq $conf_passwd)
        and fn:string-length($email) le 255 and fn:string-length($email) gt 0
        and fn:string-length($country) le 255 and fn:string-length($country) gt 0
        and fn:string-length($passwd) le 255 and fn:string-length($passwd) gt 0
        and util:validateEmail($email)
        and not(users:emailInUse($email))
        and $valid-type
        and $platform 
        and $hostname 
        and ($agree eq "on" or number($major) lt 7) 
    else
        $platform and
        $hostname and
        ($currentUser or 
            (
                $email and
                $passwd and
                users:checkCreds($email, $passwd)
            )) and
        $valid-type 
        and ($agree eq "on" or number($major) lt 7) 

let $error := if ($signup) then
        if (users:emailInUse($email)) then
            "&amp;inuse=1"
        else if (not(util:validateEmail($email))) then
            "&amp;bademail=1"
        else if (fn:string-length($email) gt 255) then
            "&amp;toolong=email"
        else if (fn:string-length($passwd) gt 255) then
            "&amp;toolong=passwd"
        else if (fn:string-length($company) gt 255) then
            "&amp;toolong=company"
        else if (fn:string-length($phone) gt 255) then
            "&amp;toolong=phone"
        else
            if ($passwd ne $conf_passwd) then
                "&amp;nonmatching=1"
            else
                ""
    else
        if (not($currentUser or users:checkCreds($email, $passwd))) then
            let $_ := xdmp:log(concat("Failed credential check for ", $email))
            return "&amp;badpassword=1"
        else
            ""

let $invalid-url := concat($invalid-url, $error)

let $meta := (
    <cpus>{$cpus}</cpus>,
    <platform>{$platform}</platform>,
    <basepath>{$basepath}</basepath>,
    <hostname>{$hostname}</hostname>
)

let $name := if ($valid) then
    if ($signup) then
        let $list := xdmp:get-request-field("dev-list") 

        let $others := if ($type ne 'academic') then (
            <organization>{$company}</organization>,
            <industry>{$industry}</industry>,
            <phone>{$phone}</phone>,
            <country>{$country}</country>,
            <list>{$list}</list>,
            <contact-me>{$contactme}</contact-me>,
            ()
        ) else (
            <organization>{$school}</organization>,
            <country>{$country}</country>,
            <yog>{$yog}</yog>
        )

        return 
        users:createUserAndRecordLicense($type, $name, $email, $passwd, $list, $others, $meta)/name/string()
    else
        if ($type eq 'academic') then
            users:recordAcademicLicense($email, $school, $yog, $meta)/name/string()
        else
            users:recordLicense($email, $company, $meta, $type)/name/string()
else
    $name

let $hash := doc("/private/license-hash.xml")/hash/string()
let $rnumber := doc("/private/license-hash.xml")/id/string()

let $valid-url := concat($valid-url, 
    "&amp;licensee=", xdmp:url-encode($name),
    "&amp;hash=", xdmp:url-encode($hash),
    "&amp;rnumber=", xdmp:url-encode($rnumber),
"")

(:
let $_ := xdmp:log($valid-url)
:)

(: We use the synchronous version of the ga snippet on purpose since we want it to load before redirecting :)
(: and we redirect to a redirector so that the referrer header is predictable :)
return
    if ($valid) then
    (
    xdmp:set-response-content-type("text/html"), 
    <html>
        <head>
        <script type="text/javascript">
        var gaJsHost = (("https:" == document.location.protocol) ? "https://ssl." : "http://www.");
        document.write(unescape("%3Cscript src='" + gaJsHost + "google-analytics.com/ga.js' type='text/javascript'%3E%3C/script%3E"));
        </script>
<!--
        <script type="text/javascript">
        document.write(unescape("%3Cscript src='" + document.location.protocol +
          "//munchkin.marketo.net/munchkin.js' type='text/javascript'%3E%3C/script%3E"));
        </script>
         <script>Munchkin.init('371-XVQ-609');</script>
-->
         <meta http-equiv="refresh" content="1; url=/license-record?url={xdmp:url-encode($valid-url)}"/>
        </head>
	<body>
        <script type="text/javascript">
        try {{
            var is_prod = document.location.hostname == 'developer.marklogic.com';
            var acct = is_prod ? 'UA-6638631-1' : 'UA-6638631-3' 
            // _gat should be created bu google js include
            var pageTracker = _gat._getTracker(acct);
            pageTracker._setDomainName('marklogic.com');
            pageTracker._trackPageview();

            function moveOn() {{
	            var anchor = document.createElement("a");
                if(!anchor.click) {{ //Providing a logic for Non IE
                    window.location.href = "/license-record?url={xdmp:url-encode($valid-url)}";
                    return;
                }}
                anchor.setAttribute("href", "/license-record?url={xdmp:url-encode($valid-url)}");
                anchor.style.display = "none";
                document.body.appendChild(anchor);
                anchor.click();
            }}

            window.setTimeout(moveOn, 220);

        }} catch(err) {{}}
        </script>
        <noscript>Please <a>{ attribute href { concat("/license-record?url=", xdmp:url-encode($valid-url))}}click here</a> to continue fetching your license.</noscript>
    	</body>
    </html>
    ) 
    else
        xdmp:redirect-response($invalid-url)
