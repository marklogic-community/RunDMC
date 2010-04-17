xquery version "1.0-ml";

declare namespace atom="http://www.marklogic.com/blog/atom";
declare namespace ml= "http://developer.marklogic.com/site/internal";
declare default function namespace "http://www.w3.org/2005/xpath-functions";

declare function atom:fakedLikeZulu($dt as xs:dateTime) as xs:dateTime {
    $dt - implicit-timezone()
};

declare function atom:expireInSeconds ($s as xs:integer) as empty-sequence() {
    let $DATE_HEADER := "%a, %d %b %Y %H:%M:%S"
    let $duration := xs:dayTimeDuration(concat("PT", string($s), "S"))
    let $set := xdmp:add-response-header("Date", xdmp:strftime($DATE_HEADER, atom:fakedLikeZulu(current-dateTime())))
    let $set := xdmp:add-response-header("Expires", xdmp:strftime($DATE_HEADER, atom:fakedLikeZulu(current-dateTime() + $duration)))
    let $public := xdmp:add-response-header("Cache-Control", "public")
    return ()
};


xdmp:set-response-content-type("application/atom+xml"),

let $MAX_ENTRIES := 30
let $expires := atom:expireInSeconds(60 * 60)
let $feed := xdmp:get-request-field("feed", "")



(: JEM: for now just creating two separate feed paths. "feed" or empty is the blog. "newsandevents" is news and events :) 
return
if ($feed = "blog" or $feed = "")
then
    let $posts :=
        for $r in fn:doc()/ml:Post[@status="Published"]
        order by xs:dateTime($r/ml:created/text()) descending
        return $r
    return
    <feed xmlns="http://www.w3.org/2005/Atom">
    	<title>MarkLogic Developer Community Blog</title>
    	<subtitle></subtitle>
    	<link href="http://developer.marklogic.com/blog/atom.xml?feed=blog" rel="self"/>
    	<updated>{ current-dateTime() }</updated>
    	<id></id>
    
    	<generator uri="http://developer.marklogic.com/blog/atom.xml?feed=blog" version="1.0">MarkLogic Developer Community</generator>
    	<icon>http://developer.marklogic.com/favicon.ico</icon>
    	<logo>http://developer.marklogic.com/images/logo.gif</logo>
    	{
            for $p in $posts [1 to $MAX_ENTRIES]
            order by xs:dateTime($p/ml:created/text()) descending 
            return
            <entry>
                <id>{$p/ml:link/text()}</id>
                <link href="{
                    let $uri := fn:base-uri($p)
                    return
                    if ( (fn:starts-with($uri, "/blog/")) and (fn:ends-with($uri, ".xml")) )
                    then fn:concat( "http://",xdmp:host-name(), fn:substring ($uri,1, string-length($uri) - string-length(".xml") ) )
                    else ()
                }"/>
                <title>{$p/ml:title/text()}</title>
                <author><name>{$p/ml:author//text()}</name></author>
                <updated>   {
                    if ($p/ml:last-updated/text())
                    then $p/ml:last-updated/text()
                    else string($p/ml:created/text())
                }
                </updated>
                <published>{ string($p/ml:created/text()) }</published>
                <content type="html">
                    { xdmp:quote($p/ml:body)}
                </content>
            </entry>
    	}
    </feed>
else if ($feed="newsandevents")
then
(: TODO: add published status to this query -> [@status="Published"]:)
    let $newsevents :=
        for $r in (fn:doc()/ml:Announcement, fn:doc()/ml:Event)
        order by xs:dateTime($r/ml:created/text()) descending
        return $r
    return
    <feed xmlns="http://www.w3.org/2005/Atom">
        <title>MarkLogic Developer News and Events</title>
        <subtitle></subtitle>
        <link href="http://developer.marklogic.com/blog/atom.xml" rel="self"/>
        <updated>{ current-dateTime() }</updated>
        <id></id>
    
        <generator uri="http://developer.marklogic.com/blog/atom.xml" version="1.0">MarkLogic Developer Community</generator>
        <icon>http://developer.marklogic.com/favicon.ico</icon>
        <logo>http://developer.marklogic.com/images/logo.gif</logo>
        {
            for $ne in $newsevents [1 to $MAX_ENTRIES]
            order by xs:date($ne/ml:date/text()) descending 
            return
            <entry>
                <id></id>
                <link href="{
                    let $uri := fn:base-uri($ne)
                    return
                    if ( (fn:starts-with($uri, "/news/")) and (fn:ends-with($uri, ".xml")) )
                    then fn:concat( "http://",xdmp:host-name(), fn:substring ($uri,1, string-length($uri) - string-length(".xml") ) )
                    else if ( (fn:starts-with($uri, "/events/")) and (fn:ends-with($uri, ".xml")) )
                    then fn:concat( "http://",xdmp:host-name(), fn:substring ($uri,1, string-length($uri) - string-length(".xml") ) )
                    else ()
                }"/>
                <title>{$ne/ml:title/text()}</title>
                <author><name>{(: no authors:)}</name></author>
                <updated>{ string($ne/ml:date/text()) }</updated>
                <published>{ string($ne/ml:date/text()) }</published>
                <content type="html"> { 
                    if ($ne/ml:body) 
                    then xdmp:quote($ne/ml:body)
                    else if ($ne/ml:description)
                    then xdmp:quote($ne/ml:description//text())
                    else ()
                }
                </content>
            </entry>
        }
    </feed>
 else 
    ()

