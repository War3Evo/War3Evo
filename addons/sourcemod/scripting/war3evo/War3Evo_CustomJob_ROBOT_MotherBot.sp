/* ========================================================================== */
/*                                                                            */
/*   War3Source_CustomJob_ROBOT_MotherBot.sp                                  */
/*   (c) 2012 El Diablo                                                       */
/*                          Sentry Buster Race                                */
/*   Description  A Race for developers whom want to test vanilla             */
/*                players (players without any modifications) vs              */
/*                what ever race they wish to go against.                     */
/* ========================================================================== */
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
public W3ONLY(){} //unload this?

// War3Source stuff
new thisRaceID;

new Float:vicorigvec[MAXPLAYERSCUSTOM][3];

new SKILL_REVENGE;

public Plugin:myinfo =
{
	name = "Race - Sentry Buster",
	author = "El Diablo",
	description = "A Race for making Sentry Busters Stronger.",
	version = "1.0.0.0",
	url = "http://Www.war3evo.Com"
};
public OnPluginStart()
{
	CreateTimer(3.0,Check_Bot_ClassName_Timer,_,TIMER_REPEAT);
	//CreateConVar("war3evo_mvm_bot1","Mother Bot","War3Evolution MVM Bot Enhancements.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	//HookEvent("object_destroyed", Event_ObjectDestroyed, EventHookMode_Post);
	// To do: add translations
	//LoadTranslations("w3s.race.mage.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==1)
	{
		thisRaceID=War3_CreateNewRace("Mother Bot","motherbot");
		SKILL_REVENGE=War3_AddRaceSkill(thisRaceID,"Robot's Revenge",
		"On death, spawns a sentry.",false,1);
		/*SKILL_UNHOLY=War3_AddRaceSkill(thisRaceID,"No skill 2",
		"No Skill info 2",false,1);
		ABILITY_FAN=War3_AddRaceSkill(thisRaceID,"No Skill 3",
		"No skill info 3",false,1);
		ABILITY_BLIND=War3_AddRaceSkill(thisRaceID,"No Skill 4",
		"No Skill info 4",false,1);
		ULT_SOULSWAP=War3_AddRaceSkill(thisRaceID,"No Ultimate",
		"No Ultimate info",true,1);*/
		//W3SkillCooldownOnSpawn(thisRaceID,ULT_SOULSWAP,10.0,_);
		//W3SkillCooldownOnSpawn(thisRaceID,ABILITY_BLIND,10.0,_);
		//W3SkillCooldownOnSpawn(thisRaceID,SKILL_UNHOLY,10.0,_);
		//W3SkillCooldownOnSpawn(thisRaceID,SKILL_REVENGE,10.0,_);
		War3_CreateRaceEnd(thisRaceID);
		//thisAuraID=W3RegisterAura("UnholyAura",UnholyRange,true);
		//War3_SetDependency(thisRaceID, ULT_SOULSWAP, SKILL_REVIVE, 1);
	}

}

public OnMapStart()
{
//
}

public Action:Check_Bot_ClassName_Timer(Handle:timer, any:userid)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!ValidPlayer(i))
			continue;
		new String:aName[64];
		GetClientName(i, aName, sizeof(aName));

		//new motherbot=War3_GetRaceIDByShortname("motherbot");
		new race;

		//DP("timer checker for bots");

		if(StrEqual(aName, "Sentry Buster",true))
		{
			race = War3_GetRaceIDByShortname("motherbot");
			War3_SetRace(i,race);
			War3_SetLevel(i,race,W3GetRaceMaxLevel(race));
			for(new x=1;x<=War3_GetRaceSkillCount(race);x++)
			{
				War3_SetSkillLevelINTERNAL(i,race,x,W3GetRaceSkillMaxLevel(race,x));
			}
			W3DoLevelCheck(i);
		}
		else if(War3_GetRace(i)==thisRaceID)
		{
			race = War3_GetRaceIDByShortname("orcishforce");
		}
	}
}


