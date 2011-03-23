<!-- This stylesheet constructs the "Functions by category"
     portion of the TOC hierarchy. -->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:api="http://marklogic.com/rundmc/api"
  xmlns:apidoc="http://marklogic.com/xdmp/apidoc"
  xmlns:toc="http://marklogic.com/rundmc/api/toc"
  exclude-result-prefixes="xs api apidoc toc">

  <xsl:variable name="all-functions" select="collection()/api:function-page/api:function"/>

  <!-- This is bound to be slow, but that's okay, because we pre-generate this TOC -->
  <xsl:template name="functions-by-category">

    <xsl:variable name="forced-order" select="('XQuery Library Modules', 'MarkLogic Built-In Functions')"/>

    <!-- for each bucket -->
    <xsl:for-each select="distinct-values($all-functions/@bucket)">
      <xsl:sort select="index-of($forced-order, .)" order="descending"/>
      <xsl:sort select="."/>

      <!-- bucket node -->
      <node display="{.}">
        <xsl:variable name="in-this-bucket" select="$all-functions[@bucket eq current()]"/>

        <!-- for each category -->
        <xsl:for-each select="distinct-values($in-this-bucket/@category)">
          <xsl:sort select="."/>
          <xsl:variable name="category" select="."/>
          <xsl:variable name="in-this-category" select="$in-this-bucket[@category eq $category]"/>

          <xsl:variable name="lib-for-all" select="toc:lib-for-all($in-this-category)"/>

          <xsl:variable name="is-exhaustive" select="toc:category-is-exhaustive($category, (), $lib-for-all)"/>

          <xsl:variable name="sub-categories" select="distinct-values($in-this-category/@subcategory)"/>

          <!-- category node -->
          <node display="{toc:display-category(.)}{toc:display-suffix($lib-for-all)}">

            <!-- When there are sub-categories, don't create a new page for the category (they tend to be useless);
                 only create a link if it corresponds to a full lib page -->
            <xsl:choose>
              <xsl:when test="$is-exhaustive">
                <xsl:attribute name="href" select="concat('/',$lib-for-all)"/>
              </xsl:when>
              <!-- Create a new page for this category if it doesn't contain sub-categories
                   and does not already correspond to a full lib page -->
              <xsl:when test="not($sub-categories)">
                <xsl:attribute name="href" select="toc:path-for-category(.)"/>
                <intro>
                  <!--
                  <xsl:copy-of select="api:get-summary-for-category(.)"/>
                  -->
                </intro>
              </xsl:when>
            </xsl:choose>

            <!-- A category has either functions as children or sub-categories, never both -->
            <xsl:choose>
              <xsl:when test="not($sub-categories)">
                <!-- function TOC nodes -->
                <xsl:apply-templates select="toc:function-name-nodes($in-this-category)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:for-each select="$sub-categories">
                  <xsl:sort select="."/>
                  <xsl:variable name="subcategory" select="."/>

                  <xsl:variable name="in-this-subcategory" select="$in-this-category[@subcategory eq $subcategory]"/>

                  <xsl:variable name="lib-for-all" select="toc:lib-for-all($in-this-subcategory)"/>

                  <xsl:variable name="is-exhaustive" select="toc:category-is-exhaustive($category, $subcategory, $lib-for-all)"/>

                  <xsl:variable name="href" select="if ($is-exhaustive) then concat('/',$lib-for-all)
                                                                        else toc:path-for-sub-category(.)"/>

                  <node href="{$href}" display="{toc:display-category(.)}{toc:display-suffix($lib-for-all)}">
                    <!-- We already have the intro text if this is a lib-exhaustive category -->
                    <xsl:if test="not($is-exhaustive)">
                      <intro>
                        <!--
                        <xsl:copy-of select="api:get-summary-for-sub-category(.)"/>
                        -->
                      </intro>
                    </xsl:if>
                    <!-- function TOC nodes -->
                    <xsl:apply-templates select="toc:function-name-nodes($in-this-subcategory)"/>
                  </node>
                </xsl:for-each>
              </xsl:otherwise>
            </xsl:choose>
          </node>
        </xsl:for-each>
      </node>
    </xsl:for-each>
  </xsl:template>

          <xsl:function name="toc:display-category">
            <xsl:param name="cat"/>
            <xsl:sequence select="if (ends-with($cat,'Builtins')) then substring-before($cat,'Builtins') else $cat"/>
          </xsl:function>

          <!-- TODO: Make pretty/meaningful URLs -->
          <xsl:function name="toc:path-for-category">
            <xsl:param name="cat"/>
            <xsl:sequence select="concat('/',$cat)"/>
          </xsl:function>

          <!-- TODO: Make pretty/meaningful URLs -->
          <xsl:function name="toc:path-for-sub-category">
            <xsl:param name="cat"/>
            <xsl:sequence select="concat('/',$cat)"/>
          </xsl:function>

          <xsl:function name="toc:function-name-nodes">
            <xsl:param name="functions"/>
            <xsl:for-each select="$functions">
              <xsl:sort select="@fullname"/>
              <api:function-name>
                <xsl:value-of select="@fullname"/>
              </api:function-name>
            </xsl:for-each>
          </xsl:function>


          <xsl:function name="toc:lib-for-all" as="xs:string?">
            <xsl:param name="functions"/>
            <xsl:sequence select="if (count(distinct-values($functions/@lib)) eq 1)
                                  then string($functions[1]/@lib)
                                  else ()"/>
          </xsl:function>


          <xsl:function name="toc:category-is-exhaustive" as="xs:boolean">
            <xsl:param name="category"     as="xs:string"/>
            <xsl:param name="sub-category" as="xs:string?"/>
            <xsl:param name="lib-for-all"  as="xs:string?"/>

            <xsl:choose>
              <xsl:when test="$lib-for-all">
                <xsl:variable name="num-functions-in-lib"      select="count($all-functions[@lib eq $lib-for-all])"/>
                <xsl:variable name="num-functions-in-category" select="count($all-functions
                                                                             [@category    eq $category]
                                                                             [@subcategory eq $sub-category or not($sub-category)])"/>

                <xsl:sequence select="$num-functions-in-lib
                                   eq $num-functions-in-category"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:sequence select="false()"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:function>


          <xsl:function name="toc:display-suffix" as="xs:string?">
            <xsl:param name="lib-for-all" as="xs:string?"/>
            <xsl:sequence select="if ($lib-for-all) then concat(' (', api:prefix-for-lib($lib-for-all), ':)')
                                                    else ()"/>
          </xsl:function>

</xsl:stylesheet>
