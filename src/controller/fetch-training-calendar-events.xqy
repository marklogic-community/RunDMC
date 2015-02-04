xquery version "1.0-ml";

import module namespace json="http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace http = "xdmp:http";
declare namespace jbasic = "http://marklogic.com/xdmp/json/basic";
declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace em =    "URN:ietf:params:email-xml:";
declare namespace rf =    "URN:ietf:params:rfc822:";

declare variable $EVENT-COUNT := 7;

declare variable $MLU-URI := "https://mlu.marklogic.com/registration/";

declare function local:fail ($e) {

  let $_ := xdmp:log("#training-agenda not fetched")

  let $host := xdmp:host-name(xdmp:host())

  return xdmp:email(
    <em:Message xmlns:em="URN:ietf:params:email-xml:" xmlns:rf="URN:ietf:params:rfc822:">
      <rf:subject>Failed to fetch training calendar on {$host}</rf:subject>
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

declare function local:build-event(
  $session as element(jbasic:json),
  $index as xs:int)
{
  <xhtml:div id="event_{$index}" class="event">
    <xhtml:div
      id="event_{$index}_title"
      style="margin-bottom: 2px; margin-top: 8px;">
      {
        element xhtml:a {
          attribute href {
            $MLU-URI || "sessions" || $session/jbasic:uri/fn:string()
          },
          attribute target { "_blank" },
          $session/jbasic:courseType/jbasic:courseName/fn:string()
        }
      }
    </xhtml:div>
    <xhtml:div class="when" id="event_{$index}_when">
      {
        let $start as xs:date? := $session/jbasic:startDate
        let $end as xs:date? := $session/jbasic:endDate
        return (
          <xhtml:span id="event_{$index}_start" class="start">
            {  fn:format-date($start, "[M]/[D]") }
          </xhtml:span>,
          if ($start ne $end) then (
            " – ",
            <xhtml:span id="event_{$index}_end" class="end">
              { fn:format-date($end, "[M]/[D]") }
            </xhtml:span>
          )
          else ()
        )
      }
    </xhtml:div>
    <xhtml:div class="where" id="event_{$index}_where">
      {
        <xhtml:span id="event_{$index}_locality" class="locality">
          { $session/jbasic:location/fn:string() }
        </xhtml:span>
      }
    </xhtml:div>
  </xhtml:div>
};

try {
  let $uri := $MLU-URI || "api/course-sessions?future=true&amp;pageLength="
      || $EVENT-COUNT || "&amp;start=1&amp;status=Open&amp;type=course"
  let $response :=
    xdmp:http-get(
      $uri,
      <options xmlns="xdmp:http">
        <verify-cert>false</verify-cert>
      </options>
    )

  return
    if ($response[1]/http:code/fn:string() = "200") then
      let $sessions := json:transform-from-json($response[2])/jbasic:results/jbasic:json
      return
        if (fn:exists($sessions)) then
          xdmp:document-insert("/private/training-events.xml",
            <xhtml:div id="events_listing" class="events_listing">
              {
                for $session at $index in $sessions
                return
                  local:build-event($session, $index)
              }
            </xhtml:div>
          )
        else
          local:fail("Got no stories from " || $uri)
    else
      local:fail("Failed to reach " || $uri)
}
catch($e) {
  local:fail(("Stack trace: ", $e))
}
