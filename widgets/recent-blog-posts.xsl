<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns="http://www.w3.org/1999/xhtml" 
  xmlns:ml="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs">

  <xsl:import href="../view/page.xsl"/>

  <xsl:template match="/">
    <ml:widget>
      <h1><img src="/images/i_rss.png" alt="" width="36" height="33"/> Recent Blog Posts</h1>
      <div class="recent-rss">
        <xsl:apply-templates mode="latest-post" select="ml:latest-posts(5)">
          <xsl:with-param name="show-icon" select="false()"/>
        </xsl:apply-templates>
      </div>
      <a style="float: right; padding-right: 5px; padding-bottom: 5px" class="more" href="/blog">View blog</a>
    </ml:widget>
  </xsl:template>

</xsl:stylesheet>
