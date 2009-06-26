<!--- -->
<fusedoc fuse="cflogger/util/SocketConnection.cfc" language="ColdFusion" specification="2.0">
	<responsibilities>
		I am a simple object that creates and represents a socket connection
	</responsibilities>
</fusedoc>
--->

<cfcomponent output="false" hint="I am an object that creates and represents a socket connection">

	<!--- instance variables --->
	<cfscript>
		// connection objects
		variables.socket     = "";    // placeholder for the socket object to use
		variables.writer     = "";    // the writer for the socket
		// configuration options
		variables.host       = "";    // the host / IP to connect to
		variables.port       = "";    // the port number to connect to
		variables.timeout    = 5;     // how long to wait (in seconds) for a socket connection
		variables.terminator = "";    // an optional line terminator / separator
		// current status
		variables.connected  = FALSE;
	</cfscript>

	<!--- function for setting up the listener --->
	<cffunction name="init" access="public" returntype="cflogger.util.SocketConnection" output="no" hint="Initialises this connection">
		<cfargument name="host" type="string" required="yes" hint="The hostname to connect to">
		<cfargument name="port" type="string" required="yes" hint="The port number to connect to">
		<cfargument name="timeout" type="numeric" required="no" default="5" hint="How long to wait (in seconds) for a socket connection.">
		<cfargument name="terminator" type="string" required="no" default="#chr(10)#" hint="An optional line terminator">
		<cfargument name="connect" type="boolean" required="no" default="FALSE" hint="Should we attempt to connect immediately">
		<!--- record the options --->
		<cfset variables.host       = arguments.host>
		<cfset variables.port       = javacast("int", arguments.port)>
		<cfset variables.timeout    = javacast("int", arguments.timeout * 1000)>
		<cfset variables.terminator = arguments.terminator>
		<!--- open the connection if required --->
		<cfif arguments.connect><cfset open()></cfif>
		<!--- return our lovely horse, er, object --->
		<cfreturn this>
	</cffunction>

	<!--- function for writing to the socket --->
	<cffunction name="write" access="public" returntype="void" output="no" hint="Writes a single line to the socket">
		<cfargument name="msg" type="string" required="yes" hint="The line to write to the socket">
		<!--- only write if the connection is open --->
		<cfif variables.connected>
			<cfset variables.writer.print(arguments.msg & variables.terminator)>
			<cfset variables.writer.flush()>
		</cfif>
	</cffunction>

	<!--- function for connecting to the socket --->
	<cffunction name="open" access="public" returntype="void" output="no" hint="Connects to the socket">
		<cfset variables.socket = createObject("java", "java.net.Socket").init(variables.host, variables.port)>
		<cfset variables.socket.setSoTimeout(variables.timeout)>
		<cfset variables.writer = createObject("java", "java.io.PrintStream").init(variables.socket.getOutputStream(), FALSE)>
		<cfset variables.connected = TRUE>
	</cffunction>

	<!--- function for closing the print stream --->
	<cffunction name="close" access="public" returntype="void" output="no" hint="Closes the connection">
		<cfset variables.connected = FALSE>
		<cfset variables.writer.close()>
		<cfset variables.socket.close()>
	</cffunction>

</cfcomponent>