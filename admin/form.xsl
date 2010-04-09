<xsl:stylesheet version="2.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:xdmp="http://marklogic.com/xdmp"
  xmlns      ="http://www.w3.org/1999/xhtml"
  xmlns:xhtml="http://www.w3.org/1999/xhtml"
  xmlns:ml               ="http://developer.marklogic.com/site/internal"
  xmlns:form             ="http://developer.marklogic.com/site/internal/form"
  xmlns:label            ="http://developer.marklogic.com/site/internal/form/attribute-labels"
  xmlns:values           ="http://developer.marklogic.com/site/internal/form/values"
  xpath-default-namespace="http://developer.marklogic.com/site/internal"
  exclude-result-prefixes="xs ml xdmp">

  <xsl:function name="ml:form-template">
    <xsl:param name="template"/>
    <xsl:sequence select="xdmp:document-get(concat(xdmp:modules-root(),
                                                   '/admin/forms/',
                                                   $template))"/>
  </xsl:function>

  <xsl:template match="auto-form-scripts">
    <xsl:for-each select="$content//auto-form">
      <xsl:apply-templates mode="form-script" select="ml:form-template(@template)//*[@form:repeating eq 'yes']"/>
    </xsl:for-each>
  </xsl:template>

          <xsl:template mode="form-script" match="*">
            <!-- TODO: Is there a way I can do this inline without embedding it in a comment? -->
            <xsl:variable name="name" select="local-name(.)"/>
            <xsl:variable name="label" select="@form:label"/>

            <!-- Variable is necessary as workaround for bug with <xsl:comment> instruction -->
            <xsl:variable name="comment-content">
              if(typeof jQuery != 'undefined') {
                $(function() {

                  $('input[name=add_<xsl:value-of select="$name"/>]').replaceWith('&lt;a class="add_remove add_<xsl:value-of select="$name"/>">+&#160;Add <xsl:value-of select="$label"/>&lt;/a>');
                  var remove_<xsl:value-of select="$name"/>_anchor = ' &lt;a class="add_remove remove_<xsl:value-of select="$name"/>">-&#160;Remove <xsl:value-of select="$label"/>&lt;/a>';
                  $('a.add_<xsl:value-of select="$name"/>').click(function() {
                    $(this).parent().before('&lt;div>&lt;input name="<xsl:value-of select="$name"/>[]" type="text" />' + remove_<xsl:value-of select="$name"/>_anchor + '&lt;/div>');
                      if($('input[name=<xsl:value-of select="$name"/>\[\]]').length == 2) {
                        $('input[name=<xsl:value-of select="$name"/>\[\]]:first').after(remove_<xsl:value-of select="$name"/>_anchor);
                      }
                    $('a.remove_<xsl:value-of select="$name"/>').click(function() {
                      $(this).parent().remove();
                      if($('input[name=<xsl:value-of select="$name"/>\[\]]').length == 1) {
                        $('a.remove_<xsl:value-of select="$name"/>').remove();
                      }
                    });
                  });
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
    <xsl:apply-templates mode="generate-form" select="ml:form-template(@template)"/>
  </xsl:template>

          <xsl:template mode="generate-form" match="*">
            <form class="adminform" id="codeedit" action="" method="get" enctype="application/x-www-form-urlencoded">
              <input type="submit" name="add" value="Add new" />
              <xsl:apply-templates mode="labeled-controls" select="."/>
            </form>
          </xsl:template>

                  <xsl:template mode="labeled-controls" match="*">
                    <xsl:apply-templates mode="#current" select="(@* except (@label:*|@form:*|@values:*)) | *"/>
                  </xsl:template>

                  <xsl:template mode="labeled-controls" match="form:fieldset">
                    <fieldset>
                      <legend>
                        <xsl:value-of select="@legend"/>
                      </legend>
                      <xsl:apply-templates mode="#current" select="*"/>
                    </fieldset>
                  </xsl:template>

                  <xsl:template mode="labeled-controls" match="@*"/>
                  
                  <xsl:template mode="labeled-controls" match="* [@form:label]
                                                             | @*[local-name(.) = ../@label:*/local-name()]" name="control-with-label">
                    <div>
                      <label for="{local-name()}_{generate-id()}">
                        <xsl:apply-templates mode="control-label" select="."/>
                      </label>
                      <xsl:apply-templates mode="form-control" select="."/>
                      <xsl:apply-templates mode="add-more-button" select="."/>
                    </div>
                  </xsl:template>

                          <xsl:template mode="add-more-button" match="@* | *"/>
                          <xsl:template mode="add-more-button" match="*[@form:repeating eq 'yes']">
                            <div>
                              <input class="add_remove" type="submit" name="add_{local-name()}" value="+ Add {@form:label}"/>
                            </div>
                          </xsl:template>


                          <xsl:template mode="control-label" match="*">
                            <xsl:value-of select="@form:label"/>
                          </xsl:template>

                          <xsl:template mode="control-label" match="@*">
                            <xsl:value-of select="../@label:*[local-name() eq local-name(current())]"/>
                          </xsl:template>


                          <xsl:template mode="form-control" match="* | @*">
                            <xsl:variable name="field-name">
                              <xsl:value-of select="local-name()"/>
                              <xsl:apply-templates mode="field-name-suffix" select="."/>
                            </xsl:variable>
                            <div>
                              <input id ="{local-name()}_{generate-id()}"
                                     name="{$field-name}"
                                     type="text">
                                <xsl:apply-templates mode="class-att" select="."/>
                              </input>
                            </div>
                          </xsl:template>

                                  <xsl:template mode="field-name-suffix" match="@* | *"/>
                                  <xsl:template mode="field-name-suffix" match="*[@form:repeating eq 'yes']">[]</xsl:template>

                                  <xsl:template mode="class-att" match="*[@form:wide eq 'yes']">
                                    <xsl:attribute name="class">wideText</xsl:attribute>
                                  </xsl:template>


                          <xsl:template mode="form-control" match="*[@form:type eq 'textarea']">
                              <input type="submit" name="add_media" value="Add media"/>
                              <br/>
                              <textarea id ="{local-name()}_{generate-id()}"
                                        name="{local-name()}"
                                        cols="30"
                                        rows="5">
                                <xsl:apply-templates mode="class-att" select="."/>
                              </textarea>
                          </xsl:template>

</xsl:stylesheet>
