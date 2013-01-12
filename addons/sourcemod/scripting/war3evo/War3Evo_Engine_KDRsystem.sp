//////////////////////////////////////////////////////////////////
// Kill Death Ratio Checker By HSFighter / www.hsfighter.net
//////////////////////////////////////////////////////////////////

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

#pragma semicolon 1
#define PLUGIN_VERSION "1.1"

//////////////////////////////////////////////////////////////////
// Declaring Natives (Test --> Disbaled Now)
//////////////////////////////////////////////////////////////////

// native SBBanPlayer(client, target, time, String:reason[]);

//////////////////////////////////////////////////////////////////
// Declaring variables and handles
//////////////////////////////////////////////////////////////////

new Handle:KDCheckerEnabled;
new Handle:KDCheckerShowRoundEnd;
new Handle:KDCheckerShowOnKill;
//new Handle:KDCheckerWatchEnabled;
//new Handle:KDCheckerEnabledCheckRate;
new Handle:KDCheckerRate;
//new Handle:KDCheckerKills;
//new Handle:KDCheckerActionMode;
//new Handle:KDCheckerBanTime;
//new Handle:KDCheckerDebug;


//new g_bSBAvailable = false;
//new g_bDemoRecord = false;

new Float:KDRNegEffects[MAXPLAYERSCUSTOM][5];

new Deaths[MAXPLAYERSCUSTOM];
new Kills[MAXPLAYERSCUSTOM];
//new String:kdrClientName[MAXPLAYERSCUSTOM][64];

//////////////////////////////////////////////////////////////////
// Plugin Info
//////////////////////////////////////////////////////////////////

public Plugin:myinfo =
{
	name = "KDR Checker",
	author = "El Diablo",
	description = "Kill Death Ratio Checker",
	version = PLUGIN_VERSION,
	url = "http://www.war3evo.com"
};


//////////////////////////////////////////////////////////////////
// Start plugin
//////////////////////////////////////////////////////////////////

new Handle:KDRtrie = INVALID_HANDLE;

