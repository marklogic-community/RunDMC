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

module namespace mkto = "mkto";

declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace ns1 = "http://www.marketo.com/mktows/";
declare namespace SOAP-ENV = "http://schemas.xmlsoap.org/soap/envelope/";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace functx = "http://www.functx.com" at
    "/MarkLogic/functx/functx-1.0-nodoc-2007-01.xqy";

import module namespace users = "users" at "/lib/users.xqy";

(: Store /private/marketo-config.xml in the database with actuals for these configs :)
declare variable $mkto:endpoint := (doc("/private/marketo-config.xml")/marketo-config/endpoint/string(), "https://na-n.marketo.com/soap/mktows/1_7")[1];
declare variable $mkto:client-id := (doc("/private/marketo-config.xml")/marketo-config/client-id/string(), "marklogic1_283493864F0B3177859B77")[1];
declare variable $mkto:secret := (doc("/private/marketo-config.xml")/marketo-config/secret/string(), "SECRET")[1];
declare variable $mkto:munchkin-private-key := (doc("/private/marketo-config.xml")/marketo-config/munchkin-private-key/string(), "Secret")[1];

declare function mkto:hash($string as xs:string)
{
    xdmp:sha1(fn:concat($mkto:munchkin-private-key, $string), 'hex')
};

declare function mkto:auth()
{

    let $now := string(fn:current-dateTime())
    let $payload := fn:concat($now, $mkto:client-id)
    let $sig := xdmp:hmac-sha1($mkto:secret, $payload, 'hex')

    return
    <ns1:AuthenticationHeader>
       <mktowsUserId>{$mkto:client-id}</mktowsUserId>
       <requestSignature>{$sig}</requestSignature>
       <requestTimestamp>{$now}</requestTimestamp>
    </ns1:AuthenticationHeader>
};

declare function mkto:first-name($names)
{
    let $c := count($names)

    return
        if ($c le 1) then
            ""
        else if ($c eq 2) then
            $names[1]
        else
            string-join($names[1 to $c - 1], " ")
};

declare function mkto:last-name($names)
{
    $names[last()]
};

