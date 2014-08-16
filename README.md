# Raygun Error Handling Plugin

> Only for use with the **FarCry Commercial License**.  Do not distribute 
this code base to users on the GPL (open source) version of the FarCry platform.

[Raygun.io](http://raygun.io/) is a SaaS solution for aggregating error logging, 
and providing reporting, notification and escallation.  The plugin works by 
overriding the standard `farcry.core.packages.lib.error` component for error processing.

## Installation

You will require a Raygun API key for the application before you begin.

- unpack the plugin to `./farcry/plugins/raygun`
- register the plugin in the `./www/farcrycontructor.cfm`
- restart the application and deploy the Raygun config
- update the config with your Raygun API key

That is all.

!(https://raygun.io/cassette.axd/file/images/refactor-views/features-page/grouping-60f50b741288ba65e6f86cdabb8737b14a9387e7.png)