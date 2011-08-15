module namespace ml = "http://developer.marklogic.com/site/internal";

import module namespace draft = "http://developer.marklogic.com/site/internal/filter-drafts"
       at "filter-drafts.xqy";

declare default element namespace "http://developer.marklogic.com/site/internal";

declare namespace prop="http://marklogic.com/xdmp/property";
declare namespace dir ="http://marklogic.com/xdmp/directory";
declare namespace xdmp="http://marklogic.com/xdmp";


declare variable $Announcements := docs('Announcement');
declare variable $Events        := docs('Event');
declare variable $Articles      := docs('Article');
declare variable $Posts         := docs('Post');
declare variable $Projects      := docs('Project');

(: filter out temporary, preview-only docs, and filter "Draft" docs when applicable :)
declare function docs($element-name) {
  let $non-previews := fn:concat('fn:collection()/',$element-name,'[fn:not(@preview-only)]'),
      $expr := fn:concat('if ($draft:public-docs-only)',
                         'then ',$non-previews,'[@status eq "Published"]',
                         'else ',$non-previews
                        )
  return
    xdmp:value($expr)
};

(: used by get-updated-disqus-threads.xqy :)
declare variable $Comments := fn:collection()/Comments; (: backed-up Disqus conversations :)

                                                    (: Exclude admin pages themselves, so you can't change,
                                                       or break, the Admin UI through the Admin UI :)
declare variable $pages    := fn:collection()/page/self::*[fn:not(fn:starts-with(fn:base-uri(.),'/admin/'))]
                                                          [draft:listed(.)]; (: regular pages :)

(: Used to limit what documents are exposed via Search :)
declare variable $live-documents := ( $Announcements
                                    | $Events
                                    | $Articles
                                    | $Posts
                                    | $Projects
                                    );

