xquery version "1.0-ml";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";

declare function local:extract-title( $tds ) {
  let $a := $tds //*:a
  return ($a, ($tds except $a)) } ;

declare function local:extract-event($tr, $n) {
  let $tds := $tr//xhtml:td
  return if(fn:count($tds) = 4) 
         then let $nodes   := local:extract-title( $tds )
              let $title   := $nodes [1]
              let $date    := $nodes [2]
              let $where := $nodes [4]
              return <xhtml:div id="event_{$n}" class="event"> 
                <xhtml:h4 id="event_{$n}_title" style="margin-bottom: 2px; margin-top: 8px;"> <xhtml:strong>{ $title } </xhtml:strong></xhtml:h4> 
                <xhtml:div class="when" id="event_{$n}_when">
                  { let $tokens := fn:tokenize($date, " - ")
                    let $dash := if ($tokens[2]) then " - " else " " 
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
                           </xhtml:span>, ", ", 
                           <xhtml:span id="event_{$n}_region" class="region">
                             { $tokens [2] }
                           </xhtml:span>) } </xhtml:div> </xhtml:div>
         else ()  } ;

try {
let $table := 
  ( xdmp:tidy(
      xdmp:http-get(
        'http://www.marklogic.com/services/training.html'
      ) [2] 
    ) [2] 
  ) //xhtml:body//xhtml:table[1]
return if ($table) then xdmp:document-insert("/private/training-events.xml",
<xhtml:div id="events_listing" class="events_listing"> {
  for $tr at $n in $table //xhtml:tr[1 to 7] (: just get some :)
  return local:extract-event($tr, $n - 1) 
} </xhtml:div>)
else xdmp:log("#training-agenda not fetched") } catch($e) {
  xdmp:log("#training-agenda not fetched"),
  xdmp:log("--- (exception stack trace)"),
  xdmp:log($e) 
}
