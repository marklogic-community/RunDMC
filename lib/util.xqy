module "http://markmail.org/util"
declare namespace util = "http://markmail.org/util"
import module namespace search = "http://markmail.org/search" at "/lib/search-lib.xqy"
import module namespace stox = "http://marklogic.com/commons/query-xml" at "/lib/query-xml.xqy"
import module namespace prop = "http://xqdev.com/prop" at "/lib/properties.xqy"
import module "http://markmail.org/session" at "/MarkMail/session-lib.xqy"

default function namespace = "http://www.w3.org/2003/05/xpath-functions"

declare namespace qm="http://marklogic.com/xdmp/query-meters"
declare namespace em="URN:ietf:params:email-xml:"
declare namespace rf="URN:ietf:params:rfc822:"

define variable $LOGTIME as xs:boolean { true() }
define variable $DATE_HEADER as xs:string { "%a, %d %b %Y %H:%M:%S" }

define function util:url(
	$ignore as xs:string*,
	$add as element(param)*,
	$base as xs:string?
) as xs:string
{
	let $ignore :=
		if($ignore = "*")
		then util:getRequestFieldNames(false())
		else $ignore
	let $pathAdd := string-join(
		for $field in $add[@append = "true"]
		return
			if($field/@concat = "true" and exists($field/@value))
			then concat(util:getRequestField($field/@name, ()), " ", $field/@value)
			else if($field/@concat = "true")
			then util:getRequestField($field/@name, ())
			else util:encode($field/@value)
	, "/")
	let $s := string-join((
		for $field in util:getRequestFieldNames(false())
		let $fieldValue := util:getRequestField($field, ())
		where not($field = ($ignore, "domain")) and $fieldValue != ""
		return concat($field, "=", util:encode($fieldValue))
		,
		for $field in $add[empty(@append) or @append = "false"]
		let $value :=
			if($field/@concat = "true")
			then concat(util:getRequestField($field/@name, ()), " ", $field/@value)
			else string($field/@value)
		return concat($field/@name, "=", util:encode($value))
	), "&")
	let $base := if(string-length($pathAdd)) then concat($base, $pathAdd) else $base
	return
		if(string-length($s) = 0)
		then $base
		else concat($base, "?", $s)
}

define function util:commify(
	$s as xs:string*
) as xs:string
{
	let $s := string(xs:integer(xs:double($s)))
	return
		if(string-length($s) <= 3)
		then $s
		else concat(util:commify(substring($s, 1, string-length($s)-3)), ",", substring($s, string-length($s)-2, 3))
}


define function util:two-digits(
	$num as xs:integer
) as xs:string
{
  let $result := string($num)
  let $length := string-length($result)
  return
	if($length = 1) then concat("0", $result) else $result
}

define function util:endOfToday(
) as xs:dateTime
{
	let $now := current-dateTime() + implicit-timezone()  (: resolve relative to Pacific :)
	return xs:dateTime(
		concat(
			get-year-from-dateTime($now), "-",
			util:two-digits(get-month-from-dateTime($now)), "-",
			util:two-digits(get-day-from-dateTime($now)), "T",
			"23:59:59")
	)
}

define function util:formatDate(
  $date as xs:dateTime
) as xs:string
{
	let $days := get-days-from-dayTimeDuration(subtract-dateTimes-yielding-dayTimeDuration(util:endOfToday(), $date))
	return
		if($days > 2 or $days < 0)
		then util:formattedDate($date)
		else if($days = 2)
		then "2 Days Ago"
		else if($days = 1)
		then concat("Yesterday ", util:formattedTime($date))
		else concat("Today ", util:formattedTime($date))
}

define function util:formatDateForProse(
	$date as xs:dateTime,
	$leadIn as xs:string
) as xs:string
{
	let $days := get-days-from-dayTimeDuration(subtract-dateTimes-yielding-dayTimeDuration(util:endOfToday(), $date))
	return
		if($days > 2 or $days < 0)
		then concat($leadIn, util:formattedDate($date))
		else if($days = 2)
		then "2 days ago"
		else if($days = 1)
		then concat("yesterday at ", util:formattedTime($date))
		else concat("today at ", util:formattedTime($date))
}

