# Raygun Error Handling Plugin

> Distributed under the LGPL license; compatible with both the open source and commercial licenses of FarCry Core

[Raygun.io](http://raygun.io/) is a SaaS solution for aggregating error logging, 
and providing reporting, notification and escalation.  The plugin works by 
overriding the standard `farcry.core.packages.lib.error` component for error processing.

## Installation

You will require a Raygun API key for the application before you begin.

- unpack the plugin to `./farcry/plugins/raygun`
- register the plugin in the `./www/farcrycontructor.cfm`
- restart the application and deploy the Raygun config
- update the config with your Raygun API key

That is all.

![Raygun](https://raygun.io/images/products/integrations-2.jpg)
