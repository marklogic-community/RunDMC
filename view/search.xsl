<!-- Search-specific tag library and auxiliary rules -->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:search="http://marklogic.com/appservices/search"
  xmlns:cts   ="http://marklogic.com/cts"
  xmlns:u    ="http://marklogic.com/rundmc/util"
  xmlns:qp   ="http://www.marklogic.com/ps/lib/queryparams"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns:srv  ="http://marklogic.com/rundmc/server-urls"
  xmlns:api  ="http://marklogic.com/rundmc/api"
  xmlns:ck   ="http://parthcomp.com/cookies"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp qp search cts srv api ck">

  <xsl:variable name="versions" select="u:get-doc('/config/server-versions.xml')/*:versions/*:version"/>

  <xsl:variable name="set-version-param-name" select="'v'"/>
  <xsl:variable name="set-version"            select="string($params[@name eq $set-version-param-name])"/>

  <xsl:variable name="preferred-version-cookie" select="ck:get-cookie('preferred-version')"/>
  <xsl:variable name="preferred-version" select="if ($set-version)
                                                then $set-version
                                            else if ($preferred-version-cookie)
                                                then $preferred-version-cookie
                                            else     $ml:default-version"/>

  <xsl:variable name="_set-cookie"
                select="if ($set-version) then ck:add-cookie('preferred-version',
                                                             $set-version,
                                                             xs:dateTime('2100-01-01T12:00:00'), (: expires :)
                                                             (),
                                                             '/search',
                                                             false())
                                          else ()"/>


  <!-- Don't keep an <a> tag if it was inserted into an existing <a> tag
       as a result of search hit highlighting -->
  <xsl:template match="xhtml:a//xhtml:a[contains(string(@class), 'hit_highlight')]">
    <span class="hit_highlight">
      <xsl:apply-templates/>
    </span>
  </xsl:template>


  <!-- The "Server version" switcher code;
       this is also customized in apidoc/view/page.xsl -->
  <xsl:template mode="version-list" match="*">
    <div class="version">
      <span>Server version:</span>
      <xsl:text> </xsl:text>
      <xsl:apply-templates mode="version-list-item" select="$versions"/>
    </div>
  </xsl:template>

          <!-- separator between each version -->
          <xsl:template mode="version-list-item" match="*:version">
            <xsl:apply-templates mode="version-list-item-selected-or-not" select="."/>
            <xsl:if test="position() ne last()"> | </xsl:if>
          </xsl:template>

                  <!-- selected -->
                  <xsl:template mode="version-list-item-selected-or-not" match="*:version[@number eq $preferred-version]"
                                name="show-selected-version"> 
                    <b>
                      <xsl:apply-templates mode="version-number-display" select="."/>
                    </b>
                  </xsl:template>

                          <!-- Display 5.0 as "MarkLogic 5" -->
                          <xsl:template mode="version-number-display" match="*:version[@number eq '5.0']">MarkLogic 5</xsl:template>
                          <xsl:template mode="version-number-display" match="*:version">
                            <xsl:value-of select="@number"/>
                          </xsl:template>

                  <!-- not selected -->
                  <xsl:template mode="version-list-item-selected-or-not" match="*:version"
                                name="show-unselected-version">
                    <xsl:variable name="href">
                      <xsl:apply-templates mode="version-list-item-href" select="."/>
                    </xsl:variable>
                    <a href="{$href}">
                      <xsl:apply-templates mode="version-number-display" select="."/>
                    </a>
                  </xsl:template>

                          <!-- version-specific results URL -->
                          <xsl:template mode="version-list-item-href" match="*:version">
                            <xsl:sequence select="concat('/search?q=', $q, '&amp;', $set-version-param-name, '=', @number)"/>
                          </xsl:template>


  <xsl:variable name="search-options" as="element()">
    <search:options>
      <xsl:copy-of select="$common-search-options"/>
      <search:return-query>true</search:return-query>

      <!-- If this is an empty search and the category is xccn, then don't snippet
           (workaround for stack overflow in snippeting functions, particularly against
            /pubs/5.0/dotnet/Marklogic.Xcc.Types.Duration.Minutes.html) -->
      <xsl:if test="$q eq 'cat:xccn'">
        <search:transform-results apply="empty-snippet"/>
      </xsl:if>

    </search:options>
  </xsl:variable>

  <xsl:variable name="facet-options" as="element()">
    <search:options>
      <xsl:copy-of select="$common-search-options"/>
      <search:return-results>false</search:return-results>
    </search:options>
  </xsl:variable>

          <xsl:variable name="common-search-options" as="element()*">
            <search:additional-query>
              <xsl:copy-of select="ml:search-corpus-query($preferred-version)"/>
            </search:additional-query>
            <search:constraint name="cat">
              <search:collection prefix="category/"/>
            </search:constraint>
          </xsl:variable>

  <xsl:variable name="q" select="string($params[@name eq 'q'])"/>

  <xsl:variable name="search-response" as="element(search:response)">
    <xsl:variable name="results-per-page" select="10"/>
    <xsl:variable name="start" select="ml:start-index($results-per-page)"/>
    <!-- Adding the document wrapper is a workaround for XSLTBUG 13062 -->
    <xsl:variable name="search-response-doc">
      <xsl:copy-of select="search:search($q,
                                         $search-options,
                                         $start,
                                         $results-per-page
                                        )"/>
    </xsl:variable>
    <xsl:sequence select="$search-response-doc/search:response"/>
  </xsl:variable>

  <xsl:variable name="facets-response" as="element(search:response)">
    <xsl:choose>
      <!-- When a category constraint isn't supplied, just use the main search results;
           (don't run search:search again) -->
      <xsl:when test="not(contains($q,'cat:'))">
        <xsl:sequence select="$search-response"/>
      </xsl:when>
      <!-- Otherwise, run the search without the category constraint, so we get the full list of facet values -->
      <xsl:otherwise>
        <!-- Adding the document wrapper is a workaround for XSLTBUG 13062 -->
        <xsl:variable name="response-doc">
          <xsl:copy-of select="search:search(ml:qtext-with-no-constraints($search-response,$search-options),
                                             $facet-options)"/>
        </xsl:variable>
        <xsl:sequence select="$response-doc/search:response"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:variable>

          <xsl:function name="ml:qtext-with-no-constraints" as="xs:string">
            <xsl:param name="response" as="element(search:response)"/>
            <xsl:param name="options" as="element(search:options)"/>
            <xsl:variable name="constraints" select="$response/search:query//@qtextconst"/>
            <xsl:sequence select="ml:remove-constraints($response/search:qtext, $constraints, $options)"/>
          </xsl:function>

          <!-- Remove constraints recursively, in case someone tries to enter two constraints -->
          <xsl:function name="ml:remove-constraints" as="xs:string">
            <xsl:param name="q" as="xs:string"/>
            <xsl:param name="constraints" as="xs:string*"/>
            <xsl:param name="options" as="element(search:options)"/>
            <xsl:choose>
              <xsl:when test="not($constraints)">
                <xsl:sequence select="$q"/>
              </xsl:when>
              <xsl:otherwise>
                <xsl:variable name="new-q" select="search:remove-constraint($q, $constraints[1], $options)"/>
                <xsl:sequence select="if (count($constraints) gt 1) then ml:remove-constraints($new-q,$constraints[position() gt 1],$options)
                                                                    else $new-q"/>
              </xsl:otherwise>
            </xsl:choose>
          </xsl:function>


  <xsl:template match="sub-nav[$external-uri eq '/search']">
    <section>
      <xsl:value-of select="$_set-cookie"/> <!-- empty sequence; evaluate for side effect only -->
      <xsl:apply-templates mode="facet" select="$facets-response/search:facet"/>
    </section>
  </xsl:template>


  <xsl:template match="search-results">
    <xsl:if test="$DEBUG">
      <xsl:copy-of select="$search-response"/>
      <xsl:copy-of select="$facets-response"/>
    </xsl:if>
    <xsl:apply-templates mode="search-results" select="$search-response"/>
  </xsl:template>

          <xsl:template mode="search-results" match="search:response[@total eq 0]">
            <h3>
              <xsl:text>Your search – </xsl:text>
              <em>
                <xsl:value-of select="search:qtext"/>
              </em>
              <xsl:text> – did not match any documents.</xsl:text>
            </h3>
          </xsl:template>

          <xsl:template mode="search-results" match="search:response">
            <xsl:variable name="last-in-full-page" select="@start + @page-length - 1"/>
            <xsl:variable name="end-result-index"  select="if (@total lt @page-length or $last-in-full-page gt @total) then @total
                                                      else $last-in-full-page"/>
            <h3>
              <xsl:text>Results </xsl:text>
              <em>
                <xsl:value-of select="@start"/>–<xsl:value-of select="$end-result-index"/>
              </em>
              <xsl:text> of </xsl:text>
              <xsl:value-of select="@total"/>
              <xsl:text> for </xsl:text>
              <em>
                <xsl:value-of select="search:qtext"/>
              </em>
            </h3>
            <xsl:apply-templates mode="prev-and-next" select="."/>
            <table>
              <xsl:apply-templates mode="#current" select="search:result"/>
            </table>
            <xsl:apply-templates mode="prev-and-next" select="."/>
          </xsl:template>

          <!-- Temporary, only used until we enable api.marklogic.com -->
          <xsl:variable name="guide-configs" select="u:get-doc('/apidoc/config/document-list.xml')/*/*:guide"/>
          <xsl:variable name="functions-4.1" select="u:get-doc('/config/4.1-function-url-mappings.xml')/*/*:function"/>
          <xsl:variable name="functions-4.2" select="u:get-doc('/config/4.2-function-url-mappings.xml')/*/*:function"/>
          <xsl:variable name="functions-5.0" select="u:get-doc('/config/5.0-function-url-mappings.xml')/*/*:function"/>

          <xsl:template mode="search-results" match="search:result">
            <xsl:variable name="is-flat-file" select="starts-with(@uri, '/pubs/')"/>
            <xsl:variable name="doc" select="doc(@uri)"/>
            <xsl:variable name="is-api-doc" select="starts-with(@uri,'/apidoc/')"/>
            <xsl:variable name="api-version" select="substring-before(substring-after(@uri,'/apidoc/'),'/')"/>
            <xsl:variable name="version-prefix" select="if ($api-version eq $ml:default-version) then '' else concat('/',$api-version)"/>
            <!-- Temporary, until we enable api.marklogic.com -->
            <xsl:variable name="result-uri" select="if ($is-api-doc) then (for $uri in ml:external-uri-api($doc) return
                                                                           concat('/pubs/', $api-version,
                                                                                  if (starts-with($uri,'/docs/')) then concat('/books/',$guide-configs[@url-name eq substring-after($uri,'/docs/')]/(@pdf-name,@source-name)[1], '.pdf')
                                                                                                                  else concat('/apidocs/',
                                                                                                                              (if ($api-version eq '4.1') then $functions-4.1
                                                                                                                          else if ($api-version eq '4.2') then $functions-4.2
                                                                                                                          else if ($api-version eq '5.0') then $functions-5.0
                                                                                                                          else ())
                                                                                                                               [@name eq substring-after($uri,'/')][1]/@url
                                                                                                                             )
                                                                                )
                                                                          )

                                                                     else concat($srv:main-server, if ($is-flat-file)
                                                                                                   then @uri
                                                                                                   else ml:external-uri-main($doc))"/>
            <!-- Re-enable this once we enable api.marklogic.com
            <xsl:variable name="result-uri" select="if ($is-api-doc) then concat($srv:api-server,  $version-prefix, ml:external-uri-api($doc))
                                                                     else concat($srv:main-server, if ($is-flat-file)
                                                                                                   then @uri
                                                                                                   else ml:external-uri-main($doc))"/>
                                                                                                   -->
            <tr>
              <th>
                <xsl:variable name="category">
                  <ml:category name="{ml:category-for-doc(@uri)}"/>
                </xsl:variable>
                <xsl:apply-templates mode="category-image" select="$category/*"/>
              </th>
              <td>
                <h4>
                  <!-- Highlighting until we find a better way (fully featured, not in URL) -->
                  <xsl:variable name="clean-q" select="ml:qtext-with-no-constraints($search-response, $search-options)"/>
                  <xsl:variable name="do-highlight" select="$clean-q and not(contains($result-uri,'#') or ends-with($result-uri,'.pdf')
                                                                                                       or ends-with($result-uri,'.html')
                                                                            )"/>
                  <xsl:variable name="hl-query-string" select="if ($do-highlight) then concat('?hl=',encode-for-uri($clean-q))
                                                                                  else ''"/>
                  <a href="{$result-uri}{$hl-query-string}">
                    <xsl:variable name="page-specific-title">
                      <xsl:apply-templates mode="page-specific-title" select="$doc/*"/>
                    </xsl:variable>
                    <xsl:value-of select="if (string($page-specific-title)) then $page-specific-title else @uri"/>
                  </a>
                </h4>
                <div class="text">
                  <xsl:apply-templates mode="search-snippet" select="search:snippet/search:match"/>
                </div>
              </td>
            </tr>
          </xsl:template>

                  <xsl:template mode="category-image" match="*">
                    <xsl:variable name="img-src">
                      <xsl:text>/images/</xsl:text>
                      <xsl:apply-templates mode="result-img-src" select="."/>
                      <xsl:text>.png</xsl:text>
                    </xsl:variable>
                    <xsl:variable name="img-alt">
                      <xsl:apply-templates mode="facet-value-display" select="."/>
                    </xsl:variable>
                    <xsl:variable name="img-width">
                      <xsl:apply-templates mode="result-img-width" select="."/>
                    </xsl:variable>
                    <xsl:variable name="img-height">
                      <xsl:apply-templates mode="result-img-height" select="."/>
                    </xsl:variable>
                    <img src   ="{$img-src}"
                         alt   ="{$img-alt}"
                         width ="{$img-width}"
                         height="{$img-height}"/>
                  </xsl:template>

                  <!-- Titles for flat HTML files (API docs usually) -->
                  <xsl:template mode="page-specific-title" match="*:html | *:HTML">
                    <xsl:variable name="common-suffix" select="' - MarkLogic Server Online Documentation'"/>
                    <xsl:variable name="title" select="( //*:title
                                                       | //*:TITLE)[1]" as="xs:string"/>
                    <xsl:value-of select="if (ends-with($title, $common-suffix)) then substring-before($title, $common-suffix)
                                                                                 else $title"/>
                  </xsl:template>

                  <xsl:template mode="page-specific-title" match="/guide" xpath-default-namespace="">
                    <xsl:value-of select="title"/>
                  </xsl:template>

                  <xsl:template mode="page-specific-title" match="api:function-page">
                    <xsl:value-of select="api:function[1]/@fullname"/>
                  </xsl:template>


                  <xsl:template mode="search-snippet" match="search:match">
                    <xsl:apply-templates mode="#current"/>
                    <xsl:if test="position() ne last()">…</xsl:if>
                  </xsl:template>

                  <xsl:template mode="search-snippet" match="search:highlight">
                    <span class="highlight">
                      <xsl:apply-templates mode="#current"/>
                    </span>
                  </xsl:template>


                  <xsl:template mode="prev-and-next" match="search:response">
                    <xsl:variable name="search-url" select="ml:external-uri(.)"/>
                    <form class="pagination" action="/search" method="get">
                      <div>
                        <xsl:if test="$page-number gt 1">
                          <a class="prev" href="{$search-url}?q={encode-for-uri($q)}&amp;p={$page-number - 1}">«</a>
                          <xsl:text> </xsl:text>
                        </xsl:if>
                        <label>
                          <xsl:text>Page </xsl:text>
                          <input name="p" type="text" value="{$page-number}" size="4"/>
                          <input name="q" type="hidden" value="{$q}"/>
                          <xsl:text> of </xsl:text>
                          <xsl:value-of select="ceiling(@total div @page-length)"/>
                        </label>
                        <xsl:if test="@total gt (@start + @page-length - 1)">
                          <xsl:text> </xsl:text>
                          <a class="next" href="{$search-url}?q={encode-for-uri($q)}&amp;p={$page-number + 1}">»</a>
                        </xsl:if>
                      </div>
                    </form>
                  </xsl:template>

  <xsl:template mode="facet" match="search:facet">
    <h2>
      <xsl:apply-templates mode="facet-name" select="@name"/>
    </h2>
    <ul class="categories">
      <xsl:apply-templates mode="facet-value" select="parent::search:response | search:facet-value">
        <xsl:sort select="@count | @total" order="descending" data-type="number"/>
      </xsl:apply-templates>
    </ul>
  </xsl:template>

          <xsl:template mode="facet-name" match="@name[. eq 'cat']">Categories</xsl:template>

                                                                       <!-- Using <search:response> to represent "all categories" -->
          <xsl:template mode="facet-value" match="search:facet-value | search:response">
            <xsl:variable name="this-constraint" select="self::search:facet-value/concat(../@name,':',@name)"/>
            <xsl:variable name="current-constraints" select="$search-response/search:query//@qtextconst/string(.)"/>
            <xsl:variable name="selected" select="$this-constraint  = $current-constraints
                                           or not($this-constraint or $current-constraints)"/>

            <xsl:variable name="clean-q" select="ml:qtext-with-no-constraints($search-response, $search-options)"/>
            <xsl:variable name="new-q" select="if (not($this-constraint)) then $clean-q
                                          else if ($clean-q) then concat('(', $clean-q, ')', ' AND ', $this-constraint)
                                          else $this-constraint"/>
            <li>
              <xsl:if test="$selected">
                <xsl:attribute name="class" select="'current'"/>
              </xsl:if>
              <a href="?q={encode-for-uri($new-q)}">
                <!-- this looks like an XSLT BUG, since I had to add string() to get any output
                <xsl:value-of select="."/>
                -->
                <!--
                <xsl:value-of select="string(.)"/>
                -->
                <xsl:variable name="category">
                  <ml:category name="{(@name,'all')[1]}"/>
                </xsl:variable>
                <xsl:apply-templates mode="category-image" select="$category/*"/>
                <xsl:text> </xsl:text>
                <xsl:apply-templates mode="facet-value-display" select="."/>
                <xsl:apply-templates mode="category-plural" select="."/>
                <xsl:text> [</xsl:text>
                <xsl:value-of select="@count | @total"/>
                <xsl:text>]</xsl:text>
              </a>
            </li>
          </xsl:template>

                  <!-- "All categories" is already plural -->
                  <xsl:template mode="category-plural" match="search:response"/>
                  <xsl:template mode="category-plural" match="*">s</xsl:template>

                  <xsl:template mode="facet-value-display" match="search:response       ">All categories</xsl:template>

                  <xsl:template mode="facet-value-display" match="*[@name eq 'blog']    ">Blog post</xsl:template>
                  <xsl:template mode="facet-value-display" match="*[@name eq 'code']    ">Open-source project</xsl:template>
                  <xsl:template mode="facet-value-display" match="*[@name eq 'event']   ">Event</xsl:template>
                  <xsl:template mode="facet-value-display" match="*[@name eq 'function']">Function page</xsl:template>
                  <xsl:template mode="facet-value-display" match="*[@name eq 'guide']   ">User guide</xsl:template>
                  <xsl:template mode="facet-value-display" match="*[@name eq 'news']    ">News item</xsl:template>
                  <xsl:template mode="facet-value-display" match="*[@name eq 'tutorial']">Tutorial</xsl:template>
                  <xsl:template mode="facet-value-display" match="*[@name eq 'xcc']     ">XCC Connector Javadoc</xsl:template>
                  <xsl:template mode="facet-value-display" match="*[@name eq 'xccn']    ">XCC Connector .Net doc</xsl:template>
                  <xsl:template mode="facet-value-display" match="*[@name eq 'other']   ">Miscellaneous page</xsl:template>

                  <!-- Search result icon file names -->
                  <xsl:template mode="result-img-src" match="*[@name eq 'all']     ">i_mag_logo_small</xsl:template>
                  <xsl:template mode="result-img-src" match="*[@name eq 'blog']    ">i_rss_small</xsl:template>
                  <xsl:template mode="result-img-src" match="*[@name eq 'code']    ">i_opensource</xsl:template>
                  <xsl:template mode="result-img-src" match="*[@name eq 'event']   ">i_calendar</xsl:template>
                  <xsl:template mode="result-img-src" match="*[@name eq 'function']">i_function</xsl:template>
                  <xsl:template mode="result-img-src" match="*[@name eq 'guide']   ">i_documentation</xsl:template>
                  <xsl:template mode="result-img-src" match="*[@name eq 'news']    ">i_newspaper</xsl:template>
                  <xsl:template mode="result-img-src" match="*[@name eq 'tutorial']">i_monitor</xsl:template>
                  <xsl:template mode="result-img-src" match="*[@name eq 'xcc']     ">i_java</xsl:template>
                  <xsl:template mode="result-img-src" match="*[@name eq 'xccn']    ">i_dotnet</xsl:template>
                  <xsl:template mode="result-img-src" match="*[@name eq 'other']   ">i_folder</xsl:template>

                  <!-- All icons except the user guide icon are 30 pixels wide -->
                  <xsl:template mode="result-img-width" match="*[@name eq 'guide']">29</xsl:template>
                  <xsl:template mode="result-img-width" match="*"                  >30</xsl:template>

                  <!-- various image heights -->
                  <xsl:template mode="result-img-height" match="*[@name eq 'all']     ">23</xsl:template>
                  <xsl:template mode="result-img-height" match="*[@name eq 'blog']    ">23</xsl:template>
                  <xsl:template mode="result-img-height" match="*[@name eq 'code']    ">24</xsl:template>
                  <xsl:template mode="result-img-height" match="*[@name eq 'event']   ">24</xsl:template>
                  <xsl:template mode="result-img-height" match="*[@name eq 'function']">27</xsl:template>
                  <xsl:template mode="result-img-height" match="*[@name eq 'guide']   ">25</xsl:template>
                  <xsl:template mode="result-img-height" match="*[@name eq 'news']    ">23</xsl:template>
                  <xsl:template mode="result-img-height" match="*[@name eq 'tutorial']">21</xsl:template>
                  <xsl:template mode="result-img-height" match="*[@name eq 'xcc']     "><!--31-->26</xsl:template>
                  <xsl:template mode="result-img-height" match="*[@name eq 'xccn']    ">24</xsl:template>
                  <xsl:template mode="result-img-height" match="*[@name eq 'other']   ">19</xsl:template>

</xsl:stylesheet>
