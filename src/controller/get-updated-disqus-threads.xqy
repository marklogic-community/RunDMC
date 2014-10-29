(: This script should be run periodically, e.g., every 10-20 minutes,
   to grab all the updated conversation threads from Disqus
   so that we have a backup and a means by which to publish the
   hidden comments in our pages for SEO purposes.

   It's probably best to run this as a scheduled task.
:)

import module namespace ml = "http://developer.marklogic.com/site/internal"
       at "../model/data-access.xqy";

import module namespace u = "http://marklogic.com/rundmc/util"
       at "../lib/util-2.xqy";

import module namespace dq = "http://marklogic.com/disqus"
       at "disqus-info.xqy";

declare namespace j="http://marklogic.com/xdmp/json";

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

declare variable $threadIds := ((: ML 6.0 :)
                               $updatedThreadList/j:object/j:entry[@key eq 'message']/j:value/j:array/j:value
                                                 /j:object/j:entry[@key eq 'id'     ]/j:value

                               (: ML 5.0 :)
                             | $updatedThreadList/map:map/map:entry[@key eq 'message']/map:value
                                                 /map:map/map:entry[@key eq 'id'     ]/map:value);

declare variable $threadPosts := for $threadId in $threadIds return 
                                   let $url := concat('http://disqus.com/api/get_thread_posts?exclude=spam,killed&amp;limit=10000&amp;thread_id=',
                                                      $threadId,$commonURIParams)
                                   return ml:get-json-xml($url);
                                        
<results since="{$sinceDate}">
{
  for $doc in $threadPosts
  let $disqus-identifier := ((:ML 6.0:)
                            $doc/j:object/j:entry[@key eq 'message'   ]/j:value/j:array/j:value[1]
                                /j:object/j:entry[@key eq 'thread'    ]/j:value
                                /j:object/j:entry[@key eq 'identifier']/j:value/j:array[1]/j:value
                                                                                       (: ASSUMPTION: a thread will have just one disqus identifier :)
                            (:ML 5.0:)
                          | $doc/map:map/map:entry[@key eq 'message'   ]/map:value[1]
                                /map:map/map:entry[@key eq 'thread'    ]/map:value
                                /map:map/map:entry[@key eq 'identifier']/map:value)

  where not(empty($disqus-identifier))
  return
  (
    let $thread-id := string(
                        (:ML 6.0:)
                        $disqus-identifier/../../../../j:entry[@key eq 'id']
                        (:ML 5.0:)
                      | $disqus-identifier/../../map:entry[@key eq 'id'])
    let $comments-doc := $ml:Comments[@disqus_identifier eq $disqus-identifier]
    let $path :=
      if ($comments-doc) then base-uri($comments-doc)
                         else ml:default-comments-uri-from-disqus-identifier($disqus-identifier)
    return
      if (string($path))
      then
        let $new-doc := if ($doc/map:map) then xdmp:xslt-invoke('disqus-to-comments-pre-ML6.xsl', $doc)
                                          else xdmp:xslt-invoke('disqus-to-comments.xsl', $doc)
        return (
           (: Here's where we actually do what we need to do (create or replace the comments docs). :)
           xdmp:document-insert($path, $new-doc),
           <result>Comments document ({$path}) inserted for disqus_identifier: {$disqus-identifier/string(.)}</result>
            )
      else <result>No comments doc could be determined for  thread ID: {$thread-id} (disqus_identifier: {$disqus-identifier/string(.)})</result>
  ),
  if ($DEBUG) then (<THREAD_LIST> {$updatedThreadList}</THREAD_LIST>,
                    <THREAD_POSTS>{$threadPosts      }</THREAD_POSTS>) else ()
}
</results>
