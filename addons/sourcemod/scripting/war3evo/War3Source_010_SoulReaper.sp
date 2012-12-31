/**
 * 
 * Description:   SR FROM HON
 * Author(s): Ownz (DarkEnergy) and pimpjuice
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <cstrike>

public W3ONLY(){} //unload this?
new thisRaceID;
new Handle:ultCooldownCvar;

new SKILL_JUDGE, SKILL_PRESENCE,SKILL_INHUMAN, ULT_EXECUTE;


// Chance/Data Arrays
new JudgementAmount[5]={0,10,20,30,40};
new Float:JudgementCooldownTime=10.0;
new Float:JudgementRange=200.0;

new Float:PresenseAmount[5]={0.0,0.5,1.0,1.5,2.0}; 
new Float:PresenceRange=400.0;

new InhumanAmount[5]={0,5,10,15,20};
new Float:InhumanRange=400.0;

new Float:ultRange=300.0;
new Float:ultiDamageMulti[5]={0.0,0.4,0.6,0.8,1.0};

new String:judgesnd[256]; //="war3source/sr/judgement.mp3";
new String:ultsnd[256]; //="war3source/sr/ult.mp3";

new AuraID;

public Plugin:myinfo = 
{
	name = "Race - Soul Reaper",
	author = "Ownz (DarkEnergy)",
	description = "Soul Reaper for War3Source.",
	version = "1.0",
	url = "War3Source.com"
};

public OnPluginStart()
{
	HookEvent("player_death",PlayerDeathEvent);
	
	ultCooldownCvar=CreateConVar("war3_sr_ult_cooldown","20","Cooldown time for CD ult overload.");
	
	LoadTranslations("w3s.race.sr.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==100)
	{
		thisRaceID=War3_CreateNewRaceT("sr");
		SKILL_JUDGE=War3_AddRaceSkillT(thisRaceID,"Judgement",false,4);
		SKILL_PRESENCE=War3_AddRaceSkillT(thisRaceID,"WitheringPresence",false,4);
		SKILL_INHUMAN=War3_AddRaceSkillT(thisRaceID,"InhumanNature",false,4);
		ULT_EXECUTE=War3_AddRaceSkillT(thisRaceID,"DemonicExecution",true,4); 
		War3_CreateRaceEnd(thisRaceID);
		
		AuraID=W3RegisterAura("witheringpresense",PresenceRange,true);
	}
}

public OnMapStart()
{
	if(GAMECSGO)
	{
		strcopy(judgesnd,sizeof(judgesnd),"music/war3source/sr/judgement.mp3");
		strcopy(ultsnd,sizeof(ultsnd),"music/war3source/sr/ult.mp3");
	}
	else
	{
		strcopy(judgesnd,sizeof(judgesnd),"war3source/sr/judgement.mp3");
		strcopy(ultsnd,sizeof(ultsnd),"war3source/sr/ult.mp3");
	}

	War3_PrecacheSound(judgesnd);
	War3_PrecacheSound(ultsnd);
}



public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,SKILL_JUDGE);
		if(skill_level>0)
		{
			
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,SKILL_JUDGE,true))
			{
				new amount=JudgementAmount[skill_level];
				
				new Float:playerOrigin[3];
				GetClientAbsOrigin(client,playerOrigin);
				
				new team = GetClientTeam(client);
				new Float:otherVec[3];
				for(new i=1;i<=MaxClients;i++){
					if(ValidPlayer(i,true)){
						GetClientAbsOrigin(i,otherVec);
						if(GetVectorDistance(playerOrigin,otherVec)<JudgementRange)
						{
							if(GetClientTeam(i)==team){
								War3_HealToMaxHP(i,amount);
							}
							else{
								War3_DealDamage(i,amount,client,DMG_BURN,"judgement",W3DMGORIGIN_SKILL);
							}
							
						}
					}
				}
				PrintHintText(client,"%T","+/- {amount} HP",client,amount);
				W3EmitSoundToAll(judgesnd,client);
				//EmitSoundToAll(judgesnd,client);
				War3_CooldownMGR(client,JudgementCooldownTime,thisRaceID,SKILL_JUDGE,true,true);
				
			}
		}
	}
}


public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && IsPlayerAlive(client))
	{
		//if(
		
		new skill=War3_GetSkillLevel(client,race,ULT_EXECUTE);
		if(skill>0)
		{
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_EXECUTE,true))
			{
				new target=War3_GetTargetInViewCone(client,ultRange,false);
				if(ValidPlayer(target,true)&&!W3HasImmunity(target,Immunity_Ultimates))
				{

					new hpmissing=War3_GetMaxHP(target)-GetClientHealth(target);
					
					new dmg=RoundFloat(FloatMul(float(hpmissing),ultiDamageMulti[skill]));
					
					if(War3_DealDamage(target,dmg,client,_,"demonicexecution"))
					{
						PrintToConsole(client,"T%","Executed for {amount} damage",client,War3_GetWar3DamageDealt());
						War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_EXECUTE,true,true);
					
						W3EmitSoundToAll(ultsnd,client);
						
						W3EmitSoundToAll(ultsnd,target);
					}
				}
				else
				{
					W3MsgNoTargetFound(client,ultRange);
				}
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}



CheckAura(client){
	new level=War3_GetSkillLevel(client,thisRaceID,SKILL_PRESENCE);
	W3SetAuraFromPlayer(AuraID,client,level>0?true:false,level);
}
public OnRaceChanged(client,oldrace,newrace)
{
	if(newrace==thisRaceID)
	{
		CheckAura(client);
	}
	else if(oldrace==thisRaceID){
		W3SetAuraFromPlayer(AuraID,client,false);
	}
}
public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	if(race==thisRaceID && War3_GetRace(client)==thisRaceID)
	{
		CheckAura(client);
	}
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new victim=GetClientOfUserId(userid);
	
	if(victim>0)
	{
		new Float:deathvec[3];
		GetClientAbsOrigin(victim,deathvec);
		
		new Float:gainhpvec[3];
		
		for(new client=1;client<=MaxClients;client++)
		{
			if(ValidPlayer(client,true)&&War3_GetRace(client)==thisRaceID){
				GetClientAbsOrigin(client,gainhpvec);
				if(GetVectorDistance(deathvec,gainhpvec)<InhumanRange){
					new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_INHUMAN);
					if(skilllevel>0&&!Hexed(client)){
						War3_HealToMaxHP(client,InhumanAmount[skilllevel]);
					}
				}
			}
		}
		//new deathFlags = GetEventInt(event, "death_flags");
	// where is the list of flags? idksee firefox
		//if (War3_GetGame()==Game_TF&&deathFlags & 32)
		//{
		   //PrintToChat(client,"war3 debug: dead ringer kill");
		//}

		
	}
}

public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
	if(aura==AuraID)
	{
		War3_SetBuff(client,fHPDecay,thisRaceID,inAura?PresenseAmount[level]:0.0);
		//DP("%d %f",inAura,HealingWaveAmountArr[level]);
	}
}