public OnPluginStart()
{
	// Create convars  mm
	CreateConVar("War3Evo_KDR", PLUGIN_VERSION, "War3Evo KDR Montioring System", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	KDCheckerEnabled          = CreateConVar("sm_kdrc_enable",          "1",    "Enable/Disable KD Checker", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	KDCheckerShowRoundEnd     = CreateConVar("sm_kdrc_show_roundend",   "1",    "Show KD Rate to player on roundend", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	KDCheckerShowOnKill       = CreateConVar("sm_kdrc_show_kill",   	"0",    "Show KD Rate to attacker on kill", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	//KDCheckerWatchEnabled     = CreateConVar("sm_kdrc_watch_enable",    "0",    "Enable/Disable KD Rate watching", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	KDCheckerRate             = CreateConVar("sm_kdrc_watch_rate",      "4.0",  "KD Rate for a player before action", FCVAR_PLUGIN, true, 1.0);
	//KDCheckerKills            = CreateConVar("sm_kdrc_watch_kills",     "10",   "Count of kills before a player is checked", FCVAR_PLUGIN, true, 1.0);
	//KDCheckerEnabledCheckRate = CreateConVar("sm_kdrc_watch_checkrate", "15.0",	"Rate in seconds at players KD Rate are checked", FCVAR_PLUGIN, true, 1.0);
	//KDCheckerActionMode       = CreateConVar("sm_kdrc_watch_action",    "2",    "Action for affected player (0 = kick, 1 = ban, 2=War3Evo)", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	//KDCheckerBanTime          = CreateConVar("sm_kdrc_watch_bantime",   "60",   "Amount of time in Minutes to ban if using 'sm_kdrc_watch_action = 1' (0 = perm)", _, true, 0.0);
	//KDCheckerDebug     		  = CreateConVar("sm_kdrc_debug",   		"0",    "Debug playercheck to serverlog", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	// Register Console Commands
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say2", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	RegConsoleCmd("sm_kdr", ShowKDRateToClientCmd);

	// Admin command
	RegAdminCmd("sm_playerskdr",Command_PlayerKDR,ADMFLAG_KICK,"Allows an administrator to see all players KDR.");

	// Hook Events
	HookEvent("round_end", EventRoundEnd);
	HookEvent("player_death", hookPlayerDie, EventHookMode_Post);
	
	KDRtrie=CreateTrie();
	
	// Autoexec / Create Configfile
	AutoExecConfig(true, "plugin.kdcheck");
}


//////////////////////////////////////////////////////////////////
// Native AskPluginLoad2 so that APLRes can be used. (Test --> Disbaled Now)
//////////////////////////////////////////////////////////////////

/*public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("SBBanPlayer");
	return APLRes_Success;
}*/


//////////////////////////////////////////////////////////////////
// Check if sourcebans present 
//////////////////////////////////////////////////////////////////

/*
public OnAllPluginsLoaded()
{
	if (LibraryExists("sourcebans"))
	{
		g_bSBAvailable = true;
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "sourcebans"))
	{
		g_bSBAvailable = true;
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "sourcebans"))
	{
		g_bSBAvailable = false;
	}
}
*/


//////////////////////////////////////////////////////////////////
// Action: Say Command
//////////////////////////////////////////////////////////////////

public Action:Command_Say(client, args)
{
	
    // Check if plugin is disbaled
	if(GetConVarInt(KDCheckerEnabled) != 1)
	{  
		return Plugin_Continue;	
	}
		
	// Check if player ok
	if (!client)
	{
		return Plugin_Continue;
	}

	// Declaring variables
	decl String:text[192], String:command[64];
	new startidx = 0;

	// Check saycommand is valid
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}

	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}

	// Check saycommand type
	GetCmdArg(0, command, sizeof(command));
	if (strcmp(command, "say2", false) == 0)
	{
		startidx += 4;
	}

	// Is saycommand "kdr" show KD-Rate to player
	if (strcmp(text[startidx], "kdr", false) == 0)
	{
		ShowKDRateToClient(client, 0);
		
	}
	
	return Plugin_Continue;
}


//////////////////////////////////////////////////////////////////
// Action: Send KD Rate Text to Client Cmd
//////////////////////////////////////////////////////////////////

public Action:ShowKDRateToClientCmd(client, args){

	ShowKDRateToClient(client, 0);

}

//////////////////
/// ADMIN COMMAND
/////////////////

public Action:Command_PlayerKDR(client, args)
{
	decl String:player_name[65];
	for (new i = 1; i <= MaxClients; i++)
	{
		if(ValidPlayer(i)&&!IsFakeClient(i))
		{
			GetClientName(i, player_name, sizeof(player_name));

			// Get Deaths, Kills and KD Rate
			//new Deaths = GetClientDeaths(i);
			//new Frags = GetClientFrags(i);
			new zDeaths = Deaths[i];
			new zFrags = Kills[i];
			new Float:KDRate = float(zFrags)/float(zDeaths);

			if ((zDeaths == 0) && (zFrags != 0)) KDRate = float(zFrags);
			if (zFrags < 0) KDRate = float(0);

			// Print Client KDR to Admin
			PrintToChat(client, "\x01[\x04War3Evo|KDR|\x01] \x03%s\x04, KDR is \x03%.2f \x04(\x03%i \x04Kills / \x03%i \x04Deaths)", player_name, KDRate, zFrags, zDeaths);
		}
	}
	return Plugin_Handled;
}

//////////////////////////////////////////////////////////////////
// Action: Send KD Rate Text to Client
//////////////////////////////////////////////////////////////////

public Action:ShowKDRateToClient(client, offset){
	
	decl String:player_name[65];
	GetClientName(client, player_name, sizeof(player_name));
	
	// Get Deaths, Kills and KD Rate
	//new Deaths = GetClientDeaths(client);
	//new Frags = GetClientFrags(client) + offset;
	new zDeaths = Deaths[client];
	new zFrags = Kills[client]+offset;
	new Float:KDRate = float(zFrags)/float(zDeaths);
	
	if ((zDeaths == 0) && (zFrags != 0)) KDRate = float(zFrags);
	if (zFrags < 0) KDRate = float(0);
	
	// Print KDR to Client
	PrintToChat(client, "\x01[\x04War3Evo|KDR|\x01] \x03%s\x04, your KDR is \x03%.2f \x04(\x03%i \x04Kills / \x03%i \x04Deaths)", player_name, KDRate, zFrags, zDeaths);
	return Plugin_Handled;	
}


//////////////////////////////////////////////////////////////////
// Action: Event Roundstart
//////////////////////////////////////////////////////////////////


public Action:EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		Deaths[i]=0;
		Kills[i]=0;
	}

	// Check if "Plugin" is disbaled or "show kdr on roundend" is disbaled
	if((GetConVarInt(KDCheckerEnabled) != 1) || (GetConVarInt(KDCheckerShowRoundEnd) != 1)) return Plugin_Continue;
	
	// Get all clients on the server
	for (new i = 1; i <= MaxClients; i++)
	{
		//Check if player ok
		if (IsClientConnected(i) && IsClientInGame(i) && !IsClientBot(i))
		{
			ShowKDRateToClient(i, 0);			
		}
	}	
	return Plugin_Continue;

}

