/* ========================================================================== */
/*                                                                            */
/*   Angel of Death                                                           */
/*   (c) 2012 El Diablo                                                       */
/*                                                                            */
/*   Description    require level 100                                         */
/*                                                                            */
/* ========================================================================== */
/*
*/



#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON
#pragma tabsize 0     // doesn't mess with how you format your lines

#include <sourcemod>
#include <clients>
//#include "W3SIncs/War3Source_Effects"
#include "W3SIncs/War3Source_Interface"
public W3ONLY(){} //unload this?

public Plugin:myinfo =
{
	 name = "Angels - Angel de la Muerte (Angel of Death)",
	 author = "El Diablo",
	 description = "Meet the Angel of Death, let death begin!",
	 version = "1.04",
	 url = "http://cgaclan.com"
};

// Required
new thisRaceID;
new thisAuraID;
new Handle:ultCooldownCvar_angel;
new SKILL_TORTURE,SKILL_DEATH_REJECT,SKILL_REAPERS_SYCTHE,ULTIMATE_HANDS_OF_DEATH,ABILILTY_FAN;

// ABILILTY_FAN
new Float:FanRadius[5]={0.0,200.0,400.0,600.0,800.0};
new Float:FanLength[5]={0.0,2.0,4.0,6.0,8.0};  // seconds
new String:cursedSound[]="war3source/transorcerer/cursed.mp3";


// DOOM DAMAGE
new Float:Doom_dmg[5] = { 0.0, 0.04, 0.06 , 0.08, 0.1 };
new Float:Doom_dmg_others[5] ={ 0.0, 0.04, 0.06 , 0.08, 0.1 };
//new Float:Doom_dmg_others[5]={0.0,1.0,3.0,4.0,5.0};
new Float:DoomRange=9999.0;

// DEATH REJECT CHANCE
new Float:death_reject_chance[5] = { 0.0, 0.10, 0.20, 0.30, 0.45 };
// Why make people down a new sound??  Lets just use bloodmage's
new String:DeathRejectSound[]="war3source/reincarnation.wav";

// Reapers_Sycthe_dmg
new Float:Reapers_Sycthe_dmg[5] = { 0.0, 0.03, 0.06 , 0.09, 0.12 };


// HANDS OF DEATH
new HandsOfDeath_dmg[]={0,15,20,25,30};
new String:ultsnd[]="war3source/DeathScream.mp3";

/* ***************************  OnWar3LoadRaceOrItemOrdered2 *************************************/

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==100)
	{
	thisRaceID=War3_CreateNewRace("Angel of Death","AngelOfDeath");
	SKILL_TORTURE=War3_AddRaceSkill(thisRaceID,"Doom",
	"Passive Aura - a small fraction of damage to enemies and self every 10+ seconds (depends on level)",false,4);
	SKILL_DEATH_REJECT=War3_AddRaceSkill(thisRaceID,"Death reject",
	"Passive - upon death theres a 10%-20%-30%-45% chance to be revived with 25hp",false,4);
	SKILL_REAPERS_SYCTHE=War3_AddRaceSkill(thisRaceID,"Reapers sycthe",
	"bonus damage on attack 3%-6%-9%-12%",false,4);
	ABILILTY_FAN=War3_AddRaceSkill(thisRaceID,"Cursed",
	"Puts a mark of death on your eneimes\nin a radius of 150/300/450/600\nfor 2/4/6/8 seconds (+ability)",false,4);
	ULTIMATE_HANDS_OF_DEATH=War3_AddRaceSkill(thisRaceID,"Hands of Death",
	"All enemies take damage(15-20-25-30) [240 second cooldown]",true,4);

	HookConVarChange(ultCooldownCvar_angel, W3CvarCooldownHandler);
	W3SkillCooldownOnSpawn(thisRaceID,ABILILTY_FAN,10.0,_);          //ABILITY_FAN
	War3_SetDependency(thisRaceID, SKILL_REAPERS_SYCTHE, ABILILTY_FAN, 2);
//     W3SkillCooldownOnSpawn( thisRaceID, ULTIMATE_HANDS_OF_DEATH,
//     120.0 );
//DO NOT FORGET THE END!!!
	War3_CreateRaceEnd(thisRaceID);

	thisAuraID=W3RegisterAura("Doom",DoomRange,true);
	}
}

