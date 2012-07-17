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


xdmp:set-response-content-type("application/atom+xml; charset=utf-8"),

let $MAX_ENTRIES := 30
let $expires := atom:expireInSeconds(60 * 60)
let $feed := xdmp:get-request-field("feed", "")



return
('<?xml version="1.0" encoding="UTF-8"?>',
    let $posts :=
        for $r in (fn:doc()/ml:Post[@status="Published"], 
                   fn:doc()/ml:Announcement[@status="Published"], 
                   fn:doc()/ml:Event[@status="Published"])
        where not(starts-with(base-uri($r), "/preview"))
        order by xs:dateTime($r/ml:created/text()) descending
        return $r
    return
    <feed xmlns="http://www.w3.org/2005/Atom">
    	<title>MarkLogic Community Blog</title>
    	<subtitle></subtitle>
    	<link href="http://developer.marklogic.com/blog/atom.xml" rel="self"/>
    	<updated>{ current-dateTime() }</updated>
    	<id></id>
    
    	<generator uri="http://developer.marklogic.com/blog/atom.xml" version="1.0">MarkLogic Community</generator>
    	<icon>http://developer.marklogic.com/favicon.ico</icon>
    	<logo>http://developer.marklogic.com/media/marklogic-community-badge.png</logo>
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
                    else if ( (fn:starts-with($uri, "/news/")) and (fn:ends-with($uri, ".xml")) )
                    then fn:concat( "http://",xdmp:host-name(), fn:substring ($uri,1, string-length($uri) - string-length(".xml") ) )
                    else if ( (fn:starts-with($uri, "/events/")) and (fn:ends-with($uri, ".xml")) )
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
                    { 
                    if ($p/ml:body) 
                    then xdmp:quote($p/ml:body, <options xmlns="xdmp:quote"><output-encoding>utf-8</output-encoding></options>)
                    else if ($p/ml:description)
                    then xdmp:quote($p/ml:description//text(), <options xmlns="xdmp:quote"><output-encoding>utf-8</output-encoding></options>)
                    else ()
                    }
                </content>
            </entry>
    	}
    </feed>,
    ()
)
