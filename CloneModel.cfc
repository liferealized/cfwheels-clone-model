<cfcomponent output="false" displayname="Clone Model" mixin="model">

	<!-----------------------------------------------------------------------------------
	-------------------------------------------------------------------------------------
	Title:		Clone Model Plugin CF Wheels (http://cfwheels.org)
	
	Source:		http://github.com/andybellenie/CFWheels-Clone-Model
	
	Author:		Andy Bellenie
	
	Support:	Please use the GitHub's issue tracker to report any problems with this plugin
				http://github.com/andybellenie/CFWheels-Clone-Model/issues

	Usage:		Use clone() in your model to create a duplicate of it in the database. Set 
				the 'recurse' argument to true to also create duplicates of all
				associated models via the 'hasMany' or 'hasOne' association types. 
					
	-------------------------------------------------------------------------------------
	------------------------------------------------------------------------------------>	
	
	<cffunction name="init" access="public" output="false" returntype="any">
		<cfset this.version = "1.0,1.1" />
		<cfreturn this />
	</cffunction> 
	
	
	<cffunction name="clone" returntype="any" mixin="model">
		<cfargument name="recurse" type="string" default="false" hint="Set to true to clone any models associated via models hasMany() or hasOne().">
		<cfargument name="foreignKey" type="string" default="" hint="The foreign key in the child model to be cloned.">
		<cfargument name="foreignKeyValue" type="any" default="" hint="The foreign key in the child model to be cloned.">
		
		<cfset var loc = {}>

		<cfloop collection="#this.properties()#" item="loc.key">
			<cfif StructKeyExists(this,loc.key) and not ListFindNoCase("#this.primaryKey()#,createdAt,updatedAt,deletedAt",loc.key)>
				<cfset loc.properties[loc.key] = this[loc.key]>
			</cfif>
		</cfloop>
		
		<cfset loc.returnValue = $createObjectFromRoot(path=application.wheels.modelComponentPath, fileName=Capitalize(variables.wheels.class.modelName), method="$initModelObject", name=variables.wheels.class.modelName, properties=loc.properties, persisted=true)>
		
		<cfif not StructKeyExists(variables.wheels.class.callbacks,"beforeClone") or loc.returnValue.$callback("beforeClone")>
				
			<cfif Len(arguments.foreignKey)>
				<cfset loc.returnValue[arguments.foreignKey] = arguments.foreignKeyValue>
			</cfif>		
			
			<cfif loc.returnValue.$create(parameterize=true)>
				
				<cfif StructKeyExists(variables.wheels.class.callbacks,"afterClone")>
					<cfset loc.returnValue.$callback("afterClone")>
				</cfif>
								
				<cfif arguments.recurse>				
					<cfloop collection="#variables.wheels.class.associations#" item="loc.key">
						<cfif ListFindNoCase("hasMany,hasOne",variables.wheels.class.associations[loc.key].type)>
							<cfset loc.association = this.$expandedAssociations(include=loc.key)>
							<cfset loc.association = loc.association[1]>
							<cfset loc.arrChildren = Evaluate("this.#loc.key#(returnAs='objects')")>
							<cfif ArrayLen(loc.arrChildren)>
								<cfloop from="1" to="#ArrayLen(loc.arrChildren)#" index="loc.i">
									<cfset loc.arrChildren[loc.i].clone(recurse=true,foreignKey=loc.association.foreignKey,foreignKeyValue=loc.returnValue[this.primaryKey()])>
								</cfloop>
							</cfif>
						</cfif>
					</cfloop>
				</cfif>

				<cfreturn loc.returnValue>
				
			</cfif>
					
		</cfif>
		
		<cfreturn false>
	</cffunction>
	
	
	<cffunction name="beforeClone" returntype="void" access="public" output="false" mixin="model" hint="Registers method(s) that should be called before an object is cloned.">
		<cfargument name="methods" type="string" required="false" default="" hint="See documentation for @afterNew.">
		<cfset variables.wheels.class.callbacks.beforeClone = ArrayNew(1)>
		<cfset $registerCallback(type="beforeClone", argumentCollection=arguments)>
	</cffunction>


	<cffunction name="afterClone" returntype="void" access="public" output="false" mixin="model" hint="Registers method(s) that should be called after an object is cloned.">
		<cfargument name="methods" type="string" required="false" default="" hint="See documentation for @afterNew.">
		<cfset variables.wheels.class.callbacks.afterClone = ArrayNew(1)>
		<cfset $registerCallback(type="afterClone", argumentCollection=arguments)>
	</cffunction>	


</cfcomponent>