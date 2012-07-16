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
  <xsl:include href="toc-help.xsl"/>

  <!-- Implements some common content fixup rules -->
  <xsl:include href="fixup.xsl"/>

  <xsl:include href="REST-common.xsl"/>

  <!-- Compute this first so we can glean the category info from the result
       and list the sub-categories on the main page intro for each lib -->
  <xsl:variable name="by-category">
    <xsl:call-template name="functions-by-category"/>
  </xsl:variable>

                                                                              <!-- exclude REST API "functions" -->
  <xsl:variable name="all-libs" select="$api:built-in-libs | $api:library-libs[not(. eq 'REST')]"/>

  <xsl:variable name="guide-docs"                select="xdmp:directory(concat('/apidoc/',$api:version,'/guide/'))[guide]"/>
  <xsl:variable name="guide-groups"              select="u:get-doc('/apidoc/config/document-list.xml')/docs/group[guide]"/>
  <xsl:variable name="guide-docs-not-configured" select="$guide-docs except toc:guides-in-group($guide-groups)"/>

  <xsl:function name="toc:guides-in-group" as="document-node()*">
    <xsl:param name="groups" as="element(group)*"/>
    <xsl:sequence select="for $guide-config in $groups/guide
                          return doc(concat('/apidoc/',$api:version,'/guide/',$guide-config/@url-name,'.xml'))"/>
  </xsl:function>


  <xsl:template match="/">
    <all-tocs>
      <toc:functions>
        <node href="/all"
              display="All functions ({sum($all-libs/api:function-count-for-lib(.))})"
              id="AllFunctions"
              function-list-page="yes"
              open="yes"
              top-control="yes">
          <title>All functions</title>
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
        <node href="/all"
              display="All functions ({sum($all-libs/api:function-count-for-lib(.))})"
              open="yes"
              id="AllFunctionsByCat"
              top-control="yes">
          <xsl:copy-of select="$by-category/node[not(@id eq 'RESTResourcesAPI')]"/>
        </node>
      </toc:categories>
      <xsl:if test="number($api:version) ge 5">
        <toc:rest-resources>
          <!-- Add this wrapper so the /REST page will get created -->
          <node href="/REST"
                display="All REST resources"
                id="RESTResourcesAPI"
                function-list-page="yes"
                open="yes"
                top-control="yes">
            <title>All REST resources</title>
            <!-- Just the REST API bucket contents -->
            <xsl:copy-of select="$by-category/node[@id eq 'RESTResourcesAPI']/node"/>
          </node>
          <node display="Related Guides"
                id="RelatedRestGuides"
                open="yes">
            <!-- REST Client guide repeated -->
            <xsl:apply-templates mode="toc-guide-node" select="$guide-docs[ends-with(base-uri(.),'rest-dev.xml')]">
              <xsl:with-param name="is-duplicate" select="true()"/>
            </xsl:apply-templates>
            <!-- monitoring guide repeated -->
            <xsl:apply-templates mode="toc-guide-node" select="$guide-docs[ends-with(base-uri(.),'monitoring.xml')]">
              <xsl:with-param name="is-duplicate" select="true()"/>
            </xsl:apply-templates>
            </node>

        </toc:rest-resources>
      </xsl:if>
      <xsl:if test="number($api:version) ge 5.1">
        <toc:java top-control="yes">
          <node display="Java Client" open="yes" id="javaTOC">
            <node display="Java Client API" 
                  href="/javadoc/client/index.html" external="yes"/>
            <!-- Java Client guide repeated -->
            <xsl:apply-templates mode="toc-guide-node" 
               select="$guide-docs[ends-with(base-uri(.),'java.xml')]">
              <xsl:with-param name="is-duplicate" select="true()"/>
            </xsl:apply-templates>
          </node>
        </toc:java>
      </xsl:if>
      <!--
      <toc:categories>
      -->
        <!--
        <node display="Functions by category">
        -->
          <!-- Every bucket except the REST API bucket -->
          <!--
          <xsl:copy-of select="$by-category/node[not(@id eq 'RESTResourcesAPI')]"/>
          -->
        <!--
        </node>
        -->
      <!--
      </toc:categories>
      -->
      <toc:guides top-control="yes">
        <!--
        <node display="User Guides" id="user_guides">
        -->
          <xsl:if test="$guide-docs-not-configured">
            <node display="New (unclassified) guides" open="yes">
              <xsl:apply-templates mode="toc-guide-node" select="$guide-docs-not-configured"/>
            </node>
          </xsl:if>
          <xsl:for-each select="$guide-groups">
            <node display="{@name}" id="{generate-id(.)}" open="yes">
              <xsl:apply-templates mode="toc-guide-node" select="toc:guides-in-group(.)"/>
            </node>
          </xsl:for-each>
        <!--
        </node>
        -->
      </toc:guides>
      <toc:other>
        <node display="Other Documentation" open="yes" id="other" top-control="yes">
          <xsl:if test="number($api:version) ge 5">
            <node display="Hadoop Connector" open="yes">
              <node display="Connector for Hadoop API" href="/javadoc/client/index.html" external="yes"/>
              <!-- Hadoop guide repeated -->
              <xsl:apply-templates mode="toc-guide-node" select="$guide-docs[ends-with(base-uri(.),'mapreduce.xml')]">
                <xsl:with-param name="is-duplicate" select="true()"/>
              </xsl:apply-templates>
            </node>
          </xsl:if>
          <node display="XCC" open="yes">
            <node display="XCC Javadoc" href="/javadoc/xcc/index.html" external="yes"/>
            <node display="XCC .NET API" href="/dotnet/xcc/index.html" external="yes"/>
            <!-- XCC guide repeated -->
            <xsl:apply-templates mode="toc-guide-node" select="$guide-docs[ends-with(base-uri(.),'xcc.xml')]">
              <xsl:with-param name="is-duplicate" select="true()"/>
            </xsl:apply-templates>
          </node>

          <xsl:apply-templates mode="help-toc" select="."/>
        </node>
      </toc:other>
    </all-tocs>
  </xsl:template>

          <xsl:template mode="toc-guide-node" match="/guide">
            <xsl:param name="is-duplicate" select="false()"/>
            <node href="{ml:external-uri(.)}" display="{/guide/title}" id="{generate-id(.)}" async="yes" guide="yes" sub-control="yes">
              <xsl:if test="$is-duplicate">
                <xsl:attribute name="duplicate" select="'yes'"/>
              </xsl:if>
              <xsl:for-each select="/guide/chapter-list/chapter">
                <xsl:apply-templates mode="guide-toc" select="doc(@href)/chapter/node()"/>
              </xsl:for-each>
            </node>
          </xsl:template>


          <xsl:template mode="guide-toc" match="text()"/>

          <xsl:template mode="guide-toc" match="xhtml:div[@class eq 'section']">
            <node href="{ml:external-uri(.)}#{(*[1] treat as element(xhtml:a))/@id}" display="{*[2]}"> <!-- second element assumed to be the heading (<h2>, <h3>, etc.) -->
              <xsl:apply-templates mode="#current"/>
            </node>
          </xsl:template>


          <xsl:template match="api:lib">
            <node href="/{.}"
                  display="{api:prefix-for-lib(.)}:"
                  function-count="{api:function-count-for-lib(.)}"
                  namespace="{api:uri-for-lib(.)}"
                  category-bucket="{@category-bucket}"
                  function-list-page="yes"
                  async="yes"
                  id="{.}_{generate-id(.)}"> <!-- generate a unique id for this TOC section -->
              <xsl:if test="@built-in">
                <xsl:attribute name="footnote" select="'yes'"/>
              </xsl:if>
              <title>
                <xsl:value-of select="api:prefix-for-lib(.)"/>
                <xsl:text> functions</xsl:text>
              </title>
              <intro>
                <xsl:variable name="modifier" select="if (@built-in) then 'built-in' else 'XQuery library'"/>
                <p>The table below lists all the "<xsl:value-of select="api:prefix-for-lib(.)"/>" <xsl:value-of select="$modifier"/> functions (in this namespace: <code><xsl:value-of select="api:uri-for-lib(.)"/></code>).</p>

                <xsl:variable name="sub-pages" select="$by-category//node[starts-with(@href, concat('/',current(),'/'))]"/>
                <xsl:if test="$sub-pages">
                  <p>You can also view these functions broken down by category:</p>
                  <ul>
                    <xsl:apply-templates mode="sub-page" select="$sub-pages">
                      <xsl:sort select="@category-name"/>
                    </xsl:apply-templates>
                  </ul>
                </xsl:if>

                <xsl:apply-templates mode="render-summary" select="toc:get-summary-for-lib(.)"/>

              </intro>
              <xsl:comment>Current lib: <xsl:value-of select="."/></xsl:comment>
              <xsl:apply-templates select="toc:function-name-nodes($all-functions[@lib eq current()])"/>
            </node>
          </xsl:template>

                  <xsl:template mode="sub-page" match="node"> 
                    <li>
                      <a href="{@href}">
                        <xsl:value-of select="@category-name"/>
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

                  <!-- A "function" name starting with a "/" is actually a REST resource -->
                  <xsl:template match="api:function-name[starts-with(.,'/')]">
                    <xsl:variable name="resource-name" select="api:name-from-REST-fullname(.)"/>
                    <xsl:variable name="http-method"   select="api:verb-from-REST-fullname(.)"/>
                    <!-- ASSUMPTION: the input elements are pre-sorted by resource name, then by preferred HTTP verb (GET's always first) -->
                    <xsl:variable name="is-same-resource-as-next" select="following-sibling::*[1][api:name-from-REST-fullname(.) eq $resource-name]"/>


                    <!-- If we decide to prefer signal over noise... then re-enable this. -->
                    <!-- If the method is GET and the next resource in the list is different, don't include the "(GET)" at the end of the name;
                         it only adds unnecessary clutter in that case. -->
                    <!-- This isn't wanted for now:
                    <xsl:variable name="base-display-name" select="if ($http-method eq 'GET' and not($is-same-resource-as-next)) then $resource-name
                                                                                                                                 else string(.)"/>
                    -->
                    <!-- Always display the verb for now (except in 5.0 where the distinction is *never* made). -->
                    <xsl:variable name="base-display-name" select="if ($api:version eq '5.0') then $resource-name
                                                                                              else string(.)"/>


                    <!-- Display the square-bracket version
                    <node href="{api:REST-fullname-to-external-uri(.)}" display="{$base-display-name}" type="function"/>
                    -->

                    <!-- Display the wildcard (*) version in the TOC, but the original, curly-brace version on the list pages. -->
                    <node href="{api:REST-fullname-to-external-uri(.)}" display="{api:REST-name-with-wildcards($base-display-name)}"
                                                              list-page-display="{api:reverse-translate-REST-resource-name($base-display-name)}"
                                                                        type="function"/>
                  </xsl:template>

</xsl:stylesheet>
