//  Any updates to this Race, please inform me via War3source.com
//  On War3source.com I'm known as El Diablo
//  On CGACLAN.com    I'm known as El Diablo
//                     on the servers and the forum.
//
//  UPDATED: 3/16/2012 8:00pm EST
//
// ========================================================================== */
//                                                                            */
//   War3Source_Customrace_Trillin.sp                                         */                      */
//   2012 El Diablo                                                           */
//                                                                            */
//                                                                            */
//                                                                            */
// ========================================================================== */

#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON
#pragma tabsize 0

#include <sourcemod>
#include <sdktools_hooks>
#include <sdktools_functions>
#include <sdktools_sound>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>
#include <tf2>
#include "W3SIncs/War3Source_Interface"
public W3ONLY(){} //unload this?  

public Plugin:myinfo = 
{
	 name = "Race - Trillin",
	 author = "El Diablo",
	 description = "Trillin can heal self while ducking, and SolarFlare damage his enemies.",
	 version = "1.03",
	 url = "http://cgaclan.com"
};
                  
const Float:version_num = 1.0; 
const Maximum_Ki_array=100;

// Sounds
new String:fdisable_sound[] = "war3source/fdisable.wav";
new String:fenable_sound[] = "war3source/fenable.wav";

                    
// Declare Global Variables
new Handle:ultCooldownCvar_SPAWN;
new Handle:ultCooldownCvar;
new Handle:KI_MAX;

//Sounds
new String:sfsound[]="war3source/solarflare.wav";

new thisRaceID;
new ABILITY_FORT,SKILL_MEDITATE,SKILL_FASTFEET,ULTIMATE_SOLARFLARE;
new Handle:HudMessage;
// Fortitude
new Float:TArmorPhysical[5]={0.005,0.01,0.03,0.05,0.07};
new Float:TArmorMagical[5]={0.005,0.03,0.05,0.07,0.09};
new bool:ARMOR_ENABLED=false;


new Float:Ki[Maximum_Ki_array];
// Ki Feet
new Float:Ki_Feet[5]={ 0.0, 1.07 ,1.11 ,1.18 ,1.24 };
// Ki Energy gained on Hit Max 100
new Float:Ki_Skill[5]={ 0.01, 0.03 ,0.04 ,0.05 ,0.06 };
// Meditatation speed
new Float:Meditate[5]={ 4.50, 4.0, 3.25, 2.00 ,1.65 };
// Meditation Health Regen
new Meditate_Regen[5]={ 1, 2, 3, 4, 5 };
// Ki Spells Dististance
new Float:KiMaxDistance[5]={0.00,350.0,500.0,800.0,1200.0};
//
new SolarFlare_DMG[5]={1,10,15,20,25};
new HaloSprite, FireSprite;

/* ***************************  OnWar3LoadRaceOrItemOrdered2 *************************************/

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==11)
	{
     thisRaceID=War3_CreateNewRace("Trillin","trillin");
     ABILITY_FORT=War3_AddRaceSkill(thisRaceID,"Fortitude",
     "[+ability] Turn on/off Physcial/Magical increases based on amount of Ki and Fortitude level. (ON = Consumes Ki slowly) (Can not gain Ki while ON)",false,4);
     SKILL_MEDITATE=War3_AddRaceSkill(thisRaceID,"Meditate",
     "Passive - While ducking, Ki(energy) will heal you as long as you don't have attack ready. Healing 2/3/4/5 per second & costs 4.0/3.25/2.00/1.65 +1-5(Random) Ki per skill level.",false,4);
     SKILL_FASTFEET=War3_AddRaceSkill(thisRaceID,"Fast Reflexes",
     "Fast Reflexes - Increases maxspeed by 1.07/1.11/1.18/1.24.",false,4);
     ULTIMATE_SOLARFLARE=War3_AddRaceSkill(thisRaceID,"Solar Flare",
     "Solar Flare - 10/15/20/25 Damage +/-35(Based on distance) + Left over Ki (wiped on use) and 25%/50%/75%/100% chance to Ignite Target player.",true,4);
     W3SkillCooldownOnSpawn( thisRaceID, ULTIMATE_SOLARFLARE,
     GetConVarFloat(ultCooldownCvar_SPAWN) );
//DO NOT FORGET THE END!!!
     War3_CreateRaceEnd(thisRaceID);
  }
}

