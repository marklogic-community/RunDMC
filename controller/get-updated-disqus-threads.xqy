(: This script should be run periodically, e.g., every 10-20 minutes,
   to grab all the updated conversation threads from Disqus
   so that we have a backup and a means by which to publish the
   hidden comments in our pages for SEO purposes.

   It's probably best to set up a separate, temporary app
   server that doesn't use URL rewriting in order to easily
   run this script and other maintenance scripts like it.
:)

import module namespace ml = "http://developer.marklogic.com/site/internal"
       at "../model/data-access.xqy";

import module namespace u = "http://marklogic.com/rundmc/util"
       at "../lib/util-2.xqy";

import module namespace dq = "http://marklogic.com/disqus"
       at "disqus-info.xqy";


declare function ml:get-json($uri) {
  xdmp:http-get($uri, <options xmlns="xdmp:document-get">
                        <format>text</format>
                      </options>
               )[2]
};

declare function ml:get-json-xml($uri) {
  document{ xdmp:from-json(ml:get-json($uri)) }
};

(: Set ?DEBUG=yes to output more info in the result :)
declare variable $DEBUG := xdmp:get-request-field("DEBUG") eq 'yes';

(: Set ?force-all=yes to force-update all threads. :)
declare variable $forceUpdateAllThreads := xdmp:get-request-field("force-all") eq 'yes';

                                                                  (: fixup Disqus's non-standard date format :)
declare variable $lastCommentDate := max(xs:dateTime($ml:Comments/@latest-update/concat(.,':00')));

declare variable $sinceDate       := if (not(empty($lastCommentDate)) and
                                         not($forceUpdateAllThreads))
                                     then substring(string($lastCommentDate),1,16) (: truncate seconds for Disqus's sake :)
                                     else '2010-01-01T00:00'; (: a date before we started using Disqus :)


declare variable $commonURIParams := concat('&amp;user_api_key=',$dq:userAPIKey,
                                            '&amp;api_version=1.1');

declare variable $updatedThreadsURI := concat('http://disqus.com/api/get_updated_threads?',
                                              'forum_id=',  $dq:forumId,
                                              '&amp;since=',$sinceDate,
                                              $commonURIParams
                                             );

declare variable $updatedThreadList := ml:get-json-xml($updatedThreadsURI);

declare variable $threadIds := $updatedThreadList/map:map/map:entry[@key eq 'message']/map:value
                                                 /map:map/map:entry[@key eq 'id'     ]/map:value;

declare variable $threadPosts := for $threadId in $threadIds return 
                                   let $url := concat('http://disqus.com/api/get_thread_posts?exclude=spam,killed&amp;limit=10000&amp;thread_id=',
                                                      $threadId,$commonURIParams)
                                   return ml:get-json-xml($url);
                                        
<results since="{$sinceDate}">
{
  for $doc in $threadPosts
  let $disqus-identifiers := $doc/map:map/map:entry[@key eq 'message'   ]/map:value[1]
                                 /map:map/map:entry[@key eq 'thread'    ]/map:value
                                 /map:map/map:entry[@key eq 'identifier']/map:value
  where not(empty($disqus-identifiers))
  return
  (
    let $thread-id := string($disqus-identifiers/../../map:entry[@key eq 'id'])
    let $comments-docs := $ml:Comments[@disqus_identifier = $disqus-identifiers]
    return
      if ($comments-docs) then
      for $comments-doc in $comments-docs return
        let $path    := base-uri($comments-doc)
        let $new-doc := xdmp:xslt-invoke('disqus-to-comments.xsl', $doc)
        return (
           (: Here's where we actually do what we need to do (create or replace the comments docs). :)
           xdmp:document-insert($path, $new-doc),
           <result>Comments document ({$path}) replaced for disqus_identifier: {$disqus-identifiers/string(.)}</result>
        )
      else <result>No comments document found for thread ID: {$thread-id} (disqus_identifier: {$disqus-identifiers/string(.)})</result>
  ),
  if ($DEBUG) then (<THREAD_LIST> {$updatedThreadList}</THREAD_LIST>,
                    <THREAD_POSTS>{$threadPosts      }</THREAD_POSTS>) else ()
}
</results>
