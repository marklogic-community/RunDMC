<!-- ASSUMPTIONS:
       * No mixed content (except with escaped markup to be edited as string, signified using @form:type="textarea")
       * Repeating siblings are contiguous. This is okay: <foo><HI/><bat><HI/><HI/></bat></foo>
                                            But this is not: <foo><HI/><bat/><HI/></foo>
     LIMITATIONS:
       * Can't edit comments or PIs
       * Only supports one level deep of repeating groups.
           E.g.: <group><field1/><field2/></group>
                 <group><field1/><field2/></group>
           In this case, field1 (and field2) may not contain elements or attributes.
           Nor can they repeat (because they're already in a repeating group).
-->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns:map ="http://marklogic.com/xdmp/map"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns:form             ="http://developer.marklogic.com/site/internal/form"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp map">

  <xsl:variable name="doc-path" select="$params[@name eq '~doc_path']"/>

  <xsl:variable name="orig-path" select="$params[@name eq '~orig_path']"/>

  <xsl:function name="form:form-template">
    <xsl:param name="template"/>
    <xsl:variable name="template-doc" select="xdmp:xslt-invoke('strip-comments.xsl', xdmp:document-get(concat(xdmp:modules-root(),
                                                                                                              '/admin/forms/',
                                                                                                              $template)))"/>
    <xsl:variable name="map" select="map:map()"/>
    <xsl:variable name="side-effect" select="map:put($map, 'template-doc', $template-doc)"/>
    <xsl:variable name="raw-form-spec" select="if (doc-available($doc-path)) then xdmp:xslt-invoke('annotate-doc.xsl', doc($doc-path), $map)
                                                                             else $template-doc"/>
    <xsl:variable name="pre-processed" select="xdmp:xslt-invoke('pre-process-form.xsl', $raw-form-spec)"/>
    <xsl:sequence select="xdmp:xslt-invoke('add-ids.xsl', $pre-processed)"/>
  </xsl:function>

  <xsl:template match="auto-form-scripts">
    <xsl:for-each select="$content//auto-form">
      <xsl:variable name="form-spec" select="form:form-template(@template)"/>