/* ***************************  OnPluginStart *************************************/

public OnPluginStart()
{
// Create HUD For displaying Total KI    
	HudMessage = CreateHudSynchronizer();
//Create race specific Cvars here
	ultCooldownCvar_SPAWN=CreateConVar("war3_trillin_ult_cooldown_spawn","10",
     "trillin's Ultimate Cooldown on spawn.");      
	ultCooldownCvar=CreateConVar("war3_trillin_ult_cooldown","20",
     "Cooldown");
	KI_MAX=CreateConVar("war3_Trillin_max_Ki","100",
     "The Maximum amount of Ki Trillin can have total.",0,true,0.0,false);
                                  
//Hook events here!!!!
	HookEvent("player_hurt",PlayerHurtEvent);
  HookEvent("player_healed",PlayerHealEvent);
	HookConVarChange(ultCooldownCvar_SPAWN, W3CvarCooldownHandler);
}

/* ***************************  OnMapStart *************************************/

public OnMapStart() 
{
    CreateTimer(2.0,Timer_UpdateInfo,_,TIMER_REPEAT);
    //CreateTimer(1.0,Timer_Meditate,_,TIMER_REPEAT);     
    //precaches..
    War3_PrecacheSound(sfsound);
	War3_PrecacheSound(fdisable_sound);
    War3_PrecacheSound(fenable_sound);
    HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
    FireSprite=PrecacheModel("effects/fire_embers1.vmt");
    for(new i;i<Maximum_Ki_array;i++)
    {
     Ki[i]=0.0;
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

//public OnWar3PluginReady()
//{
//}
               
/* ***************************  W3CvarCooldownHandler *************************************/

public W3CvarCooldownHandler(Handle:cvar, const String:oldValue[], const String:newValue[]) 
{ 
	new Float:value = StringToFloat(newValue);
	if(value>0.0)
	W3SkillCooldownOnSpawn( thisRaceID, ULTIMATE_SOLARFLARE, value );
}

/* ***************************  PlayerHealEvent *************************************/

public PlayerHealEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new patient = GetClientOfUserId( GetEventInt( event, "patient" ) );
	new healer = GetClientOfUserId( GetEventInt( event, "healer" ) );
    //new skill_energy = War3_GetSkillLevel( healer, thisRaceID, SKILL_MEDITATE ); //KI energy
    // ARMOR_ENABLED==false --- Don't give KI while armor is enabled
	if( ValidPlayer(healer) && War3_GetRace(healer) == thisRaceID && healer!=patient && ARMOR_ENABLED==false)
  {
  if(TF2_GetPlayerClass(healer)==TFClass_Medic)
     {       // Medic Gains Ki too slowly.. lets boost it up.
     //if(skill_energy==1)
     //Ki[healer] = Ki[healer] + 2.0;
     //if(skill_energy==2)
     //Ki[healer] = Ki[healer] + 3.0;
     //if(skill_energy==3)
     //Ki[healer] = Ki[healer] + 4.0;
     //if(skill_energy==4)
     Ki[healer] = Ki[healer] + 5.0;
     }
    else
     {    // If Engineer dispenser or what not...
     //if(skill_energy==1)
     //Ki[healer] = Ki[healer] + 1.0;
     //if(skill_energy==2)
     //Ki[healer] = Ki[healer] + 2.0;
     //if(skill_energy==3)
     //Ki[healer] = Ki[healer] + 3.0;
     //if(skill_energy==4)
     Ki[healer] = Ki[healer] + 4.0;
     }
     if(Ki[healer]>100.0)
      Ki[healer]=100.0;
     if(ARMOR_ENABLED==true) SET_FORT(healer);
  }
}  

/* ***************************  PlayerHurtEvent *************************************/
                   
public PlayerHurtEvent( Handle:event, const String:name[], bool:dontBroadcast )
{
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	
	if( victim > 0 && attacker > 0 && attacker != victim && GetClientTeam( victim ) != GetClientTeam( attacker ) )
	{
		if( War3_GetRace( attacker ) == thisRaceID )
		{
               //new skill_energy = War3_GetSkillLevel( attacker, thisRaceID, SKILL_MEDITATE );  //KI ENERGY
               if( ValidPlayer( attacker, true, false ) == true )
			{
                    //if( (skill_energy > 0) && (SkillFilter(victim)) && !War3_IsUbered(victim) && ARMOR_ENABLED==false )
                    if( (SkillFilter(victim)) && !War3_IsUbered(victim) && ARMOR_ENABLED==false )
                    {
                    	   new Float:damageamountF = float(War3_GetWar3DamageDealt());
                         new bool:Apply_Extra_Ki = false; 
                         //if(skill_energy==1 && War3_Chance(0.01)) Apply_Extra_Ki = true;
                         //if(skill_energy==2 && War3_Chance(0.02)) Apply_Extra_Ki = true;
                         //if(skill_energy==3 && War3_Chance(0.03)) Apply_Extra_Ki = true;
                         //if(skill_energy==4 && War3_Chance(0.04)) Apply_Extra_Ki = true;
                         if(War3_Chance(0.04)) Apply_Extra_Ki = true;
                         if(Apply_Extra_Ki)
                           {
                            Ki[attacker]=(Ki[attacker] + (Ki_Skill[4] * FloatAbs(damageamountF)))*2;
                           }
                          else         
                           {
                            Ki[attacker]=(Ki[attacker] + (Ki_Skill[4] * FloatAbs(damageamountF)));
                           }
                           // CHECK FOR AFTERBURN AND PREVENT THIS BELOW
                            if(TF2_GetPlayerClass(attacker)==TFClass_Sniper) Ki[attacker]=Ki[attacker] * 1.4;
                            if(TF2_GetPlayerClass(attacker)==TFClass_DemoMan) Ki[attacker]=Ki[attacker] * 1.4;
                            if(TF2_GetPlayerClass(attacker)==TFClass_Scout) Ki[attacker]=Ki[attacker] * 1.4;

                         new Float:ki_max = GetConVarFloat(KI_MAX);
                         if(Ki[attacker] >= ki_max)
                                         Ki[attacker] = ki_max;
                         if(ARMOR_ENABLED==true) SET_FORT(attacker);
                    }
			}
		}
	}
}

/* ***************************  OnSkillLevelChanged *************************************/

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
    InitPassiveSkills(client);
}

