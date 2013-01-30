#define PLUGIN_VERSION "0.0.0.1"
/**
* File: War3Source_BloodMage.sp
* Description: The Blood Mage race for War3Source.
* Author(s): Anthony Iacono & Ownage | Ownz (DarkEnergy)
*
*  REWRITTEN FOR TF2 ONLY - el diablo
*/


#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
public W3ONLY(){} //unload this?
// TODO: Effects

new thisRaceID;

new SKILL_REVIVE, SKILL_BANISH, SKILL_MONEYSTEAL,ULT_FLAMESTRIKE,SKILL_IMPROVEDBM;

//skill 1
new Float:MaxRevivalChance[MAXPLAYERSCUSTOM]; //chance for first attempt at revival
new Float:CurrentRevivalChance[MAXPLAYERSCUSTOM]; //decays by half per revival attempt, will stay at minimum of 10% after decays
new reviveCount[MAXPLAYERSCUSTOM];
new Float:RevivalChancesArr[]={0.00,0.2,0.3,0.4,0.5};
new Float:flameStrikeRadius[5]={0.0,75.0,100.0,125.0,150.0}; //250.0,290.0,310.0,333.0 
new Float:flameStrikeRadiusDamage[5]={0.0,25.0,50.0,75.0,100.0}; //133.0,175.0,250.0,300.0
new RevivedBy[MAXPLAYERSCUSTOM];
new bool:bRevived[MAXPLAYERSCUSTOM];
new Float:fLastRevive[MAXPLAYERSCUSTOM];

// Team switch checker
new bool:Can_Player_Revive[MAXPLAYERSCUSTOM+1];
 
//skill 2
new Float:BanishChance[MAXPLAYERSCUSTOM];
new Float:BanishChancesArr[5]={0.00,0.05,0.10,0.15,0.20};

//for TF only:
new Float:CreditStealChanceTF[]={0.00,0.02,0.04,0.06,0.08};   //what are the chances of stealing
// instead of a percent we now base it on the attacker level
//new Float:TFCreditStealPercent=0.02;  //how much to steal
new improvedBMMultiplier[]={0,1,2,3,4};
//ultimate
new Float:ultCooldownCvar=20.0;
new Handle:hrevivalDelayCvar;

new Float:UltimateMaxDistance[]={0.0,750.0,750.0,750.0,750.0}; //max distance u can target your ultimate
new UltimateDamageDuration[]={0,4,6,8,10}; ///how many times damage is taken (like pyro's fire)

new BurnsRemaining[MAXPLAYERSCUSTOM]; //burn count for victims
new BeingBurnedBy[MAXPLAYERSCUSTOM];
new UltimateUsed[MAXPLAYERSCUSTOM];

new ULT_DAMAGE_TF = 10;

new String:reviveSound[]="war3source/reincarnation.mp3";

new BeamSprite,HaloSprite,FireSprite;
new BloodSpray,BloodDrop;

public Plugin:myinfo =
{
	name = "Race - Blood Mage",
	author = "PimpinJuice & Ownz (DarkEnergy)",
	description = "The Blood Mage race for War3Source.",
	version = "1.0.0.0",
	url = "http://Www.OwnageClan.Com"
};

