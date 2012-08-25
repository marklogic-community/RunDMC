<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs">

  <xsl:variable name="tutorial-page-path" select="string($params[@name eq 'path'])"/>
  <xsl:variable name="tutorial-page-name" select="tokenize($tutorial-page-path,'/')[last()]"/>

  <xsl:variable name="this-tutorial-page" select="if ($tutorial-page-path) then $content/Tutorial/pages/page[@url-name eq $tutorial-page-name]
                                                                           else $content/Tutorial/pages/page[1]"/>

  <xsl:template mode="page-specific-title" match="Tutorial">
    <xsl:apply-templates mode="tutorial-page-title" select="$this-tutorial-page"/>
  </xsl:template>

  <xsl:template mode="page-content" match="Tutorial">
    <xsl:if test="pages/page[1] is $this-tutorial-page">
      <xsl:apply-templates mode="author-date-etc" select="."/>
    </xsl:if>
    <xsl:apply-templates mode="tutorial-page" select="$this-tutorial-page"/>
  </xsl:template>

          <xsl:template mode="tutorial-page" match="page">
            <!--
            <xsl:apply-templates mode="tutorial-page-nav" select="."/>
            -->
            <!-- page content -->
            <xsl:apply-templates/>
            <xsl:apply-templates mode="tutorial-page-nav" select="."/>
          </xsl:template>

                  <xsl:template mode="tutorial-page-nav" match="page">
                    <!-- next/prev buttons -->
                    <div class="pagination_nav">
                      <xsl:if test="preceding-sibling::page">
                        <p class="pagination_prev">
                          <xsl:variable name="prev-href">
                            <xsl:apply-templates mode="tutorial-page-href" select="preceding-sibling::page[1]"/>
                          </xsl:variable>
                          <a href="{$prev-href}" class="btn btn_blue">
                            <xsl:text>&#171; Previous</xsl:text>
                          </a>
                          <span>
                            <xsl:apply-templates mode="tutorial-page-title" select="preceding-sibling::page[1]"/>
                          </span>
                        </p>
                      </xsl:if>
                      <xsl:if test="following-sibling::page">
                        <p class="pagination_next">
                          <xsl:variable name="next-href">
                            <xsl:apply-templates mode="tutorial-page-href" select="following-sibling::page[1]"/>
                          </xsl:variable>
                          <a href="{$next-href}" class="btn btn_blue">
                            <xsl:text>Next &#187;</xsl:text>
                          </a>
                          <span>
                            <xsl:apply-templates mode="tutorial-page-title" select="following-sibling::page[1]"/>
                          </span>
                        </p>
                      </xsl:if>
                    </div>
                  </xsl:template>

                          <xsl:template mode="tutorial-page-title" match="page[1]">
                            <xsl:apply-templates select="/Tutorial/title/node()"/>
                          </xsl:template>
                          <xsl:template mode="tutorial-page-title" match="page">
                            <xsl:value-of select="@title"/>
                          </xsl:template>

                          <xsl:template mode="tutorial-page-href" match="page[1]">
                            <xsl:value-of select="$external-uri"/>
                          </xsl:template>
                          <xsl:template mode="tutorial-page-href" match="page">
                            <xsl:value-of select="$external-uri"/>
                            <xsl:text>/</xsl:text>
                            <xsl:value-of select="@url-name"/>
                          </xsl:template>

</xsl:stylesheet>
