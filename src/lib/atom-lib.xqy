xquery version "1.0-ml";

module namespace atom = "http://www.marklogic.com/blog/atom";

import module namespace s = "http://marklogic.com/rundmc/server-urls" at "/controller/server-urls.xqy";

declare namespace ml= "http://developer.marklogic.com/site/internal";

declare namespace w3atom = "http://www.w3.org/2005/Atom";

declare option xdmp:mapping "false";

declare function atom:next-link($base-url, $more, $page)
{
  if ($more) then
    element { fn:QName("http://www.w3.org/2005/Atom", "link") } {
      attribute href {
        if (fn:matches($base-url, "page=")) then
          fn:replace($base-url, "page=" || $page, "page=" || $page + 1)
        else if (fn:matches($base-url, "\?")) then
          $base-url || "&amp;page=" || $page + 1
        else
          $base-url || "?page=" || $page + 1

      },
      attribute rel { "next" }
    }
  else ()
};

declare function atom:prev-link($base-url, $page)
{
  if ($page gt 1) then
    element { fn:QName("http://www.w3.org/2005/Atom", "link") } {
      attribute href {
        fn:replace($base-url, "page=" || $page, "page=" || $page - 1)
      },
      attribute rel { "prev" }
    }
  else ()
};

declare function atom:feed(
  $title as xs:string,
  $entries as element(w3atom:entry)*,
  $page as xs:integer,
  $more as xs:boolean (: are there more entries after these? :)
)
{
  let $server-url := xdmp:get-request-protocol() || ":" || $s:main-server
  let $base-url := $server-url || xdmp:get-original-url()
  return (
    '<?xml version="1.0" encoding="UTF-8"?>',
    <feed xmlns="http://www.w3.org/2005/Atom" xmlns:ml="http://developer.marklogic.com/site/internal">
      <title>{$title}</title>
      <link href="{ $base-url }" rel="self"/>
      <updated>{ current-dateTime() }</updated>
      <id>{$base-url}</id>
      <generator uri="{ $base-url }" version="1.0">MarkLogic Community</generator>
      <icon>{ $server-url }/favicon.ico</icon>
      <logo>{ $server-url }/media/marklogic-community-badge.png</logo>
      {
        atom:next-link($base-url, $more, $page),
        atom:prev-link($base-url, $page),
        $entries
      }
    </feed>
  )
};

declare function atom:recipe-entry($recipe as element(ml:Recipe))
{
  let $server-url := "http:" || $s:main-server
  let $uri := fn:base-uri($recipe)
  return
    <entry xmlns="http://www.w3.org/2005/Atom">
      <id>{$server-url || $uri}</id>
      <link>
        {
          attribute href {
            xdmp:get-request-protocol() || ":" || $s:main-server || fn:substring-before($uri, ".xml")
          }
        }
      </link>
      <title>{$recipe/ml:title/fn:string()}</title>
      {
        $recipe/ml:author ! <author><name>{./fn:string()}</name></author>,
        $recipe/ml:tags,
        $recipe/ml:min-server-version,
        $recipe/ml:max-server-version
      }
      <updated>{$recipe/ml:last-updated/fn:string()}</updated>
      <content type="application/xml">
        {
          $recipe/ml:problem,
          $recipe/ml:solution,
          $recipe/ml:privilege,
          $recipe/ml:index,
          $recipe/ml:discussion,
          $recipe/ml:see-also
        }
      </content>
    </entry>
};

declare function atom:entry($content)
{
  <entry xmlns="http://www.w3.org/2005/Atom">
    <id>{$content/ml:link/text()}</id>
    <link>
      {
        attribute href {
          let $uri := fn:base-uri($content)
          return
            if ((fn:starts-with($uri, "/blog/") or
                 fn:starts-with($uri, "/news/") or
                 fn:starts-with($uri, "/events/")) and
                fn:ends-with($uri, ".xml")) then
              "http://" || $s:main-server || fn:substring-before($uri, ".xml")
            else ()
        }
      }
    </link>
    <title>{$content/ml:title/text()}</title>
    {
      $content/ml:author ! <author><name>{./fn:string()}</name></author>
    }
    <updated> {
      if ($content/ml:last-updated/fn:string()) then
        $content/ml:last-updated/fn:string()
      else
        $content/ml:created/fn:string()
    }
    </updated>
    <published>{ $content/ml:created/fn:string() }</published>
    <content type="html">
      {
        if ($content/ml:body) then
          xdmp:quote(
            $content/ml:body,
            <options xmlns="xdmp:quote"><output-encoding>utf-8</output-encoding></options>
          )
        else if ($content/ml:description) then
          xdmp:quote(
            $content/ml:description//text(),
            <options xmlns="xdmp:quote"><output-encoding>utf-8</output-encoding></options>
          )
        else ()
      }
    </content>
  </entry>
};
