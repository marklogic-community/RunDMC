<!-- This is half-baked and experimental, but it also gets the job done.
     The idea has a lot of potential... -->
<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns:form             ="http://developer.marklogic.com/site/internal/form"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp">

  <xsl:function name="form:form-template">
    <xsl:param name="template"/>
    <xsl:variable name="raw-form-spec" select="xdmp:document-get(concat(xdmp:modules-root(),
                                                                        '/admin/forms/',
                                                                        $template))"/>
    <xsl:sequence select="xdmp:xslt-invoke('/admin/pre-process-form.xsl', $raw-form-spec)"/>
  </xsl:function>

  <xsl:template match="auto-form-scripts">
    <xsl:for-each select="$content//auto-form">
      <xsl:variable name="form-spec" select="form:form-template(@template)"/>
      <xsl:copy-of select="$form-spec"/>
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
                    <xsl:text>[]" type="text" />' + </xsl:text>
                    <xsl:if test="position() eq 1">
                      <xsl:text>remove_</xsl:text>
                      <xsl:value-of select="$name"/>
                      <xsl:text>_anchor + </xsl:text>
                    </xsl:if>
                    <xsl:text>'&lt;/div></xsl:text>
                  </xsl:for-each>
                  <xsl:text>&lt;/fieldset>');</xsl:text>
                </xsl:when>
                <xsl:otherwise>$(this).parent().before('&lt;div>&lt;input name="<xsl:value-of select="$name"/>[]" type="text" />' + remove_<xsl:value-of select="$name"/>_anchor + '&lt;/div>');</xsl:otherwise>
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
                if($('input[name=<xsl:value-of select="$occurrence-test-name"/>\[\]]').length == 1) {
                  $('a.remove_<xsl:value-of select="$name"/>').remove();
                }
              });
            </xsl:variable>

            <!-- Variable is necessary as workaround for bug with <xsl:comment> instruction -->
            <xsl:variable name="comment-content">
              if(typeof jQuery != 'undefined') {
                $(function() {

                  $('input[name=add_<xsl:value-of select="$name"/>]').replaceWith('&lt;a class="add_remove add_<xsl:value-of select="$name"/>">+&#160;Add <xsl:value-of select="$label"/>&lt;/a>');
                  var remove_<xsl:value-of select="$name"/>_anchor = '&lt;a class="add_remove remove_<xsl:value-of select="$name"/>">-&#160;Remove <xsl:value-of select="$label"/>&lt;/a>';
                  $('a.add_<xsl:value-of select="$name"/>').click(function() {
                    <xsl:value-of select="$insert-command"/>
                    if($('input[name=<xsl:value-of select="$occurrence-test-name"/>\[\]]').length == 2) {
                      $('input[name=<xsl:value-of select="$occurrence-test-name"/>\[\]]:first').after(remove_<xsl:value-of select="$name"/>_anchor);
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
            <form class="adminform" action="" method="get" enctype="application/x-www-form-urlencoded">
              <!--
              <input type="submit" name="add" value="Add new" />
              -->
              <xsl:apply-templates mode="labeled-controls" select="."/>
            </form>
          </xsl:template>

                  <!-- to force "Status" into fieldset container; better handled by fix in CSS
                  <xsl:template mode="labeled-controls" match="/*">
                    <xsl:if test="@* except (@label:* | @form:* | @values:*)">
                      <fieldset>
                        <legend>Edit</legend>
                        <xsl:apply-templates mode="#current" select="(@* except (@label:*|@form:*|@values:*))"/>
                      </fieldset>
                    </xsl:if>
                    <xsl:apply-templates mode="#current" select="*"/>
                  </xsl:template>
                  -->

                  <xsl:template mode="labeled-controls" match="*">
                    <xsl:apply-templates mode="#current" select="*"/>
                  </xsl:template>

                  <xsl:template mode="labeled-controls" match="form:fieldset">
                    <fieldset>
                      <legend>
                        <xsl:value-of select="@legend"/>
                      </legend>
                      <xsl:apply-templates mode="#current" select="*"/>
                    </fieldset>
                  </xsl:template>

                  <xsl:template mode="labeled-controls" match="*[@form:label][not(@form:subsequent-item)]">
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

                          <!--
                          <xsl:function name="form:repeating-elements">
                            <xsl:param name="node"/>
                            <xsl:sequence select="if ($node/@form:repeating eq 'yes')
                                                  then $node/following-sibling::*[name(.) eq name($node)]
                                                  else ()"/>
                          </xsl:function>
                          -->




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
                                    <xsl:variable name="given-value" select="string(.)"/>
                                    <select name="{form:field-name(.)}">
                                      <xsl:for-each select="form:enumerated-values(.)">
                                        <option value="{.}">
                                          <xsl:if test=". eq $given-value">
                                            <xsl:attribute name="selected">selected</xsl:attribute>
                                          </xsl:if>
                                          <xsl:value-of select="."/>
                                        </option>
                                      </xsl:for-each>
                                    </select>
                                  </xsl:template>

                                          <xsl:function name="form:enumerated-values" as="xs:string*">
                                            <xsl:param name="element"/>
                                            <xsl:sequence select="if ($element/@form:values)
                                                                  then for $v in tokenize($element/@form:values,' ') return translate($v, '_', ' ')
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
                                             value="{.}">
                                        <xsl:apply-templates mode="class-att" select="."/>
                                      </input>
                                      <!-- TODO: allow removal for other types of controls, not just text fields -->
                                      <!-- Only insert one Remove button per group -->
                                      <xsl:if test="(not(../@form:group-label) and count(../*[node-name(.) eq node-name(current())]) gt 1)
                                                  or    (../@form:group-label and not(preceding-sibling::*))">
                                        <xsl:apply-templates mode="remove-button" select="ancestor-or-self::*"/>
                                      </xsl:if>
                                    </div>
                                  </xsl:template>

                                          <xsl:template mode="field-name-suffix" match="*"/>
                                          <xsl:template mode="field-name-suffix" match="*[(.|..)/@form:repeating eq 'yes']">[]</xsl:template>

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
                                      </textarea>
                                  </xsl:template>


  <xsl:function name="form:field-name">
    <xsl:param name="node"/>
    <xsl:sequence select="translate(local-name($node), '-', '_')"/>
  </xsl:function>

</xsl:stylesheet>
