#define PLUGIN_VERSION "0.0.0.1"
/* ========================================================================== */
/*                                                                            */
/*   War3source_Custom_HyperCyborg.sp                                         */
/*   (c) 2012 El Diablo                                                       */
/*                                                                            */
/* ========================================================================== */
#pragma semicolon 1


#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/sdkhooks"
public W3ONLY(){} //unload this?

// War3Source stuff
new thisRaceID;

//global
new ownerOffset;

// Ultimate
//new bool:Sentry_Toggle[MAXPLAYERSCUSTOM];

new SKILL_ACP_SENTRY, SKILL_AUTO_DISPENSER,SKILL_NANO_PRODUCTION;
// ABILITY_TRIP, ULT_CARRY,SKILL_NANO_PRODUCTION;

// ACP SENTRY ROUNDS
new Float:ACP[5]={0.0,0.04,0.06,0.8,0.10};
new Float:ORB[5]={0.0,0.95,0.90,0.85,0.80};

new NANO[5]={0,5,10,15,20};
new NANO_decrease_health[5]={0,2,4,6,8};

//// Entity Class Names
#define CLASSNAME_SENTRY "obj_sentrygun"
#define CLASSNAME_DISPENSER "obj_dispenser"
#define CLASSNAME_TELEPORTER "obj_teleporter"

//// Other Global Variables

new MaxSentryShellsByLevel[] = { 150, 200, 200 };
new RepairRateByDispenserLevel[3] = { 5, 10, 20 };
new SentryShellRefillRateByDispenserLevel[3] = { 1, 2, 4 };
new SentryRocketRefillRateByDispenserLevel[3] = { 0, 0, 0 };

new Float:WrenchRateOfFire[5] = {1.0, 1.20, 1.30, 1.40, 1.50};

//// Global Constants

const MaxSentryRockets = 20;

new Float:TickInterval = 2.5;  //"The interval between ticks, in seconds."
//new Handle:RepairTimer = INVALID_HANDLE;

new MaxDispenserDistance = 150;
const bool:IsSentryRepairEnabled = true;
new bool:IsSentryAntiSapperEnabled = false;
const bool:IsDispenserRepairEnabled = true;
new bool:IsDispenserAntiSapperEnabled = false;
const bool:IsTeleporterRepairEnabled = true;
new bool:IsTeleporterAntiSapperEnabled = false;



new bool:bFrosted[65]; // don't frost before unfrosted

public Plugin:myinfo =
{
	name = "Race - Hyper Cyborg",
	author = "El Diablo",
	description = "A Race without Nothing. Skills mean nothing.",
	version = "1.0.0.0",
	url = "http://Www.war3evo.Com"
};
public OnPluginStart()
{
	CreateConVar("war3evo_HyperCyborg",PLUGIN_VERSION,"War3evo Hyper Cyborg",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	// To do: add translations
	//LoadTranslations("w3s.race.mage.phrases");
	ownerOffset = FindSendPropInfo("CBaseObject", "m_hBuilder");
	StartRepairTimer();
}

public Action:OnTick(Handle:timer)
{
	ProcessDispensers();
	return Plugin_Continue;
}


//// Utility Functions

StartRepairTimer()
{
	CreateTimer(
		TickInterval,
		OnTick,
		_,
		TIMER_REPEAT);
}


public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==102)
	{
		thisRaceID=War3_CreateNewRace("Hyper Cyborg","hyperC");
		SKILL_NANO_PRODUCTION=War3_AddRaceSkill(thisRaceID,"Nano Production",
		"Regenerates 4/6/8/10 metal per second.\nCan't Equip Mask of Death\nNano requires 1-4 health/second to rebuild metal.\nMust have at least 50 or more health to regen metal.",false,4);
		SKILL_AUTO_DISPENSER=War3_AddRaceSkill(thisRaceID,"Auto Dispenser",
		"When buildings are near to dispensers,\nit repairs and refills building (increases by dispenser level & job level).\nIncreases fire rate for only the wrench by 20/30/40/50 percent.",false,4);
		//ABILITY_TRIP=War3_AddRaceSkill(thisRaceID,"Trip Wards",
		//"No skill info 3",false,1);
		SKILL_ACP_SENTRY=War3_AddRaceSkill(thisRaceID,"ACP Sentry Rounds",
		"Sentry's Damage Increased and Victim Slowed by 10%/15%/20%/25%",false,4);
		//ULT_CARRY=War3_AddRaceSkill(thisRaceID,"Carry Live Sentry",
		//"No Ultimate info",true,1);
//		W3SkillCooldownOnSpawn(thisRaceID,ULT_SOULSWAP,10.0,_);
//		W3SkillCooldownOnSpawn(thisRaceID,ABILITY_BLIND,10.0,_);
//		W3SkillCooldownOnSpawn(thisRaceID,SKILL_UNHOLY,10.0,_);
//		W3SkillCooldownOnSpawn(thisRaceID,ABILITY_FAN,10.0,_);
		War3_CreateRaceEnd(thisRaceID);
		//thisAuraID=W3RegisterAura("UnholyAura",UnholyRange,true);
//		War3_SetDependency(thisRaceID, ULT_SOULSWAP, SKILL_REVIVE, 1);
	}

}

