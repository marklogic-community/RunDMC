xquery version "1.0-ml";

(:~
 : Licensed under the Apache License, Version 2.0 (the "License");
 : you may not use this file except in compliance with the License.
 : You may obtain a copy of the License at
 :
 :     http://www.apache.org/licenses/LICENSE-2.0
 :
 : Unless required by applicable law or agreed to in writing, software
 : distributed under the License is distributed on an "AS IS" BASIS,
 : WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 : See the License for the specific language governing permissions and
 : limitations under the License.
 :)

module namespace users = "users";
import module namespace cookies = "http://parthcomp.com/cookies" at "cookies.xqy";
import module namespace srv="http://marklogic.com/rundmc/server-urls" at "/controller/server-urls.xqy";
import module namespace util="http://markmail.org/util" at "/lib/util.xqy";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare namespace em="URN:ietf:params:email-xml:";

declare function users:emailInUse($email as xs:string) as xs:boolean
{
    exists(/person[email eq $email])
};

declare function users:getUserByEmail($email as xs:string) as element(*)?
{
    /person[email eq $email]
};

declare function users:getUserByID($id as xs:string) as element(*)?
{
    /person[id eq $id]
};


declare function users:getUserByFacebookID($id as xs:string) as element(*)?
{
    /person[facebook-id eq $id]
};

declare function users:startSession($user as element(*)) as empty-sequence()
{
    let $sessionID := string(xdmp:random())
    let $name := $user/name
    let $id := $user/id/string()
    let $uri := concat("/private/people/", $id, "/session.xml")
    let $doc := <session>
        <id>{$id}</id>
        <session-id>{$sessionID}</session-id>
    </session>
    let $_ := xdmp:document-insert($uri, $doc) 

    return (
        cookies:add-cookie("RUNDMC-SESSION", $sessionID, current-dateTime() + xs:dayTimeDuration("P60D"), (), "/", false()),
        cookies:add-cookie("RUNDMC-NAME", $name, current-dateTime() + xs:dayTimeDuration("P60D"), (), "/", false())
    )
};

declare function users:endSession() as empty-sequence()
{

    (: todo remove session id from /person ? :) 
    ( 
    cookies:delete-cookie("RUNDMC-SESSION", (), "/"),
    cookies:delete-cookie("RUNDMC-NAME", (), "/")
    )
};

declare function users:getCurrentUserName()
    as xs:string?
{
    let $n := cookies:get-cookie("RUNDMC-NAME")
    return if ($n eq "") then () else $n
};

