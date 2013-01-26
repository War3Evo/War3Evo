#define PLUGIN_VERSION "0.0.0.1"
/**
 * File: War3Source_CustomRace_OrcishForce.sp
 * Description: The Orcish Force Horde race.
 * Author(s): El Diablo
 *
 *--modified version of orcish horde from war3source.
 */

#pragma semicolon 1
#pragma tabsize 0

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>

//#include <cstrike>

public W3ONLY(){} //unload this?
new thisRaceID;
new Handle:ultCooldownCvar;

new Float:LastThunderClap[MAXPLAYERSCUSTOM];

new bool:bBeenHit[MAXPLAYERSCUSTOM][MAXPLAYERSCUSTOM]; // [caster][victim] been hit this chain lightning?



//new MyWeaponsOffset,AmmoOffset;
//Clip1Offset


// blitz
new Float:forcblitz[5]={0.0,1.05,1.10,1.15,1.25};
new Float:OnFireToSlow[5]={0.0,0.50,0.60,0.70,0.80};

// lustful power
new Float:forclustfulpower[5]={1.0,1.05,1.10,1.15,1.20};
new Float:MagicResistanceReduction[5]={1.0,-1.20,-1.30,-1.40,-1.50};

// Chance/Data Arrays
new Float:CriticalStrikePercent[5]={0.0,0.30,0.50,0.60,0.70};
//new Float:ChainDistance[5]={0.0,150.0,200.0,250.0,300.0};
new Float:ChainDistance[5]={0.0,150.0,200.0,300.0,450.0};
new Float:DischargeDelay[5]={0.0,4.0,3.0,2.0,1.0};

// WARDS
#define MAXWARDS 64*4 //on map LOL
#define WARDRADIUS 60
#define WARDDAMAGE 20  // was three
#define WARDBELOW -2.0 // player is 60 units tall about (6 feet)
#define WARDABOVE 160.0

new CurrentWardCount[MAXPLAYERSCUSTOM];
new WardStartingArr[]={0,1,2,3,4};
new Float:WardLocation[MAXWARDS][3];
new WardOwner[MAXWARDS];

new String:lightningSound[]="war3source/lightningbolt.wav";
new String:wardDamageSound[]="war3source/thunder_clap.wav";


new SKILL_CRIT,SKILL_BLITZ,SKILL_LUSTFUL_POWER,SKILL_WARD,ULT_LIGHTNING;
// Effects

new BeamSprite,HaloSprite,BloodSpray,BloodDrop; 

public Plugin:myinfo =
{
	name = "Race - Orcish Force",
	author = "El Diablo",
	description = "The Orcish Force job for War3evo.",
	version = "1.0.0.0",
	url = "http://www.war3evo.com"
};

public OnPluginStart()
{
	CreateConVar("war3evo_OrcishForce",PLUGIN_VERSION,"War3evo Orcish Force",FCVAR_PLUGIN);
	//HookEvent("round_start",RoundStartEvent);
	ultCooldownCvar=CreateConVar("war3_orcishforce_chain_cooldown","20.0","Cooldown time for chain lightning.");

	//MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
//	Clip1Offset=FindSendPropOffs("CBaseCombatWeapon","m_iClip1");
	//AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
	CreateTimer(0.14,CalcWards,_,TIMER_REPEAT);
//	HookEvent("player_hurt",PlayerHurtEvent);

	//LoadTranslations("w3s.race.orc.phrases");
}


