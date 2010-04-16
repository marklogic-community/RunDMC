module namespace ml = "http://developer.marklogic.com/site/internal";

import module namespace draft = "http://developer.marklogic.com/site/internal/filter-drafts"
       at "filter-drafts.xqy";

declare default element namespace "http://developer.marklogic.com/site/internal";

declare variable $collection    := fn:collection();

declare variable $Announcements := $collection/Announcement[draft:allow(.)]; (: "News"   :)
declare variable $Events        := $collection/Event       [draft:allow(.)]; (: "Events" :)
declare variable $Articles      := $collection/Article     [draft:allow(.)]; (: "Learn"  :)
declare variable $Posts         := $collection/Post        [draft:allow(.)]; (: "Blog"   :)
declare variable $Projects      := $collection/Project     [draft:allow(.)]; (: "Code"   :)
declare variable $Comments      := $collection/Comment     [draft:allow(.)]; (: blog comments :)

declare variable $live-documents := ( $Announcements
                                    | $Events
                                    | $Articles
                                    | $Posts
                                    | $Projects
                                    );

declare variable $projects-by-name := for $p in $Projects
                                      order by $p/name
                                      return $p;

declare variable $total-blog-count := fn:count($Posts);

declare variable $posts-by-date := for $p in $Posts
                                   order by $p/created descending
                                   return $p;

        declare function blog-posts($start as xs:integer, $count as xs:integer)
        {
            $posts-by-date[fn:position() ge $start
                       and fn:position() lt ($start + $count)]
        };

        declare function comments-for-post($post as xs:string)
        {
          for $c in $Comments[@about eq $post]
          order by $c/created
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


declare variable $events-by-date := for $e in $Events
                                    order by $e/details/date descending
                                    return $e;

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


declare function lookup-articles($type as xs:string, $server-version as xs:string, $topic as xs:string)
{
  let $filtered-articles := $Articles[(($type  eq @type)        or fn:not($type))
                                and   (($server-version =
                                         server-version)        or fn:not($server-version))
                                and   (($topic =  topics/topic) or fn:not($topic))]
  return
    for $a in $filtered-articles
    order by $a/created descending
    return $a
};

        declare function latest-article($type as xs:string)
        {
          ml:lookup-articles($type, '', '')[1]
        };


(: TODO: Figure out how to put this in its own module, e.g., top-threads.xqy,
   without having to use a different target namespace. Can <xdmp:import>
   support multiple modules with the same target NS?
:)
declare function get-threads-xml($search as xs:string?, $lists as xs:string*)
{
  (: This is a workaround for not yet being able to import the XQuery directly. :)
  (: This is a bit nicer anyway, since the other can double as a main module... :)
  xdmp:invoke('top-threads.xqy', (fn:QName('', 'search'), fn:string-join($search,' '),
                                  fn:QName('', 'lists') , fn:string-join($lists ,' ')))
};

declare function xquery-widget($module as xs:string)
{
  let $result := xdmp:invoke(fn:concat('../widgets/',$module))
  return
    $result/node()
};

declare function xslt-widget($module as xs:string)
{
  let $result := xdmp:xslt-invoke(fn:concat('../widgets/',$module), document{()})
  return
    $result/ml:widget/node()
};
