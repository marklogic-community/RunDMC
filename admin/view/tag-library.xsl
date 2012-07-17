<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:srv="http://marklogic.com/rundmc/server-urls"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp srv"
  extension-element-prefixes="xdmp">

  <!-- Import the definition of $srv:draft-server and $srv:webdav-server -->
  <xdmp:import-module href="/controller/server-urls.xqy" namespace="http://marklogic.com/rundmc/server-urls"/>

  <xsl:template match="admin-page-listings">
    <table id="tbl_status">
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
          <Code          doc-type="Project"      path="/code"/>
          <Blog          doc-type="Post"         path="/blog"/>
          <Learn         doc-type="Article"      path="/learn"/>
          <News          doc-type="Announcement" path="/news"/>
          <Events        doc-type="Event"        path="/events"/>
          <Pages         doc-type="page"         path="/pages"/>
        </xsl:variable>
        <xsl:apply-templates mode="admin-page-listing" select="$sections/*"/>
      </tbody>
    </table>
  </xsl:template>

          <xsl:template mode="admin-page-listing" match="*">
            <xsl:variable name="docs" select="ml:docs-by-type(@doc-type)"/>
            <tr>
              <th scope="row">
                <a href="{@path}">
                  <xsl:value-of select="translate(local-name(.),'_',' ')"/>
                </a>
              </th>
              <td>
                <xsl:value-of select="count($docs[@status eq 'Published'])"/>
              </td>
              <td class="status pending">
                <xsl:value-of select="count($docs[@status eq 'Draft'])"/>
              </td>
              <td>
                <a href="{@path}">List</a>
                <xsl:text> | </xsl:text>
                <a href="{concat(@path,'/edit')}">Add new</a>
              </td>
            </tr>
          </xsl:template>

  <xsl:template match="admin-project-list
                     | admin-learn-list
                     | admin-post-list
                     | admin-announcement-list
                     | admin-event-list
                     | admin-page-list">
    <table>
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
          <xsl:with-param name="edit-path">
            <xsl:apply-templates mode="edit-path" select="."/>
          </xsl:with-param>
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
                                                                    | $e//product-info/@name
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
                             else ()"/>
          </xsl:function>



          <xsl:template mode="edit-path" match="admin-project-list"     >/code/edit</xsl:template>
          <xsl:template mode="edit-path" match="admin-learn-list"       >/learn/edit</xsl:template>
          <xsl:template mode="edit-path" match="admin-post-list"        >/blog/edit</xsl:template>
          <xsl:template mode="edit-path" match="admin-announcement-list">/news/edit</xsl:template>
          <xsl:template mode="edit-path" match="admin-event-list"       >/events/edit</xsl:template>
          <xsl:template mode="edit-path" match="admin-page-list"        >/pages/edit</xsl:template>


          <xsl:template mode="admin-listing" match="*">
            <xsl:param name="edit-path"/>
            <xsl:param name="current-page-url"/>
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
              <td class="status {lower-case($effective-status)}">
                <xsl:value-of select="$effective-status"/>
              </td>
              <td>
                <a href="{$edit-link}">Edit</a>
                <xsl:text>&#160;|&#160;</xsl:text>
                <!-- TODO: make preview work -->
                <a href="{$srv:draft-server}{substring-before(base-uri(.), '.xml')}" target="_blank">Preview</a>
                <xsl:text>&#160;|&#160;</xsl:text>

                <xsl:variable name="action" select="if (@status eq 'Published') then 'Unpublish' else 'Publish'"/>
                <a href="/admin/controller/publish-unpublish-doc.xqy?path={base-uri(.)}&amp;action={$action}&amp;redirect={$current-page-url}">
                  <xsl:value-of select="$action"/>
                </a>

                <!-- TODO: make remove work -->
                <!-- Leave out "Remove" for v1.0
                <xsl:text>&#160;|&#160;</xsl:text>
                <a href="#">Remove</a>
                -->
              </td>
            </tr>
          </xsl:template>

</xsl:stylesheet>