public OnW3Denyable(W3DENY:event,client)
{
	if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == War3_GetItemIdByShortname("mask")))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			new Nano_Production_level=War3_GetSkillLevel(client,thisRaceID,SKILL_NANO_PRODUCTION);
			if(Nano_Production_level>0)
			{
				W3Deny();
				War3_ChatMessage(client, "Cyborgs can't feel the effects of these items!");
			}
		}
	}
	if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == War3_GetItemIdByShortname("ring")))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			new Nano_Production_level=War3_GetSkillLevel(client,thisRaceID,SKILL_NANO_PRODUCTION);
			if(Nano_Production_level>0)
			{
				W3Deny();
				War3_ChatMessage(client, "Cyborgs can't feel the effects of these items!");
			}
		}
	}
	if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == War3_GetItemIdByShortname("gauntlet")))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			new Nano_Production_level=War3_GetSkillLevel(client,thisRaceID,SKILL_NANO_PRODUCTION);
			if(Nano_Production_level>0)
			{
				W3Deny();
				War3_ChatMessage(client, "Cyborgs can't feel the effects of these items!");
			}
		}
	}
}


public OnMapStart()
{
	CreateTimer(1.0, Timer_Ammo_Regen, _, TIMER_REPEAT);
}

public OnClientPutInServer(client){
	SDKHook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitch);
}

public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitch);
}

public SDK_OnWeaponSwitch(client, weapon)
{
//
	if (ValidPlayer(client))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			if(IsValidEdict(weapon))
			{
				decl String:weaponName[128];
				GetEdictClassname(weapon, weaponName, sizeof(weaponName));
				if(StrEqual(weaponName, "tf_weapon_wrench"))
				{
					new AutoDispenser_level=War3_GetSkillLevel(client,thisRaceID,SKILL_AUTO_DISPENSER);
					War3_SetBuff(client,fAttackSpeed,thisRaceID,WrenchRateOfFire[AutoDispenser_level]);
					//DP("Weapon wrench");
				}
				else
				{
					War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
					//DP("Weapon NOT wrench");
				}
			}
			else
			{
				War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
			}
		}
	}
}

