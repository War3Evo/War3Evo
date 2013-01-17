#define PLUGIN_VERSION "0.0.0.1"
/* ========================================================================== */
/*                                                                            */
/*   War3source_001_Vanilla.sp                                              */
/*   (c) 2012 El Diablo                                                       */
/*                                                                            */
/*   Description  A Race for developers whom want to test vanilla             */
/*                players (players without any modifications) vs              */
/*                what ever race they wish to go against.                     */
/* ========================================================================== */
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/sdkhooks"
public W3ONLY(){} //unload this?

// War3Source stuff
new thisRaceID;

new ULT_MULTIPLEROCKET, ABILITY_HEATSEEKING,STABILIZERS_SKILL,T_SKILL,T_SKILL2;
//, SKILL_UNHOLY, ABILITY_FAN, ULT_SOULSWAP;


// heat seeker
new HeatSeeker_Target[66];
new HeatSeeker_Target_Rocket[66];
new bool:HeatSeeker_Target_Multiple[66];
new bool:shoot[66];
new Float:HeatSeeker_MaxDistance[5]={0.00,700.0,1400.0,2800.0,5600.0};
new Float:ult_cooldowntime = 20.0; //20.0

new String:Client_Current_Weapon[66][64];

// multiple rocket
new Amount_Of_Additional_Rockets[5]={0,3,4,5,6};
new Float:Rocket_Multiple_Damge[5]={0.0,0.70,0.80,0.90,1.00};
new Float:Rocket_Mutiple_Random[5]={0.0,7.0,6.0,5.0,4.0};
new Float:shake_duration[5]={5.0,4.0,3.0,2.0,1.0};
new Float:shake_magnitude[5]={50.0,40.0,30.0,20.0,10.0};
new Float:shake_noise[5]={50.0,40.0,30.0,20.0,10.0};

//T_SKILL
new Float:t_skill_walk_speed[5]={1.0,1.01,1.02,1.03,1.04};
new Float:t_skill_magic_armor[5]={0.0,0.2,0.3,0.4,0.5};

new String:rocketsound[]="items/cart_explode.wav";
//new String:rocketticking[]="mvm/sentrybuster/mvm_sentrybuster_loop.wav";

new Handle:HEATROCKET_CONVAR;
new Handle:HEATROCKET_DAM_CONVAR;

public Plugin:myinfo =
{
	name = "Job - Heat Seeker",
	author = "El Diablo",
	description = "A Race with heat seeking rockets.",
	version = "1.0.0.0",
	url = "http://www.war3evo.com"
};
public OnPluginStart()
{
	CreateConVar("war3evo_HeatSeeker",PLUGIN_VERSION,"War3evo Job Heat Seeker",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	// To do: add translations
	//LoadTranslations("w3s.race.mage.phrases");
	HEATROCKET_CONVAR = CreateConVar("hs_rocketspeed", "1100.0", "0.0 - 1100.0");
	HEATROCKET_DAM_CONVAR  = CreateConVar("hs_damage", "300.0", "0.0 - 1100.0");

	War3_PrecacheSound(rocketsound);
	//War3_PrecacheSound(rocketticking);

	//CreateTimer(1.0,rocket_ticking,_,TIMER_REPEAT);
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==101)       //Incinerator Bomb
	{
		thisRaceID=War3_CreateNewRace("Heat Seeker","heatseeker");
		ABILITY_HEATSEEKING=War3_AddRaceSkill(thisRaceID,"Homing Rocket",
		"Locks your rockets on a single player.\nMay run into walls and other things.\n(+ability2)",false,4);
		STABILIZERS_SKILL=War3_AddRaceSkill(thisRaceID,"Stabilizers",
		"Reduces feedback from shooting multiple rockets.",false,4);
		T_SKILL=War3_AddRaceSkill(thisRaceID,"Temporary Skill 1",
		"increase walk speed just a little bit",false,4);
		T_SKILL2=War3_AddRaceSkill(thisRaceID,"Temporary Skill 2",
		"increases magical armor just a little bit",false,4);
		ULT_MULTIPLEROCKET=War3_AddRaceSkill(thisRaceID," Missile Barrage",
		"Shoots multiple rockets. 3/4/5/6 additional rockets.\nMay not work with some rocket lauchers.\n(+ultimate)",true,4);
		//ABILITY_FAN=War3_AddRaceSkill(thisRaceID,"No Skill 3",
		//"No skill info 3",false,1);
		//ABILITY_BLIND=War3_AddRaceSkill(thisRaceID,"No Skill 4",
		//"No Skill info 4",false,1);
		//ULT_SOULSWAP=War3_AddRaceSkill(thisRaceID,"No Ultimate",
		//"No Ultimate info",true,1);
		//W3SkillCooldownOnSpawn(thisRaceID,ULT_SOULSWAP,10.0,_);
		//W3SkillCooldownOnSpawn(thisRaceID,ABILITY_BLIND,10.0,_);
		W3SkillCooldownOnSpawn(thisRaceID,ULT_MULTIPLEROCKET,20.0,_);
		//W3SkillCooldownOnSpawn(thisRaceID,ABILITY_MULTIPLEROCKET,10.0,_);
		War3_CreateRaceEnd(thisRaceID);
		//thisAuraID=W3RegisterAura("UnholyAura",UnholyRange,true);
		War3_SetDependency(thisRaceID, STABILIZERS_SKILL, ULT_MULTIPLEROCKET, 1);
	}

}

