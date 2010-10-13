<!-- This stylesheet is concerned with rendering the navigational
     components of the site (menus, breadcrumbs, etc.)
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:u    ="http://marklogic.com/rundmc/util"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp">

  <xsl:include href="pre-process-navigation.xsl"/>

  <xsl:variable name="raw-navigation" select="u:get-doc('/config/navigation.xml')"/>

  <xsl:variable name="navigation">
    <xsl:apply-templates mode="pre-process-navigation" select="$raw-navigation/*"/>
  </xsl:variable>

  <!-- The page occurs in the hierarchy either explicitly or as encompassed by a wildcard.

       If the exact URI is found, then use that;
       otherwise, look to see if the current page falls under a content-type wildcard.

       If the URI is found more than once (as may happen with blog posts), only the first one is chosen.
  -->
  <xsl:variable name="page-in-navigation" select="($navigation//*    [@pref eq '1'][@href eq $external-uri],
                                                   $navigation//*            [@href eq $external-uri],
                                                   $navigation//Article      [$content/Article/@type eq @type],
                                                   $navigation//Announcement [$content/Announcement],
                                                   $navigation//Event        [$content/Event]
                                                  )[1]"/>

  <xsl:template match="top-nav">
    <ul>
      <xsl:apply-templates mode="top-nav" select="$navigation/*/page[not(@hide eq 'yes')]"/>
    </ul>
  </xsl:template>

          <xsl:template mode="top-nav" match="page">
            <li>
              <xsl:apply-templates mode="top-nav-current-att" select="."/>
              <a href="{@href}">
                <xsl:if test="document(concat(@href, '.xml'))//ml:short-description">
                    <xsl:attribute name="class">stip</xsl:attribute>
                    <xsl:attribute name="title">
                        <xsl:value-of select="document(concat(@href, '.xml'))//ml:short-description" />
                    </xsl:attribute>
                </xsl:if>
                <xsl:value-of select="@display"/>
              </a>
            </li>
          </xsl:template>

                  <xsl:template mode="top-nav-current-att" match="page"/>

                  <xsl:template mode="top-nav-current-att" match="page[descendant-or-self::* intersect $page-in-navigation]">
                    <xsl:attribute name="class">current</xsl:attribute>
                  </xsl:template>


  <xsl:template match="doc-breadcrumbs"/>
  <!-- Only display this for Learn docs -->
  <xsl:template match="doc-breadcrumbs[$content/Article]">
    <div id="content_title">
      <xsl:call-template name="breadcrumbs"/>
    </div>
  </xsl:template>

  <!-- For Learn content, breadcrumbs are handled elsewhere -->
  <xsl:template match="breadcrumbs[$content/Article]"/>

  <xsl:template match="breadcrumbs" name="breadcrumbs">
    <xsl:apply-templates mode="breadcrumbs" select="$page-in-navigation[1]"/>
  </xsl:template>

          <!-- No breadcrumbs on home page -->
          <xsl:template mode="breadcrumbs" match="page[@href eq '/']"/>

          <!-- But do display them on every other page -->
          <xsl:template mode="breadcrumbs" match="*" name="breadcrumbs-impl">
            <xsl:param name="site-name" select="'Developer Community'"/>
            <div class="breadcrumb">
              <a href="/">
                <xsl:value-of select="$site-name"/>
              </a>
              <xsl:apply-templates mode="breadcrumb-link" select="ancestor::page"/>
              <xsl:apply-templates mode="breadcrumb-display" select="."/>
            </div>
          </xsl:template>

                  <xsl:template mode="breadcrumb-display" match="page | generic-page">
                    <xsl:text> > </xsl:text>
                    <xsl:value-of select="@display"/>
                  </xsl:template>

                  <xsl:template mode="breadcrumb-display" match="*">
                    <xsl:text> > </xsl:text>
                    <xsl:value-of select="$content/*/title"/>
                  </xsl:template>


                  <xsl:template mode="breadcrumb-link" match="page">
                    <xsl:text> > </xsl:text>
                    <a href="{@href}">
                      <xsl:value-of select="@display"/>
                    </a>
                  </xsl:template>

  <xsl:template match="sub-nav[$content/Article]">
    <xsl:if test="$content/Article//xhtml:h3">
        <h2>Table of Contents</h2>
        <ul>
            <xsl:apply-templates mode="article-toc" select="$content/Article//xhtml:h3"/>
        </ul>
    </xsl:if>
  </xsl:template>

          <xsl:template mode="article-toc" match="xhtml:h3">
            <li>
              <a href="#{generate-id(.)}">
                <xsl:value-of select="."/>
              </a>
            </li>
          </xsl:template>

          <xsl:template match="xhtml:h3">
            <h3>
              <xsl:apply-templates select="@*"/>
              <a name="{generate-id(.)}"/>
              <xsl:apply-templates/>
            </h3>
          </xsl:template>


  <xsl:template match="sub-nav">
    <xsl:variable name="sub-nav-root" select="$page-in-navigation/ancestor-or-self::page[group | page]"/>
    <xsl:variable name="children" select="$sub-nav-root/(group | page)"/>
    <xsl:if test="$children">
      <div class="subnav {if ($sub-nav-root/@closed eq 'yes') then 'closed' else ''}">
        <xsl:choose>
          <xsl:when test="$children/self::group">
            <xsl:apply-templates mode="sub-nav" select="$children"/>
          </xsl:when>
          <!-- Otherwise, they're not grouped; they're just pages in one list -->
          <xsl:otherwise>
            <ul>
              <xsl:apply-templates mode="sub-nav" select="$children"/>
            </ul>
          </xsl:otherwise>
        </xsl:choose>
      </div>
    </xsl:if>
  </xsl:template>

          <xsl:template mode="sub-nav" match="group">
            <h2>
              <xsl:value-of select="@display"/>
            </h2>
            <ul>
              <xsl:apply-templates mode="sub-nav" select="page | group"/>
            </ul>
          </xsl:template>

                  <xsl:template mode="sub-nav" match="group/group">
                    <li>
                      <span>
                        <xsl:value-of select="@display"/>
                      </span>
                      <ul>
                        <xsl:apply-templates mode="sub-nav" select="page | group"/>
                      </ul>
                    </li>
                  </xsl:template>


                  <!-- TODO: Find out whether nested lists should be supported. The JavaScript appears to be broken currently. -->
                  <xsl:template mode="sub-nav" match="page[ not(exists(./@hide)) ] ">
                    <li>
                        <xsl:apply-templates mode="sub-nav-current-att" select="."/>
                            <a href="{@href}">
                                <xsl:if test="document(concat(@href, '.xml'))//ml:short-description">
                                    <xsl:attribute name="class">stip</xsl:attribute>
                                    <xsl:attribute name="title">
                                        <xsl:value-of select="document(concat(@href, '.xml'))//ml:short-description" />
                                    </xsl:attribute>
                                </xsl:if>
                                <xsl:value-of select="@display"/>
                            </a>
                    </li>
                  </xsl:template>

                          <xsl:template mode="sub-nav-current-att" match="page"/>

                          <xsl:template mode="sub-nav-current-att" match="page[. intersect $page-in-navigation/ancestor-or-self::*]">
                            <xsl:attribute name="class">current</xsl:attribute>
                          </xsl:template>

                          <!-- Exception: don't expand when initial expansion is explicitly disabled. This is useful
                               for the "Blog" navigation in particular, where a post may appear in multiple places in the sub-navigation.
                          -->
                          <xsl:template mode="sub-nav-current-att" match="group[@disable-initial-expansion eq 'yes']//page" priority="1"/>


          <xsl:template mode="sub-nav" match="blog-posts-grouped-by-date">
            <xsl:variable name="tree">
            </xsl:variable>
          </xsl:template>


  <!-- The <body> CSS class varies from page to page -->
  <xsl:template match="xhtml:body/@ml:class">
    <xsl:attribute name="class">
      <xsl:apply-templates mode="body-class"        select="$page-in-navigation[1]"/>
      <xsl:apply-templates mode="body-class-extra"  select="$page-in-navigation[1]"/>
    </xsl:attribute>
  </xsl:template>

          <xsl:template mode="body-class" match="navigation/page">main_page</xsl:template>
          <xsl:template mode="body-class" match="generic-page"   >main_page</xsl:template> <!-- was generic, but looked bad -->
          <xsl:template mode="body-class" match="*"              >sub_page</xsl:template>

          <xsl:template mode="body-class-extra" match="*"/>
          <xsl:template mode="body-class-extra" match="page[@href eq '/']                                  "> home</xsl:template>
          <xsl:template mode="body-class-extra" match="Article                                             "> layout2</xsl:template>
          <xsl:template mode="body-class-extra" match="page[ancestor-or-self::page/@narrow-sidebar = 'yes']"> layout3</xsl:template>

          <xsl:template mode="body-class-extra" match="@css-class">
            <xsl:text> </xsl:text>
            <xsl:value-of select="."/>
          </xsl:template>

</xsl:stylesheet>
