/**
* File: War3Source_NightElf.sp
* Description: The Night Elf race for War3Source.
* Author(s): Anthony Iacono 
*/
 
#pragma semicolon 1
 
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
public W3ONLY(){} //unload this?
new thisRaceID;

new bool:bIsEntangled[MAXPLAYERSCUSTOM];


new Handle:EntangleCooldownCvar; // cooldown

//new Handle:hWeaponDrop;


new SKILL_EVADE, SKILL_THORNS, SKILL_TRUESHOT, ULT_ENTANGLE;

// Chance/Data Arrays
//new Float:EvadeChance[5]={0.0,0.05,0.07,0.13,0.15};
new Float:EvadeChance[5]={0.0,0.04,0.06,0.08,0.10};
new Float:ThornsReturnDamage[5]={0.0,0.05,0.10,0.15,0.20};
new Float:TrueshotDamagePercent[5]={0.0,0.05,0.10,0.15,0.20};
new Float:EntangleDistance=600.0;
new Float:EntangleDuration[5]={0.0,1.25,1.5,1.75,2.0};

new String:entangleSound[]="war3source/entanglingrootsdecay1.mp3";
//new String:entangleSound[256]; //="war3source/entanglingrootsdecay1.mp3";

// Effects
new TeleBeam,BeamSprite,HaloSprite;
 
public Plugin:myinfo = 
{
	name = "Race - Night Elf",
	author = "PimpinJuice",
	description = "The Night Elf race for War3Source.",
	version = "1.0.0.0",
	url = "http://pimpinjuice.net/"
};

public OnPluginStart()
{
	

	EntangleCooldownCvar=CreateConVar("war3_nightelf_entangle_cooldown","20","Cooldown timer.");
	
	LoadTranslations("w3s.race.nightelf.phrases");
	
}


public OnMapStart()
{
	strcopy(entangleSound,sizeof(entangleSound),"war3source/entanglingrootsdecay1.mp3");
	TeleBeam=PrecacheModel("materials/sprites/tp_beam001.vmt");

	BeamSprite=War3_PrecacheBeamSprite();
	HaloSprite=War3_PrecacheHaloSprite();
	
	War3_PrecacheSound(entangleSound);
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==40)
	{
		thisRaceID=War3_CreateNewRaceT("nightelf");
		//SKILL_EVADE=War3_UseGenericSkill(thisRaceID,"Evasion");//War3_AddRaceSkillT(thisRaceID,"Evasion",false,4);
		//new Handle:evasiondata=CreateArray(5,1);
		//SetArrayArray(evasiondata,0,EvadeChance,sizeof(EvadeChance));
		//SKILL_EVADE=War3_UseGenericSkill(thisRaceID,"g_evasion",evasiondata,"Evasion",_,true,_,_);
		SKILL_EVADE=War3_AddRaceSkillT(thisRaceID,"Evasion",false,4);
		SKILL_THORNS=War3_AddRaceSkillT(thisRaceID,"ThornsAura",false,4);
		SKILL_TRUESHOT=War3_AddRaceSkillT(thisRaceID,"TrueshotAura",false,4);
		ULT_ENTANGLE=War3_AddRaceSkillT(thisRaceID,"EntanglingRoots",true,4); //TEST
		War3_CreateRaceEnd(thisRaceID);
		W3Faction(thisRaceID,"Elves",true);
	}
}



public DropWeapon(client,weapon)
{
//	new Float:angle[3];
//	GetClientEyeAngles(client,angle);
//	new Float:dir[3];
//	GetAngleVectors(angle,dir,NULL_VECTOR,NULL_VECTOR);
//	ScaleVector(dir,20.0);
//	SDKCall(hWeaponDrop,client,weapon,NULL_VECTOR,dir);
}


new ClientTracer;

public bool:AimTargetFilter(entity,mask)
{
	return !(entity==ClientTracer);
}

