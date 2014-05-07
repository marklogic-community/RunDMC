<!--
    This stylesheet constructs the "Functions by category"
    portion of the TOC hierarchy.
-->
<xsl:stylesheet version="2.0"
                xmlns:api="http://marklogic.com/rundmc/api"
                xmlns:apidoc="http://marklogic.com/xdmp/apidoc"
                xmlns:raw="http://marklogic.com/rundmc/raw-docs-access"
                xmlns:toc="http://marklogic.com/rundmc/api/toc"
                xmlns:u="http://marklogic.com/rundmc/util"
                xmlns:xdmp="http://marklogic.com/xdmp"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns="http://marklogic.com/rundmc/api/toc"
                extension-element-prefixes="xdmp"
                exclude-result-prefixes="xs api apidoc toc u raw">

  <!-- The importer of this xsl should import data-access.xqm -->
  <!-- The importer of this xsl should import toc.xqm -->

  <!--
      This is bound to be slow,
      but that's okay, because we pre-generate this TOC.
  -->
  <xsl:template name="functions-by-category">
    <xsl:param name="mode" as="xs:string?"/>

    <xsl:variable name="forced-order"
                  select="('MarkLogic Built-In Functions',
                          'XQuery Library Modules', 'CPF Functions',
                          'W3C-Standard Functions', 'REST Resources API')"/>

    <xsl:variable name="functions"
                  select="if ($mode eq 'javascript')
                          then $toc:ALL-FUNCTIONS-JAVASCRIPT
                          else $toc:ALL-FUNCTIONS"/>
    <xsl:variable name="buckets"
                  select="distinct-values($functions/@bucket)"/>

    <!-- for each bucket -->
    <xsl:for-each select="$buckets">
      <xsl:sort select="index-of($forced-order, .)" order="ascending"/>
      <xsl:sort select="."/>

      <xsl:variable name="bucket" select="."/>
      <xsl:variable name="bucket-id" select="translate($bucket,' ','')"/>

      <xsl:variable name="is-REST" select="$bucket eq 'REST Resources API'"/>

      <!-- bucket node -->
      <!-- ID for function buckets is the display name minus spaces -->
      <!-- async is ignored for REST, because we ignore this <node> container -->
      <node display="{.}" id="{$bucket-id}" sub-control="yes" async="yes">
        <xsl:if test="$mode eq 'javascript'">
          <xsl:attribute name="is-javascript" select="true()"/>
        </xsl:if>

        <xsl:variable name="in-this-bucket"
                      select="$functions[@bucket eq $bucket]"/>

        <!-- for each category -->
        <xsl:for-each select="distinct-values($in-this-bucket/@category)">
          <xsl:sort select="."/>
          <xsl:variable name="category" select="."/>
          <xsl:variable name="in-this-category" select="$in-this-bucket[@category eq $category]"/>

          <xsl:variable name="single-lib-for-category" select="toc:lib-for-all($in-this-category)"/>

          <xsl:variable name="is-exhaustive" select="toc:category-is-exhaustive($category, (), $single-lib-for-category)"/>

          <xsl:variable name="sub-categories" select="distinct-values($in-this-category/@subcategory)"/>

          <!-- category node -->
          <node id="{$bucket-id}_{translate(.,' ','')}"
                function-list-page="yes"
                display="{
                         toc:display-category(.)}{
                         toc:display-suffix($single-lib-for-category)}" >
            <xsl:if test="$mode eq 'javascript'">
              <xsl:attribute name="is-javascript" select="true()"/>
            </xsl:if>

            <!-- When there are sub-categories, don't create a new page for the category (they tend to be useless);
                 only create a link if it corresponds to a full lib page -->
            <xsl:choose>
              <xsl:when test="$is-exhaustive">
                <xsl:attribute name="href" select="concat('/',$single-lib-for-category)"/>
              </xsl:when>
              <!-- Create a new page for this category if it doesn't contain sub-categories
                   and does not already correspond to a full lib page,
                   unless it's a REST doc category, in which case we do want to create the category page (e.g., for Client API)  -->
              <xsl:when test="not($sub-categories) or $is-REST">

                <!-- ASSUMPTION: $single-lib-for-category is supplied/applicable if we are in this code branch;
                                 in other words, every top-level category page only pertains to one library (sub-categories can have more than one; see below). -->
                <xsl:attribute name="href" select="concat('/',$single-lib-for-category,
                                                          '/',toc:path-for-category(.))"/>

                <xsl:attribute name="category-name" select="toc:display-category(.)"/>

                <xsl:copy-of select="if ($is-REST) then toc:REST-page-title($category, ())
                                                   else toc:category-page-title(., $single-lib-for-category, ())"/>

                <intro>
                  <xsl:apply-templates mode="render-summary" select="toc:get-summary-for-category($category,(),$single-lib-for-category)"/>
                </intro>
              </xsl:when>
              <!-- otherwise, don't create a page/link for this category -->
            </xsl:choose>

            <!-- ASSUMPTION: A category has either functions as children or sub-categories, never both -->
            <xsl:choose>
              <xsl:when test="not($sub-categories)">
                <!-- function TOC nodes -->
                <xsl:apply-templates
                    select="toc:function-name-nodes($in-this-category)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:for-each select="$sub-categories">
                  <xsl:sort select="."/>
                  <xsl:variable name="subcategory" select="."/>

                  <xsl:variable name="in-this-subcategory" select="$in-this-category[@subcategory eq $subcategory]"/>

                  <xsl:variable  name="one-subcategory-lib" select="toc:lib-for-all($in-this-subcategory)"/>
                  <xsl:variable name="main-subcategory-lib" select="toc:primary-lib($in-this-subcategory)"/>

                  <xsl:variable name="is-exhaustive" select="toc:category-is-exhaustive($category, $subcategory, $one-subcategory-lib)"/>

                  <xsl:variable name="href"
                                select="if ($is-exhaustive) then concat('/', $one-subcategory-lib)
                                                                                                                   (: REST docs include category in path :)
                                               else if ($is-REST)       then concat('/', $one-subcategory-lib, '/', toc:path-for-category($category), '/', toc:path-for-category(.))
                                                                        else concat('/', $main-subcategory-lib,                                       '/', toc:path-for-category(.))"/>

                  <!-- Only display, e.g, "(xdmp:)" if just one library is represented in this sub-category and if the parent category doesn't already display it -->
                  <xsl:variable name="suffix" select="if ($one-subcategory-lib and not($single-lib-for-category))
                                                      then toc:display-suffix($one-subcategory-lib)
                                                      else ()"/>

                  <node href="{$href}" display="{toc:display-category(.)}{$suffix}" function-list-page="yes">
                    <!-- We already have the intro text if this is a lib-exhaustive category -->
                    <xsl:if test="not($is-exhaustive)">
                      <xsl:attribute name="category-name" select="toc:display-category(.)"/>

                      <xsl:variable name="secondary-lib"
                                    select="if (not($one-subcategory-lib)) then ($in-this-subcategory/@lib[not(. eq $main-subcategory-lib)])[1]
                                                                           else ()"/>

                      <xsl:copy-of select="if ($is-REST) then toc:REST-page-title($category, $subcategory)
                                                         else toc:category-page-title(., $main-subcategory-lib, $secondary-lib)"/>

                      <intro>
                        <xsl:apply-templates mode="render-summary" select="toc:get-summary-for-category($category, $subcategory, $main-subcategory-lib)"/>
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

</xsl:stylesheet>
