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

declare function mkto:associate-lead($email, $meta) 
{
    let $name := $meta/name/string()
    let $names := fn:tokenize($name, " ")
    let $first-name := mkto:first-name($names)
    let $last-name := mkto:last-name($names)
    let $company := $meta/organization/string()

    let $body :=
      <SOAP-ENV:Envelope>
       <SOAP-ENV:Header>{mkto:auth()}</SOAP-ENV:Header>
       <SOAP-ENV:Body>
        <ns1:paramsSyncLead>>
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
                  <attribute>
                      <attrName>LeadSource</attrName>
                      <attrValue>Community Website</attrValue>
                  </attribute>
              </leadAttributeList>
          </leadRecord>
          <marketoCookie>{cookies:get-cookie('_mkto_trk')}</marketoCookie>
       </ns1:paramsSyncLead>>
      </SOAP-ENV:Body>
     </SOAP-ENV:Envelope>

    return 
        xdmp:eval(
            '
            xquery version "1.0-ml";
            declare namespace ns1 = "http://www.marketo.com/mktows/";
            declare namespace SOAP-ENV = "http://schemas.xmlsoap.org/soap/envelope/";
            import module namespace mkto = "mkto" at "/lib/marketo.xqy";
            
            let $soap := mkto:soap($body)
            let $resp := $soap[1]
            return 
                if ($resp/code/string() eq 200) then
                    let $ok := $soap[2]/SOAP-ENV:Envelope/SOAP-ENV:Body/ns1:successSyncLead
                    return 
                        if ($ok) then
                            ()
                        else
                            xdmp:log("mkto: syncLead failed")
            
                else
                    xdmp:log(concat("mkto: syncLead bad status", $resp/code/string()))
            ',
            (),
            <options xmlns="xdmp:eval">
                <isolation>different-transaction</isolation>
                <prevent-deadlocks>true</prevent-deadlocks>
            </options> 
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