public OnPluginStart()
{
	CreateConVar("war3evo_BloodLord",PLUGIN_VERSION,"War3evo Job Blood Lord",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	HookEvent("player_spawn",PlayerSpawnEvent);
	HookEvent("round_start",RoundStartEvent);
	// removed cooldown because its a common factor that should be changed in sourcecode.
	// no need to 'test run this during game play'.
	//ultCooldownCvar=CreateConVar("war3_mage_fire_strike_cooldown","20","Cooldown between fire strikes (ultimate)");
	hrevivalDelayCvar=CreateConVar("war3_bloodlord_revive_delay","2.0","Delay when reviving a teammate (since death)");
	
	HookEvent("player_death",PlayerDeathEvent);
	HookEvent("player_team",PlayerTeamEvent);
	
	LoadTranslations("w3s.race.bloodlord.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==40)
	{
		thisRaceID=War3_CreateNewRaceT("bloodlord");
		SKILL_REVIVE=War3_AddRaceSkillT(thisRaceID,"Phoenix",false,4,"20-50%","2-8%");
		SKILL_BANISH=War3_AddRaceSkillT(thisRaceID,"Banish",false,4,"20%","0.2");
		SKILL_MONEYSTEAL=War3_AddRaceSkillT(thisRaceID,"SiphonMana",false,4,"8%","gold","damage");
		SKILL_IMPROVEDBM=War3_AddRaceSkillT(thisRaceID,"ImprovedBM",false,4);
		ULT_FLAMESTRIKE=War3_AddRaceSkillT(thisRaceID,"FlameStrike",true,4,"10", "4-10", "500");
		War3_CreateRaceEnd(thisRaceID);
	}
	
}

public OnMapStart()
{
	{
		strcopy(reviveSound,sizeof(reviveSound),"war3source/reincarnation.mp3");
	}
	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	//we gonna use theese bloodsprite as "money blood"(change color)
	BloodSpray = PrecacheModel("sprites/bloodspray.vmt");
	BloodDrop = PrecacheModel("sprites/blood.vmt");
	FireSprite	 = PrecacheModel("materials/sprites/fireburst.vmt");

	War3_PrecacheSound(reviveSound);

	// Reset Can Player Revive
	for(new i=1;i<=MAXPLAYERSCUSTOM;i++)
	{
		Can_Player_Revive[i]=true;
	}
}


public OnWar3PlayerAuthed(client)
{
	fLastRevive[client]=0.0;
	Can_Player_Revive[client]=true;
}

public OnRaceChanged(client,oldrace,newrace)
{
	if( newrace!=thisRaceID)
	{
		new userid=GetClientUserId(client);
		for(new i=1;i<=MaxClients;i++)
		{
			if(ValidPlayer(i) && BurnsRemaining[i]>0)
			{
				if(BeingBurnedBy[i]==userid)
				{
					BurnsRemaining[i]=0;
					W3ResetPlayerColor(i,thisRaceID);
				}
			}
		}
	}
}
new FireEntityEffect[MAXPLAYERSCUSTOM];
new ultimateCaller=0;
public OnUltimateCommand(client,race,bool:pressed)
{
	new userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_FLAMESTRIKE);
		if(ult_level>0)
		{
			
			//if(War3_InFreezeTime())
			//{
			//	W3MsgNoCastDuringFreezetime(client);
			//}
			ultimateCaller=client;
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_FLAMESTRIKE,true))
			{   
				if (!(reviveCount[client] < 1)) {
					/////Flame Strike
					new Float:dist = UltimateMaxDistance[ult_level];
					if (reviveCount[client]) 
						dist=dist* reviveCount[client];
					new target = War3_GetTargetInViewCone(client,dist,false,23.0,IsBurningFilter);
					if(target>0)
					{
						++UltimateUsed[client];
						BeingBurnedBy[target]=GetClientUserId(client);
						BurnsRemaining[target]=UltimateDamageDuration[ult_level];
						CreateTimer(1.0,BurnLoop,GetClientUserId(target));
						War3_CooldownMGR(client,ultCooldownCvar,thisRaceID,ULT_FLAMESTRIKE,_,_);
						PrintHintText(target,"You have been struck with a devestating Flame Strike!");
						W3SetPlayerColor(target,thisRaceID,255,128,0,_,GLOW_ULTIMATE);
						new Float:effect_vec[3];
						GetClientAbsOrigin(target,effect_vec);
						new leftOver;
						if (reviveCount[client] > 5) {
							leftOver = reviveCount[client] - 5;
							reviveCount[client] = 5; // cap this bad boy at 5 - Dagothur 1/27/2013
						} 
						else 
						{
							leftOver = 0;
						}
						PrintHintText(client,"Flame Strike! %i blood consumed.",reviveCount[client]);
						War3_SuicideBomber(client, effect_vec, flameStrikeRadiusDamage[ult_level] * reviveCount[client], -1, flameStrikeRadius[ult_level] * reviveCount[client]);
						effect_vec[2]+=150.0;
						TE_SetupGlowSprite(effect_vec, FireSprite, 2.0, 4.0, 255);
						TE_SendToAll();
						effect_vec[2]-=180;
						ThrowAwayParticle("weapon_molotov_thrown_glow", effect_vec, 3.5);
						AttachParticle(target, "burning_character", effect_vec, "rfoot");
						effect_vec[2]+=180;
						
						reviveCount[client]=leftOver;
						new skill_level_revive=War3_GetSkillLevel(client,thisRaceID,SKILL_REVIVE);
						CurrentRevivalChance[client]=RevivalChancesArr[skill_level_revive];
						
					}
					else
					{
						W3MsgNoTargetFound(client,dist); 
						PrintHintText(client,"You have %i blood!",reviveCount[client]);
					}
				}
				else
				{
					PrintHintText(client,"You require more blood!");
				}
			}
			else
			{
				PrintHintText(client,"You have %i blood!",reviveCount[client]);
			}
			
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}
public bool:IsBurningFilter(client)
{
	if (W3HasImmunity(client,Immunity_Ultimates))
	{
		new String:clientName[64];
		GetClientName(client, clientName, sizeof(clientName));
		War3_ChatMessage(ultimateCaller,"%s is immune to your Flame Strike!", clientName);
	}
	return (BurnsRemaining[client]<=0 && !W3HasImmunity(client,Immunity_Ultimates));
}
public Action:BurnLoop(Handle:timer,any:userid)
{
	new victim=GetClientOfUserId(userid);
	new attacker=GetClientOfUserId(BeingBurnedBy[victim]);
	if(victim>0 && attacker>0 && BurnsRemaining[victim]>0 && IsClientInGame(victim) && IsClientInGame(attacker) && IsPlayerAlive(victim))
	{
		BurnsRemaining[victim]--;
		new damage = ULT_DAMAGE_TF;
		War3_DealDamage(victim,damage,attacker,DMG_BURN,"flamestrike",_,W3DMGTYPE_MAGIC);
		CreateTimer(1.0,BurnLoop,userid);
		W3FlashScreen(victim,RGBA_COLOR_ORANGE);
		if(BurnsRemaining[victim]<=0)
		{
			W3ResetPlayerColor(victim,thisRaceID);
			if (IsValidEdict(FireEntityEffect[victim]))
			{
				AcceptEntityInput(FireEntityEffect[victim], "Kill");
				FireEntityEffect[victim]=-1;
			}
		} 
	}
}