/* ***************************  OnPluginStart *************************************/

public OnPluginStart()
{
//Create race specific Cvars here
	ultCooldownCvar_angel=CreateConVar("war3_angel_of_death_ult_cooldown","240.0",
     "Angel of Death Ultimate Cooldown.");

//Hook events here!!!!
  HookEvent("player_death",PlayerDeathEvent);
  //HookConVarChange(ultCooldownCvar_SPAWN, W3CvarCooldownHandler);
}

/* ****************************** W3CvarCooldownHandler ************************** */

public W3CvarCooldownHandler(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new Float:value = StringToFloat(newValue);
	if(value>0.0)
	W3SkillCooldownOnSpawn( thisRaceID, ULTIMATE_HANDS_OF_DEATH, value );
}


/* ***************************  OnMapStart *************************************/

public OnMapStart()
{
	War3_PrecacheSound(ultsnd);
	War3_PrecacheSound(DeathRejectSound);
	War3_PrecacheSound(cursedSound);
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
    // Doom
     new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_TORTURE);
     W3SetAuraFromPlayer(thisAuraID,client,skilllevel>0?true:false,skilllevel);
     War3_SetBuff(client,fHPDecay,thisRaceID,Doom_dmg[skilllevel]);

     new skilllevel2=War3_GetSkillLevel(client,thisRaceID,SKILL_REAPERS_SYCTHE);
     War3_SetBuff(client,fDamageModifier,thisRaceID,Reapers_Sycthe_dmg[skilllevel2]);
     //War3_SetBuff(client,fDamageModifier,thisRaceID,0.50);
   }
}

/* ****************************** RemovePassiveSkills ************************** */

public RemovePassiveSkills(client)
{
 War3_SetBuff(client,fHPDecay,thisRaceID,0.0);
 W3SetAuraFromPlayer(thisAuraID,client,false);
 War3_SetBuff(client,iDamageBonus,thisRaceID,0);
}

/* ****************************** DoDeathReject ************************** */

public Action:DoDeathReject(Handle:timer,any:client)
{
	if(client>0)
    {
		if(ValidPlayer(client))
		{
			if(!IsPlayerAlive(client))
			{
				War3_SpawnPlayer(client);
                nsEntity_SetHealth(client, 25);
				EmitSoundToAll(DeathRejectSound,client);

				new Float:VecPos[3];
				new Float:Angles[3];
				War3_CachedAngle(client,Angles);
				War3_CachedPosition(client,VecPos);

				TeleportEntity(client, VecPos, Angles, NULL_VECTOR);

                new W3_CoolDown_number = War3_CooldownRemaining(client,thisRaceID,ULTIMATE_HANDS_OF_DEATH);
                if(W3_CoolDown_number>0)
                {
                  new Float:W3_new_cooldown_number = float(W3_CoolDown_number - 5);
                  if(W3_new_cooldown_number>0.0)
                   {
                    War3_CooldownMGR(client,W3_new_cooldown_number,thisRaceID,ULTIMATE_HANDS_OF_DEATH,false,_);
                    //PrintToChat(client,"5 seconds shaved off Hands of Death cooldown!");
                   }
                  else
                   {
                    War3_CooldownMGR(client,240.0,thisRaceID,ULTIMATE_HANDS_OF_DEATH,false,_);
                   }
                }

              }
        }
    }
}

/* ****************************** PlayerDeathEvent ************************** */

public PlayerDeathEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
//	new userid=GetEventInt(event,"userid");
//	new victim=GetClientOfUserId(userid);
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
    //War3_CooldownRemaining(client,raceid,skillNum);
    // War3_CooldownReset(client,raceid,skillNum);
   //War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar_SPAWN),thisRaceID,ULTIMATE_HANDS_OF_DEATH,false,_);
    new W3_CoolDown_number = War3_CooldownRemaining(attacker,thisRaceID,ULTIMATE_HANDS_OF_DEATH);
    if(attacker>0 && War3_GetRace(attacker) == thisRaceID && W3_CoolDown_number>0)
       {
        new Float:W3_new_cooldown_number = float(W3_CoolDown_number - 5);
        if(W3_new_cooldown_number>0.0)
          {
           War3_CooldownMGR(attacker,W3_new_cooldown_number,thisRaceID,ULTIMATE_HANDS_OF_DEATH,false,_);
           //PrintToChat(attacker,"5 seconds shaved off Hands of Death cooldown!");
          }
         else
          {
           War3_CooldownReset(attacker,thisRaceID,ULTIMATE_HANDS_OF_DEATH);
           PrintToChat(attacker,"Hands of Death Ready!");
          }
       }
	if(victim>0)
       {
       		if( War3_GetRace( victim ) == thisRaceID )
            {
               new skilllevel=War3_GetSkillLevel(victim,thisRaceID,SKILL_DEATH_REJECT);
                   if(skilllevel>0 && War3_Chance(death_reject_chance[skilllevel]))
                   {
                      	CreateTimer(2.0,DoDeathReject,victim);
                   }

            }

       }
}

/* ****************************** OnW3PlayerAuraStateChanged ************************** */

public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
	if(aura==thisAuraID && !W3HasImmunity(client,Immunity_Skills)) //i am completely unsure if this will cause doom to respect skill immunities; currently it does not - Dagothur 1/19/2013
	{
		War3_SetBuff(client,fHPDecay,thisRaceID,inAura?Doom_dmg_others[level]:0.0);
	}
}

public OnAbilityCommand(client,ability,bool:pressed)
{
	new userid=GetClientUserId(client);
	if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && userid>1 && IsPlayerAlive(client)&&!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ABILILTY_FAN,true))
	{
	//War3_ChatMessage(client,"+ABILITY");
	new skill_level=War3_GetSkillLevel(client,thisRaceID,ABILILTY_FAN);
	//new target=War3_GetTargetInViewCone(client,FanRadius[skill_level],false,23.0,SkillFilter);
	if(skill_level>0)
		{
			EmitSoundToClient(client,cursedSound);
			new Float:posVec[3];
			GetClientAbsOrigin(client,posVec);
			new Float:otherVec[3];
			new team = GetClientTeam(client);
			if(team==TEAM_RED)
				team=TEAM_BLUE;
			else if(team==TEAM_BLUE)
				team=TEAM_RED;
			new maxtargets=15;
			new targetlist[MAXPLAYERSCUSTOM];
			new targetsfound=0;
			new Float:ultmaxdistance=FanRadius[skill_level];              //99999.0;
			for(new i=1;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true)&&GetClientTeam(i)==team&&(i!=client))
				{
					GetClientAbsOrigin(i,otherVec);
					new Float:dist=GetVectorDistance(posVec,otherVec);
					if(dist<ultmaxdistance)
					{
						targetlist[targetsfound]=i;
						targetsfound++;
						if(targetsfound>=maxtargets)
						{
							break;
						}
					}
				}
			}
			if(targetsfound==0)
			{
				W3MsgNoTargetFound(client,ultmaxdistance);
				War3_CooldownMGR(client,20.0,thisRaceID,ABILILTY_FAN,true,true);
			}
			else
			{
				//new allies;
				new String:DeathClient[64];
				GetClientName(client, DeathClient, sizeof(DeathClient));
				for(new i=0;i<targetsfound;i++)
				{
					new enemies=targetlist[i];
					if(!W3HasImmunity(enemies,Immunity_Skills))
					{
						EmitSoundToClient(enemies,cursedSound);
						TF2_AddCondition(enemies, TFCond_MarkedForDeath,FanLength[skill_level]);
						W3FlashScreen(enemies,RGBA_COLOR_PURPLE);
						//PrintHintText(enemies,"%T","CursedByDK",DeathClient);
						PrintHintText(enemies,"Cursed by Death Knight %s",DeathClient);
					}
					else
					{
						if(War3_GetOwnsItem(enemies,War3_GetItemIdByShortname("lace")))
							//PrintHintText(enemies,"%T","NecklaceProtected",enemies);
							PrintHintText(enemies,"Necklace protected you from 'Cursed!'");
						else
							//PrintHintText(enemies,"%T","UnknownImmune",enemies);
							PrintHintText(enemies,"For some reason you're immune to the ability: 'Cursed!'"); //fixed typo - Dagothur 1/19/2013
					}
				}
				//PrintHintText(client,"%T","CursedEnemies",targetsfound);
				PrintHintText(client,"You Cursed %i enemies!",targetsfound);
				War3_CooldownMGR(client,20.0,thisRaceID,ABILILTY_FAN,true,true);
				//EmitSoundToAll(ultsnd,victim);
				}
		}
	}
}

