<!--- -->
<fusedoc fuse="cflogger/listeners/TwitterListener.cfc" language="ColdFusion" specification="2.0">
	<responsibilities>
		I am a log listener that sends all messages to Twitter as status updates
	</responsibilities>
</fusedoc>
--->

<cfcomponent extends="cflogger.core.AbstractListener" output="false" hint="I am a log listener that sends all messages to Twitter as status updates">

	<!--- instance variables --->
	<cfscript>
		variables.user = "";    // the Twitter username to post as
		variables.pass = "";    // the password of the Twitter user we're posting as
	</cfscript>

	<!--- function for setting up the listener --->
	<cffunction name="init" access="public" returntype="cflogger.listeners.TwitterListener" output="no" hint="Initialises this listener">
		<cfargument name="level" type="numeric" required="yes" hint="The level above whic to log messages">
		<cfargument name="user" type="string" required="yes" hint="The Twitter username to post as">
		<cfargument name="pass" type="string" required="yes" hint="The password of the Twitter user we're posting as">
		<cfset super.init(arguments.level)>
		<cfset variables.user = arguments.user>
		<cfset variables.pass = arguments.pass>
		<cfreturn this>
	</cffunction>

	<!--- function to be run as a callback when a listener has been registered with a logger --->
	<cffunction name="on_register" access="public" returntype="void" output="yes" hint="Run when a listener is registered with a logger">
		<cfset var call = "">
		<cftry>
			<cfhttp url="http://twitter.com/account/verify_credentials.xml" method="GET" throwonerror="yes" username="#variables.user#" password="#variables.pass#" result="call">
			<cfif listfirst(call.statusCode, " ") NEQ 200>
				<cfset variables.logger.unregister_listener(this, "Could not verify Twitter credentials (got back status code #call.statusCode#)")>
			</cfif>
			<cfcatch type="any">
				<cfset variables.logger.unregister_listener(this, "Error verifying Twitter credentials: #cfcatch.detail#.")>
			</cfcatch>
		</cftry>
	</cffunction>

	<!--- function for performing the logging of a message --->
	<cffunction name="write" access="private" returntype="void" output="no" hint="Performs the actual logging of this message.">
		<cfargument name="level" type="numeric" required="yes" hint="The log level of this message">
		<cfargument name="message" type="string" required="yes" hint="The message to log">
		<cftry>
			<cfhttp url="http://twitter.com/statuses/update.xml" method="POST" throwonerror="yes" username="#variables.user#" password="#variables.pass#" result="call">
				<cfhttpparam type="formfield" name="status" value="#arguments.message#">
			</cfhttp>
			<cfcatch type="any">
				<cfset variables.logger.unregister_listener(this, "Error updating Twitter status: #cfcatch.detail#.")>
			</cfcatch>
		</cftry>
	</cffunction>

</cfcomponent>