public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==30)
	{
		thisRaceID=War3_CreateNewRace("Orcish Force","orcishforce");
		SKILL_CRIT=War3_AddRaceSkill(thisRaceID,"War Strike",
		"Chance of doing critical damage",false,4);
		SKILL_BLITZ=War3_AddRaceSkill(thisRaceID,"Blitz",
		"Increases movement speed. On Burn: you have a\nchance of 100% to getting slowed by 50%/60%/70%/80%",false,4);
		SKILL_LUSTFUL_POWER=War3_AddRaceSkill(thisRaceID,"Lustful Power",
		"Increases attack speed. Magical resistance is vulnerability is increased.",false,4);
		SKILL_WARD=War3_AddRaceSkill(thisRaceID,"Serpent Wards",
		"Wards that damage enemies if they touch. Activate by '+ability'",false,4);
		ULT_LIGHTNING=War3_AddRaceSkill(thisRaceID,"Chain Lightning",
		"Discharges a bolt of lightning that jumps to\nnearby enemies 150-300 units in range,\ndealing each damage.\nAfter Discharge you cannot attack for 4/3/2/1 seconds.",true,4); //TEST
		W3SkillCooldownOnSpawn(thisRaceID,ULT_LIGHTNING,10.0,_); //translated doesnt use this "Chain Lightning"?
		War3_CreateRaceEnd(thisRaceID);
		War3_SetDependency(thisRaceID, SKILL_LUSTFUL_POWER, SKILL_BLITZ, 4);
	}       //blood thirsty    Sweeping Strikes
}




public OnWar3PlayerAuthed(client)
{
	LastThunderClap[client]=0.0;
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{
		War3_SetBuff(client,fSlow,thisRaceID,1.0);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
		War3_SetBuff(client,bDisarm,thisRaceID,false);
		War3_SetBuff(client,fArmorMagic,thisRaceID,0.0);
	}
	else if(War3_GetRace(client)==thisRaceID)
	{
		ActivateSkills(client);
	}
}

public ActivateSkills(client)
{
	// blitz
	new skill_blitz=War3_GetSkillLevel(client,thisRaceID,SKILL_BLITZ);
	new Float:orcblitz=forcblitz[skill_blitz];
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
	War3_SetBuff(client,fMaxSpeed,thisRaceID,orcblitz);

	// lustful power
	new skill_lustful_power=War3_GetSkillLevel(client,thisRaceID,SKILL_LUSTFUL_POWER);
	new Float:orclustfulpower=forclustfulpower[skill_lustful_power];
	War3_SetBuff(client,fAttackSpeed,thisRaceID,orclustfulpower);
	// reduced magic resistance
	new Float:fMagicResistanceReduction=MagicResistanceReduction[skill_lustful_power];
	War3_SetBuff(client,fArmorMagic,thisRaceID,fMagicResistanceReduction);

	War3_SetBuff(client,bDisarm,thisRaceID,false);

}

public OnW3Denyable(W3DENY:event,client)
{
	if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == War3_GetItemIdByShortname("antiward")))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			W3Deny();
			War3_ChatMessage(client, "I'm  a strong green orcish force and I don't need no antiward!");
		}
	}
}
/*
public OnWar3Event(W3EVENT:event, client)
{
	if(event == CanBuyItem)
	{
		new item = W3GetVar(EventArg1);
		new itemname=War3_GetItemIdByShortname("antiward");
		if(item==itemname && War3_GetRace(client)==thisRaceID)
			{
				W3SetVar(EventArg2, 0);
				War3_ChatMessage(client, "I'm  a strong green orcish force and I don't need no antiward!");
				//War3_SetGold(client,100);
				//War3_SetOwnsItem(client,item,false);
				//PrintToChat(client,"Store refunded your gold.");
			}
		else W3SetVar(EventArg2, 1);
	}
}
  */
