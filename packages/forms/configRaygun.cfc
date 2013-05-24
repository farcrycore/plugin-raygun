<cfcomponent displayname="Raygun.IO" hint="Settings for logging errors to Raygun.IO" extends="farcry.core.packages.forms.forms" output="false" key="raygun">
	
	<cfproperty name="apiKey" type="string" default=""
				ftSeq="1" ftFieldSet="API" ftLabel="API Key" />
	
	
</cfcomponent>