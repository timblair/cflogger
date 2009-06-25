<!--- -->
<fusedoc fuse="cflogger/core/LogLevels.cfc" language="ColdFusion" specification="2.0">
	<responsibilities>
		A nice little collection of log levels
	</responsibilities>
</fusedoc>
--->

<cfcomponent output="false" hint="A nice little collection of log levels">

	<!--- define constants --->
	<cfscript>
		this.DEBUG = 1;
		this.INFO  = 2;
		this.WARN  = 3;
		this.ERROR = 4;
		this.FATAL = 5;
	</cfscript>

</cfcomponent>