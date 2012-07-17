xquery version "1.0-ml";

(: This script is run in the raw database, setting up the URLs for the XML
   files for each guide, and adding a chapter list to the title doc. :)

import module namespace api="http://marklogic.com/rundmc/api"
       at "../model/data-access.xqy";

import module namespace u="http://marklogic.com/rundmc/util"
       at "../../lib/util-2.xqy";

import module namespace raw = "http://marklogic.com/rundmc/raw-docs-access"
       at "raw-docs-access.xqy";

(: Directory in which to find all the guide XML for the requested server version :)
declare variable $guides-dir := concat("/",$api:version,"/xml/");

(: One sub-dir for each guide :)
declare variable $sub-dirs := xdmp:directory-properties($guides-dir)/prop:properties/prop:directory/base-uri(.);

(: Just the name of each dir, not including the full path to it :)
declare function local:dir-name($dir) {
  substring-before(substring-after($dir, $guides-dir),"/")
};

(: The list of guide configs :)
declare variable $guide-list := u:get-doc("/apidoc/config/document-list.xml")/docs//guide;

declare function local:insert($doc,
                              $title,
                              $guide-title,
                              $target-url,
                              $orig-dir,
                              $guide-uri,
                              $previous as xs:string?,
                              $next as xs:string?,
                              $number as xs:integer?,
                              $chapter-list as element()?) {
  xdmp:log(concat("Setting up guide doc: ",$target-url)),
  xdmp:document-insert($target-url,
    element { if ($chapter-list) then "guide" else "chapter" } {
      attribute original-dir {$orig-dir},
      attribute guide-uri    {$guide-uri},

      if ($previous) then attribute previous {$previous} else (),
      if ($next)     then attribute next     {$next}     else (),
      if ($number)   then attribute number   {$number}   else (),

      <guide-title>{$guide-title}</guide-title>,
      <title>      {$title}      </title>,

      <XML original-file="{base-uri($doc)}">
        {$doc/XML/node()}
      </XML>,

      $chapter-list
    }
  )
};

for $dir in $sub-dirs return
  let $title-doc    := doc(concat($dir,'title.xml')),
      $guide-title  := $title-doc/XML/Title/normalize-space(.),
      $guide-config := $guide-list[local:dir-name($dir) eq @source-name],
      (: $guide-config := $guide-list[local:dir-name($dir) = tokenize(@source-names,' ')], :)
      $url-name     := if ($guide-config) then $guide-config/@url-name else local:dir-name($dir),
      $target-url   := concat("/",$api:version,"/guide/",$url-name,".xml"),
      $final-guide-uri := raw:target-guide-doc-uri-for-string($target-url)
  return
    if ($guide-config/@exclude) then () else

      let $chapters := xdmp:directory($dir)[XML] except $title-doc,

          (: In two stages, so we can get the next & previous chapter links in the next stage :)
          $chapter-manifest :=
            (: Get each chapter doc in order :)
            <chapters>{
               for $doc in $chapters
               let $uri := base-uri($doc),
                   $chapter-file-name  := substring-after($uri,$dir),
                   $chapter-target-uri := concat("/",$api:version,"/guide/",$url-name,"/",$chapter-file-name)
               order by number(normalize-space($doc/XML/pagenum))
               return <chapter source-uri="{$uri}"
                               target-uri="{$chapter-target-uri}"
                               final-uri ="{raw:target-guide-doc-uri-for-string($chapter-target-uri)}"/>
            }</chapters>,

          $chapter-list :=
            <chapter-list>{
              for $chapter in $chapter-manifest/chapter
              let $chapter-doc   := doc($chapter/@source-uri),
                  $chapter-title := normalize-space($chapter-doc/XML/Heading-1),
                  $previous      := if ($chapter/preceding-sibling::chapter) then $chapter/preceding-sibling::chapter[1]/@final-uri
                                                                             else $final-guide-uri,
                  $chapter-num   := 1 + count($chapter/preceding-sibling::chapter),
                  $next          := $chapter/following-sibling::chapter[1]/@final-uri
              return
                (
                  <chapter href="{$chapter/@final-uri}">
                    <chapter-title>{$chapter-title}</chapter-title>
                  </chapter>,
                  local:insert($chapter-doc, $chapter-title, $guide-title, $chapter/@target-uri, $dir, $final-guide-uri, $previous, $next, $chapter-num, ())
                )
            }</chapter-list>,

          $first-chapter-uri := $chapter-manifest/chapter[1]/@final-uri

      return
        (xdmp:log($chapter-manifest),
        local:insert($title-doc, $guide-title, $guide-title, $target-url, $dir, $final-guide-uri, (), $first-chapter-uri, (), $chapter-list)
        )

,xdmp:log("Done.")
