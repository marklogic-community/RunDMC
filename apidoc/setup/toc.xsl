<!-- This stylesheet generates the XML-based TOC based on the current
     database contents. It is not run at user request time;
     we invoke it as part of the bulk content update process
     in the /apidoc/setup scripts.

     The result is used both in rendering the HTML TOC as well as in
     driving the generation of function list pages.
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:api="http://marklogic.com/rundmc/api"
  xmlns:apidoc="http://marklogic.com/xdmp/apidoc"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:toc="http://marklogic.com/rundmc/api/toc"
  xmlns:u  ="http://marklogic.com/rundmc/util"
  xmlns:ml="http://developer.marklogic.com/site/internal"
  xmlns:xdmp="http://marklogic.com/xdmp"
  exclude-result-prefixes="xs api apidoc xhtml toc u ml xdmp">

  <xsl:import href="../view/page.xsl"/>

  <xsl:include href="tocByCategory.xsl"/>

  <!-- Implements some common content fixup rules -->
  <xsl:include href="fixup.xsl"/>

  <!-- Compute this first so we can glean the category info from the result
       and list the sub-categories on the main page intro for each lib -->
  <xsl:variable name="by-category">
    <xsl:call-template name="functions-by-category"/>
  </xsl:variable>

  <xsl:variable name="all-libs" select="$api:built-in-libs | $api:library-libs"/>

  <xsl:variable name="guide-configs" select="u:get-doc('/apidoc/config/document-list.xml')/docs/(.|group)/guide"/>

  <xsl:variable name="guide-docs-configured" select="for $c in $guide-configs return doc(concat('/apidoc/',$api:version,'/docs/',$c/@url-name,'.xml'))"/>
  <xsl:variable name="guide-docs-all"                             select="xdmp:directory(concat('/apidoc/',$api:version,'/docs/'))[guide]"/>

  <!-- Prefix unconfigured guides to the beginning (so new ones are easily discoverable) -->
  <xsl:variable name="guide-docs-ordered" select="$guide-docs-all except $guide-docs-configured,
                                                                         $guide-docs-configured"/>
  <xsl:template match="/">
    <all-tocs>
      <toc:functions>
        <node href="/all"
              title="All functions"
              display="All functions ({$api:all-functions-count})"
              id="AllFunctions"
              function-list-page="yes">
          <intro>
            <p>The following table lists all functions in the MarkLogic API reference, including both built-in functions and functions implemented in XQuery library modules.</p>
          </intro>
          <xsl:apply-templates select="$all-libs">
            <xsl:sort select="."/>
          </xsl:apply-templates>
          <!--
          <node href="/built-in" display="Built-in functions ({$api:built-in-function-count})" title="All built-in functions">
            <intro>
              <p>The following table lists all built-in functions, including both the standard XQuery functions (in the <code>fn:</code> namespace) and the MarkLogic extension functions.</p>
            </intro>
            <xsl:apply-templates select="$api:built-in-libs"/>
          </node>
          <node href="/library" display="Library functions ({$api:library-function-count})" title="All library functions">
            <intro>
              <p>The following table lists all library functions, i.e. functions implemented in XQuery library modules that ship with MarkLogic Server.</p>
            </intro>
            <xsl:apply-templates select="$api:library-libs"/>
          </node>
          -->
        </node>
      </toc:functions>
      <toc:categories>
        <!--
        <node display="Functions by category">
        -->
          <xsl:copy-of select="$by-category"/>
        <!--
        </node>
        -->
      </toc:categories>
      <toc:guides>
        <!--
        <node display="User Guides" id="user_guides">
        -->
          <xsl:for-each select="$guide-docs-ordered">
            <node href="{ml:external-uri(.)}" display="{/guide/title}" id="{generate-id(.)}">
              <xsl:apply-templates mode="guide-toc"/>
            </node>
          </xsl:for-each>
        <!--
        </node>
        -->
      </toc:guides>
    </all-tocs>
  </xsl:template>

          <xsl:template mode="guide-toc" match="text()"/>
          <xsl:template mode="guide-toc" match="xhtml:div[@class eq 'section']">
            <node href="{ml:external-uri(.)}#{*[1]/xhtml:a[last()]/@id}" display="{*[1]}">
              <xsl:apply-templates mode="#current"/>
            </node>
          </xsl:template>


          <xsl:template match="api:lib">
            <node href="/{.}"
                  display="{api:prefix-for-lib(.)}:"
                  function-count="{api:function-count-for-lib(.)}"
                  namespace="{api:uri-for-lib(.)}"
                  title="{api:prefix-for-lib(.)} functions"
                  category-bucket="{@category-bucket}"
                  function-list-page="yes"
                  id="{.}_{generate-id(.)}"> <!-- generate a unique id for this TOC section -->
              <xsl:if test="@built-in">
                <xsl:attribute name="footnote" select="'yes'"/>
              </xsl:if>
              <intro>
                <xsl:variable name="modifier" select="if (@built-in) then 'built-in' else 'XQuery library'"/>
                <p>The table below lists all the "<xsl:value-of select="api:prefix-for-lib(.)"/>" <xsl:value-of select="$modifier"/> functions (in this namespace: <code><xsl:value-of select="api:uri-for-lib(.)"/></code>).</p>

                <xsl:variable name="sub-pages" select="$by-category//node[starts-with(@href, concat('/',current(),'/'))]"/>
                <xsl:if test="$sub-pages">
                  <p>You can also view these functions broken down by category:</p>
                  <ul>
                    <xsl:apply-templates mode="sub-page" select="$sub-pages">
                      <xsl:sort select="@title"/>
                    </xsl:apply-templates>
                  </ul>
                </xsl:if>

                <xsl:apply-templates mode="render-summary" select="toc:get-summary-for-lib(.)"/>

              </intro>
              <xsl:apply-templates select="api:function-names-for-lib(.)"/>
            </node>
          </xsl:template>

                  <xsl:template mode="sub-page" match="node"> 
                    <li>
                      <a href="{@href}">
                        <xsl:value-of select="substring-after(
                                                substring-before(@title, ')'),
                                                '(')"/>
                      </a>
                    </li>
                    <!--
                    <xsl:if test="position() ne last()">, </xsl:if>
                    <xsl:if test="position() eq (last() - 1)">and </xsl:if> 
                    -->
                  </xsl:template>

                  <!-- Wrap summary content with <p> if not already present -->
                  <xsl:template mode="render-summary" match="apidoc:summary[not(xhtml:p)]">
                    <p>
                      <xsl:next-match/>
                    </p>
                  </xsl:template>

                  <xsl:template mode="render-summary" match="apidoc:summary">
                    <xsl:apply-templates mode="fixup"/>
                  </xsl:template>


                  <xsl:template match="api:function-name">
                    <node href="/{.}" display="{.}" type="function"/>
                  </xsl:template>

</xsl:stylesheet>
