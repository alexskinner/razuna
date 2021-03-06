<!---
*
* Copyright (C) 2005-2008 Razuna
*
* This file is part of Razuna - Enterprise Digital Asset Management.
*
* Razuna is free software: you can redistribute it and/or modify
* it under the terms of the GNU Affero Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* Razuna is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU Affero Public License for more details.
*
* You should have received a copy of the GNU Affero Public License
* along with Razuna. If not, see <http://www.gnu.org/licenses/>.
*
* You may restribute this Program with a special exception to the terms
* and conditions of version 3.0 of the AGPL as described in Razuna's
* FLOSS exception. You should have received a copy of the FLOSS exception
* along with Razuna. If not, see <http://www.razuna.com/licenses/>.
*
--->
<cfcomponent  output="false" extends="extQueryCaching">

<!--- LOG USERS --->
<cffunction name="log_users" output="false" access="public">
	<cfargument name="theuserid" type="string" required="yes" />
	<cfargument name="logaction" type="string" required="yes" />
	<cfargument name="logdesc" type="string" required="yes" />
	<cfargument name="logsection" type="string" required="yes" />
	<cfargument name="thestruct" type="struct" required="true" />
	<!--- Params for struct --->
	<cfset arguments.thestruct.theuserid = arguments.theuserid>
	<cfset arguments.thestruct.logaction = arguments.logaction>
	<cfset arguments.thestruct.logdesc = arguments.logdesc>
	<cfset arguments.thestruct.logsection = arguments.logsection>
	<cfset arguments.thestruct.http_user_agent = cgi.http_user_agent>
	<cfset arguments.thestruct.remote_addr = cgi.remote_addr>
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" background="yes">
	INSERT INTO #arguments.thestruct.razuna.session.hostdbprefix#log_users
	(log_id,log_user,log_action,log_date,log_time,log_desc,log_browser,log_ip,log_timestamp,log_section,host_id)
	VALUES(
	<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#CreateUUid()#">,
	<cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.thestruct.theuserid#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logaction#">,
	<cfqueryparam cfsqltype="cf_sql_date" value="#now()#">,
	<cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logdesc#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.http_user_agent#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.remote_addr#">,
	<cfqueryparam cfsqltype="cf_sql_timestamp" value="#now()#">,
	<cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logsection#">,
	<cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
	)
	</cfquery>
	<!--- Flush Cache --->
	<cfset resetcachetoken(type="logs", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
	<cfreturn />
</cffunction>

<!--- GET LOG USERS --->
<cffunction name="get_log_users" output="false" access="public">
	<cfargument name="thestruct" type="struct" required="yes" />
	<cfparam name="arguments.thestruct.logaction" default="" />
	<!--- Get the cachetoken for here --->
	<cfset var cachetoken = getcachetoken(type="logs", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
	<!--- Get all log entries --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="thetotal" cachedwithin="1" region="razcache">
	SELECT /* #cachetoken#get_log_users */ log_id
	FROM #arguments.thestruct.razuna.session.hostdbprefix#log_users
	WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
	</cfquery>
	<!--- Set the session for offset correctly if the total count of assets in lower the the total rowmaxpage --->
	<cfif thetotal.recordcount LTE arguments.thestruct.razuna.session.rowmaxpage_log>
		<cfset arguments.thestruct.razuna.session.offset_log = 0>
	</cfif>
	<cfif arguments.thestruct.razuna.session.offset_log EQ 0>
		<cfset var min = 0>
		<cfset var max = arguments.thestruct.razuna.session.rowmaxpage_log>
	<cfelse>
		<cfset var min = arguments.thestruct.razuna.session.offset_log * arguments.thestruct.razuna.session.rowmaxpage_log>
		<cfset var max = (arguments.thestruct.razuna.session.offset_log + 1) * arguments.thestruct.razuna.session.rowmaxpage_log>
	</cfif>
	<!--- MySQL Offset --->
	<cfset var mysqloffset = arguments.thestruct.razuna.session.offset_log * arguments.thestruct.razuna.session.rowmaxpage_log>
	<!--- Query --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="qry" cachedwithin="1" region="razcache">
		<!--- Oracle --->
		<cfif arguments.thestruct.razuna.application.thedatabase EQ "oracle">
			SELECT /* #cachetoken#get_log_users2 */ rn, log_user, log_action, log_date, log_time, log_desc, log_browser, log_ip, log_timestamp, thetotal
			FROM (
				SELECT ROWNUM AS rn, log_user, log_action, log_date, log_time, log_desc, log_browser, log_ip, log_timestamp, thetotal
				FROM (
					SELECT l.log_user, l.log_action, l.log_date, l.log_time, l.log_desc, l.log_browser, l.log_ip, l.log_timestamp,
					(
						SELECT count(log_id)
						FROM #arguments.thestruct.razuna.session.hostdbprefix#log_users
						WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
						<cfif structkeyexists(arguments.thestruct,"logaction") AND arguments.thestruct.logaction NEQ "">
							AND log_action = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logaction#">
						</cfif>
					) as thetotal
					FROM #arguments.thestruct.razuna.session.hostdbprefix#log_users l
					WHERE l.log_section = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logsection#">
					AND l.host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
					<cfif structkeyexists(arguments.thestruct,"logaction") AND arguments.thestruct.logaction NEQ "">
						AND l.log_action = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logaction#">
					</cfif>
					GROUP BY l.log_user, l.log_action, l.log_date, l.log_time, l.log_desc, l.log_browser, l.log_ip, l.log_id, l.log_timestamp
					ORDER BY log_timestamp DESC
					) d
				WHERE ROWNUM <= #max#
				) dt
			WHERE rn > #min#
		<!--- MSSQL, MySQL, H2 --->
		<cfelse>
			SELECT /* #cachetoken#get_log_users2 */<cfif arguments.thestruct.razuna.application.thedatabase EQ "mssql"> TOP #arguments.thestruct.razuna.session.rowmaxpage_log#</cfif> l.log_user, l.log_action, l.log_date, l.log_time, l.log_desc, l.log_browser,
			l.log_ip, l.log_timestamp,
			(
				SELECT count(log_id)
				FROM #arguments.thestruct.razuna.session.hostdbprefix#log_users
				WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
				<cfif structkeyexists(arguments.thestruct,"logaction") AND arguments.thestruct.logaction NEQ "">
					AND log_action = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logaction#">
				</cfif>
			) as thetotal
			FROM #arguments.thestruct.razuna.session.hostdbprefix#log_users l
			WHERE l.log_section = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logsection#">
			AND l.host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
			<cfif structkeyexists(arguments.thestruct,"logaction") AND arguments.thestruct.logaction NEQ "">
				AND l.log_action = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logaction#">
			</cfif>
			<cfif arguments.thestruct.razuna.application.thedatabase EQ "mssql">
				AND l.log_id NOT IN (
					SELECT TOP #min# log_id
					FROM #arguments.thestruct.razuna.session.hostdbprefix#log_users
					WHERE log_section = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logsection#">
					AND host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
					<cfif structkeyexists(arguments.thestruct,"logaction") AND arguments.thestruct.logaction NEQ "">
						AND log_action = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logaction#">
					</cfif>
					ORDER BY log_timestamp DESC
				)
			</cfif>
			GROUP BY l.log_user, l.log_action, l.log_date, l.log_time, l.log_desc, l.log_browser, l.log_ip, l.log_id, l.log_timestamp
			ORDER BY log_timestamp DESC
			<cfif arguments.thestruct.razuna.application.thedatabase EQ "mysql" OR arguments.thestruct.razuna.application.thedatabase EQ "h2">
				LIMIT #mysqloffset#, #arguments.thestruct.razuna.session.rowmaxpage_log#
			</cfif>
		</cfif>
	</cfquery>
	<!--- Return --->
	<cfreturn qry>
</cffunction>

<!--- REMOVE LOG USERS --->
<cffunction name="remove_log_users" output="false" access="public">
	<cfargument name="thestruct" type="struct" required="true" />
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
	DELETE FROM #arguments.thestruct.razuna.session.hostdbprefix#log_users
	WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
	</cfquery>
	<!--- Flush Cache --->
	<cfset resetcachetoken(type="logs", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
</cffunction>

<!--- GET LOG ASSETS --->
<cffunction name="get_log_assets" output="false" access="public">
	<cfargument name="thestruct" type="struct" required="yes" />
	<cfparam name="arguments.thestruct.logaction" default="" />

	<!--- Get Dashboard most recently updated assets without paging records --->
	<cfif structKeyExists(arguments.thestruct,"is_dashboard_update")>
		<cfset temp_rowmaxpage_log = arguments.thestruct.razuna.session.rowmaxpage_log>
		<cfset temp_offset_log = arguments.thestruct.razuna.session.offset_log>
		<cfset arguments.thestruct.razuna.session.rowmaxpage_log = 50>
		<cfset arguments.thestruct.razuna.session.offset_log = 0>
	</cfif>
	<!--- Get the cachetoken for here --->
	<cfset var cachetoken = getcachetoken(type="logs", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
	<!--- Get all log entries --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="thetotal" cachedwithin="1" region="razcache">
	SELECT /* #cachetoken#get_log_assets */ log_id
	FROM #arguments.thestruct.razuna.session.hostdbprefix#log_assets
	WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
	<cfif structKeyExists(arguments.thestruct,"id") AND arguments.thestruct.id NEQ 0>
		AND asset_id_r = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.thestruct.id#">
	</cfif>
	</cfquery>
	<!--- Set the session for offset correctly if the total count of assets in lower the the total rowmaxpage --->
	<cfif thetotal.recordcount LTE arguments.thestruct.razuna.session.rowmaxpage_log>
		<cfset arguments.thestruct.razuna.session.offset_log = 0>
	</cfif>
	<cfif arguments.thestruct.razuna.session.offset_log EQ 0>
		<cfset var min = 0>
		<cfset var max = arguments.thestruct.razuna.session.rowmaxpage_log>
	<cfelse>
		<cfset var min = arguments.thestruct.razuna.session.offset_log * arguments.thestruct.razuna.session.rowmaxpage_log>
		<cfset var max = (arguments.thestruct.razuna.session.offset_log + 1) * arguments.thestruct.razuna.session.rowmaxpage_log>
	</cfif>
	<!--- MySQL Offset --->
	<cfset var mysqloffset = arguments.thestruct.razuna.session.offset_log * arguments.thestruct.razuna.session.rowmaxpage_log>
	<!--- this is also called from individual asset log entries thus we have a id in the struct --->
	<cfif !structkeyexists(arguments.thestruct,"id")>
		<cfset arguments.thestruct.id = 0>
	</cfif>
	<!--- Query --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="qry" cachedwithin="1" region="razcache">
		<!--- Oracle --->
		<cfif arguments.thestruct.razuna.application.thedatabase EQ "oracle">
			SELECT /* #cachetoken#get_log_assets2 */ rn, log_user, log_action, log_date, log_time, log_desc, log_browser, log_ip, log_file_type,
			log_timestamp, user_first_name, user_last_name, thetotal
			FROM (
				SELECT ROWNUM AS rn,
				log_user, log_action, log_date, log_time, log_desc, log_browser, log_ip, log_file_type,
				log_timestamp, user_first_name, user_last_name, thetotal
				FROM (
					SELECT l.log_user, l.log_action, l.log_date, l.log_time, l.log_desc, l.log_browser,
					l.log_ip, l.log_file_type, l.log_timestamp, u.user_first_name, u.user_last_name,
					(
						SELECT count(log_id)
						FROM #arguments.thestruct.razuna.session.hostdbprefix#log_assets
						WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
						<cfif structkeyexists(arguments.thestruct,"logaction") AND arguments.thestruct.logaction NEQ "">
							AND log_action = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logaction#">
						</cfif>
						<cfif arguments.thestruct.id NEQ 0>
							AND asset_id_r = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.thestruct.id#">
						</cfif>
					) as thetotal
					FROM #arguments.thestruct.razuna.session.hostdbprefix#log_assets l LEFT JOIN users u ON l.log_user = u.user_id
					WHERE l.host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
					<cfif structkeyexists(arguments.thestruct,"logaction") AND arguments.thestruct.logaction NEQ "">
						AND l.log_action = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logaction#">
					</cfif>
					<cfif arguments.thestruct.id NEQ 0>
						AND asset_id_r = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.thestruct.id#">
					</cfif>
					GROUP BY log_timestamp, log_id, log_user, log_action, log_date, log_time, log_desc, log_browser, log_ip, log_file_type,
					user_first_name, user_last_name
					ORDER BY log_timestamp DESC
					) d
				WHERE ROWNUM <= <cfqueryparam value="#max#" cfsqltype="cf_sql_numeric">
				) dt
			WHERE rn > <cfqueryparam value="#min#" cfsqltype="cf_sql_numeric">
		<!--- MSSQL, MySQL, H2 --->
		<cfelse>
			SELECT /* #cachetoken#get_log_assets2 */<cfif arguments.thestruct.razuna.application.thedatabase EQ "mssql"> TOP #arguments.thestruct.razuna.session.rowmaxpage_log#</cfif> l.log_user, l.log_action, l.log_date,
			l.log_time, l.log_desc, l.log_browser, l.log_ip, l.log_file_type, l.log_timestamp, u.user_first_name, u.user_last_name,
			(
				SELECT count(log_id)
				FROM #arguments.thestruct.razuna.session.hostdbprefix#log_assets
				WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
				<cfif structkeyexists(arguments.thestruct,"logaction") AND arguments.thestruct.logaction NEQ "">
					AND log_action = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logaction#">
				</cfif>
				<cfif arguments.thestruct.id NEQ 0>
					AND asset_id_r = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.thestruct.id#">
				</cfif>
			) as thetotal
			FROM #arguments.thestruct.razuna.session.hostdbprefix#log_assets l LEFT JOIN users u ON l.log_user = u.user_id
			WHERE l.host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
			<cfif arguments.thestruct.id NEQ 0>
				AND asset_id_r = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.thestruct.id#">
			</cfif>
			<cfif structkeyexists(arguments.thestruct,"logaction") AND arguments.thestruct.logaction NEQ "">
				AND l.log_action = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logaction#">
			</cfif>
			<cfif arguments.thestruct.razuna.application.thedatabase EQ "mssql">
				AND l.log_id NOT IN
				(
					SELECT TOP #min# log_id
					FROM #arguments.thestruct.razuna.session.hostdbprefix#log_assets
					WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
					<cfif structkeyexists(arguments.thestruct,"logaction") AND arguments.thestruct.logaction NEQ "">
						AND log_action = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logaction#">
					</cfif>
					<cfif arguments.thestruct.id NEQ 0>
						AND asset_id_r = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.thestruct.id#">
					</cfif>
					ORDER BY log_timestamp DESC
				)
			</cfif>
			GROUP BY log_timestamp, log_id, log_user, log_action, log_date, log_time, log_desc, log_browser, log_ip, log_file_type,
			user_first_name, user_last_name
			ORDER BY log_timestamp DESC
			<cfif arguments.thestruct.razuna.application.thedatabase EQ "mysql" OR arguments.thestruct.razuna.application.thedatabase EQ "h2">
				LIMIT #mysqloffset#, #arguments.thestruct.razuna.session.rowmaxpage_log#
			</cfif>
		</cfif>
	</cfquery>
	<!--- Get Dashboard most recently updated assets without paging records --->
	<cfif structKeyExists(arguments.thestruct,"is_dashboard_update")>
		<cfset arguments.thestruct.razuna.session.rowmaxpage_log = temp_rowmaxpage_log>
		<cfset arguments.thestruct.razuna.session.offset_log = temp_offset_log>
	</cfif>

	<!--- Return --->
	<cfreturn qry>
</cffunction>

<!--- REMOVE LOG USERS --->
<cffunction name="remove_log_assets" output="false" access="public">
	<cfargument name="id" type="string" required="false" />
	<cfargument name="thestruct" type="struct" required="true" />
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
	DELETE FROM #arguments.thestruct.razuna.session.hostdbprefix#log_assets
	WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
	<cfif structkeyexists(arguments,"id")>
		AND asset_id_r = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.id#">
	</cfif>
	</cfquery>
	<!--- Flush Cache --->
	<cfset resetcachetoken(type="logs", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
</cffunction>

<!--- GET LOG FOLDERS --->
<cffunction name="get_log_folders" output="false" access="public">
	<cfargument name="thestruct" type="struct" required="yes" />
	<cfparam name="arguments.thestruct.logaction" default="" />
	<!--- Get the cachetoken for here --->
	<cfset var cachetoken = getcachetoken(type="logs", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
	<!--- Get all log entries --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="thetotal" cachedwithin="1" region="razcache">
	SELECT /* #cachetoken#get_log_folders */ log_id
	FROM #arguments.thestruct.razuna.session.hostdbprefix#log_folders
	WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
	</cfquery>
	<!--- Set the session for offset correctly if the total count of assets in lower then the total rowmaxpage --->
	<cfif thetotal.recordcount LTE arguments.thestruct.razuna.session.rowmaxpage_log>
		<cfset arguments.thestruct.razuna.session.offset_log = 0>
	</cfif>
	<cfif arguments.thestruct.razuna.session.offset_log EQ 0>
		<cfset var min = 0>
		<cfset var max = arguments.thestruct.razuna.session.rowmaxpage_log>
	<cfelse>
		<cfset var min = arguments.thestruct.razuna.session.offset_log * arguments.thestruct.razuna.session.rowmaxpage_log>
		<cfset var max = (arguments.thestruct.razuna.session.offset_log + 1) * arguments.thestruct.razuna.session.rowmaxpage_log>
	</cfif>
	<!--- MySQL Offset --->
	<cfset var mysqloffset = arguments.thestruct.razuna.session.offset_log * arguments.thestruct.razuna.session.rowmaxpage_log>
	<!--- Query --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="qry" cachedwithin="1" region="razcache">
		<!--- Oracle --->
		<cfif arguments.thestruct.razuna.application.thedatabase EQ "oracle">
			SELECT /* #cachetoken#get_log_folders2 */ rn, log_user, log_action, log_date, log_time, log_desc, log_browser, log_ip, log_timestamp,
			user_first_name, user_last_name, thetotal
			FROM (
				SELECT ROWNUM AS rn, log_user, log_action, log_date, log_time, log_desc, log_browser, log_ip, log_timestamp, user_first_name,
				user_last_name, thetotal
				FROM (
					SELECT l.log_user, l.log_action, l.log_date, l.log_time, l.log_desc, l.log_browser, l.log_ip, l.log_timestamp,
					u.user_first_name, u.user_last_name,
					(
						SELECT count(log_id)
						FROM #arguments.thestruct.razuna.session.hostdbprefix#log_folders
						WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
						<cfif structkeyexists(arguments.thestruct,"logaction") AND arguments.thestruct.logaction NEQ "">
							AND log_action = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logaction#">
						</cfif>
					) as thetotal
					FROM #arguments.thestruct.razuna.session.hostdbprefix#log_folders l LEFT JOIN users u ON l.log_user = u.user_id
					WHERE l.host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
					<cfif structkeyexists(arguments.thestruct,"logaction") AND arguments.thestruct.logaction NEQ "">
						AND l.log_action = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logaction#">
					</cfif>
					GROUP BY l.log_user, l.log_action, l.log_date, l.log_time, l.log_desc, l.log_browser, l.log_ip, u.user_first_name, u.user_last_name, l.log_id, l.log_timestamp
					ORDER BY log_timestamp DESC
					) d
				WHERE ROWNUM <= #max#
				) dt
			WHERE rn > #min#
		<!--- MSSQL, MySQL, H2 --->
		<cfelse>
			SELECT /* #cachetoken#get_log_folders2 */<cfif arguments.thestruct.razuna.application.thedatabase EQ "mssql"> TOP #arguments.thestruct.razuna.session.rowmaxpage_log#</cfif> l.log_user, l.log_action, l.log_date, l.log_time, l.log_desc, l.log_browser,
			l.log_ip, l.log_timestamp, u.user_first_name, u.user_last_name,
			(
				SELECT count(log_id)
				FROM #arguments.thestruct.razuna.session.hostdbprefix#log_folders
				WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
				<cfif structkeyexists(arguments.thestruct,"logaction") AND arguments.thestruct.logaction NEQ "">
					AND log_action = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logaction#">
				</cfif>
			) as thetotal
			FROM #arguments.thestruct.razuna.session.hostdbprefix#log_folders l LEFT JOIN users u ON l.log_user = u.user_id
			WHERE l.host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
			<cfif structkeyexists(arguments.thestruct,"logaction") AND arguments.thestruct.logaction NEQ "">
				AND l.log_action = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logaction#">
			</cfif>
			<cfif arguments.thestruct.razuna.application.thedatabase EQ "mssql">
				AND l.log_id NOT IN
				(
					SELECT TOP #min# log_id
					FROM #arguments.thestruct.razuna.session.hostdbprefix#log_folders
					WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
					<cfif structkeyexists(arguments.thestruct,"logaction") AND arguments.thestruct.logaction NEQ "">
						AND log_action = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.logaction#">
					</cfif>
					ORDER BY log_timestamp DESC
				)
			</cfif>
			GROUP BY l.log_user, l.log_action, l.log_date, l.log_time, l.log_desc, l.log_browser, l.log_ip, u.user_first_name, u.user_last_name,
			l.log_id, l.log_timestamp
			ORDER BY log_timestamp DESC
			<cfif arguments.thestruct.razuna.application.thedatabase EQ "mysql" OR arguments.thestruct.razuna.application.thedatabase EQ "h2">
				LIMIT #mysqloffset#, #arguments.thestruct.razuna.session.rowmaxpage_log#
			</cfif>
		</cfif>
	</cfquery>
	<!--- Return --->
	<cfreturn qry>
</cffunction>

<!--- REMOVE LOG USERS --->
<cffunction name="remove_log_folders" output="false" access="public">
	<cfargument name="thestruct" type="struct" required="true" />
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
	DELETE FROM #arguments.thestruct.razuna.session.hostdbprefix#log_folders
	WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
	</cfquery>
	<!--- Flush Cache --->
	<cfset resetcachetoken(type="logs", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
</cffunction>

<!--- GET LOG SEARCHES --->
<cffunction name="get_log_searches" output="false" access="public">
	<cfargument name="thestruct" type="struct" required="yes" />
	<!--- Get the cachetoken for here --->
	<cfset var cachetoken = getcachetoken(type="logs", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
	<!--- Get all log entries --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="thetotal" cachedwithin="1" region="razcache">
	SELECT /* #cachetoken#get_log_searches */ log_id
	FROM #arguments.thestruct.razuna.session.hostdbprefix#log_search
	WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
	</cfquery>
	<!--- Set the session for offset correctly if the total count of assets in lower the the total rowmaxpage --->
	<cfif thetotal.recordcount LTE arguments.thestruct.razuna.session.rowmaxpage_log>
		<cfset arguments.thestruct.razuna.session.offset_log = 0>
	</cfif>
	<cfif arguments.thestruct.razuna.session.offset_log EQ 0>
		<cfset var min = 0>
		<cfset var max = arguments.thestruct.razuna.session.rowmaxpage_log>
	<cfelse>
		<cfset var min = arguments.thestruct.razuna.session.offset_log * arguments.thestruct.razuna.session.rowmaxpage_log>
		<cfset var max = (arguments.thestruct.razuna.session.offset_log + 1) * arguments.thestruct.razuna.session.rowmaxpage_log>
	</cfif>
	<!--- MySQL Offset --->
	<cfset var mysqloffset = arguments.thestruct.razuna.session.offset_log * arguments.thestruct.razuna.session.rowmaxpage_log>
	<!--- Query --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="qry" cachedwithin="1" region="razcache">
		<!--- Oracle --->
		<cfif arguments.thestruct.razuna.application.thedatabase EQ "oracle">
			SELECT /* #cachetoken#get_log_searches2 */ rn, log_user, log_date, log_time, log_search_for, log_search_from, log_founditems, log_browser, log_ip, log_timestamp,
			user_first_name, user_last_name, thetotal
			FROM (
				SELECT ROWNUM AS rn, log_user, log_date, log_time, log_search_for, log_search_from, log_founditems, log_browser, log_ip, log_timestamp,
				 user_first_name, user_last_name, thetotal
				FROM (
					SELECT l.log_user, l.log_date, l.log_time, l.log_search_for, l.log_search_from, l.log_founditems,
					l.log_browser, l.log_ip, l.log_timestamp, u.user_first_name, u.user_last_name,
					(
						SELECT count(log_id)
						FROM #arguments.thestruct.razuna.session.hostdbprefix#log_search
						WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
					) as thetotal
					FROM #arguments.thestruct.razuna.session.hostdbprefix#log_search l LEFT JOIN users u ON l.log_user = u.user_id
					WHERE l.host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
					GROUP BY l.log_user, l.log_date, l.log_time, l.log_search_for, l.log_search_from, l.log_founditems, l.log_browser, l.log_ip, u.user_first_name, u.user_last_name, l.log_id, l.log_timestamp
					ORDER BY log_timestamp DESC
					) d
				WHERE ROWNUM <= #max#
				) dt
			WHERE rn > #min#
		<!--- MSSQL, MySQL, H2 --->
		<cfelse>
			SELECT /* #cachetoken#get_log_searches2 */<cfif arguments.thestruct.razuna.application.thedatabase EQ "mssql"> TOP #arguments.thestruct.razuna.session.rowmaxpage_log#</cfif> l.log_user, l.log_date, l.log_time, l.log_search_for, l.log_search_from,
			l.log_founditems, l.log_timestamp, l.log_browser, l.log_ip, u.user_first_name, u.user_last_name,
			(
				SELECT count(log_id)
				FROM #arguments.thestruct.razuna.session.hostdbprefix#log_search
				WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
			) as thetotal
			FROM #arguments.thestruct.razuna.session.hostdbprefix#log_search l LEFT JOIN users u ON l.log_user = u.user_id
			WHERE l.host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
			<cfif arguments.thestruct.razuna.application.thedatabase EQ "mssql">
				AND l.log_id NOT IN
				(
					SELECT TOP #min# log_id
					FROM #arguments.thestruct.razuna.session.hostdbprefix#log_search
					WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
					ORDER BY log_timestamp DESC
				)
			</cfif>
			GROUP BY log_user, log_date, log_time, log_search_for, log_search_from, log_founditems, log_browser, log_ip, user_first_name, user_last_name, log_id, log_timestamp
			ORDER BY log_timestamp DESC
			<cfif arguments.thestruct.razuna.application.thedatabase EQ "mysql" OR arguments.thestruct.razuna.application.thedatabase EQ "h2">
				LIMIT #mysqloffset#, #arguments.thestruct.razuna.session.rowmaxpage_log#
			</cfif>
		</cfif>
	</cfquery>
	<!--- Return --->
	<cfreturn qry>
</cffunction>

<!--- REMOVE LOG SEARCHES --->
<cffunction name="remove_log_searches" output="false" access="public">
	<cfargument name="thestruct" type="struct" required="true" />
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
	DELETE FROM #arguments.thestruct.razuna.session.hostdbprefix#log_search
	WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
	</cfquery>
	<!--- Flush Cache --->
	<cfset resetcachetoken(type="logs", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
</cffunction>

<!--- GET LOG SEARCHES SUM --->
<cffunction name="get_log_searches_sum" output="false" access="public">
	<cfargument name="thestruct" type="struct" required="yes" />
	<cfparam name="arguments.thestruct.what" default="" />
	<!--- Get the cachetoken for here --->
	<cfset var cachetoken = getcachetoken(type="logs", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
	<!--- Query --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="qry" cachedwithin="1" region="razcache">
	SELECT /* #cachetoken#get_log_searches_sum */ log_search_for, count(log_search_for) count_words, sum(log_founditems) found
	FROM #arguments.thestruct.razuna.session.hostdbprefix#log_search
	WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
	<cfif structkeyexists(arguments.thestruct,"what") AND arguments.thestruct.what NEQ "">
		AND log_search_from = <cfqueryparam cfsqltype="cf_sql_varchar" value="#arguments.thestruct.what#">
	</cfif>
	GROUP BY log_search_for
	order by found DESC, count_words DESC
	</cfquery>
	<!--- Return --->
	<cfreturn qry>
</cffunction>

<!--- GET LOG SEARCHES --->
<cffunction name="get_log_errors" output="false" access="public">
	<cfargument name="thestruct" type="struct" required="yes" />
	<!--- Get the cachetoken for here --->
	<cfset var cachetoken = getcachetoken(type="logs", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
	<!--- Get all log entries --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="thetotal" cachedwithin="1" region="razcache">
	SELECT /* #cachetoken#get_log_errors */ id
	FROM #arguments.thestruct.razuna.session.hostdbprefix#errors
	WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
	</cfquery>
	<!--- Set the session for offset correctly if the total count of assets in lower the the total rowmaxpage --->
	<cfif thetotal.recordcount LTE arguments.thestruct.razuna.session.rowmaxpage_log>
		<cfset arguments.thestruct.razuna.session.offset_log = 0>
	</cfif>
	<cfif arguments.thestruct.razuna.session.offset_log EQ 0>
		<cfset var min = 0>
		<cfset var max = arguments.thestruct.razuna.session.rowmaxpage_log>
	<cfelse>
		<cfset var min = arguments.thestruct.razuna.session.offset_log * arguments.thestruct.razuna.session.rowmaxpage_log>
		<cfset var max = (arguments.thestruct.razuna.session.offset_log + 1) * arguments.thestruct.razuna.session.rowmaxpage_log>
	</cfif>
	<!--- MySQL Offset --->
	<cfset var mysqloffset = arguments.thestruct.razuna.session.offset_log * arguments.thestruct.razuna.session.rowmaxpage_log>
	<!--- Query --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="qry" cachedwithin="1" region="razcache">
		<!--- Oracle --->
		<cfif arguments.thestruct.razuna.application.thedatabase EQ "oracle">
			SELECT /* #cachetoken#get_log_errors2 */ rn, id, err_date, thetotal
			FROM (
				SELECT ROWNUM AS rn, id, err_date, thetotal
				FROM (
					SELECT id, err_date,
					(
						SELECT count(id)
						FROM #arguments.thestruct.razuna.session.hostdbprefix#errors
						WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
					) as thetotal
					FROM #arguments.thestruct.razuna.session.hostdbprefix#errors
					WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
					GROUP BY id, err_date, host_id
					ORDER BY err_date DESC
					) d
				WHERE ROWNUM <= #max#
				) dt
			WHERE rn > #min#
		<!--- MSSQL, MySQL, H2 --->
		<cfelse>
			SELECT /* #cachetoken#get_log_errors2 */<cfif arguments.thestruct.razuna.application.thedatabase EQ "mssql"> TOP #arguments.thestruct.razuna.session.rowmaxpage_log#</cfif> id, err_date,
			(
				SELECT count(id)
				FROM #arguments.thestruct.razuna.session.hostdbprefix#errors
				WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
			) as thetotal
			FROM #arguments.thestruct.razuna.session.hostdbprefix#errors
			WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
			<cfif arguments.thestruct.razuna.application.thedatabase EQ "mssql">
				AND id NOT IN
				(
					SELECT TOP #min# id
					FROM #arguments.thestruct.razuna.session.hostdbprefix#errors
					WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
					ORDER BY err_date DESC
				)
			</cfif>
			GROUP BY id, err_date, host_id
			ORDER BY err_date DESC
			<cfif arguments.thestruct.razuna.application.thedatabase EQ "mysql" OR arguments.thestruct.razuna.application.thedatabase EQ "h2">
				LIMIT #mysqloffset#, #arguments.thestruct.razuna.session.rowmaxpage_log#
			</cfif>
		</cfif>
	</cfquery>
	<!--- Return --->
	<cfreturn qry>
</cffunction>

<!--- GET ERROR DETAIL --->
<cffunction name="get_log_errors_detail" output="false" access="public">
	<cfargument name="id" required="true">
	<cfargument name="thestruct" type="struct" required="true" />
	<!--- Qry --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="qry">
	SELECT err_text
	FROM #arguments.thestruct.razuna.session.hostdbprefix#errors
	WHERE id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.id#">
	AND host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
	</cfquery>
	<!--- Return --->
	<cfreturn qry.err_text>
</cffunction>

<!--- REMOVE LOG SEARCHES --->
<cffunction name="remove_log_errors" output="false" access="public">
	<cfargument name="thestruct" type="struct" required="true" />
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#">
	DELETE FROM #arguments.thestruct.razuna.session.hostdbprefix#errors
	WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
	</cfquery>
	<!--- Flush Cache --->
	<cfset resetcachetoken(type="logs", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
</cffunction>

<!--- SEND ERROR LOG --->
<cffunction name="send_log_error" output="false" access="public">
	<cfargument name="thestruct" type="struct" required="yes" />
	<!--- Get Error --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="qry">
	SELECT err_text
	FROM #arguments.thestruct.razuna.session.hostdbprefix#errors
	WHERE id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.id#">
	AND host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
	</cfquery>
	<!--- Write error to system --->
	<cfset var tf = "#createuuid()#.html">
	<cfset var t = filewrite("#GetTempDirectory()#/#tf#", qry.err_text)>
	<!--- Send the mail --->
	<cfif arguments.thestruct.qrysettings.set2_email_server EQ "">
		<cfmail to="issues@razuna.com" from="#arguments.thestruct.email#" subject="Error Report" type="text/html">
		#arguments.thestruct.comment#
		<!--- Handle normal doc files --->
		<cfmailparam file="#GetTempDirectory()#/#tf#">
		</cfmail>
	<cfelse>
		<!--- send message if there is a mail server set for this host --->
		<cfmail to="issues@razuna.com" from="#arguments.thestruct.email#" subject="Error Report" username="#arguments.thestruct.qrysettings.SET2_EMAIL_SMTP_USER#" password="#arguments.thestruct.qrysettings.SET2_EMAIL_SMTP_PASSWORD#" server="#arguments.thestruct.qrysettings.SET2_EMAIL_SERVER#" port="#arguments.thestruct.qrysettings.SET2_EMAIL_SERVER_PORT#" usessl="#arguments.thestruct.qrysettings.SET2_EMAIL_USE_SSL#" usetls="#arguments.thestruct.qrysettings.SET2_EMAIL_USE_TLS#" type="text/html" timeout="900">
		#arguments.thestruct.comment#
		<!--- Handle normal doc files --->
		<cfmailparam file="#GetTempDirectory()#/#tf#">
		</cfmail>
	</cfif>
	<!--- Remove temp report --->
	<cfset var x = FileDelete("#GetTempDirectory()#/#tf#")>
	<cfreturn />
</cffunction>

<!--- SEARCH LOG --->
<cffunction name="log_search" output="false" access="public">
	<cfargument name="thestruct" required="true" type="struct">
	<!--- this is also called from individual asset log entries thus we have a id in the struct --->
	<cfif !structkeyexists(arguments.thestruct,"id")>
		<cfset arguments.thestruct.id = 0>
	</cfif>
	<!--- Get the cachetoken for here --->
	<cfset var cachetoken = getcachetoken(type="logs", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
	<!--- Qry --->
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="qry" cachedwithin="1" region="razcache">
	SELECT /* #cachetoken#log_search */ l.LOG_ACTION, l.LOG_DESC, <cfif arguments.thestruct.logtype EQ "log_assets">l.LOG_FILE_TYPE,</cfif> l.LOG_TIMESTAMP, u.user_first_name, u.user_last_name
	FROM #arguments.thestruct.razuna.session.hostdbprefix##arguments.thestruct.logtype# l LEFT JOIN users u ON l.log_user = u.user_id
	WHERE l.log_desc LIKE <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="%#arguments.thestruct.searchtext#%">
	AND l.host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
	<cfif arguments.thestruct.id NEQ 0>
		AND asset_id_r = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.thestruct.id#">
	</cfif>
	GROUP BY log_timestamp, log_action, log_desc, <cfif arguments.thestruct.logtype EQ "log_assets">log_file_type,</cfif> user_first_name, user_last_name
	ORDER BY log_timestamp DESC
	</cfquery>
	<!--- Return --->
	<cfreturn qry>
</cffunction>

<!--- FOLDER SUMMARY --->
<cffunction name="log_folder_summary" output="false" access="public">
	<cfargument name="folder_id" required="true" type="string">
	<cfargument name="allfolders" default="false" required="false" type="string" >
	<cfargument name="sortby" default="" required="false" type="string" >
	<cfargument name="thestruct" type="struct" required="true" />
	<!--- Get the cachetoken for here --->
	<cfset var cachetoken = getcachetoken(type="logs", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
	<!--- Qry --->
	<cfset var qry ="">
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="qry" cachedwithin="1" region="razcache">
	SELECT /* #cachetoken#log_summary */ f.folder_id, f.folder_name, u.user_login_name as username,
	(SELECT COUNT(1) FROM #arguments.thestruct.razuna.session.hostdbprefix#folders WHERE folder_id_r = f.folder_id AND folder_id_r <> folder_id AND in_trash = 'F') sf_cnt
	FROM #arguments.thestruct.razuna.session.hostdbprefix#folders f LEFT JOIN users u ON f.folder_owner = u.user_id
	WHERE host_id = <cfqueryparam cfsqltype="cf_sql_numeric" value="#arguments.thestruct.razuna.session.hostid#">
	AND (folder_is_collection IS NULL OR folder_is_collection ='' OR folder_is_collection ='F')
	AND in_trash = 'F'
	AND EXISTS (SELECT 1 FROM #arguments.thestruct.razuna.session.hostdbprefix#folders WHERE folder_id = f.folder_id_r)/*Make sure folder parent exists in system to avoid orphans*/
	<cfif arguments.folder_id NEQ 0>
		AND f.folder_id_r = <cfqueryparam cfsqltype="CF_SQL_VARCHAR" value="#arguments.folder_id#">
		AND f.folder_id_r <> f.folder_id
	<cfelseif !arguments.allfolders>
		AND f.folder_level = '1'
	</cfif>
	ORDER BY
	<cfif arguments.sortby NEQ ''>
		#arguments.sortby#
	<cfelse>
		f.folder_name ASC
	</cfif>
	</cfquery>
	<!--- Return --->
	<cfreturn qry>
</cffunction>

<!--- Get specific log according to timestamp and assetId --->
<cffunction name="getLogSpecific" output="false" access="public">
	<cfargument name="file_id" required="true" type="string">
	<cfargument name="timestamp" required="true" type="date">
	<cfargument name="fields" required="true" type="string">
	<cfargument name="log_action" required="true" type="string">
	<cfargument name="thestruct" type="struct" required="true" />
	<!--- Get the cachetoken for here --->
	<cfset var cachetoken = getcachetoken(type="logs", hostid=arguments.thestruct.razuna.session.hostid, thestruct=arguments.thestruct)>
	<!--- Qry --->
	<cfset var qry ="">
	<cfquery datasource="#arguments.thestruct.razuna.application.datasource#" name="qry" cachedwithin="1" region="razcache">
	SELECT /* #cachetoken#getLogSpecific */ #arguments.fields#
	FROM #arguments.thestruct.razuna.session.hostdbprefix#log_assets
	WHERE asset_id_r = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.file_id#">
	AND log_action = <cfqueryparam CFSQLType="CF_SQL_VARCHAR" value="#arguments.log_action#">
	AND log_timestamp > <cfqueryparam CFSQLType="cf_sql_timestamp" value="#arguments.timestamp#">
	</cfquery>
	<!--- Return --->
	<cfreturn qry>
</cffunction>

</cfcomponent>