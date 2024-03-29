#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define PL_VERSION "0.6"

#define TF_CLASS_DEMOMAN		4
#define TF_CLASS_ENGINEER		9
#define TF_CLASS_HEAVY			6
#define TF_CLASS_MEDIC			5
#define TF_CLASS_PYRO				7
#define TF_CLASS_SCOUT			1
#define TF_CLASS_SNIPER			2
#define TF_CLASS_SOLDIER		3
#define TF_CLASS_SPY				8
#define TF_CLASS_UNKNOWN		0

#define TF_TEAM_BLU					3
#define TF_TEAM_RED					2

public Plugin:myinfo =
{
	name        = "TF2 Class Restrictions",
	author      = "Tsunami",
	description = "Restrict classes in TF2.",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
}

new g_iClass[MAXPLAYERS + 1];
new Handle:g_hEnabled;
new Handle:g_hFlags;
new Handle:g_hImmunity;
new Handle:g_hLimits[4][10];
//new String:g_sSounds[10][24] = {"", "vo/scout_no03.wav",   "vo/sniper_no04.wav", "vo/soldier_no01.wav",
//																		"vo/demoman_no03.wav", "vo/medic_no03.wav",  "vo/heavy_no02.wav",
//																		"vo/pyro_no01.wav",    "vo/spy_no02.wav",    "vo/engineer_no03.wav"};

public OnPluginStart()
{
	CreateConVar("sm_classrestrict_version", PL_VERSION, "Restrict classes in TF2.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled                                = CreateConVar("sm_classrestrict_enabled",       "1",  "Enable/disable restricting classes in TF2.");
	g_hFlags                                  = CreateConVar("sm_classrestrict_flags",         "a",   "Admin flags for restricted classes in TF2.");
	g_hImmunity                               = CreateConVar("sm_classrestrict_immunity",      "1",  "Enable/disable admins being immune for restricted classes in TF2.");
	g_hLimits[TF_TEAM_BLU][TF_CLASS_DEMOMAN]  = CreateConVar("sm_classrestrict_blu_demomen",   "3", "Limit for Blu demomen in TF2.");
	g_hLimits[TF_TEAM_BLU][TF_CLASS_ENGINEER] = CreateConVar("sm_classrestrict_blu_engineers", "3", "Limit for Blu engineers in TF2.");
	g_hLimits[TF_TEAM_BLU][TF_CLASS_HEAVY]    = CreateConVar("sm_classrestrict_blu_heavies",   "2", "Limit for Blu heavies in TF2.");
	g_hLimits[TF_TEAM_BLU][TF_CLASS_MEDIC]    = CreateConVar("sm_classrestrict_blu_medics",    "3", "Limit for Blu medics in TF2.");
	g_hLimits[TF_TEAM_BLU][TF_CLASS_PYRO]     = CreateConVar("sm_classrestrict_blu_pyros",     "3", "Limit for Blu pyros in TF2.");
	g_hLimits[TF_TEAM_BLU][TF_CLASS_SCOUT]    = CreateConVar("sm_classrestrict_blu_scouts",    "2", "Limit for Blu scouts in TF2.");
	g_hLimits[TF_TEAM_BLU][TF_CLASS_SNIPER]   = CreateConVar("sm_classrestrict_blu_snipers",   "2", "Limit for Blu snipers in TF2.");
	g_hLimits[TF_TEAM_BLU][TF_CLASS_SOLDIER]  = CreateConVar("sm_classrestrict_blu_soldiers",  "3", "Limit for Blu soldiers in TF2.");
	g_hLimits[TF_TEAM_BLU][TF_CLASS_SPY]      = CreateConVar("sm_classrestrict_blu_spies",     "2", "Limit for Blu spies in TF2.");
	g_hLimits[TF_TEAM_RED][TF_CLASS_DEMOMAN]  = CreateConVar("sm_classrestrict_red_demomen",   "3", "Limit for Red demomen in TF2.");
	g_hLimits[TF_TEAM_RED][TF_CLASS_ENGINEER] = CreateConVar("sm_classrestrict_red_engineers", "3", "Limit for Red engineers in TF2.");
	g_hLimits[TF_TEAM_RED][TF_CLASS_HEAVY]    = CreateConVar("sm_classrestrict_red_heavies",   "2", "Limit for Red heavies in TF2.");
	g_hLimits[TF_TEAM_RED][TF_CLASS_MEDIC]    = CreateConVar("sm_classrestrict_red_medics",    "3", "Limit for Red medics in TF2.");
	g_hLimits[TF_TEAM_RED][TF_CLASS_PYRO]     = CreateConVar("sm_classrestrict_red_pyros",     "3", "Limit for Red pyros in TF2.");
	g_hLimits[TF_TEAM_RED][TF_CLASS_SCOUT]    = CreateConVar("sm_classrestrict_red_scouts",    "2", "Limit for Red scouts in TF2.");
	g_hLimits[TF_TEAM_RED][TF_CLASS_SNIPER]   = CreateConVar("sm_classrestrict_red_snipers",   "2", "Limit for Red snipers in TF2.");
	g_hLimits[TF_TEAM_RED][TF_CLASS_SOLDIER]  = CreateConVar("sm_classrestrict_red_soldiers",  "3", "Limit for Red soldiers in TF2.");
	g_hLimits[TF_TEAM_RED][TF_CLASS_SPY]      = CreateConVar("sm_classrestrict_red_spies",     "2", "Limit for Red spies in TF2.");
	
	HookEvent("player_changeclass", Event_PlayerClass);
	HookEvent("player_spawn",       Event_PlayerSpawn);
	HookEvent("player_team",        Event_PlayerTeam);
}

public OnClientPutInServer(client)
{
	g_iClass[client] = TF_CLASS_UNKNOWN;
}

public Event_PlayerClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	//DP("A Player Changed Class");

	new iClient = GetClientOfUserId(GetEventInt(event, "userid")),
			iClass  = GetEventInt(event, "class"),
			iTeam   = GetClientTeam(iClient);
	
	if(!(GetConVarBool(g_hImmunity) && IsImmune(iClient)) && IsFull(iTeam, iClass, false))
	{
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		PrintCenterText(iClient,"That class is at capacity!");
		TF2_SetPlayerClass(iClient, TFClassType:g_iClass[iClient]);
	}
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid")),
			iTeam   = GetClientTeam(iClient);
	
	if(!(GetConVarBool(g_hImmunity) && IsImmune(iClient)) && IsFull(iTeam, (g_iClass[iClient] = _:TF2_GetPlayerClass(iClient))))
	{
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		PrintCenterText(iClient,"That class is at capacity!");
		PickClass(iClient);
	}
}

