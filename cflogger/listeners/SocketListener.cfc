<!--- -->
<fusedoc fuse="cflogger/listeners/SocketListener.cfc" language="ColdFusion" specification="2.0">
	<responsibilities>
		I am a log listener that logs all messages to a socket
	</responsibilities>
</fusedoc>
--->

<cfcomponent extends="cflogger.core.AbstractListener" output="false" hint="I am a log listener that logs all messages to a socket">

	<!--- instance variables --->
	<cfscript>
		// placeholder for the persistent socket connection
		variables.connection = createobject("component", "cflogger.util.SocketConnection");
		// configuration options
		variables.host       = "";    // the host / IP to connect to
		variables.port       = 0;     // the port number to connect to
		variables.timeout    = 5;     // how long to wait (in seconds) for a socket connection
		variables.persistent = TRUE;  // use persistent socket connections?
		variables.terminator = "";    // an optional line terminator / separator
	</cfscript>

	<!--- function for setting up the listener --->
	<cffunction name="init" access="public" returntype="cflogger.listeners.SocketListener" output="no" hint="Initialises this listener">
		<cfargument name="level" type="numeric" required="yes" hint="The level above whic to log messages">
		<cfargument name="host" type="string" required="yes" hint="The hostname to connect to">
		<cfargument name="port" type="string" required="yes" hint="The port number to connect to">
		<cfargument name="timeout" type="numeric" required="no" default="5" hint="How long to wait (in seconds) for a socket connection.">
		<cfargument name="persistent" type="boolean" required="no" default="TRUE" hint="Use persistent socket connections?">
		<cfargument name="terminator" type="string" required="no" default="#chr(10)#" hint="An optional line terminator">
		<!--- do the parent class stuff --->
		<cfset super.init(arguments.level)>
		<!--- store the config options options --->
		<cfset variables.host       = arguments.host>
		<cfset variables.port       = javacast("int", arguments.port)>
		<cfset variables.timeout    = javacast("int", arguments.timeout * 1000)>
		<cfset variables.persistent = arguments.persistent>
		<cfset variables.terminator = arguments.terminator>
		<!--- return our lovely horse, er, object --->
		<cfreturn this>
	</cffunction>

	<!--- function to be run as a callback when a listener has been registered with a logged --->
	<cffunction name="on_register" access="public" returntype="void" output="yes" hint="Run when a listener is registered with a logger.">
		<!--- nothing much to do: connect if we're using persistent connections and that's it --->
		<cfif variables.persistent>
			<!--- this will unregister automatically if there's a problem --->
			<cftry>
				<!--- initialise the connection object --->
				<cfset variables.connection = get_connection()>
				<!--- catch any problems and unregister --->
				<cfcatch type="any">
					<!--- unregister this listener cos we can't use it! --->
					<cfset variables.logger.unregister_listener(this, "Could not connect to socket at #variables.host#:#variables.port# : #cfcatch.message#.")>
				</cfcatch>
			</cftry>
		</cfif>
	</cffunction>

	<!--- function for performing the logging of a message --->
	<cffunction name="write" access="private" returntype="void" output="no" hint="Handles the general writing of ">
		<cfargument name="level" type="numeric" required="yes" hint="The log level of this message">
		<cfargument name="message" type="string" required="yes" hint="The message to log">
		<!--- localise vars --->
		<cfset var conn = "">

		<!--- start building up the message string --->
		<cfset var msg = variables.logger.getName() & " ">
		<cfswitch expression="#arguments.level#">
			<cfcase value="1"><cfset msg = msg & "DEBUG"></cfcase>
			<cfcase value="2"><cfset msg = msg & "INFO"></cfcase>
			<cfcase value="3"><cfset msg = msg & "WARN"></cfcase>
			<cfcase value="4"><cfset msg = msg & "ERROR"></cfcase>
			<cfcase value="5"><cfset msg = msg & "FATAL"></cfcase>
		</cfswitch>
		<cfset msg = msg & ": " & arguments.message>

		<!--- wrap up the write in case of failure --->
		<cftry>
			<!--- if we're persisting, use the existing connection --->
			<cfif variables.persistent><cfset conn = variables.connection><cfelse><cfset conn = get_connection()></cfif>
			<!--- write the message --->
			<cfset conn.write(msg)>
			<!--- close the connection if needed --->
			<cfif NOT variables.persistent><cfset conn.close()></cfif>
			<!--- catch any problem --->
			<cfcatch type="any">
				<!--- unregister this listener cos we can't use it! --->
				<cfset variables.logger.unregister_listener(this, "Error writing to socket at #variables.host#:#variables.port# : #cfcatch.type# : #cfcatch.message# : #cfcatch.detail#.")>
				<cfrethrow>
			</cfcatch>
		</cftry>
	</cffunction>

	<!--- function for connecting to the socket --->
	<cffunction name="get_connection" access="public" returntype="cflogger.util.SocketConnection" output="no" hint="Opens a socket connection">
		<cfreturn createobject("component", "cflogger.util.SocketConnection").init(
			host       = variables.host,
			port       = variables.port,
			timeout    = variables.timeout,
			terminator = variables.terminator,
			connect    = TRUE
		)>
	</cffunction>

</cfcomponent>