public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	
	if(race==thisRaceID)
	{
		if(newskilllevel>=0)
		{
			if(skill==SKILL_REVIVE) //1
			{
				MaxRevivalChance[client]=RevivalChancesArr[newskilllevel];
			}
			if(skill==SKILL_BANISH) //2
			{
				BanishChance[client]=BanishChancesArr[newskilllevel];
			}
		}
	}
}

public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&attacker!=victim&&GetClientTeam(attacker)!=GetClientTeam(victim))
	{
		if(War3_GetRace(attacker)==thisRaceID)
		{
			new Float:chance_mod=W3ChanceModifier(attacker);	
			if(IsPlayerAlive(attacker)&&IsPlayerAlive(victim))
			{
				if(!W3HasImmunity(victim,Immunity_Skills))
				{
					
					new skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_BANISH);
					if(skill_level>0)
					{
						new Float:tempFloat=GetRandomFloat(0.0,1.0);
						new Float:tempChance=BanishChancesArr[skill_level]*chance_mod;
						PrintToConsole(attacker,"(Banish) Dice: %f Chance: %f",tempFloat,tempChance);
						if(!Hexed(attacker,false)&&tempFloat<=tempChance)
						{
							if(W3HasImmunity(victim,Immunity_Skills))
							{
								W3MsgSkillBlocked(victim,attacker,"Banish");
							}
							else 
							{
								// TODO: Sound effects?
								//new Float:oldangle[3];
								//GetClientEyeAngles(victim,oldangle);
								//oldangle[0]+=GetRandomFloat(-20.0,20.0);
								//oldangle[1]+=GetRandomFloat(-20.0,20.0);
								//TeleportEntity(victim, NULL_VECTOR, oldangle, NULL_VECTOR);
								PrintHintText(victim, "You have been Banished!");
								
								new skill_level_revive=War3_GetSkillLevel(attacker,thisRaceID,SKILL_REVIVE);
								CurrentRevivalChance[attacker]=CurrentRevivalChance[attacker]*2;
								if (CurrentRevivalChance[attacker] > RevivalChancesArr[skill_level_revive] || CurrentRevivalChance[attacker] == RevivalChancesArr[skill_level_revive]) 
								{
									CurrentRevivalChance[attacker] = RevivalChancesArr[skill_level_revive];
									PrintHintText(attacker, "You Banished! Your Pheonix is at maximum power! +1 blood.");
									reviveCount[attacker]++;
								}
								else
								{
									PrintHintText(attacker, "You Banished! Your Pheonix grew stronger!");
								}
								W3FlashScreen(victim,{0,0,0,255},0.4,_,FFADE_STAYOUT);
								CreateTimer(0.2,Unbanish,GetClientUserId(victim));
								
								new Float:effect_vec[3];//
								GetClientAbsOrigin(attacker,effect_vec);
								new Float:effect_vec2[3];
								GetClientAbsOrigin(victim,effect_vec2);
								effect_vec[2]+=40;
								effect_vec2[2]+=40;
								TE_SetupBeamPoints(effect_vec,effect_vec2,BeamSprite,BeamSprite,0,50,1.0,30.0,10.0,0,12.0,{140,150,255,255},40);
								TE_SendToAll();
								effect_vec2[2]+=18;
								TE_SetupBeamPoints(effect_vec,effect_vec2,BeamSprite,BeamSprite,0,50,1.0,30.0,10.0,0,12.0,{140,150,255,255},40);
								TE_SendToAll();
							}
						}
					}
					skill_level=War3_GetSkillLevel(attacker,thisRaceID,SKILL_MONEYSTEAL);
					if(skill_level>0&&!Hexed(attacker,false))
					{
						if(GetRandomFloat(0.0,1.0) <= CreditStealChanceTF[skill_level]*chance_mod)
						{
							if(W3HasImmunity(victim,Immunity_Skills))
							{
								W3MsgSkillBlocked(victim,attacker,"Siphon Mana");
							}
							else
							{
								//new stolen=RoundFloat(float(War3_GetGold(victim))*TFCreditStealPercent);
								new stolen=War3_GetLevel(victim, War3_GetRace(victim));
								if(stolen>20)
								{
									stolen=20;
								}
								if(stolen<=0&&War3_GetGold(victim)>0)
								{
									stolen=1;
								}
								if(stolen>0) // no need to do anything otherwise
								{
									War3_SetGold(attacker,War3_GetGold(attacker)+stolen);
									War3_SetGold(victim,War3_GetGold(victim)-stolen);
									W3MsgStoleGold(victim,attacker,stolen);
									W3FlashScreen(attacker,RGBA_COLOR_BLUE);
									siphonsfx(victim);
								}
							}
						}
					}
				}
			}
		}
	}
}

