<!-- This stylesheet generates the TOC based on the current
     database contents. It is not run at user request time;
     we invoke it as part of the bulk content update process
     in /apidoc/setup/update-content.xqy.
-->
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

  <xsl:import href="../view/page.xsl"/>

  <xsl:template match="/">
    <div>
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

      <div>API Reference</div>
      <ul id="apidoc_tree">
        <li>
          <a href="/built-in">Built-in functions (<xsl:value-of select="$api:built-in-function-count"/>)</a>
          <ul>
            <xsl:apply-templates select="$api:built-in-modules"/>
          </ul>
        </li>
        <li>
          <a href="/library">Library functions (<xsl:value-of select="$api:library-function-count"/>)</a>
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
    </div>
  </xsl:template>

          <xsl:template match="api:module">
            <li>
              <xsl:variable name="href">
                <xsl:apply-templates mode="module-href" select="."/>
              </xsl:variable>
              <a href="/{$href}">
                <xsl:value-of select="."/>: (<xsl:value-of select="api:function-count-for-module(.,@built-in)"/>)
              </a>
              <ul>
                <xsl:apply-templates select="api:function-names-for-module(.,@built-in)"/>
              </ul>
            </li>
          </xsl:template>


                  <!-- By default, just use the name of the module -->
                  <xsl:template mode="module-href" match="api:module">
                    <xsl:value-of select="."/>
                  </xsl:template>

                  <!-- But special-case the "spell" library, since "spell" also appears as a built-in module,
                       and we need to disambiguate the two -->
                  <xsl:template mode="module-href" match="api:module[. eq 'spell'][not(@built-in)]">
                    <xsl:text>spell-lib</xsl:text>
                  </xsl:template>


                  <xsl:template match="api:function-name">
                    <li class="function_name" id="{.}">
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


</xsl:stylesheet>

