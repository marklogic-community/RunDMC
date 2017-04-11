xquery version "1.0-ml";

module namespace atom = "http://www.marklogic.com/blog/atom";

import module namespace s = "http://marklogic.com/rundmc/server-urls" at "/controller/server-urls.xqy";

declare namespace ml= "http://developer.marklogic.com/site/internal";

declare namespace w3atom = "http://www.w3.org/2005/Atom";

declare option xdmp:mapping "false";

declare function atom:feed(
  $title as xs:string,
  $entries as element(w3atom:entry)*
)
{
  '<?xml version="1.0" encoding="UTF-8"?>',
  <feed xmlns="http://www.w3.org/2005/Atom">
    <title>{$title}</title>
    <subtitle></subtitle>
    <link href="{ $s:main-server || xdmp:get-original-url() }" rel="self"/>
    <updated>{ current-dateTime() }</updated>
    <id></id>
    <generator uri="{ $s:main-server || xdmp:get-original-url() }" version="1.0">MarkLogic Community</generator>
    <icon>{ $s:main-server }/favicon.ico</icon>
    <logo>{ $s:main-server }/media/marklogic-community-badge.png</logo>
    { $entries }
  </feed>
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
    <author><name>{$content/ml:author//text()}</name></author>
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