/* ***************************  SET_FORT *************************************/

public SET_FORT(client)
{
    // FORTITUDE
    new Float:Ki_pArmor=0.0;
    new Float:Ki_mArmor=0.0;
    new skilllevel_Armor=War3_GetSkillLevel(client,thisRaceID,ABILITY_FORT);
    Ki_pArmor = Ki[client] * TArmorPhysical[skilllevel_Armor];
    Ki_mArmor = Ki[client] * TArmorMagical[skilllevel_Armor];
    War3_SetBuff(client,fArmorPhysical,thisRaceID,Ki_pArmor);
    War3_SetBuff(client,fArmorMagic,thisRaceID,Ki_mArmor);
}

/* ***************************  InitPassiveSkills *************************************/

public InitPassiveSkills(client)
{
    if(War3_GetRace(client)==thisRaceID)
    {
          // FAST FEET
          new skilllevel_fastfeet=War3_GetSkillLevel(client,thisRaceID,SKILL_FASTFEET);
          War3_SetBuff(client,fSlow,thisRaceID,1.0);
          War3_SetBuff(client,fMaxSpeed,thisRaceID,Ki_Feet[skilllevel_fastfeet]);
          // FORTITUDE    -- is ability.. don't setup on passive skills
          //SET_FORT(client);
    }
}

/* ***************************  RemovePassiveSkills *************************************/

public RemovePassiveSkills(client)
{
 War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
 War3_SetBuff(client,fSlow,thisRaceID,1.0);
 War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
 War3_SetBuff(client,fArmorMagic,thisRaceID,0.0);
 Ki[client]=0.0;
}   

/* ***************************  Timer_UpdateInfo *************************************/

