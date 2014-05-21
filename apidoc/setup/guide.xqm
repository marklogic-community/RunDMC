xquery version "1.0-ml";
(: setup functions for guides. :)

module namespace guide="http://marklogic.com/rundmc/api/guide" ;

declare default function namespace "http://www.w3.org/2005/xpath-functions";

import module namespace ml="http://developer.marklogic.com/site/internal"
  at "/model/data-access.xqy";
import module namespace u="http://marklogic.com/rundmc/util"
  at "/lib/util-2.xqy";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";
import module namespace raw="http://marklogic.com/rundmc/raw-docs-access"
  at "raw-docs-access.xqy";
import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "setup.xqm";

declare namespace xhtml="http://www.w3.org/1999/xhtml" ;

declare function guide:full-anchor-id($ID-att as xs:string)
as xs:string
{
  concat('id_', $ID-att)
};

declare function guide:anchor-id-for-top-level-heading(
  $heading-1 as element(Heading-1))
{
  guide:basename-stem($heading-1/ancestor::XML/@original-file)
};

declare function guide:heading-anchor-id(
  $e as element())
as xs:string
{
  typeswitch($e)
  (: Top-level anchor ID is simply "chapter" :)
  case element(Heading-1) return 'chapter'
  (: Otherwise use only the last A/@ID inside the heading,
   : since all links get rewritten to the last one.
   :)
  default return guide:full-anchor-id($e/A[@ID][last()]/@ID)
};

declare function guide:basename-stem($url as xs:string)
as xs:string
{
  substring-before(guide:basename($url),'.xml')
};

declare function guide:basename($url as xs:string)
{
  tokenize($url,'/')[last()]
};

declare function guide:doc-url(
  $guide as document-node()?)
