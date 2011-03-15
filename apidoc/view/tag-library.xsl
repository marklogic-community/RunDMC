<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:u    ="http://marklogic.com/rundmc/util"
  xmlns:docapp="http://marklogic.com/docapp/contents"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp docapp"
  extension-element-prefixes="xdmp">


  <xsl:template match="ml:api-toc">
    <script type="text/javascript">
    $(function() {
      $("#apidoc_tree").treeview({
        collapsed: true,
/*        animated: "medium",*/
/*        control:"#sidetreecontrol",*/
        persist: "cookie"
      });
    })
    </script>
    <xsl:variable name="options" as="element()">
      <options xmlns="xdmp:eval">
        <database>
          <xsl:value-of select="xdmp:database('docapp')"/>
        </database>
      </options>
    </xsl:variable>
    <!--
    <xsl:copy-of select="xdmp:invoke('../model/contents.xqy', (), $options)"/>
    -->
    <xsl:apply-templates mode="convert-toc-tree" select="xdmp:invoke('../model/contents.xqy', (), $options)"/>
  </xsl:template>

          <xsl:template mode="convert-toc-tree" match="all">
            <ul id="apidoc_tree">
              <xsl:apply-templates mode="#current"/>
            </ul>
          </xsl:template>

          <xsl:template mode="convert-toc-tree" match="top | sections | section | subsection | subsubsection">
            <li>
              <a href="?{@uri}">
                <xsl:value-of select="@label"/>
              </a>
              <xsl:if test="*">
                <ul>
                  <xsl:apply-templates mode="#current"/>
                </ul>
              </xsl:if>
            </li>
          </xsl:template>

          <xsl:template mode="convert-toc-tree" match="xhtml:div[@class eq 'treeNode']">
            <li>
              <xsl:apply-templates mode="#current"/>
            </li>
          </xsl:template>

          <xsl:template mode="convert-toc-tree" match="xhtml:img"/>

          <xsl:template mode="convert-toc-tree" match="xhtml:a">
            <xsl:copy>
              <xsl:apply-templates mode="#current"/>
            </xsl:copy>
          </xsl:template>

</xsl:stylesheet>

