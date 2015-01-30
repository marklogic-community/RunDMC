xquery version "1.0-ml";

import module namespace api="http://marklogic.com/rundmc/api"
  at "/apidoc/model/data-access.xqy";

declare namespace apidoc="http://marklogic.com/xdmp/apidoc";

xdmp:set-response-content-type("text/html"),
<html>
  <head>
    <title>Redirecting to new docs...</title>
    <script type="text/javascript">
      var hash = window.location.hash;

      // Function name redirects
      if (hash.indexOf("function=") != -1) {{
        window.location.href = "/" + hash.match(/function=(.*)/)[1];
      }}

      // Guide redirects
      else if (hash.indexOf("/xml/") != -1) {{
        var guide = hash.match(/\/xml\/([^/]+)\//)[1];
        var chapterName = hash.match(/\/xml\/.*\/(.*)\.xml/)[1];
        var fragmentMatch = hash.match(/.xml%23(.*)/);
        if (fragmentMatch !== null)
          fragment = "id_" + fragmentMatch[1];
        else
          fragment = "chapter";
        var guideUrlName;
        {
      (: #296 might want to figure out the correct version. :)
      let $version := $api:DEFAULT-VERSION
      let $guides := api:document-list($version)//apidoc:guide[
        not(xs:boolean(@duplicate))]
      for $guide at $pos in $guides
      return (
           if ($pos ne 1) then text{" else "} else (),
           text{ "if (guide == '"     },
           text{ $guide/@source-name  },
           text{ "') guideUrlName = '"},
           text{ $guide/@url-name     },
           text{ "'; " } )
      }
        /*
        alert(guide);
        alert(fragment);
        alert(chapterName);
        alert(guideUrlName);
        */
        window.location.href = "/guide/" + guideUrlName + ((chapterName != "title") ? "/" + chapterName + "#" + fragment
                                                                                    : "");
      }}

      // Search redirects
      else if (hash.indexOf("#search.xqy" != -1)) {{
        var queryMatch = hash.match(/query=([^\046]+)/); // \046 is ampersand
        var query;
        if (queryMatch != null) {{
          query = queryMatch[1];
          //alert(query);
          window.location.href = "//developer.marklogic.com/search?q=" + query;
        }}
        else window.location.href = "/"; // give up
      }}

      // Give up and redirect to site home
      else window.location.href = "/";
    </script>
  </head>
  <body>Redirecting to new doc URL...</body>
</html>
