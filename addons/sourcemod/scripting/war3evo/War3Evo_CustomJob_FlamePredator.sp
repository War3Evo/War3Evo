/**
* File: War3Source_Flame_Predator.sp
* Description: The Flame Predator race for SourceCraft.
* Author(s): xDr.HaaaaaaaXx
*
* MODIFIED by El Diablo
*/

#pragma semicolon 1
#pragma tabsize 0
#include <sourcemod>
#include <sdktools>
#include <sdktools_stocks>
#include <sdktools_tempents>
#include <sdktools_functions>
#include <sdktools_tempents_stocks>
#include <sdktools_entinput>
#include <sdktools_sound>

#include "W3SIncs/War3Source_Interface"

// War3Source stuff
new thisRaceID, SKILL_SPEEDHP, SKILL_INVIS, SKILL_LEVI, SKILL_DAZE, SKILL_FIRE, ULT_BURNINGINFERNO;

// Chance/Data Arrays
new Float:InfernoRadius[5] = { 0.0, 200.0, 233.0, 275.0, 333.0 };
new Float:InfernoDamage[5] = { 0.0, 166.0, 200.0, 233.0, 266.0 };
//new Float:InfernoChance[5] = { 0.0, 0.20, 0.27, 0.33, 0.40 };
new Float:FlameSpeed[5] = { 1.0, 1.1, 1.2, 1.3, 1.4 };
new Float:FlameInvis[5] = { 1.0, 0.55, 0.50, 0.45, 0.40 };
new Float:DazeChance[5] = { 0.0, 0.02, 0.04, 0.06, 0.08 };
new Float:BurnChance[5] = { 0.0, 0.15, 0.20, 0.25, 0.30 };
new Float:FlameGravity[5] = { 1.0, 0.7, 0.6, 0.5, 0.4 };
new Float:BurnTime[5] = { 0.0, 2.0, 2.5, 3.0, 3.5 };
new FlameHP[5] = { 100, 125, 130, 135, 140 };
new Float:InfernoLocation[MAXPLAYERS][3];


new Float:UltimateCharge[5] = { 0.0, 0.5, 1.0, 1.5, 2.0 };
// Sounds
new String:InfernoSound[] = "war3source/particle_suck1.wav";

// Other
//new HaloSprite, BeamSprite, ExplosionModel;

public Plugin:myinfo = 
{
	name = "War3Source Race - Flame Predator",
	author = "xDr.HaaaaaaaXx",
	description = "The Flame Predator race for War3Source.",
	version = "1.0.0.0",
	url = ""
};

public OnPluginStart()
{
	//LoadTranslations( "w3s.race.undead.phrases" );
}

public OnMapStart()
{	
//	ExplosionModel = PrecacheModel( "materials/sprites/zerogxplode.vmt", false );
//	BeamSprite = PrecacheModel( "materials/sprites/lgtning.vmt" );
//	HaloSprite = PrecacheModel( "materials/sprites/halo01.vmt" );
	PrecacheSound( "weapons/explode5.wav", false );
	War3_PrecacheSound( InfernoSound );
}

public OnWar3PluginReady()
{
	thisRaceID = War3_CreateNewRace( "Flame Predator", "flamepredator" );
	
	SKILL_SPEEDHP = War3_AddRaceSkill( thisRaceID, "Berserk", "Pump yourself with adrenaline to gain 45-60% more speed", false );
	SKILL_INVIS = War3_AddRaceSkill( thisRaceID, "Cloak of Invisibility", "Put on your cloak to be 76-88% invisible.", false );	
	SKILL_LEVI = War3_AddRaceSkill( thisRaceID, "Levitation", "Reduce your gravity by 30-60%", false );
	SKILL_DAZE = War3_AddRaceSkill( thisRaceID, "Blade Attack", "Hit an enemy, 2-8% chance to daze a enemy for 2 seconds.", false );
	SKILL_FIRE = War3_AddRaceSkill( thisRaceID, "Burning Blade", "Hit an enemy, 20-35% chance that he catch on fire", false );
	ULT_BURNINGINFERNO = War3_AddRaceSkill( thisRaceID, "Burning Inferno (AOE)", "Your forced to run super fast while on fire\nFinishes with 'Explosion Spell' damages enemies around you!\nYou run for 0.5/1/1.5/2 seconds", true );
	W3SkillCooldownOnSpawn(thisRaceID,ULT_BURNINGINFERNO,10.0,_);
	War3_CreateRaceEnd( thisRaceID );
	War3_SetDependency(thisRaceID, SKILL_FIRE, SKILL_DAZE, 4);
}

