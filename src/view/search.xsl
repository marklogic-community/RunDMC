
<xsl:stylesheet version="2.0"
  xmlns:api="http://marklogic.com/rundmc/api"
  xmlns:ck="http://parthcomp.com/cookies"
  xmlns:cts="http://marklogic.com/cts"
  xmlns:ml="http://developer.marklogic.com/site/internal"
  xmlns:qp="http://www.marklogic.com/ps/lib/queryparams"
  xmlns:search="http://marklogic.com/appservices/search"
  xmlns:srv="http://marklogic.com/rundmc/server-urls"
  xmlns:ss="http://developer.marklogic.com/site/search"
  xmlns:u="http://marklogic.com/rundmc/util"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns="http://www.w3.org/1999/xhtml"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  extension-element-prefixes="xdmp"
  exclude-result-prefixes="api ck cts ml qp search srv ss u xs xdmp">

  <xdmp:import-module
      namespace="http://developer.marklogic.com/site/search"
      href="/controller/search.xqm"/>

  <!-- TODO Creates dependency on apidoc code. -->
  <xdmp:import-module
      namespace="http://marklogic.com/rundmc/api"
      href="/apidoc/model/data-access.xqy"/>

  <!-- There may be a bug somewhere that adds multiple version params. -->
  <xsl:variable name="set-version"
                select="ml:version-select(
                        $params[@name eq $ss:INPUT-NAME-API-VERSION])"/>

  <xsl:variable name="IS-API-SEARCH" as="xs:boolean"
                select="xs:boolean(
                        ($params[@name eq $ss:INPUT-NAME-API][
                        . castable as xs:boolean],
                        0)[1])"/>

  <xsl:variable name="API-VERSION-PREFIX"
                select="if ($PREFERRED-VERSION eq $ml:default-version) then ''
                        else concat('/',$PREFERRED-VERSION)"/>

  <xsl:variable name="QUERY" as="xs:string"
                select="string-join($params[@name eq 'q'], ' ')"/>

  <xsl:variable name="SEARCH-RESPONSE" as="element(search:response)">
    <xsl:variable name="results-per-page" select="10"/>
    <xsl:sequence
        select="ss:search(
                $PREFERRED-VERSION, $IS-API-SEARCH, $QUERY,
                ml:start-index($results-per-page), $results-per-page)"/>
  </xsl:variable>

  <!-- qtext without constraints -->
  <xsl:variable name="QUERY-UNCONSTRAINED" as="xs:string"
                select="($SEARCH-RESPONSE/@query-unconstrained, $QUERY)[1]"/>

  <xsl:variable name="preferred-version-cookie-name"
                select="if ($srv:cookie-domain ne 'marklogic.com')
                        then 'preferred-server-version-not-on-live-site'
                        else if ($srv:host-type eq 'staging')
                        then 'preferred-server-version-staging'
                        else 'preferred-server-version'"/>

  <xsl:variable name="preferred-version-cookie"
                select="ck:get-cookie($preferred-version-cookie-name)[1]"/>

  <!-- #198 The version cookie is set, but never honored. -->
  <xsl:variable name="PREFERRED-VERSION"
                select="if ($set-version) then $set-version
                        else if (0 and $preferred-version-cookie)
                        then $preferred-version-cookie
                        else $ml:default-version"/>

  <xsl:variable name="_set-cookie"
                select="if (not($set-version)) then ()
                        else ck:add-cookie(
                        $preferred-version-cookie-name,
                        $set-version,
                        xs:dateTime('2100-01-01T12:00:00'), (: expires :)
                        $srv:cookie-domain,
                        '/',
                        false())"/>

  <!-- Overriden by apidoc/view/page.xsl so this has to use XSL. -->
  <xsl:function name="ml:version-is-selected" as="xs:boolean">
    <xsl:param name="_version" as="xs:string"/>
    <xsl:copy-of select="$_version eq $PREFERRED-VERSION"/>
  </xsl:function>

  <!--
      The "Version" switcher code.
      This is also customized in apidoc/view/page.xsl
  -->
  <xsl:template mode="version-list" match="*">
    <div class="version">
      <span>Version:</span>
      <xsl:text> </xsl:text>
      <select id="version_list" data-default="{$ml:default-version}">
        <xsl:apply-templates mode="version-list-item"
                             select="$ml:server-version-nodes-available"/>
      </select>
    </div>
  </xsl:template>

  <!--
      All this uses *:version because server-versions.xml is in empty namespace,
      and xpath-default-namespace has been set.
  -->

  <!-- separator between each version -->
  <xsl:template mode="version-list-item" match="*:version">
    <option value="{@number}">
      <xsl:if test="ml:version-is-selected(@number)">
        <xsl:attribute name="selected">
          <xsl:value-of select="true()"/>
        </xsl:attribute>
      </xsl:if>
      <!-- Display label. -->
      <xsl:value-of select="(@display, @number)[1]"/>
    </option>
  </xsl:template>

  <!-- TODO version-specific results URL - dead code? -->
  <xsl:template mode="version-list-item-href" match="*:version">
    <xsl:value-of select="ss:href(@number, $QUERY, $IS-API-SEARCH)"/>
  </xsl:template>

  <xsl:template match="sub-nav[$external-uri = ('/search','/apidoc/do-search')]">
    <section>
      <xsl:value-of select="$_set-cookie"/> <!-- empty sequence; evaluate for side effect only -->
      <xsl:apply-templates mode="facet" select="$SEARCH-RESPONSE/search:facet"/>
    </section>
  </xsl:template>


  <!-- Prepend the appropriate server name to the search form target -->
  <xsl:template match="@ml:action">
    <xsl:attribute name="action" select="$srv:search-page-url"/>
  </xsl:template>


  <!--
      Prefer exact function matches over search results.
      Prefer exact error message matches over search results.
  -->
  <xsl:template match="search-results">
    <xsl:if test="$DEBUG">
      <xsl:copy-of select="$SEARCH-RESPONSE"/>
    </xsl:if>
    <!-- Skip any shortcuts if there is a category constraint or page number. -->
    <xsl:variable name="skip-exact-matches"
                  select="$page-number-supplied or contains($QUERY,'cat:')"/>
    <xsl:variable name="matching-functions"
                  select="if ($skip-exact-matches) then ()
                          else ml:get-matching-functions($QUERY,$PREFERRED-VERSION)"/>
    <xsl:variable name="matching-message-id" as="xs:string?"
                  select="if ($skip-exact-matches or $matching-functions) then ()
                          else ml:get-matching-messages(
                          $QUERY, $PREFERRED-VERSION)[1]/*/@id"/>
    <xsl:variable name="redirect"
                  select="if (not($matching-functions or $matching-message-id))
                          then ()
                          else concat(
                          $srv:effective-api-server,
                          $API-VERSION-PREFIX,
                          '/',
                          if ($matching-functions)
                          then $matching-functions[1]/*/api:function[1]/@fullname
                          else concat(
                          'messages/',
                          replace($matching-message-id, '^(\w+)-(\w+)', '$1'),
                          '-en/',
                          $matching-message-id))"/>
    <xsl:choose>
      <xsl:when test="$redirect">
        <!-- Keep the query intact for an undo link. -->
        <xsl:value-of
            select="xdmp:redirect-response(concat($redirect, '?q=', $QUERY))"/>
      </xsl:when>
      <xsl:otherwise>
        <!-- Pass the unconstrained query for the facet UI. -->
        <div class="hidden" id="queryUnconstrained">
          <xsl:value-of select="$QUERY-UNCONSTRAINED"/>
        </div>
        <!-- Render search results. -->
        <xsl:apply-templates mode="search-results" select="$SEARCH-RESPONSE"/>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="did-you-mean">
    <xsl:param name="q"/>
    <!--
        Did the query start with something like a version number?
        ASSUMPTION: future versions will match regex '\d+.0'.
        Is the requested version supposed to be available?
    -->
    <xsl:variable name="pat" select="'^(\d+\.?0?)\s+(.+)$'"/>
    <xsl:if test="matches($q, $pat)">
      <xsl:variable name="q-version-raw"
                    select="replace($q, $pat, '$1')"/>
      <xsl:variable name="q-version"
                    select="if (ends-with($q-version-raw, '.0'))
                            then $q-version-raw
                            else concat($q-version-raw, '.0')"/>
      <xsl:if test="$q-version = $ml:server-versions-available
                    and not(
                      $q-version eq $set-version
                      or (not($set-version)
                        and $q-version eq $ml:default-version))">
        <xsl:variable name="q-clean" select="replace($q, $pat, '$2')"/>
        <p class="didYouMean">
          <xsl:text>Did you mean to search for </xsl:text>
          <a href="{ ss:href($q-version, $q-clean, $IS-API-SEARCH) }">
            <xsl:value-of select="$q-clean"/>
            <xsl:text> in version </xsl:text>
            <xsl:value-of select="$q-version"/>
          </a>
          <xsl:text>?</xsl:text>
        </p>
      </xsl:if>
    </xsl:if>
  </xsl:template>

  <xsl:template mode="search-results" match="search:response[@total eq 0]">
    <xsl:call-template name="did-you-mean">
      <xsl:with-param name="q" select="$QUERY"/>
    </xsl:call-template>
    <h3>
      <xsl:text>Your search – </xsl:text>
      <em>
        <xsl:value-of select="search:qtext"/>
      </em>
      <xsl:text> – did not match any documents.</xsl:text>
    </h3>
  </xsl:template>

  <xsl:template mode="search-results" match="search:response">
    <xsl:call-template name="did-you-mean">
      <xsl:with-param name="q" select="$QUERY"/>
    </xsl:call-template>
    <xsl:variable name="total" as="xs:int"
                  select="(@facet-total, @total)[1]"/>
    <xsl:variable name="last-in-full-page" select="@start + @page-length - 1"/>
    <xsl:variable name="end-result-index"
                  select="if ($total lt @page-length
                          or $last-in-full-page gt $total) then $total
                          else $last-in-full-page"/>
    <h3>
      <xsl:text>Results </xsl:text>
      <em>
        <xsl:value-of select="@start"/>–<xsl:value-of select="$end-result-index"/>
      </em>
      <xsl:text> of </xsl:text>
      <xsl:value-of select="$total"/>
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

  <!-- Render one result from a search:response. -->
  <xsl:template mode="search-results" match="search:result">
    <xsl:variable name="doc" select="doc(@uri)"/>
    <xsl:variable name="result-uri"
                  select="ss:result-uri(
                          @uri,
                          $QUERY-UNCONSTRAINED,
                          starts-with(@uri, '/apidoc/'),
                          $API-VERSION-PREFIX)"/>
    <tr>
      <th>
        <xsl:variable name="category">
          <ml:category name="{ ml:category-for-doc(@uri)[1] }"/>
        </xsl:variable>
        <xsl:apply-templates mode="category-image" select="$category/*"/>
      </th>
      <td>
        <h4>
          <a href="{ $result-uri }" class="search_result">
            <xsl:variable name="page-specific-title">
              <xsl:apply-templates mode="page-specific-title"
                                   select="$doc/*"/>
            </xsl:variable>
            <xsl:value-of
                select="if (string($page-specific-title)) then $page-specific-title
                        else @uri"/>
          </a>
        </h4>
        <div class="text">
          <xsl:apply-templates mode="search-snippet"
                               select="search:snippet/search:match"/>
        </div>
      </td>
    </tr>
  </xsl:template>

  <xsl:template mode="category-image" match="*">
    <xsl:variable name="img-src">
      <xsl:text>/images/</xsl:text>
      <xsl:value-of select="ss:result-img-src(@name)"/>
      <xsl:text>.png</xsl:text>
    </xsl:variable>
    <xsl:variable name="img-alt">
      <xsl:value-of select="ss:facet-value-display(.)"/>
    </xsl:variable>
    <xsl:variable name="img-width">
      <xsl:value-of select="ss:result-img-width(@name)"/>
    </xsl:variable>
    <xsl:variable name="img-height">
      <xsl:value-of select="ss:result-img-height(@name)"/>
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

  <xsl:template mode="page-specific-title" match="/chapter" xpath-default-namespace="">
    <xsl:value-of select="title"/> (<xsl:value-of select="guide-title"/>)
  </xsl:template>

  <xsl:template mode="page-specific-title" match="api:help-page">
    <xsl:value-of select="api:title"/>
  </xsl:template>

  <xsl:template mode="page-specific-title" match="api:function-page">
    <xsl:value-of select="api:function[1]/@fullname"/>
  </xsl:template>

  <!-- TODO should not refer directly to the apidoc code. -->
  <xsl:template mode="page-specific-title" match="api:function-page[api:function[1]/@lib eq $api:MODE-REST]">
    <xsl:value-of select="api:REST-resource-heading(api:function[1]/@fullname)"/>
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
    <xsl:variable name="total" as="xs:int"
                  select="(@facet-total, @total)[1]"/>
    <xsl:variable name="search-url" select="ml:external-uri(.)"/>
    <form class="pagination" action="/search" method="get">
      <div>
        <xsl:if test="$page-number gt 1">
          <a class="prev" rel="prev"
             href="{
                   ss:href(
                   $PREFERRED-VERSION, $QUERY, $IS-API-SEARCH,
                   $page-number - 1) }">«</a>
          <xsl:text> </xsl:text>
        </xsl:if>
        <label>
          <xsl:text>Page </xsl:text>
          <input name="p" type="text" value="{$page-number}" size="4"/>
          <input name="q" type="hidden" value="{$QUERY}"/>
          <xsl:text> of </xsl:text>
          <xsl:value-of select="ceiling($total div @page-length)"/>
        </label>
        <xsl:if test="$total gt (@start + @page-length - 1)">
          <xsl:text> </xsl:text>
          <a class="next" rel="next"
             href="{
                   ss:href(
                   $PREFERRED-VERSION, $QUERY, $IS-API-SEARCH,
                   1 + $page-number) }">»</a>
        </xsl:if>
      </div>
    </form>
  </xsl:template>

  <xsl:template mode="facet" match="search:facet">
    <h2>
      <xsl:apply-templates mode="facet-name" select="@name"/>
      <span id="facetSelectionWidget"/>
    </h2>
    <ul class="categories">
      <xsl:apply-templates mode="facet-value"
                           select="parent::search:response"/>
      <xsl:apply-templates mode="facet-value"
                           select="search:facet-value[
                                   not(contains(@name, '/'))]">
        <xsl:sort
            select="@count | @total" order="descending" data-type="number"/>
      </xsl:apply-templates>
    </ul>
  </xsl:template>

  <xsl:template mode="facet-name"
                match="@name[. eq 'cat']">Categories</xsl:template>

  <xsl:template name="facet-value-anchor">
    <xsl:param name="is-api-search" as="xs:boolean"/>
    <xsl:param name="preferred-version" as="xs:string"/>
    <xsl:param name="query-unconstrained" as="xs:string"/>
    <xsl:variable name="category">
      <ml:category name="{
                         if (empty(@name)) then 'all'
                         else if (not(contains(@name, '/'))) then @name
                         else substring-after(@name, '/') }"/>
    </xsl:variable>
    <xsl:variable name="this-constraint" as="xs:string?"
                  select="self::search:facet-value/concat(../@name,':',@name)"/>
    <xsl:variable name="current-constraints" as="xs:string*"
                  select="$SEARCH-RESPONSE/search:query//@qtextconst[
                          starts-with(., 'cat:')]"/>
    <xsl:variable name="selected"
                  select="$this-constraint = $current-constraints
                          or not($this-constraint or $current-constraints)"/>
    <xsl:variable name="new-q"
                  select="if (not($this-constraint)) then $query-unconstrained
                          else if (not($query-unconstrained)) then $this-constraint
                          else concat(
                          $this-constraint, ' (', $query-unconstrained, ')')"/>
    <xsl:if test="$selected">
      <xsl:attribute name="class" select="'current'"/>
    </xsl:if>
    <!--
        "All categories" link forces the search by including p=1
        (preventing function page redirects).
        This also resets to page 1.
    -->
    <a data-constraint="{ $this-constraint }"
       href="{
             ss:href(
             $preferred-version, $new-q, $is-api-search,
             if ($this-constraint) then () else 1) }">
      <xsl:if test="not(contains(@name, '/'))">
        <xsl:apply-templates mode="category-image" select="$category/*"/>
        <xsl:text> </xsl:text>
      </xsl:if>
      <xsl:value-of select="ss:facet-value-display(.)"/>
      <xsl:text> [</xsl:text>
      <xsl:value-of select="@count|@total"/>
      <xsl:text>]</xsl:text>
    </a>
  </xsl:template>

  <!-- Using <search:response> to represent "all categories" -->
  <xsl:template mode="facet-value"
                match="search:facet-value|search:response">
    <xsl:variable name="this-prefix" as="xs:string?"
                  select="self::search:facet-value/concat(@name, '/')"/>
    <li>
      <xsl:call-template name="facet-value-anchor">
        <xsl:with-param name="is-api-search"
                        select="$IS-API-SEARCH"/>
        <xsl:with-param name="preferred-version"
                        select="$PREFERRED-VERSION"/>
        <xsl:with-param name="query-unconstrained"
                        select="$QUERY-UNCONSTRAINED"/>
      </xsl:call-template>
      <xsl:if
          test="$this-prefix
                and self::search:facet-value/../search:facet-value[
                starts-with(@name, $this-prefix)]">
        <ul class="subcategories">
          <xsl:for-each
              select="self::search:facet-value/../search:facet-value[
                      starts-with(@name, $this-prefix)]">
            <xsl:sort
                select="@count" order="descending" data-type="number"/>
            <li>
              <xsl:call-template name="facet-value-anchor">
                <xsl:with-param name="is-api-search"
                                select="$IS-API-SEARCH"/>
                <xsl:with-param name="preferred-version"
                                select="$PREFERRED-VERSION"/>
                <xsl:with-param name="query-unconstrained"
                                select="$QUERY-UNCONSTRAINED"/>
              </xsl:call-template>
            </li>
          </xsl:for-each>
        </ul>
      </xsl:if>
    </li>
  </xsl:template>


  <xsl:template match="ml:breadcrumbs[ $IS-API-SEARCH ]">
    <xsl:apply-templates mode="breadcrumbs"
                         select=".">
      <xsl:with-param name="site-name" select="'Docs'"/>
      <xsl:with-param name="version" select="$PREFERRED-VERSION"/>
    </xsl:apply-templates>
    <xsl:apply-templates mode="version-list" select="."/>
  </xsl:template>

</xsl:stylesheet>