public Action:Timer_Ammo_Regen(Handle:timer, any:user)
{
	//PrintToChatAll("Timer called, timestamp: %i", GetTime());
	new iMaxMetal = 200;
	new iMetalToAdd = 0;

	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i) || TF2_GetPlayerClass(i) != TFClass_Engineer || War3_GetRace(i)!=thisRaceID)
			continue;	// Client isnt valid

		new Nano_Production_level=War3_GetSkillLevel(i,thisRaceID,SKILL_NANO_PRODUCTION);
		if(Nano_Production_level<=0)
			continue;
		iMetalToAdd = NANO[Nano_Production_level];

		new iCurrentMetal = GetEntProp(i, Prop_Data, "m_iAmmo", 4, 3);
		new iNewMetal = iMetalToAdd + iCurrentMetal;
		if (iNewMetal <= iMaxMetal && GetClientHealth(i)>50)
		{
			SetEntProp(i, Prop_Data, "m_iAmmo", iNewMetal, 4, 3);
			War3_DecreaseHP(i,NANO_decrease_health[Nano_Production_level]);
		}
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
		new AutoDispenser_level=War3_GetSkillLevel(client,thisRaceID,SKILL_AUTO_DISPENSER);
		if(AutoDispenser_level>0)
		{
			switch(AutoDispenser_level)
			{
				case 1:
				{
					MaxDispenserDistance = 100;

					IsSentryAntiSapperEnabled = false;
					IsDispenserAntiSapperEnabled = false;
					IsTeleporterAntiSapperEnabled = false;

					MaxSentryShellsByLevel[0] = 150;
					MaxSentryShellsByLevel[1] = 200;
					MaxSentryShellsByLevel[2] = 200;

					RepairRateByDispenserLevel[0] = 10;
					RepairRateByDispenserLevel[1] = 17;
					RepairRateByDispenserLevel[2] = 25;

					SentryShellRefillRateByDispenserLevel[0] = 5;
					SentryShellRefillRateByDispenserLevel[1] = 10;
					SentryShellRefillRateByDispenserLevel[2] = 15;

					SentryRocketRefillRateByDispenserLevel[0] = 0;
					SentryRocketRefillRateByDispenserLevel[1] = 0;
					SentryRocketRefillRateByDispenserLevel[2] = 0;
				}
				case 2:
				{
					MaxDispenserDistance = 150;

					IsSentryAntiSapperEnabled = false;
					IsDispenserAntiSapperEnabled = false;
					IsTeleporterAntiSapperEnabled = true;

					MaxSentryShellsByLevel[0] = 150;
					MaxSentryShellsByLevel[1] = 200;
					MaxSentryShellsByLevel[2] = 200;

					RepairRateByDispenserLevel[0] = 25;
					RepairRateByDispenserLevel[1] = 35;
					RepairRateByDispenserLevel[2] = 50;

					SentryShellRefillRateByDispenserLevel[0] = 15;
					SentryShellRefillRateByDispenserLevel[1] = 20;
					SentryShellRefillRateByDispenserLevel[2] = 25;

					SentryRocketRefillRateByDispenserLevel[0] = 0;
					SentryRocketRefillRateByDispenserLevel[1] = 0;
					SentryRocketRefillRateByDispenserLevel[2] = 1;
				}
				case 3:
				{
					MaxDispenserDistance = 200;

					IsSentryAntiSapperEnabled = true;
					IsDispenserAntiSapperEnabled = false;
					IsTeleporterAntiSapperEnabled = true;

					MaxSentryShellsByLevel[0] = 150;
					MaxSentryShellsByLevel[1] = 200;
					MaxSentryShellsByLevel[2] = 200;

					RepairRateByDispenserLevel[0] = 50;
					RepairRateByDispenserLevel[1] = 75;
					RepairRateByDispenserLevel[2] = 100;

					SentryShellRefillRateByDispenserLevel[0] = 25;
					SentryShellRefillRateByDispenserLevel[1] = 35;
					SentryShellRefillRateByDispenserLevel[2] = 45;

					SentryRocketRefillRateByDispenserLevel[0] = 0;
					SentryRocketRefillRateByDispenserLevel[1] = 1;
					SentryRocketRefillRateByDispenserLevel[2] = 2;
				}
				case 4:
				{
					MaxDispenserDistance = 250;

					IsSentryAntiSapperEnabled = true;
					IsDispenserAntiSapperEnabled = true;
					IsTeleporterAntiSapperEnabled = true;

					MaxSentryShellsByLevel[0] = 150;
					MaxSentryShellsByLevel[1] = 200;
					MaxSentryShellsByLevel[2] = 200;

					RepairRateByDispenserLevel[0] = 100;
					RepairRateByDispenserLevel[1] = 125;
					RepairRateByDispenserLevel[2] = 150;

					SentryShellRefillRateByDispenserLevel[0] = 45;
					SentryShellRefillRateByDispenserLevel[1] = 60;
					SentryShellRefillRateByDispenserLevel[2] = 75;

					SentryRocketRefillRateByDispenserLevel[0] = 1;
					SentryRocketRefillRateByDispenserLevel[1] = 2;
					SentryRocketRefillRateByDispenserLevel[2] = 3;
				}
			}

		}

	}
}

/* ****************************** RemovePassiveSkills ************************** */

public RemovePassiveSkills(client)
{
	War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
}


