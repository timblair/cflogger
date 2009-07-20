<!--- -->
<fusedoc fuse="cflogger/serialisers/JSON.cfc" language="ColdFusion" specification="2.0">
	<responsibilities>
		I am a JSON serialiser for writing out data blobs as a JSON string
	</responsibilities>
</fusedoc>
--->

<cfcomponent extends="cflogger.serialisers.Base" output="no" hint="A JSON serialiser for writing out data blobs as a JSON string">

	<cffunction name="serialise" access="public" returntype="string" output="no" hint="Generates a JSON-encoded string representation of an arbitrary data blob">
		<cfargument name="data" type="any" required="yes" hint="The data structure to convert">
		<cfreturn serializejson(arguments.data)>
	</cffunction>

</cfcomponent>
