/**
* File: War3Source_CustomRace_Transmutation_Sorcerer.sp
* Description: The Transmutation Sorcerer race for War3Source.
* By El Diablo 2012
*/

#pragma semicolon 1

#include "W3SIncs/sdkhooks"
#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include <sdktools>
#include <sdktools_functions>
#include <sdktools_tempents>
#include <sdktools_tempents_stocks>


public W3ONLY(){} //unload this?

new thisRaceID;

new SKILL_UNHOLY, ABILITY_PURPLE_WARD, ABILILTY_FAN, ULT_HEADLESS_HORSEMAN;

new BeamSprite, HaloSprite;

//skill1 Unholy Aura
new thisAuraID;
new Float:UnholyRange=300.0;     // about 30 feet
new Float:UnholyAura[5]={0.0,1.0,2.0,3.0,4.0};  // seconds

//skill2 Slow Ward
new Float:TurtledSpeed[5]={0.0,0.40,0.30,0.20,0.10};
#define MAXWARDS 64*4 //on map LOL
#define WARDRADIUS 70 // was 70
#define WARDBELOW -2.0 // player is 60 units tall about (6 feet)
#define WARDABOVE 160.0
new CurrentWardCount[MAXPLAYERSCUSTOM];
new bool:TurtledWard[MAXPLAYERSCUSTOM];
new TurtledOwnerWard[MAXWARDS][MAXPLAYERSCUSTOM];
new WardStartingArr[]={0,1,2,3,4};
new Float:WardLocation[MAXWARDS][3];
new WardOwner[MAXWARDS];

new bool:flashedscreen[MAXPLAYERSCUSTOM];

//skill3 ABILILTY_FAN
new Float:FanRadius[5]={0.0,200.0,400.0,600.0,800.0};
new Float:FanLength[5]={0.0,2.0,4.0,6.0,8.0};  // seconds

// headless horseman
new Float:g_pos[3];
new HeadlessHorseman[MAXPLAYERSCUSTOM][2];
new Float:HeadlessHorseman_delay[5]={0.0,20.0,25.0,30.0,35.0};  // seconds

//ultimate
//new Float:SwapRange[5]={0.0,300.0,600.0,900.0,1200.0};

new String:cursedSound[]="war3source/transorcerer/cursed.mp3";
new String:TransSoulSwapSound[]="war3source/transorcerer/transsoulswap.mp3";

public Plugin:myinfo = 
{
	name = "Race - Transmutation Sorcerer",
	author = "El Diablo",
	description = "The Transmutation Sorcerer race for War3Source.",
	version = "1.0.0.1",
	url = "http://www.war3source.com"
};

