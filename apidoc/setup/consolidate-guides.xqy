xquery version "1.0-ml";

(: This script is run in the raw database, setting up the URLs for the XML
 : files for each guide, and adding a chapter list to the title doc.
 :)

import module namespace api="http://marklogic.com/rundmc/api"
  at "../model/data-access.xqy";

import module namespace u="http://marklogic.com/rundmc/util"
  at "../../lib/util-2.xqy";

import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "raw-docs-access.xqy";

declare function local:insert(
  $doc as node(),
  $title as xs:string?,
  $guide-title as xs:string?,
  $target-url as xs:string,
  $orig-dir as xs:string,
  $guide-uri as xs:string,
  $previous as xs:string?,
  $next as xs:string?,
  $number as xs:integer?,
  $chapter-list as element()?)
{
  xdmp:log(
    text {
      '[do-consolidate-guides:insert]', xdmp:describe($doc),
      xdmp:describe($title), xdmp:describe($guide-title), $target-url }),
  xdmp:document-insert(
    $target-url,
    element { if ($chapter-list) then "guide" else "chapter" } {
      attribute original-dir { $orig-dir },
      attribute guide-uri { $guide-uri },

      $previous ! attribute previous { . },
      $next ! attribute next { . },
      $number ! attribute number { . },

      element guide-title { $guide-title },
      element title { $title },

      element XML {
        attribute original-file { concat('file:',base-uri($doc)) },
        $doc/XML/node() },

      $chapter-list })
};

raw:invoke-function(
  function() {
    (: Directory in which to find guide XML for the server version :)
    let $guides-dir := concat("/", $api:version, "/xml/")
    (: The list of guide configs :)
    let $guide-list as element()+ := u:get-doc(
      "/apidoc/config/document-list.xml")/docs/*/guide
    (: Assume every guide has a title.xml document.
     : This might seem inefficient,
     : but consider that we will want to look at most of these documents.
     : Anyway we probably just loaded them, so they should be cached.
     :)
    let $directory-uris as xs:string+ := (
      xdmp:directory(
        $guides-dir, 'infinity')/xdmp:node-uri(.)[
        ends-with(., '/title.xml')]
      ! substring-before(., '/title.xml')
      ! concat(., '/'))
    for $dir in $directory-uris
    (: Basename of each dir, not including the full path to it :)
    let $dir-name := substring-before(
      substring-after($dir, $guides-dir), "/")
    let $title-doc := doc(concat($dir,'title.xml'))
    let $guide-title := $title-doc/XML/Title/normalize-space(.)
    let $guide-config := $guide-list[@source-name eq $dir-name]
    let $url-name := (
      if ($guide-config) then $guide-config/@url-name
      else $dir-name)
    let $target-url   := concat("/",$api:version,"/guide/",$url-name,".xml")
    let $final-guide-uri := raw:target-guide-doc-uri-for-string($target-url)
    where not($guide-config/@exclude)
    return (
      let $chapters := xdmp:directory($dir)[XML] except $title-doc
      (: In two stages,
       : so we can get the next and previous chapter links in the next stage.
       :)
      (: Get each chapter doc in order :)
      let $chapter-manifest := element chapters {
        for $doc in $chapters
        let $uri := base-uri($doc)
        let $chapter-file-name  := substring-after($uri,$dir)
        let $chapter-target-uri := concat(
          "/",$api:version,"/guide/",$url-name,"/",$chapter-file-name)
        order by number(normalize-space($doc/XML/pagenum))
        return element chapter {
          attribute source-uri {$uri},
          attribute target-uri {$chapter-target-uri},
          attribute final-uri {
            raw:target-guide-doc-uri-for-string($chapter-target-uri)} } }
      let $chapter-list := element chapter-list {
        for $chapter in $chapter-manifest/chapter
        let $chapter-doc   := doc($chapter/@source-uri)
        let $chapter-title := normalize-space($chapter-doc/XML/Heading-1)
        let $previous      := (
          $chapter/preceding-sibling::chapter[1]/@final-uri,
          $final-guide-uri)[1]
        let $chapter-num   := 1 + count($chapter/preceding-sibling::chapter)
        let $next          := $chapter/following-sibling::chapter[1]/@final-uri
        return (
          element chapter {
            attribute href { $chapter/@final-uri },
            element chapter-title { $chapter-title } },
          local:insert(
            $chapter-doc, $chapter-title, $guide-title,
            $chapter/@target-uri, $dir, $final-guide-uri,
            $previous, $next, $chapter-num,
            ())) }
      let $first-chapter-uri := $chapter-manifest/chapter[1]/@final-uri
      let $_ := xdmp:log(
        text {
          '[do-consolidate-guides]',
          xdmp:describe($chapter-manifest) })
      return local:insert(
        $title-doc, $guide-title, $guide-title,
        $target-url, $dir, $final-guide-uri,
        (), $first-chapter-uri, (),
        $chapter-list))
    ,
    xdmp:commit(),
    xdmp:log("[consolidate-guides.xqy] Done.") },
  true()),
"Done consolidating guides."

(: apidoc/setup/consolidate-guides.xqy :)