public TF2_OnConditionAdded(client, TFCond:condition)
{
	if(ValidPlayer(client))
	{
		if(TF2_IsPlayerInCondition(client,TFCond_OnFire) && War3_GetRace(client)==thisRaceID)
		{
			//DP("Player is on fire!");
			new skill_blitz=War3_GetSkillLevel(client,thisRaceID,SKILL_BLITZ);
			new Float:orcblitz=forcblitz[skill_blitz]*OnFireToSlow[skill_blitz]; // by 50%

			War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
			War3_SetBuff(client,fSlow,thisRaceID,orcblitz);
			/*else
			{
				orcblitz=forcblitz[skill_blitz];
				War3_SetBuff(client,fSlow,thisRaceID,1.0);
				War3_SetBuff(client,fMaxSpeed,thisRaceID,orcblitz);
			} */
		}
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(ValidPlayer(client))
	{
		if(!(TF2_IsPlayerInCondition(client,TFCond_OnFire)) && War3_GetRace(client)==thisRaceID)
		{
			new skill_blitz=War3_GetSkillLevel(client,thisRaceID,SKILL_BLITZ);
			new Float:orcblitz=forcblitz[skill_blitz];
			War3_SetBuff(client,fSlow,thisRaceID,1.0);
			War3_SetBuff(client,fMaxSpeed,thisRaceID,orcblitz);
		}
	}
}

public DoChain(client,Float:distance,dmg,bool:first_call,last_target)
{
	new target=0;
	new Float:target_dist=distance+1.0; // just an easy way to do this
	new caster_team=GetClientTeam(client);
	new Float:start_pos[3];
	if(last_target<=0)
		GetClientAbsOrigin(client,start_pos);
	else
		GetClientAbsOrigin(last_target,start_pos);
	for(new x=1;x<=MaxClients;x++)
	{
		if(ValidPlayer(x,true)&&!bBeenHit[client][x]&&caster_team!=GetClientTeam(x)&&!W3HasImmunity(x,Immunity_Ultimates))
		{
			new Float:this_pos[3];
			GetClientAbsOrigin(x,this_pos);
			new Float:dist_check=GetVectorDistance(start_pos,this_pos);
			if(dist_check<=target_dist)
			{
				// found a candidate, whom is currently the closest
				target=x;
				target_dist=dist_check;
			}
		}
	}
	if(target<=0)
	{
	//DP("no target");
		// no target, if first call dont do cooldown
		if(first_call)
		{
			W3MsgNoTargetFound(client,distance);
		}
		else
		{
			// alright, time to cooldown
			new Float:cooldown=GetConVarFloat(ultCooldownCvar);
			War3_CooldownMGR(client,cooldown,thisRaceID,ULT_LIGHTNING,_,_);
			War3_SetBuff(client,bDisarm,thisRaceID,true); //since this is where the cooldown activates it seems appropriate to activate the disarm here - Dagothur 1/16/2013
			//DP("CD %f %d %d",cooldown,thisRaceID,ULT_LIGHTNING);
		}
	}
	else
	{
		// found someone
		if(!W3HasImmunity(target,Immunity_Ultimates))
		{
			bBeenHit[client][target]=true; // don't let them get hit twice
			War3_DealDamage(target,dmg,client,DMG_ENERGYBEAM,"chainlightning");
			PrintHintText(target,"Hit by Chain Lightning -%i HP",War3_GetWar3DamageDealt());
			start_pos[2]+=30.0; // offset for effect
			decl Float:target_pos[3],Float:vecAngles[3];
			GetClientAbsOrigin(target,target_pos);
			target_pos[2]+=30.0;
			TE_SetupBeamPoints(start_pos,target_pos,BeamSprite,HaloSprite,0,35,1.0,25.0,25.0,0,10.0,{255,100,255,255},40);
			TE_SendToAll();
			GetClientEyeAngles(target,vecAngles);
			TE_SetupBloodSprite(target_pos, vecAngles, {200, 20, 20, 255}, 28, BloodSpray, BloodDrop);
			TE_SendToAll();
			EmitSoundToAll( lightningSound , target,_,SNDLEVEL_TRAIN);
			new new_dmg=RoundFloat(float(dmg)*0.66);
		
			DoChain(client,distance,new_dmg,false,target);
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new skill=War3_GetSkillLevel(client,race,ULT_LIGHTNING);
		if(skill>0)
		{
			
			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_LIGHTNING,true)&&!Silenced(client))
			{
					
				for(new x=1;x<=MaxClients;x++)
					bBeenHit[client][x]=false;
				
				new Float:distance=ChainDistance[skill];
				// Dochange was 60 damage:
				DoChain(client,distance,90,true,0); // This function should also handle if there aren't targets
				
				CreateTimer(DischargeDelay[skill],Enable_Attack,GetClientUserId(client));
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

public Action:Enable_Attack(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(ValidPlayer(client))
	{
		War3_SetBuff(client,bDisarm,thisRaceID,false);
	}
}


new int:totalChecks;
new checkArray[20][4];

public OnMapStart()
{
	decl String:mapname[128];
    GetCurrentMap(mapname, sizeof(mapname));
	//DP(mapname);
	if (strcmp(mapname, "pl_goldrush", false) == 0) {
		totalChecks = 2;
		checkArray[0][0] = -2200; //x < 
		checkArray[0][1] = -3700; //x >
		checkArray[0][2] = 1700; //y >
		checkArray[0][3] = 2200; //y <
		
		checkArray[1][0] = -4100;
		checkArray[1][1] = -4700;
		checkArray[1][2] = -2666;
		checkArray[1][3] = -2255;
	} else if (strcmp(mapname, "koth_nucleus", false) == 0)	{
		totalChecks = 6;
		checkArray[0][0] = -1300; //x < 
		checkArray[0][1] = -1500; //x >
		checkArray[0][2] = -450; //y >
		checkArray[0][3] = 400; //y <
		
		checkArray[1][0] = 1500; //x < 
		checkArray[1][1] = 1200; //x >
		checkArray[1][2] = -400; //y >
		checkArray[1][3] = 400; //y <
		
		checkArray[2][0] = 2000; //x < not bugged
		checkArray[2][1] = 1600; //x >
		checkArray[2][2] = 100; //y >
		checkArray[2][3] = 400; //y <
		
		checkArray[3][0] = 1800; //x < not bugged
		checkArray[3][1] = 1100; //x >
		checkArray[3][2] = -1000; //y >
		checkArray[3][3] = -700; //y <
		
		checkArray[4][0] = -1100; //x < not bugged
		checkArray[4][1] = -1900; //x >
		checkArray[4][2] = -1000; //y >
		checkArray[4][3] = -700; //y <
		
		checkArray[5][0] = -1600; //x < not bugged
		checkArray[5][1] = -2000; //x >
		checkArray[5][2] = 100; //y >]
		checkArray[5][3] = 400; //y <
		
	}	 else if (strcmp(mapname, "koth_viaduct", false) == 0)	{
		totalChecks = 2;
		checkArray[0][0] = -928; //x < 
		checkArray[0][1] = -1800; //x >
		checkArray[0][2] = 2823; //y >
		checkArray[0][3] = 3224; //y <
		
		checkArray[1][0] = -1000;
		checkArray[1][1] = -1700;
		checkArray[1][2] = -3200;
		checkArray[1][3] = -2800;
	}  else if (strcmp(mapname, "koth_lakeside_final", false) == 0)	{
		totalChecks = 2;
		checkArray[0][0] = 3400; //x < 
		checkArray[0][1] = 2800; //x >
		checkArray[0][2] = -1000; //y >
		checkArray[0][3] = -50; //y <
		
		checkArray[1][0] = -2600;
		checkArray[1][1] = -3400;
		checkArray[1][2] = -1000;
		checkArray[1][3] = 50;
	} else if (strcmp(mapname, "koth_harvest_final", false) == 0)	{
		totalChecks = 2;
		checkArray[0][0] = 900; //x < 
		checkArray[0][1] = 27; //x >
		checkArray[0][2] = 1700; //y >
		checkArray[0][3] = 2100; //y <
		
		checkArray[1][0] = -27;
		checkArray[1][1] = -900;
		checkArray[1][2] = -2100;
		checkArray[1][3] = -1700;
	}  else if (strcmp(mapname, "pl_badwater", false) == 0)	{
		totalChecks = 5;
		checkArray[0][0] = -1000; //x < 
		checkArray[0][1] = -1300; //x >
		checkArray[0][2] = -80; //y >
		checkArray[0][3] = 200; //y <
		
		checkArray[1][0] = 255;
		checkArray[1][1] = -230;
		checkArray[1][2] = -90;
		checkArray[1][3] = 300;
		
		checkArray[2][0] = 550; //x < 
		checkArray[2][1] = 375; //x >
		checkArray[2][2] = 150; //y >
		checkArray[2][3] = 900; //y <
		
		checkArray[3][0] = 3200;


		checkArray[3][1] = 2650;
		checkArray[3][2] = -2000;
		checkArray[3][3] = -400;
		
		checkArray[4][0] = -1500; //x < 
		checkArray[4][1] = -2250; //x >
		checkArray[4][2] = -1100; //y >
		checkArray[4][3] = -725; //y <
	} else if (strcmp(mapname, "pl_upward", false) == 0)	{
		totalChecks = 6;
		checkArray[0][0] = -600; //x < 
		checkArray[0][1] = -1000; //x >
		checkArray[0][2] = -2300; //y >
		checkArray[0][3] = -1900; //y <
		
		checkArray[1][0] = -1600; //x < 
		checkArray[1][1] = -2000; //x >
		checkArray[1][2] = -1700; //y >
		checkArray[1][3] = -1400; //y <
		
		checkArray[2][0] = -1150; //x < not bugged
		checkArray[2][1] = -1400; //x >
		checkArray[2][2] = -1300; //y >
		checkArray[2][3] = -800; //y <
		
		checkArray[3][0] = 720; //x < not bugged
		checkArray[3][1] = 300; //x >
		checkArray[3][2] = 1000; //y >
		checkArray[3][3] = 1400; //y <
		
		checkArray[4][0] = 1000; //x < not bugged
		checkArray[4][1] = 88; //x >
		checkArray[4][2] = -25; //y >
		checkArray[4][3] = 730; //y <
		
		checkArray[5][0] = 2000; //x < not bugged
		checkArray[5][1] = 1500; //x >
		checkArray[5][2] = -800; //y >]
		checkArray[5][3] = -475; //y <		

		
	}  else if (strcmp(mapname, "cp_dustbowl", false) == 0)	{
		totalChecks = 7;
		checkArray[0][0] = -1750; //x < 
		checkArray[0][1] = -2500; //x >
		checkArray[0][2] = 2264; //y >
		checkArray[0][3] = 3100; //y <
		
		checkArray[1][0] = -1550; //x < 
		checkArray[1][1] = -1800; //x >
		checkArray[1][2] = 1400; //y >
		checkArray[1][3] = 2100; //y <
		
		checkArray[2][0] = 2900; //x < not bugged
		checkArray[2][1] = 1400; //x >
		checkArray[2][2] = -350; //y >
		checkArray[2][3] = 1100; //y <
		
		checkArray[3][0] = -1300; //x < not bugged
		checkArray[3][1] = -2655; //x >
		checkArray[3][2] = -1750; //y >
		checkArray[3][3] = -560; //y <
		
		checkArray[4][0] = -215; //x < not bugged
		checkArray[4][1] = -1300; //x >
		checkArray[4][2] = 250; //y >
		checkArray[4][3] = 1315; //y <
		
		checkArray[5][0] = 300; //x < not bugged
		checkArray[5][1] = -100; //x >
		checkArray[5][2] = 600; //y >]
		checkArray[5][3] = 1000; //y <
		
		checkArray[6][0] = 1300; //x < not bugged
		checkArray[6][1] = 800; //x >
		checkArray[6][2] = 600; //y >]
		checkArray[6][3] = 1000; //y <

	} else if (strcmp(mapname, "pl_hoodoo_final", false) == 0)	{
		totalChecks = 5;
		checkArray[0][0] = 5700; //x < 
		checkArray[0][1] = 5000; //x >
		checkArray[0][2] = 340; //y >
		checkArray[0][3] = 1400; //y <
		
		checkArray[1][0] = 2700; //x < 
		checkArray[1][1] = 1450; //x >
		checkArray[1][2] = -3800; //y >
		checkArray[1][3] = -1750; //y <
		
		checkArray[2][0] = -3400; //x < not bugged
		checkArray[2][1] = -3900; //x >
		checkArray[2][2] = -1650; //y >
		checkArray[2][3] = -1200; //y <
		
		checkArray[3][0] = -4200; //x < not bugged
		checkArray[3][1] = -4800; //x >
		checkArray[3][2] = -1300; //y >
		checkArray[3][3] = -300; //y <
		
		checkArray[4][0] = -7700; //x < not bugged
		checkArray[4][1] = -8800; //x >
		checkArray[4][2] = -1100; //y >
		checkArray[4][3] = 0; //y <
		

		
	} else {
		totalChecks = 0;
	}
	
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
	
	BloodSpray = PrecacheModel("sprites/bloodspray.vmt");
	BloodDrop = PrecacheModel("sprites/blood.vmt");
	
	War3_PrecacheSound(lightningSound);
	War3_PrecacheSound(wardDamageSound);

}

/* SHADOW HUNTER SWAP ABILITY BELOW */
public bool:wardCheck(client)
{
	
	if (!totalChecks)
		return false;
	
	
	new Float:vec[3];
	GetClientAbsOrigin(client, vec);
	
	for(new x=0;x<totalChecks;x++) {
		if (vec[0] < checkArray[x][0] && vec[0] > checkArray[x][1] && vec[1] > checkArray[x][2] && vec[1] < checkArray[x][3]) {
			War3_ChatMessage(client, "You cannot place wards here, cheapo!");
			return true;
		} 
	}
	return false;
}
public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_WARD);
		if(skill_level>0)
		{
			if (!wardCheck(client)) 
			{
				if(!Silenced(client)&&CurrentWardCount[client]<WardStartingArr[skill_level])
				{
					new iTeam=GetClientTeam(client);
					new bool:conf_found=false;
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
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	if(race==thisRaceID)
	{
		ActivateSkills(client);
		//War3_SetBuff(client,fInvisibilitySkill,thisRaceID,alpha);
		//War3_SetBuff(client,bInvisibilityDenySkill,thisRaceID,false);
	}
}

public OnWar3EventSpawn(client)
{
	RemoveWards(client);
	for(new x=1;x<=MaxClients;x++)
		bBeenHit[client][x]=false;
/*	if(ValidPlayer(client))
	{
		if(IsFakeClient(client))
		{
			if(War3_GetRace(client)==thisRaceID)
			{
			}
		}
	}*/
}

new damagestackcritmatch=-1;
new Float:critpercent=0.0;
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new Float:chance_mod=W3ChanceModifier(attacker);
			if(race_attacker==thisRaceID)
			{
				new skill_cs_attacker=War3_GetSkillLevel(attacker,race_attacker,SKILL_CRIT);
				if(skill_cs_attacker>0&&!Hexed(attacker,false))
				{
					//new Float:chance=0.15*chance_mod;
					new Float:chance=0.30*chance_mod;
					if( GetRandomFloat(0.0,1.0)<=chance && !W3HasImmunity(victim,Immunity_Skills))
					{
						damagestackcritmatch=W3GetDamageStack();
						new Float:percent=CriticalStrikePercent[skill_cs_attacker]; //0.0 = zero effect -1.0 = no damage 1.0=double damage
						War3_DamageModPercent(percent+1.0);
						critpercent=percent;
					}
				}
			}
		}
	}
}

//need event for weapon string
public OnWar3EventPostHurt(victim,attacker,dmg){
	// Trigger Ultimate on bots 5% chance
	if(ValidPlayer(victim))
	{
		if(IsFakeClient(victim)&&War3_GetRace(victim)==thisRaceID&&W3Chance(0.05))
		{
			//DP("ultimate should trigger");
			OnUltimateCommand(victim,thisRaceID,true);
			new Float:cooldown=GetConVarFloat(ultCooldownCvar);
			War3_CooldownMGR(victim,cooldown,thisRaceID,ULT_LIGHTNING,true,false);
		}
	}
	if(victim>0&&attacker>0&&victim!=attacker)
	{
		new race_attacker=War3_GetRace(attacker);
		
		if(race_attacker==thisRaceID)
		{
			if(damagestackcritmatch==W3GetDamageStack())
			{
				damagestackcritmatch=-1;
				W3PrintSkillDmgHintConsole(victim,attacker,RoundFloat(float(dmg)*critpercent/(critpercent+1.0)),SKILL_CRIT);	
				W3FlashScreen(victim,RGBA_COLOR_RED);	
			}
		}
	}
}

/*
public OnWar3EventDeath(index,attacker)
{
} */

/* *********************** SHADOW HUNTER SWAP ************************* */

CreateWard(client)
{
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]==0)
		{
			WardOwner[i]=client;
			GetClientAbsOrigin(client,WardLocation[i]);
			break;
			////CHECK BOMB HOSTAGES TO BE IMPLEMENTED
		}
	}
}