public OnPluginStart()
{
	CreateTimer(0.1,CalcWards,_,TIMER_REPEAT);
	//CreateTimer(1.0,HeadlessHorsemanTimer,_,TIMER_REPEAT);
	LoadTranslations("w3s.race.transorcerer.phrases");
}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==120)
	{
	// Translations added:
		thisRaceID=War3_CreateNewRaceT("transorcerer");
		SKILL_UNHOLY=War3_AddRaceSkillT(thisRaceID,"UnholyAura",false,4,"1/2/3/4");
		ABILITY_PURPLE_WARD=War3_AddRaceSkillT(thisRaceID,"SlowWard",false,4,"");
		ABILILTY_FAN=War3_AddRaceSkillT(thisRaceID,"Cursed",false,4,"150/300/450/600","2/4/6/8");
		ULT_HEADLESS_HORSEMAN=War3_AddRaceSkillT(thisRaceID,"Summon",true,4,"");

/*      WITHOUT TRANSLATIONS:
		thisRaceID=War3_CreateNewRace("Transmutation Sorcerer","transorcerer");
		SKILL_UNHOLY=War3_AddRaceSkill(thisRaceID,"Unholy Aura",
		"Enemies within your range receive Slow effects. Lasts 1/2/3/4 seconds.",false,4);

		ABILITY_PURPLE_WARD=War3_AddRaceSkill(thisRaceID,"Slow Ward",
		"Slows down your enemies! (Slows down enemies greatly)\n(+ability)",false,4);
		ULT_HEADLESS_HORSEMAN=War3_AddRaceSkill(thisRaceID,"Soul Swap",
		"Swap places with your target.\n300/600/900/1200 range.(+ability2)",false,4);
		ABILILTY_FAN=War3_AddRaceSkill(thisRaceID,"Cursed",
		"Puts a mark of death on your eneimes\nin a radius of 150/300/450/600\nfor 2/4/6/8 seconds (+ultimate)",true,4);
*/
		W3SkillCooldownOnSpawn(thisRaceID,ULT_HEADLESS_HORSEMAN,10.0,_);         //ULT_SOULSWAP
		W3SkillCooldownOnSpawn(thisRaceID,ABILILTY_FAN,10.0,_);          //ABILITY_FAN
		War3_CreateRaceEnd(thisRaceID);
		thisAuraID=W3RegisterAura("UnholyAura",UnholyRange,true);
		// If you want to add a dependency skill:    Last number is how many levels of the ult_fan
		//                                           that you want the user to level before he/she
		//                                           can use Skill_Unholy.
		//War3_SetDependency(thisRaceID, SKILL_UNHOLY, ULT_FAN, 4);
	}
	
}

public OnMapStart()
{
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");

	War3_PrecacheSound(cursedSound);
	War3_PrecacheSound(TransSoulSwapSound);

	PrecacheModel("models/bots/headless_hatman.mdl");
	PrecacheModel("models/weapons/c_models/c_bigaxe/c_bigaxe.mdl");
	PrecacheSound("ui/halloween_boss_summon_rumble.wav");
	PrecacheSound("vo/halloween_boss/knight_alert.wav");
	PrecacheSound("vo/halloween_boss/knight_alert01.wav");
	PrecacheSound("vo/halloween_boss/knight_alert02.wav");
	PrecacheSound("vo/halloween_boss/knight_attack01.wav");
	PrecacheSound("vo/halloween_boss/knight_attack02.wav");
	PrecacheSound("vo/halloween_boss/knight_attack03.wav");
	PrecacheSound("vo/halloween_boss/knight_attack04.wav");
	PrecacheSound("vo/halloween_boss/knight_death01.wav");
	PrecacheSound("vo/halloween_boss/knight_death02.wav");
	PrecacheSound("vo/halloween_boss/knight_dying.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh01.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh02.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh03.wav");
	PrecacheSound("vo/halloween_boss/knight_laugh04.wav");
	PrecacheSound("vo/halloween_boss/knight_pain01.wav");
	PrecacheSound("vo/halloween_boss/knight_pain02.wav");
	PrecacheSound("vo/halloween_boss/knight_pain03.wav");
	PrecacheSound("vo/halloween_boss/knight_spawn.wav");
	PrecacheSound("weapons/halloween_boss/knight_axe_hit.wav");
	PrecacheSound("weapons/halloween_boss/knight_axe_miss.wav");
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
		new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_UNHOLY);
		W3SetAuraFromPlayer(thisAuraID,client,skilllevel>0?true:false,skilllevel);
	}

}

/* ****************************** RemovePassiveSkills ************************** */

public RemovePassiveSkills(client)
{
	W3SetAuraFromPlayer(thisAuraID,client,false);
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	RemoveWards(client);
}


/* ****************************** OnW3PlayerAuraStateChanged ************************** */

