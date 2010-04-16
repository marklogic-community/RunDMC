module "http://markmail.org/atom-lib"
declare namespace atomlib = "http://markmail.org/atom-lib"
declare namespace xhtml = "intentional"
import module namespace search = "http://markmail.org/search" at "/lib/search-lib.xqy"
import module namespace util = "http://markmail.org/util" at "/lib/util.xqy"
import module namespace prop = "http://xqdev.com/prop" at "/lib/properties.xqy"
import module "http://markmail.org/session" at "/MarkMail/session-lib.xqy"
default function namespace = "http://www.w3.org/2003/05/xpath-functions"

define function atomlib:renderMessage(
	$message as element(message),
	$xmlQuery as element(search)
) as element(xhtml:div)
{
	let $message := search:highlight($message, $xmlQuery)
	return
		<xhtml:div>
			<xhtml:table style="border-bottom: 1px solid #ccc; margin-bottom: 10px;"><xhtml:tbody>{ (
				atomlib:process(($message/headers/from)[1], $xmlQuery),
				atomlib:process($message/@list, $xmlQuery),
				atomlib:process($message/attachments, $xmlQuery),
				atomlib:truncated($message/body/@overflow)
			) }</xhtml:tbody></xhtml:table>
			<xhtml:div>{ atomlib:process($message/body, $xmlQuery) }</xhtml:div>
		</xhtml:div>
}

define function atomlib:dispatch(
	$element as element(),
	$xmlQuery as element(search)
) as node()*
{
	for $i in $element/node()
	return atomlib:process($i, $xmlQuery)
}

define function atomlib:process(
	$node as node()?,
	$xmlQuery as element(search)
) as node()?
{
	if(empty($node))
	then ()
	else
		typeswitch($node)
		case text() return $node
		case processing-instruction() return ()
		case comment() return ()

		case element(from) return atomlib:from($node, $xmlQuery)
		case element(to) return atomlib:to($node, $xmlQuery)
		case element(subject) return atomlib:subject($node, $xmlQuery)
		case attribute(date) return atomlib:date($node, $xmlQuery)
		case attribute(list) return atomlib:list($node, $xmlQuery)
		case element(attachments) return atomlib:attachments($node, $xmlQuery)
		case element(body) return atomlib:body($node, $xmlQuery)
		case element(greeting) return atomlib:para($node, $xmlQuery)
		case element(para) return atomlib:para($node, $xmlQuery)
		case element(quote) return atomlib:quote($node, $xmlQuery)
		case element(quotepara) return atomlib:para($node, $xmlQuery)
		case element(email) return atomlib:email($node, $xmlQuery)
		case element(url) return atomlib:url($node, $xmlQuery)
		case element(footer) return atomlib:footer($node, $xmlQuery)
		case element(quotefooter) return atomlib:footer($node, $xmlQuery)

		case element(inner-message) return atomlib:innerMessage($node, $xmlQuery)
		case element(inner-from) return atomlib:from($node, $xmlQuery)
		case element(inner-subject) return atomlib:subject($node, $xmlQuery)
		case element(inner-date) return atomlib:inner-date($node, $xmlQuery)
		case element(inner-to) return atomlib:to($node, $xmlQuery)
		case element(inner-cc) return atomlib:cc($node, $xmlQuery)
		case element(inner-body) return atomlib:quote($node, $xmlQuery)
		case element(inner-attachments) return atomlib:attachments($node, $xmlQuery)
		case element(inner-para) return atomlib:para($node, $xmlQuery)

		case element(strong) return <xhtml:strong>{ atomlib:dispatch($node, $xmlQuery) }</xhtml:strong>

		case element(br) return <xhtml:br/>

		default return ()
}

define function atomlib:subject(
	$subject as element(),
	$xmlQuery as element(search)
) as element(xhtml:tr)
{
	<xhtml:tr>
		<xhtml:th style="text-align: right; font-weight: normal">Subject:</xhtml:th>
		<xhtml:td>{
				if(exists($subject/node()))
				then $subject/node()
				else (attribute style { "font-style:italic" }, "(No subject)")
		}</xhtml:td>
	</xhtml:tr>
}

