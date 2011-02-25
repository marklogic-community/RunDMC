# Run ./optimize-js.sh (from within this directory)
#   to create template.optimized.xhtml, which includes
#   a reference to a newly generated all-*.js file 
#
# This script assumes the existence of a script named "Transform"
#  somewhere in your path, e.g., /usr/local/bin/Transform, which
#  invokes Saxon, e.g.:
#
#     #!/bin/bash
#     java -jar /Applications/saxon/saxon9he.jar "$@"
#
# This is intended to be run every time we push code to
# the production/staging servers so might best invoked as
# a git hook.

Transform -s:../config/template.xhtml \
          -xsl:optimize-js-requests.xsl \
          -o:../config/template.optimized.xhtml