public OnW3PlayerAuraStateChanged(client,aura,bool:inAura,level)
{
	if(aura==thisAuraID && ValidPlayer(client,true,true) && level>0)
	{
		if(!W3HasImmunity(client,Immunity_Skills))
		{
			if(inAura==true)
			{
				War3_SetBuff(client,fSlow,thisRaceID,0.50);
				CreateTimer(UnholyAura[level],RemoveSlow,client);
				// TF2_AddCondition(client, TFCond_MarkedForDeath,deathtime);
			}
			else if(inAura==false)
			{
				//TF2_RemoveCondition(client, TFCond_MarkedForDeath);
				//TF2_AddCondition(client, TFCond_MarkedForDeath,deathtime);
			}
		}
		else
		{
//		PrintHintText(client,"%T","HolyShieldProtected",client);
		// non-translated:
		PrintHintText(client,"Holy Shield protected you from 'Unholy Aura'");
		}
	}
}

/* ***************************  RemoveSlow *************************************/

public Action:RemoveSlow(Handle:timer,any:client)
{
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
}

/* ***************************  OnUltimateCommand *************************************/

public OnUltimateCommand(client,race,bool:pressed)
{
	new userid=GetClientUserId(client);
	//War3_ChatMessage(client,"OnAbility");
	// SoulSwap +ability]
	if(War3_SkillNotInCooldown(client,thisRaceID,ULT_HEADLESS_HORSEMAN,true) && HeadlessHorseman[client][0]==0&&War3_GetRace(client)==thisRaceID && pressed && userid>1 && IsPlayerAlive(client))
	{
		new ability_level=War3_GetSkillLevel(client,thisRaceID,ULT_HEADLESS_HORSEMAN);
		if(ability_level>0)
		{
			if(!Silenced(client))
			{
				//Headless Horseman
				if(!SetTeleportEndPoint(client))
				{
					PrintToChat(client, "[SM] Could not find spawn point.");
				}
				if(GetEntityCount() >= GetMaxEntities()-32)
				{
					PrintToChat(client, "[SM] Entity limit is reached. Can't spawn anymore pumpkin lords.\nChange maps or try again later (maybe to many MVM Bots?)");
				}
				new entity = CreateEntityByName("headless_hatman");
				if(IsValidEntity(entity))
				{
					DispatchSpawn(entity);

					g_pos[2] -= 10.0;
					TeleportEntity(entity, g_pos, NULL_VECTOR, NULL_VECTOR);
					HeadlessHorseman[client][0]=1;
					HeadlessHorseman[client][1]=entity;
					//new userid = GetClientUserId(client);
					//CreateTimer(HeadlessHorseman_delay[ability_level],HeadlessHorseman_Disable,userid);
					SDKHook(entity,SDKHook_OnTakeDamage,SDK_Forwarded_TraceAttack);
					new Float:cooldown_Timer_delay=60.0+HeadlessHorseman_delay[ability_level];
					War3_CooldownMGR(client,cooldown_Timer_delay,thisRaceID,ULT_HEADLESS_HORSEMAN,true,true);
					CreateTimer(HeadlessHorseman_delay[ability_level],HeadlessHorseman_Disable,userid);

					new String:cName[64];
					GetClientName(client, cName, sizeof(cName));
					PrintCenterText(client, "%s summoned a Headless Horseman!", cName);
				}
			}
		}
	}
	/*else if(HeadlessHorseman[client][0]>0)
	{
		W3Hint(client,HINT_SKILL_STATUS,3.0,"You can must wait to summon another Headless Horseman.");
	} */
}

