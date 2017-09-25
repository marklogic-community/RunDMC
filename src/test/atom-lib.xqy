xquery version "1.0-ml";

module namespace t = "http://github.com/robwhitby/xray/test";

import module namespace at="http://github.com/robwhitby/xray/assertions" at "/xray/src/assertions.xqy";

import module namespace atom = "http://www.marklogic.com/blog/atom" at "/lib/atom-lib.xqy";

declare namespace w3c-atom = "http://www.w3.org/2005/Atom";

declare option xdmp:mapping "false";

declare %t:case function t:next-link-first-page()
{
  at:equal(
    atom:next-link("http://dmc.com/recipe/atom.xml", fn:true(), 1),
    <link xmlns="http://www.w3.org/2005/Atom" href="http://dmc.com/recipe/atom.xml?page=2" rel="next"/>
  )
};

declare %t:case function t:next-link-second-page()
{
  at:equal(
    atom:next-link("http://dmc.com/recipe/atom.xml?page=2", fn:true(), 2),
    <link xmlns="http://www.w3.org/2005/Atom" href="http://dmc.com/recipe/atom.xml?page=3" rel="next"/>
  )
};

declare %t:case function t:next-link-second-page-no-more()
{
  at:equal(
    atom:next-link("http://dmc.com/recipe/atom.xml?page=2", fn:false(), 2),
    ()
  )
};

declare %t:case function t:prev-link-first-page()
{
  at:equal(
    atom:prev-link("http://dmc.com/recipe/atom.xml", 1),
    ()
  )
};

declare %t:case function t:prev-link-first-page-explicit()
{
  at:equal(
    atom:prev-link("http://dmc.com/recipe/atom.xml?page=1", 1),
    ()
  )
};

declare %t:case function t:prev-link-second-page()
{
  at:equal(
    atom:prev-link("http://dmc.com/recipe/atom.xml?page=2", 2),
    <link xmlns="http://www.w3.org/2005/Atom" href="http://dmc.com/recipe/atom.xml?page=1" rel="prev"/>
  )
};

declare %t:case function t:entry()
{
  let $actual :=
    atom:entry(
      "/blog/els-performance.xml",
      <ml:Post status="Published"
        xmlns:ml="http://developer.marklogic.com/site/internal">
        <ml:title>Element Level Security Performance</ml:title>
        <ml:author>Silvano Ravotto</ml:author>
        <ml:created>2017-06-20T04:32:56.0152-07:00</ml:created>
        <ml:last-updated>2017-06-23T04:09:50.383939-07:00</ml:last-updated>
        <ml:topic-tag/>
        <ml:short-description>short description</ml:short-description>
        <ml:tags>
          <ml:tag>security</ml:tag>
          <ml:tag>performance</ml:tag>
          <ml:tag>element-level security</ml:tag>
          <ml:tag>ml9</ml:tag>
        </ml:tags>
        <ml:body>body</ml:body>
      </ml:Post>
    )
  let $expected :=
    <entry xmlns="http://www.w3.org/2005/Atom">
      <id>http://localhost:8012/blog/els-performance.xml</id>
      <link href="http://localhost:8012/blog/els-performance"/>
      <title>Element Level Security Performance</title>
      <author>
        <name>Silvano Ravotto</name>
      </author>
      <updated>2017-06-23T04:09:50.383939-07:00</updated>
      <published>2017-06-20T04:32:56.0152-07:00</published>
      <content type="html">&lt;ml:body xmlns:ml="http://developer.marklogic.com/site/internal"&gt;body&lt;/ml:body&gt;</content>
    </entry>
  return (
    (: Can't just deep-equal this, as the server:port will vary depending on
     : where it's run. :)
    at:true(fn:matches($actual/w3c-atom:id, "http://[\w\.]+(:\d+)?/blog/els-performance"),
      "id does not match: " || $actual/w3c-atom:id),
    at:true(fn:matches($actual/w3c-atom:link/@href, "http://[\w\.]+(:\d+)?/blog/els-performance"),
      "Link does not match: " || $actual/w3c-atom:link/@href),
    at:equal($actual/w3c-atom:title, $expected/w3c-atom:title),
    at:equal($actual/w3c-atom:author, $expected/w3c-atom:author),
    at:equal($actual/updated, $expected/updated),
    at:equal($actual/published, $expected/published),
    at:equal($actual/content, $expected/content)
  )
};
