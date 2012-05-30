import module namespace u="http://marklogic.com/rundmc/util"
       at "../../lib/util-2.xqy";

declare variable $versions := u:get-doc("/config/server-versions.xml")/*/*:version/@number/string(.);

<html xmlns="http://www.w3.org/1999/xhtml">
  <head>
    <title>Set up all content</title>
		<script type="text/javascript" src="/js/jquery-1.7.2.min.js"></script>
  </head>
  <body>
    <h1>Set up all content</h1>
    <p>This page has many buttons. The simplest usage is to click the "Set up everything" button, which will run the setup process
       for all the server versions in parallel. At the end, it will run the category tagger (which is what enables faceted search).</p>
    <p>Alternatively, you can run the setup for just one server version, e.g. "Set up all 5.0 docs". The "Delete" buttons are never run
       automatically. They give you the option of clearing out the existing documents before running a clean setup.</p>
    <p>Finally, the individual parts (steps 1 and 2 and their lettered sub-steps) can be invoked individually. These are provided
       for debugging purposes and also to give a visual hint as to the current progress of the setup tasks. For even more granular
       tracking, watch the ErrorLog file while a setup task is running.</p>
    <table cellspacing="0" cellpadding="10">
      <tr>
        <th><input type="button" id="runAll" value="Set up everything!"/></th>
        <th>&#160;</th>
        <th>Step 1: Guides</th>
        <th>Step 2: Functions, TOC, etc.</th>
      </tr>
      {
      for $v in $versions return
        <tr>
          <th>
            <div>
              <input type="button" class="runVersion" value="Set up all {$v} docs ->"/>
            </div>
            <div>
              <input type="button" class="deleteButton" value="Delete all {$v} docs" alt="/apidoc/setup/delete-docs.xqy?version={$v}"/>
            </div>
          </th>
          <th>{$v}</th>
          <td valign="top">
            <input type="button" class="runSection" value="Set up {$v} guides"/>
            <ol type="a">
              <li>
                <input class="atomicStep" type="button" alt="/apidoc/setup/consolidate-guides.xqy?version={$v}" value="Consolidate {$v} guides"/>
              </li>
              <li>
                <input class="atomicStep" type="button" alt="/apidoc/setup/convert-guides.xqy?version={$v}"     value="Convert {$v} guides"/>
              </li>
              <li>
                <input class="atomicStep" type="button" alt="/apidoc/setup/copy-guide-images.xqy?version={$v}"  value="Copy {$v} guide images"/>
              </li>
            </ol>
          </td>
          <td>
            <input type="button" class="runSection" value="Set up {$v} functions, TOC, etc."/>
            <ol type="a">
              <li>
                <input class="atomicStep" type="button" alt="/apidoc/setup/pull-function-docs.xqy?version={$v}" value="Pull {$v} function docs"/>
              </li>
              <li>
                <input class="atomicStep" type="button" alt="/apidoc/setup/create-toc.xqy?version={$v}"         value="Create {$v} XML TOC"/>
              </li>
              <li>
                <input class="atomicStep" type="button" alt="/apidoc/setup/render-toc.xqy?version={$v}"         value="Render {$v} HTML TOC"/>
              </li>
              <li>
                <input class="atomicStep" type="button" alt="/apidoc/setup/delete-old-toc.xqy?version={$v}"     value="Delete old {$v} TOC"/>
              </li>
              <li>
                <input class="atomicStep" type="button" alt="/apidoc/setup/make-list-pages.xqy?version={$v}"    value="Make {$v} list pages"/>
              </li>
            </ol>
          </td>
        </tr>
      }
      <tr>
        <td>
          <input id="tagger" type="button" alt="/setup/collection-tagger.xqy" value="Run global category tagger"/>
        </td>
      </tr>
    </table>
    <script>
      <!--
      $(function(){{

        // This is updated when you run "setup everything"
        var runCollectionTagger = false;

        var invokeStep = function(button, masterButton) {{

          var getNextStep = function() {{
            var nextSiblingSteps = button.parent()     .nextAll().find(".atomicStep");
            var nextCousinSteps  = button.parents("td").nextAll().find(".atomicStep");

            var nextSteps = masterButton.is(".runVersion") ? nextSiblingSteps.add(nextCousinSteps)
                         : (masterButton.is(".runSection") ? nextSiblingSteps
                                                            : $([]));
            return nextSteps.first();
          }};

          var nextStep = masterButton==undefined ? $([]) : getNextStep();

          run(button);

          button.load(button.attr("alt"),
            function(response, status, xhr) {{
              if (status == "error") {{
                button.parent().html(response);
                abort(masterButton);
              }} else {{
                finish(button);
                if (nextStep.length)
                  invokeStep(nextStep, masterButton)
                else {{
                  finish(masterButton);
                  // If we've just finished running "everything", then run the collection tagger now
                  if (runCollectionTagger && $('input[disabled="disabled"]').length==0) {{
                    $("#tagger").click();
                    runCollectionTagger = false;
                  }}
                }}
              }}
            }});
        }};

        var run = function(buttons) {{
          buttons.each(function(){{
            $(this).val("RUNNING: " + $(this).val());
            $(this).css("color", "red");
            $(this).attr("disabled","disabled");
          }})
        }};

        var finish = function(buttons) {{
          buttons.each(function(){{
            $(this).val("Finished: " + $(this).val());
            $(this).css("color", "inherit");
            $(this).removeAttr("disabled");
          }})
        }};

        var abort = function(buttons) {{
          buttons.each(function(){{
            $(this).val("Aborted: " + $(this).val());
            $(this).css("color", "inherit");
          }})
        }};

        // Run an individual step
        $(".atomicStep, .deleteButton, #tagger").click(function(){{
          invokeStep($(this), $([]));
        }});

        // Run everything for the given version or section
        $(".runVersion, .runSection").click(function(){{
          var firstStep = $(this).closest("tr,td").find("li input").first();
          run($(this));
          invokeStep(firstStep, $(this));
        }});

        // Run every version
        $("#runAll").click(function(){{
          $(".runVersion").click();
          runCollectionTagger = true;
        }});

      }});
    -->
    </script>
  </body>
</html>
