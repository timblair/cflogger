<!--- -->
<fusedoc fuse="cflogger/listeners/DBListener.cfc" language="ColdFusion" specification="2.0">
	<responsibilities>
		I am a log listener that logs all messages to a database
	</responsibilities>
</fusedoc>
--->

<cfcomponent extends="cflogger.core.AbstractListener" output="false" hint="I am a log listener that logs all messages to a database.  Currently MySQL only when <em>initchecks</em> is specified.">

	<!--- instance variables --->
	<cfscript>
		variables.dsn       = "";                            // datasource to write to
		variables.table     = "logger";                      // database log table
		variables.cols      = "logger,level,message,stamp";  // default column names
		variables.leveltype = "string";                      // we store the level type as a string
		// initialisation variables
		variables.initchecks = FALSE;   // should we run init checks like "does the DSN exist"
		variables.autocreate = FALSE;   // if the log table doesn't exist, should we try and create it?'
	</cfscript>

	<!--- function for setting up the listener --->
	<cffunction name="init" access="public" returntype="cflogger.listeners.DBListener" output="no" hint="Initialises this listener">
		<cfargument name="level" type="numeric" required="yes" hint="The level above whic to log messages">
		<cfargument name="dsn" type="string" required="yes" hint="The datasource to write to">
		<cfargument name="table" type="string" required="no" default="logger" hint="The table name to log messages to">
		<cfargument name="cols" type="string" required="no" default="logger,level,message,stamp" hint="The list of columns to write to, in the following order: logger name, log level, message, time stamp">
		<cfargument name="leveltype" type="string" required="no" default="string" hint="Should we store the level as a string or a numeric value?  Default is 'string'.  For numeric values this should be 'numeric'">
		<cfargument name="initchecks" type="boolean" required="no" default="FALSE" hint="Should initialisation checks be run?  Does clever things like checking the DSN exists and can be written to etc...">
		<cfargument name="autocreate" type="boolean" required="no" default="FALSE" hint="Should we try and automatically create the appropriate table if it doesn't already exist?  Also requires <em>initchecks</em> to be true">

		<!--- do the parent class stuff --->
		<cfset super.init(arguments.level)>

		<!--- record the database information --->
		<cfset variables.dsn = arguments.dsn>
		<cfset variables.table = arguments.table>
		<cfset variables.cols = arguments.cols>
		<cfset variables.leveltype = arguments.leveltype>
		<!--- checks and creation flags --->
		<cfset variables.initchecks = arguments.initchecks>
		<cfset variables.autocreate = arguments.autocreate>

		<!--- return our lovely horse, er, object --->
		<cfreturn this>
	</cffunction>

	<!--- function to be run as a callback when a listener has been registered with a logged --->
	<cffunction name="on_register" access="public" returntype="void" output="yes" hint="Run when a listener is registered with a logger">
		<!--- localise vars --->
		<cfset var datasources = CreateObject("java", "coldfusion.server.ServiceFactory").datasourceservice.getDatasources()>
		<cfset var q = "">
		<cfset var ds = "">

		<!--- don't do anything if we're not worried about the checks --->
		<cfif NOT variables.initchecks><cfreturn></cfif>

		<!--- check if the datasource exists --->
		<cfif NOT structkeyexists(datasources, variables.dsn)>
			<!--- unregister this listener cos we can't use it! --->
			<cfset variables.logger.unregister_listener(this, "Datasource #variables.dsn# cannot be found.")>
		</cfif>

		<!--- grab the appropriate datasource --->
		<cfset ds = datasources[variables.dsn]>

		<!--- check that we can read and write to it --->
		<cfif NOT (ds.select AND ds.insert)>
			<!--- unregister this listener cos we can't use it! --->
			<cfset variables.logger.unregister_listener(this, "Datasource #variables.dsn# does not have SELECT and/or INSERT permissions.")>
		</cfif>

		<!--- check if the table exists --->
		<cftry>
			<cfquery name="q" datasource="#variables.dsn#">
				SHOW TABLES LIKE <cfqueryparam cfsqltype="cf_sql_varchar" value="#variables.table#">
			</cfquery>
			<cfif NOT q.recordcount>
				<cfif variables.autocreate>
					<!--- do we have permission to create the table? --->
					<cfif NOT ds.create>
						<cfset variables.logger.unregister_listener(this, "Could not auto-create logger table #variables.table#: datasource #variables.dsn# does not have CREATE permissions.")>
					<cfelse>
						<cftry>
							<cfquery datasource="#variables.dsn#">
								CREATE TABLE #variables.table# (
									id integer UNSIGNED NOT NULL AUTO_INCREMENT,
									#listgetat(variables.cols, 1)# VARCHAR(20) NOT NULL,
									#listgetat(variables.cols, 2)# <cfif variables.leveltype EQ 'numeric'>TINYINT<cfelse>VARCHAR(5)</cfif> NOT NULL,
									#listgetat(variables.cols, 3)# TEXT,
									#listgetat(variables.cols, 4)# DATETIME NOT NULL,
									PRIMARY KEY (id)
								)
							</cfquery>
							<!--- any problems with the create we unregister --->
							<cfcatch type="database">
								<cfset variables.logger.unregister_listener(this, "Could not create table #variables.table# using datasource #variables.dsn#: #cfcatch.detail#.")>
							</cfcatch>
						</cftry>
					</cfif>
				<cfelse>
					<!--- unregister this listener cos we can't use it! --->
					<cfset variables.logger.unregister_listener(this, "Table #variables.table# does not exist.")>
				</cfif>
			</cfif>
			<!--- catch any problems --->
			<cfcatch type="database">
				<cfset variables.logger.unregister_listener(this, "Error checking table #variables.table# using datasource #variables.dsn#: #cfcatch.detail#.")>
			</cfcatch>
		</cftry>

	</cffunction>

	<!--- function for performing the logging of a message --->
	<cffunction name="write" access="private" returntype="void" output="no" hint="Performs the actual logging of this message.  Must be overwritten in the implementing class.">
		<cfargument name="level" type="numeric" required="yes" hint="The log level of this message">
		<cfargument name="message" type="string" required="yes" hint="The message to log">

		<!--- set the default type for the log level --->
		<cfset var type = "cf_sql_tinyint">

		<!--- if we're not using a numeric type then assume string --->
		<cfif variables.leveltype NEQ "numeric">
			<cfset type = "cf_sql_varchar">
			<cfswitch expression="#arguments.level#">
				<cfcase value="1"><cfset arguments.level = "DEBUG"></cfcase>
				<cfcase value="2"><cfset arguments.level = "INFO"></cfcase>
				<cfcase value="3"><cfset arguments.level = "WARN"></cfcase>
				<cfcase value="4"><cfset arguments.level = "ERROR"></cfcase>
				<cfcase value="5"><cfset arguments.level = "FATAL"></cfcase>
			</cfswitch>
		</cfif>

		<!--- write the log message to the DB --->
		<cfquery datasource="#variables.dsn#">
			INSERT INTO #variables.table# (#variables.cols#) VALUES (
				<cfqueryparam cfsqltype="cf_sql_varchar" value="#variables.logger.getName()#">,
				<cfqueryparam cfsqltype="#type#" value="#arguments.level#">,
				<cfqueryparam cfsqltype="cf_sql_longvarchar" value="#arguments.message#">,
				<cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">
			)
		</cfquery>
	</cffunction>

</cfcomponent>