public InitPassiveSkills( client )
{
	if( War3_GetRace( client ) == thisRaceID )
	{
		//TF2_RemoveWeaponSlot(client, 0);
		//TF2_AddCondition( client, TFCond_RestrictToMelee,9999.0);
		//new weapon= GetPlayerWeaponSlot(client, 2);
		//EquipPlayerWeapon(client, weapon);
		War3_SetBuff( client, fInvisibilitySkill, thisRaceID, FlameInvis[War3_GetSkillLevel( client, thisRaceID, SKILL_INVIS )] );
		War3_SetBuff( client, fMaxSpeed, thisRaceID, FlameSpeed[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEEDHP )] );
		War3_SetBuff( client, fLowGravitySkill, thisRaceID, FlameGravity[War3_GetSkillLevel( client, thisRaceID, SKILL_LEVI )] );
		//War3_SetMaxHP( client, FlameHP[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEEDHP )] );
        War3_SetMaxHP_INTERNAL( client, FlameHP[War3_GetSkillLevel( client, thisRaceID, SKILL_SPEEDHP )] );
		if( War3_GetMaxHP( client ) > GetClientHealth( client ) )
		{
			War3_HealToMaxHP( client, ( War3_GetMaxHP( client ) - GetClientHealth( client ) ) );
		}
	}
}

public OnRaceChanged( client,oldrace,newrace )
{
	if( newrace != thisRaceID )
	{
		//War3_WeaponRestrictTo( client, thisRaceID, "" );
		W3ResetAllBuffRace( client, thisRaceID );
		//TF2_RemoveCondition(client, TFCond_RestrictToMelee);
	}
	else
	{	
		if( ValidPlayer( client, true ) )
		{
			InitPassiveSkills( client );
			//War3_WeaponRestrictTo( client, thisRaceID, "weapon_knife" );
		}
	}
}

public OnSkillLevelChanged( client, race, skill, newskilllevel )
{
	InitPassiveSkills( client );
}

public OnWar3EventSpawn( client )
{
	new race = War3_GetRace( client );
	if( race == thisRaceID )
	{
		InitPassiveSkills( client );
	}
}

public OnWar3EventPostHurt( victim, attacker, damage )
{
	if( W3GetDamageIsBullet() && ValidPlayer( victim, true ) && ValidPlayer( attacker, true ) && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
			new skill_daze = War3_GetSkillLevel( attacker, thisRaceID, SKILL_DAZE );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= DazeChance[skill_daze] )
			{
				if( !W3HasImmunity( victim, Immunity_Skills ) )
				{
					//FakeClientCommand( victim, "drop" );
					//TF2_RemoveAllWeapons(victim);
					TF2_AddCondition(victim,TFCond_Dazed,2.0);
				}
			}
			
			new skill_fire = War3_GetSkillLevel( attacker, thisRaceID, SKILL_FIRE );
			if( !Hexed( attacker, false ) && GetRandomFloat( 0.0, 1.0 ) <= BurnChance[skill_fire] )
			{
				if( !W3HasImmunity( victim, Immunity_Skills ) )
				{
					IgniteEntity( victim, BurnTime[skill_fire] );
				}
			}
		}
	}
}

public OnWar3EventDeath( victim, attacker )
{
	W3ResetAllBuffRace( victim, thisRaceID );
}

public OnUltimateCommand(client,race,bool:pressed)
{
	new userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) && !Silenced(client))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULT_BURNINGINFERNO);
		if(ult_level>0)
		{

			if(War3_SkillNotInCooldown(client,thisRaceID,ULT_BURNINGINFERNO,true))
			{
				//new Float:Timer_in_half=UltimateCharge[ult_level]/2;
				TF2_AddCondition(client,TFCond_OnFire,UltimateCharge[ult_level]);
				TF2_AddCondition(client,TFCond_Charging,UltimateCharge[ult_level]);
				War3_SetBuff(client,fMaxSpeed,thisRaceID,6.0);
				TF2_IgnitePlayer(client,client);
				//CreateTimer(Timer_in_half,Timer_Bomb,GetClientUserId(client));
				CreateTimer(UltimateCharge[ult_level],Timer_Disable_Ultimate,GetClientUserId(client));
				War3_CooldownMGR(client,20.0,thisRaceID,ULT_BURNINGINFERNO,_,_);
			}
		}
	}
}