<!-- DEBUGGING
<xsl:copy-of select="$form-spec"/>
-->
      <xsl:apply-templates mode="form-script" select="$form-spec//*[@form:repeating eq 'yes'][not(node-name(.) eq node-name(preceding-sibling::*[1]))]"/>
    </xsl:for-each>
  </xsl:template>

          <xsl:template mode="form-script" match="*">
            <!-- TODO: Is there a way I can do this inline without embedding it in a comment? -->
            <xsl:variable name="name" select="form:field-name(.)"/>
            <xsl:variable name="label" select="@form:label | @form:group-label"/>

            <xsl:variable name="insert-command">
              <xsl:choose>
                <xsl:when test="@form:group-label">
                  <xsl:text>$(this).parent().siblings("fieldset.</xsl:text>
                  <xsl:value-of select="$name"/>
                  <xsl:text>").last().after('&lt;fieldset class="</xsl:text>
                  <xsl:value-of select="$name"/>
                  <xsl:text>"></xsl:text>
                  <xsl:for-each select="*">
                    <xsl:text>&lt;div>&lt;label></xsl:text>
                    <xsl:apply-templates mode="control-label" select="."/>
                    <xsl:text>&lt;/label>&lt;input name="</xsl:text>
                    <xsl:value-of select="form:field-name(.)"/>
                    <xsl:text>[' + clickCount + ']" type="text" />' + </xsl:text>
                    <xsl:if test="position() eq 1">
                      <xsl:text>remove_</xsl:text>
                      <xsl:value-of select="$name"/>
                      <xsl:text>_anchor + </xsl:text>
                    </xsl:if>
                    <xsl:text>'&lt;/div></xsl:text>
                  </xsl:for-each>
                  <xsl:text>&lt;/fieldset>');</xsl:text>
                </xsl:when>
                <xsl:otherwise>$(this).parent().before('&lt;div>&lt;input name="<xsl:value-of select="$name"/>[' + clickCount + ']" type="text" />' + remove_<xsl:value-of select="$name"/>_anchor + '&lt;/div>');</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>

            <xsl:variable name="remove-command">
              <xsl:choose>
                <xsl:when test="@form:group-label">$(this).closest("fieldset").remove();</xsl:when>
                <xsl:otherwise                    >$(this).parent().remove();</xsl:otherwise>
              </xsl:choose>
            </xsl:variable>

            <xsl:variable name="occurrence-test-name">
              <xsl:choose>
                <xsl:when test="@form:group-label">
                  <!-- Test for the presence of the first field in the group -->
                  <xsl:value-of select="form:field-name(*[1])"/>
                </xsl:when>
                <xsl:otherwise>
                  <xsl:value-of select="$name"/>
                </xsl:otherwise>
              </xsl:choose>
            </xsl:variable>

            <xsl:variable name="remove-script">
              $('a.remove_<xsl:value-of select="$name"/>').click(function() {
                <xsl:value-of select="$remove-command"/>
                if($('input[name^="<xsl:value-of select="$occurrence-test-name"/>\["]').length == 1) {
                  $('a.remove_<xsl:value-of select="$name"/>').remove();
                }
              });
            </xsl:variable>

            <!-- Variable is necessary as workaround for bug with <xsl:comment> instruction -->
            <xsl:variable name="comment-content">
              if(typeof jQuery != 'undefined') {
                $(function() {
                  <!-- to keep track of the order of added elements -->
                  var clickCount = <xsl:value-of select="count(../*[node-name(.) eq node-name(current())])"/>;

                  $('input[name=add_<xsl:value-of select="$name"/>]').replaceWith('&lt;a class="add_remove add_<xsl:value-of select="$name"/>">+&#160;Add <xsl:value-of select="$label"/>&lt;/a>');
                  var remove_<xsl:value-of select="$name"/>_anchor = '&lt;a class="add_remove remove_<xsl:value-of select="$name"/>">-&#160;Remove <xsl:value-of select="$label"/>&lt;/a>';
                  $('a.add_<xsl:value-of select="$name"/>').click(function() {
                    clickCount++;
                    <xsl:value-of select="$insert-command"/>
                    if($('input[name^="<xsl:value-of select="$occurrence-test-name"/>\["]').length == 2) {
                      $('input[name^="<xsl:value-of select="$occurrence-test-name"/>\["]:first').after(remove_<xsl:value-of select="$name"/>_anchor);
                    }
                    <xsl:value-of select="$remove-script"/>
                  });
                  <!-- Duplicated here because otherwise pre-existing Remove buttons (because a document already has two authors, for example) don't work -->
                  <xsl:value-of select="$remove-script"/>
                });
              }
            </xsl:variable>
            //<xsl:comment>
                <xsl:text>&#xA;</xsl:text>
                <xsl:value-of select="$comment-content"/>
                <xsl:text>&#xA;</xsl:text>
            //</xsl:comment>
          </xsl:template>


  <xsl:template match="auto-form">
    <xsl:apply-templates mode="generate-form" select="form:form-template(@template)"/>
  </xsl:template>

          <xsl:template mode="generate-form" match="*">
            <form class="adminform" method="post" enctype="application/x-www-form-urlencoded">
              <input type="hidden" name="~edit_form_url" value="{$orig-path}"/>

              <xsl:if test="$params[@name eq '~updated']">
                <div id="codeedit">
                <dl>
                  <dt>LAST SAVED</dt>
                  <xsl:text> </xsl:text>
                  <dd>
                    <xsl:value-of select="substring-before($params[@name eq '~updated'], '.')"/>
                  </dd>
                </dl>
                </div>
              </xsl:if>

              <!--
              <div class="error">
                <strong>OOOPS:</strong> Please enter Project Type.<br />
                Please enter at least one download link.
              </div>
              -->


              <xsl:choose>
                <xsl:when test="@form:uri-prefix-for-timestamped-named-docs">
                  <input type="hidden" name="~timestamped-file-name" value="yes"/>
                </xsl:when>
                <xsl:otherwise>
                  <div>
                    <label for="slug">URI path</label>
                    <strong>
                      <xsl:choose>
                        <xsl:when test="string($doc-path)">
                          <xsl:variable name="external-uri" select="substring-before($doc-path, '.xml')"/>
                          <xsl:value-of select="$external-uri"/>
                          <xsl:text> </xsl:text>
                          <a href="{$staging-server}{$external-uri}" target="_blank">
                            <span>(view current)</span>
                          </a>
                          <xsl:text> </xsl:text>
                          <a href="{$webdav-server}{$external-uri}.xml" target="_blank">
                            <span>(view XML source)</span>
                          </a>
                          <input type="hidden" name="~existing_doc_uri" value="{$doc-path}"/>
                        </xsl:when>
                        <xsl:otherwise>
                          <xsl:value-of select="/*/@form:uri-prefix-for-new-docs"/>
                          <input type="hidden" name="~uri_prefix" value="{/*/@form:uri-prefix-for-new-docs}"/>
                          <input name="~new_doc_slug" value="{$params[@name eq '~new_doc_slug']}"/> <!-- empty at first -->
                        </xsl:otherwise>
                      </xsl:choose>
                    </strong>
                  </div>
                </xsl:otherwise>
              </xsl:choose>
              <input type="hidden" name="~xml_to_edit" value="{xdmp:quote(.)}"/>
              <xsl:apply-templates mode="labeled-controls" select="."/>
              <xsl:choose>
                <xsl:when test="string($doc-path)">
                  <input type="submit" name="submit" value="Save changes"  onclick="this.form.action = '/admin/replace.xqy'; this.form.target = '_self';"/>
                </xsl:when>
                <xsl:otherwise>
                  <input type="submit" name="submit" value="Submit document" onclick="this.form.action = '/admin/create.xqy'; this.form.target = '_self';"/>
                </xsl:otherwise>
              </xsl:choose>
              <input type="submit" name="submit" value="Preview changes" onclick="this.form.action = '/admin/preview.xqy'; this.form.target = '_blank';"/>
            </form>
          </xsl:template>

                  <xsl:template mode="labeled-controls" match="*">
                    <xsl:apply-templates mode="#current" select="*"/>
                  </xsl:template>

                  <xsl:template mode="labeled-controls" match="*[@form:label][not(@form:subsequent-item)]">
                    <!-- Process attribute-cum-element fields -->
                    <xsl:apply-templates mode="labeled-controls" select="*"/>

                    <div>
                      <label for="{form:field-name(.)}_{generate-id()}">
                        <xsl:apply-templates mode="control-label" select="."/>
                      </label>
                      <xsl:apply-templates mode="form-control" select="."/>
                      <xsl:if test="@form:repeating eq 'yes'">
                        <!-- Process the repeating controls -->
                        <xsl:apply-templates mode="form-control" select="following-sibling::*[node-name(.) eq node-name(current())]"/>
                      </xsl:if>
                      <xsl:apply-templates mode="add-more-button" select="."/>
                    </div>
                  </xsl:template>

                  <xsl:template mode="labeled-controls" match="*[@form:group-label]">
                    <fieldset class="{form:field-name(.)}">
                      <xsl:apply-templates mode="#current" select="*"/>
                    </fieldset>
                    <xsl:if test="form:is-last-group-in-repeating-group(.)">
                      <xsl:apply-templates mode="add-more-button" select="."/>
                    </xsl:if>
                  </xsl:template>

                          <xsl:function name="form:is-last-group-in-repeating-group" as="xs:boolean">
                            <xsl:param name="e" as="element()"/>
                            <xsl:sequence select="($e/@form:repeating eq 'yes') and not(node-name($e) eq node-name($e/following-sibling::*[1]))"/>
                          </xsl:function>

                                  <xsl:template mode="add-more-button" match="*"/>
                                  <xsl:template mode="add-more-button" match="*[@form:repeating eq 'yes']">
                                    <div>
                                      <input class="add_remove" type="submit" name="add_{form:field-name(.)}" value="+ Add {@form:label | @form:group-label}"/>
                                    </div>
                                  </xsl:template>


                                  <xsl:template mode="remove-button" match="*"/>
                                  <xsl:template mode="remove-button" match="*[@form:repeating eq 'yes']">
                                    <a class="add_remove remove_{form:field-name(.)}">
                                      <xsl:text>-&#160;Remove </xsl:text>
                                      <xsl:value-of select="@form:label | @form:group-label"/>
                                    </a>
                                  </xsl:template>


                                  <xsl:template mode="control-label" match="*">
                                    <xsl:value-of select="@form:label"/>
                                  </xsl:template>


                                  <xsl:template mode="form-control" match="*[exists(form:enumerated-values(.))]">
                                    <!-- Don't include attribute-cum-element fields in value -->
                                    <xsl:variable name="given-value" select="normalize-space(string-join(text(),''))"/>
                                    <xsl:variable name="field-name">
                                      <xsl:value-of select="form:field-name(.)"/>
                                      <xsl:apply-templates mode="field-name-suffix" select="."/>
                                    </xsl:variable>
                                    <select name="{$field-name}">
                                      <xsl:for-each select="form:enumerated-values(.)">
                                        <option value="{.}">
                                          <xsl:if test=". eq $given-value">
                                            <xsl:attribute name="selected">selected</xsl:attribute>
                                          </xsl:if>
                                          <xsl:value-of select="."/>
                                        </option>
                                      </xsl:for-each>
                                      <!-- If the given value is not found among the enumerated ones, don't clobber it; add it -->
                                      <xsl:if test="$given-value and not($given-value = form:enumerated-values(.))">
                                        <option value="{$given-value}" selected="selected">
                                          <xsl:value-of select="$given-value"/>
                                        </option>
                                      </xsl:if>
                                    </select>
                                  </xsl:template>

                                          <xsl:function name="form:enumerated-values" as="xs:string*">
                                            <xsl:param name="element"/>
                                            <xsl:sequence select="if ($element/@form:values)
                                                                  then for $v in tokenize($element/@form:values,' ') return normalize-space(translate($v, '_', ' '))
                                                                  else ()"/>
                                          </xsl:function>


                                  <xsl:template mode="form-control" match="*">
                                    <xsl:variable name="field-name">
                                      <xsl:value-of select="form:field-name(.)"/>
                                      <xsl:apply-templates mode="field-name-suffix" select="."/>
                                    </xsl:variable>
                                    <div>
                                      <input id ="{form:field-name(.)}_{generate-id()}"
                                             name="{$field-name}"
                                             type="text"
                                             value="{string-join(text(),'')}"> <!-- don't include attribute-cum-element fields in value -->
                                        <xsl:apply-templates mode="class-att" select="."/>
                                      </input>
                                      <!-- TODO: allow removal for other types of controls, not just text fields -->
                                      <!-- Only insert one Remove button per group -->
                                      <xsl:if test="(not(../@form:group-label) and count(../*[node-name(.) eq node-name(current())]) gt 1)
                                                  or    (../@form:group-label and not(preceding-sibling::*) and count(../../*[node-name(.) eq node-name(current()/..)]) gt 1)">
                                        <xsl:apply-templates mode="remove-button" select="ancestor-or-self::*"/>
                                      </xsl:if>
                                    </div>
                                  </xsl:template>

                                          <xsl:template mode="field-name-suffix" match="*"/>

                                          <xsl:template mode="field-name-suffix" match="*[(.|..)/@form:repeating eq 'yes']">
                                            <xsl:variable name="repeating-element" select="if (@form:repeating eq 'yes') then .
                                                                                                                         else .."/>
                                            <xsl:text>[</xsl:text>
                                            <xsl:number select="$repeating-element"/> <!-- position relative to its like-named siblings -->
                                            <xsl:text>]</xsl:text>
                                          </xsl:template>

                                          <xsl:template mode="class-att" match="*"/>
                                          <xsl:template mode="class-att" match="*[@form:wide eq 'yes']">
                                            <xsl:attribute name="class">wideText</xsl:attribute>
                                          </xsl:template>


                                  <xsl:template mode="form-control" match="*[@form:type eq 'textarea']">
                                      <!-- Leave this button out until I can implement it
                                      TODO: Implement media upload
                                      <input type="submit" name="add_media" value="Add media"/>
                                      <br/>
                                      -->
                                      <textarea id ="{form:field-name(.)}_{generate-id()}"
                                                name="{form:field-name(.)}"
                                                cols="30"
                                                rows="{if (@form:lines) then @form:lines else 11}">
                                        <xsl:apply-templates mode="class-att" select="."/>
                                        <xsl:value-of select="string-join(text(),'')"/> <!-- don't include attribute-cum-element fields in value -->
                                      </textarea>
                                  </xsl:template>


  <xsl:function name="form:field-name">
    <xsl:param name="node"/>
    <xsl:sequence select="if ($node/@form:group-label) then translate(local-name($node), '-', '_') else $node/@form:name"/>
  </xsl:function>

</xsl:stylesheet>