//ULT_CARRY
/*
public OnUltimateCommand(client,race,bool:pressed)
{
	new userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) && !Silenced(client))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_CARRY);
		if(ult_level>0)
		{

			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_CARRY,true)) //not in the 0.2 second delay when we check stuck via moving
			{
				// CARRY
				//Sentry_TEST(client);
			}
		}
	}
}
*/

/*
bool:IS_sentryowner(client,pSentry)
{
	if(IsValidEntity(pSentry)&&War3_GetRace(client)==thisRaceID)
	{
		//DP("Looking for sentry owner");
		new iSentry = GetEntPropEnt(pSentry, Prop_Send, "m_hBuilder");
		if(iSentry==client)
		{
			return true;
		}
	}

	return false;
}
*/
public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim)&&ValidPlayer(attacker))
	{
		new sentry_ACP_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_ACP_SENTRY);
		if(sentry_ACP_level>0)
		{
			//new damagetype = W3GetDamageType();
			new inflictor = W3GetDamageInflictor();
			/*
			new String:inflictor_name[64];
			GetEdictClassname(inflictor,inflictor_name,64);
			new String:attacker_name[64];
			GetClientName(attacker,attacker_name,64);
			new String:victim_name[64];
			GetClientName(victim,victim_name,64);
			DP("victim %s",victim_name);
			DP("attacker %s",attacker_name);
			DP("inflictor %s",inflictor_name);
			DP("damagetype %i",damagetype);
			*/
			if(isBuildingOwner(attacker,inflictor))
			{
				new String:victim_name[64];
				GetClientName(victim,victim_name,64);
				//DP("attacker %s owns sentry",attacker_name);
				// CODE HERE
				//          //ACP        sentry_ACP_level
				if(!bFrosted[victim]&&!W3HasImmunity(victim,Immunity_Skills))
				{
					new Float:speed_frost=ORB[sentry_ACP_level];
					if(speed_frost<=0.0) speed_frost=0.01; // 0.0 for override removes
					if(speed_frost>1.0)	speed_frost=1.0;
					War3_SetBuff(victim,fSlow,thisRaceID,speed_frost);
					bFrosted[victim]=true;

					//PrintToConsole(attacker,"%T","ORB OF FROST!",attacker);
					//PrintToConsole(victim,"%T","Frosted, reducing your speed",victim);
					PrintHintText(victim,"Slowed by HyperCyborg Sentry, reducing your speed!");
					CreateTimer(2.0,Unfrost,victim);
				}
				if(!W3HasImmunity(victim,Immunity_Skills))
				{
					new dmg = RoundToCeil(damage+(damage*ACP[sentry_ACP_level]));
					War3_DealDamage(victim,dmg,inflictor,DMG_BULLET,"HyperCyborg Sentry");
					PrintHintText(attacker,"HyperCyborg Sentry Damage to %s",victim_name);
				}
				else
				{
					PrintHintText(attacker,"%s is wearing Holy Shield!\n(is immune to ACP Skill)",victim_name);
				}
			}
		}
	}
}

public Action:Unfrost(Handle:timer,any:client)
{
	bFrosted[client]=false;
	//War3_SetOverrideSpeed(client,0.0,shopItem[6]);
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
	/*
	if(ValidPlayer(client))
	{

		PrintToConsole(client,"%T","REGAINED SPEED from frost",client);
	}
	*/
}

public OnWar3EventSpawn(client){
	if( bFrosted[client])
	{
		bFrosted[client]=false;
		War3_SetBuff(client,fSlow,thisRaceID,1.0);
	}
}

/*
stock bool:CheckForBuildings(client)
{
    new maxclients = GetMaxClients();
    new maxentities = GetMaxEntities();

    for (new i = maxclients + 1; i <= maxentities; i++)
    {
        if (!IsValidEntity(i))
            continue;

        decl String:netclass[32];
        GetEntityNetClass(i, netclass, sizeof(netclass));

        if (strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectTeleporter") == 0 || strcmp(netclass, "CObjectDispenser") == 0)
        {
            if (GetEntPropEnt(i, Prop_Data, "m_hBuilder") == client)
                return true;
        }
    }

    return false;
}
*/

