<!--- -->
<fusedoc fuse="cflogger/core/Logger.cfc" language="ColdFusion" specification="2.0">
	<responsibilities>
		I am the main logger component - register listeners with me!
	</responsibilities>
</fusedoc>
--->

<cfcomponent output="false" hint="I am the main logger component - register listeners with me!">

	<!--- instance variables --->
	<cfscript>
		this.levels         = createobject("component", "cflogger.core.LogLevels");
		variables.name      = "default-" & FormatBaseN(CreateObject('java','java.lang.System').identityHashCode(this), 16);
		variables.listeners = arraynew(1);
	</cfscript>

	<!--- function for initing --->
	<cffunction name="init" access="public" returntype="cflogger.core.Logger" output="no" hint="Initialises this logger">
		<cfargument name="name" type="string" required="no" default="" hint="The name for this logger instance.  Defaults to <code>application.applicationname</code>, lowercased and stripped to alnum chars, if not provided; if no application name then uses a random generated string.">
		<cfif NOT len(arguments.name) AND isdefined("application.applicationname")>
			<cfset arguments.name = application.applicationname>
		</cfif>
		<cfif len(trim(arguments.name))>
			<cfset variables.name = arguments.name>
		</cfif>
		<!--- strip out any unwanted chars --->
		<cfset variables.name = rereplacenocase(variables.name, "[^0-9a-z]", "", "ALL")>
		<!--- return the lovely object --->
		<cfreturn this>
	</cffunction>

	<!--- function for retrieving this logger's name --->
	<cffunction name="getName" access="public" returntype="string" output="no" hint="Returns this loggers identifying name">
		<cfreturn variables.name>
	</cffunction>

	<!--- function for registering a listener with this logger --->
	<cffunction name="register_listener" access="public" returntype="void" output="no" hint="Registers a listener with this logger">
		<cfargument name="listener" type="cflogger.core.AbstractListener" required="yes" hint="The listener to register">
		<!--- localise vars --->
		<cfset var i = 0>
		<cfset var sys = CreateObject('java','java.lang.System')>
		<cfset var code = FormatBaseN(sys.identityHashCode(arguments.listener), 16)>
		<cfset var isreg = FALSE>
		<!--- check if this one is already registered --->
		<cfloop from="1" to="#arraylen(variables.listeners)#" index="i">
			<!--- check the memory hash of the passed in listener against each one --->
			<cfif code EQ FormatBaseN(sys.identityHashCode(variables.listeners[i]), 16)>
				<!--- record that we've found it --->
				<cfset isreg = TRUE>
				<!--- stop there --->
				<cfbreak>
			</cfif>
		</cfloop>
		<!--- only register this one if it's not already registered --->
		<cfif NOT isreg>
			<cfif arguments.listener.is_registered()>
				<cfset warn("Cannot register listener #getmetadata(arguments.listener).name#: already registered with logger '#arguments.listener.getLogger().getName()#'")>
			<cfelse>
				<cfset arguments.listener.setLogger(this)>
				<cfset arrayappend(variables.listeners, arguments.listener)>
				<!--- run the on_register callback to do any post-processing --->
				<cftry>
					<!--- in case this fails we'll wrap it up nicely --->
					<cfset arguments.listener.on_register()>
					<cfcatch type="any">
						<!--- remove the logger --->
						<cfset unregister_listener(listener, "Failure in on_register() callback.")>
						<!--- log a failure message to any existing listeners --->
						<cfset warn("Callback failure while registering listener #getmetadata(arguments.listener).name#: #cfcatch.detail#")>
					</cfcatch>
				</cftry>
			</cfif>
		</cfif>
	</cffunction>

	<!--- function for unregistering a listener from this logger --->
	<cffunction name="unregister_listener" access="public" returntype="void" output="no" hint="Unregisters a listener from this logger">
		<cfargument name="listener" type="cflogger.core.AbstractListener" required="yes" hint="The listener to register">
		<cfargument name="msg" type="string" required="no" hint="A message to log (WARN level) about why this listener has been unregistered">
		<!--- localise vars --->
		<cfset var i = 0>
		<cfset var sys = CreateObject('java','java.lang.System')>
		<cfset var code = FormatBaseN(sys.identityHashCode(arguments.listener), 16)>
		<!--- loop through each listener until we find this one --->
		<cfloop from="1" to="#arraylen(variables.listeners)#" index="i">
			<!--- check the memory hash of the passed in listener against each one --->
			<cfif code EQ FormatBaseN(sys.identityHashCode(variables.listeners[i]), 16)>
				<!--- unset the registration with this logger --->
				<cfset variables.listeners[i].unsetLogger()>
				<!--- remove this one if we've found it --->
				<cfset arraydeleteat(variables.listeners, i)>
				<!--- log a message if there is one --->
				<cfif isdefined("arguments.msg")><cfset warn("Unregistered listener #getmetadata(arguments.listener).name#: " & arguments.msg)></cfif>
				<!--- stop there --->
				<cfbreak>
			</cfif>
		</cfloop>
	</cffunction>

	<!--- function for returning the array of active listeners --->
	<cffunction name="get_listeners" access="public" returntype="array" output="no" hint="Retrieves the array of active listeners">
		<cfreturn variables.listeners>
	</cffunction>

	<!--- check if there are any listeners registered to this logger --->
	<cffunction name="has_listeners" access="public" returntype="boolean" output="no" hint="Checks to see if there are already any listeners assigned to this logger">
		<cfreturn NOT NOT arraylen(variables.listeners)>
	</cffunction>

	<!--- the various interface methods for different logging levels --->
	<cffunction name="debug" access="public" returntype="void" output="no" hint="Logs a DEBUG message">
		<cfargument name="message" type="any" required="yes" hint="The message to log">
		<cfset write(this.levels.DEBUG, arguments.message)>		
	</cffunction>
	
	<cffunction name="info" access="public" returntype="void" output="no" hint="Logs a INFO message">
		<cfargument name="message" type="any" required="yes" hint="The message to log">
		<cfset write(this.levels.INFO, arguments.message)>		
	</cffunction>
	
	<cffunction name="warn" access="public" returntype="void" output="no" hint="Logs a WARN message">
		<cfargument name="message" type="any" required="yes" hint="The message to log">
		<cfset write(this.levels.WARN, arguments.message)>		
	</cffunction>
	
	<cffunction name="error" access="public" returntype="void" output="no" hint="Logs a ERROR message">
		<cfargument name="message" type="any" required="yes" hint="The message to log">
		<cfset write(this.levels.ERROR, arguments.message)>		
	</cffunction>
	
	<cffunction name="fatal" access="public" returntype="void" output="no" hint="Logs a FATAL message">
		<cfargument name="message" type="any" required="yes" hint="The message to log">
		<cfset write(this.levels.FATAL, arguments.message)>		
	</cffunction>

	<!--- function for logging an actual message --->
	<cffunction name="write" access="private" returntype="void" output="no" hint="Sends an individual message to each of the registered listeners">
		<cfargument name="level" type="numeric" required="yes" hint="">
		<cfargument name="message" type="any" required="yes" hint="The message to log">
		<!--- localise vars --->
		<cfset var i = 0>
		<!--- if the message is not a simple value, JSON encode it --->
		<cfif NOT isSimpleValue(arguments.message)><cfset arguments.message = serializejson(arguments.message)></cfif>
		<!--- don't do anything if there's nothing to write --->
		<cfif NOT len(trim(arguments.message))><cfreturn></cfif>
		<!--- send the message to each listener --->
		<cfloop from="1" to="#arraylen(variables.listeners)#" index="i">
			<!--- wrap the actual log call up in case something fails --->
			<cftry>
				<cfset variables.listeners[i].write_filter(arguments.level, trim(arguments.message))>
				<!--- catch and ignore any errors to stop infinite loops caused by bubbling --->
				<cfcatch type="any"><cfrethrow></cfcatch>
			</cftry>
		</cfloop>
	</cffunction>

</cfcomponent>