define function atomlib:from(
	$from as element(),
	$xmlQuery as element(search)
) as element(xhtml:tr)
{
	<xhtml:tr><xhtml:th style="text-align: right; font-weight: normal">From:</xhtml:th><xhtml:td>{
		if(exists($xmlQuery/term[@field = ("from", "sender")]))
		then <xhtml:strong>{ util:emailObfuscate(string($from/@personal)) }</xhtml:strong>
		else util:emailObfuscate(string($from/@personal))
	} ({ atomlib:email($from, $xmlQuery) })</xhtml:td></xhtml:tr>
}

(: ok :)
define function atomlib:date(
	$date as attribute(date),
	$xmlQuery as element(search)
) as element(xhtml:tr)
{
	<xhtml:tr><xhtml:th style="text-align: right; font-weight: normal">Date:</xhtml:th><xhtml:td>{ util:formattedDateTime(xs:dateTime($date), true()) }</xhtml:td></xhtml:tr>
}

(: XXX - not formatting inner dates because they are raw and unparsed :)
(: ok :)
define function atomlib:inner-date(
	$date as element(inner-date),
	$xmlQuery as element(search)
) as element(xhtml:tr)
{
	<xhtml:tr><xhtml:th style="text-align: right; font-weight: normal">Date:</xhtml:th><xhtml:td>{ string($date) }</xhtml:td></xhtml:tr>
}

(: ok :)
define function atomlib:list(
	$list as attribute(),
	$xmlQuery as element(search)
) as element(xhtml:tr)
{
	<xhtml:tr><xhtml:th style="text-align: right; font-weight: normal">List:</xhtml:th><xhtml:td>{ 
		if(exists($xmlQuery/term[@field = "list"]))
		then <xhtml:strong>{ string($list) }</xhtml:strong>
		else search:highlight(<xhtml:span>{ string($list) }</xhtml:span>, $xmlQuery)
	}</xhtml:td></xhtml:tr>
}

(: ok :)
define function atomlib:to(
	$to as element(),
	$xmlQuery as element(search)
) as element(xhtml:tr)
{
	<xhtml:tr><xhtml:th style="text-align: right; font-weight: normal">To:</xhtml:th><xhtml:td>{ atomlib:dispatch($to, $xmlQuery) }</xhtml:td></xhtml:tr>
}

(: ok :)
define function atomlib:cc(
	$cc as element(),
	$xmlQuery as element(search)
) as element(xhtml:tr)
{
	<xhtml:tr><xhtml:th style="text-align: right; font-weight: normal">CC:</xhtml:th><xhtml:td>{ atomlib:dispatch($cc, $xmlQuery) }</xhtml:td></xhtml:tr>
}

(: ok :)
define function atomlib:attachments(
	$attachments as element(),
	$xmlQuery as element(search)
) as element(xhtml:tr)?
{
	if(exists($attachments/attachment) or exists($attachments/inner-attachment))
	then
		<xhtml:tr><xhtml:th style="text-align: right; font-weight: normal">Attachments:</xhtml:th><xhtml:td>{
			let $id := string($attachments/ancestor::message/@id)
			let $previous-attachments := count($attachments/(preceding::attachment | preceding::inner-attachment))
			for $attachment at $i in $attachments/(attachment | inner-attachment)
			let $number := $i + $previous-attachments
			let $len := string-length($attachment/@file)
			let $label :=
				if(string-length($attachment/@file))
				then string($attachment/@file)
				else concat("Attachment ", $number)
			let $dllink := concat("/download.xqy?id=", $id, "&number=", $number)
			return
				<xhtml:div>
					<xhtml:a href="{ $dllink }" title="Download the attachment">{ $label } - { util:bytesToHuman($attachment/@size) }</xhtml:a>
				</xhtml:div>
		}</xhtml:td></xhtml:tr>
	else ()
}

(: ok :)
define function atomlib:truncated(
	$truncated as xs:string?
) as element()?
{
	if($truncated = "true")
	then <xhtml:tr><xhtml:th style="text-align: right; font-weight: normal">Note:</xhtml:th><xhtml:td>This is a very long message, its output has been truncated.</xhtml:td></xhtml:tr>
	else ()
}

define function atomlib:body(
	$body as element(),
	$xmlQuery as element(search)
) as element(xhtml:div)
{
	<xhtml:div>{ atomlib:dispatch($body, $xmlQuery) }</xhtml:div>
}

