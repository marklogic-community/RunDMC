xquery version "1.0-ml";
module namespace ml="http://developer.marklogic.com/site/internal";

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";
import module namespace draft="http://developer.marklogic.com/site/internal/filter-drafts"
  at "filter-drafts.xqy";
import module namespace u="http://marklogic.com/rundmc/util"
  at "/lib/util-2.xqy";
import module namespace users="users" at "/lib/users.xqy";

declare default element namespace "http://developer.marklogic.com/site/internal";

declare namespace prop="http://marklogic.com/xdmp/property";
declare namespace dir ="http://marklogic.com/xdmp/directory";
declare namespace xdmp="http://marklogic.com/xdmp";

(: Some code treats the view HTML as a data model.
 : This is ugly, but needs a lot of fixing
 : and probably benefits performance as it is.
 :)
declare namespace x="http://www.w3.org/1999/xhtml";

declare variable $ADMIN as xs:boolean := false() ;

declare variable $CATEGORY-PREFIX as xs:string := 'category/' ;

declare variable $QUESTIONMARK-SUBSTITUTE := '@' ;

declare variable $MONTHS := (
  'January', 'February', 'March',
  'April', 'May', 'June',
  'July', 'August', 'September',
  'October', 'November', 'December') ;

(: used by get-updated-disqus-threads.xqy :)
declare variable $Comments := collection()/Comments; (: backed-up Disqus conversations :)

declare variable $doc-element-names := (
  xs:QName("Announcement"),
  xs:QName("Event"),
  xs:QName("Article"),
  xs:QName("Tutorial"),
  xs:QName("Project"),
  xs:QName("Post"),
  xs:QName("page"),
  xs:QName("Author"),
  xs:QName("OnDemand"),
  xs:QName("Recipe")
);

declare variable $Announcements := ml:docs( xs:QName("Announcement"));
declare variable $Events        := ml:docs( xs:QName("Event"));
declare variable $Articles      := ml:docs((xs:QName("Article"), xs:QName("Tutorial")));
declare variable $Projects      := ml:docs( xs:QName("Project"));
declare variable $pages         := ml:docs( xs:QName("page"));
declare variable $Authors       := ml:docs( xs:QName("Author"));
declare variable $OnDemand      := ml:docs( xs:QName("OnDemand"));
declare variable $Recipes       := ml:docs( xs:QName("Recipe"));
declare variable $Posts         := ml:docs-in-dir('/blog/');
(: "Posts" now include announcements and events, in addition to vanilla blog posts. :)

(: Get a complete listing of all live documents on DMC (used by retroactive comment script) :)
declare variable $live-dmc-documents := cts:search(collection(), ml:matches-dmc-page());

(: TODO This creates a dependency on apidoc.
 : TODO consider putting server-versions into a namespace.
 :)