/* ***************************  OnAbilityCommand *************************************/

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
							PrintHintText(enemies,"For some reason your immune to the ability: 'Cursed!'");
					}
				}
				//PrintHintText(client,"%T","CursedEnemies",targetsfound);
				PrintHintText(client,"You Cursed %i enemies!",targetsfound);
				War3_CooldownMGR(client,20.0,thisRaceID,ABILILTY_FAN,true,true);
				//EmitSoundToAll(ultsnd,victim);
				}
		}
	}
		//target=War3_GetTargetInViewCone(client,distance,false,23.0,SkillFilter);
		//if(ValidPlayer(target,true))
	// ability 2     ABILITY_BLIND
	if(ability==2&&!Silenced(client)&& pressed && War3_SkillNotInCooldown(client,thisRaceID,ABILITY_PURPLE_WARD,true))
	{
		//War3_ChatMessage(client,"Ability2");
		new skill_level=War3_GetSkillLevel(client,thisRaceID,ABILITY_PURPLE_WARD);
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
						if(!IsValidEntity(ent)) continue;
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

SetTeleportEndPoint(client)
{
	decl Float:vAngles[3];
	decl Float:vOrigin[3];
	decl Float:vBuffer[3];
	decl Float:vStart[3];
	decl Float:Distance;

	GetClientEyePosition(client,vOrigin);
	GetClientEyeAngles(client, vAngles);

	//get endpoint for teleport
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(vStart, trace);
		GetVectorDistance(vOrigin, vStart, false);
		Distance = -35.0;
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		g_pos[0] = vStart[0] + (vBuffer[0]*Distance);
		g_pos[1] = vStart[1] + (vBuffer[1]*Distance);
		g_pos[2] = vStart[2] + (vBuffer[2]*Distance);
	}
	else
	{
		CloseHandle(trace);
		return false;
	}

	CloseHandle(trace);
	return true;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask)
{
	return entity > GetMaxClients() || !entity;
}

public OnClientPutInServer(client){
	SDKHook(client,SDKHook_OnTakeDamage,SDK_Forwarded_TraceAttack_client);
}
public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_OnTakeDamage,SDK_Forwarded_TraceAttack_client);
}

/*
public OnEntityDestroyed(entity) {
	new String:eName[64];
	GetEntityClassname(entity, eName, sizeof(eName));

	if(StrEqual(eName,"headless_hatman"))
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(HeadlessHorseman[i][1]==entity)
			{
				DP("Entity Removed from array (OnEntityDestroyed)");
				HeadlessHorseman[i][0]=0;
				HeadlessHorseman[i][1]=0;
			}
		}
	}
} */

