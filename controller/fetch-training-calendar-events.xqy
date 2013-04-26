xquery version "1.0-ml";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace em =    "URN:ietf:params:email-xml:";
declare namespace rf =    "URN:ietf:params:rfc822:";

declare function local:extract-title( $tds ) {
  let $a := $tds //*:a
  return ($a, ($tds except $a))
} ;

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


declare function local:extract-event($tr, $n) {
  let $tds := $tr//xhtml:td
  return if(fn:count($tds) = 4)
         then let $nodes   := local:extract-title( $tds )
              let $title   := $nodes [1]
              let $date    := $nodes [2]
              let $where := $nodes [3]
              return <xhtml:div id="event_{$n}" class="event">
                <xhtml:h4 id="event_{$n}_title" style="margin-bottom: 2px; margin-top: 8px;"> <xhtml:strong>{ $title } </xhtml:strong></xhtml:h4>
                <xhtml:div class="when" id="event_{$n}_when">
                  { let $tokens := fn:tokenize($date, " – ")
                    let $dash := if ($tokens[2]) then " – " else " "
                    return (<xhtml:span id="event_{$n}_start" class="start">
                             { $tokens [1] }
                           </xhtml:span>, $dash,
                           <xhtml:span id="event_{$n}_end" class="end">
                             { $tokens [2] }
                           </xhtml:span>) }
                </xhtml:div>
                <xhtml:div class="where" id="event_{$n}_where">


                { let $tokens := fn:tokenize($where, ", ")
                    return (<xhtml:span id="event_{$n}_locality" class="locality">
                             { $tokens [1] }
                           </xhtml:span>, if ($tokens [2]) then ", " else "",
                           <xhtml:span id="event_{$n}_region" class="region">
                             { $tokens [2] }
                           </xhtml:span>) } </xhtml:div> </xhtml:div>
         else ()
} ;

try {
    let $url := "http://www.marklogic.com/services/training/class-schedule/"

    let $table :=
      ( xdmp:tidy(
          xdmp:http-get(
            $url
          ) [2]
        ) [2]
      ) //xhtml:body//xhtml:table[1]

    let $events := for $tr at $n in $table //xhtml:tr[1 to 7] (: just get some :)
        return local:extract-event($tr, $n - 1)

    return
        if (count($events) gt 1) then 
            xdmp:document-insert("/private/training-events.xml",
                <xhtml:div id="events_listing" class="events_listing">
                  { $events }
                </xhtml:div>
            )
        else
            local:fail(concat("no training events found at ", $url))
}
catch($e) {
  local:fail(("Stack trace: ", $e))
}