(: cts:query for live documents, so we can pass this to search:search() :)
(: TODO: Yes, this duplicates some logic above, so some refactoring is in order. :)
declare variable $live-document-query :=
  cts:and-query((
    (: Assumption: These elements only ever appear at the top level. :)
    cts:or-query((
      cts:element-query(xs:QName("Announcement"),cts:and-query(())),
      cts:element-query(xs:QName("Event")       ,cts:and-query(())),
      cts:element-query(xs:QName("Article")     ,cts:and-query(())),
      cts:element-query(xs:QName("Post")        ,cts:and-query(())),
      cts:element-query(xs:QName("Project")     ,cts:and-query(())),
      cts:element-query(xs:QName("page")        ,cts:and-query(()))
    )),
    (: Exclude preview-only documents :)
    cts:not-query(
      cts:or-query((
        cts:element-attribute-value-query(xs:QName("Announcement"),fn:QName("","preview-only"),"yes"),
        cts:element-attribute-value-query(xs:QName("Event")       ,fn:QName("","preview-only"),"yes"),
        cts:element-attribute-value-query(xs:QName("Article")     ,fn:QName("","preview-only"),"yes"),
        cts:element-attribute-value-query(xs:QName("Post")        ,fn:QName("","preview-only"),"yes"),
        cts:element-attribute-value-query(xs:QName("Project")     ,fn:QName("","preview-only"),"yes"),
        cts:element-attribute-value-query(xs:QName("page")        ,fn:QName("","preview-only"),"yes")
      ))
    ),
    (: Require status="Published" if we're only serving public docs :)
    if ($draft:public-docs-only) then
      cts:or-query((
        cts:element-attribute-value-query(xs:QName("Announcement"),fn:QName("","status"),"Published"),
        cts:element-attribute-value-query(xs:QName("Event")       ,fn:QName("","status"),"Published"),
        cts:element-attribute-value-query(xs:QName("Article")     ,fn:QName("","status"),"Published"),
        cts:element-attribute-value-query(xs:QName("Post")        ,fn:QName("","status"),"Published"),
        cts:element-attribute-value-query(xs:QName("Project")     ,fn:QName("","status"),"Published"),
        cts:element-attribute-value-query(xs:QName("page")        ,fn:QName("","status"),"Published")
      ))
    else ()
  ));


(: Used to discover Project docs in the Admin UI :)
declare variable $projects-by-name := for $p in $Projects
                                      order by $p/name
                                      return $p;

(: Blog posts :)
declare variable $posts-by-date := for $p in $Posts
                                   order by $p/created descending
                                   return $p;


(: Backed-up Disqus conversations :)
declare function comments-for-doc-uri($uri as xs:string)
{
  (: Associated with a page by using the same relative URI path but inside /private/comments :)
  fn:doc(fn:concat('/private/comments',$uri))/Comments
};

declare function disqus-identifier($uri as xs:string) {
  comments-for-doc-uri($uri)/@disqus_identifier/fn:string(.)
};

(: Insert a container for conversations pertaining to the given document (i.e. comments) :)
declare function insert-comment-doc($doc-uri) {
  let $comment-doc-uri := fn:concat('/private/comments', $doc-uri) return

  (: Only insert a comments doc if there isn't one already present :)
  if (fn:not(fn:doc-available($comment-doc-uri)))
  then xdmp:document-insert($comment-doc-uri,
                            document{ <ml:Comments disqus_identifier="disqus-{$doc-uri}"/> })
  else ()
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

        declare function announcements-by-date()
        {
          $announcements-by-date
        };

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


(: Everything below is concerned with caching our navigation XML :)
declare variable $code-dir       := xdmp:modules-root();
declare variable $config-file    := "navigation.xml";
declare variable $config-dir     := fn:concat($code-dir,'config/');
declare variable $raw-navigation := xdmp:document-get(fn:concat($config-dir,$config-file));
declare variable $public-nav-location := "/private/public-navigation.xml";
declare variable $draft-nav-location  := "/private/draft-navigation.xml";
declare variable $pre-generated-location := if ($draft:public-docs-only)
                                            then $public-nav-location
                                            else $draft-nav-location;

(: This function implements a basic caching mechanism for our $navigation info.
   It checks to see if the code has changed since the last time we pre-generated
   the $navigation, whether the draft version or the public-only version. If
   navigation.xml or any of the other code has been updated since the last
   time we generated the fully populated navigation, then we must re-generate
   it afresh. Otherwise, we serve up the pre-generated navigation, thereby
   avoiding this costly operation on most server requests.

   We no longer try to detect database changes but leave it up to the admin UI
   to call invalidate-navigation-cache. To manually invalidate, just delete
   public-navigation.xml and draft-navigation.xml
:) 
declare function get-cached-navigation()
{
let $pre-generated-navigation := fn:doc($pre-generated-location),

    $last-generated := xdmp:document-properties($pre-generated-location)/*/prop:last-modified,

    $last-update :=

      let $config-last-updated := xdmp:filesystem-directory($config-dir)
                                  /dir:entry [dir:filename eq $config-file]
                                  /dir:last-modified,

          (: A happy side effect of using git is that any time we push
             code, the .git directory should show a new last-modified date;
             this should ensure that any and all code updates will invalidate
             the navigation cache :)
          $code-last-updated := xdmp:filesystem-directory($code-dir)
                                /dir:entry
                                /dir:last-modified

          (: Let the admin controller code explicitly invalidate the cache rather than
             checking the document properties all the time, which is expensive. It's also
             insufficient, because this approach doesn't detect new documents, e.g., a new blog post.
          ,$doc-uris := fn:distinct-values($pre-generated-navigation//page/@href/fn:concat(.,'.xml')),

          $docs-last-updated := fn:max(xdmp:document-properties($doc-uris)/*/prop:last-modified)
          :)

      return
         fn:max(($config-last-updated,
                 $code-last-updated
                 (:,
                 $docs-last-updated):)
               ))

return
   if (fn:exists($pre-generated-navigation) and $last-generated gt $last-update)
   then $pre-generated-navigation
   else ()
};

(: When first populating the navigation, cache it in the database :)
declare function save-cached-navigation($doc)
{
  (: Force the insert to occur in a separate transaction to prevent every request
     from being marked as an update :)
  xdmp:invoke("document-insert.xqy", (fn:QName("","uri"),      $pre-generated-location,
                                      fn:QName("","document"), $doc))
};

(: Call this to explicitly invalidate the cached navigation :)
declare function invalidate-cached-navigation()
{
       if (fn:doc-available($public-nav-location))
  then xdmp:document-delete($public-nav-location) else (),
       if (fn:doc-available($draft-nav-location))
  then xdmp:document-delete($draft-nav-location) else ()
};
