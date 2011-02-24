# Run ./optimize-js.sh to create template.optimized.xhtml,
#   including a reference to a newly generated all-*.js file 
#
# This script assumes the existence of a script named "Transform"
#  somewhere in your path, e.g., /usr/local/bin/Transform, which
#  invokes Saxon, e.g.:
#
#     #!/bin/bash
#     java -jar /Applications/saxon/saxon9he.jar "$@"
#

Transform -s:../config/template.xhtml \
          -xsl:optimize-js-requests.xsl \
          -o:../config/template.optimized.xhtml
