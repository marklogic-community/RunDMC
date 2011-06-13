setup-guides.xqy and setup.xqy are the master scripts that we run to get
everything in place. They pull in all the relevant data from the raw docs
database, massaging it as necessary, generating the XML TOC, the HTML TOC,
the function page XML docs, the function list page XML docs, etc. For more
details, see the comments in each file.

For development purposes, you don't always want to re-generate all the
content just to test one code change. For example, if you make a change
to how the TOC is (pre-)rendered, you don't want to have to run the whole
setup.xqy script which can take over a minute to run. In that case, you
can run just one of the individual XQuery scripts that setup.xqy calls,
e.g., render-toc.xqy.


Watch the error log as you run these scripts. They will help you keep
track of the progress and also report any applicable warnings.

Here's the series of requests you must run to get things set up:

http://localhost:8037/apidoc/setup/setup-guides.xqy?version=4.1
http://localhost:8037/apidoc/setup/setup-guides.xqy?version=4.2
http://localhost:8037/apidoc/setup/setup-guides.xqy?version=5.0
http://localhost:8037/apidoc/setup/setup.xqy?version=4.1
http://localhost:8037/apidoc/setup/setup.xqy?version=4.2
http://localhost:8037/apidoc/setup/setup.xqy?version=5.0

NOTE: For each version, setup-guides.xqy must be run before setup.xqy.