//////////////////////////////////////////////////////////////////
// Action: Event Player Die
//////////////////////////////////////////////////////////////////


public Action:hookPlayerDie(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Check if "Plugin" is disbaled or "show kdr on kill" is disbaled
	//if((GetConVarInt(KDCheckerEnabled) != 1) || (GetConVarInt(KDCheckerShowOnKill) != 1)) return Plugin_Continue;
	
	new attackerid = GetEventInt(event, "attacker");

	new assisterid = GetEventInt(event, "assister");

	new victimid = GetEventInt(event, "userid");


	new bool:deadringereath=false;
	if(victimid>0)
	{
		new deathFlags = GetEventInt(event, "death_flags");
		if (deathFlags & 32)
		{
			deadringereath=deadringereath?true:true; //stfu
			//DP("dead ringer kill");
		}
	}


	if(victimid!=attackerid&&attackerid>0&&!deadringereath)
	{
		new Attacker =  GetClientOfUserId(attackerid);
		new Assister =  GetClientOfUserId(assisterid);
		new Victim =  GetClientOfUserId(victimid);

		Deaths[Victim]++;
		Kills[Attacker]++;
		Kills[Assister]++;

		if((GetConVarInt(KDCheckerEnabled) != 1) || (GetConVarInt(KDCheckerShowOnKill) != 1)) return Plugin_Continue;

		// Check if player ok
		if (IsClientConnected(Attacker) && IsClientInGame(Attacker))
		{
			ShowKDRateToClient(Attacker, 1);
		}
	}
	return Plugin_Continue;
}

public OnWar3Event(W3EVENT:event,client)
{
	if(event==InitPlayerVariables&&!IsFakeClient(client))
	{
		new String:steamid[32];
		new KDR[2];

		GetClientAuthString(client,steamid,sizeof(steamid));
		//DP("STEAMID %s",steamid);

		if(GetTrieArray(KDRtrie,steamid,KDR,2))
		{
			new String:clientKDRname[64];
			GetClientName(client,clientKDRname,64);

			PrintToChatAll("\x01[\x04War3Evo|KDR|\x01] KDR Tracking %s connected.",clientKDRname);
			PrintToChat(client,"\x01[\x04War3Evo|KDR|\x01] KDR Kills: %i",KDR[0]);
			PrintToChat(client,"\x01[\x04War3Evo|KDR|\x01] KDR Deaths: %i",KDR[1]);

			//was commented out
			for (new i = 1; i <= MaxClients; i++)
			{
				DP("checking thru clients for admins");
				new AdminId:admin = GetUserAdmin(client);
				if(admin != INVALID_ADMIN_ID) //flag is required and this client is not admin
				{
					new AdminFlag:flag;
					new String:requiredflagstr[1]="d";
					if (FindFlagByChar(requiredflagstr[0], flag)) //this gets the flag class from the string
					{
						if (GetAdminFlag(admin, flag))
						{
							PrintToChat(i,"\x01[\x04War3Evo|KDR|\x01] [KDR Tracking] User %s has returned! STEAMID: %s",clientKDRname,steamid);
							PrintToChat(i,"\x01[\x04War3Evo|KDR|\x01] KDR Kills: %i",KDR[0]);
							PrintToChat(i,"\x01[\x04War3Evo|KDR|\x01] KDR Deaths: %i",KDR[1]);
						}
					}
				}
			}


 /*
		ADMFLAG_RESERVATION
		ADMFLAG_GENERIC
		ADMFLAG_KICK
		ADMFLAG_BAN
		ADMFLAG_UNBAN
		ADMFLAG_SLAY
		ADMFLAG_CHANGEMAP
		ADMFLAG_CONVARS
		ADMFLAG_CONFIG
		ADMFLAG_CHAT
		ADMFLAG_VOTE
		ADMFLAG_PASSWORD
		ADMFLAG_RCON
		ADMFLAG_CHEATS
		ADMFLAG_CHEATS
		ADMFLAG_CUSTOM1
		ADMFLAG_CUSTOM2
		ADMFLAG_CUSTOM3
		ADMFLAG_CUSTOM4
		ADMFLAG_CHEATS
		ADMFLAG_CUSTOM6
*/
			//DP("steamid %s",steamid);
			//DP("KDR Kills = %i",KDR[0]);
			//DP("KDR Deaths = %i",KDR[1]);
			Kills[client]=KDR[0];
			Deaths[client]=KDR[1];
		}
		else
		{
			PrintToChat(client,"\x01[\x04War3Evo|KDR|\x01] KDR Tracking System %s has loaded.",PLUGIN_VERSION);
			KDR[0]=0;
			KDR[1]=0;
			SetTrieArray(KDRtrie,steamid,KDR,2);
		}
	}
}

