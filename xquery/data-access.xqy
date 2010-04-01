module namespace ml = "http://developer.marklogic.com/site/internal";

declare default element namespace "http://developer.marklogic.com/site/internal";

declare variable $collection    := fn:collection();

declare variable $Announcements := $collection/Announcement; (: "News"   :)
declare variable $Events        := $collection/Event;        (: "Events" :)
declare variable $Articles      := $collection/Article;      (: "Learn"  :)
declare variable $Posts         := $collection/Post;         (: "Blog"   :)
declare variable $Comments      := $collection/Comment;      (: blog comments :)

        declare function comments-for-post($post as xs:string)
        {
          for $c in $Comments[@about eq $post]
                             [@status eq 'Approved'] 
          order by $c/date
          return $c
        };


declare variable $announcements-by-date := for $a in $Announcements
                                           order by $a/date descending
                                           return $a;

        declare function latest-user-group-announcement()
        {
          $announcements-by-date[fn:string(@user-group)][1]
        };

        declare function latest-announcement()
        {
          $announcements-by-date[1]
        };

        declare function recent-announcements($months as xs:integer)
        {
          let $duration := fn:concat('P', $months, 'M'),
              $start-date := fn:current-date() - xs:yearMonthDuration($duration)
          return
            $announcements-by-date[xs:date(date) ge $start-date]
        };


declare variable $future-events := $Events[xs:date(details/date) ge fn:current-date()];

        declare variable $future-events-by-date := for $e in $future-events
                                                   order by $e/details/date
                                                   return $e;

        declare function next-event()
        {
          $future-events-by-date[1]
        };

        declare function next-two-user-group-events($group as xs:string)
        {
          let $events := if ($group eq '')
                         then $future-events-by-date[fn:string(@user-group)]
                         else $future-events-by-date[@user-group eq $group]
          return
            $events[fn:position() le 2]
        };


declare function lookup-articles($type as xs:string, $topic as xs:string)
{
  $Articles[(($type  eq @type)        or fn:not($type)) and
            (($topic =  topics/topic) or fn:not($topic))]
};

        declare function latest-article($type as xs:string)
        {
          let $articles         := ml:lookup-articles($type, ''),
              $articles-by-date := for $a in $articles
                                   order by $a/created descending
                                   return $a
          return
            $articles-by-date[1]
        };


(: TODO: Figure out how to put this in its own module, e.g., top-threads.xqy,
   without having to use a different target namespace. Can <xdmp:import>
   support multiple modules with the same target NS?
:)

(: The first parameter "search" is an arbitrary search string.
   The second parameter "lists" is a list of mailing list names to constrain the search to.

   The function should still return results even if an empty string or sequence is passed in.
   Presumably in that case, the function should return the "top threads" for all ML-related
   mailing lists.
:)
declare function get-threads-xml($search as xs:string?, $lists as xs:string*)
{
    (: TODO: Implement this function, based on the two parameters supplied :)
    (: The results should look something like this; each @href value should be an absolute URL
       which will be used to generate a clickable link :)
    <ml:threads all-threads-href="..." start-thread-href="...">
      <ml:thread title="MarkLogic Server 4.1 Rocks!!" href="..." date-time="2010-03-04T11:22" replies="2" views="14">
        <ml:author href="...">JoelH</ml:author>
        <ml:list href="...">Mark Logic General</ml:list>
      </ml:thread>
      <ml:thread title="Issue with lorem ipsum dolor" href="..." date-time="2009-09-23T13:22" replies="2" views="15">
        <ml:author href="...">Laderlappen</ml:author>
        <ml:list href="...">Mark Logic General</ml:list>
      </ml:thread>
      <ml:thread title="Lorem ipsum dolor sit amet" href="..." date-time="2009-09-24T23:22" replies="1" views="1">
        <ml:author href="...">Jane</ml:author>
        <ml:list href="...">Mark Logic General</ml:list>
      </ml:thread>
      <ml:thread title="Useful tips for NY meets" href="..." date-time="2009-09-26T13:22" replies="12" views="134">
        <ml:author href="...">JoelH</ml:author>
        <ml:list href="...">Mark Logic General</ml:list>
      </ml:thread>
      <ml:thread title="Lorem ipsum dolor sit amet" href="..." date-time="2009-10-03T10:37" replies="0" views="12">
        <ml:author href="...">JoelH</ml:author>
        <ml:list href="...">Mark Logic General</ml:list>
      </ml:thread>
    </ml:threads>
};