stock siphonsfx(victim) {
	decl Float:vecAngles[3];
	GetClientEyeAngles(victim,vecAngles);
	decl Float:target_pos[3];
	GetClientAbsOrigin(victim,target_pos);
	target_pos[2]+=45;
	TE_SetupBloodSprite(target_pos, vecAngles, {250, 250, 28, 255}, 35, BloodSpray, BloodDrop);
	TE_SendToAll();
}

stock respawnsfx(target) {
	new Float:effect_vec[3];
	GetClientAbsOrigin(target,effect_vec);
	effect_vec[2]+=15.0;
	TE_SetupBeamRingPoint(effect_vec,60.0,1.0,BeamSprite,HaloSprite,0,15,1.5,8.0,1.0,{255,255,20,255},10,0);
	TE_SendToAll();
	effect_vec[2]+=15.0;
	TE_SetupBeamRingPoint(effect_vec,60.0,1.0,BeamSprite,HaloSprite,0,15,1.5,8.0,1.0,{255,255,20,255},10,0);
	TE_SendToAll();
	effect_vec[2]+=15.0;
	TE_SetupBeamRingPoint(effect_vec,60.0,1.0,BeamSprite,HaloSprite,0,15,1.5,8.0,1.0,{255,255,20,255},10,0);
	TE_SendToAll();
}

// Events
public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new client=GetClientOfUserId(userid);
	if(client>0)
	{
		
		UltimateUsed[client]=0;
		if(War3_GetRace(client)==thisRaceID)
		{
			new skill_level_revive=War3_GetSkillLevel(client,thisRaceID,SKILL_REVIVE);
			if(!bRevived[client]&&skill_level_revive)
			{
				CurrentRevivalChance[client]=RevivalChancesArr[skill_level_revive];
				reviveCount[client]++;
			}
		}
		bRevived[client]=false;
	}
	
}

public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	
	for(new i=1;i<=MaxClients;i++)
	{
		//Reset revival chance
		new skill_level_revive=War3_GetSkillLevel(i,thisRaceID,SKILL_REVIVE);
		if(ValidPlayer(i) && skill_level_revive)
		{
			CurrentRevivalChance[i]=RevivalChancesArr[skill_level_revive];
			reviveCount[i]=0;
		}
		//reset everyone's ultimate
		
	}
}