public Action:Timer_UpdateInfo(Handle:timer) 
{
  for(new i;i<Maximum_Ki_array;i++)
  {
    if(ValidPlayer(i,true) && !IsFakeClient(i) && (War3_GetRace(i)==thisRaceID))
      {
      if(ARMOR_ENABLED==true)
      {
      // consume KI
         Ki[i] = Ki[i] - 1.5;
         if(Ki[i]<0.0)
          {
           Ki[i]=0.0;
           ARMOR_ENABLED=false;
           W3Hint(i,HINT_SKILL_STATUS,1.0,"Fortitude Disabled");
           EmitSoundToClient( i, fdisable_sound );
          }
         SET_FORT(i);
      }
      new skills_level = War3_GetLevel(i,thisRaceID);  // KI ENERGY
      if (skills_level>0)
         {
         //ClearSyncHud(i, HudMessage);
         SetHudTextParams(0.08, 0.84, 1.95, 255, 255, 0, 255);
         ShowSyncHudText(i, HudMessage, " Ki: %i ",RoundFloat(Ki[i]));
         }
      }
  }
}

/* ***************************  ACTIONS *************************************/

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
    //if (!IsPlayerAlive(client))
//        buttons = buttons &= ~IN_USE;
//    return Plugin_Continue;
    if(ValidPlayer(client,true,true) && !IsFakeClient(client) && War3_GetRace(client)==thisRaceID)
    {
        new skilllevel_meditate=War3_GetSkillLevel(client,thisRaceID,SKILL_MEDITATE);
        if((skilllevel_meditate > 0 && Ki[client]>0) && (buttons == IN_DUCK))
            {
                if(GetClientHealth(client)<War3_GetMaxHP(client))
                {
                Ki[client] = (Ki[client] - (Meditate[skilllevel_meditate] + GetRandomFloat(1.0,5.0)));
                if(Ki[client] <=0.0)
                  Ki[client] = 0.0;
                War3_HealToMaxHP(client,Meditate_Regen[skilllevel_meditate]);
                //SetHudTextParams(0.90, 0.70, 10.0, 0, 0, 255, 150);
                //ShowSyncHudText(i, HudMessage, "...Meditating...");
                }
            }
    }
}

/* ***************************  ability *************************************/

public OnAbilityCommand(client,ability,bool:pressed)
{
	//if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed)
	{
	   //new skilllevelz = War3_GetSkillLevel(client,thisRaceID,ABILITY_FORT);
       if(ARMOR_ENABLED==true)
       {
         // disabled
         ARMOR_ENABLED=false;
         EmitSoundToClient( client, fdisable_sound );
         War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
         War3_SetBuff(client,fArmorMagic,thisRaceID,0.0);
         W3Hint(client,HINT_SKILL_STATUS,1.0,"Fortitude Disabled");
       }
       else
       {
       // enabled
         EmitSoundToClient( client, fenable_sound );
         ARMOR_ENABLED=true;
         SET_FORT(client);
         W3Hint(client,HINT_SKILL_STATUS,1.0,"Fortitude Enabled");
       }
    }

}

/* ***************************  OnUltimateCommand *************************************/

