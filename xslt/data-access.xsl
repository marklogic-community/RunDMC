<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp"
  extension-element-prefixes="xdmp">

  <xdmp:import-module href="data-access.xqy" namespace="http://developer.marklogic.com/site/internal"/>

  <!-- TODO: reimplement this module in XQuery -->

  <xsl:variable name="collection" select="collection()"/>
  <!--
  <xsl:variable name="collection" select="collection('http://developer.marklogic.com/content-collection')"/>
  -->

  <!--
  <xsl:variable name="all-blog-posts" select="$collection/Post"/>
  -->

  <!-- TODO: refactor these repetitive functions -->

  <!--
  <xsl:function name="ml:latest-user-group-announcement">
    <xsl:for-each select="$collection/Announcement[string(@user-group)]">
      <xsl:sort select="date" order="descending"/>
      <xsl:if test="position() eq 1">
        <xsl:sequence select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:function>

  <xsl:function name="ml:latest-announcement">
    <xsl:for-each select="$collection/Announcement">
      <xsl:sort select="date" order="descending"/>
      <xsl:if test="position() eq 1">
        <xsl:sequence select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:function>
  -->


  <!--
  <xsl:function name="ml:future-events">
    <xsl:sequence select="$collection/Event[xs:date(details/date) >= current-date()]"/>
  </xsl:function>

  <xsl:function name="ml:next-two-user-group-events">
    <xsl:param name="group" as="xs:string"/>
    <xsl:variable name="events" select="if ($group eq '')
                                        then ml:future-events()[string(@user-group)]
                                        else ml:future-events()[@user-group eq $group]"/>
    <xsl:for-each select="$events">
      <xsl:sort select="details/date"/>
      <xsl:if test="position() le 2">
        <xsl:sequence select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:function>

  <xsl:function name="ml:next-event">
    <xsl:for-each select="ml:future-events()">
      <xsl:sort select="details/date"/>
      <xsl:if test="position() eq 1">
        <xsl:sequence select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:function>
  -->


  <xsl:function name="ml:latest-article">
    <xsl:param name="type"  as="xs:string"/>
    <xsl:variable name="articles" select="ml:lookup-articles($type, '')"/>
    <xsl:for-each select="$articles">
      <xsl:sort select="created" order="descending"/>
      <xsl:if test="position() eq 1">
        <xsl:sequence select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:function>

  <xsl:function name="ml:lookup-articles" as="element()*">
    <xsl:param name="type"  as="xs:string"/>
    <xsl:param name="topic" as="xs:string"/>
    <xsl:sequence select="$collection/Article[(($type  eq @type)        or not($type)) and
                                              (($topic =  topics/topic) or not($topic))]"/>
  </xsl:function>


  <xsl:function name="ml:recent-events" as="element()*">
    <xsl:param name="months" as="xs:integer"/>
    <xsl:variable name="duration" select="concat('P', $months, 'M')"/>
    <xsl:variable name="start-date" select="current-date() - xs:yearMonthDuration($duration)"/>
    <xsl:sequence select="$collection/Event[xs:date(details/date) >= $start-date]"/>
  </xsl:function>

  <xsl:function name="ml:recent-announcements" as="element()*">
    <xsl:param name="months" as="xs:integer"/>
    <xsl:variable name="duration" select="concat('P', $months, 'M')"/>
    <xsl:variable name="start-date" select="current-date() - xs:yearMonthDuration($duration)"/>
    <xsl:sequence select="$collection/Announcement[xs:date(date) >= $start-date]"/>
  </xsl:function>

  <xsl:function name="ml:get-threads">
    <xsl:param name="search" as="xs:string?"/>
    <xsl:param name="lists"  as="element()*"/>
    <!-- TODO: offload this to an XQuery script authored by someone else -->
    <ml:thread title="MarkLogic Server 4.1 Rocks!!" href="..." date-time="2010-03-04T11:22" replies="2" views="14">
      <ml:author href="...">JoelH</ml:author>
      <ml:list href="...">Mark Logic General</ml:list>
    </ml:thread>
    <ml:thread title="Issue with lorem ipsum dolor" date-time="2009-09-23T13:22" replies="2" views="15">
      <ml:author href="...">Laderlappen</ml:author>
      <ml:list href="...">Mark Logic General</ml:list>
    </ml:thread>
    <ml:thread title="Lorem ipsum dolor sit amet" date-time="2009-09-24T23:22" replies="1" views="1">
      <ml:author href="...">Jane</ml:author>
      <ml:list href="...">Mark Logic General</ml:list>
    </ml:thread>
    <ml:thread title="Useful tips for NY meets" date-time="2009-09-26T13:22" replies="12" views="134">
      <ml:author href="...">JoelH</ml:author>
      <ml:list href="...">Mark Logic General</ml:list>
    </ml:thread>
    <ml:thread title="Lorem ipsum dolor sit amet" date-time="2009-10-03T10:37" replies="0" views="12">
      <ml:author href="...">JoelH</ml:author>
      <ml:list href="...">Mark Logic General</ml:list>
    </ml:thread>
  </xsl:function>

</xsl:stylesheet>
