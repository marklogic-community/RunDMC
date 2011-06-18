HOW TO BUILD CONTENT

Content is loaded and built using a series of script invocations. You only
ever load and build content for one version at a time, e.g., 4.1, 4.2, etc.


STEP 1: Create an empty source database.
  The source database is used by the setup code but not by the run-time rendering
  code. For that reason, it will only be necessary to include this database on
  the staging server, not the production server. The expected name of this database,
  "RunDMC-api-rawdocs", is configured in /apidoc/config/source-database.xml.

  The same source database is used for all versions of the documentation. (In other
  words, you don't need to create a separate database for each version.)

  This is a one-time step. Subsequent runs of the content-loading script (next step)
  will keep using the same database.


STEP 2: Create an app server for running the setup scripts.
  E.g., I have an app server called RunDMC-Maintenance on my machine.

  Database: RunDMC
  Modules: (filesystem)
  Root: /Users/elenz/work/rundmc.git (or wherever your code is checked out)
  Port: 8008 (or whatever you want)

  (same configuration as RunDMC, except with no URL rewriter)


STEP 3: Put the latest raw docs (from \\gfurbush\Docs) on the machine running MarkLogic Server.
  For example, on my local machine, I put these folders into: /Users/elenz/Desktop/api-rawdocs/


STEP 4: Load the raw docs into the source database.
  This is done by running the load-raw-docs.xqy script in this directory. You must
  specify both the version of the docs that you're loading and the source directory
  for those documents.

  For example, here's what I point my browser to to load the 4.2 docs:

  http://localhost:8008/apidoc/setup/load-raw-docs.xqy?srcdir=/Users/elenz/Desktop/api-rawdocs/b4_2_XML&version=4.2

  Watch the error log as you run these scripts. They will help you keep
  track of the progress and also report any applicable warnings.


STEP 5: Run setup-guides.xqy.
  http://localhost:8008/apidoc/setup/setup-guides.xqy?version=4.2


STEP 6: Run setup.xqy.
  http://localhost:8008/apidoc/setup/setup.xqy?version=4.2


SUMMARY
  To load and build all the 4.1, 4.2, and 5.0 docs, here is the complete
  series of requests you'd have to run:

    http://localhost:8008/apidoc/setup/load-raw-docs.xqy?srcdir=/Users/elenz/Desktop/api-rawdocs/b4_1_XML&version=4.1
    http://localhost:8008/apidoc/setup/setup-guides.xqy?version=4.1
    http://localhost:8008/apidoc/setup/setup.xqy?version=4.1

    http://localhost:8008/apidoc/setup/load-raw-docs.xqy?srcdir=/Users/elenz/Desktop/api-rawdocs/b4_2_XML&version=4.2
    http://localhost:8008/apidoc/setup/setup-guides.xqy?version=4.2
    http://localhost:8008/apidoc/setup/setup.xqy?version=4.2

    http://localhost:8008/apidoc/setup/load-raw-docs.xqy?srcdir=/Users/elenz/Desktop/api-rawdocs/latest_XML&version=5.0
    http://localhost:8008/apidoc/setup/setup-guides.xqy?version=5.0
    http://localhost:8008/apidoc/setup/setup.xqy?version=5.0

  NOTE: For each version, setup-guides.xqy must be run before setup.xqy.

  There are no dependencies between versions of the documentation. You can load
  and build one version of the documentation independently of the others.


WARNING
  One of the files in 4.1 has an issue that breaks the setup script. Until it gets
  fixed, I have to manually fix this each time, changing id="output formats" and
  href="#output formats" to id="outputformats" and href="#outputformats", respectively.
  This isn't an issue for either 4.2 or 5.0. (See bug #13808)


MORE IMPLEMENTATION NOTES
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
  i.e., render-toc.xqy.
