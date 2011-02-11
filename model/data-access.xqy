module namespace ml = "http://developer.marklogic.com/site/internal";

import module namespace draft = "http://developer.marklogic.com/site/internal/filter-drafts"
       at "filter-drafts.xqy";

declare default element namespace "http://developer.marklogic.com/site/internal";

(: We're not currently using collections, so just start with all docs in the database :)
declare variable $collection    := fn:collection();

                                                           (: filter out temporary, preview-only docs, and
                                                              filter "Draft" docs when applicable :)
declare variable $Announcements := $collection/Announcement[draft:listed(.)]; (: "News"   :)
declare variable $Events        := $collection/Event       [draft:listed(.)]; (: "Events" :)
declare variable $Articles      := $collection/Article     [draft:listed(.)]; (: "Learn"  :)
declare variable $Posts         := $collection/Post        [draft:listed(.)]; (: "Blog"   :)
declare variable $Projects      := $collection/Project     [draft:listed(.)]; (: "Code"   :)
declare variable $Comments      := $collection/Comments    [draft:listed(.)]; (: backed-up Disqus conversations :)

                                                    (: Exclude admin pages themselves, so you can't change,
                                                       or break, the Admin UI through the Admin UI :)
declare variable $pages         := $collection/page[fn:not(fn:starts-with(fn:base-uri(.),'/admin/'))]
                                                           [draft:listed(.)]; (: regular pages :)

(: Used to limit what documents are exposed via Search :)
declare variable $live-documents := ( $Announcements
                                    | $Events
                                    | $Articles
                                    | $Posts
                                    | $Projects
                                    );

(: Used to discover Project docs in the Admin UI :)
declare variable $projects-by-name := for $p in $Projects
                                      order by $p/name
                                      return $p;

(: Blog posts :)
declare variable $posts-by-date := for $p in $Posts
                                   order by $p/created descending
                                   return $p;


(: Backed-up Disqus conversations :)
declare function comments-for-page($page as node())
{
  (: Associated with a page by using the same relative URI path but inside /private/comments :)
  $Comments[fn:base-uri(.) eq fn:concat('/private/comments',
                                        fn:base-uri($page))]
};

declare function disqus-identifier($node as node()) {
  comments-for-page($node)/@disqus_identifier/fn:string(.)
};

(: Get a range of documents for paginated parts of the site; used for Blog, News, and Events :)
declare function list-segment-of-docs($start as xs:integer, $count as xs:integer, $type as xs:string)
{
    (: TODO: Consider refactoring so we have generic "by-date" and "list-by-type" functions that can sort out the differences :)
    let $docs := if ($type eq "Announcement") then $announcements-by-date
            else if ($type eq "Event"       ) then $events-by-date
            else if ($type eq "Post"        ) then $posts-by-date
            else ()
    return
      $docs[fn:position() ge $start
        and fn:position() lt ($start + $count)]
};


declare function total-doc-count($type as xs:string)
{
  let $docs := if ($type eq "Announcement") then $Announcements
          else if ($type eq "Event"       ) then $Events
          else if ($type eq "Post"        ) then $Posts
          else ()
  return
    fn:count($docs)
};


declare variable $announcements-by-date := for $a in $Announcements
                                           order by $a/date descending
                                           return $a;

        (: Apparently no longer used (see change in revision 240) :)
        declare function latest-user-group-announcement()
        {
          $announcements-by-date[fn:normalize-space(@user-group)][1]
        };

        declare function latest-announcement()
        {
          $announcements-by-date[1]
        };


declare variable $events-by-date := for $e in $Events
                                    order by $e/details/date descending
                                    return $e;

        declare function events-by-date()
        {
          $events-by-date
        };

        declare function most-recent-event()
        {
          $events-by-date[1]
        };

        declare function most-recent-two-user-group-events($group as xs:string)
        {
          let $events := if ($group eq '')
                         then $events-by-date[fn:normalize-space(@user-group)]
                         else $events-by-date[@user-group eq $group]
          return
            $events[fn:position() le 2]
        };


(: Filtered documents by type and/or topic. Used in the "Learn" section of the site. :)
declare function lookup-articles($type as xs:string, $server-version as xs:string, $topic as xs:string,
    $allow-unversioned as xs:boolean)
{
  let $filtered-articles := $Articles[(($type  eq @type)        or fn:not($type))
                                and   (($server-version =
                                         server-version)        or fn:not($server-version) or 
                                        ($allow-unversioned and fn:empty(server-version)))
                                and   (($topic =  topics/topic) or fn:not($topic))]
  return
    for $a in $filtered-articles
    order by $a/created descending
    return $a
};

        declare function latest-article($type as xs:string)
        {
          ml:lookup-articles($type, '', '', ())[1]
        };


(: Used to implement the <ml:top-threads/> tag :)
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
