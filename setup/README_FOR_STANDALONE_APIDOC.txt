This document lists the steps for getting a copy of the standalone apidoc
application up and running on your machine.

1. Install MarkLogic 5 if you haven't already.

2. Get and install git from http://git-scm.com.
   Alternatively, if you use Cygwin, you can install it using Cygwin's setup.exe.

3. Go to the directory where you'd like to install your code,
   e.g. your home directory.

   Run these commands:

   $ git clone git://github.com/marklogic/RunDMC.git
   $ cd RunDMC
   $ git branch apidoc origin/apidoc
   $ git checkout apidoc

   Note: The first command will take a while due to downloading a large
         zip file that had been put in the repository.

   Later on, whenever you need to get the latest code, run this command:

   $ git pull

   Note: The above clone URL is read-only. For push/write access, you'll
         need the appropriate ssh credentials, etc.

4. Create an app server for running scripts in this directory.

   Name: RunDMC-Maintenance (any name will do)
   Port: 8008 (or a different one if that's being used already)
   Root: <rundmc-src-dir> (the directory you used above, e.g., /Users/elenz/RunDMC)
   Database: Documents (this will get automatically changed later)

5. In your browser, go to the following URL (assuming you used port 8008):

   http://localhost:8008/setup/install-standalone-api.xqy

   This script will set up your database, forest, and apidoc server.

   The port for your standalone apidoc server will be 8011. If you need it
   to be something different, you'd need to first update /config/server-urls.xml
   before running the above script.

6. Follow the steps in /apidoc/setup/README.txt, starting at step #4
   (steps 1-3 have already been completed for you).
