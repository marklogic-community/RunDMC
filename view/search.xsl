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
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp qp search cts srv api">

  <xsl:template match="search-results">
    <xsl:variable name="results-per-page" select="10"/>
    <xsl:variable name="start" select="ml:start-index($results-per-page)"/>
    <xsl:variable name="options" as="element()">
      <options xmlns="http://marklogic.com/appservices/search">
        <additional-query>
          <!-- TODO: move pubs URIs to config -->
          <xsl:copy-of select="cts:or-query((
                                $ml:live-document-query,
                                cts:directory-query(((:'/pubs/4.2/apidocs/',:)
                                                     '/pubs/4.2/dotnet/',
                                                     '/pubs/4.2/javadoc/',
                                                     '/pubs/code/'
                                                    ),
                                                    'infinity'
                                                   )
                               ))"/>
        </additional-query>
        <constraint name="cat">
          <custom facet="false">
          <!--
          <custom facet="true">
          -->
            <parse        apply="category-parse"        ns="http://marklogic.com/rundmc/facets" at="/model/facets.xqy"/>
            <!--
            <finish-facet apply="category-finish-facet" ns="http://marklogic.com/rundmc/facets" at="/model/facets.xqy"/>
            -->
          </custom>
        </constraint>
      </options>
    </xsl:variable>
    <xsl:variable name="search-results" select="search:search($params[@name eq 'q'],
                                                              $options,
                                                              (:
                                                              search:get-default-options(),
                                                              :)
                                                              $start,
                                                              $results-per-page
                                                             )"/>

    <xsl:if test="$DEBUG">
      <xsl:copy-of select="$search-results"/>
    </xsl:if>
    <!-- Everything below is a workaround for XSLTBUG 13062 -->
    <!--
    <xsl:apply-templates mode="search-results" select="$search-results"/>
    -->
    <xsl:variable name="search-results-doc">
      <xsl:copy-of select="$search-results"/>
    </xsl:variable>
    <xsl:apply-templates mode="search-results" select="$search-results-doc/search:response"/>
    <div style="display:none;" id="search_sidebar">
      <p>Placeholder for facet navigation</p>
    </div>
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
              <xsl:text> for </xsl:text>
              <strong>
                <xsl:value-of select="search:qtext"/>
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
            <xsl:variable name="result-uri" select="if ($is-api-doc) then concat($srv:api-server,  ml:external-uri-api($doc))
                                                                     else concat($srv:main-server, if ($is-flat-file) then @uri else ml:external-uri-main($doc))"/>
            <div class="searchResult">
              <a href="{$result-uri}?hl={encode-for-uri($params[@name eq 'q'])}"> <!-- Send query term -->
                <div class="searchTitle">
                  <xsl:variable name="page-specific-title">
                    <xsl:apply-templates mode="page-specific-title" select="$doc/*"/>
                  </xsl:variable>
                  <xsl:value-of select="if (string($page-specific-title)) then $page-specific-title else @uri"/>
                </div>
                <div class="snippets">
                  <xsl:apply-templates mode="search-snippet" select="search:snippet/search:match"/>
                </div>
              </a>
            </div>
          </xsl:template>

                  <!-- Titles for flat HTML files (API docs usually) -->
                  <xsl:template mode="page-specific-title" match="*:html">
                    <xsl:variable name="common-suffix" select="' - MarkLogic Server Online Documentation'"/>
                    <xsl:variable name="title" select="(//*:title)[1]" as="xs:string"/>
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
                        <a href="{$search-url}?q={encode-for-uri($params[@name eq 'q'])}&amp;p={$page-number + 1}">Next</a>
                      </div>
                    </xsl:if>
                    <xsl:if test="$page-number gt 1">
                      <div class="prevPage">
                        <a href="{$search-url}?q={encode-for-uri($params[@name eq 'q'])}&amp;p={$page-number - 1}">Prev</a>
                      </div>
                    </xsl:if>
                    <p/>
                  </xsl:template>

</xsl:stylesheet>
