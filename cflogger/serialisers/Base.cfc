<!--- -->
<fusedoc fuse="cflogger/serialisers/Base.cfc" language="ColdFusion" specification="2.0">
	<responsibilities>
		I am the base component that all serialisers must extend
	</responsibilities>
</fusedoc>
--->

<cfcomponent output="no" hint="A JSON serialiser for writing out data blobs as a JSON string">

	<cffunction name="serialise" access="public" returntype="string" output="no" hint="The serialiser function that will be called by the Logger instance when non-simple value data is to be logged">
		<cfargument name="data" type="any" required="yes" hint="The data structure to convert">
		<cfthrow type="CFLogger.InvalidSerialiser" message="serialise() must be implemented in #getmetadata(this).name#" detail="All serialisers must implement a serialise() function.">
	</cffunction>

</cfcomponent>
