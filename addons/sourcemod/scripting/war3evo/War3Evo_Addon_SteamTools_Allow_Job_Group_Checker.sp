/* ========================================================================== */
/*             steamtools (check if user in steam group)                     */
/*   (c) 2012 El Diablo                                                       */
/*                                                                            */
/* ========================================================================== */
#pragma semicolon 1

#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON
#include <sourcemod>
#undef REQUIRE_EXTENSIONS
#include "W3SIncs/steamtools"
#define REQUIRE_EXTENSIONS
//#include "W3SIncs/cssclantags"
#include "W3SIncs/War3Source_Interface"
//#include "W3SIncs/War3evo"
public W3ONLY(){} //unload this?

new Handle:g_hClanID = INVALID_HANDLE;

new bool:g_bSteamTools = false;
new bool:bIsInGroup[MAXPLAYERSCUSTOM] = false;

#define PLUGIN_VERSION "0.0.1"

public Plugin:myinfo = {
	name        = "SteamTools Group Checker Addon",
	author      = "El Diablo",
	description = "SteamTools Group checker for races.",
	version     = PLUGIN_VERSION,
	url         = "http://www.war3evo.com/"
};

public OnPluginStart()
{
	g_hClanID = CreateConVar("war3_clan_id","4174523","If GroupID is non-zero the plugin will use steamtools to identify clan players(Overrides 'war3_bonusclan_name')");
	// tells if steamtools is loaded and(if used from a client console) if you're member of the war3_bonusclan_id group
	RegConsoleCmd("war3_bonusclan", Command_TellStatus);
	// refreshes groupcache
	RegServerCmd("war3_bonusclan_refresh", Command_Refresh);
}

public bool:InitNativesForwards()
{
	MarkNativeAsOptional("Steam_RequestGroupStatus");
	CreateNative("War3_IsInSteamGroup",NWar3_isingroup);
	return true;  // prevents log errors
}


public NWar3_isingroup(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	return bIsInGroup[client];

}

public Action:Command_Refresh(args)
{
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,false))
		{
			Steam_RequestGroupStatus(client, GetConVarInt(g_hClanID));
		}
	}
	PrintToServer("[W3S] Repolling groupstatus...");
}

public Action:Command_TellStatus(client,args)
{
	if(g_bSteamTools) {
		ReplyToCommand(client,"[W3S] Steamtools detected!");
	}
	else {
		ReplyToCommand(client,"[W3S] Steamtools wasn't recognized!");
	}
	if(IS_PLAYER(client)) {
		ReplyToCommand(client,"[W3S] Membership status of Group(%i) is: %s",GetConVarInt(g_hClanID),(bIsInGroup[client]?"member":"nobody"));
	}
	return Plugin_Handled;
}

public OnClientPutInServer(client)
{
	if (IsFakeClient (client))
	return;

	if(ValidPlayer(client))
	{
		CreateTimer (30.0, WelcomeAdvertTimer, client);

		// reset cached group status
		bIsInGroup[client] = false;
		// repoll
		if(check_steamtools()) {
			new iGroupID = GetConVarInt(g_hClanID);
			if(iGroupID != 0) {
				Steam_RequestGroupStatus(client, iGroupID);
			}
		}
	}
}

public Action:WelcomeAdvertTimer (Handle:timer, any:client)
{
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidPlayer(x,false) && !IsFakeClient(x))
		{
			Steam_RequestGroupStatus(x, GetConVarInt(g_hClanID));
		}
	}
	//PrintToServer("[W3S] Repolling groupstatus...");

	decl String:ClientName[MAX_NAME_LENGTH] = "";
	if (ValidPlayer(client))
	{
		GetClientName (client, ClientName, sizeof (ClientName));
		decl String:buffer2[32] = "-W3E- TF2 WAR3EVOLUTION!";

		Format(ClientName, sizeof(ClientName), "\x01\x03%s\x01", ClientName);
		Format(buffer2, sizeof(buffer2), "\x01\x04%s\x01", buffer2);
		if(bIsInGroup[client])
		{
			PrintToChat(client, "\x01\x04[War3Evo]\x01 Welcome %s to our Steam Group %s",ClientName,buffer2);
		}
		else
		{
			PrintToChat(client, "\x01\x04[War3Evo]\x01 Welcome %s! Please join our Steam Group %s",ClientName,buffer2);
			PrintToChat(client, "\x01\x04[War3Evo]\x01 Visit to join: http://steamcommunity.com/groups/war3evo");
		}
		//PrintToChat (client, "\x01\x04[War3Source]\x01 Welcome! Please join our Steam Group ");
	}

	return Plugin_Stop;
}



/* SteamTools */


public Steam_FullyLoaded()
{
	g_bSteamTools = true;
}

public Steam_Shutdown()
{
	g_bSteamTools = false;
}

public Steam_GroupStatusResult(client, groupID, bool:bIsMember, bool:bIsOfficer)
{
	if(groupID == GetConVarInt(g_hClanID)) {
		if(ValidPlayer(client))
		{
			bIsInGroup[client] = bIsMember;
			if(!bIsMember)
			{
				PrintToChat(client, "\x01\x04[War3Evo]\x01 Please join our steam group War3Evo.");
			}
			else
			{
				PrintToChat(client, "\x01\x04[War3Evo]\x01 Thanks for joining our steam group!");
			}
		}
	}
}

// Checks if steamtools is currently running properly
stock bool:check_steamtools()
{
	/*if(HAS_STEAMTOOLS()) {
		if(!g_bSteamTools) {
			LogError("SteamTools was detected but not properly loaded");
			return false;
		}
		return true;
	}
	return false;*/
	return g_bSteamTools;
}