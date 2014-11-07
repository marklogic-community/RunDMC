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
  at "/apidoc/setup/raw-docs-access.xqy";
import module namespace stp="http://marklogic.com/rundmc/api/setup"
  at "/apidoc/setup/setup.xqm";

declare namespace apidoc="http://marklogic.com/xdmp/apidoc" ;

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
  (: Top-level anchor ID is simply "chapter".
   : Per #310 we do not actually use this chapter fragment,
   : but generating it is easier than not.
   :)
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
    let $id := substring-before(substring-after($href, '#id('), ')')
    (: Always rewrite to the last ID that appears,
     : so we have a canonical one we can script against in the TOC,
     : which also uses the last one present.
     : This is a hotspot, called for most A elements.
     :)
    let $id := ($target-doc//A[@ID eq $id])[1]/../A[@ID][last()]/@ID
    return concat('id_', $id))
};

declare function guide:starts-list(
  $e as element())
as xs:boolean
{
  (: Use instance of element as much as possible: faster than self axis. :)
  (: For when a note contains a list :)
  $e instance of element(Number)
  or $e instance of element(Body-bullet)
  (: Very expensive so try it last. :)
  or ($e instance of element(Note)
    and $e/following-sibling::*[1] instance of element(Body-bullet-2))
};

declare function guide:starts-or-ends-list(
  $e as element())
as xs:boolean
{
  (: Use instance of element as much as possible: faster than self axis. :)
  $e instance of element(Body-bullet)
  or $e instance of element(Number)
  or $e instance of element(EndList-root)
  (: For when a note contains a list :)
  or ($e instance of element(Body) and not($e/IMAGE))
  (: Very expensive so try it last. :)
  or ($e instance of element(Note)
    and $e/following-sibling::*[1] instance of element(Body-bullet-2))
};

declare function guide:ends-list(
  $e as element())
as xs:boolean
{
  (: Use instance of element as much as possible: faster than self axis. :)
  $e instance of element(EndList-root)
  or ($e instance of element(Body) and not($e/IMAGE))
};

declare function guide:is-before-end-of-list(
  $e as element())
as xs:boolean
{
  (: We assume that an element is included in the list,
   : unless it is a known end-of-list indicator
   : or one has appeared more recently than the most recent list start.
   : This is a hotspot, the worst in this code path.
   :)
  not(guide:ends-list($e))
  and ($e/preceding-sibling::*[
      guide:starts-or-ends-list(.) ][1]/guide:starts-list(.))[1]
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
  (: This is a hotspot. :)
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
  (: By default we just strip the start and end tags out. :)
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
  case element() return element { node-name($n) } {
    $n/@*,
    guide:flatten($n/node()) }
  default return $n
};

declare function guide:target-doc(
  $raw-docs as document-node()*,
  $fully-resolved-href as xs:string)