public OnWar3EventDeath(victim, attacker, deathrace)
{
	//new String:aName[64];
	//GetEntityClassname(victim, aName, sizeof(aName));

//	DP("Bot Name %s",aName);

	//new String:aName[64];
	//GetEntityClassname(attacker, aName, sizeof(aName));

	//DP("Entity Attacker name %s",aName);
	if(ValidPlayer(victim))
	{
		new String:aName[64];
		GetClientName(victim, aName, sizeof(aName));

		if(StrEqual(aName, "Sentry Buster",true))
		{
			new Float:vicvec[3];
			//new Float:vicorigvec[MAXPLAYERSCUSTOM][3];
			GetClientAbsOrigin(victim, Float:vicvec);

			vicorigvec[victim][0]= vicvec[0];
			vicorigvec[victim][1]= vicvec[1];
			vicorigvec[victim][2]= vicvec[2];

			new useridX=GetClientUserId(victim);
			CreateTimer(5.0,BuildSentryTimer,useridX);
		}
	}

//	if (thisRaceID == deathrace)
//	{
		//new userid = GetEventInt(event, "userid")

		//decl String:vicname[64]
		//new client = GetClientOfUserId(userid)
		//GetClientName(client, vicname, sizeof(vicname))


		//new Float:rand = GetRandomFloat(0.0, 1.0);
		//new rand=GetRandomInt(1, 3);

		//if (gSentRemaining[client]>0 && GetConVarFloat(g_SpawnSentryChance) >= rand)
		//if (gSentRemaining[client]>0 && GetConVarFloat(g_SpawnSentryChance) >= rand)
		//{
		//BuildSentry(victim, vicorigvec, angl, rand);

		//gSentRemaining[client]-=1;
		//PrintToChat(client, "[SM] You have %d deathsentries remaining", gSentRemaining[client])
		//}
	//}
}

public Action:BuildSentryTimer(Handle:timer, any:userid)
{
	new victim=GetClientOfUserId(userid);
	new rand=GetRandomInt(1, 3);

	new Float:angl[3];
	angl[0] = 0.0;
	angl[1] = 0.0;
	angl[2] = 0.0;

	if(ValidPlayer(victim))
		BuildSentry(victim, angl, rand);

}


public OnClientDisconnect(client) //Destroy all of a player's sentries when he/she disconnects Credit to loop goes to bl4nk
{
	new maxentities = GetMaxEntities();
	for (new i = MAXPLAYERS+1; i <= maxentities; i++)
	{
		if (!IsValidEntity(i))
			continue;

		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));

		if (!strcmp(netclass, "CObjectSentrygun") && GetEntDataEnt2(i, FindSendPropOffs("CObjectSentrygun","m_hBuilder")) == client)
		{
			SetVariantInt(9999);
			AcceptEntityInput(i, "RemoveHealth");
		}
	}
}

/*
public Action:Event_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)	//Keep track of a player's sentry count
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));							//I don't know how to determine whether a sentry was created
																							//by this plugin or by engie as build
	new maxentities = GetMaxEntities();
	for (new i = MAXPLAYERS+1; i <= maxentities; i++)
	{
		if (!IsValidEntity(i))
			continue;

		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));

		if (!strcmp(netclass, "CObjectSentrygun") && GetEntDataEnt2(i, FindSendPropOffs("CObjectSentrygun","m_hBuilder")) == client)
		{
			//gSentRemaining[client]+=1;
			return Plugin_Continue;
		}
	}
	return Plugin_Continue;
} */
								//vicorigvec[MAXPLAYERSCUSTOM][3]

