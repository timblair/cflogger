<!--- -->
<fusedoc fuse="cflogger/serialisers/YAML.cfc" language="ColdFusion" specification="2.0">
	<responsibilities>
		I am a YAML serialiser for writing out data blobs as a YAML string
	</responsibilities>
</fusedoc>
--->

<cfcomponent extends="cflogger.serialisers.Base" output="no" hint="A YAML serialiser for writing out data blobs as a YAML string">

	<cffunction name="serialise" access="public" returntype="string" output="no" hint="Generates a YAML-encoded string representation of an arbitrary data blob">
		<cfargument name="data" type="any" required="yes" hint="The data structure to convert">
		<cfargument name="indent" type="numeric" required="no" default="0" hint="Internal indentation level">
		<cfset var local = structnew()>

		<!--- work out any indentation --->
		<cfset local.sp = repeatstring('  ', arguments.indent)>
		<!--- empty string to build up --->
		<cfset local.yaml = "">
		<!--- we need to know if it's not been handled --->
		<cfset local.same_line = FALSE>

		<!--- SCALARS (SIMPLE VALUES) --->
		<cfif isSimpleValue(arguments.data)>
			<!--- MULTI-LINE --->
			<cfif find(chr(10), arguments.data)>
				<cfreturn "|" & replace("#chr(10)##trim(arguments.data)#", chr(10), chr(10) & local.sp, "ALL")>
			<!--- SINGLE LINE --->
			<cfelse>
				<cfreturn arguments.data>
			</cfif>

		<!--- ARRAYS --->
		<cfelseif isArray(arguments.data)>
			<cfif arraylen(arguments.data)>
				<cfloop from="1" to="#arraylen(arguments.data)#" index="local.i">
					<cfset local.yaml = local.yaml & local.sp & "- " & serialise(arguments.data[local.i], arguments.indent + 1) & chr(10)>
				</cfloop>
			<cfelse>
				<cfset local.same_line = TRUE>
				<cfset local.yaml = "[EMPTY ARRAY]">
			</cfif>

		<!--- OBJECTS --->
		<cfelseif isObject(arguments.data)>
			<cfset local.same_line = TRUE>
			<!--- native CF objects and java class instances need different processing --->
			<cfif structkeyexists(getMetaData(arguments.data), 'fullname')>
				<cfset local.klass_name = getMetaData(arguments.data).fullname>
			<cfelse>
				<cfset local.klass_name = "java:" & arguments.data.getClass().getName()>
			</cfif>
			<cfset local.yaml = "!" & local.klass_name & chr(10)>
			<!--- copy all data into a standard struct to output on the next run through --->
			<cfset local.members = structnew()>
			<cfloop collection="#arguments.data#" item="local.item">
				<cfset local.members[local.item] = arguments.data[local.item]>
			</cfloop>
			<cfset local.yaml = local.yaml & local.sp & "- " & serialise(local.members, arguments.indent + 1) & chr(10)>

		<!--- CUSTOM FUNCTIONS --->
		<cfelseif isCustomFunction(arguments.data)>
			<cfset local.fn = getMetaData(arguments.data)>
			<cfset local.args = "">
			<cfloop from="1" to="#arraylen(local.fn.parameters)#" index="local.i">
				<cfset local.arg = local.fn.parameters[local.i]>
				<cfset local.args = listappend(local.args, local.arg.name & ":" & local.arg.type, ",")>
			</cfloop>
			<cfset local.args = replace(local.args, ",", ", ", "ALL")>
			<cfset local.same_line = TRUE>
			<cfparam name="local.fn.access" default="public">
			<cfparam name="local.fn.returntype" default="any">
			<cfset local.yaml = "[FUNCTION] " & local.fn.access & " " & local.fn.name & " (" & local.args & "): " & local.fn.returntype>
			<!--- use the following line instead of all the above for more verbosity --->
			<!--- <cfset local.yaml = local.yaml & local.sp & serialise(getMetaData(arguments.data), arguments.indent) & chr(10)> --->

		<!--- STRUCTURES --->
		<cfelseif isStruct(arguments.data)>
			<cfif NOT structisempty(arguments.data)>
				<cfloop collection="#arguments.data#" item="local.k">
					<cfset local.yaml = local.yaml & local.sp & local.k & ": " & serialise(arguments.data[local.k], arguments.indent + 1) & chr(10)>
				</cfloop>
			<cfelse>
				<cfset local.same_line = TRUE>
				<cfset local.yaml = "[EMPTY STRUCTURE]">
			</cfif>

		<!--- ANYTHING ELSE --->
		<cfelse>
			<cfset local.same_line = TRUE>
			<cfset local.yaml = "[UNKNOWN: #arguments.data.getClass().getCanonicalName()#]">
		</cfif>

		<!--- new line if this isn't the first item, scalar or forced on to same line --->
		<cfif arguments.indent AND NOT isSimpleValue(arguments.data) AND NOT local.same_line>
			<cfset local.yaml = chr(10) & local.sp & trim(local.yaml)>
		</cfif>

		<cfreturn local.yaml>
	</cffunction>

</cfcomponent>