public Action:DoRevival(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);
	if(Can_Player_Revive[client]==false)
	{
		return Plugin_Handled;
	}
	//new client=GetClientOfUserId(userid);
	if(client>0)
	{
		new savior = RevivedBy[client];
		new skill_level2=War3_GetSkillLevel(savior,thisRaceID,SKILL_IMPROVEDBM);
		if(ValidPlayer(savior,true) && ValidPlayer(client))
		{
			if(GetClientTeam(savior)==GetClientTeam(client)&&!IsPlayerAlive(client))
			{
				//PrintToChatAll("omfg remove true");
				//SetEntityMoveType(client, MOVETYPE_NOCLIP);
				War3_SpawnPlayer(client);
				W3EmitSoundToAll(reviveSound,client);
				new gold=1 * improvedBMMultiplier[skill_level2];
				new xp = W3GetKillXP(savior) * improvedBMMultiplier[skill_level2];
				new heal=10*skill_level2;//
				
				new old_XP = War3_GetXP(savior,thisRaceID);
				new max=W3GetMaxGold();
				new old_credits=War3_GetGold(savior);
				new new_credits = old_credits + gold;
				if (new_credits > max)
					new_credits = max;
				War3_SetGold(savior,new_credits);
				War3_SetXP(savior,thisRaceID,old_XP+xp);

				//W3MsgRevivedBM(client,savior,gold,xp,heal,reviveCount[savior]);
				
				new String:clientName[64];
				GetClientName(client, clientName, sizeof(clientName));
				new String:saviorName[64];
				GetClientName(savior, saviorName, sizeof(saviorName));

				//PrintHintText(savior, "%T", "You revived {player}. +{gold} gold +{xp} xp.", savior, clientName, gold, xp);
				PrintHintText(savior, "You revived %s. +%i gold +%i xp.\nYou have %i blood. Your Pheonix weakens.", clientName, gold, xp, reviveCount[savior]);
				War3_ChatMessage(client,"%s revived you. +%i HP bonus.", saviorName, heal);
	
				new Float:VecPos[3];
				new Float:Angles[3];
				//War3_CachedAngle(client,Angles);
				//War3_CachedPosition(client,VecPos);
				
				GetClientAbsOrigin(savior,VecPos);
				GetClientEyeAngles(savior,Angles);
				
				
				
				War3_HealToBuffHP(client,heal);
				
				TeleportEntity(client, VecPos, Angles, NULL_VECTOR);

				testhull(client);
				
				
				fLastRevive[client]=GetGameTime();
				//test noclip method
				
				//SetEntityMoveType(client, MOVETYPE_WALK);
				
			}
			else
			{
				//this guy changed team?
				CurrentRevivalChance[savior]*=2.0;
				reviveCount[savior]--;
				RevivedBy[client]=0;
				bRevived[client]=false; 
			}
		}
		else
		{
			// savior left or something? maybe dead?
			RevivedBy[client]=0;
			bRevived[client]=false; 
		}

	}
	return Plugin_Continue;
}

bool:CooldownRevive(client)
{
	if(GetGameTime() >= (fLastRevive[client]+20.0))
		return true;
	return false;
}

public PlayerTeamEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
// Team Switch checker
	new userid=GetEventInt(event,"userid");
	new client=GetClientOfUserId(userid);
	// For testing purposes:
	//new String:clientname[64];
	//GetClientName(client, clientname, sizeof(clientname));
	//DP("Player %s Switched Teams (Can not be revived for 15 seconds)",clientname);
	Can_Player_Revive[client]=false;
	CreateTimer(30.0,PlayerCanRevive,userid);
}