define function util:formattedTime(
	$date as xs:dateTime
) as xs:string
{
	util:formattedTime($date, false())
}

define function util:formattedTime(
	$date as xs:dateTime,
	$withSeconds as xs:boolean
) as xs:string
{
	let $sessionID := ($session:access)[1]
	let $timeFormat :=
		if($sessionID)
		then $session:time-format
		else ""
	return
		if($timeFormat = "written-24h")
		then if($withSeconds) then xdmp:strftime("%R:%S", $date) else xdmp:strftime("%R", $date)
		else if($timeFormat = "written-french")
		then if($withSeconds) then xdmp:strftime("%Hh%Mm%Ss", $date) else xdmp:strftime("%Hh%Mm", $date)
		else if($withSeconds) then xdmp:strftime("%l:%M:%S %P", $date) else xdmp:strftime("%l:%M %P", $date)
}

define function util:formattedDate(
	$date as xs:dateTime
) as xs:string
{
	let $sessionID := ($session:access)[1]
	let $dateFormat :=
		if($sessionID)
		then $session:date-format
		else ""
	return
		if($dateFormat = "written-euro")
		then xdmp:strftime("%e %b %Y", $date)
		else if($dateFormat = "number-us")
		then xdmp:strftime("%m/%d/%Y", $date)
		else if($dateFormat = "number-cdn")
		then xdmp:strftime("%d/%m/%Y", $date)
		else if($dateFormat = "number-euro")
		then xdmp:strftime("%Y/%m/%d", $date)
		else xdmp:strftime("%b %e, %Y", $date)
}

define function util:formattedDateTime(
	$date as xs:dateTime,
	$withSeconds as xs:boolean
) as xs:string
{
	concat(util:formattedDate($date), " ", util:formattedTime($date, true()))
}

define function util:formattedDateTime(
	$date as xs:dateTime
) as xs:string
{
	concat(util:formattedDate($date), " ", util:formattedTime($date, false()))
}


define function util:humanDateDuration(
	$startDate as xs:dateTime,
	$endDate as xs:dateTime
) as xs:string
{
	let $duration := subtract-dateTimes-yielding-dayTimeDuration($endDate, $startDate)
	let $secondsDiff := get-seconds-from-dayTimeDuration($duration)
	let $minutesDiff := get-minutes-from-dayTimeDuration($duration)
	let $hoursDiff := get-hours-from-dayTimeDuration($duration)
	let $daysDiff := get-days-from-dayTimeDuration($duration)
	let $dateString :=
		if($daysDiff > 1)
		then concat($daysDiff, " days")
		else if($daysDiff = 1)
		then concat("1 day and ", $hoursDiff, " hours")
		else if($hoursDiff > 2)
		then concat($hoursDiff, " hours")
		else if($hoursDiff > 0)
		then concat(util:pluralizeAppend($hoursDiff, "hour", ()), " and ", util:pluralizeAppend($minutesDiff, "minute", ()))
		else if($minutesDiff > 0)
		then util:pluralizeAppend($minutesDiff, "minute", ())
		else util:pluralizeAppend($secondsDiff, "second", ())
	return 
		concat($dateString, " later")
}

