#define PLUGIN_VERSION "0.0.0.1"

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

#pragma semicolon 1
//#define PLUGIN_VERSION "1.0b"

new Handle:g_maxplayers = INVALID_HANDLE;
new Handle:g_addbots = INVALID_HANDLE;

new g_DiamondChecker[MAXPLAYERSCUSTOM];

//new bool:mapstarted;

///////////////////////////////////////////////////////////////////
// Plugin Info
//////////////////////////////////////////////////////////////////

public Plugin:myinfo =
{
	name = "War3Evo Engine Addon",
	author = "El Diablo",
	description = "Engine Addons",
	version = PLUGIN_VERSION,
	url = "http://www.war3evo.com"
};


public OnPluginStart()
{
	CreateConVar("war3evo_Engine_Addons",PLUGIN_VERSION,"War3evo Engine Addons",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	g_maxplayers = CreateConVar("War3Evo_maxplayers", "24", "The max amount of players your server can hold.");
	g_addbots = CreateConVar("War3Evo_addbots", "10", "When players are at or  below this number, set tf_bot_quota to this number.");
	CreateTimer(10.0,Timer_Checker,TIMER_REPEAT);
	CreateTimer(60.0,Timer_Diamonds);
}

public OnMapStart()
{
	//ServerCommand("tf_bot_quota 0");
	ServerCommand("sv_visiblemaxplayers 24");
}

public OnMapEnd()
{
	//ServerCommand("tf_bot_quota 0");
	ServerCommand("sv_visiblemaxplayers 24");
}

public Action:Timer_Mapstart(Handle:timer, any:userid)
{
//	mapstarted=false;
	CheckPlayers();
}

public Action:Timer_Checker(Handle:timer, any:userid)
{
	CheckPlayers();
}

public Action:Timer_Diamonds(Handle:timer, any:userid)
{
	for(new i=1; i<GetMaxClients(); i++)
	{
		//g_DiamondChecker[i]=g_DiamondChecker[i]+1;
		//if(g_DiamondChecker[i]>5 && ValidPlayer(i))
		if(ValidPlayer(i))
		{
			//g_DiamondChecker[i]=0;
			new GivePlayerDiamonds = War3_GetDiamonds(i) + 1;
			//new GivePlayerDiamonds = W3GetPlayerProp(i, PlayerDiamonds) + 1;
			War3_SetDiamonds(i, GivePlayerDiamonds);
			//W3SetPlayerProp(i, PlayerDiamonds, GivePlayerDiamonds);
		}
	}
	CreateTimer(60.0,Timer_Diamonds);
}

//HACK, THIS IS A BAD HACK - Dagothur 1/13/2013
new String:itembuffer2[512];

//HERE'S ANOTHER LOL - Dagothur 1/13/2013
public OnWar3Event(W3EVENT:event,client){
	// Record Items before death
	if(event==OnDeathPre)
	{
		//Check to see if Player owns any items, if so.. record those items,
		// otherwise keep the current record.
		Format(itembuffer2, sizeof(itembuffer2), "");
		if(GetClientItemsOwned(client)>0)
		{
			new ItemsLoaded = W3GetItemsLoaded();
			decl String:itemname[64];
			for(new x=1;x<=ItemsLoaded;x++)
			{
					if(War3_GetOwnsItem(client,x)) {
						W3GetItemName(x,itemname,sizeof(itemname));
						Format(itembuffer2, sizeof(itembuffer2),"\x01|\x05%s%s", itemname, itembuffer2);
					}
			}
			Format(itembuffer2, sizeof(itembuffer2),"%s\x01|", itembuffer2);
		}
		else 
		{
			Format(itembuffer2, sizeof(itembuffer2), "\x01<\x05no items\x01>");
		}
	}
}


public OnWar3EventDeath(victim, attacker, deathrace, distance, attacker_hpleft)
{
	if(victim!=attacker&&ValidPlayer(victim)&&ValidPlayer(attacker))
	{
		decl String:msgbuffer[256 + MAX_NAME_LENGTH];
		// El Diablo (Flame Predator level 20) killed you from %i feet %i hp left.
		new String:attackerName[32];
		new String:attackerRaceName[32];
		GetClientName(attacker,attackerName,64);
		new attackerraceid = War3_GetRace(attacker);
		War3_GetRaceName(attackerraceid,attackerRaceName,64);
		new attackerlevel = War3_GetLevel(attacker, attackerraceid);

		new ItemsLoaded = W3GetItemsLoaded();
		if(GetClientItemsOwned(attacker)>0)
		{
			decl String:itemname[64];
			new String:itembuffer[512]; // handle 8 items .. 64 * 8
			for(new x=1;x<=ItemsLoaded;x++)
			{
				if(War3_GetOwnsItem(attacker,x))
				{
					W3GetItemName(x,itemname,sizeof(itemname));
					Format(itembuffer, sizeof(itembuffer),"\x01|\x05%s%s", itemname, itembuffer);
				}
			}
			Format(itembuffer, sizeof(itembuffer),"%s\x01|", itembuffer);
			Format(msgbuffer, sizeof(msgbuffer),"\x04[War3Evo] \x05%s \x01(\x05%s \x01level \x05%i\x01) \x01killed you from \x05%i \x01feet with \x05%i \x01hp left. Carrying following items:", attackerName, attackerRaceName, attackerlevel, distance, attacker_hpleft);
			CSayText2(victim,attacker,msgbuffer);
			CSayText2(victim,attacker,itembuffer);
		}
		else
		{
			Format(msgbuffer, sizeof(msgbuffer),"\x04[War3Evo] \x05%s \x01(\x05%s \x01level \x05%i\x01) \x01killed you from \x05%i \x01feet with \x05%i \x01hp left. Carrying following items: \x01<\x05no items\x01>", attackerName, attackerRaceName, attackerlevel, distance, attacker_hpleft);
			CSayText2(victim,attacker,msgbuffer);
		}
		
		//hack to display the reverse to the killer; note how the var names remain but they are pulling the opposite info - Dagothur 1/13/2013
		GetClientName(victim,attackerName,64);
		attackerraceid = War3_GetRace(victim);
		War3_GetRaceName(attackerraceid,attackerRaceName,64);
		attackerlevel = War3_GetLevel(victim, attackerraceid);

		Format(msgbuffer, sizeof(msgbuffer),"\x04[War3Evo] \x05You \x01killed \x05%s \x01(\x05%s \x01level \x05%i\x01) \x01 from \x05%i \x01feet with \x05%i \x01hp left. They carried the following items:", attackerName, attackerRaceName, attackerlevel, distance, attacker_hpleft);
		CSayText2(attacker,victim,msgbuffer);
		CSayText2(attacker,victim,itembuffer2);
	}
	// VIP INSTANT RESPAWN
	if(ValidPlayer(victim))
	{
		if(GetAdminFlag(GetUserAdmin(victim), Admin_Reservation))
		{
			CreateTimer(1.0,instaspawn,victim);
		}
	}
}


// Color levels
public OnRaceChanged(client,oldrace,newrace)
{
	if(GetClientTeam (client)==2 && ValidPlayer(client)) //red team
	{
		W3ResetPlayerColor(client, oldrace);
		new a = War3_GetLevel(client, newrace);
		if(a>=0 && a<=7)
		{
			W3ResetPlayerColor(client, newrace);
		}
		if(a>=8 && a<=14)
		{
			W3SetPlayerColor(client,newrace,255,200,0,_,GLOW_OVERRIDE); //255,200,0);
		}
		if(a>=15)
		{
			W3SetPlayerColor(client,newrace,255,0,0,_,GLOW_OVERRIDE); //255,200,0);
		}
	}
	else if(GetClientTeam (client)==3 && ValidPlayer(client)) //blue team
	{
		W3ResetPlayerColor(client, oldrace);
		new a = War3_GetLevel(client, newrace);
		if(a>=0 && a<=7)
		{
			W3ResetPlayerColor(client, newrace);
		}
		if(a>=8 && a<=14)
		{
			W3SetPlayerColor(client,newrace,0,255,255,_,GLOW_OVERRIDE); //255,200,0);
		}
		if(a>=15)
		{
			W3SetPlayerColor(client,newrace,0,128,255,_,GLOW_OVERRIDE); //255,200,0);
		}
	}
}

public Action:instaspawn(Handle:timer, any:client)
{
	if(ValidPlayer(client))
	{
		TF2_RespawnPlayer(client);
		PrintToChat(client, "[Instant Repsawn for VIP only]");
	}
}


public OnWar3EventSpawn(client)
{
	new newrace = War3_GetRace(client);
	if(GetClientTeam (client)==2 && ValidPlayer(client)) //red team
	{
		new a = War3_GetLevel(client, newrace);
		if(a>=0 && a<=7)
		{
			W3ResetPlayerColor(client, newrace);
		}
		if(a>=8 && a<=14)
		{
			W3SetPlayerColor(client,newrace,255,200,0,_,GLOW_OVERRIDE); //255,200,0);
		}
		if(a>=15)
		{
			W3SetPlayerColor(client,newrace,255,0,0,_,GLOW_OVERRIDE); //255,200,0);
		}
	}
	else if(GetClientTeam (client)==3 && ValidPlayer(client)) //blue team
	{
		new a = War3_GetLevel(client, newrace);
		if(a>=0 && a<=7)
		{
			W3ResetPlayerColor(client, newrace);
		}
		if(a>=8 && a<=14)
		{
			W3SetPlayerColor(client,newrace,0,255,255,_,GLOW_OVERRIDE); //255,200,0);
		}
		if(a>=15)
		{
			W3SetPlayerColor(client,newrace,0,128,255,_,GLOW_OVERRIDE); //255,200,0);
		}
	}
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	//DP("condition added");
	if(TF2_IsPlayerInCondition(client, TFCond_Disguising) && ValidPlayer(client))
	{
		//DP("disguised");
		W3ResetPlayerColor(client, War3_GetRace(client));
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	//DP("condition removed");
	if(!TF2_IsPlayerInCondition(client, TFCond_Disguised) && ValidPlayer(client))
	{
		//DP("not disguised");
		SetPlayerColor(client);
	}
}

SetPlayerColor(client)
{
	new newrace = War3_GetRace(client);
	if(GetClientTeam (client)==2 && ValidPlayer(client)) //red team
	{
		new a = War3_GetLevel(client, newrace);
		if(a>=0 && a<=7)
		{
			W3ResetPlayerColor(client, newrace);
		}
		if(a>=8 && a<=14)
		{
			W3SetPlayerColor(client,newrace,255,200,0,_,GLOW_OVERRIDE); //255,200,0);
		}
		if(a>15)
		{
			W3SetPlayerColor(client,newrace,255,0,0,_,GLOW_OVERRIDE); //255,200,0);
		}
	}
	else if(GetClientTeam (client)==3 && ValidPlayer(client)) //blue team
	{
		new a = War3_GetLevel(client, newrace);
		if(a>=0 && a<=7)
		{
			W3ResetPlayerColor(client, newrace);
		}
		if(a>=8 && a<=14)
		{
			W3SetPlayerColor(client,newrace,0,255,255,_,GLOW_OVERRIDE); //255,200,0);
		}
		if(a>15)
		{
			W3SetPlayerColor(client,newrace,0,128,255,_,GLOW_OVERRIDE); //255,200,0);
		}
	}
}

public OnClientDisconnect_Post(client)
{
	CheckPlayers();
	g_DiamondChecker[client]=0;
}

public OnClientConnected(client)
{
	CheckPlayers();
}

stock GetRealClientCount( bool:inGameOnly = true ) {
	new clients = 0;
	for(new i=1; i<GetMaxClients(); i++) {
		if(((inGameOnly) ? IsClientInGame(i): IsClientConnected(i)) && !IsFakeClient(i)){
			clients++;
		}
	}
	return clients;
}

stock CheckPlayers()
{
	new clients = GetRealClientCount(false);
	new maxplayers = GetConVarInt(g_maxplayers);
	new addbots = GetConVarInt(g_addbots);

	if(clients<maxplayers)
	{
		// Check to see if within quickplay standards
		if(clients<24)
			clients=24;
		else
			clients = clients + 1;
		if(clients>maxplayers)
			clients=maxplayers;

		ServerCommand("sv_visiblemaxplayers %i",clients);

		clients = GetRealClientCount(true);
		//addbots = addbots - clients;
		// If player count is below this number, then add bots.
		if(clients>addbots)
		{
			ServerCommand("tf_bot_quota 0");
		}
		else
		{
			//ServerCommand("tf_bot_quota %i",addbots);
		}
	}
}