declare variable $server-version-nodes := u:get-doc(
  "/apidoc/config/server-versions.xml")/*/*:version;
declare variable $server-versions as xs:string+ := $server-version-nodes/@number;
declare variable $default-version as xs:string  := $server-version-nodes[
  xs:boolean(@default)]/@number ;
(: Limit to available versions.
 : There should always be an index.xml if a version is loaded.
 :)
declare variable $server-versions-available as xs:string+ := cts:uris(
  (), (),
  cts:document-query(
    $server-versions ! concat('/apidoc/', ., '/index.xml')))
! replace(., '/apidoc/(\d+\.\d+)/index.xml', '$1') ;
declare variable $server-version-nodes-available as element()+ := (
  $server-version-nodes[@number = $server-versions-available]) ;

(: Used to discover Project docs in the Admin UI :)
declare variable $projects-by-name := for $p in $Projects
order by $p/name
return $p;

declare variable $authors-by-name :=
  for $author in $Authors
  order by $author/name
  return $author;

(: MLU OnDemand content :)
declare variable $ondemand :=
  for $ondemand in $OnDemand
  order by $ondemand/ml:last-updated
  return $ondemand;

declare variable $media-uris :=
  cts:uri-match("/media/*") ! <uri>{.}</uri>;

(: Blog posts :)
declare variable $posts-by-date := for $p in $Posts
order by $p/created descending
return $p;

declare variable $announcements-by-date := for $a in $Announcements
order by $a/date descending
return $a;

declare variable $events-by-date := for $e in $Events
order by $e/details/date descending
return $e;

(: Everything below is concerned with caching our navigation XML :)
declare variable $code-dir       := xdmp:modules-root();
declare variable $config-file    := "navigation.xml";
declare variable $config-dir     := concat($code-dir,'config/');
declare variable $raw-navigation := u:get-doc(concat($config-dir,$config-file)) ;
declare variable $public-nav-location := "/private/public-navigation.xml";
declare variable $draft-nav-location  := "/private/draft-navigation.xml";
declare variable $pre-generated-location := if ($draft:public-docs-only)
then $public-nav-location
else $draft-nav-location;

(: Content from www.marklogic.com is in this collection :)
declare variable $WWW-COLLECTION := "www.marklogic.com";

declare variable $EXTERNAL-CONTENT-COLLECTIONS := (
  $WWW-COLLECTION,
  $ml:CATEGORY-PREFIX || "mlu"
);

(: Content that will be searched FROM www.marklogic.com will be in these collections :)
declare variable $WWW-TYPE-MAPPINGS :=
  <type-mappings>
    <type label="Business Blogs">{$WWW-COLLECTION}/post</type>
    <type label="Technical Blogs">category/blog</type>
    <type label="MarkLogic Overview">{$WWW-COLLECTION}/page</type>
    <type label="Customers">{$WWW-COLLECTION}/ml_customer</type>
    <type label="Resources">{$WWW-COLLECTION}/ml_resource</type>
    <type label="Press Releases">{$WWW-COLLECTION}/ml_press_release</type>
    <type label="News">{$WWW-COLLECTION}/ml_news</type>
    <type label="Solutions">{$WWW-COLLECTION}/ml_solution</type>
    <type label="Training Courses">{$WWW-COLLECTION}/ml_training_course</type>
    <type label="Webinars">{$WWW-COLLECTION}/ml_webinars</type>
    <type label="Events">{$WWW-COLLECTION}/pmg_event</type>
    <type label="Tutorials">category/tutorial</type>
    <type label="Projects">category/code</type>
    <type label="On Demand">category/mlu</type>
  </type-mappings>;

declare variable $USER-ROLE := "RunDMC-role";
declare variable $AUTHOR-ROLE := "RunDMC-author";
declare variable $ADMIN-ROLE := "RunDMC-admin";

(: Get a listing of all live, listed DMC documents for the given page type(s) :)
declare private function ml:docs($qnames) as element()* {
  cts:search(collection(),
    cts:or-query((
        for $qname in $qnames return ml:matches-dmc-page($qname)
        ))
    )/*
};

declare private function ml:docs-in-dir($directory) as element()* {
  cts:search(fn:collection(),
    cts:and-query((
      cts:directory-query($directory, "infinity"),
      if ($draft:public-docs-only) then
        cts:element-attribute-value-query(xs:QName("ml:Post"), fn:QName("", "status"), "Published")
      else ()
    ))
  )/*
};

declare function ml:month-name($month as xs:integer)
  as xs:string
{
  $MONTHS[$month]
};

declare function ml:display-date($date-or-dateTime as xs:string?)
  as xs:string
{
  let $date-part := substring($date-or-dateTime, 1, 10)
  let $castable := $date-part castable as xs:date
  return (
    if (not($castable)) then $date-or-dateTime
    else (
      let $dateTime := xs:dateTime(concat($date-part,'T00:00:00'))
      let $month := month-from-dateTime($dateTime)
      let $day := day-from-dateTime($dateTime)
      let $year := year-from-dateTime($dateTime)
      return concat(ml:month-name($month),' ',$day,', ',$year)))
};

declare function ml:display-time($dateTime as xs:string?)
as xs:string
{
  if (not($dateTime castable as xs:dateTime)) then $dateTime
  else format-dateTime(xs:dateTime($dateTime), '[h]:[m][P]')
};

declare function ml:display-date-with-time($dateTimeGiven as xs:string?)
as xs:string?
{
  if (not($dateTimeGiven castable as xs:dateTime)) then $dateTimeGiven
  else concat(
    ml:display-date($dateTimeGiven), '&#160;',
    ml:display-time($dateTimeGiven))
};

declare function ml:categories-for-doc(
  $cat as xs:string,
  $doc as element())
as xs:string+
{
  $cat,
  string-join(
    ($cat,
      (: Force an error if the result is inappropriate :)
      (switch($cat)
        case 'function' return ($doc/@mode, $api:MODE-XPATH)[1]
        (: checking pdf-only atribute to determine category as guide-uri ends with .pdf for pdf-only guide:)
        case 'guide' return (if($doc/@pdf-only eq true()) then replace(
          $doc/@guide-uri treat as node(),
          '^.+/(\w[\w\-]*\w)\.pdf$', '$1') else 
        replace(
          $doc/@guide-uri treat as node(),
          '^.+/(\w[\w\-]*\w)\.xml$', '$1'))
        default return error((), 'ML-UNEXPECTED', ($cat, xdmp:describe($doc))))
      (: Assert that the category name is sane. :)
      ! (if (matches(., '^\w[\w\-]*\w$')) then .
        else error((), 'ML-BADCATEGORY', xdmp:describe(.)))),
    '/')
};

declare function ml:category-for-doc(
  $doc-uri as xs:string,
  $new-doc as document-node()?)
as xs:string+
{
  (: Only look inside the doc if necessary :)
  if (contains($doc-uri, "/dotnet/xcc/"))     then "xccn"
  else if (contains($doc-uri, "/javadoc/xcc/"))    then "xcc"
  else if (contains($doc-uri, "/javadoc/client/")) then "java-api"
  else if (contains($doc-uri, "/jsdoc/"))          then "nodejs-api"
  else if (contains($doc-uri, "/javadoc/hadoop/")) then "hadoop"
  else if (contains($doc-uri, "/cpp/"))            then "cpp"
  else if (starts-with($doc-uri, "/ondemand/"))    then "mlu"
  else if (starts-with($doc-uri, "/recipe/"))     then "recipe"
  else (
    let $doc as node() := if ($new-doc) then $new-doc else doc($doc-uri)
    return (
      if ($doc/api:function-page/api:function[1]/@lib
        eq 'REST') then "rest-api"
      else if ($doc/api:function-page) then ml:categories-for-doc(
        'function', $doc/*)
      else if ($doc/(*:guide|*:chapter)) then ml:categories-for-doc(
        'guide', $doc/*)
      else if ($doc/api:help-page      ) then "help"
      else if ($doc/ml:Announcement    ) then "news"
      else if ($doc/ml:Event           ) then "event"
      else if ($doc/ml:Tutorial or
        $doc/ml:page/tutorial or
        $doc/ml:Article
        (: these are not really tutorials :)
        [not(matches(base-uri($doc),'( /learn/[0-9].[0-9]/
              | /learn/tutorials/gh/
              | /learn/dzone/
              | /learn/readme/
              | /learn/w3c-
              | /docs/
              )','x'))]) then "tutorial"
      else if ($doc/ml:Post            ) then "blog"
      else if ($doc/ml:Project         ) then "code"
      else "other"))
};

declare function ml:category-for-doc(
  $doc-uri as xs:string)
as xs:string+
{
  ml:category-for-doc($doc-uri, ())
};

(: Wrapper for xdmp:document-insert
 : that ensures correct permissions
 : and category collections.
 :)
declare function ml:document-insert(
  $uri as xs:string,
  $new as node(),
  $is-hidden as xs:boolean)
as empty-sequence()
{
  xdmp:document-insert(
    $uri,
    $new,
    (: If document exists, reset it to default permissions. :)
    xdmp:default-permissions(),
    (: Set collections, preserving existing non-category collections.
     : Optionally exclude the document from the search corpus.
     :)
    (ml:category-for-doc(
        $uri,
        if ($new instance of document-node()) then $new
        else document { $new })
      ! concat($CATEGORY-PREFIX, .),
      xdmp:document-get-collections($uri)[
        not(starts-with(., $CATEGORY-PREFIX))][
        . ne 'hide-from-search'],
      if (not($is-hidden)) then () else "hide-from-search"))
};

declare function ml:document-insert(
  $uri as xs:string,
  $new as node())
as empty-sequence()
{
  ml:document-insert($uri, $new, false())
};

(: Used by URL rewriter to control access to DMC pages :)
declare function ml:doc-matches-dmc-page-or-preview($doc as document-node())
  as xs:boolean
{
  (: TODO Rewrite the query generation for this. It is terrible. :)
  cts:contains($doc, ml:matches-any-dmc-page(true()))
};

(: Used to find all live DMC documents, for search results :)
declare private function ml:matches-dmc-page() {
  ml:matches-any-dmc-page(false())
};

(: Used to list all the DMC pages for a specific page type :)
declare private function ml:matches-dmc-page($qname) {
  ml:matches-dmc-page($qname, false())
};


declare private function ml:matches-any-dmc-page($allow-previews-on-draft as xs:boolean) {
  cts:or-query((
      (: Require the document to match one of the known DMC page types :)
      for $qname in $doc-element-names return ml:matches-dmc-page($qname, $allow-previews-on-draft)
      ))
};


(: Preview-only docs are allowed by the URL controller but never allowed in the search results page :)
declare private function ml:matches-dmc-page($qname, $allow-previews-on-draft as xs:boolean) {

  let $hide-previews := $draft:public-docs-only or not($allow-previews-on-draft) return

  cts:and-query((

      (: Require the given element to be present :)
      cts:element-query($qname,cts:and-query(())),

      (: Additionally attempt to constrain the element to exist at the top level :)
      ml:query-for-doc-element($qname),

      (: Exclude admin-specific <ml:page> docs :)
      cts:not-query(
        cts:directory-query("/admin/","infinity")
      ),

      (: Exclude documents in the /private directory :)
      cts:not-query(
        cts:directory-query("/private/","infinity")
      ),

      (: If we're only serving public docs... :)
      if ($draft:public-docs-only) then
      (: ...then hide "Draft" docs by requiring status="Published" :)
      cts:element-attribute-value-query($qname,QName("","status"),"Published")
      else (),

      (: If we're hiding previews... :)
      if ($hide-previews) then
      (: ...then disallow preview-only="yes" :)
      cts:not-query(
        cts:element-attribute-value-query($qname,QName("","preview-only"),"yes")
      )
      else ()
      ))
};

(: TODO Really? :)
declare private function ml:query-for-doc-element($qname) as cts:query? {
  let $plan := xdmp:value(concat("xdmp:plan(collection()/",$qname,")")),
  $term-query := $plan//*:term-query
  (: only do it if there's one term query returned; otherwise we can't be confident :)
  where count($term-query) eq 1
  return cts:term-query(xs:integer(string($term-query/*:key)))
};


(: Used as the additional query passed to search:search() :)
declare function ml:search-corpus-query(
  $versions as xs:string+,
  $is-api as xs:boolean)
as cts:query
{
  cts:and-query(
    (cts:or-query(
        (
          if ($is-api) then ml:matches-api-page($versions)
          else ml:live-document-query($versions),
          cts:directory-query(
            (if ($is-api) then () else '/pubs/code/',
              (: See apidoc/setup/load-static-docs.xqy :)
              for $v in $versions
              for $location in ('/cpp/', '/dotnet/', '/javadoc/', '/jsdoc/')
              return concat('/apidoc/', $v, $location)),
            'infinity'))),
      cts:not-query(
        cts:or-query(
          (cts:collection-query("hide-from-search"),
            cts:element-attribute-value-query(
              $doc-element-names,
              QName("", "hide-from-search"), "yes"))))))
};

declare function ml:search-corpus-query(
  $versions as xs:string+)
as cts:query
{
  ml:search-corpus-query($versions, false())
};

(: Match only the supplied server version(s). :)
declare private function ml:matches-api-page($versions as xs:string+)
{
  cts:and-query(
    (cts:directory-query(
        $versions ! concat("/apidoc/", ., "/"),
        "infinity"),
      (: Consider re-visiting this;
       : can we avoid having to enumerate the element names here?
       :)
      cts:element-query(
        (xs:QName("api:function-page"),
          xs:QName("api:help-page"),
          QName("","guide"),
          QName("","chapter")),
        cts:and-query(()))))
};

declare private function ml:matches-www-page()
{
  cts:collection-query($WWW-COLLECTION)
};

(: Query for all live DMC, docs, and www documents :)
declare private function ml:live-document-query(
  $versions as xs:string+)
{
  cts:or-query((
    (: Pages on developer.marklogic.com :)
    ml:matches-dmc-page(),
    (: Pages on docs.marklogic.com, specific to the given docs version :)
    ml:matches-api-page($versions),
    (: Pages on www.marklogic.com :)
    ml:matches-www-page()
  ))
};

declare function ml:get-matching-functions(
  $name as xs:string,
  $version as xs:string)
as document-node()*
{
  (: The input may be empty or all whitespace,
   : or may be impossible as a function name.
   : XQuery function names are always castable as xs:QName,
   : but that is not true for REST endpoints.
   : Whitespace is a pretty good test for both.
   : REST fullnames can look like '/v1/qbe (GET)',
   : but I don't think anyone would expect that to work
   : as a matching-function search anyway.
   :)
  let $name := normalize-space($name)[.][not(contains(., ' '))]
  let $query := $name ! cts:and-query(
    (cts:directory-query(concat("/apidoc/",$version,"/")),
      (: Matches either the local name, or the name with prefix? :)
      cts:element-attribute-value-query(
        xs:QName("api:function"),
        (QName('', "name"), QName('', 'fullname')),
        $name, "exact")))
  let $results := $query ! cts:search(collection(), $query, 'unfiltered')
  let $preferred := ("fn","xdmp")
  for $f in $results
  for $lib in $f/*/api:function[1]/(@lib|@object)/string()
  let $index := index-of($preferred, $lib)
  for $name in $f/*/api:function[1]/@name/string()[.]
  order by $index, $lib, $name
  return $f
};

declare function ml:get-matching-messages(
  $name as xs:string,
  $version as xs:string)
as document-node()*
{
  (: A valid message will always match this pattern. :)
  let $name := upper-case(normalize-space($name))[.][
    matches(., '^[A-Z]+-[A-Z]+$')]
  let $query := $name ! cts:and-query(
    (cts:directory-query('/apidoc/'||$version||'/messages/', 'infinity'),
      cts:element-attribute-value-query(
        QName('', "message"), QName('', "id"), $name)))
  return $query ! cts:search(collection(), $query, 'unfiltered')
};

(: Look for a message guide section with the requested version and id.
 : This does no checking of the version or id.
 :)
declare function ml:get-matching-message(
  $id as xs:string,
  $version as xs:string)
as element(x:div)?
{
  xdmp:directory(
    '/apidoc/'||$version||'/guide/messages/',
    'infinity')
  /chapter/x:div/x:div[x:a/@id = $id]
};

declare function ml:topic-docs($tag as xs:string) as document-node()* {
  collection()[.//topic-tag = $tag]

  (: filter out non-live docs :)
  [cts:contains(., ml:search-corpus-query($default-version))]
};

(: For determining category facets.
 : This repeats work done by ml:document-insert,
 : but because of this it usually runs very quickly.
 : If it logs any URIs, try to change them to use ml:document-insert.
 :)
declare function ml:reset-category-tags(
  $doc-uri as xs:string,
  $new-doc as document-node()?)
as empty-sequence()
{
  let $category-tag := ml:category-for-doc(
    $doc-uri, $new-doc) ! concat($CATEGORY-PREFIX, .)
  (: Leave any non-category collections alone. :)
  let $categories-old := xdmp:document-get-collections($doc-uri)[
    starts-with(., $CATEGORY-PREFIX)]
  let $categories-to-remove := $categories-old[not(. = $category-tag)]
  (: If there are no categories to remove, the function will not map. :)
  let $_ := xdmp:document-remove-collections(
    $doc-uri, $categories-to-remove)
  let $update-needed := not($categories-old[. eq $category-tag])
  let $_ := if (not($update-needed)) then () else xdmp:log(
    text {
      "[ml:reset-category-tags] adding", xdmp:describe($category-tag),
      'to', $doc-uri },
    'info')
  where $update-needed
  return xdmp:document-add-collections($doc-uri, $category-tag)
};

declare function ml:reset-category-tags(
  $doc-uri as xs:string)
as empty-sequence()
{
  ml:reset-category-tags($doc-uri, ())
};

declare function ml:latest-posts($how-many) { $posts-by-date[position() le $how-many] };

(: Backed-up Disqus conversations :)
declare function ml:comments-for-doc-uri($uri as xs:string)
{
  (: Associated with a page by using the same relative URI path but inside /private/comments :)
  doc(ml:comment-doc-uri($uri))/Comments
};

declare private function ml:comment-doc-uri($doc-uri as xs:string) {
  concat("/private/comments", $doc-uri)
};

declare function ml:disqus-identifier($uri as xs:string) {
  let $existing-comments-doc := ml:comments-for-doc-uri($uri)
  return
  (: Use the existing @disqus_indentifier if present (in case the doc URI has since changed).:)
  if ($existing-comments-doc) then $existing-comments-doc/@disqus_identifier/string(.)

  (: Otherwise, just use the given URI, prefixed with "disqus-" :)
  else concat("disqus-",$uri)
};

declare function ml:default-comments-uri-from-disqus-identifier($id as xs:string?) {
  if (starts-with($id,'disqus-')) then ml:comment-doc-uri(
    substring-after($id,'disqus-'))
  else ()
};

(: Insert a container for conversations pertaining to the given document (i.e. comments) :)
declare function ml:insert-comment-doc($doc-uri) {
  let $comment-doc-uri := ml:comment-doc-uri($doc-uri)
  (: Only insert a comments doc if there isn't one already present :)
  where not(doc-available($comment-doc-uri))
  return ml:document-insert(
    $comment-doc-uri,
    <ml:Comments disqus_identifier="{ml:disqus-identifier($doc-uri)}"/>)
};


(: Get a range of documents for paginated parts of the site; used for Blog, News, and Events :)
declare function ml:list-segment-of-docs($start as xs:integer, $count as xs:integer, $type as xs:string)
{
  (: TODO: Consider refactoring so we have generic "by-date" and "list-by-type" functions that can sort out the differences :)
  let $docs := if ($type eq "Announcement") then $announcements-by-date
  else if ($type eq "Event"       ) then $events-by-date
  else if ($type eq "Post"        ) then $posts-by-date
  else ()
  return
  $docs[position() ge $start
    and position() lt ($start + $count)]
};


declare function ml:total-doc-count($type as xs:string)
{
  let $docs := if ($type eq "Announcement") then $Announcements
  else if ($type eq "Event"       ) then $Events
  else if ($type eq "Post"        ) then $Posts
  else ()
  return
  count($docs)
};


declare function ml:announcements-by-date()
{
  $announcements-by-date
};

(: Apparently no longer used (see change in revision 240) :)
declare function ml:latest-user-group-announcement()
{
  $announcements-by-date[normalize-space(@user-group)][1]
};

declare function ml:latest-announcement()
{
  $announcements-by-date[1]
};


declare function ml:events-by-date()
{
  $events-by-date
};

declare function ml:most-recent-event()
{
  $events-by-date[1]
};

declare function ml:most-recent-two-user-group-events($group as xs:string)
{
  let $events := if ($group eq '')
  then $events-by-date[normalize-space(@user-group)]
  else $events-by-date[@user-group eq $group]
  return
  $events[position() le 2]
};


(: Filtered documents by type and/or topic. Used in the "Learn" section of the site. :)
declare function ml:lookup-articles($type as xs:string, $server-version as xs:string, $topic as xs:string,
  $allow-unversioned as xs:boolean)
{
  let $filtered-articles := $Articles[(($type  eq @type)        or not($type))
    and   (($server-version =
        server-version)        or not($server-version) or
      ($allow-unversioned and empty(server-version)))
    and   (($topic =  topics/topic) or not($topic))]
  return
  for $a in $filtered-articles
  order by $a/created descending
  return $a
};

declare function ml:latest-article($type as xs:string)
{
  ml:lookup-articles($type, '', '', ())[1]
};


(: Used to implement the <ml:top-threads/> tag :)
declare function ml:get-threads-xml($search as xs:string?, $lists as xs:string*)
{
  try {
    (: This is a workaround for not yet being able to import the XQuery directly. :)
    (: This is a bit nicer anyway, since the other can double as a main module... :)
    xdmp:invoke('top-threads.xqy', (QName('', 'search'), string-join($search,' '),
        QName('', 'lists') , string-join($lists ,' ')))
    } catch ($e) {
    (: Don't break the page if top threads doesn't work (e.g., because markmail.org is down) :)
    xdmp:log(concat("ERROR in calling top-threads.xqy: ", xdmp:quote($e)))
  }
};

declare function ml:xquery-widget($module as xs:string)
{
  let $result := xdmp:invoke(concat('../widgets/',$module))
  return
  $result/node()
};

declare function ml:xslt-widget($module as xs:string)
{
  let $result := xdmp:xslt-invoke(concat('../widgets/',$module), document{()})
  return
  $result/ml:widget/node()
};


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
declare function ml:get-cached-navigation()
  as document-node()?
{
  let $pre-generated-navigation := doc($pre-generated-location)
  let $last-generated := xdmp:document-properties(
    $pre-generated-location)/*/prop:last-modified
  let $last-update := max(
    if (xdmp:modules-database() gt 0) then xdmp:invoke-function(
      function() {
        cts:max(
          cts:element-reference(
            xs:QName('prop:last-modified'), 'type=dateTime')) },
      $u:OPTS-MODULES-DB)
    else (
      (: A happy side effect of using git is that any time we push
       : code, the .git directory should show a new last-modified date.
       : This should ensure that any and all code updates will invalidate
       : the navigation cache.
       :)
      xdmp:filesystem-directory($code-dir)/dir:entry/dir:last-modified,
      xdmp:filesystem-directory($config-dir)/dir:entry[
        dir:filename eq $config-file]/dir:last-modified))
  where exists($pre-generated-navigation) and $last-generated gt $last-update
  return $pre-generated-navigation
};

