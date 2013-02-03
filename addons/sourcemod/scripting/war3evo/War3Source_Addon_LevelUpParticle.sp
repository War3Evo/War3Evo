#define PLUGIN_VERSION "0.0.0.1"
/**
 * File: War3Source_Addon_LevelUpParticle.sp
 * Description: Displays particles whenever somebody levels up.
 * Author(s): Glider & xDr.HaaaaaaaXx
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include "W3SIncs/War3Source_Interface"

public Plugin:myinfo = 
{
	name = "W3S - Addon - Display Particles on Level Up",
	author = "Glider & xDr.HaaaaaaaXx",
	description = "Displays particles whenever somebody levels up",
	version = "1.2",
};

public OnPluginStart()
{
	//CreateConVar("war3evo_AddonLevelUpParticle",PLUGIN_VERSION,"War3evo Addon Level Up Particle",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	LoadTranslations("w3s.addon.levelupparticle.phrases");	
}

public OnMapStart()
{
	War3_PrecacheParticle("achieved");
}

public OnWar3Event(W3EVENT:event, client)
{
	if (event == PlayerLeveledUp)
	{
		new String:name[32];
		GetClientName(client, name, sizeof(name));
		new String:racename[32];
		new race = War3_GetRace(client);
		
		new level = War3_GetLevel(client, race);
		
		AttachThrowAwayParticle(client, "achieved", NULL_VECTOR, "partyhat", 5.0);
		AttachThrowAwayParticle(client, "bday_1balloon", NULL_VECTOR, "partyhat", 5.0);
		AttachThrowAwayParticle(client, "bday_balloon01", NULL_VECTOR, "partyhat", 5.0);
		AttachThrowAwayParticle(client, "bday_balloon02", NULL_VECTOR, "partyhat", 5.0);
		
		for(new i=1;i<=MaxClients;i++){
			if(ValidPlayer(i)){
				SetTrans(i);
				War3_GetRaceName(race, racename, sizeof(racename));
				War3_ChatMessage(i, "%T", "{player} has leveled {racename} to {amount}", i, name, racename, level);
			}
		}
		
	}
}
