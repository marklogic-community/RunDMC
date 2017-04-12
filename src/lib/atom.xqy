xquery version "1.0-ml";

import module namespace atom = "http://www.marklogic.com/blog/atom" at "atom-lib.xqy";

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
let $page := xs:integer(xdmp:get-request-field("page", "1"))
let $page-size := 10
return (
  if ($feed = "recipes") then
    let $recipe-count := xdmp:estimate(/ml:Recipe)
    let $start := ($page - 1) * $page-size + 1
    let $end := $start + $page-size - 1
    let $_ := xdmp:log("atom: feed=" || $feed || "; start=" || $start || "; end=" || $end)
    return
      atom:feed(
        "MarkLogic Recipes",
        for $recipe in (/ml:Recipe)[$start to $end]
        order by $recipe/ml:last-updated descending
        return atom:recipe-entry($recipe),
        $page, $recipe-count gt $end
      )
  else
    (: preserve original functionality :)
    let $posts :=
      for $r in (fn:doc()/ml:Post[@status="Published"],
                 fn:doc()/ml:Announcement[@status="Published"],
                 fn:doc()/ml:Event[@status="Published"])
      where not(starts-with(base-uri($r), "/preview"))
      order by xs:dateTime($r/ml:created/text()) descending
      return $r
    return
      atom:feed(
        "MarkLogic Community Blog",
        for $p in $posts [1 to $MAX_ENTRIES]
        order by xs:dateTime($p/ml:created/text()) descending
        return
          atom:entry($p),
        1, fn:false()
      )
)
