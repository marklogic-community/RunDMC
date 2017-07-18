xquery version "1.0-ml";

import module namespace search = "http://marklogic.com/appservices/search"
  at "/MarkLogic/appservices/search/search.xqy";

declare namespace ml = "http://developer.marklogic.com/site/internal";

declare variable $PAGE-SIZE := 10;

declare function local:neaten($str)
{
  fn:replace(fn:normalize-space($str), '"', '%22')
};

xdmp:set-response-content-type("application/json"),

let $tags as xs:string* :=
  fn:string-join(
    fn:tokenize(xdmp:get-request-field("tags"), ";;") ! ('tag:"' || . || '"'),
    " "
  )
let $text as xs:string := xdmp:get-request-field("text", "")
let $page := try { xs:int(xdmp:get-request-field("p", "1")) } catch ($e) { 1 }
let $start := ($page - 1) * $PAGE-SIZE + 1
let $end := $start + $PAGE-SIZE - 1
let $query :=
  cts:and-query((
    if (fn:exists($tags)) then
      cts:and-query((
        $tags ! cts:element-value-query(xs:QName("ml:tag"), .)
      ))
    else(),
    if (fn:exists($text)) then
      cts:word-query($text)
    else ()
  ))
let $options :=
  <options xmlns="http://marklogic.com/appservices/search">
    <additional-query>
      <cts:and-query xmlns:cts="http://marklogic.com/cts">
        <cts:directory-query depth="infinity">
          <cts:uri>/recipe/</cts:uri>
        </cts:directory-query>
        <cts:element-attribute-value-query>
          <cts:element xmlns:ml="http://developer.marklogic.com/site/internal">ml:Recipe</cts:element>
          <cts:attribute>status</cts:attribute>
          <cts:text xml:lang="en">Published</cts:text>
        </cts:element-attribute-value-query>
      </cts:and-query>
    </additional-query>
    <transform-results apply="raw"/>
    <constraint name="tag">
      <range type="xs:string" collation="http://marklogic.com/collation/en/S1" facet="true">
        <element ns="http://developer.marklogic.com/site/internal" name="tag"/>
      </range>
    </constraint>
  </options>
let $results :=
(:
  cts:search(
    fn:doc(),
    $query
  )[$start to $end]
:)
  search:search($text || " " || $tags, $options, $start, $end)
return
(:
  $results
:)
  '{' ||
    fn:string-join(
      (
        '"total":' || $results/@total,
        '"pages":' || fn:ceiling(($results/@total) div $PAGE-SIZE),
        '"start":' || $start,
        '"end":' || fn:min(($end, $results/@total/fn:data())),
        '"recipes": [' ||
          fn:string-join(
            for $recipe in $results/search:result
            return
              '{' ||
                '"title":"' || local:neaten($recipe/ml:Recipe/ml:title/fn:string()) || '",' ||
                '"url":"' || fn:replace($recipe/@uri, ".xml", "") || '",' ||
                '"problem":"' || local:neaten($recipe/ml:Recipe/ml:problem/fn:string()) || '",' ||
                '"minVersion":"' || local:neaten($recipe/ml:Recipe/ml:min-server-version/fn:string()) || '",' ||
                '"maxVersion":"' || local:neaten($recipe/ml:Recipe/ml:max-server-version/fn:string()) || '",' ||
                '"tags":' || '[' ||
                  fn:string-join($recipe/ml:Recipe/ml:tags/ml:tag/fn:string() ! ('"' || . || '"'), ', ') ||
                ']' ||
              '}',
            ', '
          ) ||
        ']',
        '"tags": [' ||
          fn:string-join(
            for $tag in $results/search:facet[./@name="tag"]/search:facet-value
            return
              '{ "name": "' || $tag/@name || '", "count": ' || $tag/@count || '}',
            ", "
          ) ||
        ']'
      ), ','
    ) ||
  '}'
