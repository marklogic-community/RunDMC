xquery version "1.0-ml";

import module namespace json="http://marklogic.com/json" at "/lib/mljson/lib/json.xqy";
import module namespace path="http://marklogic.com/mljson/path-parser" at "/lib/mljson/lib/path-parser.xqy";
import module namespace users="users" at "/lib/users.xqy";
import module namespace util="http://markmail.org/util" at "/lib/util.xqy";
import module namespace cookies = "http://parthcomp.com/cookies" at "../lib/cookies.xqy";
import module namespace mkto="mkto" at "../lib/marketo.xqy";

(: sign up directly :)
let $email := xdmp:get-request-field("s_email")
let $password := xdmp:get-request-field("s_password")
let $confirm-password := xdmp:get-request-field("s_password_confirm")
let $name := xdmp:get-request-field("s_name")
let $signup := xdmp:get-request-field("list", "off")
let $msignup := xdmp:get-request-field("mlist", "off")

let $title := xdmp:get-request-field("s_title")
let $company := xdmp:get-request-field("s_company")
let $industry := xdmp:get-request-field("s_industry")
let $companysize := xdmp:get-request-field("s_companysize") 
let $phone := xdmp:get-request-field("s_phone")
let $city := xdmp:get-request-field("s_city")
let $state := xdmp:get-request-field("s_state")
let $zip := xdmp:get-request-field("s_zip")
let $country := xdmp:get-request-field("s_country")
let $contactme := xdmp:get-request-field("s_contactme", "off")
let $deployment := xdmp:get-request-field("s_deployment")

(: TODO validate deployment and industry picklists :)

(: validate email addy, passwords, etc :)
let $valid := util:validateEmail($email) and 
    (fn:string-length($email) le 255) and
    (fn:string-length($password) le 255) and
    ($password and not($password eq "")) and 
    ($password eq $confirm-password) and 
    ($name and not($name eq "")) and
    (number($companysize) = (1, 250, 1000, 10000, 100000)) and
    (fn:string-length($name) gt 0 and fn:string-length($name) le 255) and
    (fn:string-length($title) gt 0 and fn:string-length($title) le 255) and
    (fn:string-length($company) gt 0 and fn:string-length($company) le 255) and
    (fn:string-length($phone) gt 0 and fn:string-length($phone) le 255) and
    (fn:string-length($city) gt 0 and fn:string-length($city) le 255) and
    (fn:string-length($state) gt 0 and fn:string-length($state) le 255) and
    (fn:string-length($zip) gt 0 and fn:string-length($zip) le 255) and
    (fn:string-length($country) gt 0 and fn:string-length($country) le 255) and
    true()

let $others := (
    <title>{$title}</title>,
    <organization>{$company}</organization>,
    <industry>{$industry}</industry>,
    <org-size>{$companysize}</org-size>,
    <phone>{$phone}</phone>,
    <city>{$city}</city>,
    <state>{$state}</state>,
    <zip>{$zip}</zip>,
    <country>{$country}</country>,
    <list>{$signup}</list>,
    <mktg-list>{$msignup}</mktg-list>,
    <contact-me>{$contactme}</contact-me>,
    <deployment>{$deployment}</deployment>,
    ()
)

(: rely on nice client side error messages; this validation is for protection, so no need to be nice with error text :)
let $user := if ($valid) then users:createOrUpdateUser($name, $email, $password, $others)
    else "invalid form input"

(: user might be an error if it's already registered :)


return if ($user instance of element()) then
    let $_ := mkto:sync-lead($email, $user, cookies:get-cookie('_mkto_trk')[1]) 
    let $_ := xdmp:set-response-content-type("text/html")
    let $_ := users:startSession($user)
    return <html><script type="text/javascript">
           window.location = { fn:concat("'",xdmp:get-request-field('s_page', '/products'),"?d=",xdmp:get-request-field('s_download'),"'") } ;
    </script></html>

else
    let $down := xdmp:get-request-field('s_download')
    let $page := xdmp:get-request-field('s_page')
    return xdmp:redirect-response(concat("/people/signup?e=", $user, "&amp;d=", $down,  "&amp;p=", $page))
