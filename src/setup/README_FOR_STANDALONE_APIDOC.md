Follow these instructions to set up a standalone installation of the
online documentation portion of RunDMC (i.e. docapp, evanapp, "that thing
that runs on pubs:8011"). Do NOT use instructions you may trip over in
other README.txt files in this distribution.

INSTALL REQUIRED SOFTWARE AND SOURCES 
-------------------------------------
You should only need to do this once. Thereafter, you can update the
RunDMC sources as needed by doing a git pull. For example:

  $ git pull

1. Install MarkLogic Server if you don't already have it.

2. Install a git client if you don't already have one. For example,
   from http://get-scm.com or use Cygwin setup to install the git command.

3. If you don't already have the RunDMC sources, check them out from GitHub:
   a) cd to the directory you want to contain the RunDMC source folder,
      such as your home directory.
   b) Run the following commands. The first command may take awhile.
      git clone git://github.com/marklogic/RunDMC.git
      cd RunDMC
      git branch apidoc origin/apidoc
      git checkout apidoc
   c) To update to the latest version at any time, run this command:
      git pull


SETUP THE DATABASES AND APP SERVERS
-----------------------------------
You should only need to follow this procedure once.

1. Create an app server for running scripts in this directory.

    Name: RunDMC-Maintenance (any name will do)  
    Port: 8008 (or a different one if that's being used already)  
    Root: Your RunDMC directory, e.g., /Users/elenz/RunDMC  
    Database: Documents (this will get automatically changed later)  

2. Hit http://localhost:8008/apidoc/setup/install-standalone-apidoc.xqy 
   in your browser or with curl. This creates the RunDMC and
   RunDMC-api-rawdocs databases and the RunDMC-standalone-api app server.


LOAD THE DOCUMENTATION INTO THE APPLICATION
-------------------------------------------
Repeat this procedure each time you want to load new documentation
into your local version of the application.

1. If you don't already have one, create a staging area that contains
   both zipped and unzipped versions of the nightly doc build output.
   Use the zip file created by the nightly doc build for your target version.
   Yes, you really have to have it both zipped and unzipped. Sigh.
 
   For example, if your staging dir is /stage and you're loading ML7 docs:

     /stage/
       MarkLogic_7_pubs/
       MarkLogic_7_pubs.zip

2. If you don't have xdmp/src/Config checked out somewhere, check it out.
   For example, in /space/svn/7.0/xdmp/src/Config.

3. Load the docs for a given version by running a curl command similar to
   the following (or hit the equivalent URL in your browser). (USER,
   PASSWORD, VER, STAGE, and CONFIG as per your env.)

     curl -i -X GET --anyauth --user USER:PASSWORD \
       'http://localhost:8008/apidoc/setup/build.xqy?version=VER&srcdir=STAGE&help-xsd-dir=CONFIG&clean=yes'

   Expect the load to take quite awhile - 10-15 minutes. If it finishes
   quickly, it didn't work.

   For example, if your staging dir is /stage/ and your xdmp checkout is
   in /space/svn/7.0/xdmp/src, and you're loading 7.0 docs as admin, you 
   would use the following command:

     curl -i -X GET --anyauth --user admin:password \
       'http://localhost:8008/apidoc/setup/build.xqy?version=7.0&srcdir=/stage/MarkLogic_7_pubs&help-xsd-dir=/space/svn/7.0/xdmp/src/Config&clean=yes'

   NOTE:
   - Don't forget to either put single quotes around the URL or escape
     the &'s (\&).
   - If you're Windows, use Windows paths not cygwin paths. It's ML you're
     communicating the path to, not a shell script.


For more information about loading just portions of the documentation
(say, just the static docs), see:

   RunDMC/apidoc/setup/README_FOR_NIGHTLY_BUILD.txt

