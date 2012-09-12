<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xhtml">

  <!-- Content of tutorial page #1 -->
  <xsl:template mode="page-content" match="Tutorial">
    <xsl:apply-templates mode="author-date-etc" select="."/>
    <xsl:apply-templates select="Body/node()"/>
    <!-- Append the next/prev buttons to the tutorial page #1 -->
    <xsl:apply-templates mode="tutorial-page-nav" select="Body/pages"/>
  </xsl:template>

  <!-- Content of subsequent tutorial pages -->
  <xsl:template mode="page-content" match="page[tutorial]">
    <xsl:next-match/>
    <xsl:variable name="url-name" select="ml:tutorial-page-url-name(current())"/>
    <!-- Append the next/prev buttons -->
    <xsl:apply-templates mode="tutorial-page-nav" select="ml:parent-tutorial(.)/Body/pages/page[@url-name eq $url-name]"/>
  </xsl:template>

          <!-- <pages> stands for the first page; <page> children for each subsequent page -->
          <xsl:template mode="tutorial-page-nav" match="pages | page">
            <xsl:variable name="previous-page" select="(preceding-sibling::page[1], parent::pages)[1]"/>
            <xsl:variable name="next-page"     select="self::page/following-sibling::page[1] | self::pages/page[1]"/>
            <!-- next/prev buttons -->
            <div class="pagination_nav">
              <xsl:if test="$previous-page">
                <p class="pagination_prev">
                  <xsl:variable name="prev-href">
                    <xsl:apply-templates mode="tutorial-page-href" select="$previous-page"/>
                  </xsl:variable>
                  <a href="{$prev-href}" class="btn btn_blue">
                    <xsl:text>&#171; Previous</xsl:text>
                  </a>
                  <span>
                    <xsl:apply-templates mode="tutorial-page-title" select="$previous-page"/>
                  </span>
                </p>
              </xsl:if>
              <xsl:if test="$next-page">
                <p class="pagination_next">
                  <xsl:variable name="next-href">
                    <xsl:apply-templates mode="tutorial-page-href" select="$next-page"/>
                  </xsl:variable>
                  <a href="{$next-href}" class="btn btn_blue">
                    <xsl:text>Next &#187;</xsl:text>
                  </a>
                  <span>
                    <xsl:apply-templates mode="tutorial-page-title" select="$next-page"/>
                  </span>
                </p>
              </xsl:if>
            </div>
          </xsl:template>

                  <!-- First page -->
                  <xsl:template mode="tutorial-page-title" match="pages">
                    <xsl:apply-templates select="/Tutorial/title/node()"/>
                  </xsl:template>

                  <!-- Subsequent pages -->
                  <xsl:template mode="tutorial-page-title" match="page">
                    <xsl:variable name="href" as="xs:string">
                      <xsl:apply-templates mode="tutorial-page-href" select="."/>
                    </xsl:variable>
                    <xsl:apply-templates mode="page-specific-title" select="doc(ml:internal-uri($href))">
                      <xsl:with-param name="exclude-parent-title" select="true()"/>
                    </xsl:apply-templates>
                  </xsl:template>


                  <!-- First page -->
                  <xsl:template mode="tutorial-page-href" match="pages">
                    <xsl:value-of select="ml:external-uri(.)"/>
                  </xsl:template>

                  <!-- Subsequent pages -->
                  <xsl:template mode="tutorial-page-href" match="page">
                    <xsl:value-of>
                      <xsl:value-of select="ml:external-uri(.)"/>
                      <xsl:text>/</xsl:text>
                      <xsl:value-of select="@url-name"/>
                    </xsl:value-of>
                  </xsl:template>


  <!-- list parent tutorial title in search results (and HTML <title>) -->
  <xsl:template mode="page-specific-title" match="page[tutorial]">
    <xsl:param name="exclude-parent-title"/>
    <xsl:next-match/>
    <!-- unless this is a heading -->
    <xsl:if test="not($exclude-parent-title)">
      <xsl:text> — </xsl:text>
      <xsl:value-of select="ml:parent-tutorial(.)/title"/>
    </xsl:if>
  </xsl:template>

  <!-- but not in the page heading -->
  <xsl:template mode="page-heading" match="page[tutorial]">
    <xsl:apply-templates mode="page-specific-title" select=".">
      <xsl:with-param name="exclude-parent-title" select="true()"/>
    </xsl:apply-templates>
  </xsl:template>


  <!-- Get the parent tutorial that this page is a part of -->
  <xsl:function name="ml:parent-tutorial" as="element(Tutorial)">
    <xsl:param name="node"/>
    <xsl:choose>
      <xsl:when test="$node/self::Tutorial">
        <xsl:sequence select="$node"/>
      </xsl:when>
      <xsl:otherwise>
        <xsl:variable name="parent-uri" select="substring-before(ml:external-uri($node), concat('/',ml:tutorial-page-url-name($node)))"/>
        <xsl:sequence select="doc(ml:internal-uri($parent-uri))/Tutorial"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:function>

  <!-- Get the last part of the page's URL -->
  <xsl:function name="ml:tutorial-page-url-name" as="xs:string">
    <xsl:param name="node"/>
    <xsl:variable name="this-uri" select="ml:external-uri($node)"/>
    <xsl:variable name="url-name" select="tokenize($this-uri,'/')[last()]"/>
    <xsl:sequence select="$url-name"/>
  </xsl:function>

</xsl:stylesheet>