as xs:string?
{
  (: if absent, then it's a bad link :)
  $guide/ml:external-uri-for-string(raw:target-guide-doc-uri(.))
};

declare function guide:fully-resolved-href(
  $href as attribute(href))
as xs:string
{
  resolve-uri($href, $href/ancestor::XML/@original-file)
};

declare function guide:anchor-id-from-href(
  $fully-resolved-top-level-heading-references as xs:string*,
  $href as attribute(href),
  $target-doc as document-node())
as xs:string?
{
  let $resolved-href := guide:fully-resolved-href($href)
  let $is-top-level-section-link := (
    $resolved-href = $fully-resolved-top-level-heading-references)
  where not($is-top-level-section-link)
  return (
    (: The section name of the guide :)
    (: Leave out the _12345 part if we are linking to a top-level section :)
    let $id := guide:extract-id-from-href($href)
    (: Always rewrite to the last ID that appears,
     : so we have a canonical one we can script against in the TOC,
     : which also uses the last one present. :)
    let $canonical-fragment-id := $target-doc//*[A/@ID=$id]/A[@ID][last()]/@ID
    return concat('id_', $canonical-fragment-id))
};

declare function guide:extract-id-from-href(
  $href as xs:string)
as xs:string
{
  substring-before(substring-after($href,'#id('),')')
};

declare function guide:starts-list(
  $e as element())
as xs:boolean
{
  (: For when a note contains a list :)
  $e/self::Number
  or $e/self::Body-bullet
  or $e/self::Note[following-sibling::*[1]/self::Body-bullet-2]
};

declare function guide:ends-list(
  $e as element())
as xs:boolean
{
  $e/self::EndList-root
  or $e/self::Body[not(IMAGE)]
};

declare function guide:is-before-end-of-list($e)
as xs:boolean
{
  let $most-recent-start-or-end-element := $e/preceding-sibling::*[
    guide:starts-list(.) or guide:ends-list(.)][1]
  (: We assume that an element is included in the list,
   : unless it is a known end-of-list indicator
   : or one has appeared more recently than the most recent list start.
   :)
  return (
    not(guide:ends-list($e))
    and $most-recent-start-or-end-element[guide:starts-list(.)])
};

declare function guide:is-part-of-list($e)
as xs:boolean
{
  guide:starts-list($e)
  or guide:is-before-end-of-list($e)
};

declare function guide:new-name($e as element())
as xs:string?
{
  typeswitch($e)
  (: Some need to be set to lower-case :)
  case element(TABLE) return 'table'
  case element(TH) return 'th'
  (: Others need to be renamed :)
  case element(Body) return 'p'
  case element(Body-indent) return 'p'
  case element(Body-indent-blockquote) return 'p'
  case element(Bold) return 'strong'
  case element(CELL) return 'td'
  case element(CellBody) return 'p'
  case element(Code) return 'pre'
  case element(CodeLeft) return 'pre'
  case element(CodeNoIndent) return 'pre'
  case element(Emphasis) return 'em'
  case element(ROW) return 'tr'
  (: By default, we just strip the start and end tags out :)
  default return ()
};

declare function guide:link-content($e as element(A))
  as xs:string
{
  let $value := normalize-space($e)
  return (
    (: Remove apostrophe delimiters when present (assumption is they are the
     : first and last character in the string) and remove 'on page'.
     :)
    if (starts-with($value, "&apos;")) then (
      let $nopage := substring-before($value, ' on page')
      return substring($nopage, 2, string-length($nopage) - 2))
    (: Remove "on page 32" verbiage :)
    else if (contains($value, ' on page')) then substring-before(
      $value, ' on page')
    else $value)
};

declare function guide:attributes(
  $list as attribute()*)
as attribute()*
{
  (: This drops the attributes of most translated elements,
   : and lower-cases any that we want to keep.
   :)
  for $a in $list return typeswitch($a)
  case attribute(ROWSPAN) return (
    if ($a eq 1) then () else attribute rowspan { $a })
  case attribute(COLSPAN) return (
    if ($a eq 1) then () else attribute colspan { $a })
  default return ()
};

declare function guide:metadata($e as element())
as element()?
{
  typeswitch($e)
  case element(chapter) return ()
  (: metadata from title.xml :)
  case element(guide) return element info {
    element version {
      $e/XML/Version/string() },
    element date {
      $e/XML/Date/string() },
    element revision {
      $e/XML/DateRev/string() } }
  default return stp:error('UNEXPECTED', xdmp:describe($e))
};

(: This flattens the structure of the raw XML. :)
declare function guide:flatten($n as node())
as node()?
{
  typeswitch($n)
  (: These container elements apparently add no value for list detection.
   : They appear inconsistently.
   :)
  case element(NumberList) return guide:flatten($n/node())
  case element(NumberAList) return guide:flatten($n/node())
  case element(WarningList) return guide:flatten($n/node())
  (: Rewrite Number1 as Number :)
  case element(Number1) return element Number {
    $n/@*,
    guide:flatten($n/node()) }
  (: Rewrite NumberA1 as NumberA :)
  case element(NumberA1) return element NumberA {
    $n/@*,
    guide:flatten($n/node()) }
  default return $n
};

declare function guide:target-doc(
  $raw-docs as document-node()*,
  $href as attribute())
as document-node()*
{
  $raw-docs[
    starts-with(
      guide:fully-resolved-href($href),
      */XML/@original-file)]
};

declare function guide:anchor-href-missing(
  $href as attribute(href))
as empty-sequence()
{
  stp:warning(
    'guide:anchor-href',
    ('BAD LINK FOUND!',
      'Unable to find referenced title or chapter doc for this link:',
      xdmp:describe($href), $href/string()))
};

declare function guide:anchor-href(
  $raw-docs as document-node()*,
  $fully-resolved-top-level-heading-references as xs:string*,
  $href as attribute(href))
as attribute(href)
{
  (: Links within the same chapter :)
  if (contains($href, '#id(')
    and starts-with(
      $href, guide:basename(base-uri($href)))) then attribute href {
    let $target-doc := root($href)
    return concat(
      '#',
      guide:anchor-id-from-href(
        $fully-resolved-top-level-heading-references, $href, $target-doc)) }
  (: Links to other chapters (whether the same or a different guide) :)
  else if (contains($href,'#id(')) then (
    let $target-doc := guide:target-doc($raw-docs, $href)
    return (
      if ($target-doc) then () else guide:anchor-href-missing($href),
      attribute href {
        concat(
          guide:doc-url($target-doc),
          '#',
          guide:anchor-id-from-href(
            $fully-resolved-top-level-heading-references, $href, $target-doc)) }
      ))
  (: Fixup Linkerator links
   : Change "#display.xqy&function=" to "/"
   :)
  else if (starts-with($href, '#display.xqy?function=')) then (
    let $target-doc := guide:target-doc($raw-docs, $href)
    return (
      if ($target-doc) then () else guide:anchor-href-missing($href),
      attribute href {
        concat('/',
          substring-after($href, '#display.xqy?function=')) }))
  else $href
};

declare function guide:anchor(
  $raw-docs as document-node()*,
  $fully-resolved-top-level-heading-references as xs:string*,
  $e as element(A))
as element()?
{
  (: Since we rewrite all links to point to the last anchor,
   : it is safe to drop any anchors that is not last.
   :)
  if ($e[@id]/preceding-sibling::A) then ()
  (: Default :)
  else element a {
    (: Anchors may have @id or @href or both. :)
    $e/@ID ! attribute id { guide:full-anchor-id(.) },
    $e/@href ! attribute href {
      guide:anchor-href(
        $raw-docs,
        $fully-resolved-top-level-heading-references,
        $e/@href) },
    guide:link-content($e) }
};

(: Extract one document per message. :)
declare function guide:convert-messages(
  $uri as xs:string,
  $guide as element(chapter))
as node()+
{
  stp:debug('guide:convert-messages', ($uri)),
  let $base-uri := replace(
    replace($uri, '/guide/', '/'),
    '\.xml$', '/')
  (: TODO remove hack for duplicate ids in this content. :)
  let $seen := map:map()
  for $message in $guide//xhtml:div[xhtml:h3]
  let $id as xs:string := $message/xhtml:a/@id
  where not(map:contains($seen, $id))
  return (
    map:put($seen, $id, $id),
    ($base-uri||$id||'.xml')
    ! element message {
      attribute xml:base { . },
      attribute id { $id },
      $message })
};

declare function guide:convert(
  $raw-docs as node()+,
  $fully-resolved-top-level-heading-references as xs:string+,
  $uri as xs:string,
  $guide as document-node())
as node()
{
  xdmp:xslt-invoke(
    "convert-guide.xsl", $guide,
    map:new(
      (map:entry('OUTPUT-URI', $uri),
        map:entry('RAW-DOCS', $raw-docs),
        map:entry(
          'FULLY-RESOLVED-TOP-LEVEL-HEADING-REFERENCES',
          $fully-resolved-top-level-heading-references))))
};

(: The input documents are consolidated raw guides,
 : not raw raw guides.
 :)
declare function guide:render(
  $raw-docs as document-node()+)
as empty-sequence()
{
  (: The slowest conversion is messages/XDMP-en.xml. :)
  (: TODO arrange to spawn these tasks, then wait for all to complete. :)
  let $fully-resolved-top-level-heading-references as xs:string+ := (
    $raw-docs/chapter/XML/Heading-1/A/@ID/concat(
      ancestor::XML/@original-file, '#id(', ., ')'))
  for $g in $raw-docs
  let $start := xdmp:elapsed-time()
  let $uri as xs:string := raw:target-guide-doc-uri($g)
  let $converted as node() := guide:convert(
    $raw-docs, $fully-resolved-top-level-heading-references,
    $uri, $g)
  let $messages := (
    if (not(contains($uri, '/messages/'))) then ()
    (: Allow for porting the XSL to XQuery. :)
    else guide:convert-messages($uri, $converted/(self::chapter|chapter)))
  for $c in ($converted, $messages)
  let $uri as xs:string := base-uri($c)
  let $_ := xdmp:document-insert($uri, $c)
  let $_ := stp:debug(
    'guide:render',
    (base-uri($g), '=>', $uri,
      'in', xdmp:elapsed-time() - $start))
  return ()
};

(: This should run in the raw database. :)
declare function guide:consolidate-insert(
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
  as empty-sequence()
{
  stp:info(
    'guide:consolidate-insert',
    (xdmp:describe($doc), xdmp:describe($title),
      xdmp:describe($guide-title), $target-url)),
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

(: This should run in the raw database. :)
declare function guide:consolidate-chapter(
  $dir as xs:string,
  $guide-title as xs:string,
  $final-guide-uri as xs:string,
  $chapter as element(chapter))
as element(chapter)
{
  let $chapter-doc   := doc($chapter/@source-uri)
  let $chapter-num   := 1 + count($chapter/preceding-sibling::chapter)
  let $chapter-title := normalize-space($chapter-doc/XML/Heading-1)
  let $next as xs:string? := $chapter/following-sibling::chapter[1]/@final-uri
  let $previous := (
    $chapter/preceding-sibling::chapter[1]/@final-uri,
    $final-guide-uri)[1]
  let $_ := guide:consolidate-insert(
    $chapter-doc, $chapter-title, $guide-title,
    $chapter/@target-uri, $dir, $final-guide-uri,
    $previous, $next, $chapter-num, ())
  return element chapter {
    attribute href { $chapter/@final-uri },
    element chapter-title { $chapter-title } }
};

(: This should run in the raw database. :)
declare function guide:consolidate(
  $version as xs:string,
  $dir as xs:string,
  $dir-name as xs:string,
  $guide-config as element(guide)?)
as empty-sequence()
{
  let $title-doc := doc(concat($dir,'title.xml'))
  let $guide-title := $title-doc/XML/Title/normalize-space(.)
  let $url-name := (
    if ($guide-config) then $guide-config/@url-name
    else $dir-name)
  let $target-url   := concat("/",$version,"/guide/",$url-name,".xml")
  let $final-guide-uri := raw:target-guide-doc-uri-for-string($target-url)
  let $chapters := xdmp:directory($dir)[XML] except $title-doc
  (: In two stages,
   : so we can get the next and previous chapter links in the next stage.
   :)
  (: Get each chapter doc in order :)
  let $chapter-manifest := element chapters {
    for $doc in $chapters
    let $uri := base-uri($doc)
    let $chapter-file-name  := substring-after($uri, $dir)
    let $chapter-target-uri := concat(
      "/",$version,"/guide/",$url-name,"/",$chapter-file-name)
    order by number(normalize-space($doc/XML/pagenum))
    return element chapter {
      attribute source-uri {$uri},
      attribute target-uri {$chapter-target-uri},
      attribute final-uri {
        raw:target-guide-doc-uri-for-string($chapter-target-uri)} } }
  (: This inserts chapter documents and creates a manifest. :)
  let $chapter-list := element chapter-list {
    guide:consolidate-chapter(
      $dir, $guide-title, $final-guide-uri,
      (: Function mapping. :)
      $chapter-manifest/chapter) }
  let $first-chapter-uri := $chapter-manifest/chapter[1]/@final-uri
  let $_ := stp:info(
    'guide:consolidate', (xdmp:describe($chapter-manifest)))
  return guide:consolidate-insert(
    $title-doc, $guide-title, $guide-title,
    $target-url, $dir, $final-guide-uri,
    (), $first-chapter-uri, (),
    $chapter-list)
};

declare function guide:consolidate($version as xs:string)
  as empty-sequence()
{
  raw:invoke-function(
    function() {
      (: Directory in which to find guide XML for the server version :)
      let $guides-dir := concat("/", $version, "/xml/")
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
      let $guide-config as element(guide)? := $guide-list[
        @source-name eq $dir-name]
      where not($guide-config/@exclude)
      return guide:consolidate(
        $version, $dir, $dir-name, $guide-config)
      ,
      xdmp:commit(),
      stp:info('guide:consolidate', 'ok') },
    (: This is an update. :)
    true())
};

declare function guide:images(
  $version as xs:string)
as empty-sequence()
{
  stp:info('guide:images', $version),
  let $guide-docs as node()+ := raw:guide-docs($version)
  for $doc in $guide-docs
  let $base-dir := string($doc/(guide|chapter)/@original-dir)
  let $img-dir := api:guide-image-dir(raw:target-guide-doc-uri($doc))
  (: Copy every distinct image referenced by this guide.
   : Images are not shared across guides.
   :)
  for $img-path in distinct-values($doc//IMAGE/@href)
  let $source-uri := resolve-uri($img-path, $base-dir)
  let $dest-uri := concat($img-dir, $img-path)
  let $_ := stp:info('guide:images', ($source-uri, "to", $dest-uri))
  return xdmp:document-insert($dest-uri, raw:get-doc($source-uri))
};

(: apidoc/setup/guide.xqm :)