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
let $msignup := xdmp:get-request-field("mlist", "off")

let $title := functx:trim(xdmp:get-request-field("s_title"))
let $company := functx:trim(xdmp:get-request-field("s_company"))
let $industry := functx:trim(xdmp:get-request-field("s_industry"))
let $companysize := functx:trim(xdmp:get-request-field("s_companysize") )
let $phone := functx:trim(xdmp:get-request-field("s_phone"))
let $street := functx:trim(xdmp:get-request-field("s_street"))
let $city := functx:trim(xdmp:get-request-field("s_city"))
let $state := functx:trim(xdmp:get-request-field("s_state"))
let $zip := functx:trim(xdmp:get-request-field("s_zip"))
let $country := functx:trim(xdmp:get-request-field("s_country"))
let $contactme := xdmp:get-request-field("s_contactme", "off")
let $deployment := functx:trim(xdmp:get-request-field("s_deployment"))

(: TODO validate deployment and industry picklists :)

(: validate email addy, passwords, etc :)
let $valid := util:validateEmail($email) and 
    (fn:string-length($email) le 255) and
    (fn:string-length($password) le 255) and
    ($password and not($password eq "")) and 
    ($password eq $confirm-password) and 
    ($name and not($name eq "")) and
    (fn:string-length($name) gt 0 and fn:string-length($name) le 255) and
    (fn:string-length($title) gt 0 and fn:string-length($title) le 255) and
    (fn:string-length($company) gt 0 and fn:string-length($company) le 255) and
    (fn:string-length($phone) gt 0 and fn:string-length($phone) le 255) and
    (fn:string-length($street) gt 0 and fn:string-length($street) le 255) and
    (fn:string-length($city) gt 0 and fn:string-length($city) le 255) and
    (fn:string-length($state) gt 0 and fn:string-length($state) le 255) and
    (fn:string-length($zip) gt 0 and fn:string-length($zip) le 255) and
    (fn:string-length($country) gt 0 and fn:string-length($country) le 255) and
    (fn:string-length($deployment) gt 0 and fn:string-length($deployment) le 255) and
    (fn:string-length($industry) gt 0 and fn:string-length($industry) le 255) and
    (fn:string-length($companysize) gt 0 and fn:string-length($companysize) le 255) and
    true()

let $_ :=
    xdmp:log(fn:concat(
        "email: ", $email, " ", 
        "name: ", $name, " ", 
        "companysize: ", $companysize, " ", 
        "company: ", $company, " ", 
        "phone: ", $phone, " ", 
        "street: ", $street, " ", 
        "city: ", $city, " ", 
        "state: ", $state, " ", 
        "zip: ", $zip, " ", 
        "country: ", $country, " ", 
        "contactme: ", $contactme, " ", 
        "industry: ", $industry, " ", 
        "deployment: ", $deployment, " ", 
        ""
    ))

let $others := (
    <title>{$title}</title>,
    <organization>{$company}</organization>,
    <industry>{$industry}</industry>,
    <org-size>{$companysize}</org-size>,
    <phone>{$phone}</phone>,
    <street>{$street}</street>,
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
    let $_ := users:mkto-sync-lead($email, $user, "MarkLogic Download")
    let $_ := xdmp:set-response-content-type("text/html")
    let $_ := users:startSession($user)
    return <html><script type="text/javascript">
           window.location = { fn:concat("'",xdmp:get-request-field('s_page', '/products'),"?d=",xdmp:get-request-field('s_download'),"'") } ;
    </script></html>

else
    let $down := xdmp:get-request-field('s_download')
    let $page := xdmp:get-request-field('s_page')
    return xdmp:redirect-response(concat("/people/signup?e=", $user, "&amp;d=", $down,  "&amp;p=", $page))
