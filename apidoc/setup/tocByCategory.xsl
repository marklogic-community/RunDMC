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
  xmlns:docapp="http://marklogic.com/rundmc/docapp-data-access"
  extension-element-prefixes="xdmp"
  exclude-result-prefixes="xs api apidoc toc u docapp">

  <!-- We look back into the docapp database to get the introductory content for each function list page -->
  <xdmp:import-module namespace="http://marklogic.com/rundmc/docapp-data-access" href="/apidoc/setup/docapp-data-access.xqy"/>

  <xsl:variable name="all-functions" select="$api:all-function-docs/api:function-page/api:function"/>

  <!-- This is for specifying exceptions to the automated mappings of categories to URLs -->
  <xsl:variable name="category-mappings" select="u:get-doc('/apidoc/config/category-mappings.xml')/*/category"/>

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

          <xsl:variable name="single-lib-for-category" select="toc:lib-for-all($in-this-category)"/>

          <xsl:variable name="is-exhaustive" select="toc:category-is-exhaustive($category, (), $single-lib-for-category)"/>

          <xsl:variable name="sub-categories" select="distinct-values($in-this-category/@subcategory)"/>

          <!-- category node -->
          <node display="{toc:display-category(.)}{toc:display-suffix($single-lib-for-category)}">

            <!-- When there are sub-categories, don't create a new page for the category (they tend to be useless);
                 only create a link if it corresponds to a full lib page -->
            <xsl:choose>
              <xsl:when test="$is-exhaustive">
                <xsl:attribute name="href" select="concat('/',$single-lib-for-category)"/>
              </xsl:when>
              <!-- Create a new page for this category if it doesn't contain sub-categories
                   and does not already correspond to a full lib page -->
              <xsl:when test="not($sub-categories)">

                <!-- ASSUMPTION: $single-lib-for-category is supplied/applicable if we are in this code branch;
                                 in other words, every function list page only pertains to one library, at least ostensibly ("exsl" exception below). -->
                <xsl:attribute name="href" select="concat('/',$single-lib-for-category,
                                                          '/',toc:path-for-category(.))"/>

                <xsl:attribute name="title" select="toc:category-page-title(., $single-lib-for-category)"/>

                <!-- Used to trigger adding a link to the title of the resulting page -->
                <xsl:attribute name="type" select="'function-category'"/>

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

                  <xsl:variable name="subcategory-lib" select="toc:lib-for-all($in-this-subcategory)"/>

                  <xsl:variable name="is-exhaustive" select="toc:category-is-exhaustive($category, $subcategory, $subcategory-lib)"/>

                  <xsl:variable name="href" select="concat('/', $subcategory-lib,
                   if ($is-exhaustive) then () else concat('/', toc:path-for-category(.)))"/>

                  <!-- Don't display, e.g, "(xdmp:)" if the parent node already has it -->
                  <!-- ASSUMPTION: $subcategory-lib will always be supplied: subcategories always pertain to only one lib, except for the "exsl" exception (see below) -->
                  <xsl:variable name="suffix" select="if ($single-lib-for-category)
                                                      then ()
                                                      else toc:display-suffix($subcategory-lib)"/>

                  <node href="{$href}" display="{toc:display-category(.)}{$suffix}">
                    <!-- We already have the intro text if this is a lib-exhaustive category -->
                    <xsl:if test="not($is-exhaustive)">
                      <xsl:attribute name="title" select="toc:category-page-title(., $subcategory-lib)"/>

                      <!-- Used to trigger adding a link to the title of the resulting page -->
                      <xsl:attribute name="type" select="'function-category'"/>

                      <intro>
                        <xsl:apply-templates mode="render-summary" select="toc:get-summary-for-category($category, $subcategory, $subcategory-lib)"/>
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
            <xsl:value-of select="$lib"/>
            <!-- toc.xsl depends on this format (category name in parentheses)
                 to determine what sub-pages to list on the main lib page;
                 so don't change this without changing it there also -->
            <xsl:text> functions (</xsl:text>
            <xsl:value-of select="toc:display-category($cat)"/>
            <xsl:text>)</xsl:text>
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


          <!-- Returns true if all the functions are in the same library (special case: not counting "exsl") -->
          <xsl:function name="toc:lib-for-all" as="xs:string?">
            <xsl:param name="functions"/>
            <xsl:variable name="libs" select="distinct-values($functions/@lib)"/>
            <xsl:sequence select="if (count($libs) eq 1 
                                   or count($libs) eq 2 and $libs = 'exsl') (: special-case: don't let the presence of exsl count :)
                                  then string(($functions/@lib
                                                        [. ne 'exsl' or (every $lib in $functions/@lib satisfies ($lib eq 'exsl'))]
                                              )[1]
                                             )
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

          <xsl:function name="toc:get-summary-for-category" as="element()*">
            <xsl:param name="cat"/>
            <xsl:param name="subcat"/>
            <xsl:param name="lib"/>
            <xsl:variable name="summaries-with-category" select="$docapp:docs/apidoc:module/apidoc:summary[@category eq $cat][@subcategory eq $subcat or not($subcat)]"/>
            <xsl:variable name="modules-with-category"   select="$docapp:docs/apidoc:module               [@category eq $cat][@subcategory eq $subcat or not($subcat)]"/>

            <!-- Fallback boilerplate is different for library modules than for built-in libs  -->
            <xsl:variable name="fallback">
              <xsl:choose>
                <!-- the admin library sub-pages don't have their own descriptions currently; use this boilerplate instead -->
                <xsl:when test="$lib = $all-libs[not(@built-in)]">
                  <apidoc:summary>
                    <p>For information on how to import the functions in this module, refer to the main <a href="/{$lib}"><xsl:value-of select="$lib"/> library page</a>.</p>
                  </apidoc:summary>
                </xsl:when>
                <!-- some of the xdmp sub-pages don't have descriptions either, so use this -->
                <xsl:otherwise>
                  <apidoc:summary>
                    <p>For the complete list of functions and categories in this namespace, refer to the main <a href="/{$lib}"><xsl:value-of select="$lib"/> functions page</a>.</p>
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

            <!-- exceptional ("spell" built-in) -->
            <xsl:variable name="summaries-by-module-cat"  select="$docapp:docs/apidoc:module[@category eq toc:hard-coded-category($lib)]/apidoc:summary"/>
            <!-- the most common case -->
            <xsl:variable name="summaries-by-module-lib"  select="$docapp:docs/apidoc:module               [@lib eq api:prefix-for-lib($lib)]/apidoc:summary"/>
            <!-- exceptional ("map") -->
            <xsl:variable name="summaries-by-summary-lib" select="$docapp:docs/apidoc:module/apidoc:summary[@lib eq api:prefix-for-lib($lib)]"/>
            <!-- exceptional ("dls") -->
            <xsl:variable name="summaries-by-module-lib-no-subcat" select="$summaries-by-module-lib[not(@subcategory)]"/>

            <xsl:sequence select="if (count($summaries-by-module-cat) eq 1)
                                       then $summaries-by-module-cat
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

</xsl:stylesheet>