public OnMapStart()
{
//
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
		new skill_level=War3_GetSkillLevel(client,thisRaceID,T_SKILL);
		if(skill_level>0)
		{
			War3_SetBuff(client,fSlow,thisRaceID,1.0);
			War3_SetBuff(client,fMaxSpeed,thisRaceID,t_skill_walk_speed[skill_level]);
		}
		skill_level=War3_GetSkillLevel(client,thisRaceID,T_SKILL2);
		if(skill_level>0)
		{
			War3_SetBuff(client,fArmorMagic,thisRaceID,t_skill_magic_armor[skill_level]);
		}
	}
}

/* ****************************** RemovePassiveSkills ************************** */

public RemovePassiveSkills(client)
{
	// nothing
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	War3_SetBuff(client,fArmorMagic,thisRaceID,0.0);
}


public OnGameFrame()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(War3_GetRace(i)==thisRaceID)
		{
			//SetHomingProjectile(i, "tf_projectile_arrow");
			//SetHomingProjectile(i, "tf_projectile_energy_ball");
			//SetHomingProjectile(i, "tf_projectile_flare");
			//SetHomingProjectile(i, "tf_projectile_healing_bolt");
			SetHomingProjectile(i, "tf_projectile_rocket");
			//SetHomingProjectile(i, "tf_projectile_sentryrocket");
			//SetHomingProjectile(i, "tf_projectile_syringe");
		}
	}
}

SetHomingProjectile(client, const String:classname[])
{
	if(!IsValidEntity(HeatSeeker_Target_Rocket[client])&&HeatSeeker_Target[client]>0)
	{
		//StopSoundPerm(HeatSeeker_Target_Rocket[client],rocketticking);
		HeatSeeker_Target_Rocket[client]=0;
		HeatSeeker_Target[client]=0;
	}
	new entity = -1;
	while((entity = FindEntityByClassname(entity, classname))!=INVALID_ENT_REFERENCE)
	{
		new owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
		if(!IsValidEntity(owner)) continue;
		//if(StrEqual(classname, "tf_projectile_sentryrocket", false)) owner = GetEntPropEnt(owner, Prop_Send, "m_hBuilder");
		//new Target = GetClosestTarget(entity, owner);
		new Target = HeatSeeker_Target[client];
		if(!Target) continue;
		if(owner == client)
		{
			HeatSeeker_Target_Rocket[client]=entity;
			new Float:ProjLocation[3], Float:ProjVector[3], Float:ProjSpeed, Float:ProjAngle[3], Float:TargetLocation[3], Float:AimVector[3];
			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", ProjLocation);
			GetClientAbsOrigin(Target, TargetLocation);
			TargetLocation[2] += 40.0;
			MakeVectorFromPoints(ProjLocation, TargetLocation , AimVector);
			GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector);
			ProjSpeed = GetVectorLength(ProjVector);
			AddVectors(ProjVector, AimVector, ProjVector);
			NormalizeVector(ProjVector, ProjVector);
			GetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
			GetVectorAngles(ProjVector, ProjAngle);
			SetEntPropVector(entity, Prop_Data, "m_angRotation", ProjAngle);
			ScaleVector(ProjVector, ProjSpeed);
			SetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", ProjVector);
		}
	}
}
/*
public Action:rocket_ticking(Handle:timer, any:args)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(HeatSeeker_Target[i]>0 && HeatSeeker_Target_Rocket[i]>0)
		{
			EmitSoundToAll(rocketticking,HeatSeeker_Target_Rocket[i]);
		}
	}
}
*/

