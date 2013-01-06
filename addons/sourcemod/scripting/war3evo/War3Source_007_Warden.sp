/**
 * File: War3Source_Warden.sp
 * Description: The Warden race for War3Source.
 * Author(s): Anthony Iacono & Ownage | Ownz (DarkEnergy)
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
public W3ONLY(){} //unload this?
new thisRaceID;

//skill 1
new Float:FanOfKnivesTFChanceArr[]={0.0,0.05,0.1,0.15,0.2};
new const KnivesTFDamage = 50; 
new const Float:KnivesTFRadius = 300.0;
 
//skill 2
new Float:BlinkChanceArr[]={0.00,0.25,0.5,0.75,1.00};

//skill 3
new const ShadowStrikeInitialDamage=20;
new const ShadowStrikeTrailingDamage=5;
new Float:ShadowStrikeChanceArr[]={0.0,0.05,0.1,0.15,0.2};
new ShadowStrikeTimes[]={0,2,3,4,5};
new BeingStrikedBy[MAXPLAYERSCUSTOM];
new StrikesRemaining[MAXPLAYERSCUSTOM];

//ultimate
new Handle:ultCooldownCvar;

new Float:VengenceTFHealHPPercent[]={0.0,0.25,0.5,0.75,1.0};

#define IMMUNITYBLOCKDISTANCE 300.0


new SKILL_FANOFKNIVES, SKILL_BLINK,SKILL_SHADOWSTRIKE,ULT_VENGENCE;

//new String:shadowstrikestr[]="war3source/shadowstrikebirth.wav";
//new String:ultimateSound[]="war3source/MiniSpiritPissed1.wav";

new String:shadowstrikestr[]="war3source/shadowstrikebirth.mp3";
new String:ultimateSound[]="war3source/MiniSpiritPissed1.mp3";

new BeamSprite;
new HaloSprite;

public Plugin:myinfo =
{
	name = "Race - Warden",
	author = "PimpinJuice & Ownz (DarkEnergy)",
	description = "The Warden race for War3Source.",
	version = "1.0.0.0",
	url = "http://Www.OwnageClan.Com"
};

public OnPluginStart()
{
	
	ultCooldownCvar=CreateConVar("war3_warden_vengence_cooldown","20","Cooldown between Warden Vengence (ultimate)");
	
	CreateTimer(0.2,CalcBlink,_,TIMER_REPEAT);

	LoadTranslations("w3s.race.warden.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==0)
	{
		thisRaceID=War3_CreateNewRaceT("warden");
		SKILL_FANOFKNIVES=War3_AddRaceSkillT(thisRaceID,"FanOfKnivesTF",false,4);
		SKILL_BLINK=War3_AddRaceSkillT(thisRaceID,"Immunity",false,4);
		SKILL_SHADOWSTRIKE=War3_AddRaceSkillT(thisRaceID,"ShadowStrike",false,4);
		ULT_VENGENCE=War3_AddRaceSkillT(thisRaceID,"VengenceTF",true,4);
		War3_CreateRaceEnd(thisRaceID);
	
	}
		
	
}

public OnMapStart()
{
	War3_PrecacheSound(shadowstrikestr);
	War3_PrecacheSound(ultimateSound);
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
}

public OnWar3EventSpawn(client){
	StrikesRemaining[client]=0;
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace!=thisRaceID)
	{	
		War3_SetBuff(client,bImmunityUltimates,thisRaceID,false);
	}

}


public OnUltimateCommand(client,race,bool:pressed)
{
	// TODO: Increment UltimateUsed[client]
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_VENGENCE);
		if(ult_level>0)
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_VENGENCE,true))
			{
				if(!blockingVengence(client))
				{
					new maxhp=War3_GetMaxHP(client);
				
					new heal=RoundToCeil(float(maxhp)*VengenceTFHealHPPercent[ult_level]);
					War3_HealToBuffHP(client,heal);
					W3FlashScreen(client,{0,255,0,20},0.5,_,FFADE_OUT);
					
					W3EmitSoundToAll(ultimateSound,client);
					W3EmitSoundToAll(ultimateSound,client);
					
					War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_VENGENCE,_,_);
					
				}
				else
				{
					W3MsgUltimateBlocked(client);
				}
				
			}
			
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}



public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		if(IsPlayerAlive(attacker)&&IsPlayerAlive(victim)&&GetClientTeam(victim)!=GetClientTeam(attacker))
		{
			//VICTIM IS WAREN!!! 
			if(War3_GetRace(victim)==thisRaceID)
			{
				new Float:chance_mod=W3ChanceModifier(attacker);
				/// CHANCE MOD BY ATTACKER
				new skill_level = War3_GetSkillLevel(victim,thisRaceID,SKILL_FANOFKNIVES);
				if(!Hexed(victim,false)&&GetRandomFloat(0.0,1.0)<=chance_mod*FanOfKnivesTFChanceArr[skill_level])
				{
					//knives damage hp around the victim
					W3MsgThrewKnives(victim);
					new Float:playerVec[3];
					GetClientAbsOrigin(victim,playerVec);

					playerVec[2]+=20;
					TE_SetupBeamRingPoint(playerVec, 10.0, KnivesTFRadius, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, {255,255,255,155}, 100, 0);
					TE_SendToAll();
					playerVec[2]-=20;

					new Float:otherVec[3];
					new team = GetClientTeam(victim);
					for(new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i,true)&&GetClientTeam(i)!=team)
						{
							GetClientAbsOrigin(i,otherVec);
							if(GetVectorDistance(playerVec,otherVec)<KnivesTFRadius)
							{
								if(War3_DealDamage(i,KnivesTFDamage,victim,DMG_BULLET,"knives",W3DMGORIGIN_SKILL,W3DMGTYPE_MAGIC))
								{
									W3FlashScreen(i,RGBA_COLOR_RED);
									W3MsgHitByKnives(i);
									decl Float:StartPos[3];
									GetClientAbsOrigin(victim,StartPos);
									StartPos[2]+=40;
									TE_SetupBeamRingPoint(StartPos, 150.0, 10.0, BeamSprite, HaloSprite, 0, 10, 0.8, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
									TE_SendToAll();
									TE_SetupBeamRingPoint(StartPos, 150.0, 10.0, BeamSprite, HaloSprite, 0, 10, 0.8, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
									TE_SendToAll(0.3);
									TE_SetupBeamRingPoint(StartPos, 150.0, 10.0, BeamSprite, HaloSprite, 0, 10, 0.8, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
									TE_SendToAll(0.6);
									TE_SetupBeamRingPoint(StartPos, 10.0, 200.0, BeamSprite, HaloSprite, 0, 10, 0.5, 20.0, 0.0, {255,50,130,255}, 1600, FBEAM_SINENOISE);
									TE_SendToAll(0.8);
								}
								else {
									W3MsgSkillBlocked(i,_,"Knives");
								}
							}
						}
					}
				}
			}
			//ATTACKER IS WARDEN
			if(War3_GetRace(attacker)==thisRaceID)
			{
				//shadow strike poison
				new Float:chance_mod=W3ChanceModifier(attacker);
				/// CHANCE MOD BY VICTIM
				new skill_level = War3_GetSkillLevel(attacker,thisRaceID,SKILL_SHADOWSTRIKE);
				if(skill_level>0 && StrikesRemaining[victim]==0 && !Hexed(attacker,false)&&GetRandomFloat(0.0,1.0)<=chance_mod*ShadowStrikeChanceArr[skill_level])
				{
					if(W3HasImmunity(victim,Immunity_Skills))
					{
						W3MsgSkillBlocked(victim,attacker,"Shadow Strike");
					}
					else
					{
						W3MsgAttackedBy(victim,"Shadow Strike");
						W3MsgActivated(attacker,"Shadow Strike");
						
						BeingStrikedBy[victim]=attacker;
						StrikesRemaining[victim]=ShadowStrikeTimes[skill_level];
						War3_DealDamage(victim,ShadowStrikeInitialDamage,attacker,DMG_BULLET,"shadowstrike");
						W3FlashScreen(victim,RGBA_COLOR_RED);
						
						W3EmitSoundToAll(shadowstrikestr,attacker);
						W3EmitSoundToAll(shadowstrikestr,attacker);
						CreateTimer(1.0,ShadowStrikeLoop,GetClientUserId(victim));
					}
				}
			}
		}
	}
}
public Action:ShadowStrikeLoop(Handle:timer,any:userid)
{
	new victim = GetClientOfUserId(userid);
	if(StrikesRemaining[victim]>0 && ValidPlayer(BeingStrikedBy[victim]) && ValidPlayer(victim,true))
	{
		War3_DealDamage(victim,ShadowStrikeTrailingDamage,BeingStrikedBy[victim],DMG_BULLET,"shadowstrike");
		StrikesRemaining[victim]--;
		W3FlashScreen(victim,RGBA_COLOR_RED);
		CreateTimer(1.0,ShadowStrikeLoop,userid);
		decl Float:StartPos[3];
		GetClientAbsOrigin(victim,StartPos);
		TE_SetupDynamicLight(StartPos,255,255,100,100,100.0,0.3,3.0);
		TE_SendToAll();
	}
}

stock TE_SetupDynamicLight(const Float:vecOrigin[3], r,g,b,iExponent,Float:fRadius,Float:fTime,Float:fDecay)
{
	TE_Start("Dynamic Light");
	TE_WriteVector("m_vecOrigin",vecOrigin);
	TE_WriteNum("r",r);
	TE_WriteNum("g",g);
	TE_WriteNum("b",b);
	TE_WriteNum("exponent",iExponent);
	TE_WriteFloat("m_fRadius",fRadius);
	TE_WriteFloat("m_fTime",fTime);
	TE_WriteFloat("m_fDecay",fDecay);
}

stock TE_SetupBubbles(const Float:vecOrigin[3], const Float:vecFinish[3],modelIndex,const Float:heightF,count,const Float:speedF)
{
	TE_Start("Bubbles");
	TE_WriteVector("m_vecMins", vecOrigin);
	TE_WriteVector("m_vecMaxs", vecFinish);
	TE_WriteFloat("m_fHeight", heightF);
	TE_WriteNum("m_nModelIndex", modelIndex);
	TE_WriteNum("m_nCount", count);
	TE_WriteFloat("m_fSpeed", speedF);
}

public Action:CalcBlink(Handle:timer,any:userid)
{
	if(thisRaceID>0)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i,true)&&War3_GetRace(i)==thisRaceID)
			{
				War3_SetBuff(i,bImmunityUltimates,thisRaceID, (GetRandomFloat(0.0,1.0)<BlinkChanceArr[War3_GetSkillLevel(i,thisRaceID,SKILL_BLINK)]) ? true:false);
			}
		}
	}
}

public bool:blockingVengence(client)  //TF2 only
{
	//ELIMINATE ULTIMATE IF THERE IS IMMUNITY AROUND
	new Float:playerVec[3];
	GetClientAbsOrigin(client,playerVec);
	new Float:otherVec[3];
	new team = GetClientTeam(client);

	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates))
		{
			GetClientAbsOrigin(i,otherVec);
			if(GetVectorDistance(playerVec,otherVec)<IMMUNITYBLOCKDISTANCE)
			{
				return true;
			}
		}
	}
	return false;
}