public Action:SDK_Forwarded_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(IsValidEntity(victim))    //||!ValidPlayer(victim))
	{
		new String:vName[64];
		GetEntityClassname(victim, vName, sizeof(vName));
		if(ValidPlayer(attacker,true))
		{
			// if attacker is on red team and is shooting at headless horseman.. do zero damage.
			if(GetClientTeam(attacker)==_:TFTeam_Red&&(StrEqual(vName,"headless_hatman")))
			{
				//DP("Red team is attacking horseman.");
				damage=0.0;
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action:SDK_Forwarded_TraceAttack_client(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(IsValidEntity(attacker))    //||!ValidPlayer(victim))
	{
		new String:aName[64];
		GetEntityClassname(attacker, aName, sizeof(aName));

		// If Headless attacks red player, then stun the headless
		if(ValidPlayer(victim,true))
		{
			if(GetClientTeam(victim)==_:TFTeam_Red&&(StrEqual(aName,"headless_hatman")))
			{
				damage=0.0;
				//DP("Victim is red team and headless hatman is attacker.");
				if(IsValidEntity(attacker))
				{
					AcceptEntityInput(attacker, "kill");
				}
				return Plugin_Changed;
			}
		}
	}
	return Plugin_Continue;
}

public Action:HeadlessHorseman_Disable(Handle:timer,any:userid)
{
	new client=GetClientOfUserId(userid);

	if(IsValidEntity(HeadlessHorseman[client][1]))
	{
		AcceptEntityInput(HeadlessHorseman[client][1], "kill");
	}
	SDKUnhook(HeadlessHorseman[client][1],SDKHook_OnTakeDamage,SDK_Forwarded_TraceAttack);

	HeadlessHorseman[client][0]=0;
	HeadlessHorseman[client][1]=0;
}

/*
public Action:HeadlessHorsemanTimer(Handle:timer,any:userid)
{
	for(new i = 0; i <= MaxClients; i++)
	{
		if(HeadlessHorseman[i][0]>0)
		{
			if(IsValidEntity(HeadlessHorseman[i][1]))
			{
				DP("Remove this function");
				//SetVariantString("player");
				//AcceptEntityInput(HeadlessHorseman[i][1], "ForgetEntity");
			}
		}
	}
}
  */

/* ***************************  WARDS *************************************/
/* ***************************  CreateWard *************************************/

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


/* ***************************  RemoveWards *************************************/

// If we create a vortex that removes 1 vortex per player whom enters..??
// may have to revise this function
public RemoveWards(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
	InitPassiveSkills(client);
	TurtledWard[client]=false;
	TurtledOwnerWard[client][client]=0;
	}

	for(new i=0;i<MAXWARDS;i++)
	{
		if(WardOwner[i]==client)    // i == owner
		{
		WardOwner[i]=0;

		for(new z=0;z<MAXPLAYERSCUSTOM;z++)  // z == client check
			{
			if(TurtledOwnerWard[i][z]==1)
				{
				if (ValidPlayer(z))
					{
						if(War3_GetRace(z)==thisRaceID)
						{
						InitPassiveSkills(z);
						TurtledWard[z]=false;
						TurtledOwnerWard[i][z]=0;
						}
						else
						{
						TurtledWard[z]=false;
						War3_SetBuff(z,fSlow,thisRaceID,1.0);
						War3_SetBuff(z,fMaxSpeed,thisRaceID,1.0);
						TurtledOwnerWard[i][z]=0;
						}
					}
				}

			//if player at location then remove buff
			// instead of maxwards use max players for the statment above..
			}
/*			if(War3_GetRace(i)==thisRaceID)
			{
			InitPassiveSkills(i);
			TurtledWard[i]=false;
			TurtledOwnerWard[i][i]=0;
			}
			else
			{
			TurtledWard[i]=false;
			War3_SetBuff(i,fSlow,thisRaceID,1.0);
			War3_SetBuff(i,fMaxSpeed,thisRaceID,1.0);
			TurtledOwnerWard[i][i]=0;
			}
*/

			//War3_SetBuff(i,fSlow,thisRaceID,1.0);
			//War3_SetBuff(i,fMaxSpeed,thisRaceID,1.0);
			//War3_SetBuff(i,bBashed,thisRaceID,false);
		}

	}
	CurrentWardCount[client]=0;
}

/* ***************************  CalcWards *************************************/

public Action:CalcWards(Handle:timer,any:userid)
{
	for(new i=0;i<=MaxClients;i++){
		flashedscreen[i]=false;
	}
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
				if(War3_GetRace(client)==thisRaceID)
					{
						InitPassiveSkills(client);
						TurtledWard[client]=false;
						TurtledOwnerWard[i][client]=0;
					}
				else
					{
						TurtledWard[client]=false;
						War3_SetBuff(client,fSlow,thisRaceID,1.0);
						War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
						TurtledOwnerWard[i][client]=0;
					}

				//War3_SetBuff(i,fSlow,thisRaceID,1.0);
				//War3_SetBuff(i,fMaxSpeed,thisRaceID,1.0);
			}
			else
			{
				WardEffectAndNoMovement(client,i);
			}
		}
	}
}

/* ***************************  WardEffectAndNoMovement *************************************/

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
						PrintCenterText(i,"%T","SlowedByAntiwards",i);
						//PrintCenterText(i,"Your being Slowed! QUICK -->> Open Chatbox and type: antiwards");
						//PrintToChat(i,"You've been walled! / Say Antiwards"); TurtledSpeed
						War3_SetBuff(i,fSlow,thisRaceID,TurtledSpeed[skilllevel_TurtledSpeedSkills]);
						TurtledWard[i]=true;
						TurtledOwnerWard[owner][i]=1;
						W3FlashScreen(i,DamageScreen);
					}
					/*	else
						{
							if(War3_GetRace(i)==thisRaceID)
							{
							InitPassiveSkills(i);
							TurtledWard[i]=false;
							}
							else
							{
							TurtledWard[i]=false;
							War3_SetBuff(i,fSlow,thisRaceID,1.0);
							War3_SetBuff(i,fMaxSpeed,thisRaceID,1.0);
							}
						} */
