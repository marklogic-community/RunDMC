#!/bin/bash
#
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

Transform -s:../config/template.xhtml             \
          -xsl:optimize-js-requests.xsl           \
          -o:../config/template.optimized.xhtml   \
          previous-result=template.previous.xhtml \
          last-all.js=last-all.js                 \
          new-all.js=new-all.js                     &&

# Copy for next time so we can keep using the same
# all-*.js script ref when there are no JS changes
cd ../config                                        &&
cp template.optimized.xhtml template.previous.xhtml &&

# Keep last-all.js around for next time as the basis
# for detecting whether the JS has since changed
cd ../js/optimized                                  &&
mv new-all.js last-all.js
