(: TODO: Implement this query, based on the two parameters supplied :)
(: The first parameter "search" is an arbitrary search string.
   The second parameter "lists" is a space-separated list of mailing list names to constrain the search to.

   The function should still return results even if an empty string is passed in.
   Presumably in that case, the function should return the "top threads" for all ML-related
   mailing lists.
:)
declare variable $string as xs:string external;
declare variable $lists  as xs:string external;

(: The results should look something like this; each @href value should be an absolute URL
   which will be used to generate a clickable link :)

<ml:threads all-threads-href="..." start-thread-href="..." xmlns:ml="http://developer.marklogic.com/site/internal">
  <ml:thread title="MarkLogic Server 4.1 Rocks!!" href="..." date-time="2010-03-04T11:22" replies="2" views="14">
    <ml:author href="...">JoelH</ml:author>
    <ml:list href="...">Mark Logic General</ml:list>
  </ml:thread>
  <ml:thread title="Issue with lorem ipsum dolor" href="..." date-time="2009-09-23T13:22" replies="2" views="15">
    <ml:author href="...">Laderlappen</ml:author>
    <ml:list href="...">Mark Logic General</ml:list>
  </ml:thread>
  <ml:thread title="Lorem ipsum dolor sit amet" href="..." date-time="2009-09-24T23:22" replies="1" views="1">
    <ml:author href="...">Jane</ml:author>
    <ml:list href="...">Mark Logic General</ml:list>
  </ml:thread>
  <ml:thread title="Useful tips for NY meets" href="..." date-time="2009-09-26T13:22" replies="12" views="134">
    <ml:author href="...">JoelH</ml:author>
    <ml:list href="...">Mark Logic General</ml:list>
  </ml:thread>
  <ml:thread title="Lorem ipsum dolor sit amet" href="..." date-time="2009-10-03T10:37" replies="0" views="12">
    <ml:author href="...">JoelH</ml:author>
    <ml:list href="...">Mark Logic General</ml:list>
  </ml:thread>
</ml:threads>
