module namespace ml = "http://developer.marklogic.com/site/internal";

declare default element  namespace "http://developer.marklogic.com/site/internal";

declare variable $collection     := fn:collection();

declare variable $all-blog-posts := $collection/Post;


declare variable $announcements-by-date := for $a in $collection/Announcement
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


declare variable $future-events := $collection/Event[xs:date(details/date) >= fn:current-date()];

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