BuildSentry(iBuilder, Float:fAngle[3], iLevel=1)							//Not my code, credit goes to The JCS and Muridas
{
	new checkrace = War3_GetRace(iBuilder);
	if(ValidPlayer(iBuilder)&&(checkrace==thisRaceID))
	{

		new Float:fOrigin[3];

		fOrigin[0]=vicorigvec[iBuilder][0];
		fOrigin[1]=vicorigvec[iBuilder][1];
		fOrigin[2]=vicorigvec[iBuilder][2];

		new Float:fBuildMaxs[3];
		fBuildMaxs[0] = 24.0;
		fBuildMaxs[1] = 24.0;
		fBuildMaxs[2] = 66.0;

		new Float:fMdlWidth[3];
		fMdlWidth[0] = 1.0;
		fMdlWidth[1] = 0.5;
		fMdlWidth[2] = 0.0;

		new String:sModel[64];

		new iTeam = GetClientTeam(iBuilder);

		//LogError("<<Sentry Buster>> Team %i",iTeam);

		new iShells, iHealth, iRockets;

		if(iLevel == 1)
		{
			sModel = "models/buildables/sentry1.mdl";
			iShells = 1000;
			iHealth = 3000;
		}
		else if(iLevel == 2)
		{
			sModel = "models/buildables/sentry2.mdl";
			iShells = 2000;
			iHealth = 5000;
		}
		else if(iLevel == 3)
		{
			sModel = "models/buildables/sentry3.mdl";
			iShells = 3000;
			iHealth = 7000;
			iRockets = 300;
		}

		new iSentry = CreateEntityByName("obj_sentrygun");

		DispatchSpawn(iSentry);

		ActivateEntity(iSentry);

		TeleportEntity(iSentry, fOrigin, fAngle, NULL_VECTOR);

		//SetEntityRenderMode(iSentry, RENDER_TRANSCOLOR);
		//SetEntityRenderColor(iSentry, 255, 255, 255, 0);

		//SetEntProp(iSentry, Prop_Data, "m_CollisionGroup", 5);

		SetEntData(iSentry, FindSendPropOffs("CObjectSentrygun","m_flAnimTime"),                 51, 4 , true);
		SetEntProp(iSentry, Prop_Send, "m_nNewSequenceParity",         3+iLevel);
		SetEntProp(iSentry, Prop_Send, "m_nResetEventsParity",         3+iLevel);
		SetEntProp(iSentry, Prop_Send, "m_iAmmoShells",                 iShells);
		SetEntProp(iSentry, Prop_Send, "m_iMaxHealth",                 iHealth);
		SetEntProp(iSentry, Prop_Send, "m_iHealth",                     iHealth);
		SetEntProp(iSentry, Prop_Send, "m_bBuilding",                 0);
		SetEntProp(iSentry, Prop_Send, "m_bPlacing",                     0);
		SetEntProp(iSentry, Prop_Send, "m_bDisabled",                 0);
		SetEntProp(iSentry, Prop_Send, "m_iObjectType",                 3);
		SetEntProp(iSentry, Prop_Send, "m_iState",                     1);
		SetEntProp(iSentry, Prop_Send, "m_iUpgradeMetal",             0);
		SetEntProp(iSentry, Prop_Send, "m_bHasSapper",                 0);
		SetEntProp(iSentry, Prop_Send, "m_nSkin",                     iTeam-2);
		SetEntProp(iSentry, Prop_Send, "m_bServerOverridePlacement",     0);
		SetEntProp(iSentry, Prop_Send, "m_iUpgradeLevel",             iLevel);
		SetEntProp(iSentry, Prop_Send, "m_iAmmoRockets",                 iRockets);

		SetEntProp(iSentry, Prop_Send, "m_nSequence", 0);
		SetEntPropEnt(iSentry, Prop_Send, "m_hBuilder",     iBuilder);

		SetEntPropFloat(iSentry, Prop_Send, "m_flCycle",                     0.0);
		SetEntPropFloat(iSentry, Prop_Send, "m_flPlaybackRate",             1.0);
		SetEntPropFloat(iSentry, Prop_Send, "m_flPercentageConstructed",     1.0);

		//SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_vecOrigin"),             fOrigin, true);
		//SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_angRotation"),         fAngle, true);
		SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_vecBuildMaxs"),         fBuildMaxs, true);
		//SetEntDataVector(iSentry, FindSendPropOffs("CObjectSentrygun","m_flModelWidthScale"),     fMdlWidth, true);

		new Float:minbounds[3] = {-70.0, -70.0, -70.0};
		new Float:maxbounds[3] = {70.0, 70.0, 70.0};
		SetEntPropVector(iSentry, Prop_Send, "m_vecMins", minbounds);
		SetEntPropVector(iSentry, Prop_Send, "m_vecMaxs", maxbounds);

		SetVariantInt(iTeam);
		AcceptEntityInput(iSentry, "TeamNum", -1, -1, 0);

		SetVariantInt(iTeam);
		AcceptEntityInput(iSentry, "SetTeam", -1, -1, 0);

		SetEntityModel(iSentry,sModel);
	}
}

/* ***************************  OnRaceChanged *************************************/

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		InitPassiveSkills(client);
	}
	else
	{
		RemovePassiveSkills(client);
	}
}
/* ****************************** OnSkillLevelChanged ************************** */

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	InitPassiveSkills(client);
}

public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
	//nothing
		new skilllevel_PassiveSkills=War3_GetSkillLevel(client,thisRaceID,SKILL_REVENGE);
		if(skilllevel_PassiveSkills>0)
		{
			War3_ChatMessage(client,"Good Job, your higher than level 0 and you dont need it!");
		}
	}

}

/* ****************************** RemovePassiveSkills ************************** */

public RemovePassiveSkills(client)
{
// nothing
}
