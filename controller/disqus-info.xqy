(: Processes the Disqus configuration in /config/disqus-info.xml :)

module namespace dq = "http://marklogic.com/disqus";

import module namespace u = "http://marklogic.com/rundmc/util"
       at "../lib/util-2.xqy";

import module namespace srv = "http://marklogic.com/rundmc/server-urls"
       at "server-urls.xqy";

declare variable $disqusInfo := u:get-doc('/config/disqus-info.xml')/disqus-info;
declare variable $forum      := $disqusInfo/forum[fn:tokenize(@host-types,' ') = $srv:host-type];

declare variable $userAPIKey := fn:string($forum/user_api_key);
declare variable $forumId    := fn:string($forum/forum_id);

declare variable $shortname  := fn:string($forum/@shortname);

declare variable $developer_0_or_1  := 1; (: Make this conditional if we find a need to. :)