/* ****************************** OnUltimateCommand ************************** */

public OnUltimateCommand(client,race,bool:pressed)
{
	new userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) )
	{
		new ult_level=War3_GetSkillLevel(client,race,ULTIMATE_HANDS_OF_DEATH);
		if(ult_level>0)
		{
			if(War3_SkillNotInCooldown(client,thisRaceID,ULTIMATE_HANDS_OF_DEATH,true))
			{
				if(!Silenced(client))
				{
					new Float:posVec[3];
					GetClientAbsOrigin(client,posVec);
					new Float:otherVec[3];
					new team = GetClientTeam(client);
					new maxtargets=15;
					new targetlist[MAXPLAYERSCUSTOM];
					new targetsfound=0;
					new Float:ultmaxdistance=99999.0;
					for(new i=1;i<=MaxClients;i++)
					{
						if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&!W3HasImmunity(i,Immunity_Ultimates))
						{
							GetClientAbsOrigin(i,otherVec);
							new Float:dist=GetVectorDistance(posVec,otherVec);
							if(dist<ultmaxdistance)
							{
								targetlist[targetsfound]=i;
								targetsfound++;
								if(targetsfound>=maxtargets){  //???
									break;
								}
							}
						}
					}
					if(targetsfound==0)
					{
						W3MsgNoTargetFound(client,ultmaxdistance);
					}
					else
					{
						new damage=HandsOfDeath_dmg[ult_level];
						new damagedealt;
						for(new i=0;i<targetsfound;i++)
						{
							new victim=targetlist[i];
							if(War3_DealDamage(victim,damage,client,DMG_BULLET,"Hands of Death")) //default magic
							{
								damagedealt+=War3_GetWar3DamageDealt();
								W3FlashScreen(victim,RGBA_COLOR_RED);
								PrintHintText(victim,"Attacked by Hands of Death");
								EmitSoundToAll(ultsnd,victim);
							}
						}
						PrintHintText(client,"Hands of Death attacked for %i total damage to all victims!",damage*targetsfound);
						War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar_angel),thisRaceID,ULTIMATE_HANDS_OF_DEATH,false,_);
						//EmitSoundToAll(ultsnd,victim);
					}
				}

			}
		}
		else
		{
			W3MsgUltNotLeveled(client);
		}
	}
}

/*
public OnWar3EventPostHurt(victim, attacker, damage)
{
   if(attacker==thisRace)
   War3_DealDamage(victim,newdamage,attacker,_,"weapon_crit");
} */