//					if(IsFakeClient(i) && W3Chance(0.10))
//						{
//						War3_SetBuff(i,fSlow2,thisRaceID,1.0);
//						War3_SetBuff(i,fMaxSpeed,thisRaceID,1.0);
//						}
						//SetEntityZHealth(i,new_hp);
					//VictimPos[2]+=65.0;
					//War3_TF_ParticleToClient(0, GetApparentTeam(i)==2?"particle_nemesis_red":"particle_nemesis_blue", VictimPos);
				}
			}     // TEMP TEMP TEMP  if not near a ward...
			else
			{    // Needs a timer to work correctly
				CreateTimer(1.0,Slow_Turtled_Disable,i);
/*					if(War3_GetRace(i)==thisRaceID)
					{
					InitPassiveSkills(i);
					TurtledWard[i]=false;
					TurtledOwnerWard[owner][i]=0;
					}
					else
					{
					TurtledWard[i]=false;
					War3_SetBuff(i,fSlow,thisRaceID,1.0);
					War3_SetBuff(i,fMaxSpeed,thisRaceID,1.0);
					TurtledOwnerWard[owner][i]=0;
					}*/
			}
		}
	}
}

/* ***************************  Slow_Turtled_Disable *************************************/

public Action:Slow_Turtled_Disable(Handle:timer, any:client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
	InitPassiveSkills(client);
	TurtledWard[client]=false;
	//TurtledOwnerWard[owner][client]=0;
	}
	else
	{
	TurtledWard[client]=false;
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	//TurtledOwnerWard[owner][i]=0;
	}
}

/* ***************************  OnItemPurchase *************************************/

public OnItemPurchase(client,item)
{
 	new itemid = War3_GetItemIdByShortname("antiward");
	if(item==itemid&&ValidPlayer(client))
	{
		if(War3_GetRace(client)==thisRaceID)
		{
			InitPassiveSkills(client);
			TurtledWard[client]=false;
		}
		else
		{
			War3_SetBuff(client,fSlow,thisRaceID,1.0);
			War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
			TurtledWard[client]=false;
		}
	}
}

new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25,27,-27,30,-30};//,33,-33,40,-40};

/* ***************************  testhull *************************************/

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

/* ***************************  CanHitThis *************************************/

public bool:CanHitThis(entityhit, mask, any:data)
{
	if(entityhit == data )
	{// Check if the TraceRay hit the itself.
		return false; // Don't allow self to be hit, skip this result
	}
	if(ValidPlayer(entityhit)&&ValidPlayer(data)&&War3_GetGame()==Game_TF&&GetClientTeam(entityhit)==GetClientTeam(data)){
		return false; //skip result, prend this space is not taken cuz they on same team
	}
	return true; // It didn't hit itself
}


//					new String:tName[64];
//					new String:eName[64];
//					GetEntityClassname(client, eName, sizeof(eName));
//					Format(tName, sizeof(tName), "%s D_LI", eName);

//					DP("eName %s",eName);
//					DP("tName %s",tName);

					//SetVariantString("D_LI");
					//AcceptEntityInput(entity, "SetRelationship");

					//SetVariantInt(1);
					//AcceptEntityInput(entity, "SetRelationship");
					//DispatchKeyValue(entity, "Sleep State", "3");

					//SetVariantString("player D_LI 1");
					//SetVariantString("D_FR");
					//SetVariantInt(100);
					//AcceptEntityInput(entity, "SetRelationship");

					//SetEntityFlags(entity, 16384);
