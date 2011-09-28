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


  <xsl:variable name="search-options" as="element()">
    <search:options>
      <xsl:copy-of select="$common-search-options"/>
      <search:return-query>true</search:return-query>
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
    <div id="search_sidebar">
      <xsl:value-of select="$_set-cookie"/> <!-- empty sequence; evaluate for side effect only -->
      <xsl:apply-templates mode="version-list" select="."/>
      <xsl:apply-templates mode="facet" select="$facets-response/search:facet"/>
    </div>
  </xsl:template>

          <!-- This is also invoked (and customized) in apidoc/view/page.xsl -->
          <xsl:template mode="version-list" match="*">
            <div id="version_list">
              <span class="version">
                <xsl:text>Server version: </xsl:text>
                <xsl:apply-templates mode="version-list-item" select="$versions"/>
              </span>
            </div>
          </xsl:template>

                  <xsl:template mode="version-list-item" match="*:version">
                    <xsl:variable name="href">
                      <xsl:apply-templates mode="version-list-item-href" select="."/>
                    </xsl:variable>
                    <a href="{$href}">
                      <xsl:apply-templates mode="current-version-selected" select="."/>
                      <xsl:apply-templates mode="version-number-display" select="."/>
                    </a>
                    <xsl:if test="position() ne last()"> | </xsl:if>
                  </xsl:template>

                          <xsl:template mode="version-list-item-href" match="*:version">
                            <xsl:sequence select="concat('/search?q=', $q, '&amp;', $set-version-param-name, '=', @number)"/>
                          </xsl:template>

                          <xsl:template mode="current-version-selected" match="*:version"/>
                          <xsl:template mode="current-version-selected" match="*:version[@number eq $preferred-version]"
                                        name="current-version-class-att">
                            <xsl:attribute name="class" select="'currentVersion'"/>
                          </xsl:template>

                          <!-- Display 5.0 as "MarkLogic 5" -->
                          <xsl:template mode="version-number-display" match="*:version[@number eq '5.0']">MarkLogic 5</xsl:template>
                          <xsl:template mode="version-number-display" match="*:version">
                            <xsl:value-of select="@number"/>
                          </xsl:template>


  <xsl:template match="search-results">
    <xsl:if test="$DEBUG">
      <xsl:copy-of select="$search-response"/>
      <xsl:copy-of select="$facets-response"/>
    </xsl:if>
    <xsl:apply-templates mode="search-results" select="$search-response"/>
  </xsl:template>

          <xsl:template mode="search-results" match="search:response[@total eq 0]">
            <div class="searchSummary">
              <xsl:text>Your search - </xsl:text>
              <strong>
                <xsl:value-of select="search:qtext"/>
              </strong>
              <xsl:text> - did not match any documents.</xsl:text>
            </div>
          </xsl:template>

          <xsl:template mode="search-results" match="search:response">
            <xsl:variable name="last-in-full-page" select="@start + @page-length - 1"/>
            <xsl:variable name="end-result-index"  select="if (@total lt @page-length or $last-in-full-page gt @total) then @total
                                                      else $last-in-full-page"/>
            <div class="searchSummary">
              <xsl:text>Results </xsl:text>
              <strong>
                <xsl:value-of select="@start"/>&#8211;<xsl:value-of select="$end-result-index"/>
              </strong>
              <xsl:text> of </xsl:text>
              <strong>
                <xsl:value-of select="@total"/>
              </strong>
              <xsl:text>.</xsl:text>
            </div>
            <xsl:apply-templates mode="#current" select="search:result"/>
            <xsl:apply-templates mode="prev-and-next" select="."/>
          </xsl:template>

          <xsl:template mode="search-results" match="search:result">
            <xsl:variable name="is-flat-file" select="starts-with(@uri, '/pubs/')"/>
            <xsl:variable name="doc" select="doc(@uri)"/>
            <xsl:variable name="is-api-doc" select="starts-with(@uri,'/apidoc/')"/>
            <xsl:variable name="api-version" select="substring-before(substring-after(@uri,'/apidoc/'),'/')"/>
            <xsl:variable name="version-prefix" select="if ($api-version eq $ml:default-version) then '' else concat('/',$api-version)"/>
            <xsl:variable name="result-uri" select="if ($is-api-doc) then concat($srv:api-server,  $version-prefix, ml:external-uri-api($doc))
                                                                     else concat($srv:main-server, if ($is-flat-file)
                                                                                                   then @uri
                                                                                                   else ml:external-uri-main($doc))"/>
            <div class="searchResult category_{ml:category-for-doc(@uri)}">
              <a href="{$result-uri}"><!--?hl={encode-for-uri($q)}">--> <!-- Highlighting disabled until we find a better way (fully featured, not in URL) -->
                <div class="searchTitle">
                  <xsl:variable name="page-specific-title">
                    <xsl:apply-templates mode="page-specific-title" select="$doc/*"/>
                  </xsl:variable>
                  <xsl:value-of select="if (string($page-specific-title)) then $page-specific-title else @uri"/>
                </div>
              </a>
              <div class="snippets">
                <xsl:apply-templates mode="search-snippet" select="search:snippet/search:match"/>
              </div>
            </div>
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
                    <span class="snippet">
                      <xsl:apply-templates mode="#current"/>
                    </span>
                    <xsl:if test="position() ne last()">...</xsl:if>
                  </xsl:template>

                  <xsl:template mode="search-snippet" match="search:highlight">
                    <span class="highlight">
                      <xsl:apply-templates mode="#current"/>
                    </span>
                  </xsl:template>


                  <xsl:template mode="prev-and-next" match="search:response">
                    <xsl:variable name="search-url" select="ml:external-uri(.)"/>
                    <xsl:if test="@total gt (@start + @page-length - 1)">
                      <div class="nextPage">
                        <a href="{$search-url}?q={encode-for-uri($q)}&amp;p={$page-number + 1}">Next</a>
                      </div>
                    </xsl:if>
                    <xsl:if test="$page-number gt 1">
                      <div class="prevPage">
                        <a href="{$search-url}?q={encode-for-uri($q)}&amp;p={$page-number - 1}">Prev</a>
                      </div>
                    </xsl:if>
                    <p/>
                  </xsl:template>

  <xsl:template mode="facet" match="search:facet">
    <div class="facet">
      <div class="facet_name">
        <xsl:apply-templates mode="facet-name" select="@name"/>
      </div>
      <ul>
        <xsl:apply-templates mode="facet-value" select="search:facet-value">
          <xsl:sort select="@count" order="descending" data-type="number"/>
        </xsl:apply-templates>
      </ul>
    </div>
  </xsl:template>

          <xsl:template mode="facet-name" match="@name[. eq 'cat']">Narrow by Category:</xsl:template>


          <xsl:template mode="facet-value" match="search:facet-value">
            <xsl:variable name="this" select="concat(../@name,':',@name)"/>
            <xsl:variable name="selected" select="$search-response/search:query//@qtextconst[. eq $this]"/>
            <xsl:variable name="img-file" select="if ($selected) then 'checkmark.gif'
                                                                 else 'checkblank.gif'"/>

            <xsl:variable name="clean-q" select="ml:qtext-with-no-constraints($search-response, $search-options)"/>
            <xsl:variable name="new-q" select="if (string($clean-q)) then concat('(', $clean-q, ')', ' AND ', $this)
                                                                     else $this"/>
            <li class="facet_value">
              <img src="/images/{$img-file}"/>
              <a href="?q={encode-for-uri($new-q)}">
                <!-- this looks like an XSLT BUG, since I had to add string() to get any output
                <xsl:value-of select="."/>
                -->
                <!--
                <xsl:value-of select="string(.)"/>
                -->
                <xsl:value-of select="@count"/>
                <xsl:text> </xsl:text>
                <xsl:apply-templates mode="facet-value-display" select="."/>
              </a>
            </li>
          </xsl:template>

                  <xsl:template mode="facet-value-display" match="*[@name eq 'blog']    ">Blog posts</xsl:template>
                  <xsl:template mode="facet-value-display" match="*[@name eq 'code']    ">Open-source projects</xsl:template>
                  <xsl:template mode="facet-value-display" match="*[@name eq 'event']   ">Events</xsl:template>
                  <xsl:template mode="facet-value-display" match="*[@name eq 'function']">Function docs</xsl:template>
                  <xsl:template mode="facet-value-display" match="*[@name eq 'guide']   ">User guides</xsl:template>
                  <xsl:template mode="facet-value-display" match="*[@name eq 'news']    ">News items</xsl:template>
                  <xsl:template mode="facet-value-display" match="*[@name eq 'tutorial']">Tutorials</xsl:template>
                  <xsl:template mode="facet-value-display" match="*[@name eq 'xcc']     ">XCC Connector Javadocs</xsl:template>
                  <xsl:template mode="facet-value-display" match="*[@name eq 'xccn']    ">XCC Connector .Net docs</xsl:template>

</xsl:stylesheet>