(: Is there's no session ID, we'll show ads :)
define function util:showAds() as xs:boolean
{
	let $forceAds :=  boolean(xdmp:get-request-field("force-ads"))
	let $sessionID := ($session:access)[1]
	(: TODO: move this into a config parameter :)
	(: let $startHour := hours-from-dateTime(session:get-start($sessionID)) :)
	(: let $startHour := hours-from-dateTime(current-dateTime()) :)
	(: let $oddHour := (math:fmod($startHour, 2) = 0) :)
   
	(: Set noAdSegment to true() to disable ads in all segments or :)
	(: false() to turn them on for those who haven't hidden them :)
	(: let $noAdSegment := $oddHour :)
	let $noAdSegment := false()
	
	let $showAds :=
	  if ($noAdSegment)
	  then false()
	  else if ($sessionID and $session:show-ads ne "show")
	  then false()
	  else true()

	return ($showAds or $forceAds)
}

define function util:pluralize(
	$number as xs:integer,
	$string as xs:string,
	$pluralString as xs:string?
) as xs:string
{
	if($number = 1)
	then $string
	else
		if(empty($pluralString))
		then concat($string, "s")
		else $pluralString
}

define function util:pluralizeAppend(
	$number as xs:integer,
	$string as xs:string,
	$pluralString as xs:string?
) as xs:string
{
	concat(util:commify(string($number)), " ", util:pluralize($number, $string, $pluralString))
}

define function util:encodeHtml(
	$s as xs:string
) as xs:string
{
	let $s := replace($s, "<", "&lt;")
	let $s := replace($s, ">", "&gt;")
	let $s := replace($s, """", "&quot;")
	let $s := replace($s, "'", "&apos;")
	let $s := replace($s, "&", "&quot;")
	return $s
}

define function util:encode(
	$s as xs:string
) as xs:string
{
	(: Undo some encodings we don't need for our purposes :)
	let $e := encode-for-uri($s)
	let $e := replace($e, "%20", "+")
	let $e := replace($e, "%2F", "/")
	let $e := replace($e, "%3A", ":")
	let $e := replace($e, "%22", """")
	(: Leave the at sign encoded to make it harder on spammers :)
	(:let $e := replace($e, "%40", "@"):)
	(: And encode periods also to make it harder on spammers :)
	let $e := replace($e, "\.", "%2E")
	return $e
}

(: @param returnAllFields - if true, uses all request fields; if false, omits an internally-used set :)
(: FIXME: this function is broken if there are request fields used multiple times in the same request :)
define function util:buildQueryString(
	$returnAllFields as xs:boolean
) as xs:string
{
	string-join(
		for $name in util:getRequestFieldNames($returnAllFields)
		let $value := util:getRequestField($name, ())[1]
		return concat(util:encode($name), "=", util:encode($value)),
		"&"
	)
}

define function util:sanitizeReferQuery(
	$query as xs:string
) as xs:string
{
	let $base := stox:searchToXml($query, (
				"site", "inurl", "intitle", "allintitle", "allinurl", "intext",
				"allintext", "inanchor", "allinanchor", "inlinks",
				"allinlinks", "filetype", "ext", "daterange", "group",
				"insubject", "author", "msgid", "link", "related", "cache",
				"stocks", "phonebook", "bphonebook", "rphonebook", "info",
				"category"
			),
			("-", "+"), (), ",")
	let $terms :=
		for $term in $base/term
		where empty($term/@field)
		return
			if($term/@op = "-")
			then $term
			else <term>{ string($term) }</term>
	return search:constructQueryString($terms)
}

define function util:logTime(
) as empty()
{
	if($LOGTIME)
	then
		let $nl := "
"
		let $page := xdmp:get-request-path()
		let $qs := util:buildQueryString(true())
		let $qs := if ($qs = "") then "" else concat("?", $qs)
		let $ch := tokenize(string-join(xdmp:get-request-header("Cookie"), ";"), ";")
		let $ch := string-join($ch, concat(";", $nl))
		return xdmp:log(concat("TIMING: ", $page, $qs, " ", xdmp:elapsed-time(), $nl, " ", $ch), "info")
	else ()
}

define function util:getSearchDomain(
) as xs:string
{
	let $domain := util:getRequestField("domain", ())
	let $domains := tokenize($domain, "\.")
	let $domains :=
		for $i in $domains
		where not($i = ("", "www"))
		return concat(" _domain:", $i)
	return
		if(count($domains))
		then string-join($domains, " ")
		else ""
}

define function util:getAttachmentType(
	$attachment as element()?
) as xs:string?
{
	if($attachment)
	then
		if(exists($attachment/attachment-image-large) and exists($attachment/attachment-image-thumb))
		then if(exists($attachment/@conversion-error)) then "binary" else "document"
		else if(exists($attachment/attachment-image-large))
		then "image"
		else if(exists($attachment/page))
		then "text"
		else "binary"
	else ()
}

define function util:_joinQ(
	$default as xs:string
) as xs:string?
{
	let $qs := xdmp:get-request-field("q", $default)
	let $qcount := count($qs)
	return
		if($qcount < 2)
		then $qs
		else normalize-space(string-join($qs, " "))
}

define function util:getRequestField(
	$name as xs:string,
	$default as xs:string?
) as xs:string*
{
	let $default := if($default) then $default else ""
	return
		if($name = "q")
		then util:_joinQ($default)
		else xdmp:get-request-field($name, $default)[1]
}

define function util:getRequestFieldNames(
	$returnAll as xs:boolean
) as xs:string*
{
	if ($returnAll) then
		xdmp:get-request-field-names()
	else
	   	xdmp:get-request-field-names()[not(. = ("domain", "type", "mode", "x", "y", "extended"))]
}

(:
	Returns the full domain name.
	Examples:
		markmail.org
		php.markmail.org
:)
define function util:getHostname(
) as xs:string
{
	let $domain := util:getRequestField("domain", ())
	return
		if($domain != "")
		then concat($domain, ".", prop:get("base_domain"))
		else prop:get("base_domain")
}

define function util:getRawDomain(
) as xs:string
{
	let $d := util:getRequestField("domain", ())
	return
		if(string-length($d) = 0)
		then ""
		else if($d = ("www", "www."))
		then ""
		else if(ends-with($d, "."))
		then substring($d, 0, string-length($d))
		else $d
}

define function util:getPrintableDomain(
) as xs:string
{
	let $d := util:getRawDomain()
	return 
		if(string-length($d) = 0)
		then ""
		else concat(" """, $d, """")
}

define function util:shortMonth(
	$m as xs:string?
) as xs:string
{
	substring($m, 0, 8)  (: 2007-01-01 -> 2007-01 :)
}

define function util:longMonth(
	$m as xs:string?
) as xs:string
{
	if(string-length($m) = 7)
	then concat($m, "-01")
	else $m
}

(: Note: this function pays no attention to the users formating preferences :)
define function util:prettyYearMonth(
	$m as xs:string?
) as xs:string
{
	if($m castable as xs:date)
	then xdmp:strftime("%Y %B", util:fakedLikeZulu(xs:dateTime(xs:date($m))))
	else ""
}

(: Note: this function pays no attention to the users formating preferences :)
define function util:prettyMonthYear(
	$m as xs:string?
) as xs:string
{
	if($m castable as xs:date)
	then xdmp:strftime("%B %Y", util:fakedLikeZulu(xs:dateTime(xs:date($m))))
	else ""
}

define function util:getRequestUrl(
) as xs:string
{
	concat(
		xdmp:get-request-path(), "?",
		util:buildQueryString(false())
	)
}

(:
	We don't want to do lexicons and search work for a /message/123
	or /thread/123 request.  So we have Squid give us a type=message
	or type=thread so we can know not to bother with that work.
:)
define function util:isMessageOnly(
) as xs:boolean
{
	util:getRequestField("type", ()) = ("message","thread")
}

define function util:bytesToHuman(
	$bytes as xs:integer
) as xs:string
{
	if($bytes < 1024)
	then concat(round-half-to-even($bytes div 1024, 1), "k")
	else if($bytes < 1024 * 1024)
	then concat(round($bytes div 1024), "k")
	else concat(round-half-to-even($bytes div (1024 * 1024), 1), "MB")
}

(:
let $projects :=
  distinct-values(
	for $list in cts:element-attribute-values(
	  xs:QName("message"),
	  xs:QName("list"),
	  "",
	  (),
	  cts:element-attribute-word-query(
		xs:QName("message"),
		xs:QName("list"),
		"apache"
	  )
	)
	let $tokens := tokenize($list, "\.")
	where count($tokens) > 3
	return $tokens[3]
  )
for $project in $projects
let $msgCount := count(
  cts:uris("", (), 
	cts:and-query((
	  cts:element-attribute-word-query(
		xs:QName("message"),
		xs:QName("list"),
		$project
	  ),
	  cts:element-attribute-range-query(
		xs:QName("message"),
		xs:QName("year-month"),
		">",
		"2007"
	  )
	))
  )
)
order by $msgCount descending
return $project
:)
define function util:getTopApacheProjects(
	$num as xs:integer?
) as xs:string+
{
	let $projects := (
		"ws", "maven", "incubator", "lucene", "harmony", "geronimo", "myfaces",
		"struts", "db", "tomcat", "wicket", "httpd", "spamassassin", "ofbiz",
		"tapestry", "jakarta", "activemq", "cocoon", "directory", "commons",
		"jackrabbit", "xmlgraphics", "openjpa", "ant", "portals", "lenya",
		"felix", "openejb", "mina", "james", "roller", "logging", "cayenne",
		"ibatis", "velocity", "forrest", "ode", "perl", "xml", "apr", "xerces",
		"shale", "poi", "tiles", "xmlbeans", "turbine", "gump", "labs", "beehive",
		"excalibur", "hivemind", "tcl", "apachecon", "santuario", "archive",
		"avalon"
	)
	for $proj in if($num) then $projects[1 to $num] else $projects
	order by $proj
	return $proj
}

define function util:getTopProjects(
	$num as xs:integer?
) as xs:string+
{
	let $projects := (
		"apache", "xen", "mysql", "perl", "pear", "php", "ruby", "gnome",
		"mozilla", "firefox", "thunderbird", "python", "postgresql",
		"squid-cache", "w3", "wso2", "ant", "cocoon", "db", "geronimo",
		"harmony", "httpd", "incubator", "lucene", "maven", "mina",
		"myfaces", "spamassassin", "struts", "tomcat", "ws", "groovy",
		"grails", "jruby", "css-discuss", "saxon", "hibernate", "jdom",
		"markmail", "xsl"
	)
	for $proj in if($num) then $projects[1 to $num] else $projects
	order by $proj
	return $proj
}

define function util:getHintProjects(
) as xs:string+
{
	(: We will make this automatic when we have list metadata to pull from :)
	(
		util:getTopApacheProjects(()),
		"apache", "php", "pear", "mozilla", "mysql", "appfuse", "jdom",
		"xwiki", "xml", "xsl", "hibernate", "nhibernate", "plone",
		"markmail", "firefox", "thunderbird", "postgresql", "wso2",
		"webtest", "htmlunit", "saxon"
	)
}

define function util:fakedLikeZulu(
	$dt as xs:dateTime
) as xs:dateTime
{
	$dt - implicit-timezone()
}

define function util:expireInSeconds(
	$s as xs:integer
) as empty()
{
	let $s :=
		if(prop:get("deployment_mode") = "production")
		then $s
		else 0

	(: We print dates simulating GMT w/o the timezone shown to make squid happy. :)
	let $duration := xdt:dayTimeDuration(concat("PT", string($s), "S"))
	let $set := xdmp:add-response-header("Date", xdmp:strftime($DATE_HEADER, util:fakedLikeZulu(current-dateTime())))
	let $set := xdmp:add-response-header("Expires", xdmp:strftime($DATE_HEADER, util:fakedLikeZulu(current-dateTime() + $duration)))
	let $public := xdmp:add-response-header("Cache-Control", "public")
	return ()
}

define function util:trimString(
	$string as xs:string,
	$toLength as xs:integer
) as xs:string
{
	if(string-length($string) > $toLength)
	then concat(substring($string, 1, $toLength - 3), "...")
	else $string
}

define function util:trimStringLeft(
	$string as xs:string,
	$toLength as xs:integer
) as xs:string
{
	let $strLength := string-length($string)

	(: ... => +3 and 1-origin => +1 ==> 4 :)
	let $trimStartPos := $strLength - $toLength + 4
	return
		if($toLength > 3 and $strLength > $toLength)
		then concat("...", substring($string, $trimStartPos, $strLength))
		else $string
}

define function util:getCaptchaChallenge(
) as xs:string?
{
	let $publicKey := prop:get("captcha_pub_key")
	let $publicKey :=
		if(empty($publicKey))
		then "6Ld6VAAAAAAAABnqmlt864wwQEDIAXkUMeKv1H3B"
		else $publicKey

	let $response := xdmp:http-get(concat("http://api.recaptcha.net/challenge?ajax=1&k=", $publicKey), <options xmlns="xdmp:document-get"><encoding>ISO-8859-1</encoding></options>)
	let $response := if($response[1]/*:code = 200) then $response[2] else ()
	return replace(tokenize(tokenize(util:hexDecode($response), "\s*challenge\s?:\s?")[2], ",")[1], "'", "")
}

define function util:checkCaptcha(
	$challenge as xs:string,
	$response as xs:string
) as xs:boolean
{
	let $privateKey := prop:get("captcha_priv_key")
	let $privateKey :=
		if(empty($privateKey))
		then "6Ld6VAAAAAAAANbHvXLGcSh_DOkbA2ByxGfUDdyH"
		else $privateKey

	(: The recaptcha server needs to know the requesting IP for security :)
	(: When we're behind a proxy X-Forwarded-For is more authoritative :)
	let $remoteIP := (
		xdmp:get-request-header("X-Forwarded-For"),
		xdmp:get-request-client-address()
		)[1]

	(: Their server address :)
	let $server := "http://api-verify.recaptcha.net/verify"

	let $payload :=
		concat(
			"privatekey=", xdmp:url-encode($privateKey),
			"&remoteip=", xdmp:url-encode($remoteIP),
			"&challenge=", xdmp:url-encode($challenge),
			"&response=", xdmp:url-encode($response)
		)

	let $post :=
		xdmp:http-post($server,
			<options xmlns="xdmp:http">
				<headers>
					<content-type>application/x-www-form-urlencoded</content-type>
				</headers>
				<data>{ $payload }</data>
			</options>)

	let $response := $post[1]
	let $body := $post[2]
	let $bodyTok := tokenize($body, "\n")
	let $recaptchaAnswer := $bodyTok[1]
	let $recaptchaCode := $bodyTok[2]

	return contains($body, "true")  (: in case it's useful, esp in case of error :)
}

define function util:hexDecode(
	$b
) as xs:string
{
	let $s := xs:string($b)
	let $iterations := string-length($s) idiv 2
	let $vals :=
		for $i in (1 to $iterations)
		return substring($s, (2 * $i) - 1, 2)
	let $chars :=
		for $val in $vals
		return codepoints-to-string(xdmp:hex-to-integer($val))
	return string-join($chars, "")
}

define function util:singleWordCase(
	$name as xs:string
) as xs:string {
  concat(
		upper-case(substring($name, 1, 1)),
		lower-case(substring($name, 2))
	)
}

define function util:multiWordCase(
	$name as xs:string
) as xs:string? {
	if (string-length($name) = 0)
	then ()
	else string-join(
	let $words := tokenize($name, "[\s\.]+") (: space or period :)
	for $word in $words return util:singleWordCase($word)
  , " ")
}

define function util:getLatestThreadsIDsInList(
	$list as xs:string,
	$giveMe as xs:integer
) as xs:string*
{
	let $ids := ()
	let $doSomeStuff :=
		for $message in (/message[@list = $list])[1 to 100]
		where count($ids) lt $giveMe
		order by xs:dateTime($message/@date) descending
		return
			if($message/@thread-id = $ids)
			then ()
			else xdmp:set($ids, ($ids, $message/@thread-id))
	return $ids
}

define function util:getLatestThreadIDs(
	$query as element(search),
	$giveMe as xs:integer
) as xs:string*
{
	let $messages := (
		for $message in cts:search(/message, search:getCtsQuery($query), "unfiltered")
		order by xs:dateTime($message/@date) descending
		return $message
	)[1 to $giveMe * 10]

	let $ids := ()
	let $doSomeStuff :=
		for $message in $messages
		where count($ids) lt $giveMe
		return
			if($message/@thread-id = $ids)
			then ()
			else xdmp:set($ids, ($ids, $message/@thread-id))
	return $ids
}

define function util:emailDotify(
	$email as xs:string
) as xs:string+  (: two items: (user, host) :)
{
	let $user := substring-before($email, "@")
	let $host := substring-after($email, "@")
	let $ulength := string-length($user)
	let $reveal :=
		if($ulength <= 4)
		then 2
		else if($ulength <= 6)
		then 3
		else 4
	let $userPrefix := substring($user, 1, $reveal)
	return ($userPrefix, $host)
}

define function util:emailObfuscate(
	$email as xs:string?
) as xs:string
{
	if (empty($email))
	then ""
	else if(not(contains($email, "@")))
	then $email
	else
		let $dotify := util:emailDotify($email)
		let $userPrefix := $dotify[1]
		let $host := $dotify[2]
		return concat($userPrefix, "...@", $host)
}


(: Sends email as provided :)
(: Returns true() if no immediate error, false() otherwise :)
(: If more than one $toAddress is provided, ignores $toName :)
(: If a $from address is provided, assumes an on-behalf-of send and creates rf:sender entry :)
(: Logs all errors :)

define function util:sendEmail(
	$fromName as xs:string?,
	$fromAddress as xs:string?,
	$onBehalfOf as xs:boolean,
	$toName as xs:string*,
	$toAddress as xs:string*,
	$replyToName as xs:string*,
	$replyToAddress as xs:string*,
	$subject as xs:string,
	$body as element(em:content)
) as xs:boolean
{
	try {
		xdmp:email(
			<em:Message>
				<rf:subject>{ $subject }</rf:subject>
				{
					if ($onBehalfOf) then
						<rf:sender>
							<em:Address>
								<em:adrs>do-not-reply@void.markmail.org</em:adrs>
							</em:Address>
						</rf:sender>
					else ()
				}
				<rf:from>{
					if ($fromAddress)
					then 
						<em:Address>
							{ if ($fromName) then <em:name>{ $fromName }</em:name> else () }
							<em:adrs>{ $fromAddress }</em:adrs>
						</em:Address>
					else
						<em:Address>
							<em:name>MarkMail.org Registration Confirmation</em:name>
							<em:adrs>do-not-reply@void.markmail.org</em:adrs>
						</em:Address>
				}</rf:from>
				{
					if ($replyToAddress)
					then
						<rf:reply-to>{
						  for $address at $index in $replyToAddress
							let $name := $replyToName[$index]
							let $name := if ($name = "") then () else $name
							return
								<em:Address>
									{ if ($name) then <em:name>{ $name }</em:name> else () }
									<em:adrs>{ $address }</em:adrs>
								</em:Address>
						}</rf:reply-to>
					else ()
				}
				<rf:to>
					{
						for $address at $index in $toAddress
						let $name := $toName[$index]
						let $name := if ($name = "") then () else $name
						return
							<em:Address>
								{ if ($name) then <em:name>{ $toName }</em:name> else () }
								<em:adrs>{ $address }</em:adrs>
							</em:Address>
					}
				</rf:to>
				{ $body }
			</em:Message>
		)
		,
		true()
	} catch ($e) {
		xdmp:log(concat("MM-FAILEDEMAIL:  Unable to send confirming e-mail for ",
			if ($toName) then
				concat("user ", $toName)
			else
				"new user"
			, " to email: ", $toAddress, ". Threw exception: ", xdmp:quote($e)))
		,
		false()
  }
}


(: validates that email fits pattern user@domain or user+extension@domain :)

define function util:validateEmail(
	$email as xs:string?
) as xs:boolean
{
	if (empty($email))
	then false()
	else if ($email = "")
	then false()
	else matches($email, "^[a-zA-Z0-9._+'-]+@[a-zA-Z0-9.-]+\.[a-zA-Z0-9]{1,4}$")
}


(: Return a list of search keywords associated with the given list :)
(: In theory, we should add metadata to the /list entries to provide additional keywords :)
define function util:keywordsFromList(
	$list as xs:string
) as xs:string*
{
	let $omit := ( 	"announce", "com", "dev", "devel", "checkins", "org", "lists", "list",
					"talk", "basic", "basics", "advanced", "misc", "miscellaneous", "users", "user",
					"bugs", "troubleshooting", 
					"open", "public", 
					"net", "commits", "svn", "cvs", "developers", "developer", "discuss", "general", "help", "updates"
		)
	return distinct-values(
		for $piece in fn:tokenize($list, "[\.\-_]")
			return
				if (index-of($omit, $piece)) then
					()
				else
					if (string-length($piece) > 2) then
						$piece
					else
						()
	)
}

(: throw an exception :)
define function util:fail() as xs:integer
{
	1 div 0
}