/*public Action:Timer_Bomb(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	GetClientAbsOrigin( client, InfernoLocation[client] );
	//SuicideBomber( client, War3_GetSkillLevel( client, thisRaceID, ULT_BURNINGINFERNO ) );
	new level = War3_GetSkillLevel( client, thisRaceID, ULT_BURNINGINFERNO );
	War3_SuicideBomber(client, InfernoLocation[client], InfernoDamage[level], thisRaceID, InfernoRadius[level], true);
}
*/

public Action:Timer_Disable_Ultimate(Handle:timer, any:userid)
{
	new client = GetClientOfUserId(userid);
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	ExtinguishEntity(client);
	TF2_RemoveCondition(client, TFCond_OnFire);
	GetClientAbsOrigin( client, InfernoLocation[client] );
	//SuicideBomber( client, War3_GetSkillLevel( client, thisRaceID, ULT_BURNINGINFERNO ) );
	new level = War3_GetSkillLevel( client, thisRaceID, ULT_BURNINGINFERNO );
	War3_SuicideBomber(client, InfernoLocation[client], InfernoDamage[level], thisRaceID, InfernoRadius[level], true);
	//War3_DealDamage(client,9999,client,_,"suicidebomber",W3DMGORIGIN_ULTIMATE,W3DMGTYPE_PHYSICAL);
}

/*
public SuicideBomber( client, level )
{
	if( level > 0 )
	{
		new Float:radius = InfernoRadius[level];
		new our_team = GetClientTeam( client );
		new Float:client_location[3];
		for( new i = 0; i < 3; i++ )
		{
			client_location[i] = InfernoLocation[client][i];
		}

		TE_SetupExplosion( client_location, ExplosionModel, 10.0, 1, 0, RoundToFloor( radius ), 160 );
		TE_SendToAll();

		client_location[2] -= 40.0;

		TE_SetupBeamRingPoint( client_location, 10.0, radius, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, { 255, 255, 255, 33 }, 120, 0 );
		TE_SendToAll();

		new beamcolor[] = { 0, 200, 255, 255 };
		if( our_team == 2 )
		{
			beamcolor[0] = 255;
			beamcolor[1] = 0;
			beamcolor[2] = 0;
		}
		TE_SetupBeamRingPoint( client_location, 20.0, radius + 10.0, BeamSprite, HaloSprite, 0, 15, 0.5, 10.0, 10.0, beamcolor, 120, 0 );
		TE_SendToAll();

		client_location[2] += 40.0;

		EmitSoundToAll( InfernoSound, client );
		EmitSoundToAll( "weapons/explode5.wav", client );

		new Float:location_check[3];
		for( new x = 1; x <= MaxClients; x++ )
		{
			if( ValidPlayer( x, true ) && client != x )
			{
				new team = GetClientTeam( x );
				if( team != our_team )
				{
					GetClientAbsOrigin( x, location_check );
					new Float:distance = GetVectorDistance( client_location, location_check );
					if( distance < radius )
					{
						if( !W3HasImmunity( x, Immunity_Ultimates ) )
						{
							new Float:factor = ( radius - distance ) / radius;
							new damage;
							damage = RoundFloat( InfernoDamage[level] * factor );

							War3_DealDamage( x, damage, client, _, "suicidebomber", W3DMGORIGIN_ULTIMATE, W3DMGTYPE_PHYSICAL );
							PrintToConsole( client, "%T", "Suicide bomber damage: {amount} to {amount} at distance {amount}", client, War3_GetWar3DamageDealt(), x, distance );

							War3_ShakeScreen( x, 3.0 * factor, 250.0 * factor, 30.0 );
							W3FlashScreen( x, RGBA_COLOR_RED );
						}
						else
						{
							PrintToConsole( client, "%T", "Could not damage player {player} due to immunity", client, x );
						}
					}
				}
			}
		}
	}
}
*/
