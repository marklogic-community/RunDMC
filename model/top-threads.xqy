(: TODO: Implement this query, based on the two parameters supplied :)
(: The first parameter "search" is an arbitrary search string.
   The second parameter "lists" is a space-separated list of mailing list names to constrain the search to.

   The function should still return results even if an empty string is passed in.
   Presumably in that case, the function should return the "top threads" for all ML-related
   mailing lists.
:)

declare variable $search as xs:string external;
declare variable $lists  as xs:string external;

(: The results should look something like this; each @href value should be an absolute URL
   which will be used to generate a clickable link :)

let $search := concat($search, " order:date-backward")
let $url := concat("http://markmail.org/results.xqy?q=", $search)
let $all := concat("http://markmail.org/search/", $search)
let $doc := xdmp:http-get($url)[2]
let $first := concat("http://markmail.org/message", string($doc/results/result/url))

return
<ml:threads all-threads-href="{$all}" start-thread-href="{$first}" xmlns:ml="http://developer.marklogic.com/site/internal">
{
for $result in $doc//result
let $url := concat("http://markmail.org/message/", encode-for-uri($result/id/text()))
let $title := string($result/subject)
let $author := $result/from/text()
let $list := $result/list/text()
let $ahref := 
        if  (matches($author, "@")) then
            "#"
        else
            concat("http://markmail.org/search/?q=", 
                encode-for-uri(concat('from:"', $author, '" order:date-backward')))

let $lhref := concat("http://markmail.org/search/?q=", 
                encode-for-uri(concat('list:"', $list, '" order:date-backward')))
return
  <ml:thread title="{$title}" href="{$url}" date="{$result/date}">
    <ml:author href="{$ahref}" >{$author}</ml:author>
    <ml:list href="{$lhref}" >{$result/list/text()}</ml:list>
    <ml:blurb>{$result/blurb/*/text()}</ml:blurb>
  </ml:thread>
}
</ml:threads>
