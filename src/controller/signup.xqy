xquery version "1.0-ml";

import module namespace json="http://marklogic.com/json" at "/lib/mljson/lib/json.xqy";
import module namespace path="http://marklogic.com/mljson/path-parser" at "/lib/mljson/lib/path-parser.xqy";
import module namespace users="users" at "/lib/users.xqy";
import module namespace util="http://markmail.org/util" at "/lib/util.xqy";
import module namespace param="http://marklogic.com/rundmc/params" at "modules/params.xqy";
import module namespace functx = "http://www.functx.com" at "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

(: sign up directly :)
let $email := functx:trim(xdmp:get-request-field("s_email"))
let $password := functx:trim(xdmp:get-request-field("s_password"))
let $confirm-password := functx:trim(xdmp:get-request-field("s_password_confirm"))
let $name := functx:trim(xdmp:get-request-field("s_name"))
let $signup := xdmp:get-request-field("list", "off")

let $company := functx:trim(xdmp:get-request-field("s_company"))
let $industry := functx:trim(xdmp:get-request-field("s_industry"))
let $persona := functx:trim(xdmp:get-request-field("s_persona"))
let $phone := functx:trim(xdmp:get-request-field("s_phone"))
let $country := functx:trim(xdmp:get-request-field("s_country"))
let $state := functx:trim(xdmp:get-request-field("s_state"))
let $contactme := xdmp:get-request-field("s_contactme", "off")
let $optin := xdmp:get-request-field("s_opt_in", "off")
let $optin-url := xdmp:get-request-field("s_opt_in_url", "http://developer.marklogic.com/people/signup")

(: TODO validate industry picklists :)

(: validate email addy, passwords, etc :)
let $valid := util:validateEmail($email) and
    (fn:string-length($email) le 255) and
    (fn:string-length($password) le 255) and
    ($password and not($password eq "")) and
    ($password eq $confirm-password) and
    ($name and not($name eq "")) and
    (fn:string-length($name) gt 0 and fn:string-length($name) le 255) and
    (fn:string-length($company) gt 0 and fn:string-length($company) le 255) and
    (fn:string-length($country) gt 0 and fn:string-length($country) le 255) and
    ($country ne $users:COUNTRY-REQUIRES-STATE or fn:string-length($state) gt 0 and fn:string-length($state) le 255) and
    (fn:string-length($industry) gt 0 and fn:string-length($industry) le 255) and
    true()

let $_ :=
    xdmp:log(fn:concat(
        "email: ", $email, " ",
        "name: ", $name, " ",
        "company: ", $company, " ",
        "phone: ", $phone, " ",
        "country: ", $country, " ",
        "state: ", $state, " ",
        "contactme: ", $contactme, " ",
        "industry: ", $industry, " ",
        "opt-in: ", $optin, " ",
        "opt-in-url: ", $optin-url, " ",
        ""
    ))

let $others := (
    <organization>{$company}</organization>,
    <industry>{$industry}</industry>,
    <persona>{$persona}</persona>,
    <phone>{$phone}</phone>,
    <country>{$country}</country>,
    if (fn:string-length($state) > 0) then
      <state>{$state}</state>
    else (),
    <list>{$signup}</list>,
    <contact-me>{$contactme}</contact-me>,
    <opt-in>{$optin}</opt-in>,
    <opt-in-url>{$optin-url}</opt-in-url>,
    ()
)

(: rely on nice client side error messages; this validation is for protection, so no need to be nice with error text :)
let $user := if ($valid) then users:createOrUpdateUser($name, $email, $password, $others)
    else "invalid form input"

(: user might be an error if it's already registered :)


return if ($user instance of element()) then
    let $_ := users:mkto-sync-lead($email, $user, "DMC Signup")
    let $_ := xdmp:set-response-content-type("text/html")
    let $_ := users:startSession($user)
    return <html><script type="text/javascript">
           window.location = { fn:concat("'",xdmp:get-request-field('s_page', '/products'),"?d=",xdmp:get-request-field('s_download'),"'") } ;
    </script></html>

else
    let $down := xdmp:get-request-field('s_download')
    let $page := xdmp:get-request-field('s_page')
    return xdmp:redirect-response(concat("/people/signup?e=", $user, "&amp;d=", $down,  "&amp;p=", $page))