/*
//global
new ownerOffset;

//inside OnPluginStart
ownerOffset = FindSendPropInfo("CBaseObject", "m_hBuilder");

//the function
stock bool:CheckForBuildings(client)
{
    new maxclients = GetMaxClients();
    new maxentities = GetMaxEntities();

    for (new i = maxclients + 1; i <= maxentities; i++)
    {
        if (!IsValidEntity(i))
            continue;

        decl String:netclass[32];
        GetEntityNetClass(i, netclass, sizeof(netclass));

        if (strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectTeleporter") == 0 || strcmp(netclass, "CObjectDispenser") == 0)
        {
            if (GetEntDataEnt2(i, ownerOffset) == client)
                return true;
        }
    }

    return false;
}
*/

bool:isBuildingOwner(client,pBuilding)
{
/*
	if(IsValidEntity(pBuilding)&&War3_GetRace(client)==thisRaceID)
	{
		//DP("Looking for sentry owner");
		new iBuilding = GetEntPropEnt(pBuilding, Prop_Send, "m_hBuilder");
		if(iBuilding==client)
		{
			return true;
		}
	}

	return false;
	*/

	if(ValidPlayer(client))
	{
		if(War3_GetRace(client)==thisRaceID && IsValidEntity(pBuilding)&&TF2_GetPlayerClass(client)==TFClass_Engineer)
		{
			//DP("Looking for sentry owner");
			//new iSentry = GetEntPropEnt(pSentry, Prop_Send, "m_hBuilder");
			//if(iSentry==client)
			//{
			//	return true;
			//}
			decl String:netclass[32];
			GetEntityNetClass(pBuilding, netclass, sizeof(netclass));

			if (strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectTeleporter") == 0 || strcmp(netclass, "CObjectDispenser") == 0)
			{
				if (GetEntDataEnt2(pBuilding, ownerOffset) == client)
					return true;
			}
		}
	}

	return false;
}


FindDispenser(previousDispenserEntity)
{
	return FindEntityByClassname(previousDispenserEntity, "obj_dispenser");
}

GetEntLevel(entity)
{
	return GetEntProp(entity, Prop_Send, "m_iUpgradeLevel", 1);
}

GetEntTeam(entity)
{
	return GetEntProp(entity, Prop_Send, "m_iTeamNum", 1);
}

GetEntLocation(entity, Float:positionVector[3])
{
	return GetEntPropVector(entity, Prop_Send, "m_vecOrigin", positionVector);
}

GetEntHealth(entity)
{
	return GetEntProp(entity, Prop_Send, "m_iHealth");
}

GetEntMaxHealth(entity)
{
	return GetEntProp(entity, Prop_Send, "m_iMaxHealth");
}

AddEntHealth(entity, amount)
{
	SetVariantInt(amount);
	AcceptEntityInput(entity, "AddHealth");
}

bool:IsEntBeingBuilt(entity)
{
	return (GetEntProp(entity, Prop_Send, "m_bBuilding", 1) == 1);
}

bool:IsEntBeingPlaced(entity)
{
	return (GetEntProp(entity, Prop_Send, "m_bPlacing", 1) == 1);
}

bool:IsEntBeingSapped(entity)
{
	return (GetEntProp(entity, Prop_Send, "m_bHasSapper", 1) == 1);
}

		//// Business Logic

ProcessDispensers()
{
	// Loop through the dispensers.
	for (new dispenserEntity = FindDispenser(-1);
		dispenserEntity != -1;
		dispenserEntity = FindDispenser(dispenserEntity))
	{
		// Skip dispensers that are being built, placed, or sapped.
		if (IsEntBeingBuilt(dispenserEntity)
			|| IsEntBeingPlaced(dispenserEntity)
			|| IsEntBeingSapped(dispenserEntity))
		{
			continue;
		}

		for(new i=0;i<=MaxClients;i++)
		{
			if(ValidPlayer(i))
			{
				if(War3_GetRace(i)==thisRaceID)
				{
					new AutoDispenser_level=War3_GetSkillLevel(i,thisRaceID,SKILL_AUTO_DISPENSER);
					if(AutoDispenser_level>0&&isBuildingOwner(i,dispenserEntity))
					{
						ProcessDispenser(dispenserEntity);
					}
				}
			}
		}
	}
}

ProcessDispenser(dispenserEntity)
{
	new dispenserTeam = GetEntTeam(dispenserEntity);
	new dispenserLevel = GetEntLevel(dispenserEntity);
	decl Float:dispenserLocation[3];
	GetEntLocation(dispenserEntity, dispenserLocation);
	ProcessOtherBuildings(
		dispenserEntity,
		dispenserLevel,
		dispenserTeam,
		dispenserLocation,
		CLASSNAME_SENTRY);
	ProcessOtherBuildings(
		dispenserEntity,
		dispenserLevel,
		dispenserTeam,
		dispenserLocation,
		CLASSNAME_DISPENSER);
	ProcessOtherBuildings(
		dispenserEntity,
		dispenserLevel,
		dispenserTeam,
		dispenserLocation,
		CLASSNAME_TELEPORTER);
}

ProcessOtherBuildings(
	dispenserEntity,
	dispenserLevel,
	dispenserTeam,
	Float:dispenserLocation[3],
	String:otherBuildingClassname[])
{
	new bool:isSentry =
		(strcmp(otherBuildingClassname, CLASSNAME_SENTRY) == 0);
	new bool:isDispenser =
		(strcmp(otherBuildingClassname, CLASSNAME_DISPENSER) == 0);
	new bool:isTeleporter =
		(strcmp(otherBuildingClassname, CLASSNAME_TELEPORTER) == 0);

	new otherBuildingEntity = -1;
	for (
		otherBuildingEntity =
			FindEntityByClassname(otherBuildingEntity, otherBuildingClassname);
		otherBuildingEntity != -1;
		otherBuildingEntity =
			FindEntityByClassname(otherBuildingEntity, otherBuildingClassname))
	{
		if (dispenserEntity == otherBuildingEntity)
		{
			// The other building IS the dispenser.
			// Skip it. (Don't let dispensers heal themselves.)
			continue;
		}

		new otherBuildingTeam = GetEntTeam(otherBuildingEntity);
		new Float:otherBuildingLocation[3];
		GetEntLocation(otherBuildingEntity, otherBuildingLocation);

		new Float:actualDistance =
			GetVectorDistance(dispenserLocation, otherBuildingLocation);
		if (actualDistance > MaxDispenserDistance)
		{
			// The other building is too far from the dispenser.
			// Skip it.
			continue;
		}

		if (otherBuildingTeam != dispenserTeam)
		{
			// The other building is on a different team than the dispenser.
			// Skip it.
			continue;
		}

		if (IsEntBeingBuilt(otherBuildingEntity)
			|| IsEntBeingPlaced(otherBuildingEntity))
		{
			// The other building is being built or placed.
			// Skip it.
			continue;
		}

		// I'd really like to define a ProcessBuilding functag:
		//   functag public ProcessBuilding(entity, dispenserLevel);
		// then pass a callback to the appropriate building's function, but as
		// far as I can tell there's no way to invoke a callback from a
		// SourcePawn script... so I'll just do if/else/if/else/if...
		if (isSentry)
		{
			RepairBuilding(
				otherBuildingEntity,
				dispenserLevel,
				IsSentryRepairEnabled,
				IsSentryAntiSapperEnabled);
			RefillSentryShells(otherBuildingEntity, dispenserLevel);
			RefillSentryRockets(otherBuildingEntity, dispenserLevel);
		}
		else if (isDispenser)
		{
			RepairBuilding(
				otherBuildingEntity,
				dispenserLevel,
				IsDispenserRepairEnabled,
				IsDispenserAntiSapperEnabled);
		}
		else if (isTeleporter)
		{
			RepairBuilding(
				otherBuildingEntity,
				dispenserLevel,
				IsTeleporterRepairEnabled,
				IsTeleporterAntiSapperEnabled);
		}
	}
}

RepairBuilding(
	buildingEntity,
	dispenserLevel,
	bool:isRepairEnabled,
	bool:isAntiSapperEnabled)
{
	new buildingMaxHealth = GetEntMaxHealth(buildingEntity);
	new buildingHealth = GetEntHealth(buildingEntity);

	if (buildingHealth >= buildingMaxHealth)
	{
		// This building is already at full health.
		// Skip it.
		return;
	}

	if (dispenserLevel < 1)
	{
		// The dispenser level is below 1. This is unexpected.
		// Skip the building.
		// TODO: Log this.
		return;
	}

	if (dispenserLevel > 3)
	{
		// The dispenser level is above 3. This is unexpected.
		// Clip it to 3 for the purpose of establishing the repair rate.
		dispenserLevel = 3;
		// TODO: Log this.
	}

	new healthIncrement = RepairRateByDispenserLevel[dispenserLevel - 1];

	if (IsEntBeingSapped(buildingEntity))
	{
		// The building is being sapped.
		if (isAntiSapperEnabled)
		{
			// Anti-sapper is enabled.
			// Repair the building at one fifth normal speed.
			//healthIncrement /= 5;
		}
		else
		{
			// Anti-sapper is disabled.
			// Skip the building.
			return;
		}
	}
	else if (!isRepairEnabled)
	{
		// The building is not being sapped, but repair is disabled.
		// Skip the building.
		return;
	}

	if ((buildingHealth + healthIncrement) > buildingMaxHealth)
	{
		// The increase in the building's health would exceed its maximum
		// health.
		// Clip the increment to the amount necessary to reach maximum health.
		healthIncrement = buildingMaxHealth - buildingHealth;
	}

	AddEntHealth(buildingEntity, healthIncrement);
}

RefillSentryShells(sentryEntity, dispenserLevel)
{
	new sentryLevel = GetEntLevel(sentryEntity);
	new shells = GetEntProp(sentryEntity, Prop_Send, "m_iAmmoShells");
	shells += SentryShellRefillRateByDispenserLevel[dispenserLevel - 1];
	if (shells > MaxSentryShellsByLevel[sentryLevel - 1])
	{
		shells = MaxSentryShellsByLevel[sentryLevel - 1];
	}

	SetEntProp(sentryEntity, Prop_Send, "m_iAmmoShells", shells);
}

RefillSentryRockets(sentryEntity, dispenserLevel)
{
	new sentryLevel = GetEntLevel(sentryEntity);
	if (sentryLevel < 3)
	{
		// The sentry is below level 3, so it doesn't have rockets.
		return;
	}

	new sentryRockets = GetEntProp(sentryEntity, Prop_Send, "m_iAmmoRockets");
	sentryRockets += SentryRocketRefillRateByDispenserLevel[dispenserLevel - 1];
	if (sentryRockets > MaxSentryRockets)
	{
		sentryRockets = MaxSentryRockets;
	}

	SetEntProp(sentryEntity, Prop_Send, "m_iAmmoRockets", sentryRockets);
}


/* ***************************  ability *************************************/
/*
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,ABILITY_TRIP);
		if(skill_level>0)
		{
			if(!Silenced(client)&&CurrentWardCount[client]<WardStartingArr[skill_level])
			{
				new iTeam=GetClientTeam(client);
				new bool:conf_found=false;
				if(War3_GetGame()==Game_TF)
				{
					new Handle:hCheckEntities=War3_NearBuilding(client);
					new size_arr=0;
					if(hCheckEntities!=INVALID_HANDLE)
						size_arr=GetArraySize(hCheckEntities);
					for(new x=0;x<size_arr;x++)
					{
						new ent=GetArrayCell(hCheckEntities,x);
						if(!IsValidEdict(ent)) continue;
						new builder=GetEntPropEnt(ent,Prop_Send,"m_hBuilder");
						if(builder>0 && ValidPlayer(builder) && GetClientTeam(builder)!=iTeam)
						{
							conf_found=true;
							break;
						}
					}
					if(size_arr>0)
						CloseHandle(hCheckEntities);
				}
				if(conf_found)
				{
					W3MsgWardLocationDeny(client);
				}
				else
				{
					if(War3_IsCloaked(client))
					{
						W3MsgNoWardWhenInvis(client);
						return;
					}
					CreateWard(client);
					CurrentWardCount[client]++;
					W3MsgCreatedWard(client,CurrentWardCount[client],WardStartingArr[skill_level]);
				}
			}
			else
			{
				W3MsgNoWardsLeft(client);
			}
		}
	}
}

//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
//////////////////WARDS//////WARDS//////WARDS//////WARDS//////WARDS///////////
//////////////////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////////////////
public OnWar3EventSpawn(client)
{
	RemoveWards(client);
}

// Wards
public CreateWard(client)
{
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]==0)
		{
			WardOwner[i]=client;
			GetClientAbsOrigin(client,WardLocation[i]);
			break;
		}
	}
}

public RemoveWards(client)
{
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]==client)    // i == owner
		{
			WardOwner[i]=0;
		}
	}
	CurrentWardCount[client]=0;
}

public Action:CalcWards(Handle:timer,any:userid)
{
	new client;
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]!=0)
		{
			client=WardOwner[i];
			if(!ValidPlayer(client,true))
			{
				WardOwner[i]=0; //he's dead, so no more wards for him
				--CurrentWardCount[client];
			}
			else
			{
				WardEffectAndNoMovement(client,i);
			}
		}
	}
}

// This is where you need to create the Black Vortex ward
// EFFECTs !
// Find map positions for every approved Steam map,
// The mark those locations for each map in an array or something
//
// Need to setup some sounds when a player walks thru this vortex!
//
// Thought about vortexs disappearing once 1 player enters 1 vortex.
//
//healing wards
public WardEffectAndNoMovement(owner,wardindex)
{
	new beamcolor[]={128,0,128,25}; //190
	new Float:start_pos[3];
	new Float:end_pos[3];

	new Float:tempVec1[]={0.0,0.0,WARDBELOW};
	new Float:tempVec2[]={0.0,0.0,WARDABOVE};
	AddVectors(WardLocation[wardindex],tempVec1,start_pos);
	AddVectors(WardLocation[wardindex],tempVec2,end_pos);
	TE_SetupBeamPoints(start_pos,end_pos,BeamSprite,HaloSprite,0,GetRandomInt(30,100),1.2,float(WARDRADIUS),float(WARDRADIUS),0,30.0,beamcolor,10);
	TE_SendToAll();
	new Float:BeamXY[3];
	for(new x=0;x<3;x++) BeamXY[x]=start_pos[x]; //only compare xy
	new Float:BeamZ= BeamXY[2];
	BeamXY[2]=0.0;
	new Float:VictimPos[3];
	new Float:tempZ;

	new OwnerTeam = GetClientTeam(owner);
	new skilllevel_TurtledSpeedSkills=War3_GetSkillLevel(owner,thisRaceID,ABILITY_PURPLE_WARD);
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true) && (GetClientTeam(i) != OwnerTeam))
		{
			GetClientAbsOrigin(i,VictimPos);
			tempZ=VictimPos[2];
			VictimPos[2]=0.0; //no Z
			if(GetVectorDistance(BeamXY,VictimPos) < WARDRADIUS) ////ward RADIUS
			{
				// now compare z
				if(tempZ>BeamZ+WARDBELOW && tempZ < BeamZ+WARDABOVE)
				{
					//Heal!!
					new DamageScreen[4];
					DamageScreen[0]=beamcolor[0];
					DamageScreen[1]=beamcolor[1];
					DamageScreen[2]=beamcolor[2];
					DamageScreen[3]=20; //alpha
					// Did they buy antiwards?  if so, remove it.
					if(W3HasImmunity(i,Immunity_Wards))
					{
						W3MsgSkillBlocked(i,_,"Wards");
					}
					else
					{
						////////////////////////// DAMAGE HERE TRIP WARDS /////////////////
						////////////////////////// DAMAGE HERE TRIP WARDS /////////////////
						////////////////////////// DAMAGE HERE TRIP WARDS /////////////////
						if(War3_DealDamage(i,WARDDAMAGE,owner,DMG_ENERGYBEAM,"Trip Wards",_,W3DMGTYPE_MAGIC))
						{
							if(LastThunderClap[i]<GetGameTime()-2)
							{
								EmitSoundToAll(wardDamageSound,i,SNDCHAN_WEAPON);
								LastThunderClap[i]=GetGameTime();
							}
						}

						PrintCenterText(i,"Your being Turtled! QUICK -->> Open Chatbox and type: antiwards");
						//PrintToChat(i,"You've been walled! / Say Antiwards"); TurtledSpeed
						War3_SetBuff(i,fSlow,thisRaceID,TurtledSpeed[skilllevel_TurtledSpeedSkills]);
						TurtledWard[i]=true;
						TurtledOwnerWard[owner][i]=1;
						W3FlashScreen(i,DamageScreen);
					}
				}
			}
		}
	}
}

*/