public Action:PlayerCanRevive(Handle:timer,any:userid)
{
// Team Switch checker
	new client=GetClientOfUserId(userid);
	// For testing purposes:
	//new String:clientname[64];
	//GetClientName(client, clientname, sizeof(clientname));
	//DP("Player %s can be revived by bloodmages",clientname);
	Can_Player_Revive[client]=true;
}

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new userid=GetEventInt(event,"userid");
	new victim=GetClientOfUserId(userid);
	if(victim>0)
	{
		BurnsRemaining[victim]=0;
		W3ResetPlayerColor(victim,thisRaceID);
		new victimTeam = GetClientTeam(victim);
		new skillevel;
		
		if (IsValidEdict(FireEntityEffect[victim]))
		{
			AcceptEntityInput(FireEntityEffect[victim], "TurnOff");
			FireEntityEffect[victim]=-1;
		}
		
		new deathFlags = GetEventInt(event, "death_flags");
		
		if (deathFlags & 32)
		{
			//PrintToChat(client,"war3 debug: dead ringer kill");
		}
		else
		{
			
			//
			
			//TEST!! remove!!
			//DP("Auto revival  Remove this line CreateTimer(0.1,DoRevival,victim);");
			//CreateTimer(0.1,DoRevival,victim);
			//RevivedBy[victim]=GetClientOfUserId(userid);
			//PrintToChatAll("blood mage");
			
			//find a revival

			// Can_Player_Revive is the team switch checking variable
			if(CooldownRevive(victim)&&Can_Player_Revive[victim]) {
			//if(Can_Player_Revive[victim]) {
				for(new i=1;i<=MaxClients;i++)
				{
					if(i!=victim&&ValidPlayer(i,true)&&GetClientTeam(i)==victimTeam&&War3_GetRace(i)==thisRaceID)
					{
						skillevel=War3_GetSkillLevel(i,thisRaceID,SKILL_REVIVE);
						if(skillevel>0&&!Hexed(i,false))
						{
							new Float:tempRandom=GetRandomFloat(0.0,1.0);
							PrintToConsole(i,"(Revive) Dice: %f Chance: %f",tempRandom,CurrentRevivalChance[i]);
							if(tempRandom<=CurrentRevivalChance[i])
							{
								
								reviveCount[i]++;
								CurrentRevivalChance[i]/=2.0;
								if(CurrentRevivalChance[i]<0.020*(skillevel*1.000) || CurrentRevivalChance[i]==0.020*(skillevel*1.000)){
									CurrentRevivalChance[i]=0.020*(skillevel*1.000);
									PrintHintText(i, "Your Pheonix is at minimum power!");
								}
								RevivedBy[victim]=i;
								bRevived[victim]=true;
								CreateTimer(GetConVarFloat(hrevivalDelayCvar),DoRevival,GetClientUserId(victim));
								break;
							}
						}
					}
				}
			}
		}
	}
}



public Action:Unbanish(Handle:timer,any:userid)
{
	// never EVER use client in a timer. userid is safe
	new client=GetClientOfUserId(userid);
	if(client>0)
	{
		W3FlashScreen(client,{0,0,0,0},0.1,_,(FFADE_IN|FFADE_PURGE));
	}
}

new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25,27,-27,30,-30};//,33,-33,40,-40};

public bool:testhull(client){
	
	//PrintToChatAll("BEG");
	new Float:mins[3];
	new Float:maxs[3];
	GetClientMins(client,mins);
	GetClientMaxs(client,maxs);
	
	//PrintToChatAll("min : %.1f %.1f %.1f MAX %.1f %.1f %.1f",mins[0],mins[1],mins[2],maxs[0],maxs[1],maxs[2]);
	new absincarraysize=sizeof(absincarray);
	new Float:originalpos[3];
	GetClientAbsOrigin(client,originalpos);
	
	new limit=5000;
	for(new x=0;x<absincarraysize;x++){
		if(limit>0){
			for(new y=0;y<=x;y++){
				if(limit>0){
					for(new z=0;z<=y;z++){
						new Float:pos[3]={0.0,0.0,0.0};
						AddVectors(pos,originalpos,pos);
						pos[0]+=float(absincarray[x]);
						pos[1]+=float(absincarray[y]);
						pos[2]+=float(absincarray[z]);
						
						//PrintToChatAll("hull at %.1f %.1f %.1f",pos[0],pos[1],pos[2]);
						//PrintToServer("hull at %d %d %d",absincarray[x],absincarray[y],absincarray[z]);
						TR_TraceHullFilter(pos,pos,mins,maxs,CONTENTS_SOLID|CONTENTS_MOVEABLE,CanHitThis,client);
						//new ent;
						if(TR_DidHit(_))
						{
							//PrintToChatAll("2");
							//ent=TR_GetEntityIndex(_);
							//PrintToChatAll("hit %d self: %d",ent,client);
						}
						else{
							TeleportEntity(client,pos,NULL_VECTOR,NULL_VECTOR);
							limit=-1;
							break;
						}
					
						if(limit--<0){
							break;
						}
					}
					
					if(limit--<0){
						break;
					}
				}
			}
			
			if(limit--<0){
				break;
			}
			
		}
		
	}
	//PrintToChatAll("END");
}

public bool:CanHitThis(entityhit, mask, any:data)
{
	if(entityhit == data )
	{// Check if the TraceRay hit the itself.
		return false; // Don't allow self to be hit, skip this result
	}
	if(ValidPlayer(entityhit)&&ValidPlayer(data)&&GetClientTeam(entityhit)==GetClientTeam(data)){
		return false; //skip result, prend this space is not taken cuz they on same team
	}
	return true; // It didn't hit itself
}

