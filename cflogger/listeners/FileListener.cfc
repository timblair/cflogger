<!--- -->
<fusedoc fuse="cflogger/listeners/FileListener.cfc" language="ColdFusion" specification="2.0">
	<responsibilities>
		I am a log listener that logs all messages to a file
	</responsibilities>
</fusedoc>
--->

<cfcomponent extends="cflogger.core.AbstractListener" output="false" hint="I am a log listener that logs all messages to a file">

	<!--- instance variables --->
	<cfscript>
		variables.path = getTempDirectory();    // by default we store logs in the temp dir
		variables.file = "";                    // unless we get a name, use the name from the Logger
	</cfscript>

	<!--- function for setting up the listener --->
	<cffunction name="init" access="public" returntype="cflogger.listeners.FileListener" output="no" hint="Initialises this listener">
		<cfargument name="level" type="numeric" required="yes" hint="The level above whic to log messages">
		<cfargument name="file" type="string" required="no" default="" hint="The filename to write to.  If left blank, will use the name of the Logger">
		<cfargument name="path" type="string" required="no" default="#getTempDirectory()#" hint="The path to write the log file to">
		<!--- do the parent class stuff --->
		<cfset super.init(arguments.level)>
		<!--- record the path --->
		<cfset variables.path = arguments.path>
		<!--- and the file --->
		<cfset variables.file = arguments.file>
		<!--- return our lovely horse, er, object --->
		<cfreturn this>
	</cffunction>

	<!--- function to be run as a callback when a listener has been registered with a logged --->
	<cffunction name="on_register" access="public" returntype="void" output="yes" hint="Run when a listener is registered with a logger">
		<!--- localise vars --->
		<cfset var logfile = variables.path & "/" & variables.file & ".log">
		<!--- check for any failures to create/write --->
		<cftry>
			<!--- check the path exists: create it if not --->
			<cfif NOT directoryexists(variables.path)><cfdirectory action="create" directory="#variables.path#"></cfif>
			<!--- check if the file exists and we can write to it --->
			<cfif fileexists(logfile) AND NOT createobject("java", "java.io.File").init(logfile).canWrite()>
				<cfthrow detail="File exists but is not writeable">
			<cfelseif NOT fileexists(logfile)>
				<!--- try and create the log file --->
				<cffile action="write" file="#logfile#" output="">
			</cfif>
			<!--- catch any problem --->
			<cfcatch type="Application">
				<!--- unregister this listener cos we can't use it! --->
				<cfset variables.logger.unregister_listener(this, "Could not write to log file at #variables.path & '/' & variables.file#.log: #cfcatch.detail#.")>
			</cfcatch>
		</cftry>
	</cffunction>

	<!--- function for performing the logging of a message --->
	<cffunction name="write" access="private" returntype="void" output="no" hint="Performs the actual logging of this message.  Must be overwritten in the implementing class.">
		<cfargument name="level" type="numeric" required="yes" hint="The log level of this message">
		<cfargument name="message" type="string" required="yes" hint="The message to log">
		<!--- nice and easy: simply append a string to a file --->
		<cfset var msg = "[" & lsdateformat(now(), "yyyy-mm-dd") & " " & timeformat(now(), "HH:mm:ss") & "] ">
		<cfset msg = msg & variables.logger.getName() & " ">
		<cfswitch expression="#arguments.level#">
			<cfcase value="1"><cfset msg = msg & "DEBUG"></cfcase>
			<cfcase value="2"><cfset msg = msg & "INFO"></cfcase>
			<cfcase value="3"><cfset msg = msg & "WARN"></cfcase>
			<cfcase value="4"><cfset msg = msg & "ERROR"></cfcase>
			<cfcase value="5"><cfset msg = msg & "FATAL"></cfcase>
		</cfswitch>
		<cfset msg = msg & " " & arguments.message>
		<!--- work out which log file we're writing to (default to the logger name) --->
		<cfif NOT len(variables.file)><cfset variables.file = variables.logger.getName()></cfif>
		<!--- wrap up the write in case of failure --->
		<cftry>
			<!--- lock the write so we're not going to overwrite/corrupt --->
			<cflock type="exclusive" name="filelistener-#variables.file#" timeout="3" throwontimeout="no">
				<cffile action="append" file="#variables.path & '/' & variables.file#.log" output="#msg#">
			</cflock>
			<!--- catch any problem --->
			<cfcatch type="Application">
				<!--- unregister this listener cos we can't use it! --->
				<cfset variables.logger.unregister_listener(this, "Could not write to log file at #variables.path & '/' & variables.file#.log: #cfcatch.detail#.")>
			</cfcatch>
		</cftry>
	</cffunction>

</cfcomponent>