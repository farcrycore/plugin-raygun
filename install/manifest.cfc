<cfcomponent extends="farcry.core.webtop.install.manifest" name="manifest">
	
	<cfset this.name = "Raygun Logger" />
	<cfset this.description = "<strong>Raygun Logger</strong> logs errors to the <a href='http://raygun.io'>Raygun.IO</a> service" />
	<cfset this.lRequiredPlugins = "" />
	<cfset addSupportedCore(majorVersion="6", minorVersion="1", patchVersion="0") />
	
	
	<cffunction name="getStatus" output="false" access="public" returntype="string">
		
		<cfif len(application.fapi.getConfig('raygun', 'apiKey', ''))>
			<cfreturn "good" />
		<cfelse>
			<cfreturn "bad" />
		</cfif>
	</cffunction>

</cfcomponent>