public OnClientDisconnect(client)
{

	if(client>0&&!IsFakeClient(client))
	{
		new String:steamid[32]; //
		new KDR[2];
		KDR[0]=Kills[client];
		KDR[1]=Deaths[client];

		GetClientAuthString(client,steamid,32);
		SetTrieArray(KDRtrie,steamid,KDR,2);
		//DP("disconnected steamid %s",steamid);
	}

	KDRNegEffects[client][0]=0.0;
	KDRNegEffects[client][1]=0.0;
	KDRNegEffects[client][2]=0.0;
	KDRNegEffects[client][3]=0.0;
//KillTimer[client]=true;
	Deaths[client]=0;
	Kills[client]=0;
}

//////////////////////////////////////////////////////////////////
// Function: Is client a bot
//////////////////////////////////////////////////////////////////


public bool:IsClientBot(client)
{
	decl String:SteamID[64];
	// Get Steam ID
	GetClientAuthString(client, SteamID, sizeof(SteamID));
	
	//Check if BOT
	if (!IsFakeClient(client) && !StrEqual(SteamID, "BOT") && !StrEqual(SteamID, "STEAM_ID_PENDING")) return false;

	return true;
}

//////////////////////////////////////////////////////////////////
//   OnW3TakeDmgAll  -- DAMAGE MODIFICATION:
//////////////////////////////////////////////////////////////////
//FF triggers this function!!! even though it didnt damage any teammate
//THIS is a theoretical damage given by the engine, if u want real damage dealt use the hurt-event
//use natives to retrieve inflictor and game damagetype
//becareful when using this, u should only use this to reduce incoming damage. if you want to return damge, only use on bullet (first trigger damage)(below) or check IsBullet
//you may set damage mod percent HERE
//you may NOT DAMAGE IN HERE
//g_CurDMGModifierPercent*=num;
//War3_DamageModPercent(num)
public OnW3TakeDmgAllPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim)&&ValidPlayer(attacker))
	{
		// attacker
		new KDR_Deaths = Deaths[attacker];
		new KDR_Frags = Kills[attacker];
		new Float:attacker_KDRate = float(KDR_Frags)/float(KDR_Deaths);

		if ((KDR_Deaths == 0) && (KDR_Frags != 0)) attacker_KDRate = float(KDR_Frags);
		if (KDR_Frags < 0) attacker_KDRate = float(0);

		if (attacker_KDRate >= GetConVarFloat(KDCheckerRate))
		{
			// victim
			KDR_Deaths = Deaths[victim];
			KDR_Frags = Kills[victim];
			new Float:victim_KDRate = float(KDR_Frags)/float(KDR_Deaths);

			if ((KDR_Deaths == 0) && (KDR_Frags != 0)) victim_KDRate = float(KDR_Frags);
			if (KDR_Frags < 0) victim_KDRate = float(0);

			// Do math
			if(attacker_KDRate>victim_KDRate)
			{
				new Float:do_the_math = (FloatAbs(attacker_KDRate - victim_KDRate) * 0.10);
				War3_DamageModPercent(do_the_math);
				DP("Attacker KDR %.2f",attacker_KDRate);
				DP("Victim KDR %.2f",victim_KDRate);
				DP("Damage Reduction %.2f",do_the_math);
			}
		}
	}
}


//////////////////////////////////////////////////////////////////
// End Plugin
//////////////////////////////////////////////////////////////////

public OnPluginEnd(){
	
	//CloseHandle(TimeHandle);
	CloseHandle(KDRtrie);   // temporary removed trie
}

//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////