public bool:ImmunityCheck(client)
{
	if(bIsEntangled[client]||W3HasImmunity(client,Immunity_Ultimates))
	{
		return false;
	}
	return true;
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && IsPlayerAlive(client) && pressed)
	{
		new skill_level=War3_GetSkillLevel(client,race,ULT_ENTANGLE);
		// Spys should be visible to use this ultimate
		if(skill_level>0)
		{
			if(!Spying(client))
			{

				if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_ENTANGLE,true))
				{
				
					new Float:distance=EntangleDistance;
					new target; // easy support for both

					new Float:our_pos[3];
					GetClientAbsOrigin(client,our_pos);
			
					target=War3_GetTargetInViewCone(client,distance,false,23.0,ImmunityCheck);
					if(ValidPlayer(target,true))
					{
				
						bIsEntangled[target]=true;
				
						War3_SetBuff(target,bNoMoveMode,thisRaceID,true);
						new Float:entangle_time=EntangleDuration[skill_level];
						CreateTimer(entangle_time,StopEntangle,target);
						new Float:effect_vec[3];
						GetClientAbsOrigin(target,effect_vec);
						effect_vec[2]+=15.0;
						TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
						TE_SendToAll();
						effect_vec[2]+=15.0;
						TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
						TE_SendToAll();
						effect_vec[2]+=15.0;
						TE_SetupBeamRingPoint(effect_vec,45.0,44.0,BeamSprite,HaloSprite,0,15,entangle_time,5.0,0.0,{0,255,0,255},10,0);
						TE_SendToAll();
						our_pos[2]+=25.0;
						TE_SetupBeamPoints(our_pos,effect_vec,BeamSprite,HaloSprite,0,50,4.0,6.0,25.0,0,12.0,{80,255,90,255},40);
						TE_SendToAll();
						new String:name[64];
						GetClientName(target,name,64);
						//War3_ChatMessage(target,"You have been entangled");//%s!")//,(War3_GetGame()==Game_TF)?", your weapons are POWERLESS until you are released":"");
						W3EmitSoundToAll(entangleSound,target);
						W3EmitSoundToAll(entangleSound,target);
					
						W3MsgEntangle(target,client);
				
					
						War3_CooldownMGR(client,GetConVarFloat(EntangleCooldownCvar),thisRaceID,ULT_ENTANGLE,_,_);
					}
					else
					{
						W3MsgNoTargetFound(client,distance);
					}
				}
			}
			else
			{
				PrintHintText(client,"You must not be disguised/cloaked!");
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

public Action:StopEntangle(Handle:timer,any:client)
{

	bIsEntangled[client]=false;
	War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
	
}

public OnWar3EventSpawn(client)
{	
	if(bIsEntangled[client])
	{
		bIsEntangled[client]=false;
		War3_SetBuff(client,bNoMoveMode,thisRaceID,false);
	}
}



public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			new race_attacker=War3_GetRace(attacker);
			new race_victim=War3_GetRace(victim);
			//new skill_level_thorns=War3_GetSkillLevel(victim,thisRaceID,SKILL_THORNS);
			new skill_level_trueshot=War3_GetSkillLevel(attacker,thisRaceID,SKILL_TRUESHOT);
		
			
			//evade
			//if they are not this race thats fine, later check for race
			if(race_victim==thisRaceID ) 
			{
				new skill_level_evasion=War3_GetSkillLevel(victim,thisRaceID,SKILL_EVADE);
				if( skill_level_evasion>0 &&!Hexed(victim,false) && GetRandomFloat(0.0,1.0)<=EvadeChance[skill_level_evasion] && !W3HasImmunity(attacker,Immunity_Skills))
				{
					
					W3FlashScreen(victim,RGBA_COLOR_BLUE);
					
					War3_DamageModPercent(0.0); //NO DAMAMGE
					
					W3MsgEvaded(victim,attacker);
					if(War3_GetGame()==Game_TF){
						decl Float:pos[3];
						GetClientEyePosition(victim, pos);
						pos[2] += 4.0;
						War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
					}
						
				}
				
			/*	//thorns only if he didnt evade
				else if( skill_level_thorns>0 && IsPlayerAlive(attacker)&&!Hexed(victim,false))
				{                                                                                
					if(!W3HasImmunity(attacker,Immunity_Skills))
					{
					
						new damage_i=RoundToFloor(damage*ThornsReturnDamage[skill_level_thorns]);
						if(damage_i>0)
						{
							if(damage_i>40) damage_i=40; // lets not be too unfair ;]
							
							//PrintToChatAll("1 %d",W3GetDamageIsBullet());
							War3_DealDamage(attacker,damage_i,victim,_,"thorns",_,W3DMGTYPE_PHYSICAL);
						//	PrintToChatAll("2 %d",W3GetDamageIsBullet());
							//W3ForceDamageIsBullet();
							
							W3PrintSkillDmgConsole(attacker,victim,War3_GetWar3DamageDealt(),SKILL_THORNS);	
						}
						//}
					}
				}*/
			}
			
			// Trueshot Aura
			if(race_attacker==thisRaceID && skill_level_trueshot>0 && IsPlayerAlive(attacker)&&!Hexed(attacker,false))
			{
				if(!W3HasImmunity(victim,Immunity_Skills))
				{		
					War3_DamageModPercent(TrueshotDamagePercent[skill_level_trueshot]+1.0);			
					W3FlashScreen(victim,RGBA_COLOR_RED);

				}
			}
		}
	}
}
//public OnWar3EventPostHurt(victim,attacker,damage){
public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
	if(W3GetDamageIsBullet()&&ValidPlayer(victim,true)&&ValidPlayer(attacker,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		
		if(War3_GetRace(victim)==thisRaceID)
		{
			new skill_level=War3_GetSkillLevel(victim,thisRaceID,SKILL_THORNS);
			if(skill_level>0&&!Hexed(victim,false))
			{
				if(!W3HasImmunity(attacker,Immunity_Skills))
				{
					new damage_i=RoundToFloor(damage*ThornsReturnDamage[skill_level]);
					if(damage_i>0)
					{
						if(damage_i>40) damage_i=40; // lets not be too unfair ;]
						
						if(War3_DealDamage(attacker,damage_i,victim,_,"thorns",_,W3DMGTYPE_PHYSICAL))
						{
							decl Float:iVec[3];
							decl Float:iVec2[3];
							GetClientAbsOrigin(attacker, iVec);
							GetClientAbsOrigin(victim, iVec2);
							iVec[2]+=35.0, iVec2[2]+=40.0;
							TE_SetupBeamPoints(iVec, iVec2, TeleBeam, TeleBeam, 0, 45, 0.4, 10.0, 10.0, 0, 0.5, {255,35,15,255}, 30);
							TE_SendToAll();
							iVec2[0]=iVec[0];
							iVec2[1]=iVec[1];
							iVec2[2]=80+iVec[2];
							TE_SetupBubbles(iVec, iVec2, HaloSprite, 35.0,GetRandomInt(6,8),8.0);
							TE_SendToAll();
						}
					}
				}
			}
		}
	}
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