as document-node()*
{
  (: This is a hotspot.
   : In this form it is pretty well optimized.
   :)
  $raw-docs/*/XML/@original-file[ starts-with($fully-resolved-href, .) ]
  /root()
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
    concat(
      '#',
      guide:anchor-id-from-href(
        $fully-resolved-top-level-heading-references, $href, root($href))) }
  (: Links to other chapters (whether the same or a different guide) :)
  else if (contains($href, '#id(')) then (
    let $target-doc := guide:target-doc(
      $raw-docs, guide:fully-resolved-href($href))
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
    let $target-doc := guide:target-doc(
      $raw-docs, guide:fully-resolved-href($href))
    return (
      if ($target-doc) then () else guide:anchor-href-missing($href),
      attribute href {
        concat('/',
          substring-after($href, '#display.xqy?function=')) }))
  else $href
};

declare function guide:heading-anchor(
  $e as element(),
  $name as xs:string)
as element()+
{
  let $heading-level := 1 + number(substring-after($name, '-'))
  let $id := guide:heading-anchor-id($e)
  (: Beware of changing this structure without updating
   : the toc.xqm toc:guide-* functions, which depend on it.
   :)
  return (
    element a { attribute id { $id } },
    element { 'h'||$heading-level } {
      element a {
        attribute href { "#"||$id },
        attribute class { "sectionLink" },
        normalize-space($e) } })
};

(: This function converts a guide section id
 : to an appropriate href value.
 :)
declare function guide:heading-2message-href(
  $uri as xs:string,
  $id as xs:string)
as xs:string
{
  (: Non-message sections get a fragment reference. :)
  if (not(contains($uri, '/messages/'))) then ('#'||$id)
  (: #277 Message sections link to something like
   : /8.0/messages/XDMP-en/XDMP-BAD
   :)
  else concat(
    replace(
      $uri, '^/apidoc/(\d+\.\d+)/guide/(messages/[A-Z]+-[a-z]+).xml$',
      '/$2'),
    '/', $id)
};

declare function guide:anchor(
  $raw-docs as document-node()*,
  $fully-resolved-top-level-heading-references as xs:string*,
  $e as element(A))
as element(a)?
{
  (: Since we rewrite all links to point to the last anchor,
   : it is safe to drop any anchors that is not last.
   :)
  if ($e[@ID]/following-sibling::A) then ()
  (: Default :)
  else element a {
    (: Anchors may have @ID or @href or both. :)
    $e/@ID/attribute id { guide:full-anchor-id(.) },
    $e/@href/attribute href {
      guide:anchor-href(
        $raw-docs,
        $fully-resolved-top-level-heading-references,
        .) },
    guide:link-content($e) }
};

(: Extract one document per message. :)
declare function guide:convert-messages(
  $uri as xs:string,
  $guide as element(chapter))
as node()+
{
  if (not($stp:DEBUG)) then () else stp:debug('guide:convert-messages', ($uri)),
  let $base-uri := replace(
    replace($uri, '/guide/', '/'),
    '\.xml$', '/')
  (: #277 We want the same value that the guide pages use,
   : so we can find the right TOC entry at display time.
   :)
  let $guide-uri as xs:string := $guide/@guide-uri
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
      attribute guide-uri { $guide-uri },
      $message })
};

(: This is for development work only, so efficiency is not paramount. :)
declare function guide:convert-uri(
  $version as xs:string,
  $uri as xs:string)
as document-node()
{
  let $guide-docs := raw:guide-docs($version)
  return xdmp:xslt-invoke(
    '/apidoc/setup/convert-guide.xsl',
    $guide-docs[
      raw:target-guide-doc-uri(.) eq $uri] treat as node(),
    map:new(
      (map:entry('OUTPUT-URI', $uri),
        map:entry('RAW-DOCS', $guide-docs),
        map:entry(
          'FULLY-RESOLVED-TOP-LEVEL-HEADING-REFERENCES', 'DUMMY'))))
};

(: This is for development work only, so efficiency is not paramount. :)
declare function guide:convert-uri-profiled(
  $version as xs:string,
  $uri as xs:string)
as node()+
{
  let $guide-docs := raw:guide-docs($version)
  return prof:xslt-invoke(
    '/apidoc/setup/convert-guide.xsl',
    $guide-docs[
      raw:target-guide-doc-uri(.) eq $uri] treat as node(),
    map:new(
      (map:entry('OUTPUT-URI', $uri),
        map:entry('RAW-DOCS', $guide-docs),
        map:entry(
          'FULLY-RESOLVED-TOP-LEVEL-HEADING-REFERENCES', 'DUMMY'))))
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
  $raw-docs as document-node()+,
  $fully-resolved-top-level-heading-references as xs:string+,
  $g as document-node())
as node()+
{
  let $uri as xs:string := raw:target-guide-doc-uri($g)
  let $converted as node() := guide:convert(
    $raw-docs, $fully-resolved-top-level-heading-references,
    $uri, $g)
  let $messages := (
    if (not(contains($uri, '/messages/'))) then ()
    else guide:convert-messages($uri, $converted/(self::chapter|chapter)))
  return ($converted, $messages)
};

(: The input documents are consolidated raw guides,
 : not raw raw guides.
 : This is pretty slow, because it does massive amounts of node traversal.
 : The message guides tend to be slowest.
 :)
declare function guide:render(
  $raw-docs as document-node()+)
as empty-sequence()
{
  (: The slowest conversion is messages/XDMP-en.xml. :)
  (: TODO arrange to spawn these tasks, then wait for all to complete. :)
  let $fully-resolved-top-level-heading-references as xs:string+ := (
    for $orig in $raw-docs/chapter/XML[@original-file]
    let $orig-file as xs:string := $orig/@original-file
    return $orig/Heading-1/A/@ID/concat($orig-file, '#id(', ., ')'))
  for $g in $raw-docs
  let $start := xdmp:elapsed-time()
  for $c at $x in guide:render(
    $raw-docs, $fully-resolved-top-level-heading-references, $g)
  let $uri as xs:string := base-uri($c)
  let $_ := xdmp:document-insert($uri, $c)
  let $_ := if (not($stp:DEBUG)) then () else stp:debug(
    'guide:render',
    (base-uri($g), '=>', $uri,
      if ($x ne 1) then ()
      else ('in', xdmp:elapsed-time() - $start)))
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
  if (not($stp:DEBUG)) then () else stp:debug(
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
  $guide-config as element(apidoc:guide)?)
as empty-sequence()
{
  let $title-doc := doc(concat($dir, 'title.xml'))
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
  let $_ := if (not($stp:DEBUG)) then () else stp:debug(
    'guide:consolidate', (xdmp:describe($chapter-manifest)))
  return guide:consolidate-insert(
    $title-doc, $guide-title, $guide-title,
    $target-url, $dir, $final-guide-uri,
    (), $first-chapter-uri, (),
    $chapter-list)
};

declare function guide:consolidate(
  $version as xs:string)
as empty-sequence()
{
  (: The list of guide configs comes from the main database. :)
  let $guide-list as element()+ := api:document-list($version)//apidoc:guide
  (: Run the rest of the work in the raw database. :)
  return raw:invoke-function(
    function() {
      (: Directory in which to find guide XML for the server version :)
      let $guides-dir := concat("/", $version, "/xml/")
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
      let $guide-config as element()? := $guide-list[
        @source-name eq $dir-name ]
      where not($guide-config/@exclude)
      return guide:consolidate($version, $dir, $dir-name, $guide-config)
      ,
      xdmp:commit() },
    (: This is an update. :)
    true())
};

(: This function copies all guide images into place. :)
declare function guide:images(
  $version as xs:string,
  $guide-docs as node()*)
as empty-sequence()
{
  stp:info('guide:images', ($version, count($guide-docs))),
  for $doc in $guide-docs
  let $base-dir := $doc/(guide|chapter)/@original-dir/string()
  let $img-dir := api:guide-image-dir(raw:target-guide-doc-uri($doc))
  (: Copy every distinct image referenced by this guide.
   : Images are not shared across guides.
   :)
  for $img-path in distinct-values($doc//IMAGE/@href)
  let $source-uri as xs:string := resolve-uri($img-path, $base-dir)
  let $dest-uri := concat($img-dir, $img-path)
  let $_ := if (not($stp:DEBUG)) then () else stp:debug(
    'guide:images', ($source-uri, "to", $dest-uri))
  return xdmp:document-insert($dest-uri, raw:get-doc($source-uri))
};

(: This function copies all guide images into place. :)
declare function guide:images(
  $version as xs:string)
as empty-sequence()
{
  guide:images($version, raw:guide-docs($version))
};

declare function guide:sections(
  $level as xs:integer,
  $list as element()*,
  $heading-positions as xs:integer*)
as element()*
{
  (: If there are no heading positions that means we never had any.
   : See below for halting recursion when we run out.
   :)
  if (empty($heading-positions)) then $list else
  let $heading-position := $heading-positions[1]
  let $heading-positions-rest := subsequence($heading-positions, 2)
  let $section as element()+ := (
    if (exists($heading-positions-rest)) then subsequence(
      $list, $heading-position,
      $heading-positions-rest[1] - $heading-position)
    (: End of the list, so grab everything. :)
    else subsequence($list, $heading-position))
  let $heading := $section[1]
  let $heading-name := local-name($heading)
  return (
    (: Gather this section and recurse with its contents.
    if (not($stp:DEBUG)) then () else stp:debug(
      'guide:sections',
      ('level', $level,
        'list', count($list),
        'heading-positions', count($heading-positions),
        xdmp:describe($heading-positions),
        normalize-space($heading), count($section), xdmp:describe($section))),
     :)
    element div {
      attribute class {
        if (starts-with($heading-name, 'Simple-')) then 'message-part'
        else if ($heading-name eq 'Heading-2MESSAGE') then 'message'
        else if (starts-with($heading-name, 'Heading-')) then 'section'
        else '' },
      attribute data-fm-style { $heading-name },
      $heading,
      guide:sections(1 + $level, subsequence($section, 2)) },
    (: Recurse until the current level is complete. :)
    if (empty($heading-positions-rest)) then ()
    else guide:sections(
      $level, $list, $heading-positions-rest))
};

(: Capture flat sections in nested structure.
 : Turn something like this
 : <Heading-1>...
 : Into something like this:
 : <div class="section" data-fm-style="Heading-1">...
 : with nested content.
 :)
declare function guide:sections(
  $level as xs:integer,
  $list as element()*)
as element()*
{
  if (empty($list)) then () else
  (: Find all the headings for the current level,
   : and gather them into div elements.
   :)
  let $current-heading := concat('Heading-', $level)
  let $simple-heading := concat('Simple-', $current-heading)
  (: Discover the position of each heading in this section
   : and at this level.
   :)
  let $heading-positions := (
    for $e at $x in $list
    let $name := local-name($e)
    where (
      $name eq $simple-heading
      or starts-with($name, $current-heading))
    return $x)
  return (
    (: The list may not have any headings,
     : and may not start with a heading.
     if (not($stp:DEBUG)) then () else stp:debug(
      'guide:sections',
      ('level', $level,
        'list', count($list), xdmp:describe($list),
        'heading-positions', count($heading-positions),
        xdmp:describe($heading-positions))),
     :)
    if (not($heading-positions)) then $list
    else (
      let $first := $heading-positions[1]
      where $first gt 1
      return subsequence($list, 1, $first - 1)
      ,
      guide:sections($level, $list, $heading-positions)))
};

(: Capture flat sections in nested structure.
 : This replaces the old XSL capture-sections code.
 : Input will be something like a guide chapter in consolidated raw form.
 :)
declare function guide:sections(
  $raw as element())
as element()
{
  (: First we strip out some unhelpful hierarchy. :)
  let $flat as element() := guide:flatten($raw)
  return element { node-name($flat) } {
    $flat/namespace::*,
    $flat/@*,
    $flat/node() ! (
      typeswitch(.)
      case element(XML) return element XML {
        namespace::*,
        (: Preserve input URI. :)
        base-uri($raw) ! attribute xml:base { . },
        @*,
        guide:sections(1, *) }
      default return .) }
};

(: apidoc/setup/guide.xqm :)