public OnUltimateCommand(client,ability,bool:pressed)
{
	if(War3_GetRace(client)==thisRaceID && pressed && IsPlayerAlive(client))
	{
		new skilllevelz = War3_GetSkillLevel(client,thisRaceID,ULTIMATE_SOLARFLARE);
		if(skilllevelz > 0)
		{
			if(!Silenced(client))
			{
				if(War3_SkillNotInCooldown(client,thisRaceID,ULTIMATE_SOLARFLARE,true))
				{
                         new Float:startpos[3];
                         new Float:targetpos[3];
                         War3_GetAimEndPoint(client,targetpos);
                         GetClientAbsOrigin(client,startpos);
                         new Float:vdistance = GetVectorDistance(startpos,targetpos,false);
                         startpos[2]+=45;
                    
                         new target = War3_GetTargetInViewCone(client,KiMaxDistance[skilllevelz],false,90.0);
                         if(target>0 && !War3_IsUbered(target) && !W3HasImmunity(target,Immunity_Skills))
                              {
                              W3FlashScreen(target,{10,10,15,228}, 0.65, 0.8, FFADE_OUT);
                              TE_SetupBeamRingPoint(targetpos,120.1,120.0,FireSprite,HaloSprite,0,15,4.50,5.0,50.0,{255,0,0,200},0,0);
                              TE_SendToAll();
                              EmitSoundToAll(sfsound,client);
                              new ddmg;
                              if(vdistance<75)
                              {
                              ddmg = (SolarFlare_DMG[skilllevelz] + RoundToCeil(Ki[client]) + GetRandomInt(10,35));
                              if(ddmg<25 && skilllevelz==1 && War3_Chance(0.25)) ddmg=20;
                              if(ddmg<25 && skilllevelz==2 && War3_Chance(0.50)) ddmg=30;
                              if(ddmg<25 && skilllevelz==3 && War3_Chance(0.75)) ddmg=40;
                              if(ddmg<25 && skilllevelz==4) ddmg=50;                                                                                          
                              //Ki[client] = 0.0;
                              if(skilllevelz==1 && War3_Chance(0.25)) TF2_IgnitePlayer(target, client);                              
                              if(skilllevelz==2 && War3_Chance(0.50)) TF2_IgnitePlayer(target, client);
                              if(skilllevelz==3 && War3_Chance(0.75)) TF2_IgnitePlayer(target, client);
                              if(skilllevelz==4 && War3_Chance(1.00)) TF2_IgnitePlayer(target, client);
                              War3_DealDamage(target,ddmg,client,DMG_ENERGYBEAM,"solar_flare",W3DMGORIGIN_SKILL,W3DMGTYPE_MAGIC);                              
                              }
                              else  
                              {
                              ddmg = (SolarFlare_DMG[skilllevelz] + RoundToCeil(Ki[client])- GetRandomInt(10,35));
                              if(ddmg<25 && skilllevelz==1 && War3_Chance(0.25)) ddmg=20;
                              if(ddmg<25 && skilllevelz==2 && War3_Chance(0.50)) ddmg=30;
                              if(ddmg<25 && skilllevelz==3 && War3_Chance(0.75)) ddmg=40;
                              if(ddmg<25 && skilllevelz==4) ddmg=50;                                                                                          
                              //Ki[client] = 0.0;
                              if(skilllevelz==1 && War3_Chance(0.25)) TF2_IgnitePlayer(target, client);
                              if(skilllevelz==2 && War3_Chance(0.50)) TF2_IgnitePlayer(target, client);
                              if(skilllevelz==3 && War3_Chance(0.75)) TF2_IgnitePlayer(target, client);
                              if(skilllevelz==4 && War3_Chance(1.00)) TF2_IgnitePlayer(target, client);
                              War3_DealDamage(target,ddmg,client,DMG_ENERGYBEAM,"solar_flare",W3DMGORIGIN_SKILL,W3DMGTYPE_MAGIC);                                                                                                                                 
                              }
                              if(ARMOR_ENABLED==true)
                                {
                                Ki[client] = 0.0;
                                }
                               else
                                {
                                if(Ki[client]>=50.0) Ki[client] = 50.0;
                                }
                              PrintToConsole(client,"damaged enemy [Estimate damage]: (%i -hp)",ddmg);
                              PrintHintText(client,"SolarFlare : Hit Target [Estimate damage]: (%i -hp)",ddmg);
                              PrintHintText(target,"You were hit by SolarFlare [Estimate damage]: (%i -hp)",ddmg);
                              new Float:solarflarecooldowntime = GetConVarFloat(ultCooldownCvar);
                              War3_CooldownMGR(client,solarflarecooldowntime,thisRaceID,ULTIMATE_SOLARFLARE,_,_);                              
                              }
                         else
                              {
                              //War3_CooldownMGR(client,1.0,thisRaceID,ULTIMATE_SOLARFLARE,true,true);
                              PrintHintText(client,"No Valid Target.");
                              }
                    }
               }
				else
                    {
                    PrintToChat(client,"\x05Failed, you are Silenced!");
                    }
		}
	}
}
