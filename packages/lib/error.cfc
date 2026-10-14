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
		
		<cfif structkeyexists(application,"security")>
			<cfset stResult.username = application.security.getCurrentUserID() />
		<cfelse>
			<cfset stResult.username = "" />
		</cfif>
		
		<cfset stResult.session = getSession() />
		
		<cfreturn stResult />
	</cffunction>
	
	<cffunction name="logToRaygun" access="public" output="false" returntype="void" hint="Logs data to the couchdb">
		<cfargument name="type" type="string" required="true" hint="Log type" />
		<cfargument name="data" type="struct" requried="true" hint="A normalized error struct as produced by the core error library" />

		<cftry>
			<cfset var apiKey = application.fapi.getConfig("raygun", "apiKey", "") />
			<cfcatch>
				<cfset var apiKey = "" />
			</cfcatch>
		</cftry>
		
		
		<cfif len(apiKey)>
			<cfthread action="run" name="log-error-#createuuid()#" data="#arguments.data#" apiKey="#apiKey#" headers="#getHttpRequestData().headers#">
				<cfset system = createObject("java", "java.lang.System") />
				<cfset props = system.getProperties() />
				<cfset mf = createObject("java", "java.lang.management.ManagementFactory") />
				<cfset osbean = mf.getOperatingSystemMXBean() />
				<cfset oFile = createObject("java", "java.io.File") />
				<cfset aRoots = oFile.listRoots() />
				<cfset runtime = CreateObject("java","java.lang.Runtime").getRuntime()>
				
				<cfset stMessage["occurredOn"] = dateformat(attributes.data.datetime,"yyyy-mm-dd") & "T" & timeformat(attributes.data.datetime,"HH:mm:ss") & "Z" />
				<cfset stMessage["details"] = structnew() />
				<cfset stMessage["details"]["machineName"] = attributes.data.machinename />
				<cfset stMessage["details"]["version"] = JavaCast("null","") />
				<cfset stMessage["details"]["client"] = structnew() />
				<cfset stMessage["details"]["client"]["name"] = JavaCast("null","") />
				<cfset stMessage["details"]["client"]["version"] = JavaCast("null","") />
				<cfset stMessage["details"]["client"]["clientUrl"] = JavaCast("null","") />
				<cfset stMessage["details"]["error"] = structnew() />
				<cfset stMessage["details"]["error"]["innerError"] = JavaCast("null","") />
				<cfset stMessage["details"]["error"]["data"] = structnew() />
				<cfif structKeyExists(attributes.data, "type") and len(attributes.data.type)>
					<cfset stMessage["details"]["error"]["data"]["type"] = attributes.data.type />
				</cfif>
				<cfif structKeyExists(attributes.data, "errorcode") and len(attributes.data.errorcode)>
					<cfset stMessage["details"]["error"]["data"]["errorcode"] = attributes.data.errorcode />
				</cfif>
				<cfif structKeyExists(attributes.data, "detail") and len(attributes.data.detail)>
					<cfset stMessage["details"]["error"]["data"]["detail"] = attributes.data.detail />
				</cfif>
				<cfif structKeyExists(attributes.data, "queryError") and len(attributes.data.queryError)>
					<cfset stMessage["details"]["error"]["data"]["queryError"] = attributes.data.queryError />
				</cfif>
				<cfif structKeyExists(attributes.data, "sql") and len(attributes.data.sql)>
					<cfset stMessage["details"]["error"]["data"]["sql"] = attributes.data.sql />
				</cfif>
				<cfif structKeyExists(attributes.data, "where") and len(attributes.data.where)>
					<cfset stMessage["details"]["error"]["data"]["where"] = attributes.data.where />
				</cfif>
				<cfset stMessage["details"]["error"]["className"] = JavaCast("null","") />
				<cfset stMessage["details"]["error"]["message"] = attributes.data.message />
				<cfset stMessage["details"]["error"]["stackTrace"] = arraynew(1) />
				<cfloop from="1" to="#arraylen(attributes.data.stack)#" index="i">
					<cfset stSub = structnew() />
					<cfset stSub["lineNumber"] = attributes.data.stack[i].line />
					<cfset stSub["className"] = JavaCast("null","") />
					<cfset stSub["fileName"] = attributes.data.stack[i].template />
					<cfset arrayappend(stMessage["details"]["error"]["stackTrace"],stSub) />
				</cfloop>
				<cfset stMessage["details"]["environment"] = structnew() />
				<cfset stMessage["details"]["environment"]["processorCount"] = osbean.getAvailableProcessors() />
				<cfset stMessage["details"]["environment"]["osVersion"] = props["os.name"] & "|" & props["os.version"] />
				<cfset stMessage["details"]["environment"]["windowBoundsWidth"] = JavaCast("null","") />
				<cfset stMessage["details"]["environment"]["windowBoundsHeight"] = JavaCast("null","") />
				<cfset stMessage["details"]["environment"]["resolutionScale"] = JavaCast("null","") />
				<cfset stMessage["details"]["environment"]["currentOrientation"] = JavaCast("null","") />
				<cfset stMessage["details"]["environment"]["packageVersion"] = props["java.vm.vendor"] & "|" & props["java.runtime.version"] & "|" & props["java.vm.name"] />
				<cfset stMessage["details"]["environment"]["architecture"] = props["os.arch"] />
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
				<cfset stMessage["details"]["userCustomData"]["instanceName"] = attributes.data.instanceName />
				<cfif isdefined("application.plugins")>
					<cfset stMessage["details"]["userCustomData"]["plugins"] = application.plugins />
				</cfif>
				<cfif isdefined("application.fcstats.updateapp")>
					<cfset stMessage["details"]["userCustomData"]["appStart"] = dateformat(application.fcstats.updateapp.when[application.fcstats.updateapp.recordcount],"yyyy-mm-dd") & "T" & timeformat(application.fcstats.updateapp.when[application.fcstats.updateapp.recordcount],"HH:mm:ss") & "Z" />
				</cfif>
				<cfif structKeyExists(attributes.data, "extended_info") and len(attributes.data.extended_info)>
					<cfset stMessage["details"]["userCustomData"]["extended_info"] = attributes.data.extended_info />
				</cfif>
				<cfset stMessage["details"]["request"] = structnew() />
				<cfset stMessage["details"]["request"]["hostName"] = attributes.data.host />
				<cfset stMessage["details"]["request"]["url"] = attributes.data.scriptname />
				<cfset stMessage["details"]["request"]["httpMethod"] = CGI.REQUEST_METHOD />
				<cfset stMessage["details"]["request"]["iPAddress"] = arguments.data.remoteaddress />
				<cfset stMessage["details"]["request"]["queryString"] = arguments.data.querystring />
				<cfset stMessage["details"]["request"]["userAgent"] = CGI.HTTP_USER_AGENT />
				<cfset stMessage["details"]["request"]["form"] = structnew() />
				<cfloop collection="#form#" item="key">
					<cfif key neq "fieldnames">
						<cfif isSensitiveName(key)>
							<cfset stMessage["details"]["request"]["form"][key] = "[removed]" />
						<cfelse>
							<cfset stMessage["details"]["request"]["form"][key] = left(form[key],256) />
						</cfif>
					</cfif>
				</cfloop>
				<cfset stMessage["details"]["request"]["headers"] = filterSensitive(attributes.headers) />
				<cfset stMessage["details"]["request"]["data"] = filterSensitive(CGI) />
				<cfset stMessage["details"]["request"]["raw"] = JavaCast("null","") />
				<cfset stMessage["details"]["request"]["rawData"] = filterRequestBody(getHTTPRequestData().content, CGI.CONTENT_TYPE) />
				<cfset stMessage["details"]["request"]["session"] = arguments.data.session />
				<cfset stMessage["details"]["user"] = structnew() />
				<cfset stMessage["details"]["user"]["identifier"] = arguments.data.username />
				
				<cfhttp url="https://api.raygun.io/entries" method="post" charset="utf-8" timeout="0">
					<cfhttpparam type="header" name="Content-Type" value="application/json"/>
					<cfhttpparam type="header" name="X-ApiKey" value="#attributes.apiKey#"/>
					<cfhttpparam type="body" value="#serializeJSON(stMessage)#" />
				</cfhttp>
			</cfthread>
		</cfif>
	</cffunction>

	<cffunction name="isSensitiveName" access="public" output="false" returntype="boolean" hint="True when a form field, header, CGI or JSON key name suggests its value is a credential">
		<cfargument name="name" type="string" required="true" />

		<cfreturn reFindNoCase("password|secret|token|otp|recovery|code$|apikey|accesskey|signingkey|encryptkey|executionkey|cookie|authorization|cfid|sessionid", arguments.name) gt 0 />
	</cffunction>

	<cffunction name="filterSensitive" access="public" output="false" returntype="any" hint="Returns a copy of a struct (or scope) or array with the values of sensitive names replaced, at any depth">
		<cfargument name="data" type="any" required="true" />

		<cfset var result = "" />
		<cfset var key = "" />
		<cfset var i = 0 />

		<cfif isstruct(arguments.data)>
			<cfset result = structnew() />
			<cfloop collection="#arguments.data#" item="key">
				<cfif isSensitiveName(key)>
					<cfset result[key] = "[removed]" />
				<cfelseif structkeyexists(arguments.data, key)>
					<cfset result[key] = filterSensitive(arguments.data[key]) />
				</cfif>
			</cfloop>
		<cfelseif isarray(arguments.data)>
			<cfset result = arraynew(1) />
			<cfloop from="1" to="#arraylen(arguments.data)#" index="i">
				<cfif arrayisdefined(arguments.data, i)>
					<cfset arrayappend(result, filterSensitive(arguments.data[i])) />
				</cfif>
			</cfloop>
		<cfelse>
			<cfset result = arguments.data />
		</cfif>

		<cfreturn result />
	</cffunction>

	<cffunction name="filterRequestBody" access="public" output="false" returntype="any" hint="Returns the raw request body with sensitive values replaced: url-encoded and JSON bodies are filtered, multipart and unparseable bodies are replaced, other types are unchanged">
		<cfargument name="content" type="any" required="true" />
		<cfargument name="contentType" type="string" required="true" />

		<cfset var aPairs = arraynew(1) />
		<cfset var pair = "" />

		<cfif findnocase("multipart/", arguments.contentType)>
			<cfreturn "[removed: multipart, see form]" />
		</cfif>

		<cfif not issimplevalue(arguments.content) or not len(arguments.content)>
			<cfreturn arguments.content />
		</cfif>

		<cftry>
			<cfif findnocase("application/x-www-form-urlencoded", arguments.contentType)>
				<cfloop list="#arguments.content#" index="pair" delimiters="&">
					<cfif isSensitiveName(urldecode(listfirst(pair, "=")))>
						<cfset arrayappend(aPairs, listfirst(pair, "=") & "=[removed]") />
					<cfelse>
						<cfset arrayappend(aPairs, pair) />
					</cfif>
				</cfloop>
				<cfreturn arraytolist(aPairs, "&") />
			</cfif>

			<cfif findnocase("json", arguments.contentType)>
				<cfreturn serializeJSON(filterSensitive(deserializeJSON(arguments.content))) />
			</cfif>

			<cfcatch>
				<cfreturn "[removed: could not be filtered]" />
			</cfcatch>
		</cftry>

		<cfreturn arguments.content />
	</cffunction>

	<cffunction name="getSession" access="public" output="false" returntype="struct" hint="Returns the session in a flattened-to-dot-notation struct">
		<cfargument name="varstem" type="string" required="false" default="" />
		<cfargument name="base" type="any" required="false" />
		<cfargument name="result" type="struct" required="false" default="#structnew()#" />
		<cfargument name="depth" type="numeric" required="false" default="0" />

		<cfset var key = "" />
		<cfset var stem = "" />
		<!--- never collected: noise or bulk, personal details, session identifiers and transient authorization state --->
		<cfset var lSkipKeys = "Tempobjectstore,Objectadminfilterobjects,Urltoken,Objectadmin,Writingdir,Dmsec.AUTHENTICATION,Sessionid,Userlanguage,cfid,cftoken,jsessionid,fc.directUploads,fc.mfaPending,fc.stMFAEnrol,resetPWUserID,stFarCryFormSpamProtection,dmProfile.phone,dmProfile.fax" />

		<cfif not structkeyexists(arguments, "base")>
			<cfif isdefined("session") AND arguments.depth eq 0>
				<cfset arguments.base = session />
			<cfelse>
				<cfreturn arguments.result />
			</cfif>
		</cfif>

		<cfif issimplevalue(arguments.base)>
			<cfset arguments.result[arguments.varstem] = arguments.base />
		<cfelseif isstruct(arguments.base)>
			<cfloop collection="#arguments.base#" item="key">
				<!--- sessions.<id> holds whole sessions parked by switchSession(), so skip the same keys inside each one --->
				<cfif not listfindnocase(lSkipKeys,listappend(arguments.varstem,key,".")) and not listfindnocase(lSkipKeys,reReplaceNoCase(listappend(arguments.varstem,key,"."),"^sessions\.[^.]+\.",""))>
					<cfif NOT isNull(arguments.base[key])>
						<cfset getSession(listappend(arguments.varstem,key,"."),arguments.base[key],arguments.result,arguments.depth+1) />
					</cfif>
				</cfif>
			</cfloop>
		<cfelseif isarray(arguments.base)>
			<cfloop from="1" to="#arraylen(arguments.base)#" index="key">
				<cfif NOT isNull(arguments.base[key])>
					<cfset getSession(arguments.varstem & "[" & key & "]",arguments.base[key],arguments.result,arguments.depth+1) />
				</cfif>
			</cfloop>
		</cfif>
		
		<cfreturn arguments.result />
	</cffunction>
	
	
	<cffunction name="logData" access="public" output="false" returntype="void" hint="Logs error to application and exception log files">
		<cfargument name="log" type="struct" required="true" />
		<cfargument name="bApplication" type="boolean" required="false" default="true" />
		<cfargument name="bException" type="boolean" required="false" default="true" />
		<cfargument name="bCouch" type="boolean" required="false" default="true" />
		
		<cfset var errorJSON = "" />
		<cfset var logtype = "error" />
		<cfset var key = hash(arguments.log.message) />
		
		<cfif structkeyexists(arguments.log,"logtype")>
			<cfset logtype = arguments.log.logtype />
			<cfset structdelete(arguments.log,"logtype") />
		</cfif>

		<cfset super.logData(argumentCollection=arguments) />
		
		<cfparam name="request.loggedToRaygun" default="" />

		<cfif logtype eq "error" and not listfind(request.loggedToRaygun, key)>
			<cfset logToRaygun(logType, arguments.log) />
			<cfset request.loggedToRaygun = listAppend(request.loggedToRaygun, key) />
		</cfif>
	</cffunction>
	
</cfcomponent>
