<!-- This stylesheet constructs the "Functions by category"
     portion of the TOC hierarchy. -->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:api="http://marklogic.com/rundmc/api"
  xmlns:apidoc="http://marklogic.com/xdmp/apidoc"
  xmlns:toc="http://marklogic.com/rundmc/api/toc"
  xmlns:u  ="http://marklogic.com/rundmc/util"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:raw="http://marklogic.com/rundmc/raw-docs-access"
  extension-element-prefixes="xdmp"
  exclude-result-prefixes="xs api apidoc toc u raw">

  <!-- We look back into the raw docs database to get the introductory content for each function list page -->
  <xdmp:import-module namespace="http://marklogic.com/rundmc/raw-docs-access" href="/apidoc/setup/raw-docs-access.xqy"/>

  <xsl:variable name="all-functions" select="$api:all-function-docs/api:function-page/api:function[1]"/>

  <!-- This is for specifying exceptions to the automated mappings of categories to URLs -->
  <xsl:variable name="category-mappings" select="u:get-doc('/apidoc/config/category-mappings.xml')/*/category"/>

  <!-- This is bound to be slow, but that's okay, because we pre-generate this TOC -->
  <xsl:template name="functions-by-category">

    <xsl:variable name="forced-order" select="('MarkLogic Built-In Functions',
	  'XQuery Library Modules', 'CPF Functions', 'W3C-Standard Functions',
          'REST Resources API')"/>

    <!-- for each bucket -->
    <xsl:for-each select="distinct-values($all-functions/@bucket)">
      <xsl:sort select="index-of($forced-order, .)" order="ascending"/>
      <xsl:sort select="."/>

      <xsl:variable name="bucket" select="."/>
      <xsl:variable name="bucket-id" select="translate($bucket,' ','')"/>

      <xsl:variable name="is-REST" select="$bucket eq 'REST Resources API'"/>

      <!-- bucket node --> <!-- ID for function buckets is the display name minus spaces -->
      <node display="{.}" id="{$bucket-id}" sub-control="yes" async="yes"> <!-- async is ignored for REST, because we ignore this <node> container -->

        <xsl:variable name="in-this-bucket" select="$all-functions[@bucket eq $bucket]"/>

        <!-- for each category -->
        <xsl:for-each select="distinct-values($in-this-bucket/@category)">
          <xsl:sort select="."/>
          <xsl:variable name="category" select="."/>
          <xsl:variable name="in-this-category" select="$in-this-bucket[@category eq $category]"/>

          <xsl:variable name="single-lib-for-category" select="toc:lib-for-all($in-this-category)"/>

          <xsl:variable name="is-exhaustive" select="toc:category-is-exhaustive($category, (), $single-lib-for-category)"/>

          <xsl:variable name="sub-categories" select="distinct-values($in-this-category/@subcategory)"/>

          <!-- category node -->
          <node display="{toc:display-category(.)}{toc:display-suffix($single-lib-for-category)}" function-list-page="yes" id="{$bucket-id}_{translate(.,' ','')}">

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
                <xsl:apply-templates select="toc:function-name-nodes($in-this-category)"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:for-each select="$sub-categories">
                  <xsl:sort select="."/>
                  <xsl:variable name="subcategory" select="."/>

                  <xsl:variable name="in-this-subcategory" select="$in-this-category[@subcategory eq $subcategory]"/>

                  <xsl:variable  name="one-subcategory-lib" select="toc:lib-for-all($in-this-subcategory)"/>
                  <xsl:variable name="main-subcategory-lib" select="toc:primary-lib($in-this-subcategory)"/>

                  <xsl:variable name="is-exhaustive" select="toc:category-is-exhaustive($category, $subcategory, $one-subcategory-lib)"/>

                  <xsl:variable name="href" select="if ($is-exhaustive) then concat('/', $one-subcategory-lib)
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

          <xsl:function name="toc:display-category">
            <xsl:param name="cat"/>
            <xsl:sequence select="if (ends-with($cat,'Builtins')) then substring-before($cat,'Builtins') else $cat"/>
          </xsl:function>

          <xsl:function name="toc:path-for-category">
            <xsl:param name="cat"/>
            <xsl:variable name="explicitly-specified" select="$category-mappings[@from eq $cat]/@to"/>
            <xsl:sequence select="if ($explicitly-specified)
                                 then $explicitly-specified
                                 else translate(lower-case(toc:display-category($cat)), ' ', '-')"/>
          </xsl:function>

          <xsl:function name="toc:category-page-title">
            <xsl:param name="cat"/>
            <xsl:param name="lib"/>
            <xsl:param name="secondary-lib"/>
            <title>
              <a href="/{$lib}">
                <xsl:value-of select="api:prefix-for-lib($lib)"/>
              </a>
              <xsl:text> functions (</xsl:text>
              <xsl:value-of select="toc:display-category($cat)"/>
              <xsl:text>)</xsl:text>
              <xsl:if test="$secondary-lib">
                <xsl:text> and </xsl:text>
                <a href="/{$secondary-lib}">
                  <xsl:value-of select="api:prefix-for-lib($secondary-lib)"/>
                </a>
                <xsl:text> functions</xsl:text>
              </xsl:if>
            </title>
          </xsl:function>

          <xsl:function name="toc:REST-page-title">
            <xsl:param name="category"/>
            <xsl:param name="subcategory"/>
            <title>
              <xsl:value-of select="$category"/>
              <xsl:if test="$subcategory">
                <xsl:text> (</xsl:text>
                <xsl:value-of select="$subcategory"/>
                <xsl:text>)</xsl:text>
              </xsl:if>
            </title>
          </xsl:function>

          <xsl:function name="toc:function-name-nodes">
            <xsl:param name="functions"/>
            <!-- NOTE: These elements are intentionally siblings (not parentless), so the TOC construction
                       code has the option of inspecting their siblings.  -->
            <xsl:variable name="wrapper">
              <xsl:for-each select="$functions">
                <!-- By default, just use alphabetical order.
                     But for REST docs, first sort by the resource name... -->
                <xsl:sort select="if (@lib eq 'REST') then api:name-from-REST-fullname(@fullname)
                                                      else @fullname"/>
                <!-- ...and then the HTTP method (only applicable to REST docs) -->
                <xsl:sort select="api:verb-sort-key-from-REST-fullname(@fullname)"/>
                <api:function-name>
                  <xsl:value-of select="@fullname"/>
                </api:function-name>
              </xsl:for-each>
            </xsl:variable>
            <xsl:sequence select="$wrapper/api:function-name"/>
          </xsl:function>


          <!-- Returns the one library string if all the functions are in the same library; otherwise returns empty -->
          <xsl:function name="toc:lib-for-all" as="xs:string?">
            <xsl:param name="functions"/>
            <xsl:variable name="libs" select="distinct-values($functions/@lib)"/>
            <xsl:sequence select="if (count($libs) eq 1) then string(($functions/@lib)[1])
                                                         else ()"/>
          </xsl:function>

          <!-- Uses toc:lib-for-most() (because I already implemented it) but favors "xdmp" as primary regardless -->
          <xsl:function name="toc:primary-lib" as="xs:string">
            <xsl:param name="functions"/>
            <xsl:variable name="libs" select="distinct-values($functions/@lib)"/>
            <xsl:sequence select="if ($libs = 'xdmp') then 'xdmp' else toc:lib-for-most($functions)"/>
          </xsl:function>

          <!-- Returns the most common library string among the given functions
               (handles the unique "XSLT" and "JSON" subcategories which each represent more than one library) -->
          <xsl:function name="toc:lib-for-most" as="xs:string">
            <xsl:param name="functions"/>
            <xsl:variable name="libs" select="distinct-values($functions/@lib)"/>
            <xsl:variable name="counts">
              <xsl:for-each select="$libs">
                <lib name="{.}" count="{count($functions[@lib eq current()])}"/>
              </xsl:for-each>
            </xsl:variable>
            <xsl:sequence select="$counts/lib[number(@count) eq max(../lib/@count)][1]/@name"/>
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
            <!-- Don't display a suffix for REST categories -->
            <xsl:sequence select="if ($lib-for-all eq 'REST') then ()
                             else if ($lib-for-all)           then concat(' (', api:prefix-for-lib($lib-for-all), ':)')
                                                              else ()"/>
          </xsl:function>

          <xsl:function name="toc:get-summary-for-category" as="element()*">
            <xsl:param name="cat"/>
            <xsl:param name="subcat"/>
            <xsl:param name="lib"/>
            <xsl:variable name="summaries-with-category" select="$raw:api-docs/apidoc:module/apidoc:summary[@category eq $cat][@subcategory eq $subcat or not($subcat)]"/>
            <xsl:variable name="modules-with-category"   select="$raw:api-docs/apidoc:module               [@category eq $cat][@subcategory eq $subcat or not($subcat)]"/>

            <!-- Fallback boilerplate is different for library modules than for built-in libs  -->
            <xsl:variable name="fallback">
              <xsl:choose>
                <!-- the admin library sub-pages don't have their own descriptions currently; use this boilerplate instead -->
                <xsl:when test="$lib = $all-libs[not(@built-in)]">
                  <apidoc:summary>
                    <p>For information on how to import the functions in this module, refer to the main <a href="/{$lib}"><xsl:value-of select="api:prefix-for-lib($lib)"/> library page</a>.</p>
                  </apidoc:summary>
                </xsl:when>
                <!-- some of the xdmp sub-pages don't have descriptions either, so use this -->
                <xsl:otherwise>
                  <apidoc:summary>
                    <p>For the complete list of functions and categories in this namespace, refer to the main <a href="/{$lib}"><xsl:value-of select="api:prefix-for-lib($lib)"/> functions page</a>.</p>
                  </apidoc:summary>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>

            <xsl:sequence select="if ($summaries-with-category)
                                 then $summaries-with-category
                             else if ($modules-with-category/apidoc:summary)
                                 then $modules-with-category/apidoc:summary
                             else $fallback/apidoc:summary"/>
          </xsl:function>


          <!-- We only want to see one summary -->
          <xsl:function name="toc:get-summary-for-lib" as="element()?">
            <xsl:param name="lib"/>

            <!-- exceptional ("json" built-in) -->
            <xsl:variable name="summaries-by-summary-subcat" select="$raw:api-docs/apidoc:module/apidoc:summary[@subcategory eq toc:hard-coded-subcategory($lib)]"/>
            <!-- exceptional ("spell" built-in) -->
            <xsl:variable name="summaries-by-module-cat"  select="$raw:api-docs/apidoc:module[@category eq toc:hard-coded-category($lib)]/apidoc:summary"/>
            <!-- the most common case -->
            <xsl:variable name="summaries-by-module-lib"  select="$raw:api-docs/apidoc:module               [@lib eq api:prefix-for-lib($lib)]/apidoc:summary"/>
            <!-- exceptional ("map") -->
            <xsl:variable name="summaries-by-summary-lib" select="$raw:api-docs/apidoc:module/apidoc:summary[@lib eq api:prefix-for-lib($lib)]"/>
            <!-- exceptional ("dls") -->
            <xsl:variable name="summaries-by-module-lib-no-subcat" select="$summaries-by-module-lib[not(@subcategory)]"/>

            <xsl:sequence select="if (count($summaries-by-summary-subcat) eq 1)
                                       then $summaries-by-summary-subcat
                             else if (count($summaries-by-module-lib) eq 1)
                                       then $summaries-by-module-lib
                             else if (count($summaries-by-module-lib) eq 1)
                                       then $summaries-by-module-lib
                             else if (count($summaries-by-summary-lib) eq 1)
                                       then $summaries-by-summary-lib
                             else if (count($summaries-by-module-lib-no-subcat) eq 1)
                                       then $summaries-by-module-lib-no-subcat
                             else ()"/>
          </xsl:function>

                  <!-- Look in the  namespaces/libs config file to see if we've forced a hard-coded category (for summary-lookup purposes) -->
                  <xsl:function name="toc:hard-coded-category" as="xs:string?">
                    <xsl:param name="lib"/>
                    <xsl:sequence select="$api:namespace-mappings[@lib eq $lib]/@category/string(.)"/>
                  </xsl:function>

                  <!-- Look in the  namespaces/libs config file to see if we've forced a hard-coded subcategory (for summary-lookup purposes) -->
                  <xsl:function name="toc:hard-coded-subcategory" as="xs:string?">
                    <xsl:param name="lib"/>
                    <xsl:sequence select="$api:namespace-mappings[@lib eq $lib]/@subcategory/string(.)"/>
                  </xsl:function>

</xsl:stylesheet>
