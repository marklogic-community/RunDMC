<ml:widget xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:ml="http://developer.marklogic.com/site/internal">
  <div class="head">
    <h2>MarkLogic Training Calendar</h2>
  </div>
<div class="body events_listing" id="events_listing"> {
for $ticket at $i 
  in xdmp:tidy(xdmp:http-get("http://mlu.eventbrite.com/") [2]) //xhtml:tr [@class="ticket_row"]
let $title    := fn:string($ticket//xhtml:h3)
let $when     := fn:tokenize( fn:normalize-space(
                fn:string( $ticket//xhtml:span[@class="dtstart"] ) ), "-")
let $start    := $when[1]
let $end      := $when[2]
let $locality := $ticket //xhtml:span [@class="locality"]
let $region   := $ticket //xhtml:span [@class="region"]
let $id       := fn:concat('event_', $i)
return <div id="{$id}" class="event">
         <br/>
         <h3 id="{fn:concat($id, '_title')}"> { $title } </h3>
         <div class="when" id="{fn:concat($id, '_when')}"> 
           <span id="{fn:concat($id, '_start')}" class="start">
           { $start } </span> -
           <span id="{fn:concat($id, '_end')}" class="end">
           { $end } </span> 
         </div>
         <div class="where"> 
           <span id="{fn:concat($id, '_locality')}" class="locality">
           { $locality } </span> -
           <span id="{fn:concat($id, '_region')}" class="region">
           { $region } </span> 
         </div>
       </div>
} </div>
</ml:widget>