declare function mkto:sync-lead($email, $user, $cookie, $source)
{
    let $name := $user/name/string()
    let $names := fn:tokenize($name, " ")
    let $first-name := mkto:first-name($names)
    let $last-name := mkto:last-name($names)
    let $company := $user/organization/string()
    let $industry := $user/industry/string()
    let $country := $user/country/string()
    let $state :=
      if ($country = $users:COUNTRY-REQUIRES-STATE) then
        <attribute>
            <attrName>State</attrName>
            <attrValue>{$user/state/string()}</attrValue>
        </attribute>
      else ()
    let $phone := $user/phone/string()
    let $contact-me := if ($user/contact-me/string () ne "on") then 0 else 1
    let $cook := if ($cookie ne "") then
        <marketoCookie>{$cookie}</marketoCookie>
    else
        ()
    let $optin := $user/opt-in/string() eq "on"
    let $optin-url := $user/opt-in-url/string()
    let $optin-date := fn:current-dateTime()

    (: First check to see if lead exists :)
    let $body :=
      <SOAP-ENV:Envelope>
       <SOAP-ENV:Header>{mkto:auth()}</SOAP-ENV:Header>
       <SOAP-ENV:Body>
        <ns1:paramsGetLead>
            <leadKey><keyType>EMAIL</keyType><keyValue>{$email}</keyValue></leadKey>
        </ns1:paramsGetLead>
      </SOAP-ENV:Body>
     </SOAP-ENV:Envelope>
    let $soap := mkto:soap($body)
    let $leadExists := $soap[2]/SOAP-ENV:Envelope/SOAP-ENV:Body/ns1:successGetLead

    (: if lead exists, leave it's source details alone, otherwise it's from the Community Site :)
    let $leadSourceAttrs := (
        if ($leadExists) then
            ()
        else
            (
            <attribute>
                <attrName>LeadSource</attrName>
                <attrValue>Community Website</attrValue>
            </attribute>
            ,
            <attribute>
                <attrName>Specific_Lead_Source__c</attrName>
                <attrValue>{$source}</attrValue>
            </attribute>
            ,
            <attribute>
                <attrName>Opt_in__c</attrName>
                <attrValue>{$optin}</attrValue>
            </attribute>
            )
        ,
        if ($optin) then
        (: basically do not send these info if option is set to false. :)
            (
            <attribute>
                <attrName>Opt_in_URL__c</attrName>
                <attrValue>{$optin-url}</attrValue>
            </attribute>
            ,
            <attribute>
                <attrName>Opt_in_Date__c</attrName>
                <attrValue>{$optin-date}</attrValue>
            </attribute>
            )
        else ()
            )

    let $body :=
      <SOAP-ENV:Envelope>
       <SOAP-ENV:Header>{mkto:auth()}</SOAP-ENV:Header>
       <SOAP-ENV:Body>
        <ns1:paramsSyncLead>
          <leadRecord>
              <Email>{$email}</Email>
              <leadAttributeList>
                  <attribute>
                      <attrName>FirstName</attrName>
                      <attrValue>{$first-name}</attrValue>
                  </attribute>
                  <attribute>
                      <attrName>LastName</attrName>
                      <attrValue>{$last-name}</attrValue>
                  </attribute>
                  <attribute>
                      <attrName>Email</attrName>
                      <attrValue>{$email}</attrValue>
                  </attribute>
                  <attribute>
                      <attrName>Phone</attrName>
                      <attrValue>{$phone}</attrValue>
                  </attribute>
                  <attribute>
                      <attrName>Country</attrName>
                      <attrValue>{$country}</attrValue>
                  </attribute>
                  { $state }
                  <attribute>
                      <attrName>Company</attrName>
                      <attrValue>{$company}</attrValue>
                  </attribute>
                  <attribute>
                      <attrName>Main_Industry__c</attrName>
                      <attrValue>{$industry}</attrValue>
                  </attribute>
                  <attribute>
                      <attrName>Contact_me__c</attrName>
                      <attrValue>{$contact-me}</attrValue>
                  </attribute>
                  <attribute>
                      <attrName>Role__c</attrName>
                      <attrValue></attrValue>
                  </attribute>
                  {$leadSourceAttrs}
              </leadAttributeList>
          </leadRecord>
          {$cook}
       </ns1:paramsSyncLead>>
      </SOAP-ENV:Body>
     </SOAP-ENV:Envelope>

    let $soap := mkto:soap($body)
    let $resp := $soap[1]
    return
        if ($resp/*:code/string() eq '200') then
            let $ok := $soap[2]/SOAP-ENV:Envelope/SOAP-ENV:Body/ns1:successSyncLead
            return
                if ($ok) then
                    ()
                else
                    mkto:alert(concat("mkto: syncLead failed.
Error:

",
xdmp:quote($soap[2]/SOAP-ENV:Envelope/SOAP-ENV:Body), "

Body:

",
xdmp:quote($body)))
        else
                    mkto:alert(concat("mkto: soap error:
",
xdmp:quote($soap), "

Body:

",
xdmp:quote($body)))
};

declare function mkto:associate-lead($email, $cookie, $meta)
{
    let $name := $meta/name/string()
    let $names := fn:tokenize($name, " ")
    let $first-name := mkto:first-name($names)
    let $last-name := mkto:last-name($names)
    let $company := $meta/organization/string()
    let $cook := if ($cookie ne "") then
        <marketoCookie>{$cookie}</marketoCookie>
    else
        ()

    (: First check to see if lead exists :)
    let $body :=
      <SOAP-ENV:Envelope>
       <SOAP-ENV:Header>{mkto:auth()}</SOAP-ENV:Header>
       <SOAP-ENV:Body>
        <ns1:paramsGetLead>
            <leadKey><keyType>EMAIL</keyType><keyValue>{$email}</keyValue></leadKey>
        </ns1:paramsGetLead>
      </SOAP-ENV:Body>
     </SOAP-ENV:Envelope>
    let $soap := mkto:soap($body)
    let $leadExists := $soap[2]/SOAP-ENV:Envelope/SOAP-ENV:Body/ns1:successGetLead

    let $license := $meta/license[last()]

    let $licenseAttrs :=
    (
        <attribute>
            <attrName>License_Host__c</attrName>
            <attrValue>{$license/hostname/string()}</attrValue>
        </attribute>
        ,
        <attribute>
            <attrName>License_Num_of_CPUs__c</attrName>
            <attrValue>{$license/cpus/string()}</attrValue>
        </attribute>
        ,
        <attribute>
            <attrName>License_Platform__c</attrName>
            <attrValue>{$license/platform/string()}</attrValue>
        </attribute>
        ,
        <attribute>
            <attrName>license_type__c</attrName>
            <attrValue>{functx:capitalize-first($license/type/string())}</attrValue>
        </attribute>
    )

    (: if lead exists, leave it's source details alone, otherwise it's from the Community Site :)
    let $leadSourceAttrs :=
        if ($leadExists) then
            ()
        else
            (
            <attribute>
                <attrName>LeadSource</attrName>
                <attrValue>Community Website</attrValue>
            </attribute>
            ,
            <attribute>
                <attrName>Specific_Lead_Source__c</attrName>
                <attrValue>License Request</attrValue>
            </attribute>
            )

    let $body :=
      <SOAP-ENV:Envelope>
       <SOAP-ENV:Header>{mkto:auth()}</SOAP-ENV:Header>
       <SOAP-ENV:Body>
        <ns1:paramsSyncLead>
          <leadRecord>
              <Email>{$email}</Email>
              <leadAttributeList>
                  <attribute>
                      <attrName>FirstName</attrName>
                      <attrValue>{$first-name}</attrValue>
                  </attribute>
                  <attribute>
                      <attrName>LastName</attrName>
                      <attrValue>{$last-name}</attrValue>
                  </attribute>
                  <attribute>
                      <attrName>Email</attrName>
                      <attrValue>{$email}</attrValue>
                  </attribute>
                  <attribute>
                      <attrName>Company</attrName>
                      <attrValue>{$company}</attrValue>
                  </attribute>
                  {$leadSourceAttrs}
                  {$licenseAttrs}
              </leadAttributeList>
          </leadRecord>
          {$cook}
       </ns1:paramsSyncLead>>
      </SOAP-ENV:Body>
     </SOAP-ENV:Envelope>

    let $soap := mkto:soap($body)
    let $resp := $soap[1]
    return
        if ($resp/*:code/string() eq '200') then
            let $ok := $soap[2]/SOAP-ENV:Envelope/SOAP-ENV:Body/ns1:successSyncLead
            return
                if ($ok) then
                    ()
                else
                    mkto:alert(concat("mkto: syncLead failed.
Error:

",
xdmp:quote($soap[2]/SOAP-ENV:Envelope/SOAP-ENV:Body), "

Body:

",
xdmp:quote($body)))
        else
                    mkto:alert(concat("mkto: soap error:
",
xdmp:quote($soap), "

Body:

",
xdmp:quote($body)))
};

declare function mkto:alert ($e as xs:string) {
    let $_ := xdmp:log($e)
    let $host := xdmp:host-name(xdmp:host())

    return xdmp:email(
    <em:Message xmlns:em="URN:ietf:params:email-xml:" xmlns:rf="URN:ietf:params:rfc822:">
      <rf:subject>Marketo integration failure on {$host}</rf:subject>
      <rf:from>
        <em:Address>
          <em:name>MarkLogic Developer Community</em:name>
          <em:adrs>NOBODY@marklogic.com</em:adrs>
        </em:Address>
      </rf:from>
      <rf:to>
        <em:Address>
          <em:name>DMC Admin</em:name>
          <em:adrs>dmc-admin@marklogic.com</em:adrs>
        </em:Address>
      </rf:to>
      <em:content>{$e}</em:content>
    </em:Message>
   )
};

declare function mkto:soap($body)
{
    xdmp:http-post($mkto:endpoint,
        <options xmlns="xdmp:http">
         <headers>
           <content-type>text/xml</content-type>
         </headers>
            <data>{ xdmp:quote($body) }</data>
        </options>)
};

