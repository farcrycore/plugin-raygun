<cfcomponent extends="farcry.core.packages.lib.error" output="false">
	
	
	<cffunction name="collectRequestInfo" access="public" returntype="struct" output="false" hint="Returns a struct containing information that should be included in every error report">
		<cfset var stResult = super.collectRequestInfo() />
		<cfset var headers = GetHttpRequestData().headers />
		<cfset var key = "" />
		
		<cfif structkeyexists(headers,"X-User-Agent")>
			<cfset stResult["browser"] = headers["X-User-Agent"] />
		</cfif>
		<cfif structkeyexists(headers,"X-Forwarded-For")>
			<cfset stResult["remoteaddress"] = trim(listfirst(headers["X-Forwarded-For"])) />
		</cfif>
		
		<cfloop collection="#arguments#" item="key">
			<cfset stResult[key] = arguments[key] />
		</cfloop>
		
		<cfreturn stResult />
	</cffunction>
	
	<cffunction name="logToRaygun" access="public" output="false" returntype="void" hint="Logs data to the couchdb">
		<cfargument name="type" type="string" required="true" hint="Log type" />
		<cfargument name="data" type="struct" requried="true" hint="A normalized error struct as produced by the core error library" />
		
		<cfset var cfhttp = structnew() />
		<cfset var stMessage = structnew() />
		<cfset var i = 0 />
		<cfset var stSub = "" />
		<cfset var system = "" />
		<cfset var props = "" />
		<cfset var mf = "" />
		<cfset var osbean = "" />
		<cfset var oFile = "" />
		<cfset var aRoots = "" />
		<cfset var runtime = "" />
		
		<cfif isdefined("application.config.raygun.apiKey") and len(application.config.raygun.apiKey)>
			<cfset system = createObject("java", "java.lang.System") />
			<cfset props = system.getProperties() />
			<cfset mf = createObject("java", "java.lang.management.ManagementFactory") />
			<cfset osbean = mf.getOperatingSystemMXBean() />
			<cfset oFile = createObject("java", "java.io.File") />
			<cfset aRoots = oFile.listRoots() />
			<cfset runtime = CreateObject("java","java.lang.Runtime").getRuntime()>
			
			<cfset stMessage["occurredOn"] = dateformat(arguments.data.datetime,"yyyy-mm-dd") & "T" & timeformat(arguments.data.datetime,"HH:mm:ss") & "Z" />
			<cfset stMessage["details"] = structnew() />
			<cfset stMessage["details"]["machineName"] = arguments.data.machinename />
			<cfset stMessage["details"]["version"] = JavaCast("null","") />
			<cfset stMessage["details"]["client"] = structnew() />
			<cfset stMessage["details"]["client"]["name"] = JavaCast("null","") />
			<cfset stMessage["details"]["client"]["version"] = JavaCast("null","") />
			<cfset stMessage["details"]["client"]["clientUrl"] = JavaCast("null","") />
			<cfset stMessage["details"]["error"] = structnew() />
			<cfset stMessage["details"]["error"]["innerError"] = JavaCast("null","") />
			<cfset stMessage["details"]["error"]["data"] = structnew() />
			<cfif structKeyExists(arguments.data, "type") and len(arguments.data.type)>
				<cfset stMessage["details"]["error"]["data"]["type"] = arguments.data.type />
			</cfif>
			<cfif structKeyExists(arguments.data, "errorcode") and len(arguments.data.errorcode)>
				<cfset stMessage["details"]["error"]["data"]["errorcode"] = arguments.data.errorcode />
			</cfif>
			<cfif structKeyExists(arguments.data, "detail") and len(arguments.data.detail)>
				<cfset stMessage["details"]["error"]["data"]["detail"] = arguments.data.detail />
			</cfif>
			<cfif structKeyExists(arguments.data, "extended_info") and len(arguments.data.extended_info)>
				<cfset stMessage["details"]["error"]["data"]["extended_info"] = arguments.data.extended_info />
			</cfif>
			<cfif structKeyExists(arguments.data, "queryError") and len(arguments.data.queryError)>
				<cfset stMessage["details"]["error"]["data"]["queryError"] = arguments.data.queryError />
			</cfif>
			<cfif structKeyExists(arguments.data, "sql") and len(arguments.data.sql)>
				<cfset stMessage["details"]["error"]["data"]["sql"] = arguments.data.sql />
			</cfif>
			<cfif structKeyExists(arguments.data, "where") and len(arguments.data.where)>
				<cfset stMessage["details"]["error"]["data"]["where"] = arguments.data.where />
			</cfif>
			<cfset stMessage["details"]["error"]["className"] = JavaCast("null","") />
			<cfset stMessage["details"]["error"]["message"] = arguments.data.message />
			<cfset stMessage["details"]["error"]["stackTrace"] = arraynew(1) />
			<cfloop from="1" to="#arraylen(arguments.data.stack)#" index="i">
				<cfset stSub = structnew() />
				<cfset stSub["lineNumber"] = arguments.data.stack[i].line />
				<cfset stSub["className"] = JavaCast("null","") />
				<cfset stSub["fileName"] = arguments.data.stack[i].template />
				<cfset arrayappend(stMessage["details"]["error"]["stackTrace"],stSub) />
			</cfloop>
			<cfset stMessage["details"]["environment"] = structnew() />
			<cfset stMessage["details"]["environment"]["processorCount"] = osbean.getAvailableProcessors() />
			<cfset stMessage["details"]["environment"]["osVersion"] = props["os.name"] & "|" & props["os.version"] />
			<cfset stMessage["details"]["environment"]["windowBoundsWidth"] = JavaCast("null","") />
			<cfset stMessage["details"]["environment"]["windowBoundsHeight"] = JavaCast("null","") />
			<cfset stMessage["details"]["environment"]["resolutionScale"] = JavaCast("null","") />
			<cfset stMessage["details"]["environment"]["currentOrientation"] = JavaCast("null","") />
			<cfset stMessage["details"]["environment"]["cpu"] = osbean.getProcessCpuTime() />
			<cfset stMessage["details"]["environment"]["packageVersion"] = props["java.vm.vendor"] & "|" & props["java.runtime.version"] & "|" & props["java.vm.name"] />
			<cfset stMessage["details"]["environment"]["architecture"] = props["os.arch"] />
			<cfset stMessage["details"]["environment"]["totalPhysicalMemory"] = osbean.getTotalPhysicalMemorySize() />
			<cfset stMessage["details"]["environment"]["availablePhysicalMemory"] = osbean.getFreePhysicalMemorySize() />
			<cfset stMessage["details"]["environment"]["totalVirtualMemory"] = JavaCast("null","") />
			<cfset stMessage["details"]["environment"]["availableVirtualMemory"] = JavaCast("null","") />
			<cfset stMessage["details"]["environment"]["diskSpaceFree"] = arraynew(1) />
			<cfloop from="1" to="#arraylen(aRoots)#" index="i">
				<cfset arrayappend(stMessage["details"]["environment"]["diskSpaceFree"],aRoots[i].getFreeSpace()) />
			</cfloop> 
			<cfset stMessage["details"]["environment"]["deviceName"] = JavaCast("null","") />
			<cfset stMessage["details"]["environment"]["locale"] = JavaCast("null","") />
			<cfset stMessage["details"]["tags"] = JavaCast("null","") />
			<cfset stMessage["details"]["userCustomData"] = structnew() />
			<cfset stMessage["details"]["userCustomData"]["instanceName"] = arguments.data.instanceName />
			<cfset stMessage["details"]["userCustomData"]["browser"] = arguments.data.browser />
			<cfif isdefined("application.plugins")>
				<cfset stMessage["details"]["userCustomData"]["plugins"] = application.plugins />
			</cfif>
			<cfif isdefined("application.fcstats.updateapp")>
				<cfset stMessage["details"]["userCustomData"]["appStart"] = dateformat(application.fcstats.updateapp.when[application.fcstats.updateapp.recordcount],"yyyy-mm-dd") & "T" & timeformat(application.fcstats.updateapp.when[application.fcstats.updateapp.recordcount],"HH:mm:ss") & "Z" />
			</cfif>
			<cfset stMessage["details"]["request"] = structnew() />
			<cfset stMessage["details"]["request"]["hostName"] = arguments.data.host />
			<cfset stMessage["details"]["request"]["url"] = arguments.data.scriptname />
			<cfset stMessage["details"]["request"]["httpMethod"] = CGI.REQUEST_METHOD />
			<cfset stMessage["details"]["request"]["ipAddress"] = arguments.data.remoteaddress />
			<cfset stMessage["details"]["request"]["queryString"] = arguments.data.querystring />
			<cfset stMessage["details"]["request"]["form"] = FORM />
			<cfset stMessage["details"]["request"]["headers"] = getHttpRequestData().headers />
			<cfset stMessage["details"]["request"]["data"] = CGI />
			<cfset stMessage["details"]["request"]["raw"] = JavaCast("null","") />
			
			<cfhttp url="https://api.raygun.io/entries" method="post" charset="utf-8" timeout="0">
				<cfhttpparam type="header" name="Content-Type" value="application/json"/>
				<cfhttpparam type="header" name="X-ApiKey" value="#application.config.raygun.apiKey#"/>
				<cfhttpparam type="body" value="#serializeJSON(stMessage)#" />
			</cfhttp>
		</cfif>
	</cffunction>
	
	
	<cffunction name="logData" access="public" output="false" returntype="void" hint="Logs error to application and exception log files">
		<cfargument name="log" type="struct" required="true" />
		<cfargument name="bApplication" type="boolean" required="false" default="true" />
		<cfargument name="bException" type="boolean" required="false" default="true" />
		<cfargument name="bCouch" type="boolean" required="false" default="true" />
		
		<cfset var errorJSON = "" />
		<cfset var logtype = "error" />
		
		<cfif structkeyexists(arguments.log,"logtype")>
			<cfset logtype = arguments.log.logtype />
			<cfset structdelete(arguments.log,"logtype") />
		</cfif>
		
		<cfif logtype eq "error">
			<cfset logToRaygun(logtype,arguments.log) />
		</cfif>
		
		<cfset super.logData(argumentCollection=arguments) />
	</cffunction>
	
</cfcomponent>