/**
 * @brief When an entity is destroyed
 *
 * @param		entity		Entity index
 * @noreturn
 */
/*
public OnEntityDestroyed(entity)
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(entity==HeatSeeker_Target_Rocket[i])
			StopSound(HeatSeeker_Target[i],SNDCHAN_AUTO,rocketticking);
	}
}
*/

/*
GetClosestTarget(entity, owner)
{
	new Float:TargetDistance = 0.0;
	new ClosestTarget = 0;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(!IsClientConnected(i) || !IsPlayerAlive(i) || i == owner || (GetClientTeam(owner) == GetClientTeam(i))) continue;
		new Float:EntityLocation[3], Float:TargetLocation[3];
		GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", EntityLocation);
		GetClientAbsOrigin(i, TargetLocation);

		new Float:distance = GetVectorDistance(EntityLocation, TargetLocation);
		if(TargetDistance)
		{
			if(distance < TargetDistance)
			{
				ClosestTarget = i;
				TargetDistance = distance;
			}
		}
		else
		{
			ClosestTarget = i;
			TargetDistance = distance;
		}
	}
	return ClosestTarget;
}

 ***************************  ability *************************************/

public OnAbilityCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && ability==2 && pressed && ValidPlayer(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,ABILITY_HEATSEEKING);
		if(skill_level>0&&War3_SkillNotInCooldown(client,thisRaceID,ABILITY_HEATSEEKING,true))
		{
			HeatSeeker_Target[client]= War3_GetTargetInViewCone(client,HeatSeeker_MaxDistance[skill_level],false,23.0);
			if(!Silenced(client)&&ValidPlayer(HeatSeeker_Target[client]))
			{
				new String:player_name[64];
				GetClientName(HeatSeeker_Target[client],player_name,64);
				if(!War3_IsUbered(HeatSeeker_Target[client]) && !W3HasImmunity(HeatSeeker_Target[client],Immunity_Skills))
				{
					PrintHintText(client, "Homing Rocket Locked on Target [%s]!",player_name);
					PrintHintText(HeatSeeker_Target[client], "RUN! Your a target of a Heat Seeking Rocket!\nBuy Shield to protect yourself next time.");
					//FakeClientCommand(client,"slot1");
					//FakeClientCommand(client,"+attack");
					//shoot[client]=true;
					//War3_CooldownMGR(client,HeatSeeker_cooldowntime,thisRaceID,ABILITY_MULTIPLEROCKET,_,_);
					//War3_CooldownMGR(client,HeatSeeker_cooldowntime,thisRaceID,ABILITY_HEATSEEKING,_,_);
				}
				else
				{
					PrintHintText(client, "Target [%s] is Immune!",player_name);
					HeatSeeker_Target[client]=0;
				}
			}
		}
	}
}

