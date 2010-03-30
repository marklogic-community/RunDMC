<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp">

  <xsl:output doctype-public="-//W3C//DTD XHTML 1.0 Strict//EN"
              doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd"
              omit-xml-declaration="yes"/>

  <xsl:param name="message"/>

  <xsl:variable name="content"    select="/"/>
  <xsl:variable name="base-uri"   select="base-uri($content)"/>

  <xsl:variable name="template"       select="document('/private/config/template.xhtml')"/>
  <xsl:variable name="raw-navigation" select="document('/private/config/navigation.xml')"/>
  <xsl:variable name="widget-config"  select="document('/private/config/widgets.xml')"/>

  <xsl:variable name="collection" select="collection()"/>
  <!--
  <xsl:variable name="collection" select="collection('http://developer.marklogic.com/content-collection')"/>
  -->

  <xsl:variable name="all-blog-posts" select="$collection/Post"/>

  <xsl:variable name="navigation">
    <xsl:apply-templates mode="pre-process-navigation" select="$raw-navigation/*"/>
  </xsl:variable>

          <xsl:template mode="pre-process-navigation" match="@* | node()">
            <xsl:copy>
              <xsl:apply-templates mode="#current" select="@* | node()"/>
            </xsl:copy>
          </xsl:template>

          <!-- These three rules smell. Consider refactoring -->
          <xsl:template mode="pre-process-navigation" match="blog-posts-grouped-by-date">
            <xsl:variable name="unique-years" select="distinct-values($all-blog-posts/date/year-from-date(.))"/>
            <xsl:for-each select="$unique-years">
              <xsl:sort select="." order="descending"/>
              <xsl:variable name="posts-this-year" select="$all-blog-posts[year-from-date(date) eq current()]"/>
              <ml:group display="{.}">
                <xsl:variable name="unique-months" select="distinct-values($posts-this-year/date/month-from-date(.))"/>
                <xsl:for-each select="$unique-months">
                  <xsl:sort select="." order="descending"/>
                  <xsl:variable name="posts-this-month" select="$posts-this-year[month-from-date(date) eq current()]"/>
                  <ml:group display="{ml:month-name(.)} ({count($posts-this-month)})">
                    <xsl:for-each select="$posts-this-month">
                      <xsl:sort select="date" order="descending"/>
                      <ml:page display="{title}" href="{ml:external-uri(.)}"/>
                    </xsl:for-each>
                  </ml:group>
                </xsl:for-each>
              </ml:group>
            </xsl:for-each>
          </xsl:template>

          <xsl:template mode="pre-process-navigation" match="blog-posts-grouped-by-author">
            <xsl:variable name="unique-authors" select="distinct-values($all-blog-posts/author)"/>
            <xsl:for-each select="$unique-authors">
              <ml:group display="{.}">
                <xsl:variable name="posts-by-author" select="$all-blog-posts[author eq current()]"/>
                <xsl:for-each select="$posts-by-author">
                  <xsl:sort select="date" order="descending"/>
                  <ml:page display="{title}" href="{ml:external-uri(.)}"/>
                </xsl:for-each>
              </ml:group>
            </xsl:for-each>
          </xsl:template>

          <xsl:template mode="pre-process-navigation" match="blog-posts-grouped-by-category">
            <xsl:variable name="unique-tags" select="distinct-values($all-blog-posts/tags/tag)"/>
            <xsl:for-each select="$unique-tags">
              <ml:group display="{.}">
                <xsl:variable name="posts-with-tag" select="$all-blog-posts[tags/tag = current()]"/>
                <xsl:for-each select="$posts-with-tag">
                  <xsl:sort select="date" order="descending"/>
                  <ml:page display="{title}" href="{ml:external-uri(.)}"/>
                </xsl:for-each>
              </ml:group>
            </xsl:for-each>
          </xsl:template>



  <xsl:variable name="external-uri" select="ml:external-uri(/)"/>

  <!-- The page occurs in the hierarchy either explicitly or as encompassed by a wildcard.

       If the exact URI is found, then use that;
       otherwise, look to see if the current page falls under a content-type wildcard.

       If the URI is found more than once (as may happen with blog posts), only the first one is chosen.
  -->
  <xsl:variable name="page-in-navigation" select="($navigation//*            [@href eq $external-uri],
                                                   $navigation//Article      [$content/Article/@type eq @type],
                                                   $navigation//Announcement [$content/Announcement],
                                                   $navigation//Event        [$content/Event]
                                                  )"/>

  <!-- Start by processing the template page -->
  <xsl:template match="/">
    <!-- XSLT BUG WORKAROUND (outputs nothing); works because it apparently forces evaluation earlier -->
    <xsl:value-of select="$content/.."/> <!-- empty sequence -->
    <xsl:value-of select="substring-after($external-uri,$external-uri)"/> <!-- empty string -->

    <xsl:apply-templates select="$template/*"/>
  </xsl:template>

          <!-- By default, copy everything unchanged -->
          <xsl:template match="@* | comment() | text() | processing-instruction()">
            <xsl:copy/>
          </xsl:template>

          <!-- Strip out inline custom tags (such as <ml:teaser>) -->
          <xsl:template match="ml:*">
            <xsl:apply-templates/>
          </xsl:template>

          <!-- For elements, "replicate" rather than copy, to prevent unwanted namespace nodes in output -->
          <xsl:template match="*">
            <xsl:element name="{name()}" namespace="{namespace-uri()}">
              <xsl:apply-templates select="@* | node()"/>
            </xsl:element>
          </xsl:template>


  <!-- Process page content when we hit the <ml:page-content> element -->
  <xsl:template match="page-content">
    <xsl:if test="string($message)">
      <div class="alert">
        <xsl:value-of select="$message"/>
      </div>
    </xsl:if>
    <xsl:apply-templates mode="page-content" select="$content/*"/>
  </xsl:template>

          <xsl:template mode="page-content" match="page">
            <xsl:apply-templates/>
          </xsl:template>


          <xsl:template mode="page-content" match="Post">
            <h1>Blog</h1>
            <xsl:apply-templates mode="post-with-comments" select="."/>
          </xsl:template>

                  <xsl:template mode="post-with-comments" match="Post">
                    <xsl:apply-templates mode="blog-post" select="."/>
                    <xsl:if test="ml:comments-for-post(.)">
                      <h3 id="comments">Comments</h3>
                      <ol class="commentlist">
                        <xsl:apply-templates mode="blog-comment" select="ml:comments-for-post(.)">
                          <xsl:sort select="date"/>
                        </xsl:apply-templates>
                      </ol>
                    </xsl:if>
                    <form id="post_comment" action="/post-comment.xqy" method="post">
                      <input type="hidden" name="about" value="{ml:external-uri(.)}"/>
                      <fieldset>
                        <legend>Post a Comment</legend>
                        <div>
                          <label for="pc_name">Name</label>
                          <xsl:text> </xsl:text>
                          <input id="pc_name" type="text" name="author"/>
                        </div>
                        <div>
                          <label for="pc_url">URL</label>
                          <xsl:text> </xsl:text>
                          <input id="pc_url" type="text" name="url"/>
                        </div>
                        <div>
                          <label for="pc_comment">Comment</label>
                          <textarea cols="30" rows="5" id="pc_comment" name="body"/>
                        </div>
                      </fieldset>
                      <div class="submit">
                        <input type="image" src="/images/b_send.png" value="Send"/>
                      </div>
                    </form>
                  </xsl:template>

                          <xsl:template mode="blog-post" match="Post">
                            <div class="post">
                              <h2>
                                <xsl:apply-templates select="title/node()"/>
                              </h2>
                              <span class="date">
                                <xsl:value-of select="date"/>
                              </span>
                              <span class="author">
                                <xsl:text>by </xsl:text>
                                <xsl:value-of select="author"/>
                              </span>
                              <xsl:apply-templates select="body/node()"/>
                              <div class="action">
                                <ul>
                                  <li>
                                    <a href="{ml:external-uri(.)}#comments">Comments (<xsl:value-of select="count(ml:comments-for-post(.))"/>)</a>
                                  </li>
                                  <li>
                                    <a href="{ml:external-uri(.)}#post_comment">Post a comment</a>
                                  </li>
                                </ul>
                              </div>
                            </div>
                          </xsl:template>

                                  <xsl:function name="ml:comments-for-post" as="element()*">
                                    <xsl:param name="post" as="element()"/>
                                    <xsl:sequence select="$collection/Comment[@about eq ml:external-uri($post)]
                                                                             [@status eq 'Approved']"/>
                                  </xsl:function>


                          <xsl:template mode="blog-comment" match="Comment">
                            <li>
                              <xsl:apply-templates select="body/node()"/>
                              <div class="comment_info">
                                <span class="user">
                                  <a class="tag-" href="{url}">
                                    <xsl:value-of select="author"/>
                                  </a>,
                                </span>
                                <span class="time">
                                  <xsl:value-of select="ml:display-time(date)"/>,
                                </span>
                                <span class="date">
                                  <xsl:value-of select="ml:display-date(date)"/>
                                </span>
                              </div>
                            </li>
                          </xsl:template>


          <xsl:template mode="page-content" match="Event">
            <h1>Events</h1>
            <h2>
              <xsl:apply-templates select="title/node()"/>
            </h2>
            <dl>
              <xsl:apply-templates mode="event-details" select="details/*"/>
            </dl>
            <xsl:apply-templates select="description/node()"/>
          </xsl:template>


          <xsl:template mode="page-content" match="Article">
            <!-- TODO: What's the intention of this form? The whole document is on the client, but it has no client-side behavior
            <form id="doc_search" action="" method="get">

              <fieldset>
                <legend><label for="ds_inp">Search current document</label></legend>
                <input id="ds_inp" type="text" />
                <input type="submit" />
              </fieldset>
            </form>
            -->
            <!-- placeholder for form to get CSS to display background -->
            <div id="doc_search"/>

            <h2>
              <xsl:apply-templates select="title/node()"/>
            </h2>
            <div class="author">
              <xsl:apply-templates select="author/node()"/>
            </div>
            <div class="date"> 
              <xsl:text>Last updated </xsl:text>
              <xsl:value-of select="last-updated"/>
            </div>
            <xsl:apply-templates select="body/node()"/>
          </xsl:template>


          <xsl:template mode="page-content" match="Project">
            <h2>
              <xsl:value-of select="name"/>
            </h2>
            <xsl:apply-templates select="description/node()"/>
            <table class="table4">
              <thead>
                <tr>
                  <th scope="col">
                    <xsl:value-of select="name"/>
                  </th>
                  <th class="size" scope="col">MarkLogic Version Needed</th>
                  <th class="last" scope="col">Date Posted</th>
                </tr>
              </thead>
              <tbody>
                <xsl:apply-templates mode="project-version" select="versions/version"/>
              </tbody>
            </table>
            <div class="action">
              <a href="{contributors/@href}">Contributors</a>
              <a href="{versions/@get-involved-href}">Get involved with this project</a>
            </div>
            <xsl:apply-templates select="top-threads"/>
          </xsl:template>

                  <xsl:template mode="project-version" match="version">
                    <tr>
                      <xsl:if test="position() mod 2 eq 1">
                        <xsl:attribute name="class">alt</xsl:attribute>
                      </xsl:if>
                      <td>
                        <a href="{@href}">
                          <xsl:value-of select="@href"/>
                        </a>
                      </td>
                      <td>
                        <xsl:text>MarkLogic Server </xsl:text>
                        <xsl:value-of select="@server-version"/>
                        <xsl:text> or later</xsl:text>
                      </td>
                      <td>
                        <xsl:value-of select="@date"/>
                      </td>
                    </tr>
                  </xsl:template>


          <xsl:template mode="page-content" match="Announcement">
            <h1>News</h1>
            <div class="date">
              <xsl:value-of select="ml:display-date(date)"/>
            </div>
            <h2>
              <xsl:apply-templates select="title/node()"/>
            </h2>
            <xsl:apply-templates select="body/node()"/>
          </xsl:template>


  <xsl:template match="top-nav">
    <ul>
      <xsl:apply-templates mode="top-nav" select="$navigation/*/page"/>
    </ul>
  </xsl:template>

          <xsl:template mode="top-nav" match="page">
            <li>
              <xsl:apply-templates mode="top-nav-current-att" select="."/>
              <a href="{@href}">
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
    <h2>Document TOC</h2>
    <ul>
      <xsl:apply-templates mode="article-toc" select="$content/Article//xhtml:h3"/>
    </ul>
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
    <xsl:variable name="children" select="$page-in-navigation/ancestor-or-self::page[group | page]/(group | page)"/>
    <xsl:if test="$children">
      <div class="subnav">
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
                  <xsl:template mode="sub-nav" match="page">
                    <li>
                      <xsl:apply-templates mode="sub-nav-current-att" select="."/>
                      <a href="{@href}">
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
      <xsl:apply-templates mode="body-class"        select="$page-in-navigation"/>
      <xsl:apply-templates mode="body-class-extra"  select="$page-in-navigation"/>
    </xsl:attribute>
  </xsl:template>

          <xsl:template mode="body-class" match="navigation/page">main_page</xsl:template>
          <xsl:template mode="body-class" match="generic-page"   >generic</xsl:template>
          <xsl:template mode="body-class" match="*"              >sub_page</xsl:template>

          <xsl:template mode="body-class-extra" match="*"/>
          <xsl:template mode="body-class-extra" match="page[@href eq '/']                                  "> home</xsl:template>
          <xsl:template mode="body-class-extra" match="Article                                             "> layout2</xsl:template>
          <xsl:template mode="body-class-extra" match="page[ancestor-or-self::page/@narrow-sidebar = 'yes']"> layout3</xsl:template>

          <xsl:template mode="body-class-extra" match="@css-class">
            <xsl:text> </xsl:text>
            <xsl:value-of select="."/>
          </xsl:template>


  <xsl:template match="xhtml:div[@id eq 'content']/@ml:class">
    <xsl:variable name="last-widget" select="$widget-config/widgets/widget[*[ml:matches-current-page(.)]][last()]"/>
    <!-- If the last widget is a "feature widget", we need to accordingly babysit the CSS class -->
    <xsl:if test="$last-widget/@feature">
      <xsl:attribute name="class">sub_special</xsl:attribute>
    </xsl:if>
  </xsl:template>


  <xsl:template match="tabbed-features">
    <div id="special_intro">
      <ul class="nav">
        <xsl:apply-templates mode="feature-tab" select="feature"/>
      </ul>
      <xsl:apply-templates mode="feature-tab-content" select="feature"/>
    </div>
  </xsl:template>

          <xsl:template mode="feature-tab" match="feature">
            <li>
              <a href="#section{position()}">
                <xsl:value-of select="document(@href)/feature/title"/>
              </a>
            </li>
          </xsl:template>

          <xsl:template mode="feature-tab-content" match="feature">
            <xsl:variable name="feature" select="document(@href)/feature"/>

            <div class="section" id="section{position()}">
              <div class="align_right">
                <xsl:apply-templates mode="feature-content" select="$feature/image"/>
              </div>
              <xsl:apply-templates mode="feature-content" select="$feature/(* except (title,image))"/>
            </div>
          </xsl:template>

                  <xsl:template mode="feature-content" match="image">
                    <img src="{@src}" alt="{@alt}"/>
                    <xsl:apply-templates mode="feature-content" select="caption"/>
                  </xsl:template>

                          <xsl:template mode="feature-content" match="caption">
                            <div class="caption">
                              <xsl:apply-templates/>
                            </div>
                          </xsl:template>

                  <xsl:template mode="feature-content" match="main-points">
                    <ul>
                      <xsl:apply-templates mode="feature-content" select="point"/>
                    </ul>
                  </xsl:template>

                          <xsl:template mode="feature-content" match="point">
                            <li>
                              <xsl:apply-templates/>
                            </li>
                          </xsl:template>

                  <xsl:template mode="feature-content" match="read-more">
                    <ul class="more">
                      <xsl:apply-templates mode="feature-content" select="link"/>
                    </ul>
                  </xsl:template>

                          <xsl:template mode="feature-content" match="link">
                            <li>
                              <a href="{@href}">
                                <xsl:apply-templates/>
                                <xsl:text>&#160;></xsl:text>
                              </a>
                            </li>
                          </xsl:template>

                  <xsl:template mode="feature-content" match="download-button">
                    <xsl:param name="is-widget" tunnel="yes"/>
                    <xsl:variable name="button-class" select="if ($is-widget) then 'download' else 'button'"/>
                    <a class="{$button-class}" href="{@href}">
                      <img src="/images/b_download_now.png" alt="Download Now"/>
                    </a>
                  </xsl:template>


  <xsl:template match="product-info">
    <h2>
      <xsl:value-of select="@name"/>
    </h2>

    <a class="more" href="{@license-page}">License Options &gt;</a>

    <xsl:apply-templates mode="product-platform" select="platform"/>
  </xsl:template>

          <xsl:template mode="product-platform" match="platform">
            <table class="table1">
              <thead>
                <tr>
                  <th scope="col">
                    <xsl:value-of select="@name"/>
                  </th>
                  <th class="size" scope="col">File Size</th>
                  <th class="last" scope="col">Date Posted</th>
                </tr>
              </thead>
              <tbody>
                <xsl:apply-templates mode="product-download" select="download"/>
              </tbody>
            </table>
          </xsl:template>

                  <xsl:template mode="product-download" match="download">
                    <tr>
                      <td>
                        <a href="{@href}">
                          <img src="/images/icon_download.png" alt="Download"/>
                          <xsl:apply-templates/>
                        </a>
                      </td>
                      <td>
                        <xsl:value-of select="@size"/>
                      </td>
                      <td>
                        <xsl:value-of select="@date"/>
                      </td>
                    </tr>
                  </xsl:template>

  <xsl:template match="product-documentation">
    <table class="table2">
      <caption>Documentation</caption>
      <tbody>
        <xsl:apply-templates mode="product-doc-entry" select="doc"/>
      </tbody>
    </table>
  </xsl:template>

          <xsl:template mode="product-doc-entry" match="doc">
            <tr>
              <td>
                <!-- TODO: add support for displaying PDF documents -->
                <xsl:value-of select="document(ml:internal-uri(@href))/*/title"/>
              </td>
              <td> 
                <a href="{@href}">
                  <!-- TODO: add support for displaying PDF documents -->
                  <img src="/images/icon_browser.png" alt="view"/>
                </a>
              </td>
            </tr>
          </xsl:template>


  <xsl:template match="widgets">
    <xsl:apply-templates mode="widget" select="$widget-config/widgets/widget[*[ml:matches-current-page(.)]]"/>
  </xsl:template>

          <xsl:template mode="widget" match="widget[@feature]">
            <div class="section special">
              <div class="head">
                <h2>
                  <xsl:apply-templates select="document(@feature)/feature/title/node()"/>
                </h2>
              </div>
              <div class="body">
                <xsl:apply-templates mode="feature-content" select="document(@feature)/feature/(* except title)">
                  <xsl:with-param name="is-widget" select="true()" tunnel="yes"/>
                </xsl:apply-templates>
              </div>
            </div>
          </xsl:template>

          <xsl:template mode="widget" match="widget">
            <div class="section">
              <xsl:apply-templates select="document(@href)/widget/node()"/>
            </div>
          </xsl:template>


          <xsl:function name="ml:matches-current-page" as="xs:boolean">
            <xsl:param name="element" as="element()"/>
            <xsl:apply-templates mode="matches-current-page" select="$element"/>
          </xsl:function>

                  <xsl:template mode="matches-current-page" match="page[@href]">
                    <xsl:sequence select="@href eq $external-uri"/>
                  </xsl:template>

                  <xsl:template mode="matches-current-page" match="page-tree">
                    <xsl:sequence select="$external-uri = $navigation//page[@href eq current()/@root]/descendant-or-self::page/@href"/>
                  </xsl:template>

                  <xsl:template mode="matches-current-page" match="page-children">
                    <xsl:sequence select="$external-uri = $navigation//page[@href eq current()/@parent]/descendant::page/@href"/>
                  </xsl:template>

                  <xsl:template mode="matches-current-page" match="*">
                    <xsl:sequence select="node-name($content/*) eq node-name(.)"/>
                  </xsl:template>



  <xsl:template match="recent-blog-posts">
    <xsl:variable name="count" select="@count" as="xs:integer"/>
    <xsl:for-each select="$collection/Post">
      <xsl:sort select="date" order="descending"/>
      <xsl:if test="position() le $count">
        <xsl:apply-templates mode="blog-post" select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:template>


  <xsl:template match="event-list">
    <xsl:variable name="events" select="ml:recent-events(xs:integer(@past-months))"/>
    <xsl:apply-templates mode="event-teaser" select="$events">
      <xsl:sort select="details/date" order="descending"/>
    </xsl:apply-templates>
  </xsl:template>

          <xsl:template mode="event-teaser" match="Event">
            <div class="newsitem">
              <h3>
                <xsl:apply-templates select="title/node()"/>
              </h3>
              <dl>
                <xsl:apply-templates mode="event-details" select="details/*"/>
              </dl>
              <p>
                <xsl:apply-templates select="description//teaser/node()"/>
                <xsl:text> </xsl:text>
                <xsl:apply-templates mode="read-more" select="."/>
              </p>
            </div>
          </xsl:template>


  <xsl:template match="announcement-list">
    <xsl:variable name="announcements" select="ml:recent-announcements(xs:integer(@past-months))"/>
    <xsl:apply-templates mode="announcement-teaser" select="$announcements">
      <xsl:sort select="date" order="descending"/>
    </xsl:apply-templates>
  </xsl:template>

          <xsl:template mode="announcement-teaser" match="Announcement">
            <div class="newsitem">
              <div class="date">
                <xsl:value-of select="ml:display-date(date)"/>
              </div>
              <h3>
                <xsl:apply-templates select="title/node()"/>
              </h3>
              <p>
                <xsl:apply-templates select="body//teaser/node()"/>
                <xsl:text> </xsl:text>
                <xsl:apply-templates mode="read-more" select="."/>
              </p>
            </div>
          </xsl:template>


  <xsl:template match="top-threads">
    <xsl:variable name="threads" select="ml:get-threads(@search,list)"/>
    <div class="single">
      <h2>Top Threads</h2>
      <!-- TODO: Put the correct URL here -->
      <a class="more" href="">All threads&#160;></a>
      <table class="table3">
        <thead>
          <tr>
            <th scope="col">
              <span>Thread</span>
              <br/>
              Mailing List
            </th>
            <th scope="col">Latest Post</th>
            <th scope="col">Replies</th>
            <th class="last" scope="col">Views</th>
          </tr>
        </thead>
        <tbody>
          <xsl:apply-templates mode="display-thread" select="$threads"/>
        </tbody>
      </table>
      <div class="action">
        <!-- TODO: Put the correct URL here -->
        <a href="">Start a new thread</a>
      </div>
    </div>
  </xsl:template>


          <xsl:template mode="display-thread" match="thread">            
            <tr>
              <xsl:if test="position() mod 2 eq 0">
                <xsl:attribute name="class">alt</xsl:attribute>
              </xsl:if>
              <td>
                <a class="thread" href="{@href}">
                  <xsl:value-of select="@title"/>
                </a>
                <br/>
                <a href="{list/@href}">
                  <xsl:value-of select="list"/>
                </a>
              </td>
              <td>
                <span class="date">
                  <xsl:apply-templates mode="display-date" select="@date-time"/>
                </span>
                <span class="time">
                  <xsl:apply-templates mode="display-time" select="@date-time"/>
                </span>
                <a class="author" href="{author/@href}">
                  <xsl:text>by </xsl:text>
                  <xsl:value-of select="author"/>
                </a>
              </td>
              <td>
                <xsl:value-of select="@replies"/>
              </td>
              <td>
                <xsl:value-of select="@views"/>
              </td>
            </tr>
          </xsl:template>


  <xsl:template match="upcoming-user-group-events">
    <xsl:variable name="events" select="ml:upcoming-user-group-events()"/>
    <div class="double">
      <h2>Upcoming Events</h2>
      <a class="more" href="/events">All events&#160;></a>
      <xsl:for-each select="$events">
        <div>
          <xsl:apply-templates mode="event-excerpt" select=".">
            <xsl:with-param name="suppress-more-link" select="true()" tunnel="yes"/>
            <xsl:with-param name="suppress-description" select="true()" tunnel="yes"/>
          </xsl:apply-templates>
        </div>
      </xsl:for-each>
    </div>
  </xsl:template>


  <xsl:template match="latest-user-group-announcement">
    <xsl:variable name="announcement" select="ml:latest-user-group-announcement()"/>
    <div class="single">
      <h2>Recent News</h2>
      <a class="more" href="/news">All news&#160;></a>
      <xsl:apply-templates mode="announcement-image" select="$announcement/image"/>
      <xsl:apply-templates mode="news-excerpt" select="$announcement">
        <xsl:with-param name="suppress-more-link" select="true()" tunnel="yes"/>
        <xsl:with-param name="read-more-inline" select="true()" tunnel="yes"/>
      </xsl:apply-templates>
    </div>
  </xsl:template>

          <xsl:template mode="announcement-image" match="image">
            <img class="align_left" src="/images/recent_news.jpg" alt="Recent news"/>
          </xsl:template>


  <xsl:template match="recent-news-and-events">
    <xsl:variable name="announcement" select="ml:latest-announcement()"/>
    <xsl:variable name="event"        select="ml:latest-event()"/>
    <div class="double">
      <div>
        <h2>Recent News</h2>
        <xsl:apply-templates mode="news-excerpt" select="$announcement">
          <xsl:with-param name="suppress-more-link" select="string(@suppress-more-links) eq 'yes'" tunnel="yes"/>
        </xsl:apply-templates>
      </div>
      <div>
        <h2>Upcoming Events</h2>
        <xsl:apply-templates mode="event-excerpt" select="$event">
          <xsl:with-param name="suppress-more-link" select="string(@suppress-more-links) eq 'yes'" tunnel="yes"/>
        </xsl:apply-templates>
      </div>
    </div>
  </xsl:template>

          <xsl:template mode="news-excerpt" match="Announcement">
            <xsl:param name="read-more-inline" tunnel="yes"/>
            <h3>
              <xsl:apply-templates select="title/node()"/>
            </h3>
            <p>
              <xsl:apply-templates select="if (normalize-space(abstract)) then abstract/node()
                                                                          else body/xhtml:p[1]/node()"/>
              <xsl:if test="$read-more-inline">
                <xsl:text> </xsl:text>
                <xsl:apply-templates mode="read-more" select="."/>
              </xsl:if>
            </p>
            <xsl:if test="not($read-more-inline)">
              <xsl:apply-templates mode="read-more" select="."/>
            </xsl:if>
            <xsl:apply-templates mode="more-link" select="."/>
          </xsl:template>

                  <xsl:template mode="read-more" match="Announcement | Event">
                    <a class="more" href="{ml:external-uri(.)}">Read more&#160;></a>
                  </xsl:template>


          <xsl:template mode="event-excerpt" match="Event">
            <xsl:param name="suppress-description" tunnel="yes"/>
            <h3>
              <xsl:apply-templates select="title/node()"/>
            </h3>
            <xsl:if test="not($suppress-description)">
              <xsl:apply-templates select="description/node()"/>
            </xsl:if>
            <dl>
              <xsl:apply-templates mode="event-details" select="details/*"/>
            </dl>
            <a class="more" href="{ml:external-uri(.)}">More information&#160;></a>
            <xsl:apply-templates mode="more-link" select="."/>
          </xsl:template>

                  <xsl:template mode="more-link" match="*">
                    <xsl:param name="suppress-more-link" tunnel="yes" as="xs:boolean" select="false()"/>
                    <xsl:if test="not($suppress-more-link)">
                      <xsl:variable name="href">
                        <xsl:apply-templates mode="more-link-href" select="."/>
                      </xsl:variable>
                      <xsl:variable name="link-text">
                        <xsl:apply-templates mode="more-link-text" select="."/>
                      </xsl:variable>

                      <div class="more">
                        <a href="{$href}">
                          <xsl:value-of select="$link-text"/>
                          <xsl:text>&#160;></xsl:text>
                        </a>
                      </div>

                    </xsl:if>
                  </xsl:template>

                          <xsl:template mode="more-link-href" match="Event"       >/events</xsl:template>
                          <xsl:template mode="more-link-href" match="Announcement">/news</xsl:template>

                          <xsl:template mode="more-link-text" match="Event"       >More Events</xsl:template>
                          <xsl:template mode="more-link-text" match="Announcement">More News</xsl:template>


                  <!-- TODO: For dates and times, consider use ISO 8601 format (in the source data) instead -->
                  <xsl:template mode="event-details" match="*">
                    <dt>
                      <xsl:apply-templates mode="event-detail-name" select="."/>
                      <xsl:text>:</xsl:text>
                    </dt>
                    <dd>
                      <xsl:apply-templates/>
                    </dd>
                  </xsl:template>

                          <xsl:template mode="event-detail-name" match="date"     >Date</xsl:template>
                          <xsl:template mode="event-detail-name" match="time"     >Time</xsl:template>
                          <xsl:template mode="event-detail-name" match="location" >Location</xsl:template>
                          <xsl:template mode="event-detail-name" match="topic"    >Topic</xsl:template>
                          <xsl:template mode="event-detail-name" match="presenter">Presenter</xsl:template>


  <xsl:template match="article-teaser">
    <xsl:apply-templates mode="article-teaser" select="document(@href)/Article">
      <xsl:with-param name="heading" select="@heading"/>
      <xsl:with-param name="suppress-byline" select="true()"/>
    </xsl:apply-templates>
  </xsl:template>

  <xsl:template match="recent-article">
    <xsl:apply-templates mode="article-teaser" select="ml:latest-article(string(@type))">
      <xsl:with-param name="heading" select="@heading"/>
    </xsl:apply-templates>
  </xsl:template>

          <xsl:template mode="article-teaser" match="Article">
            <xsl:param name="heading" as="xs:string"/>
            <xsl:param name="suppress-byline"/>
            <div class="single">
              <h2>
                <xsl:value-of select="$heading"/>
              </h2>
              <h3>
                <xsl:apply-templates select="title/node()"/>
              </h3>
              <xsl:if test="not($suppress-byline)">
                <div class="author">
                  <xsl:text>By </xsl:text>
                  <xsl:value-of select="author"/>
                </div>
              </xsl:if>
              <p>
                <xsl:apply-templates select="if (normalize-space(abstract)) then abstract/node()
                                                                            else body/xhtml:p[1]/node()"/>
                <xsl:text> </xsl:text>
                <a class="more" href="{ml:external-uri(.)}">Read&#160;more&#160;></a>
              </p>
            </div>
          </xsl:template>


  <xsl:template match="read-more">
    <a class="more" href="{@href}">Read&#160;more&#160;></a>
  </xsl:template>

  <xsl:template match="license-options">
    <div class="action">
      <ul>
        <li>
          <a href="{@href}">License options</a>
        </li>
      </ul>
    </div>
  </xsl:template>


  <xsl:template match="document-list">
    <xsl:variable name="docs" select="ml:lookup-articles(string(@type), string(@topic))"/>
    <div class="doclist">
      <h2>Documents</h2>
      <!-- 2.0 feature TODO: add pagination -->
      <span class="amount">
        <xsl:value-of select="count($docs)"/>
        <xsl:text> of </xsl:text>
        <xsl:value-of select="count($docs)"/>
        <xsl:text> documents</xsl:text>
      </span>
      <!--
      <form action="" method="get">
        <div>
          <label for="kw_inp">Search documents by keyword</label>
          <input id="kw_inp" type="text"/>
          <input type="submit"/>
        </div>
      </form>
      -->
      <table>
        <colgroup>
          <col class="col1"/>
          <col class="col2"/>
          <col class="col3"/>
          <col class="col4"/>
        </colgroup>
        <thead>
          <tr>
            <th scope="col">Title</th>
            <th scope="col">Document&#160;Type</th>
            <th scope="col">Topic(s)</th>
            <th scope="col" class="sort">Date</th>
          </tr>
        </thead>
        <tbody>
          <xsl:apply-templates mode="doc-listing" select="$docs">
            <xsl:sort select="created" order="descending"/>
          </xsl:apply-templates>
        </tbody>
      </table>
    </div>
  </xsl:template>

          <xsl:template mode="doc-listing" match="Article">
            <tr>
              <xsl:if test="position() mod 2 eq 0">
                <xsl:attribute name="class">alt</xsl:attribute>
              </xsl:if>
              <th>
                <a href="{if (external-link/@href)
                         then external-link/@href
                         else ml:external-uri(.)}">
                  <xsl:value-of select="title"/>
                </a>
              </th>
              <td>
                <xsl:value-of select="replace(@type,' ','&#160;')"/>
              </td>
              <td>
                <xsl:value-of select="topics/topic/replace(.,' ','&#160;')" separator=", "/>
              </td>
              <td>
                <xsl:value-of select="created"/>
              </td>
            </tr>
          </xsl:template>


  <!-- TODO: refactor these repetitive functions -->

  <xsl:function name="ml:latest-user-group-announcement">
    <xsl:for-each select="$collection/Announcement[string(@user-group)]">
      <xsl:sort select="date" order="descending"/>
      <xsl:if test="position() eq 1">
        <xsl:sequence select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:function>

  <xsl:function name="ml:latest-announcement">
    <xsl:for-each select="$collection/Announcement">
      <xsl:sort select="date" order="descending"/>
      <xsl:if test="position() eq 1">
        <xsl:sequence select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:function>

  <xsl:function name="ml:upcoming-user-group-events">
    <xsl:variable name="future-events" select="$collection/Event[string(@user-group)][xs:date(details/date) >= current-date()]"/>
    <xsl:for-each select="$future-events">
      <xsl:sort select="details/date"/>
      <xsl:if test="position() le 2">
        <xsl:sequence select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:function>

  <xsl:function name="ml:latest-event">
    <xsl:variable name="future-events" select="$collection/Event[xs:date(details/date) >= current-date()]"/>
    <xsl:for-each select="$collection/Event">
      <xsl:sort select="details/date" order="descending"/>
      <xsl:if test="position() eq 1">
        <xsl:sequence select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:function>

  <xsl:function name="ml:latest-article">
    <xsl:param name="type"  as="xs:string"/>
    <xsl:variable name="articles" select="ml:lookup-articles($type, '')"/>
    <xsl:for-each select="$articles">
      <xsl:sort select="created" order="descending"/>
      <xsl:if test="position() eq 1">
        <xsl:sequence select="."/>
      </xsl:if>
    </xsl:for-each>
  </xsl:function>

  <xsl:function name="ml:lookup-articles" as="element()*">
    <xsl:param name="type"  as="xs:string"/>
    <xsl:param name="topic" as="xs:string"/>
    <xsl:sequence select="$collection/Article[(($type  eq @type)        or not($type)) and
                                              (($topic =  topics/topic) or not($topic))]"/>
  </xsl:function>


  <xsl:function name="ml:recent-events" as="element()*">
    <xsl:param name="months" as="xs:integer"/>
    <xsl:variable name="duration" select="concat('P', $months, 'M')"/>
    <xsl:variable name="start-date" select="current-date() - xs:yearMonthDuration($duration)"/>
    <xsl:sequence select="$collection/Event[xs:date(details/date) >= $start-date]"/>
  </xsl:function>

  <xsl:function name="ml:recent-announcements" as="element()*">
    <xsl:param name="months" as="xs:integer"/>
    <xsl:variable name="duration" select="concat('P', $months, 'M')"/>
    <xsl:variable name="start-date" select="current-date() - xs:yearMonthDuration($duration)"/>
    <xsl:sequence select="$collection/Announcement[xs:date(date) >= $start-date]"/>
  </xsl:function>

  <xsl:function name="ml:get-threads">
    <xsl:param name="search" as="xs:string?"/>
    <xsl:param name="lists"  as="element()*"/>
    <!-- TODO: offload this to an XQuery script authored by someone else -->
    <ml:thread title="MarkLogic Server 4.1 Rocks!!" href="..." date-time="2010-03-04T11:22" replies="2" views="14">
      <ml:author href="...">JoelH</ml:author>
      <ml:list href="...">Mark Logic General</ml:list>
    </ml:thread>
    <ml:thread title="Issue with lorem ipsum dolor" date-time="2009-09-23T13:22" replies="2" views="15">
      <ml:author href="...">Laderlappen</ml:author>
      <ml:list href="...">Mark Logic General</ml:list>
    </ml:thread>
    <ml:thread title="Lorem ipsum dolor sit amet" date-time="2009-09-24T23:22" replies="1" views="1">
      <ml:author href="...">Jane</ml:author>
      <ml:list href="...">Mark Logic General</ml:list>
    </ml:thread>
    <ml:thread title="Useful tips for NY meets" date-time="2009-09-26T13:22" replies="12" views="134">
      <ml:author href="...">JoelH</ml:author>
      <ml:list href="...">Mark Logic General</ml:list>
    </ml:thread>
    <ml:thread title="Lorem ipsum dolor sit amet" date-time="2009-10-03T10:37" replies="0" views="12">
      <ml:author href="...">JoelH</ml:author>
      <ml:list href="...">Mark Logic General</ml:list>
    </ml:thread>
  </xsl:function>

  <xsl:function name="ml:month-name" as="xs:string">
    <xsl:param name="month" as="xs:integer"/>
    <xsl:sequence select="if ($month eq  1) then 'January'
                     else if ($month eq  2) then 'February'
                     else if ($month eq  3) then 'March'
                     else if ($month eq  4) then 'April'
                     else if ($month eq  5) then 'May'
                     else if ($month eq  6) then 'June'
                     else if ($month eq  7) then 'July'
                     else if ($month eq  8) then 'August'
                     else if ($month eq  9) then 'September'
                     else if ($month eq 10) then 'October'
                     else if ($month eq 11) then 'November'
                     else if ($month eq 12) then 'December'
                     else ()"/>
  </xsl:function>


  <xsl:function name="ml:display-date" as="xs:string">
    <xsl:param name="date"/>
    <!-- TODO: implement this -->
    <xsl:sequence select="$date"/>
  </xsl:function>

  <xsl:function name="ml:display-time" as="xs:string">
    <xsl:param name="date"/>
    <!-- TODO: implement this -->
    <xsl:sequence select="$date"/>
  </xsl:function>

  <xsl:function name="ml:external-uri" as="xs:string">
    <xsl:param name="node" as="node()"/>
    <xsl:variable name="doc-path" select="base-uri($node)"/>
    <xsl:sequence select="if ($doc-path eq '/index.xml') then '/' else substring-before($doc-path, '.xml')"/>
  </xsl:function>

  <xsl:function name="ml:internal-uri" as="xs:string">
    <xsl:param name="doc-path" as="xs:string"/>
    <xsl:sequence select="if ($doc-path eq '/') then '/index.xml' else concat($doc-path, '.xml')"/>
  </xsl:function>

</xsl:stylesheet>
