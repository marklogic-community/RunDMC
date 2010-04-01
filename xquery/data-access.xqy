module namespace ml = "http://developer.marklogic.com/site/internal";

declare default element namespace "http://developer.marklogic.com/site/internal";

declare variable $collection     := fn:collection();

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
