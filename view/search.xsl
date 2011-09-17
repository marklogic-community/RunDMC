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

  <xsl:variable name="search-options" as="element()">
    <options xmlns="http://marklogic.com/appservices/search">
      <additional-query>
        <xsl:copy-of select="$ml:search-corpus-query"/>
      </additional-query>
      <constraint name="cat">
        <collection prefix="category/"/>
      </constraint>
    </options>
  </xsl:variable>

  <xsl:variable name="search-response" as="element(search:response)">
    <xsl:variable name="results-per-page" select="10"/>
    <xsl:variable name="start" select="ml:start-index($results-per-page)"/>
    <!-- Adding the document wrapper is a workaround for XSLTBUG 13062 -->
    <xsl:variable name="search-response-doc">
      <xsl:copy-of select="search:search($params[@name eq 'q'],
                                          $search-options,
                                          $start,
                                          $results-per-page
                                         )"/>
    </xsl:variable>
    <xsl:sequence select="$search-response-doc/search:response"/>
  </xsl:variable>

  <xsl:template match="sub-nav[$external-uri eq '/search']">
    <div id="search_sidebar">
      <xsl:apply-templates mode="facet" select="$search-response/search:facet"/>
    </div>
  </xsl:template>

  <xsl:template match="search-results">
    <xsl:if test="$DEBUG">
      <xsl:copy-of select="$search-response"/>
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
              <a href="{$result-uri}"><!--?hl={encode-for-uri($params[@name eq 'q'])}">--> <!-- Highlighting disabled until we find a better way (fully featured, not in URL) -->
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

  <xsl:template mode="facet" match="search:facet">
    <div class="facet">
      <div class="facet_name">
        <xsl:apply-templates mode="facet-name" select="@name"/>
      </div>
      <ul>
        <xsl:apply-templates mode="facet-value" select="search:facet-value"/>
      </ul>
    </div>
  </xsl:template>

          <xsl:template mode="facet-name" match="@name[. eq 'cat']">Category</xsl:template>


          <xsl:template mode="facet-value" match="search:facet-value">
            <xsl:variable name="q" select="string(../../search:qtext)"/>
            <xsl:variable name="this" select="concat(../@name,':',@name)"/>
            <xsl:variable name="selected" select="contains($q,$this)"/>
            <xsl:variable name="img-file" select="if ($selected) then 'checkmark.gif'
                                                                 else 'checkblank.gif'"/>

            <xsl:variable name="new-q" select="if ($selected)  then search:remove-constraint($q,$this,$search-options)
                                          else if (string($q)) then concat('(', $q, ')', ' AND ', $this)
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
                <xsl:apply-templates mode="facet-value-display" select="."/>
                <xsl:text> [</xsl:text>
                <xsl:value-of select="@count"/>
                <xsl:text>]</xsl:text>
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