define function atomlib:para(
	$para as element(),
	$xmlQuery as element(search)
) as element(xhtml:p)
{
	<xhtml:p xml:space="preserve" style="white-space: pre; margin: 0px; padding: 0px;">{ atomlib:dispatch($para, $xmlQuery) }</xhtml:p>
}

define function atomlib:url(
	$url as element(),
	$xmlQuery as element(search)
) as element(xhtml:a)?
{
	(: If the URL includes an email, ignore the fact it's a URL :)
	if($url[email])
	then atomlib:dispatch($url, $xmlQuery)
	(: If the URL looks like it has a link to our subscribed user acct, suppress it :)
	(: For some reason cts:contains works with /message/msgid but not message.xqy?id=msgid :)
	(: So I'm using regular contains here and assuming lower case :)
	else if (contains($url, "%40a.markmail.org") or contains($url, "%40b.markmail.org"))
	then ()
	else <xhtml:a href="{ string($url) }">{ string($url) }</xhtml:a>
}

define function atomlib:footer(
	$footer as element(),
	$xmlQuery as element(search)
) as element(xhtml:div)?
{
	(: Don't let an auto-added list footer reveal our sub address :)
	if (cts:contains($footer, cts:or-query(("a.markmail.org", "b.markmail.org"))) or $footer/@type = ("virus-scan", "free-hosting", "sponsored"))
	then ()
	else <xhtml:div style="{ atomlib:getFooterStyle($footer/@type) }"><xhtml:p xml:space="preserve">{ atomlib:dispatch($footer, $xmlQuery) }</xhtml:p></xhtml:div>
}

define function atomlib:email(
	$email as element(),
	$xmlQuery as element(search)
) as element(xhtml:span)?
{
	let $addr := if(name($email) = "email") then string($email) else string($email/@address)
	where not($addr = "" or contains($addr, "@a.markmail.org") or contains($addr, "@b.markmail.org") or contains($addr, "ignore@markmail.org"))
	return util:emailObfuscate($addr)
}

define function atomlib:quote(
	$quote as element(),
	$xmlQuery as element(search)
) as element(xhtml:div)
{
	let $depth := if($quote/@depth castable as xs:integer) then xs:integer($quote/@depth) else 0
	let $count := count($quote/ancestor::inner-message) + $depth
	return
		<xhtml:div style="{ atomlib:getQuoteStyle($count) }">{ atomlib:dispatch($quote, $xmlQuery) }</xhtml:div>
}

define function atomlib:innerMessage(
	$innerMessage as element(inner-message),
	$xmlQuery as element(search)
) as element(xhtml:div)
{
	<xhtml:div style="{ atomlib:getQuoteStyle(count($innerMessage/ancestor-or-self::inner-message)) }">
		<xhtml:table style="border: 1px solid #ccc; margin-bottom: 10px; background-color: #ddd;"><xhtml:tbody>{ (
			atomlib:process(($innerMessage/inner-headers/inner-subject)[1], $xmlQuery),
			atomlib:process(($innerMessage/inner-headers/inner-from)[1], $xmlQuery),
			atomlib:process(($innerMessage/inner-headers/inner-date)[1], $xmlQuery),
			atomlib:process($innerMessage/inner-attachments, $xmlQuery),
			atomlib:truncated($innerMessage/inner-body/@overflow)
		) }</xhtml:tbody></xhtml:table>
		<xhtml:div style="padding-top: 5px; padding-left: 10px;">{
			atomlib:dispatch($innerMessage/inner-body, $xmlQuery)
		}</xhtml:div>
	</xhtml:div>
}

define function atomlib:getQuoteStyle(
	$level as xs:integer
) as xs:string
{
	if($level = (1, 4, 7))
	then "padding-left: 10px; color: blue; border-left: 2px solid blue;"
	else if($level = (2, 5, 8))
	then "padding-left: 10px; color: green; border-left: 2px solid green;"
	else if($level = (3, 6, 9))
	then "padding-left: 10px; color: #661C1C; border-left: 2px solid #661C1C;"
	else "padding-left: 10px;"
}

define function atomlib:getFooterStyle(
	$type as xs:string
) as xs:string
{
	if($type = ("list-management", "legalese"))
	then "font-style: italic; white-space: pre; color: #999;"
	else "font-style: italic; white-space: pre;"
}
