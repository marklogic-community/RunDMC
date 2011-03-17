<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:u    ="http://marklogic.com/rundmc/util"
  xmlns:docapp="http://marklogic.com/docapp/contents"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns:cts="http://marklogic.com/cts"
  xmlns:api="http://marklogic.com/rundmc/api"
  exclude-result-prefixes="xs ml xdmp docapp cts api"
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
    <!--
    -->

    <div>API Reference</div>
    <ul id="apidoc_tree">
      <li>Built-in functions (<xsl:value-of select="$api:built-in-function-count"/>)
        <ul>
          <xsl:apply-templates select="$api:built-in-modules"/>
        </ul>
      </li>
      <li>Library functions (<xsl:value-of select="$api:library-function-count"/>)
        <ul>
          <xsl:apply-templates select="$api:library-modules"/>
        </ul>
      </li>
    <!--
    <xsl:apply-templates mode="convert-toc-tree" select="xdmp:invoke('../model/contents.xqy', (), $options)"/>
    -->
      <li>Functions by category</li>
      <li>User Guides</li>
    </ul>
  </xsl:template>

          <xsl:template match="api:module">
            <li>
              <a href="/{.}">
                <xsl:value-of select="."/>: (<xsl:value-of select="api:function-count-for-module(.,@is-built-in)"/>)
              </a>
              <ul>
                <xsl:apply-templates select="api:function-names-for-module(.,@is-built-in)"/>
              </ul>
            </li>
          </xsl:template>

                  <xsl:template match="api:function-name">
                    <li class="function_name">
                      <a href="/{.}">
                        <xsl:value-of select="."/>
                      </a>
                    </li>
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

  <xsl:template match="api:function-list-page">
    <table>
      <xsl:apply-templates select="api:function-listing"/>
    </table>
  </xsl:template>

          <xsl:template match="api:function-listing">
            <tr>
              <td><xsl:value-of select="api:name"/></td>
              <td><xsl:copy-of select="api:description/node()"/></td>
            </tr>
          </xsl:template>

</xsl:stylesheet>

