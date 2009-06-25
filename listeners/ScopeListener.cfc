<!--- -->
<fusedoc fuse="cflogger/listeners/ScopeListener.cfc" language="ColdFusion" specification="2.0">
	<responsibilities>
		I am a log listener that logs all messages to a structure of arrays in a given scope
	</responsibilities>
</fusedoc>
--->

<cfcomponent extends="cflogger.core.AbstractListener" output="false" hint="I am a log listener that logs all messages to a structure of arrays in a given scope">

	<!--- instance variables --->
	<cfscript>
		variables.scope = "request";      // by default we log into the request scope
		variables.key   = "scopelister";  // unless we get a name, use the name from the Logger
		variables.limit = 0;              // by default we don't "rotate" the logs
	</cfscript>

	<!--- function for setting up the listener --->
	<cffunction name="init" access="public" returntype="cflogger.listeners.ScopeListener" output="no" hint="Initialises this listener">
		<cfargument name="level" type="numeric" required="yes" hint="The level above whic to log messages">
		<cfargument name="scope" type="string" required="no" default="request" hint="The scope to write to.  Note that this is not a reference: using a reference would defeat the purpose of using a scope such as request which is not persisted.">
		<cfargument name="key" type="string" required="no" default="scopelistener" hint="The key under which to store this information">
		<cfargument name="limit" type="numeric" required="no" default="0" hint="The maximum number of log messages to retain.  0 is unlimited.">
		<!--- first off we do anything that the parent class requires --->
		<cfset super.init(arguments.level)>
		<!--- and store the appropriate information --->
		<cfset variables.scope = arguments.scope>
		<cfset variables.key = arguments.key>
		<cfset variables.limit = arguments.limit>
		<!--- return the mighty object we've created --->
		<cfreturn this>
	</cffunction>

	<!--- function for performing the logging of a message --->
	<cffunction name="write" access="private" returntype="void" output="no" hint="Performs the actual logging of this message.  Must be overwritten in the implementing class.">
		<cfargument name="level" type="numeric" required="yes" hint="The log level of this message">
		<cfargument name="message" type="string" required="yes" hint="The message to log">
		<!--- localise vars --->
		<cfset var msg = structnew()>
		<cfset var i = 0>
		<cfset var j = 0>

		<!--- grab a reference to the appropriate scope --->
		<cfset var scope = evaluate(variables.scope)>

		<!--- make sure everything's set up correctly --->
		<cfparam name="#variables.scope#.#variables.key#" default="#arraynew(1)#">

		<!--- build up the "message" --->
		<cfset msg.app = variables.logger.getName()>
		<cfset msg.date = now()>
		<cfset msg.msg = arguments.message>
		<cfswitch expression="#arguments.level#">
			<cfcase value="1"><cfset msg.level = "DEBUG"></cfcase>
			<cfcase value="2"><cfset msg.level = "INFO"></cfcase>
			<cfcase value="3"><cfset msg.level = "WARN"></cfcase>
			<cfcase value="4"><cfset msg.level = "ERROR"></cfcase>
			<cfcase value="5"><cfset msg.level = "FATAL"></cfcase>
		</cfswitch>

		<!--- whack the new struct into the array --->
		<cfset arrayappend(scope[variables.key], msg)>

		<!--- "rotate" if necessary --->
		<cfif variables.limit AND arraylen(scope[variables.key]) GT variables.limit>
			<!--- remove the first item until we're done --->
			<cfset i = arraylen(scope[variables.key]) - variables.limit>
			<cfloop from="1" to="#i#" index="j">
				<cfset arraydeleteat(scope[variables.key], 1)>
			</cfloop>
		</cfif>
	</cffunction>

</cfcomponent>