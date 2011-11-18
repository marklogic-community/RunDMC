xquery version "1.0-ml";

declare namespace xhtml = "http://www.w3.org/1999/xhtml";
declare namespace em =    "URN:ietf:params:email-xml:";
declare namespace rf =    "URN:ietf:params:rfc822:";

declare function local:fail ($e) {

    let $_ := xdmp:log("#meetup details not fetched")

    let $host := xdmp:host-name(xdmp:host())

    return xdmp:email(
    <em:Message xmlns:em="URN:ietf:params:email-xml:" xmlns:rf="URN:ietf:params:rfc822:">
      <rf:subject>Failed to fetch training meetup details on {$host}</rf:subject>
      <rf:from>
        <em:Address>
          <em:name>RunDMC Alerts</em:name>
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


try {
    let $key := xdmp:get-request-field("key", "")
    let $group_urlname := xdmp:get-request-field("group_urlname", "den-mark-logic")
    let $url := concat("https://api.meetup.com/2/groups.xml?group_urlname=", $group_urlname, "&amp;key=", $key)
    let $group := xdmp:http-get($url)[2]
    let $name := $group/results/items/item/name
    let $url := concat("https://api.meetup.com/2/events.xml?desc=true&amp;page=2&amp;status=past&amp;group_urlname=", $group_urlname, "&amp;key=", $key)
    let $recent-events := xdmp:http-get($url)[2]/results/items/item
    let $url := concat("https://api.meetup.com/2/events.xml?desc=true&amp;page=2&amp;status=upcoming&amp;group_urlname=", $group_urlname, "&amp;key=", $key)
    let $upcoming-events := xdmp:http-get($url)[2]/results/items/item

    let $doc := <meetup>
            { attribute  group_urlname {$group_urlname} } 
            { attribute  name {$name} } 
            <recent-events>
            { 
                for $event in $recent-events
                return 
                    <event>
                        { attribute id {$event/id} } 
                        { attribute url {$event/event_url} } 
                        { attribute name {$event/name} } 
                        { attribute time {$event/time} } 
                        { attribute utc_offset {$event/utc_offset} } 
                        { attribute yes_rsvp_count {$event/yes_rsvp_count} } 
                        { 
                          let $url := concat("https://api.meetup.com/2/rsvps.xml?order=name&amp;rsvp=yes&amp;page=30&amp;event_id=", $event/id, "&amp;key=", $key) 
                          let $rsvps := xdmp:http-get($url)[2]/results/items/item
                          for $rsvp in $rsvps 
                          return
                              <rsvp>
                                {$rsvp/member}
                                {$rsvp/member_photo}
                              </rsvp>
                        }
                    </event>
            }
            </recent-events>

            <upcoming-events> 
            { 
                for $event in $upcoming-events
                return 
                    <event>
                        { attribute id {$event/id} } 
                        { attribute url {$event/event_url} } 
                        { attribute name {$event/name} } 
                        { attribute time {$event/time} } 
                        { attribute utc_offset {$event/utc_offset} } 
                        { attribute yes_rsvp_count {$event/yes_rsvp_count} } 
                        { 
                          let $url := concat("https://api.meetup.com/2/rsvps.xml?order=name&amp;rsvp=yes&amp;page=30&amp;event_id=", $event/id, "&amp;key=", $key)
                          let $rsvps := xdmp:http-get($url)[2]/results/items/item
                          for $rsvp in $rsvps 
                          return
                              <rsvp>
                                {$rsvp/member}
                                {$rsvp/member_photo}
                              </rsvp>
                        }
                    </event>
            }
            </upcoming-events> 

           </meetup>

    let $uri := concat("/private/meetup/", $group_urlname, ".xml")
    return xdmp:document-insert($uri, $doc)
} catch ($e) {
  local:fail(("Stack trace: ", $e))
}
