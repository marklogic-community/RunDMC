xquery version "1.0-ml";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace em =    "URN:ietf:params:email-xml:";
declare namespace rf =    "URN:ietf:params:rfc822:";

declare function local:fail ($e) {

    let $_ := xdmp:log("meetup items not fetched")

    let $host := xdmp:host-name(xdmp:host())

    return xdmp:email(
    <em:Message xmlns:em="URN:ietf:params:email-xml:" xmlns:rf="URN:ietf:params:rfc822:">
      <rf:subject>Failed to fetch meetups on {$host}</rf:subject>
      <rf:from>
        <em:Address>
          <em:name>RunDMC Alert</em:name>
          <em:adrs>NOBODY@marklogic.com</em:adrs>
        </em:Address>
      </rf:from>
      <rf:to>
        <em:Address>
          <em:name>DMC Admin</em:name>
          <em:adrs>eric.bloch@marklogic.com</em:adrs>
        </em:Address>
      </rf:to>
      <em:content>{$e}</em:content>
    </em:Message>
   )
};

try {

    let $key := xdmp:get-request-field('meetup-key') 
    let $hostname := xdmp:host-name(xdmp:host())
    let $opts := <options xmlns="xdmp:http">{
        if ($hostname eq 'developer.marklogic.com') then
            <authentication><username>admin</username><password>n00dlesYum!</password></authentication>
        else if ($hostname eq 'stage-developer.marklogic.com') then
            <authentication><username>admin</username><password>adm1n</password></authentication>
        else
            <authentication><username>admin</username><password>unknown</password></authentication>
    }</options>

    let $lhost := 
        if ($hostname eq 'developer.marklogic.com') then
            "developer-admin.marklogic.com"
        else if ($hostname eq 'stage-developer.marklogic.com') then
            "dmc-stage-admin.marklogic.com"
        else
            "localhost:8003"

    return
    <fetch-meetup-status>{
        for $group in ('den-mark-logic', 'NY-MUG', 'muglondon', 'Mark-Logic-User-Group',  'Mark-UPS', 'B-MLUG', 'laxml-meetup', 'MarkLogic-User-Group-Benelux', 'baymug')  
            let $url := concat('http://', $lhost, '/controller/fetch-meetup.xqy?group_urlname=', $group, '&amp;key=', $key)
            let $response := xdmp:http-get($url, $opts)
            return 
                if ($response/*:code/string() != '200') then
                    local:fail((concat("HTTP error for ", $url), $response))
                else
	 	    <group>{ attribute name { $group } }ok</group>
    }</fetch-meetup-status>
                    
}
catch($e) {
  local:fail(("Stack trace: ", $e))
}

