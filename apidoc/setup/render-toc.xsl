<!-- This stylesheet renders the pre-generated XML TOC
     into HTML to be cached by browsers.
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="xs">

  <!-- Optional version-specific prefix for link hrefs, e.g., "/4.2" -->
  <xsl:param name="prefix-for-hrefs"/>

  <xsl:template match="/">
    <div id="all_tocs">
      <script type="text/javascript" src="/apidoc/js/toc_filter.js"></script>
      <script type="text/javascript">
      <xsl:comment>
      $(function() {
        $("#apidoc_tree").treeview({
          //animated: "medium",
          persist: "location",
          prerendered: true
        });
      });
      $(function() {
        $("#apidoc_tree2").treeview({
          //animated: "medium",
          persist: "location",
          prerendered: true
        });
      });
      $(function() {
        $("#apidoc_tree3").treeview({
          //animated: "medium",
          persist: "location",
          prerendered: true
        });
      });

      // starting the script on page load
      $(document).ready(function(){
        tooltip();
      });

      $(function(){
          function scrollTOC() {
            var container = $('#sub'),
                scrollTo = $('#sub a.selected'),
                extra = 80,
                currentTop = container.scrollTop(),
                headerHeight = container.offset().top,
                scrollTargetDistance = scrollTo.offset().top,
                scrollTarget = currentTop + scrollTargetDistance,
                scrollTargetAdjusted = scrollTarget - headerHeight - extra,
                minimumSpaceAtBottom = 10,
                minimumSpaceAtTop = 10;

  <!--
  alert("currentTop: " + currentTop);
  alert("scrollTargetDistance: " + scrollTargetDistance);
  alert("scrollTarget: " + scrollTarget);
  alert("scrollTargetAdjusted: " + scrollTargetAdjusted);
  -->

            // Only scroll if necessary
            if (scrollTarget &lt; currentTop + headerHeight + minimumSpaceAtTop
             || scrollTarget >    currentTop + (container.height() - minimumSpaceAtBottom)) {
              container.animate({scrollTop: scrollTargetAdjusted}, 500);
            }
          }

          scrollTOC();

          $("a[href^='" + window.location.pathname + "#']").add("a[href^='#']").click(function() {
            $("#sub a.selected").removeClass("selected");
            var fullLink = this.pathname + this.hash;
            showInTOC($("#sub a[href='" + fullLink + "']"));
            scrollTOC($("#sub a.selected"));
          });
      });
      </xsl:comment>
      </script>

      <!--
      <div>API Reference</div>
      -->
      <input id="config-filter" name="config-filter"/>
      <ul id="apidoc_tree" class="treeview">
        <xsl:apply-templates select="/*/toc[1]/node"/>
      </ul>
      <input id="config-filter2" name="config-filter2"/>
      <ul id="apidoc_tree2" class="treeview">
        <xsl:apply-templates select="/*/toc[2]/node"/>
      </ul>
      <input id="config-filter3" name="config-filter3"/>
      <ul id="apidoc_tree3" class="treeview">
        <xsl:apply-templates select="/*/toc[3]/node"/>
      </ul>
    </div>
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
            </xsl:variable>
            <li class="{$class}">
              <xsl:apply-templates mode="hit-area" select="."/>
              <xsl:apply-templates mode="link"      select="."/>
              <xsl:apply-templates mode="control"   select="."/>
              <xsl:apply-templates mode="children"  select="."/>
            </li>
          </xsl:template>

                  <xsl:template mode="class" match="node[node]">expandable</xsl:template>
                  <xsl:template mode="class" match="node"/>

                  <xsl:template mode="class-last" priority="1" match="node[last()][node]">lastExpandable</xsl:template>
                  <xsl:template mode="class-last"              match="node[last()]      ">last</xsl:template>
                  <xsl:template mode="class-last"              match="node"/>

                  <xsl:template mode="hit-area" match="node"/>
                  <xsl:template mode="hit-area" match="node[node]">
                    <xsl:variable name="class">
                      <xsl:apply-templates mode="hit-area-class"      select="."/>
                      <xsl:text> </xsl:text>
                      <xsl:apply-templates mode="hit-area-class-last" select="."/>
                    </xsl:variable>
                    <div class="{$class}"/>
                  </xsl:template>

                          <xsl:template mode="hit-area-class" match="node">hitarea expandable-hitarea</xsl:template>

                          <xsl:template mode="hit-area-class-last" match="node[last()]">lastExpandable-hitarea</xsl:template>
                          <xsl:template mode="hit-area-class-last" match="node"/>

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
                    <xsl:if test="@footnote">
                      <a class="footnote_marker tooltip" title="Built-in functions (not written in XQuery)">*</a>
                    </xsl:if>
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
                  <!-- Expand/collapse buttons are enabled for all top-level menus, plus individual user guides -->
                  <xsl:template mode="control" match="toc/node | toc[2]/node/node">
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

                          <!-- Shallow for first and second top-level menus ("All functions" and "User guides") -->
                          <xsl:template mode="collapse-class" match="toc[1]/node | toc[2]/node">shallowCollapse</xsl:template>
                          <xsl:template mode="expand-class"   match="toc[1]/node | toc[2]/node">shallowExpand</xsl:template>
                          <xsl:template mode="all-suffix"                   match="toc[2]/node"/> <!-- User guide menu is the only one we don't say "all" with -->

                          <!-- Recursive (full) for everything else (individual user guides and "functions by category" -->
                          <xsl:template mode="collapse-class" match="node">collapse</xsl:template>
                          <xsl:template mode="expand-class"   match="node">expand</xsl:template>
                          <xsl:template mode="all-suffix"     match="node"> all</xsl:template>



                  <xsl:template mode="children" match="node"/>
                  <xsl:template mode="children" match="node[node]">
                    <ul style="display: none;">
                      <xsl:apply-templates select="node"/>
                    </ul>
                  </xsl:template>

</xsl:stylesheet>