public OnUltimateCommand(client,race,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && pressed && ValidPlayer(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,ULT_MULTIPLEROCKET);
		if(War3_SkillNotInCooldown(client,thisRaceID,ULT_MULTIPLEROCKET,true))  // multiple rocket shares cooldown with heatseeking
		{
			//new target = War3_GetTargetInViewCone(client,HeatSeeker_MaxDistance[skill_level],false,90.0);
			HeatSeeker_Target[client]=0;
			//if(ValidPlayer(target)&&skill_level>0&&!Silenced(client))
			if(skill_level>0&&!Silenced(client))
			{
				//new String:player_name[64];
				//GetClientName(target,player_name,64);
				//if(!War3_IsUbered(target) && !W3HasImmunity(target,Immunity_Skills))
				//{
				HeatSeeker_Target_Multiple[client]=true;
				//PrintHintText(client, "MultiRocket Found Target [%s]!",player_name);
				//PrintHintText(target, "RUN! Your a target of Multiple Rockets!");
				//FakeClientCommand(client,"slot1");
				shoot[client]=true;
				//FakeClientCommand(client,"+attack");
				War3_CooldownMGR(client,ult_cooldowntime,thisRaceID,ULT_MULTIPLEROCKET,_,_);
				//}
				//else
				//{
				//	PrintHintText(client, "Target [%s] is Immune!",player_name);
				//}
			}
			else
			{
				PrintHintText(client, "Either your skill isn't high enough\nor your silenced!");
			}
		}
		else
		{
			PrintHintText(client, "MultiRocket (+ulitmate) Skill is on cooldown!");
		}
	}
}


public OnWar3EventDeath(victim,attacker)
{
	if(HeatSeeker_Target[attacker]==victim)
	{
		HeatSeeker_Target[attacker]=0;
		HeatSeeker_Target_Rocket[attacker]=-1;
		//HeatSeeker_Target_Multiple=false;
	}
}

/*
//Stop Sound from all Channels:
StopSoundPerm(thing, String:sound[])
{
//Stop Sound:
	StopSound(thing, SNDCHAN_AUTO, sound);
	StopSound(thing, SNDCHAN_WEAPON, sound);
	StopSound(thing, SNDCHAN_VOICE, sound);
	StopSound(thing, SNDCHAN_ITEM, sound);
	StopSound(thing, SNDCHAN_BODY, sound);
	StopSound(thing, SNDCHAN_STREAM, sound);
	StopSound(thing, SNDCHAN_VOICE_BASE, sound);
	StopSound(thing, SNDCHAN_USER_BASE, sound);
}
*/

public Action:TF2_CalcIsAttackCritical(client, weapon, String:weaponname[], &bool:result)
{
	if (ValidPlayer(client,true))
	{
		if (HeatSeeker_Target_Multiple[client]==true)
		{                  // 	tf_weapon_rocketlauncher_directhit
			if (StrEqual(weaponname, "tf_weapon_rocketlauncher", false) == true || StrEqual(weaponname, "tf_weapon_rocketlauncher_directhit", false) == true)
			{
				HeatSeeker_Target_Multiple[client]=false;

				new Float:vAngles[3]; // pass
				new Float:vAngles2[3]; // original
				new Float:vPosition[3]; // pass
				new Float:vPosition2[3]; // original
				new skill_level=War3_GetSkillLevel(client,thisRaceID,ULT_MULTIPLEROCKET);
				new Amount = Amount_Of_Additional_Rockets[skill_level];
				new ClientTeam = GetClientTeam(client);
				new Float:Random = Rocket_Mutiple_Random[skill_level];
				new Float:DamageMul = Rocket_Multiple_Damge[skill_level];

				GetClientEyeAngles(client, vAngles2);
				GetClientEyePosition(client, vPosition2);

				vPosition[0] = vPosition2[0];
				vPosition[1] = vPosition2[1];
				vPosition[2] = vPosition2[2];

				new Float:Random2 = Random*-1;
				new counter = 0;
				for (new i = 0; i < Amount; i++)
				{
					vAngles[0] = vAngles2[0] + GetRandomFloat(Random2,Random);
					vAngles[1] = vAngles2[1] + GetRandomFloat(Random2,Random);
					// avoid unwanted collision
					new i2 = i%4;
					switch(i2)
					{
						case 0:
						{
							counter++;
							vPosition[0] = vPosition2[0] + counter;
						}
						case 1:
						{
							vPosition[1] = vPosition2[1] + counter;
						}
						case 2:
						{
							vPosition[0] = vPosition2[0] - counter;
						}
						case 3:
						{
							vPosition[1] = vPosition2[1] - counter;
						}
					}
					fireProjectile(vPosition, vAngles, GetConVarFloat(HEATROCKET_CONVAR), GetConVarFloat(HEATROCKET_DAM_CONVAR)*DamageMul, ClientTeam, client);
				}
			}
		}
	}
	return Plugin_Continue;
}


