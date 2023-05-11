# Purpose 

This is an attempt to handle redirection within MarkLogic. Currently, the old doc guide references sections using
anchor ids, e.g. https://docs.marklogic.com/11.0/guide/installation/procedures#id_98235. On the Paligo generated pages,
the resulting page should be: https://docs.marklogic.com/11.0/guide/installation-guide/en/procedures/configuring-the-first-and-subsequent-hosts/configuring-an-additional-host-in-a-cluster.html.

The discrepancy cannot be handled at apache level as the anchor "#id_98235" portion cannot be processed at that level.
The MLCP script here is intended to load the content located at `/space/rundmc`, then later processed for redirection.

# MLCP

The MLCP portion will load content from `/space/rundmc/` (dmc-stage and dmc-internal) or `/var/www/html/` (cms nightly)
and store them under the directory of `/paligo/` in the RunDMC content database. Currently, the globalsearch ingest
only processes `/apidoc/` and `/products/`. Then these contents could be used to compute the redirection.

It will be assumed by this project that `mlcp` is recognized as a global command.

# CORB

The Corb2 portion is meant to clean out the entire `/paligo/` directory in the content database. Note that the Paligo
generated pages are using the page title as filename. The CORB portion ensures that the renamed pages disappear from
the list of redirect candidates.