RemoveWards(client)
{
	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]==client)
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
				WardEffectAndDamage(client,i);
			}
		}
	}
}
public WardEffectAndDamage(owner,wardindex)
{
	new ownerteam=GetClientTeam(owner);
	new beamcolor[]={0,0,200,255};
	if(ownerteam==2)
	{ //TERRORISTS/RED in TF?
		beamcolor[0]=255;
		beamcolor[1]=0;
		beamcolor[2]=0;

		beamcolor[3]=155; //red blocks more than blue, so less alpha
	}


	new Float:start_pos[3];
	new Float:end_pos[3];

	new Float:tempVec1[]={0.0,0.0,WARDBELOW};
	new Float:tempVec2[]={0.0,0.0,WARDABOVE};
	AddVectors(WardLocation[wardindex],tempVec1,start_pos);
	AddVectors(WardLocation[wardindex],tempVec2,end_pos);

	TE_SetupBeamPoints(start_pos,end_pos,BeamSprite,HaloSprite,0,GetRandomInt(30,100),0.17,float(WARDRADIUS),float(WARDRADIUS),0,0.0,beamcolor,10);
	TE_SendToAll();

	new Float:BeamXY[3];
	for(new x=0;x<3;x++) BeamXY[x]=start_pos[x]; //only compare xy
	new Float:BeamZ= BeamXY[2];
	BeamXY[2]=0.0;


	new Float:VictimPos[3];
	new Float:tempZ;
	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&& GetClientTeam(i)!=ownerteam )
		{
			GetClientAbsOrigin(i,VictimPos);
			tempZ=VictimPos[2];
			VictimPos[2]=0.0; //no Z

			if(GetVectorDistance(BeamXY,VictimPos) < WARDRADIUS) ////ward RADIUS
			{
				// now compare z
				if(tempZ>BeamZ+WARDBELOW && tempZ < BeamZ+WARDABOVE)
				{
					if(W3HasImmunity(i,Immunity_Wards))
					{
						W3MsgSkillBlocked(i,_,"Wards");
					}
					else
					{
						//Boom!
						new DamageScreen[4];
						DamageScreen[0]=beamcolor[0];
						DamageScreen[1]=beamcolor[1];
						DamageScreen[2]=beamcolor[2];
						DamageScreen[3]=50; //alpha
						W3FlashScreen(i,DamageScreen);
						if(War3_DealDamage(i,WARDDAMAGE,owner,DMG_ENERGYBEAM,"wards",_,W3DMGTYPE_MAGIC))
						{
							if(LastThunderClap[i]<GetGameTime()-2)
							{
								EmitSoundToAll(wardDamageSound,i,SNDCHAN_WEAPON);
								LastThunderClap[i]=GetGameTime();
							}
						}
					}
				}
			}
		}
	}

}