fireProjectile(Float:vPosition[3], Float:vAngles[3] = NULL_VECTOR, Float:flSpeed = 500.0, Float:flDamage = 90.0, iTeam, client)
{
	new String:strClassname[32] = "";
	new String:strEntname[32] = "";

	strClassname = "CTFProjectile_Rocket";
	strEntname = "tf_projectile_rocket";

	new iRocket = CreateEntityByName(strEntname);

	if(!IsValidEntity(iRocket))
		return -1;

	decl Float:vVelocity[3];
	decl Float:vBuffer[3];

	GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);

	vVelocity[0] = vBuffer[0]*flSpeed;
	vVelocity[1] = vBuffer[1]*flSpeed;
	vVelocity[2] = vBuffer[2]*flSpeed;

	SetEntPropEnt(iRocket, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(iRocket,    Prop_Send, "m_bCritical", (GetRandomInt(0, 100) <= 5)? 1 : 0, 1);
	SetEntProp(iRocket,    Prop_Send, "m_iTeamNum",     iTeam, 1);
	SetEntData(iRocket, FindSendPropOffs(strClassname, "m_nSkin"), (iTeam-2), 1, true);

	SetEntDataFloat(iRocket, FindSendPropOffs(strClassname, "m_iDeflected") + 4, flDamage, true); // set damage
	TeleportEntity(iRocket, vPosition, vAngles, vVelocity);

	SetVariantInt(iTeam);
	AcceptEntityInput(iRocket, "TeamNum", -1, -1, 0);

	SetVariantInt(iTeam);
	AcceptEntityInput(iRocket, "SetTeam", -1, -1, 0);

	DispatchSpawn(iRocket);

	return iRocket;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{                                                                    //tf_weapon_rocketlauncher_directhit
	if(shoot[client] && ((StrEqual(Client_Current_Weapon[client], "tf_weapon_rocketlauncher", false) == true) ||  (StrEqual(Client_Current_Weapon[client], "tf_weapon_rocketlauncher_directhit", false) == true)))
	{
		buttons |= IN_ATTACK;
		shoot[client]=false;
		////////////////////////////////////////////////////// BOOOM SOUND EFFECT HERE
		//native War3_ShakeScreen(client,Float:duration=1.0,Float:magnitude=40.0,Float:noise=30.0);
		new shake_level = War3_GetSkillLevel(client,thisRaceID,STABILIZERS_SKILL);
		War3_ShakeScreen(client,shake_duration[shake_level],shake_magnitude[shake_level],shake_noise[shake_level]);
		EmitSoundToAll(rocketsound,client);
	}
	return Plugin_Continue;
}

public OnClientPutInServer(client){
	SDKHook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitchPost);
}

public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitchPost);
}

public SDK_OnWeaponSwitchPost(client, weapon)
{

	if(ValidPlayer(client))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			new String:weaponname[64];
			GetEntityClassname(weapon, weaponname, 64);
			//DP("Weapon Name Switch Post: %s",weaponname);
			Client_Current_Weapon[client]=weaponname;
		}
		else
		Client_Current_Weapon[client]="";
	}


/*	if(IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		new activeweapon = FindSendPropOffs("CTFPlayer", "m_hActiveWeapon");
		new activeweapondata = GetEntDataEnt2(client, activeweapon);
		if(IsValidEntity(activeweapondata))
		{
			new weaponindex = GetEntProp(activeweapondata, Prop_Send, "m_iItemDefinitionIndex");
			if(weaponindex==998)
			{
				CreateTimer(0.1, BlockingTimer,client);
				Spam[client]=10;

				// force player into slot 0 immediately
				new weaponslot = GetPlayerWeaponSlot(client, 0);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponslot);
			}
		}
	}
	*/
}
