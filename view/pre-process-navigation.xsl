<!-- This stylesheet pre-processes navigation.xml, specifically so it
     can be populated with blog post links, grouped in the various
     supported ways (by date, author, and category)>
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp">

  <xsl:template mode="pre-process-navigation" match="@* | node()">
    <xsl:copy>
      <xsl:apply-templates mode="#current" select="@* | node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- These three rules smell. Consider refactoring -->
  <xsl:template mode="pre-process-navigation" match="blog-posts-grouped-by-date">
    <xsl:variable name="unique-years" select="distinct-values($ml:Posts/created/year-from-dateTime(.))"/>
    <xsl:for-each select="$unique-years">
      <xsl:sort select="." order="descending"/>
      <xsl:variable name="posts-this-year" select="$ml:Posts[year-from-dateTime(created) eq current()]"/>
      <ml:group display="{.}">
        <xsl:variable name="unique-months" select="distinct-values($posts-this-year/created/month-from-dateTime(.))"/>
        <xsl:for-each select="$unique-months">
          <xsl:sort select="." order="descending"/>
          <xsl:variable name="posts-this-month" select="$posts-this-year[month-from-dateTime(created) eq current()]"/>
          <ml:group display="{ml:month-name(.)} ({count($posts-this-month)})">
            <xsl:for-each select="$posts-this-month">
              <xsl:sort select="created" order="descending"/>
              <ml:page display="{title}" href="{ml:external-uri(.)}"/>
            </xsl:for-each>
          </ml:group>
        </xsl:for-each>
      </ml:group>
    </xsl:for-each>
  </xsl:template>

  <xsl:template mode="pre-process-navigation" match="blog-posts-grouped-by-author">
    <xsl:variable name="unique-authors" select="distinct-values($ml:Posts/author/normalize-space(.))"/>
    <xsl:for-each select="$unique-authors">
      <ml:group display="{.}">
        <xsl:variable name="posts-by-author" select="$ml:Posts[author/normalize-space(.) = current()]"/>
        <xsl:for-each select="$posts-by-author">
          <xsl:sort select="created" order="descending"/>
          <ml:page display="{title}" href="{ml:external-uri(.)}"/>
        </xsl:for-each>
      </ml:group>
    </xsl:for-each>
  </xsl:template>

  <xsl:template mode="pre-process-navigation" match="blog-posts-grouped-by-category">
    <xsl:variable name="unique-tags" select="distinct-values($ml:Posts/tags/tag/normalize-space(.))"/>
    <xsl:for-each select="$unique-tags">
      <ml:group display="{.}">
        <xsl:variable name="posts-with-tag" select="$ml:Posts[tags/tag/normalize-space(.) = current()]"/>
        <xsl:for-each select="$posts-with-tag">
          <xsl:sort select="created" order="descending"/>
          <ml:page display="{title}" href="{ml:external-uri(.)}"/>
        </xsl:for-each>
      </ml:group>
    </xsl:for-each>
  </xsl:template>

</xsl:stylesheet>
