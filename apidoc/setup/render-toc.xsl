<!-- This stylesheet renders the pre-generated XML TOC
     into HTML to be cached by browsers.
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="xs">

  <xsl:param name="toc-url"/>

  <!-- Optional version-specific prefix for link hrefs, e.g., "/4.2" -->
  <xsl:param name="prefix-for-hrefs"/>

  <!-- for deciding which tabs to display -->
  <xsl:param name="version"/>

  <xsl:template match="/">
    <xsl:result-document href="{$toc-url}">
      <div id="all_tocs">
        <script type="text/javascript">
        <xsl:comment>

        $(function() {
          $("#apidoc_tree").treeview({
            //animated: "medium",
            url: "/media/apiTOC/",
//            persist: "location",
            prerendered: true
          });
          $("#apidoc_tree2").treeview({
            //animated: "medium",
            url: "/media/apiTOC/",
//            persist: "location",
            prerendered: true
          });
          $("#apidoc_tree3").treeview({
            //animated: "medium",
            url: "/media/apiTOC/",
//            persist: "location",
            prerendered: true
          });


          $("#config-filter").keyup(function(e) {
              currentFilterText = $(this).val();
              setTimeout(function() {
                  if (previousFilterText !== currentFilterText){
                      previousFilterText = currentFilterText;
                      filterConfigDetails(currentFilterText,"#apidoc_tree");
                  }            
              },350);        
          });

          $("#config-filter2").keyup(function(e) {
              currentFilterText2 = $(this).val();
              setTimeout(function() {
                  if (previousFilterText2 !== currentFilterText2){
                      previousFilterText2 = currentFilterText2;
                      filterConfigDetails(currentFilterText2,"#apidoc_tree2");
                  }            
              },350);        
          });
          
          $("#config-filter3").keyup(function(e) {
              currentFilterText3 = $(this).val();
              setTimeout(function() {
                  if (previousFilterText3 !== currentFilterText3){
                      previousFilterText3 = currentFilterText3;
                      filterConfigDetails(currentFilterText3,"#apidoc_tree3");
                  }            
              },350);        
          });

        });

        // starting the script on page load
        $(document).ready(function(){
          
          // Wire up the expand/collapse buttons
          $(".shallowExpand").click(function(event){
            shallowExpandAll($(this).parent().nextAll("ul"));
          });
          $(".shallowCollapse").click(function(event){
            shallowCollapseAll($(this).parent().nextAll("ul"));
          });
          $(".expand").click(function(event){
            expandAll($(this).parent().nextAll("ul"));
          });
          $(".collapse").click(function(event){
            collapseAll($(this).parent().nextAll("ul"));
          });


          // Set up the TOC tabs
          $("#toc_tabs").tabs({
            show: function(event, ui){ updateTocOnTabChange(ui) }
          });

          bindFragmentLinkTocActions(document.body);
          initializeTOC();

          var searchSidebarContent = $("#search_sidebar").children();

          // Only replace the default form if search sidebar content is present (because we're on the search page)
          if (searchSidebarContent.length)
            $("#search_pane_content form").replaceWith(searchSidebarContent);

          var last_tab_pos = $("#toc_tabs").tabs("length") - 1;

          if (window.location.pathname === "/srch")
            $("#toc_tabs").tabs("option", "selected", last_tab_pos);

          // Once the tabs are set up, go ahead and display the TOC
          $("#toc_tabs").show();

          tooltip();

        });
        </xsl:comment>
        </script>

        <!--
        <div>API Reference</div>
        -->
        <div id="toc_tabs" style="display:none">
          <div id="tab_bar">
            <ul>
              <li><a href="#tabs-1" class="tab_link">Functions<br/>by Name</a></li>
              <li><a href="#tabs-2" class="tab_link">Functions<br/>by Category</a></li>
              <li><a href="#tabs-3" class="tab_link">User<br/>Guides</a></li>
              <xsl:if test="number($version) ge 5">
                <li><a href="#tabs-4" class="tab_link">Error<br/>Codes</a></li>
              </xsl:if>
              <li><a href="#tabs-5" class="tab_link">Search<br/>the Site</a></li>
            </ul>
          </div>
          <div id="tab_content">
            <div id="tabs-1" class="tabbed_section pjax_enabled"> <!-- Only the function TOCs are pjax-enabled -->
              <div class="scrollable_section">
                <input id="config-filter" name="config-filter"/>
                <ul id="apidoc_tree" class="treeview">
                  <xsl:apply-templates select="/*/toc[1]/node"/>
                </ul>
              </div>
            </div>
            <div id="tabs-2" class="tabbed_section pjax_enabled">
              <div class="scrollable_section">
                <input id="config-filter2" name="config-filter2"/>
                <ul id="apidoc_tree2" class="treeview">
                  <xsl:apply-templates select="/*/toc[2]/node"/>
                </ul>
              </div>
            </div>
            <div id="tabs-3" class="tabbed_section">
              <div class="scrollable_section">
                <input id="config-filter3" name="config-filter3"/>
                <ul id="apidoc_tree3" class="treeview">
                  <xsl:apply-templates select="/*/toc[3]/node"/>
                </ul>
              </div>
            </div>

            <xsl:if test="number($version) ge 5">
              <div id="tabs-4" class="tabbed_section">
                <div class="scrollable_section">
                  <input id="config-filter4" name="config-filter4"/>
                  <ul id="apidoc_tree4" class="treeview">
                    <xsl:apply-templates select="/*/toc[4]/node"/>
                  </ul>
                </div>
              </div>
            </xsl:if>

            <div id="tabs-5" class="tabbed_section">
              <div id="search_pane_content">
                <form action="/srch" method="get">
                  <input id="q" name="q"/>
                </form>
              </div>
            </div>
          </div>
        </div>
      </div>
    </xsl:result-document>
  </xsl:template>

          <!-- We hide the "all" container so it doesn't appear in the TOC -->
          <xsl:template match="node[@hidden eq 'yes']">
            <xsl:apply-templates select="node"/>
          </xsl:template>

          <xsl:template match="node">
            <xsl:variable name="class">
              <xsl:apply-templates mode="class" select="."/>
              <xsl:text> </xsl:text>
              <xsl:apply-templates mode="class-last" select="."/>
              <xsl:text> </xsl:text>
              <xsl:apply-templates mode="class-hasChildren" select="."/>
              <xsl:text> </xsl:text>
              <xsl:apply-templates mode="class-initialized" select="."/>
            </xsl:variable>
            <li class="{$class}">
              <xsl:apply-templates mode="id-att"   select="."/>
              <xsl:apply-templates mode="hit-area" select="."/>
              <xsl:apply-templates mode="link"     select="."/>
              <xsl:apply-templates mode="control"  select="."/>
              <xsl:apply-templates mode="children" select="."/>
            </li>
          </xsl:template>

                  <xsl:template mode="id-att" match="node"/>
                  <!-- Include an ID on nodes that have one already -->
                  <xsl:template mode="id-att" match="node[@id]">
                    <xsl:attribute name="id">
                      <xsl:apply-templates mode="node-id" select="."/>
                    </xsl:attribute>
                  </xsl:template>

                          <!-- Each main TOC section ID is qualified by the version prefix -->
                          <xsl:template mode="node-id" match="node">
                            <xsl:value-of select="translate($prefix-for-hrefs,'/.','v-')"/> <!-- might be empty -->
                            <xsl:text>_</xsl:text>
                            <xsl:value-of select="@id"/>
                          </xsl:template>


                  <xsl:template mode="class" priority="1" match="toc/node"  >collapsable</xsl:template>
                  <xsl:template mode="class"              match="node[node]">expandable</xsl:template>
                  <xsl:template mode="class"              match="node"/>


                  <xsl:template mode="class-last" priority="2" match="toc/node[last()][node]">lastCollapsable</xsl:template>
                  <xsl:template mode="class-last" priority="1" match="    node[last()][node]">lastExpandable</xsl:template>
                  <xsl:template mode="class-last"              match="    node[last()]      ">last</xsl:template>
                  <xsl:template mode="class-last"              match="node"/>

                  <!-- Include on nodes that will be loaded asynchronously -->
                  <xsl:template mode="class-hasChildren" match="toc/node/node">hasChildren</xsl:template>
                  <xsl:template mode="class-hasChildren" match="node"/>

                  <!-- Include on the top-level nodes that will *not* be loaded asynchronously; that is, they are already loaded -->
                  <xsl:template mode="class-initialized" match="toc/node">loaded initialized</xsl:template>
                  <xsl:template mode="class-initialized" match="node"/>


                  <xsl:template mode="hit-area" match="node"/>
                  <xsl:template mode="hit-area" match="node[node]">
                    <xsl:variable name="class">
                      <xsl:apply-templates mode="hit-area-class"      select="."/>
                      <xsl:text> </xsl:text>
                      <xsl:apply-templates mode="hit-area-class-last" select="."/>
                    </xsl:variable>
                    <div class="{$class}"/>
                  </xsl:template>

                          <xsl:template mode="hit-area-class" match="toc/node">hitarea collapsable-hitarea</xsl:template>
                          <xsl:template mode="hit-area-class" match="    node">hitarea expandable-hitarea</xsl:template>

                          <xsl:template mode="hit-area-class-last" priority="1" match="toc/node[last()]">lastCollapsable-hitarea</xsl:template>
                          <xsl:template mode="hit-area-class-last"              match="    node[last()]">lastExpandable-hitarea</xsl:template>
                          <xsl:template mode="hit-area-class-last"              match="    node"/>

                  <!-- re-enable should we need this
                  <xsl:template mode="class-att" match="node[@type eq 'function']">
                    <xsl:attribute name="class" select="'function_name'"/>
                  </xsl:template>
                  -->

                  <xsl:template mode="link" match="node">
                    <span>
                      <xsl:value-of select="@display"/>
                    </span>
                  </xsl:template>

                  <xsl:template mode="link" match="node[@href]">
                    <xsl:variable name="href">
                      <xsl:value-of select="$prefix-for-hrefs"/>
                      <xsl:apply-templates mode="link-href" select="."/>
                    </xsl:variable>
                    <a href="{$href}">
                      <xsl:apply-templates mode="title-att" select="."/>
                      <xsl:value-of select="@display"/>
                    </a>
                    <!-- Not really helpful
                    <xsl:if test="@footnote">
                      <a class="footnote_marker tooltip" title="Built-in functions (not written in XQuery)">*</a>
                    </xsl:if>
                    -->
                  </xsl:template>

                          <!-- For most cases, just append the @href value after the optional version prefix -->
                          <xsl:template mode="link-href" match="node">
                            <xsl:value-of select="@href"/>
                          </xsl:template>

                          <!-- But when the @href value is just "/", leave it out when the version is specified explicitly (e.g., /4.2 instead of /4.2/) -->
                          <xsl:template mode="link-href" match="node[string($prefix-for-hrefs)][@href eq '/']"/>


                          <xsl:template mode="title-att" match="node"/>
                          <xsl:template mode="title-att" match="node[@namespace]">
                            <xsl:attribute name="title" select="@namespace"/>
                          </xsl:template>

                  <xsl:template mode="control" match="node"/>
                  <!-- Expand/collapse buttons are enabled for all top-level and second-level menus if they have grandchildren -->
                  <xsl:template mode="control" match="toc/node | toc/node/node[node/node]">
                    <xsl:variable name="position">
                      <xsl:number count="toc/node"/>
                    </xsl:variable>
                    <xsl:variable name="collapse-class">
                      <xsl:apply-templates mode="collapse-class" select="."/>
                    </xsl:variable>
                    <xsl:variable name="expand-class">
                      <xsl:apply-templates mode="expand-class" select="."/>
                    </xsl:variable>
                    <xsl:variable name="all-suffix">
                      <xsl:apply-templates mode="all-suffix" select="."/>
                    </xsl:variable>
                    <div style="font-size:.8em" class="treecontrol"><!--id="treecontrol{$position}" -->
                      <xsl:text>&#160;</xsl:text>
                      <span title="Collapse the entire tree below" class="{$collapse-class}"><img src="/css/apidoc/images/minus.gif" /> collapse<xsl:value-of select="$all-suffix"/></span>
                      <xsl:text>&#160;</xsl:text>
                      <span title="Expand the entire tree below" class="{$expand-class}"><img src="/css/apidoc/images/plus.gif" /> expand<xsl:value-of select="$all-suffix"/></span>
                    </div>
                  </xsl:template>

                          <!-- Shallow for top-level menus -->
                          <xsl:template mode="collapse-class" match="toc/node">shallowCollapse</xsl:template>
                          <xsl:template mode="expand-class"   match="toc/node">shallowExpand</xsl:template>
                          <xsl:template mode="all-suffix"     match="toc/node"/> <!-- User guide menu is the only one we don't say "all" with -->

                          <!-- Recursive (full) for everything else -->
                          <xsl:template mode="collapse-class" match="node">collapse</xsl:template>
                          <xsl:template mode="expand-class"   match="node">expand</xsl:template>
                          <xsl:template mode="all-suffix"     match="node"> all</xsl:template>



                  <xsl:template mode="children" match="node"/>
                  <xsl:template mode="children" match="node[node]">
                    <xsl:variable name="display-type">
                      <xsl:apply-templates mode="ul-display-type" select="."/>
                    </xsl:variable>
                    <ul style="display: {$display-type};">
                      <xsl:apply-templates select="node"/>
                    </ul>
                  </xsl:template>

                  <!-- Nodes to be loaded asynchronously -->
                  <xsl:template mode="children" match="toc/node/node" priority="1">
                    <!-- The empty placeholder -->
                    <ul style="display: none">
                      <li>
                        <span class="placeholder">&#160;</span>
                      </li>
                    </ul>
                    <xsl:variable name="node-id">
                      <xsl:apply-templates mode="node-id" select="."/>
                    </xsl:variable>
                    <!-- The content of the TOC node, stored in a separate document -->
                    <xsl:result-document href="/media/apiTOC/{$node-id}.html">
                      <xsl:next-match/>
                    </xsl:result-document>
                  </xsl:template>

                          <xsl:template mode="ul-display-type" match="toc/node | toc/node/node">block</xsl:template>
                          <xsl:template mode="ul-display-type" match="                    node">none</xsl:template>

</xsl:stylesheet>
