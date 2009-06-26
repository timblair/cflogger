<!--- -->
<fusedoc fuse="cflogger/core/AbstractListener.cfc" language="ColdFusion" specification="2.0">
	<responsibilities>
		I am the base listener component that all listeners should extend
	</responsibilities>
</fusedoc>
--->

<cfcomponent output="false" hint="I am the base listener component that all listeners should extend">

	<!--- instance variables --->
	<cfscript>
		variables.level = 0;
		variables.logger = createobject("component", "cflogger.core.Logger");
		variables.registered = FALSE;
	</cfscript>

	<!--- function for setting up the listener --->
	<cffunction name="init" access="public" returntype="cflogger.core.AbstractListener" output="no" hint="Initialises this listener">
		<cfargument name="level" type="numeric" required="yes" hint="The level above whic to log messages">
		<!--- this is an 'abstract' class and cannot be used as an actual implementation --->
		<cfif getmetadata(this).name EQ "cflogger.core.AbstractListener">
			<cfthrow message="The #getmetadata(this).name# component must be extended to provide a concrete log listener implementation.">
		</cfif>
		<cfset variables.level = arguments.level>
		<cfreturn this>
	</cffunction>

	<!--- function to be run as a callback when a listener has been registered with a logged --->
	<cffunction name="on_register" access="public" returntype="void" output="no" hint="Run when a listener is registered with a logger.">
	</cffunction>

	<!--- function for setting the logger that this listener is registered with --->
	<cffunction name="setLogger" access="public" returntype="void" output="no" hint="Set the logger that this listener is registered with">
		<cfargument name="logger" type="cflogger.core.Logger" required="yes" hint="The logger">
		<cfset variables.logger = arguments.logger>
		<cfset variables.registered = TRUE>
	</cffunction>

	<!--- function for getting the logger --->
	<cffunction name="getLogger" access="public" returntype="cflogger.core.Logger" output="no" hint="Return the logger that this listener is registered with">
		<cfreturn variables.logger>
	</cffunction>

	<!--- function for un-setting the logger that this listener is registered with --->
	<cffunction name="unsetLogger" access="public" returntype="void" output="no" hint="Un-set the logger from this listener">
		<cfset variables.logger = createobject("component", "cflogger.core.Logger")>
		<cfset variables.registered = FALSE>
	</cffunction>

	<!--- function for checking if this listener is already registered to a logger --->
	<cffunction name="is_registered" access="public" returntype="boolean" output="no" hint="Is this listener already registered to a logger?">
		<cfreturn variables.registered>
	</cffunction>

	<!--- function for logging an actual message --->
	<cffunction name="write_filter" access="public" returntype="void" output="no" hint="Sends an individual message to each of the registered listeners">
		<cfargument name="level" type="numeric" required="yes" hint="The log level of this message">
		<cfargument name="message" type="string" required="yes" hint="The message to log">
		<!--- only do something if we're at the right level --->
		<cfif arguments.level GTE variables.level><cfset write(argumentcollection=arguments)></cfif>
	</cffunction>

	<!--- function for performing the logging of a message --->
	<cffunction name="write" access="private" returntype="void" output="no" hint="Performs the actual logging of this message.  Must be overwritten in the implementing class.">
		<cfargument name="level" type="numeric" required="yes" hint="The log level of this message">
		<cfargument name="message" type="string" required="yes" hint="The message to log">
		<cfthrow type="Listener.NotImplemented" message="This log listener (#getmetadata(this).name#) must implement the write() method.">
	</cffunction>

</cfcomponent>