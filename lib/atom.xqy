import module namespace util = "http://markmail.org/util" at "/lib/util.xqy"
import module namespace search = "http://markmail.org/search" at "/lib/search-lib.xqy"
import module namespace atomlib = "http://markmail.org/atom-lib" at "/lib/atom-lib.xqy"
import module namespace prop = "http://xqdev.com/prop" at "/lib/properties.xqy"

define variable $MAX_ENTRIES as xs:integer { 50 }

define function display(
	$node as node()?
) as xs:string
{
	if($node)
	then string($node)
	else "(None)"
}

xdmp:set-response-content-type("application/atom+xml"),

let $expires := util:expireInSeconds(57 * 60)

let $rawRev := prop:get("external_file_revision")
let $rev := if($rawRev) then concat("_", $rawRev) else ""

let $domain := util:getSearchDomain()  (: returns something like _domain:tomcat :) 
let $rawDomain := util:getRawDomain() 
let $q := util:getRequestField("q", ()) 

let $query := search:getQueryXML($q)
let $cts := search:getCtsQuery(search:getQueryXML(concat($q, $domain)))
let $idURL := concat("http://", prop:get("base_domain"), "/atom/")
let $searchURL := concat("http://", prop:get("base_domain"), "/search/")
let $msgRoot := concat("http://", prop:get("base_domain"), "/message/")

(: Return all the messages in the last hour, or $MAX_ENTRIES, whichever is GREATER :)
let $lastHourQuery :=
	cts:element-attribute-range-query(
		expanded-QName("", "message"),
		expanded-QName("", "date"),
		">=",
		current-dateTime() - xdt:dayTimeDuration("PT1H")
	)
let $max := max((
	xdmp:estimate(cts:search(collection("messages"), cts:and-query(($cts, $lastHourQuery))), $MAX_ENTRIES),
	$MAX_ENTRIES
))

(: XXX The following may not be optimized :)
let $messages := (
	for $m in cts:search(collection("messages")/message, $cts)
	order by xs:dateTime($m/@date) descending
	return $m
)[1 to $max]


return
<feed xmlns="http://www.w3.org/2005/Atom">
	<title>MarkMail: { $q }</title>
	<subtitle>We've Got Mail!</subtitle>
	<link href="{ util:url((), (), $searchURL) }" rel="self"/>
	<updated>{ current-dateTime() }</updated>
	<id>{ util:url((), (), $idURL) }</id>

	<generator uri="http://markmail.org/atom" version="1.0">MarkMail</generator>
	<icon>http://markmail.org/favicon.ico</icon>
	<logo>http://markmail.org/images/logo_red.gif</logo>
	{
		(: no author :)
		(: no id :)
	}
	{
		for $m in $messages
		return
		<entry>
			<id>urn:uuid:markmail-{ string($m/@id) }</id>
			<link href="{ util:url((), (), concat($msgRoot, $m/@id)) }"/>
			<title>{ display($m/*:headers/*:subject) }</title>
			<author><name>{ util:emailObfuscate(display($m/*:headers/*:from/@personal)) }</name></author>
			<updated>{ string($m/@date) }</updated>
			<published>{ string($m/@date) }</published>
			<content type="html">{ xdmp:quote(
				<div xmlns="intentional">{ atomlib:renderMessage($m, <search xmlns=""/>) }</div>
			) }</content>
		</entry>
	}
</feed>

,
util:logTime()

(:
	The email obfu link should take you to the msg w/ the captcha open (need Ryan).
	The attachment view link should take you to the msg w/ the attachment open (need Ryan).
	Put web bugs in the feeds
	Setup a creation page
:)