public Event_PlayerTeam(Handle:event,  const String:name[], bool:dontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(event, "userid")),
			iTeam   = GetEventInt(event, "team");
	
	if(!(GetConVarBool(g_hImmunity) && IsImmune(iClient)) && IsFull(iTeam, g_iClass[iClient]))
	{
		ShowVGUIPanel(iClient, iTeam == TF_TEAM_BLU ? "class_blue" : "class_red");
		PrintCenterText(iClient,"That class is at capacity!");
		PickClass(iClient);
	}
}

bool:IsFull(iTeam, iClass, bool:countImmunes=true)
{
	// If plugin is disabled, or team or class is invalid, class is not full
	if(!GetConVarBool(g_hEnabled) || iTeam < TF_TEAM_RED || iClass < TF_CLASS_SCOUT)
		return false;
	
	// Get team's class limit
	new iLimit,
			Float:flLimit = GetConVarFloat(g_hLimits[iTeam][iClass]);
	
	// If limit is a percentage, calculate real limit
	if(flLimit > 0.0 && flLimit < 1.0)
		iLimit = RoundToNearest(flLimit * GetTeamClientCount(iTeam));
	else
		iLimit = RoundToNearest(flLimit);
	
	// If limit is -1, class is not full
	if(iLimit == -1)
		return false;
	// If limit is 0, class is full
	else if(iLimit == 0)
		return true;
	
	// Loop through all clients
	for(new i = 1, iCount = 0; i <= MaxClients; i++)
	{
		if(!countImmunes)
		{
			if (GetConVarBool(g_hImmunity) && IsImmune(i))
				continue;
		}

		// If client is in game, on this team, has this class and limit has been reached, class is full
		if(IsClientInGame(i) && GetClientTeam(i) == iTeam && _:TF2_GetPlayerClass(i) == iClass && ++iCount > iLimit)
			return true;
	}
	
	return false;
}

bool:IsImmune(iClient)
{
	if(!iClient || !IsClientInGame(iClient))
		return false;

	if(IsFakeClient(iClient))
		return true;
	
	decl String:sFlags[32];
	GetConVarString(g_hFlags, sFlags, sizeof(sFlags));
	
	// If flags are specified and client has generic or root flag, client is immune
	return !StrEqual(sFlags, "") && GetUserFlagBits(iClient) && (ReadFlagString(sFlags)|ADMFLAG_ROOT);
}

PickClass(iClient)
{
	// Loop through all classes, starting at random class
	for(new i = GetRandomInt(TF_CLASS_SCOUT, TF_CLASS_ENGINEER), iClass = i, iTeam = GetClientTeam(iClient);;)
	{
		// If team's class is not full, set client's class
		if(!IsFull(iTeam, i))
		{
			TF2_SetPlayerClass(iClient, TFClassType:i);
			TF2_RespawnPlayer(iClient);
			g_iClass[iClient] = i;
			break;
		}
		// If next class index is invalid, start at first class
		else if(++i > TF_CLASS_ENGINEER)
			i = TF_CLASS_SCOUT;
		// If loop has finished, stop searching
		else if(i == iClass)
			break;
	}
}