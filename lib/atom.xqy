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

let $posts :=
    for $r in fn:doc()/ml:Post[@status="Published"]
    order by xs:dateTime($r/ml:created/text()) descending
    return $r

return
<feed xmlns="http://www.w3.org/2005/Atom">
	<title>MarkLogic Developer Community Blog</title>
	<subtitle></subtitle>
	<link href="http://developer.marklogic.com/blog/atom.xml" rel="self"/>
	<updated>{ current-dateTime() }</updated>
	<id></id>

	<generator uri="http://developer.marklogic.com/blog/atom.xml" version="1.0">MarkLogic Developer Community</generator>
	<icon>http://developer.marklogic.com/favicon.ico</icon>
	<logo>http://developer.marklogic.com/images/logo.gif</logo>
	{
		(: no author :)
		(: no id :)
	}
	{
        for $p in $posts [1 to $MAX_ENTRIES]
        order by xs:dateTime($p/ml:created/text()) descending 
        return
        <entry>
            <id>{$p/ml:link/text()}</id>
            <link href="{$p/ml:link/text()}"/>
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


