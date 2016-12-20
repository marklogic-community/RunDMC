<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:srv="http://marklogic.com/rundmc/server-urls"
  xmlns:authorize="http://marklogic.com/rundmc/authorize"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp srv"
  extension-element-prefixes="xdmp">

  <!-- Import the definition of $srv:draft-server and $srv:webdav-server -->
  <xdmp:import-module href="/controller/server-urls.xqy" namespace="http://marklogic.com/rundmc/server-urls"/>
  <xdmp:import-module href="/admin/controller/modules/authorize.xqy" namespace="http://marklogic.com/rundmc/authorize"/>

  <xsl:template match="admin-page-listings">
    <table id="tbl_status" class="table table-striped table-bordered">
      <caption>Page Status</caption>
      <thead>
        <tr>
          <th scope="col">Type</th>
          <th scope="col">Published</th>
          <th scope="col">Pending</th>
          <th class="last">&#160;</th>
        </tr>
      </thead>
      <tbody>
        <xsl:variable name="sections" xmlns="">
          <Blog          doc-type="Post"         path="/blog"/>
          <Author        doc-type="author"       path="/author"/>
          <Code          doc-type="Project"      path="/code"/>
          <Learn         doc-type="Article"      path="/learn"/>
          <Media         doc-type="media"        path="/media"/>
          <OnDemand      doc-type="ondemand"     path="/ondemand"/>
          <Pages         doc-type="page"         path="/pages"/>
          <Recipe        doc-type="recipe"       path="/recipe"/>
          <News          doc-type="Announcement" path="/news"/>
          <Events        doc-type="Event"        path="/events"/>
        </xsl:variable>
        <xsl:apply-templates mode="admin-page-listing" select="$sections/*"/>
      </tbody>
    </table>
  </xsl:template>

  <xsl:template mode="admin-page-listing" match="*">
    <xsl:variable name="docs" select="ml:docs-by-type(@doc-type)"/>
    <tr>
      <td scope="row">
        <a href="{@path}">
          <xsl:value-of select="translate(local-name(.),'_',' ')"/>
        </a>
      </td>
      <td>
        <xsl:choose>
          <xsl:when test="@doc-type = 'media'">
            <xsl:value-of select="count($ml:media-uris)"/>
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="count($docs[@status eq 'Published'])"/>
          </xsl:otherwise>
        </xsl:choose>
      </td>
      <td class="status pending">
        <xsl:choose>
          <xsl:when test="@doc-type = 'media'">
            0
          </xsl:when>
          <xsl:otherwise>
            <xsl:value-of select="count($docs[@status eq 'Draft'])"/>
          </xsl:otherwise>
        </xsl:choose>
      </td>
      <td>
        <a href="{@path}" class="btn btn-default btn-sm">List</a>
        <a href="{concat(@path,'/edit')}" class="btn btn-default btn-sm">Add new</a>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="admin-project-list
                     | admin-learn-list
                     | admin-post-list
                     | admin-announcement-list
                     | admin-event-list
                     | admin-page-list">
    <table class="table table-striped table-bordered resource-list">
      <thead>
        <tr>
          <th scope="col">Title</th>
          <xsl:if test="not(self::admin-page-list)">
            <xsl:if test="not(self::admin-event-list)">
              <th scope="col">Author</th>
            </xsl:if>
            <xsl:if test="not(self::admin-project-list)">
              <th scope="col">Created or Published</th>
              <th scope="col">Last&#160;Updated</th>
            </xsl:if>
          </xsl:if>
          <th scope="col">URI</th>
          <th scope="col">Status</th>
          <th class="last">&#160;</th>
        </tr>
      </thead>
      <tbody>
        <xsl:variable name="doc-type" select="if (self::admin-project-list)      then 'Project'
                                         else if (self::admin-learn-list)        then 'Article'
                                         else if (self::admin-post-list)         then 'Post'
                                         else if (self::admin-announcement-list) then 'Announcement'
                                         else if (self::admin-event-list)        then 'Event'
                                         else if (self::admin-page-list)         then 'page'
                                         else ()"/>
        <xsl:variable name="docs" select="ml:docs-by-type($doc-type)"/>
        <xsl:apply-templates mode="admin-listing" select="$docs">
          <!-- Only sort if we're listing "page" docs; otherwise, don't change the order. -->
          <xsl:sort select="if (self::page) then ml:admin-doc-title(.) else ()"/>
          <xsl:with-param name="current-page-url" select="ml:external-uri(.)"/>
        </xsl:apply-templates>
      </tbody>
    </table>
  </xsl:template>

  <xsl:template match="admin-recipe-list">
    <table class="table table-striped table-bordered resource-list">
      <thead>
        <tr>
          <th>URI</th>
          <th>Language</th>
          <th>Last Updated</th>
          <th>Status</th>
          <th></th>
        </tr>
      </thead>
      <tbody>
        <xsl:variable name="docs" select="ml:docs-by-type('recipe')"/>
        <xsl:apply-templates mode="admin-recipe-listing" select="$docs">
          <!-- Only sort if we're listing "page" docs; otherwise, don't change the order. -->
          <xsl:sort select="if (self::page) then ml:admin-doc-title(.) else ()"/>
          <xsl:with-param name="current-page-url" select="ml:external-uri(.)"/>
        </xsl:apply-templates>
      </tbody>
    </table>
  </xsl:template>

  <xsl:template mode="admin-recipe-listing" match="*">
    <xsl:param name="current-page-url"/>
    <xsl:variable name="edit-path">
      <xsl:apply-templates mode="edit-path" select="."/>
    </xsl:variable>
    <xsl:variable name="edit-link" select="concat($edit-path, '?~doc_path=', base-uri(.))"/>
    <tr>
      <xsl:if test="position() mod 2 eq 0">
        <xsl:attribute name="class">alt</xsl:attribute>
      </xsl:if>
      <td>
        <a href="{$edit-link}">
          <xsl:value-of select="base-uri(.)"/>
        </a>
      </td>
      <td></td>
      <td>
        <xsl:value-of select="ml:display-date-with-time(last-updated)"/>
      </td>

      <xsl:variable name="effective-status" select="if (@status) then @status else 'Published'"/>
      <td class="status {lower-case($effective-status)}">
        <xsl:value-of select="$effective-status"/>
      </td>
      <td>
        <a href="{$edit-link}" class="btn btn-default btn-sm">Edit</a>
        <!-- TODO: make preview work -->
        <a href="{$srv:draft-server}{substring-before(base-uri(.), '.xml')}" target="_blank" class="btn btn-default btn-sm">Preview</a>
        <!-- Only show the Publish/Unpublish toggle if the user logged in is the proper role -->
        <xsl:if test="authorize:is-admin()">
          <xsl:variable name="action" select="if (@status eq 'Published') then 'Unpublish' else 'Publish'"/>
          <a href="/admin/controller/publish-unpublish-doc.xqy?path={base-uri(.)}&amp;action={$action}&amp;redirect={$current-page-url}" class="btn btn-default btn-sm">
            <xsl:value-of select="$action"/>
          </a>
        </xsl:if>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="admin-author-list">
    <table class="table table-striped table-bordered resource-list">
      <thead>
        <tr>
          <th scope="col">Name</th>
          <th scope="col">URI</th>
          <th scope="col">Created</th>
          <th scope="col">Status</th>
          <th class="last">&#160;</th>
        </tr>
      </thead>
      <tbody>
        <xsl:variable name="docs" select="ml:docs-by-type('author')"/>
        <xsl:apply-templates mode="admin-author-listing" select="$docs">
          <!-- Only sort if we're listing "page" docs; otherwise, don't change the order. -->
          <xsl:sort select="if (self::page) then ml:admin-doc-title(.) else ()"/>
          <xsl:with-param name="current-page-url" select="ml:external-uri(.)"/>
        </xsl:apply-templates>
      </tbody>
    </table>
  </xsl:template>

  <xsl:template mode="admin-author-listing" match="*">
    <xsl:param name="current-page-url"/>
    <xsl:variable name="edit-path">
      <xsl:apply-templates mode="edit-path" select="."/>
    </xsl:variable>
    <xsl:variable name="edit-link" select="concat($edit-path, '?~doc_path=', base-uri(.))"/>
    <tr>
      <xsl:if test="position() mod 2 eq 0">
        <xsl:attribute name="class">alt</xsl:attribute>
      </xsl:if>
      <th>
        <a href="{$edit-link}">
          <xsl:value-of select="name"/>
        </a>
      </th>
      <td>
        <xsl:value-of select="base-uri(.)"/>
      </td>
      <td>
        <xsl:value-of select="ml:display-date-with-time(created)"/>
      </td>

      <xsl:variable name="effective-status" select="if (@status) then @status else 'Published'"/>
      <td class="status {lower-case($effective-status)}">
        <xsl:value-of select="$effective-status"/>
      </td>
      <td>
        <a href="{$edit-link}" class="btn btn-default btn-sm">Edit</a>
        <!-- TODO: make preview work -->
        <a href="{$srv:draft-server}{substring-before(base-uri(.), '.xml')}" target="_blank" class="btn btn-default btn-sm">Preview</a>
        <!-- Only show the Publish/Unpublish toggle if the user logged in is the proper role -->
        <xsl:if test="authorize:is-admin()">
          <xsl:variable name="action" select="if (@status eq 'Published') then 'Unpublish' else 'Publish'"/>
          <a href="/admin/controller/publish-unpublish-doc.xqy?path={base-uri(.)}&amp;action={$action}&amp;redirect={$current-page-url}" class="btn btn-default btn-sm">
            <xsl:value-of select="$action"/>
          </a>
        </xsl:if>
      </td>
    </tr>
  </xsl:template>

  <xsl:template match="admin-ondemand-list">
    <table class="table table-bordered table-striped resource-list">
      <thead>
        <tr>
          <th scope="col">Title</th>
          <th scope="col">URI</th>
          <th scope="col">Created</th>
          <th scope="col">Status</th>
          <th class="last">&#160;</th>
        </tr>
      </thead>
      <tbody>
        <xsl:variable name="docs" select="ml:docs-by-type('OnDemand')"/>
        <xsl:apply-templates mode="admin-ondemand-listing" select="$docs">
        </xsl:apply-templates>
      </tbody>
    </table>
  </xsl:template>

  <xsl:template mode="admin-ondemand-listing" match="*">
    <xsl:param name="current-page-url"/>
    <xsl:variable name="edit-path">
      <xsl:apply-templates mode="edit-path" select="."/>
    </xsl:variable>
    <xsl:variable name="edit-link" select="concat($edit-path, '?~doc_path=', base-uri(.))"/>
    <tr>
      <xsl:if test="position() mod 2 eq 0">
        <xsl:attribute name="class">alt</xsl:attribute>
      </xsl:if>
      <th>
        <a href="{$edit-link}">
          <xsl:value-of select="title"/>
        </a>
      </th>
      <td>
        <xsl:value-of select="base-uri(.)"/>
      </td>
      <td>
        <xsl:value-of select="ml:display-date-with-time(created)"/>
      </td>

      <xsl:variable name="effective-status" select="if (@status) then @status else 'Published'"/>
      <td class="status {lower-case($effective-status)}">
        <xsl:value-of select="$effective-status"/>
      </td>
      <td>
        <a href="{$edit-link}" class="btn btn-default btn-sm">Edit</a>
        <!-- TODO: make preview work -->
        <a href="{$srv:draft-server}{substring-before(base-uri(.), '.xml')}" target="_blank" class="btn btn-default btn-sm">Preview</a>
        <!-- Only show the Publish/Unpublish toggle if the user logged in is the proper role -->
        <xsl:if test="authorize:is-admin()">
          <xsl:variable name="action" select="if (@status eq 'Published') then 'Unpublish' else 'Publish'"/>
          <a href="/admin/controller/publish-unpublish-doc.xqy?path={base-uri(.)}&amp;action={$action}&amp;redirect={$current-page-url}" class="btn btn-default btn-sm">
            <xsl:value-of select="$action"/>
          </a>
        </xsl:if>
      </td>
    </tr>
  </xsl:template>


  <xsl:template match="admin-media-list">
    <table class="media-list table table-bordered table-striped resource-list">
      <thead>
        <tr>
          <th scope="col">URL</th>
          <th scope="col">Actions</th>
        </tr>
      </thead>
      <tbody>
        <xsl:variable name="uris" select="ml:uris-by-type('media')"/>
        <xsl:apply-templates mode="admin-uri-listing" select="$uris">
          <xsl:sort select="."/>
          <xsl:with-param name="current-page-url" select="ml:external-uri(.)"/>
        </xsl:apply-templates>
      </tbody>
    </table>
  </xsl:template>

  <xsl:function name="ml:admin-doc-title" as="xs:string">
    <xsl:param name="e" as="element()"/>
    <xsl:sequence select="string(   if ($e/self::Project) then $e/name
                               else if ($e/self::page) then ( $e//*:h1
                                                            | $e//*:h2
                                                            | $e//*:h3
                                                            | $e//ml:product-info/@name
                                                            | ($e//ml:product-info/ml:name)[1]
                                                            )[1]
                               else $e/title
                                )"/>
  </xsl:function>

  <xsl:function name="ml:docs-by-type" as="element()*">
    <xsl:param name="doc-type"/>
    <xsl:sequence select="if ($doc-type eq 'Project')      then $ml:projects-by-name
                     else if ($doc-type eq 'Article')      then ml:lookup-articles('','','', false())
                     else if ($doc-type eq 'Post')         then $ml:posts-by-date[self::Post] (: only list blog posts here :)
                     else if ($doc-type eq 'Announcement') then $ml:announcements-by-date
                     else if ($doc-type eq 'Event')        then $ml:events-by-date
                     else if ($doc-type eq 'page')         then $ml:pages
                     else if ($doc-type eq 'author')       then $ml:authors-by-name
                     else if ($doc-type eq 'OnDemand')     then $ml:ondemand
                     else if ($doc-type eq 'recipe')       then $ml:Recipes
                     else ()"/>
  </xsl:function>

  <xsl:function name="ml:uris-by-type" as="element()*">
    <xsl:param name="doc-type"/>
    <xsl:sequence select="if ($doc-type eq 'media')      then $ml:media-uris
                     else ()"/>
  </xsl:function>

  <xsl:template mode="admin-uri-listing" match="*">
    <xsl:variable name="uri" select="."/>
    <tr>
      <td><xsl:value-of select="$uri"/></td>
      <td>
        <form action="/admin/controller/media-remove.xqy">
          <input type="hidden" name="uri" value="{$uri}"/>

          <button type="submit" title="Delete"><i class="glyphicon glyphicon-trash"></i></button>
        </form>
      </td>
    </tr>
  </xsl:template>

  <xsl:template mode="admin-listing" match="*">
    <xsl:param name="current-page-url"/>
    <xsl:variable name="edit-path">
      <xsl:apply-templates mode="edit-path" select="."/>
    </xsl:variable>
    <xsl:variable name="edit-link" select="concat($edit-path, '?~doc_path=', base-uri(.))"/>
    <tr>
      <xsl:if test="position() mod 2 eq 0">
        <xsl:attribute name="class">alt</xsl:attribute>
      </xsl:if>
      <th>
        <a href="{$edit-link}">
          <xsl:value-of select="ml:admin-doc-title(.)"/>
        </a>
      </th>
      <xsl:if test="not(self::page)">
        <xsl:if test="not(self::Event)">
          <td>
            <xsl:value-of select="if (self::Project) then contributors/contributor else author" separator=", "/>
          </td>
        </xsl:if>
        <xsl:if test="not(self::Project)">
          <td>
            <xsl:value-of select="ml:display-date-with-time(created)"/>
          </td>

          <td>
            <xsl:value-of select="if (created eq last-updated) then ()
                                                               else ml:display-date-with-time(last-updated)"/>
          </td>
        </xsl:if>
      </xsl:if>
      <xsl:variable name="effective-status" select="if (@status) then @status else 'Published'"/>
      <td>
        <xsl:value-of select="base-uri(.)"/>
      </td>
      <td class="status {lower-case($effective-status)}">
        <xsl:value-of select="$effective-status"/>
      </td>
      <td>
        <a href="{$edit-link}" class="btn btn-default btn-sm">Edit</a>
        <!-- TODO: make preview work -->
        <a href="{$srv:draft-server}{substring-before(base-uri(.), '.xml')}" target="_blank" class="btn btn-default btn-sm">Preview</a>
        <!-- Only show the Publish/Unpublish toggle if the user logged in is the proper role -->
        <xsl:if test="authorize:is-admin()">
          <xsl:variable name="action" select="if (@status eq 'Published') then 'Unpublish' else 'Publish'"/>
          <a href="/admin/controller/publish-unpublish-doc.xqy?path={base-uri(.)}&amp;action={$action}&amp;redirect={$current-page-url}" class="btn btn-default btn-sm">
            <xsl:value-of select="$action"/>
          </a>
        </xsl:if>

        <!-- TODO: make remove work -->
        <!-- Leave out "Remove" for v1.0
        <xsl:text>&#160;|&#160;</xsl:text>
        <a href="#">Remove</a>
        -->
      </td>
    </tr>
  </xsl:template>

  <xsl:template mode="edit-path" match="Project"     >/code/edit</xsl:template>
  <xsl:template mode="edit-path" match="Article"     >/learn/edit</xsl:template>
  <xsl:template mode="edit-path" match="Tutorial"    >/tutorial/edit</xsl:template>
  <xsl:template mode="edit-path" match="Post"        >/blog/edit</xsl:template>
  <xsl:template mode="edit-path" match="Announcement">/news/edit</xsl:template>
  <xsl:template mode="edit-path" match="Event"       >/events/edit</xsl:template>
  <xsl:template mode="edit-path" match="page"        >/pages/edit</xsl:template>
  <xsl:template mode="edit-path" match="Author"      >/author/edit</xsl:template>
  <xsl:template mode="edit-path" match="OnDemand"    >/ondemand/edit</xsl:template>
  <xsl:template mode="edit-path" match="Recipe"      >/recipe/edit</xsl:template>

</xsl:stylesheet>
