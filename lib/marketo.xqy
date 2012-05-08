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

import module namespace cookies = "http://parthcomp.com/cookies" at "/lib/cookies.xqy";
declare namespace html = "http://www.w3.org/1999/xhtml";
declare namespace ns1 = "http://www.marketo.com/mktows/";
declare namespace SOAP-ENV = "http://schemas.xmlsoap.org/soap/envelope/";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

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

declare function mkto:record-activity($lead, $meta)
{
    let $body :=
      <SOAP-ENV:Envelope>
       <SOAP-ENV:Header>{mkto:auth()}</SOAP-ENV:Header>
       <SOAP-ENV:Body>
<!-- TBD -->
      </SOAP-ENV:Body>
     </SOAP-ENV:Envelope>

    return 
        try {
            mkto:soap($body)
        } catch ($error) {
            (: todo: report failure :)
            ()
        }
};

declare function mkto:lookup-lead-by-cookie($cookie as xs:string)
{
    let $body :=
      <SOAP-ENV:Envelope>
       <SOAP-ENV:Header>{mkto:auth()}</SOAP-ENV:Header>
       <SOAP-ENV:Body>
        <ns1:paramsGetLead>
          <leadKey><keyType>COOKIE</keyType><keyValue>{$cookie}</keyValue></leadKey>
       </ns1:paramsGetLead>
      </SOAP-ENV:Body>
     </SOAP-ENV:Envelope>

    let $resp := mkto:soap($body)/ns1:GetLeadResponse
    return 
        if ($resp/ns1:success) then
            $resp/ns1:result/ns1:leadRecordList[1]
        else 
            () (: todo: report failure :)
};

declare function mkto:lookup-lead-by-email($email as xs:string)
{
    let $body :=
      <SOAP-ENV:Envelope>
       <SOAP-ENV:Header>{mkto:auth()}</SOAP-ENV:Header>
       <SOAP-ENV:Body>
        <ns1:paramsGetLead>
          <leadKey><keyType>EMAIL</keyType><keyValue>{$email}</keyValue></leadKey>
       </ns1:paramsGetLead>
      </SOAP-ENV:Body>
     </SOAP-ENV:Envelope>

    let $resp := mkto:soap($body)/ns1:GetLeadResponse
    return 
        if ($resp/ns1:success) then
            $resp/ns1:result/ns1:leadRecordList 
        else 
            () (: todo: report failure :)
};

declare function mkto:bind-email-to-lead($lead, $email)
{
    let $cookie := cookies:get-cookie('_mkto_trk')

    (: mem copy $lead and replace Email :) 
    let $body :=
      <SOAP-ENV:Envelope>
       <SOAP-ENV:Header>{mkto:auth()}</SOAP-ENV:Header>
       <SOAP-ENV:Body>
        <ns1:paramsSyncLead>>
          <leadRecord>{$lead}</leadRecord>
          <marketoCookie>{$cookie}</marketoCookie>
       </ns1:paramsSyncLead>>
      </SOAP-ENV:Body>
     </SOAP-ENV:Envelope>

    let $resp := mkto:soap($body)/ns1:GetSyncLeadResponse
    return 
        if ($resp/ns1:success) then
            $lead
        else 
            $lead
};

declare function mkto:bound($lead, $email) as xs:boolean
{
    $lead/ns1:email/string() eq $email (: TBD tolower for case-insensitive for domain name? :)
};


declare function mkto:generate-lead($email, $meta)
{
    (: TODO:look up cookie from header using cookie lib :)
    let $cookie := cookies:get-cookie("_mkto")/XXXX

    let $lead :=
        if ($cookie) then
            let $lead := mkto:lookup-lead-by-cookie($cookie)
            return 
                if (mkto:bound($lead, $email)) then
                    $lead
                else
                    mkto:bind-email-to-lead($lead, $email)
        else
            let $lead := mkto:lookup-lead-by-email($email)
            return 
                if ($lead) then
                    () (: TBD mkto:create-lead($email) :)
                else
                    $lead (: TBD: could be multiple leads!! :)

    return mkto:record-activity($lead, $meta)

};

declare function mkto:soap($body) 
{
    (xdmp:http-post($mkto:endpoint,
        <options xmlns="xdmp:http">
         <headers>
           <content-type>text/xml</content-type>
         </headers>
            <data>{ xdmp:quote($body) }</data>
        </options>))[2]
};

