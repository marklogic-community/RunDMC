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
                xmlns:stp="http://marklogic.com/rundmc/api/setup"
                xmlns:toc="http://marklogic.com/rundmc/api/toc"
                xmlns:u  ="http://marklogic.com/rundmc/util"
                xmlns:ml="http://developer.marklogic.com/site/internal"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns="http://marklogic.com/rundmc/api/toc"
                extension-element-prefixes="xdmp"
                exclude-result-prefixes="xs api apidoc xhtml toc u ml xdmp">

  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api"
      href="/apidoc/model/data-access.xqy"/>
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api/setup"
      href="/apidoc/setup/setup.xqm"/>
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api/toc"
      href="/apidoc/setup/toc.xqm"/>

  <!-- TODO inline? Nothing else uses this. -->
  <xsl:include href="tocByCategory.xsl"/>
  <!-- TODO inline? Nothing else uses this. -->
  <xsl:include href="toc-help.xsl"/>

  <xsl:param name="VERSION-NUMBER" as="xs:double"/>

  <!--
      Compute this first so we can glean the category info from the result
      and list the sub-categories on the main page intro for each lib
  -->
  <xsl:variable name="by-category" as="element()+">
    <xsl:call-template name="functions-by-category">
      <xsl:with-param name="mode" select="'xpath'" />
    </xsl:call-template>
  </xsl:variable>
  <xsl:variable name="javascript-by-category" as="element()+">
    <xsl:call-template name="functions-by-category">
      <xsl:with-param name="mode" select="'javascript'" />
    </xsl:call-template>
  </xsl:variable>

  <xsl:template match="/">
    <xsl:variable
        name="function-count"
        select="toc:function-count('xpath', ())"/>
    <xsl:variable
        name="javascript-function-count"
        select="toc:function-count('javascript', ())"/>
    <root display="All Documentation"
          open="true">
      <node
          display="Server-Side APIs"
          open="true">
        <xsl:if test="$VERSION-NUMBER ge 8">
          <node href="/js/all"
                display="JavaScript Functions by Category ({
                         $javascript-function-count })"
                open="true"
                id="AllFunctionsJavasScriptByCat">
            <xsl:copy-of
                select="$javascript-by-category"/>
          </node>
          <node href="/js/all"
                display="JavaScript Functions ({
                         $javascript-function-count })"
                id="AllFunctionsJavaScript"
                mode="javascript"
                function-list-page="true">
            <title>JavaScript functions</title>
            <intro>
              <p xmlns="http://www.w3.org/1999/xhtml">
                The following table lists all JavaScript functions
                in the MarkLogic API reference,
                including both built-in functions
                and functions implemented in XQuery library modules.
              </p>
            </intro>
            <xsl:apply-templates select="$toc:ALL-LIBS-JAVASCRIPT">
              <xsl:sort select="."/>
            </xsl:apply-templates>
          </node>
        </xsl:if>

        <node href="/all"
              display="XQuery/XSLT Functions by Category ({
                       $function-count })"
              open="true"
              id="AllFunctionsByCat">
          <xsl:copy-of
              select="$by-category[not(@id eq 'RESTResourcesAPI')]"/>
        </node>
        <node href="/all"
              display="XQuery/XSLT Functions ({
                       $function-count })"
              id="AllFunctions"
              function-list-page="true">
          <title>XQuery/XSLT functions</title>
          <intro>
            <p xmlns="http://www.w3.org/1999/xhtml">
              The following table lists all functions
              in the MarkLogic API reference,
              including both built-in functions
              and functions implemented in XQuery library modules.
            </p>
          </intro>
          <xsl:apply-templates select="$toc:ALL-LIBS">
            <xsl:sort select="."/>
          </xsl:apply-templates>
        </node>
      </node><!-- server-side APIs -->

      <xsl:if test="$VERSION-NUMBER ge 5">
        <!-- Add this wrapper so the /REST page will get created -->
        <node href="/REST"
              display="REST Resources"
              id="RESTResourcesAPI"
              function-list-page="true"
              open="true">
          <title>REST resources</title>
          <!-- Just the REST API bucket contents -->
          <xsl:copy-of
              select="$by-category[@id eq 'RESTResourcesAPI']"/>
          <node display="Related Guides"
                id="RelatedRestGuides"
                open="true">
            <!-- REST Client guide repeated -->
            <xsl:apply-templates mode="toc-guide-node"
                                 select="$toc:GUIDE-DOCS[
                                         ends-with(base-uri(.),'rest-dev.xml')]">
              <xsl:with-param name="is-duplicate" select="true()"/>
            </xsl:apply-templates>
            <!-- monitoring guide repeated -->
            <xsl:apply-templates mode="toc-guide-node"
                                 select="$toc:GUIDE-DOCS[
                                         ends-with(base-uri(.),'monitoring.xml')]">
              <xsl:with-param name="is-duplicate" select="true()"/>
            </xsl:apply-templates>
          </node>
        </node>
      </xsl:if>

      <xsl:if test="$VERSION-NUMBER ge 6">
        <node
            display="Client-Side APIs"
            open="true">
          <node
              display="Java API"
              open="true"
              id="javaTOC">
            <node
                display="Java API"
                href="/javadoc/client/index.html"
                external="true"/>
            <!-- Java Client guide repeated -->
            <xsl:apply-templates
                mode="toc-guide-node"
                select="$toc:GUIDE-DOCS[ends-with(base-uri(.),'java.xml')]">
              <xsl:with-param name="is-duplicate" select="true()"/>
            </xsl:apply-templates>
          </node>
        </node>
      </xsl:if>

      <node display="Guides"
            id="guides"
            open="true">
        <xsl:if test="$toc:GUIDE-DOCS-NOT-CONFIGURED">
          <node
              display="New (unclassified) guides"
              open="true">
            <xsl:apply-templates mode="toc-guide-node"
                                 select="$toc:GUIDE-DOCS-NOT-CONFIGURED"/>
          </node>
        </xsl:if>
        <xsl:for-each select="$toc:GUIDE-GROUPS">
          <node
              display="{@name}"
              id="{generate-id(.)}">
            <!-- Per #204 hard-code open state by guide. -->
            <xsl:if test="@name = ('Getting Started Guides')">
              <xsl:attribute name="open" select="true()"/>
            </xsl:if>
            <xsl:apply-templates mode="toc-guide-node"
                                 select="toc:guides-in-group(.)"/>
          </node>
        </xsl:for-each>
      </node>

      <node display="Other Documentation"
            open="true"
            id="other">
        <xsl:if test="$VERSION-NUMBER ge 5">
          <node display="Hadoop Connector">
            <node display="Connector for Hadoop API"
                  href="/javadoc/hadoop/index.html" external="true"/>
            <!-- Hadoop guide repeated -->
            <xsl:apply-templates mode="toc-guide-node"
                                 select="$toc:GUIDE-DOCS[
                                         ends-with(
                                         base-uri(.),'mapreduce.xml')]">
              <xsl:with-param name="is-duplicate" select="true()"/>
            </xsl:apply-templates>
          </node>
        </xsl:if>

        <node display="XCC">
          <node display="XCC Javadoc"
                href="/javadoc/xcc/index.html"
                external="true"/>
          <node display="XCC .NET API"
                href="/dotnet/xcc/index.html"
                external="true"/>
          <!-- XCC guide repeated -->
          <xsl:apply-templates mode="toc-guide-node"
                               select="$toc:GUIDE-DOCS[
                                       ends-with(base-uri(.),'xcc.xml')]">
            <xsl:with-param name="is-duplicate" select="true()"/>
          </xsl:apply-templates>
        </node>

        <xsl:apply-templates mode="help-toc" select="."/>
        <xsl:if test="$VERSION-NUMBER ge 6">
          <node display="C++ UDF API Reference"
                href="/cpp/udf/index.html" external="true"/>
        </xsl:if>
      </node><!-- other -->

    </root>
  </xsl:template>

  <!-- TODO any namespace problems here? -->
  <xsl:template mode="toc-guide-node" match="/guide">
    <xsl:param name="is-duplicate" select="false()"/>
    <node href="{api:external-uri(.)}" display="{/guide/title}"
          id="{generate-id(.)}"
          async="true" guide="true" sub-control="true" wrap-titles="true">
      <xsl:if test="$is-duplicate">
        <xsl:attribute name="duplicate" select="true()"/>
      </xsl:if>
      <xsl:for-each select="/guide/chapter-list/chapter">
        <xsl:apply-templates mode="guide-toc"
                             select="doc(@href)/chapter/node()"/>
      </xsl:for-each>
    </node>
  </xsl:template>

  <xsl:template mode="guide-toc" match="text()"/>

  <xsl:template mode="guide-toc" match="xhtml:div[@class eq 'section']">
    <!-- For display, second element assumed to be <h2>, <h3>, etc. -->
    <node href="{ toc:guide-href(.) }" display="{ *[2] }">
      <xsl:apply-templates mode="#current"/>
    </node>
  </xsl:template>

  <!--
      This creates an XML TOC section for a library, with an id.
      The api:lib elements are generated in api:get-libs.
      This is javascript-aware.
  -->
  <xsl:template match="api:lib">
    <xsl:variable name="mode" as="xs:string"
                  select="@mode"/>
    <node>
      <xsl:copy-of
          select="toc:node-attributes-for-lib(., $mode)"/>
      <title>
        <xsl:value-of select="api:prefix-for-lib(.)"/>
        <xsl:text> functions</xsl:text>
      </title>
      <intro>
        <xsl:variable name="modifier"
                      select="if (@built-in) then 'built-in'
                              else 'XQuery library'"/>
        <p xmlns="http://www.w3.org/1999/xhtml">
          The table below lists all the
          "<xsl:value-of select="api:prefix-for-lib(.)"/>"
          <xsl:value-of select="$modifier"/> functions
          (in this namespace:
          <code><xsl:value-of select="api:uri-for-lib(.)"/></code>).
        </p>

        <xsl:copy-of
            select="toc:lib-sub-pages(
                    .,
                    if ($mode eq 'javascript') then $javascript-by-category
                    else $by-category,
                    $mode)"/>

        <xsl:apply-templates mode="render-summary"
                             select="toc:get-summary-for-lib(.)"/>
        <xsl:copy-of
            select="$api:namespace-mappings[
                    @lib eq current()]/summary-addendum/node()"/>
      </intro>
      <xsl:comment>Current lib: <xsl:value-of select="."/></xsl:comment>
      <xsl:apply-templates
          select="toc:function-name-nodes(
                  if ($mode eq 'javascript')
                  then $toc:ALL-FUNCTIONS-JAVASCRIPT[@lib eq current()]
                  else $toc:ALL-FUNCTIONS-NOT-JAVASCRIPT[@lib eq current()])"/>
    </node>
  </xsl:template>

  <xsl:template mode="render-summary"
                match="apidoc:summary">
    <xsl:copy-of select="stp:fixup(., 'toc')"/>
  </xsl:template>

  <!--
      Wrap summary content with <p> if not already present.
      The wrapper might be in several namespaces.
  -->
  <xsl:template mode="render-summary"
                match="apidoc:summary[not(xhtml:p|apidoc:p|p)]">
    <p xmlns="http://www.w3.org/1999/xhtml">
      <xsl:next-match/>
    </p>
  </xsl:template>

  <!-- function nodes -->
  <xsl:template match="api:function-name">
    <xsl:copy-of select="toc:function-node(., $VERSION-NUMBER)"/>
  </xsl:template>

</xsl:stylesheet>
