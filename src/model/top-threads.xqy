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

let $listSearch := if ($lists) then
    concat("list:", string-join((tokenize($lists, " ")), " list:"))
else 
    ""
let $search := concat($search, $listSearch, " order:date-backward")
let $url := concat("http://markmail.org/results.xqy?q=", encode-for-uri($search))
let $all := concat("http://markmail.org/search/", encode-for-uri($search))
let $doc := xdmp:http-get($url)[2]
let $first := concat("http://markmail.org/message", string(($doc/search/results/result/url)[1]))

let $threads := map:map()

return
<ml:threads all-threads-href="{$all}" start-thread-href="{$first}" xmlns:ml="http://developer.marklogic.com/site/internal"
            estimated-count="{$doc/search/estimation}">
{
for $result in $doc//result
let $url := concat("http://markmail.org/message/", encode-for-uri($result/id/text()))
let $title := replace(string($result/subject), "RE:", "", "i")
let $title := replace($title, "\[.*\]", "", "i")

return
    (: Now showing recent messages, not just recent threads
    if (map:get($threads, $title)) then
        ()
    else
        let $_ := map:put($threads, $title, <ok/>)
    :)
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
