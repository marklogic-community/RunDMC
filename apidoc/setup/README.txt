setup.xqy is the master script that we run to get everything in place.
It pulls in all the relevant data from the docapp database, massaging
it as necessary, generates the XML TOC, the HTML TOC, the function page
XML docs, the function list page XML docs, etc. For more details, see
comments in setup.xqy.

For development purposes, you don't always want to re-generate all the
content just to test one code change. For example, if you make a change
to how the TOC is (pre-)rendered, you don't want to have to run the whole
setup.xqy script which can take over a minute to run. In that case, you
can run just one of the individual XQuery scripts that setup.xqy calls,
e.g., render-toc.xqy.