declare function users:validateFacebookSignedRequest($signed_request as xs:string)
{
    let $secret := $srv:facebook-config/*:secret/string()
    let $tokes := fn:tokenize($signed_request, "\.")
    let $sig := $tokes[1]
    let $payload := $tokes[2]
    let $data := xdmp:base64-decode(fn:replace(fn:replace($payload, '-', '+'), '_', '/')  )
    let $expected-sig := xdmp:hmac-sha256($secret, $payload, 'base64')

    return 
        (: todo deal with extra = at end, why?:)
        (: if ($sig eq $expected-sig) then :)
        if (true()) then 
            $data
        else
            ()

};

declare function users:inUse($email as xs:string, $from-fb as xs:boolean) as xs:boolean 
{
    if (/person[email eq $email]) then
        if ($from-fb) then
             /person[email eq $email and not(facebook-id eq "")]
        else
             /person[email eq $email and not(password eq "")]
    else
        false()
    
};

declare function users:createOrUpdateUser($name, $email, $password, $list)
{
    let $user := /person[email eq $email]
    let $hash := xdmp:crypt($password, $email)

    return
    if ($user) then
        if ($user/password = ("", $hash)) then
            users:updateUserWithPassword($user, $name, $password, $list)
        else
            "Email address in already registered"
    else
        users:createUser($name, $email, $password, (), $list)
};

declare function users:createOrUpdateFacebookUser($name, $email, $password, $facebook-id, $list)
{
    let $user := /person[email eq $email]

    return
    if ($user) then
        if ($user/facebook-id = ("", $facebook-id)) then
            users:updateUserWithFacebookIDAndPassword($user, $facebook-id, $name, $password, $list)
        else
            "Email address associated with this facebook account is registered here via another facebook account"
    else
        users:createUser($name, $email, $password, $facebook-id, $list)
};

declare function users:createUser($name, $email, $pass, $facebook-id, $list)
as element(*)? 
{
    let $id := xdmp:random()
    let $uri := concat("/private/people/", $id, ".xml")
    let $hash := xdmp:crypt($pass, $email)
    let $doc := 
        <person>
            <id>{$id}</id>
            <email>{$email}</email>
            <name>{$name}</name>
            <password>{$hash}</password>
            <facebook-id>{$facebook-id}</facebook-id>
            <picture>https://graph.facebook.com/{$facebook-id}/picture</picture>
            <list>{$list}</list>
            <created>{fn:current-dateTime()}</created>
        </person>

    let $_ := xdmp:document-insert($uri, $doc)
    let $_ := if ($list eq "on") then users:registerForMailingList($email, $pass) else ()
    let $_ := users:logNewUser($doc)

    return $doc
};

declare function users:updateUserWithFacebookID($user, $facebook-id)
as element(*)? 
{
    let $uri := base-uri($user)
    let $doc := <person>
        { for $field in $user/* where not($field/local-name() = ('facebook-id', 'picture')) return $field }
            <facebook-id>{$facebook-id}</facebook-id>
            <picture>https://graph.facebook.com/{$facebook-id}/picture</picture>
        </person>

    let $_ := xdmp:document-insert($uri, $doc)
    return  $doc
};

declare function users:updateUserWithFacebookIDAndPassword($user, $facebook-id, $name, $password, $list)
as element(*)? 
{
    let $uri := base-uri($user)
    let $email := $user/email/string()
    let $hash := xdmp:crypt($password, $email)
    let $doc := <person>
        { for $field in $user/* where not($field/local-name() = ('facebook-id', 'picture', 'name', 'password', 'list')) return $field }
            <facebook-id>{$facebook-id}</facebook-id>
            <name>{$name}</name>
            <picture>https://graph.facebook.com/{$facebook-id}/picture</picture>
            <password>{$hash}</password>
            <list>{$list}</list>
        </person>

    let $_ := xdmp:document-insert($uri, $doc)
    return  $doc
};

declare function users:updateUserWithPassword($user, $name, $password, $list)
as element(*)? 
{
    let $uri := base-uri($user)
    let $email := $user/email/string()
    let $hash := xdmp:crypt($password, $email)
    let $doc := 
        <person>
        { for $field in $user/* where not($field/local-name() = ('name', 'password', 'list')) return $field }
            <name>{$name}</name>
            <password>{$hash}</password>
            <list>{$list}</list>
        </person>

    let $_ := xdmp:document-insert($uri, $doc)
    let $_ := if ($list eq "on") then 
        users:registerForMailingList($email, $password)
    else    
        ()

    return  $doc
};

declare function users:registerForMailingList($email, $pass) 
{
    let $user := /person[email eq $email]
    let $uri := concat("http://developer.marklogic.com/mailman/subscribe/general", "")

    let $payload :=
        concat(
            "email=", xdmp:url-encode($email),
            "&amp;fullname=", xdmp:url-encode($user/name/string()),
            "&amp;pw=", xdmp:url-encode($pass),
            "&amp;pw-conf=", xdmp:url-encode($pass)
        )

    return
        xdmp:http-post($uri, <options xmlns="xdmp:http">
            <headers>
                <content-type>application/x-www-form-urlencoded</content-type>
            </headers>
            <data>{ $payload }</data>
        </options>)
        

};

declare function users:logNewUser($user) 
{
    let $_ := xdmp:log(concat("Created user ", $user/id))

    let $hostname := xdmp:hostname()

    let $staging := if ($hostname = "stage-developer.marklogic.com") then "Staging " else ""

    let $address := 
        if ($hostname = ("developer.marklogic.com", "stage-developer.marklogic.com", "dmc-stage.marklogic.com")) then
            "dmc-admin@marklogic.com"
        else if ($hostname = ("wlan31-12-236.marklogic.com", "dhcp141.marklogic.com")) then
            "eric.bloch@marklogic.com"
        else
            ()

    let $_ := if ($address) then
        util:sendEmail(

            "RunDMC Signup",
            $address,
            false(),
            "RunDMC Admin",
            $address,
            "RunDMC Admin",
            $address,
            concat($staging, "Signed up user ", $user/email/string()), 
            <em:content>
            {concat("
Username: ", $user/name/string(), "
Email: ", $user/email/string(), "
ID: ", $user/id/string())
            }
            </em:content>
        )
    else
        ()

    return ()
};

declare function users:checkCreds($email as xs:string, $password as xs:string) as element(*)?
{
    let $user := /person[email eq $email]
    return
    if ($user/password eq xdmp:crypt($password, $email)) then
        $user
    else
        ()
};

declare function users:signupsEnabled()
    as xs:boolean
{
    true() (: not(empty(cookies:get-cookie("RUNDMC-SIGNUPS"))) :)
};

declare function users:cornifyEnabled()
    as xs:boolean
{
    not(empty(cookies:get-cookie("RUNDMC-CORN")))
};

declare function users:getCurrentUser() as element(*)?
{
    let $session := cookies:get-cookie("RUNDMC-SESSION")
    let $id := /session[session-id eq $session]/id/string() 
    return /person[id eq $id]
};

declare function users:getResetToken($email as xs:string) as xs:string
{
    let $user := /person[email eq $email]
    let $now := fn:string(fn:current-time())
    let $token := xdmp:crypt($email, $now)
    let $doc := 
        <person>
            { for $field in $user/* where not($field/local-name() = ('reset-token')) return $field }
            <reset-token>{$token}</reset-token>
        </person>
    let $_ := xdmp:document-insert(base-uri($user), $doc)

    return $token
};

declare function users:setPassword($user as element(*)?, $password as xs:string)
{
    let $email := $user/email/string()
    let $hash := xdmp:crypt($password, $email)

    let $doc := 
        <person>
            { for $field in $user/* where not($field/local-name() = ('reset-token', 'password')) return $field }
            <password>{$hash}</password>
        </person>

    return xdmp:document-insert(base-uri($user), $doc)
};

(: save params into the user, leaving along fields not specified in the params :)
declare function users:saveProfile($user as element(*), $params as element(*)*) as element(*)
{
    (: todo: cheap secure by only storing first 10? :) 

    (: trim params from input to only the ones we support for now, todo: generate from/share with profile-form in tag-lib :)
    let $fields := ('organization', 'title', 'name', 'url', 'picture', 'location', 'country')
    let $params := for $p in $params where $p/@name = $fields return $p

    let $doc := <person>
        { for $field in $user/* where not($field/local-name() = ($params/@name)) return $field }
        { for $field in $params return element {$field/@name} {$field/string()} }
    </person>

    let $_ := xdmp:document-insert(base-uri($user), $doc)
    let $_ := xdmp:log(concat("Updated profile for ", $user/email, " : ", xdmp:quote($doc)))

    (: update name cookie just in case :)
    let $_ := cookies:add-cookie("RUNDMC-NAME", $doc/name/string(), current-dateTime() + xs:dayTimeDuration("P60D"), (), "/", false())

    return $doc
};
