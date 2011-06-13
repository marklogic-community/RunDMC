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
    <div>
      <script type="text/javascript">
      $(function() {
        $("#apidoc_tree").treeview({
          collapsed: true,
  /*        animated: "medium",*/
          control:"#treecontrol1",
          persist: "location"
        });
      })
      $(function() {
        $("#apidoc_tree2").treeview({
          collapsed: true,
  /*        animated: "medium",*/
          control:"#treecontrol2",
          persist: "location"
        });
      })
      $(function() {
        $("#apidoc_tree3").treeview({
          collapsed: true,
  /*        animated: "medium",*/
          control:"#treecontrol3",
          persist: "location"
        });
      })

      // starting the script on page load
      $(document).ready(function(){
        tooltip();
      });
      </script>
      <script type="text/javascript" src="/js/apidoc/toc_filter.js"></script>

      <!--
      <div>API Reference</div>
      -->
      <input id="config-filter" name="config-filter"/>
      <ul id="apidoc_tree">
        <xsl:apply-templates select="/toc/node[1]"/>
      </ul>
      <input id="config-filter2" name="config-filter2"/>
      <ul id="apidoc_tree2">
        <xsl:apply-templates select="/toc/node[2]"/>
      </ul>
      <input id="config-filter3" name="config-filter3"/>
      <ul id="apidoc_tree3">
        <xsl:apply-templates select="/toc/node[3]"/>
      </ul>
      <!--
      <div id="toc_footnote">
        <span class="footnote_marker">*</span>
        <xsl:text> </xsl:text>
        <span class="footnote">Built-in functions (not written in XQuery)</span>
      </div>
      -->
    </div>
  </xsl:template>

          <!-- We hide the "all" container so it doesn't appear in the TOC -->
          <xsl:template match="node[@hidden eq 'yes']">
            <xsl:apply-templates select="node"/>
          </xsl:template>

          <xsl:template match="node">
            <li>
              <xsl:apply-templates mode="class-att" select="."/>
              <xsl:apply-templates mode="link"      select="."/>
              <xsl:apply-templates mode="control"   select="."/>
              <xsl:apply-templates mode="children"  select="."/>
            </li>
          </xsl:template>

                  <xsl:template mode="class-att" match="node"/>
                  <!--
                  <xsl:template mode="class-att" match="node[@initially-expanded]">
                    <xsl:attribute name="class" select="'open'"/>
                  </xsl:template>
                  -->
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
                    <a href="{$prefix-for-hrefs}{@href}">
                      <xsl:apply-templates mode="title-att" select="."/>
                      <xsl:value-of select="@display"/>
                    </a>
                    <xsl:if test="@footnote">
                      <a class="footnote_marker tooltip" title="Built-in functions (not written in XQuery)">*</a>
                    </xsl:if>
                  </xsl:template>

                          <xsl:template mode="title-att" match="node"/>
                          <xsl:template mode="title-att" match="node[@namespace]">
                            <xsl:attribute name="title" select="@namespace"/>
                          </xsl:template>

                  <xsl:template mode="control" match="node"/>
                  <!-- Expand/collapse buttons are enabled for all top-level menus, plus individual user guides -->
                  <xsl:template mode="control" match="toc/node | toc/node[2]/node">
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
                      <span title="Collapse the entire tree below" href="#" class="{$collapse-class}"><img src="/css/apidoc/images/minus.gif" /> collapse<xsl:value-of select="$all-suffix"/></span>
                      <xsl:text>&#160;</xsl:text>
                      <span title="Expand the entire tree below" href="#" class="{$expand-class}"><img src="/css/apidoc/images/plus.gif" /> expand<xsl:value-of select="$all-suffix"/></span>
                    </div>
                  </xsl:template>

                          <!-- Shallow for first and second top-level menus ("All functions" and "User guides") -->
                          <xsl:template mode="collapse-class" match="toc/node[1] | toc/node[2]">shallowCollapse</xsl:template>
                          <xsl:template mode="expand-class"   match="toc/node[1] | toc/node[2]">shallowExpand</xsl:template>
                          <xsl:template mode="all-suffix"                   match="toc/node[2]"/> <!-- User guide menu is the only one we don't say "all" with -->

                          <!-- Recursive (full) for everything else (individual user guides and "functions by category" -->
                          <xsl:template mode="collapse-class" match="node">collapse</xsl:template>
                          <xsl:template mode="expand-class"   match="node">expand</xsl:template>
                          <xsl:template mode="all-suffix"     match="node"> all</xsl:template>



                  <xsl:template mode="children" match="node"/>
                  <xsl:template mode="children" match="node[node]">
                    <ul>
                      <xsl:apply-templates select="node"/>
                    </ul>
                  </xsl:template>

</xsl:stylesheet>
