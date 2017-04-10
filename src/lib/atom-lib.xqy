xquery version "1.0-ml";

module namespace atom = "http://www.marklogic.com/blog/atom";

import module namespace s = "http://marklogic.com/rundmc/server-urls" at "/controller/server-urls.xqy";

declare namespace w3atom = "http://www.w3.org/2005/Atom";

declare option xdmp:mapping "false";

declare function atom:feed(
  $title as xs:string,
  $entries as element(w3atom:entry)*
)
{
  '<?xml version="1.0" encoding="UTF-8"?>',
  <feed xmlns="http://www.w3.org/2005/Atom">
    <title>$title</title>
    <subtitle></subtitle>
    <link href="{ $s:main-server }/blog/atom.xml" rel="self"/>
    <updated>{ current-dateTime() }</updated>
    <id></id>
    <generator uri="{ $s:main-server }/blog/atom.xml" version="1.0">MarkLogic Community</generator>
    <icon>{ $s:main-server }/favicon.ico</icon>
    <logo>{ $s:main-server }/media/marklogic-community-badge.png</logo>
    { $entries }
  </feed>
};