(: When first populating the navigation, cache it in the database :)
declare function ml:save-cached-navigation($doc)
{
  if (empty($doc/node())) then ()
  (: Force the insert to occur in a separate transaction to prevent every request
   from being marked as an update :)
  else xdmp:invoke(
    "document-insert.xqy",
    (QName("","uri"), $pre-generated-location,
      QName("","document"), $doc))
};

(: Call this to explicitly invalidate the cached navigation :)
declare function ml:invalidate-cached-navigation()
{
  if (doc-available($public-nav-location))
  then xdmp:document-delete($public-nav-location) else (),
  if (doc-available($draft-nav-location))
  then xdmp:document-delete($draft-nav-location) else ()
};

(: Used to implement the <ml:meetup-events/> tag :)
declare function ml:get-meetup-upcoming($group as xs:string?)
{
  let $doc := doc(concat('/private/meetup/', $group, '.xml'))

  return
  for $m in $doc/*:meetup/*:upcoming-events/*:event
  return
  <ml:meetup>
    <ml:id>{$m/@*:id/string()}</ml:id>
    <ml:title>{$m/@*:name/string()}</ml:title>
    <ml:url>{$m/@*:url/string()}</ml:url>
    <ml:yes-rsvps>{$m/@*:yes_rsvp_count/string()}</ml:yes-rsvps>
    <ml:date>
  {
    xdmp:strftime("%B %d", u:epoch-seconds-to-dateTime(($m/@*:time/number()) idiv 1000))
  }
    </ml:date>
    <ml:rsvps>
  {
    for $r in $m/*:rsvp
    return
    <ml:member>
      <ml:id>{$r/*:member/*:member_id/string()}</ml:id>
      <ml:name>{$r/*:member/*:name/string()}</ml:name>
      <ml:avatar>{$r/*:member_photo/*:thumb_link/string()}</ml:avatar>
    </ml:member>
  }
    </ml:rsvps>
  </ml:meetup>
};

declare function ml:get-meetup-recent($group as xs:string?)
{
  let $doc := doc(concat('/private/meetup/', $group, '.xml'))

  return
  for $m in $doc/*:meetup/*:recent-events/*:event
  return
  <ml:meetup>
    <ml:id>{$m/@*:id/string()}</ml:id>
    <ml:title>{$m/@*:name/string()}</ml:title>
    <ml:url>{$m/@*:url/string()}</ml:url>
    <ml:yes-rsvps>{$m/@*:yes_rsvp_count/string()}</ml:yes-rsvps>
    <ml:date>
  {
    xdmp:strftime("%B %d, %Y", u:epoch-seconds-to-dateTime(($m/@*:time/number()) idiv 1000))
  }
    </ml:date>
    <ml:rsvps>
  {
    for $r in $m/*:rsvp[exists(*:member_photo/*:thumb_link)][1 to 6]
    return
    <ml:member>
      <ml:id>{$r/*:member/*:member_id/string()}</ml:id>
      <ml:name>{$r/*:member/*:name/string()}</ml:name>
      <ml:avatar>{$r/*:member_photo/*:thumb_link/string()}</ml:avatar>
    </ml:member>
  }
    </ml:rsvps>
  </ml:meetup>
};

declare function ml:get-meetup-name($group as xs:string?)
{
  let $url := concat('/private/meetup/', $group, '.xml')
  return doc($url)/*:meetup/@*:name/string()
};

declare function ml:videos()
{
  element ml:videos {
    for $video in $Articles[@type eq 'Video']
    return $video
  }
};

(: "?" is illegal in document URIs, but we use it in some REST docs,
 : escaped using "@"
 :)
declare function ml:escape-uri(
  $external-uri as xs:string)
as xs:string
{
  (: ?foo=bar   =>   @foo=bar :)
  translate($external-uri, '?', $QUESTIONMARK-SUBSTITUTE)
};

declare function ml:unescape-uri(
  $doc-uri as xs:string)
as xs:string
{
  (: @foo=bar   =>   ?foo=bar :)
  translate($doc-uri, $QUESTIONMARK-SUBSTITUTE, '?')
};

(: Account for "/apidoc" prefix in internal/external URI mappings :)
declare function ml:external-uri-for-string($doc-uri as xs:string)
  as xs:string
{
  let $version := substring-before(substring-after($doc-uri,'/apidoc/'),'/')
  let $versionless-path := (
    if ($version) then substring-after($doc-uri,concat('/apidoc/',$version))
    else substring-after($doc-uri,'/apidoc'))
  let $path := ml:unescape-uri($versionless-path)
  return
  (: Map "/index.xml" to "/" and "/foo.xml" to "/foo" :)
  (: Strip ".xml" suffix (only applies to .xml files, not .html files, etc.) :)
  if ($path eq '/index.xml') then '/'
  else if (ends-with($path,'.xml')) then substring-before($path, '.xml')
  else $path
};

(: Mapping of internal->external URIs for API server :)
declare function ml:external-uri-api($node as node())
  as xs:string
{
  ml:external-uri-for-string(base-uri($node))
};

(: Mapping of internal->external URIs for admin server. :)
declare function ml:external-uri-admin(
  $doc-path as xs:string)
as xs:string
{
  if ($doc-path eq '/admin/index.xml') then '/'
  else substring-before(substring-after($doc-path,'/admin'), '.xml')
};

(: Mapping of internal->external URIs for main server :)
declare function ml:external-uri-main(
  $doc-path as xs:string)
as xs:string
{
  if ($doc-path eq '/index.xml') then '/'
  else substring-before($doc-path, '.xml')
};

declare function ml:external-uri(
  $node as node()?)
as xs:string?
{
  base-uri($node) ! (
    if (not(starts-with(., '/admin'))) then ml:external-uri-main(.)
    else ml:external-uri-admin(.))
};

declare function ml:internal-uri-admin(
  $doc-path as xs:string)
as xs:string
{
  if ($doc-path eq '/') then '/admin/index.xml'
  else concat('/admin', $doc-path, '.xml')
};

declare function ml:internal-uri-main(
  $doc-path as xs:string)
as xs:string
{
  if ($doc-path eq '/') then '/index.xml'
  else concat($doc-path, '.xml')
};

(: Some apidoc code uses api:internal-uri instead.
 : NOTE: only intended for docs whose URIs end in ".xml"
 :)
declare function ml:internal-uri(
  $doc-path as xs:string)
as xs:string
{
    (: Use admin version when needed. :)
    if ($ADMIN) then ml:internal-uri-admin($doc-path)
    else ml:internal-uri-main($doc-path)
};

(: Get the last part of the page's URL :)
declare function ml:tutorial-page-url-name($node as node())
as xs:string
{
  tokenize(ml:external-uri($node), '/')[last()]
};

(: Get the parent tutorial for this page. :)
declare function ml:parent-tutorial($node as node())
as element(Tutorial)?
{
  typeswitch ($node)
  case element(Tutorial) return $node
  default return (
    let $uri-external as xs:string := ml:external-uri($node)
    let $page-name := concat('/', ml:tutorial-page-url-name($node))
    let $parent-uri as xs:string := substring-before(
      $uri-external, $page-name)
    let $uri-internal := ml:internal-uri($parent-uri)
    return doc($uri-internal)/Tutorial)
};

(: Given a sequence of possible version strings,
 : return the best one available.
 :)
declare function ml:version-select(
  $list as xs:string*)
as xs:string?
{
  (for $v in distinct-values($list ! normalize-space(.))
    where $v = $server-versions-available
    order by xs:double($v) descending
    return $v)[1]
};

declare function ml:file-from-path($path as xs:string)
as xs:string
{
  if (not(contains($path, '/'))) then $path
  else ml:file-from-path(substring-after($path, '/'))
};

declare function ml:get-author-info($author-name as xs:string)
{
  /ml:Author[ml:name = $author-name]
};

declare function ml:build-doc-sections-options()
{
  let $options := fn:doc(api:toc-uri())//node()[@class/fn:string() = "toc_select_option"]/fn:string()
  let $preference := users:get-user-preference(users:getCurrentUser(), $users:PREF-DOC-SECTION)
  for $option in $options
  return
    element option {
      if ($option = $preference) then
        attribute selected { "true" }
      else (),
      $option
    }
};

declare private function ml:build-recipe-element($params, $name)
{
  xdmp:unquote(
    '<ml:' || $name || ' xmlns:ml="http://developer.marklogic.com/site/internal">' ||
    $params[@name eq $name]/fn:string() || "</ml:" || $name || ">", (: " :)
    "http://www.w3.org/1999/xhtml"
  )
};

(:
 : Build a recipe document base on a sequence of parameters.
 : Combine with existing document where appropriate.
 :)
declare function ml:build-recipe(
  $existing as document-node()?,
  $params as element()*)
as document-node()
{
  document {
    element ml:Recipe {
      attribute xmlns { "http://www.w3.org/1999/xhtml" },
      attribute status { $params[@name eq "status"]/fn:string() },
      element ml:title { $params[@name eq "title"]/fn:string() },
      for $author in $params[fn:matches(@name, "author\[")]
      return
        element ml:author { $author/fn:string() },
      if ($existing/ml:Recipe/ml:created ne "") then
        $existing/ml:Recipe/ml:created
      else
        element ml:created {
          fn:current-dateTime()
        },
      (: If <last-updated> is given a value, take that, otherwise use the current dateTime :)
      element ml:last-updated {
        if ($params[@name eq "last_updated"]/fn:string() = "") then
          fn:current-dateTime()
        else
          $params[@name eq "last_updated"]/fn:string()
      },
      element ml:min-server-version {
        $params[@name eq "min_server_version"]/fn:string()
      },
      if ($params[@name eq "max_server_version"] ne "") then
        element ml:max-server-version {
          $params[@name eq "max_server_version"]/fn:string()
        }
      else (),
      element ml:tags {
        for $tag in $params[fn:matches(@name, "tag\[")]
        return
          element ml:tag { $tag/fn:string() }
      },
      ml:build-recipe-element($params, "description"),
      ml:build-recipe-element($params, "problem"),
      ml:build-recipe-element($params, "solution"),
      (: Record the needed privileges :)
      for $tag in $params[fn:matches(@name, "privilege[_\w]*\[")]
      return
        element ml:privilege { $tag/fn:string() },
      (: Record the needed indexes :)
      for $index in $params[fn:matches(@name, "index[_\w]*\[")]
      return
        element ml:index { $index/fn:string() },
      ml:build-recipe-element($params, "discussion"),
      ml:build-recipe-element($params, "see-also")
    }
  }
};

(: model/data-access.xqy :)
