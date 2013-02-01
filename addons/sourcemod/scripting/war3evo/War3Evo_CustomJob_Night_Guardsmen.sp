#define PLUGIN_VERSION "0.0.0.1"

#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON
#pragma tabsize 0     // doesn't mess with how you format your lines

#include <sourcemod>
//#include <clients>
//#include <sdktools_functions>
//#include <sdktools_sound>
//#include <sdktools_tempents>
//#include <sdktools_tempents_stocks>
//#include <tf2>
#include "W3SIncs/sdkhooks"
#include "W3SIncs/War3Source_Interface"
public W3ONLY(){} //unload this?

public Plugin:myinfo =
{
	 name = "Evil Race - Night Guardsmen",
	 author = "El Diablo (IDEA BY Axin)",
	 description = "This race is for defense for the evil side.",
	 version = "1.0",
	 url = "http://www.nguclan.com"
};

// Declare Global Variables
new Handle:ultCooldownCvar_SPAWN;
//new Handle:ultCooldownCvar;

new thisRaceID;
new SKILL_HEAVYEQUIPMENT,SKILL_NIGHT_GUARDS_HELM,ABILITY_PURPLE_WARD,SKILL_MAGIC_ARMOR,ULTIMATE_REINFORCE;

new String:helmSound0[]="physics/metal/metal_solid_impact_bullet1.wav";
new String:helmSound1[]="physics/metal/metal_solid_impact_bullet2.wav";
new String:helmSound2[]="physics/metal/metal_solid_impact_bullet3.wav";
new String:helmSound3[]="physics/metal/metal_solid_impact_bullet4.wav";


// Black Vortex Ward Specific
#define MAXWARDS 64*4 //on map LOL
#define WARDRADIUS 70 // was 70
// WARDHEAL WAS 4
//#define WARDHEAL 10
#define WARDBELOW -2.0 // player is 60 units tall about (6 feet)
//#define WARDABOVE 160.0
#define WARDABOVE 160.0
new CurrentWardCount[MAXPLAYERSCUSTOM];
new bool:TurtledWard[MAXPLAYERSCUSTOM];
new TurtledOwnerWard[MAXWARDS][MAXPLAYERSCUSTOM];
new WardStartingArr[]={0,1,2,3,4};
new Float:WardLocation[MAXWARDS][3];
new WardOwner[MAXWARDS];

// Effects
new BeamSprite,HaloSprite; //BloodSpray,BloodDrop; //

new bool:flashedscreen[MAXPLAYERSCUSTOM];

// skill 1
//"Have a 15/25/45/65 percent of Physical and Magical resistance.\nAlso reduces your speed by 60/50/40/30 percent.",false,4);
new Float:PhysicalResistance[5]={0.0,2.0,5.0,10.0,16.0};
new Float:MagicalResistance[5]={0.0,1.0,2.5,5.0,8.0};
new Float:SSpeed[5]={1.0,0.80,0.75,0.70,0.65};

// skill 2
new Float:NightGuardsHelmChance[5]={0.0,0.25,0.50,0.75,1.0};

// Ward
new Float:TurtledSpeed[5]={0.0,0.40,0.30,0.20,0.10};

// ultimat
new Float:NightGuardsUltimateReinforce[5]={0.0,1.0,2.0,3.0,4.0};
new Float:NightGuardsUltimateReducedReinforce[5]={0.0,5.0,4.0,3.0,2.0};
new Float:UltimateResistance[5]={0.0,1.0,2.0,3.0,4.0};
new Float:UltimateReducedResistance[5]={0.0,0.5,1.0,1.5,2.0};


// Reduced damage from backstab
new Float:ReducedSpyDamage[5]={1000.0,150.0,125.0,100.0,75.0};
new Float:SlowSpeedDuringFireChance[5]={0.0,0.35,0.30,0.25,0.20};
new Float:IncreasedDamageWhileShooting[5]={0.0,0.05,0.10,0.15,0.20};


public OnPluginStart()
{
	CreateConVar("war3evo_NightGuardsmen",PLUGIN_VERSION,"War3evo Night Guardsmen",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	War3_PrecacheSound(helmSound0);
	War3_PrecacheSound(helmSound1);
	War3_PrecacheSound(helmSound2);
	War3_PrecacheSound(helmSound3);

// Create HUD For displaying Total KI
	//HudMessage = CreateHudSynchronizer();
//Create race specific Cvars here
	ultCooldownCvar_SPAWN=CreateConVar("war3_nightguard_ult_cooldown","20",
     "Night Guardsmen Ultimate Cooldown.");
	//ultCooldownCvar=CreateConVar("war3_nightguard_ult_cooldown","20",
     //"Cooldown");
//	KI_MAX=CreateConVar("war3_Trillin_max_Ki","100",
//     "The Maximum amount of Ki Trillin can have total.",0,true,0.0,false);

//Hook events here!!!!
//	HookEvent("player_hurt",PlayerHurtEvent);
  //HookEvent("player_healed",PlayerHealEvent);
	HookConVarChange(ultCooldownCvar_SPAWN, W3CvarCooldownHandler);
	CreateTimer(0.1,CalcWards,_,TIMER_REPEAT);

}
new totalChecks;   // dont use int:totalChecks; gave tagmismatch
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
    //CreateTimer(1.0,Timer_Meditate,_,TIMER_REPEAT);
    //precaches..
    //War3_PrecacheSound(sfsound);
    //HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
    //FireSprite=PrecacheModel("effects/fire_embers1.vmt");
	BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
	HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");

    //for(new i;i<Maximum_Players_array;i++)
    //{
     //SONG[i]=0.0;
    //}
}
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

//public OnWar3LoadRaceOrItemOrdered2(num)
public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==81)
	{
		thisRaceID=War3_CreateNewRace("Night Guardsmen","nightguard");
		SKILL_HEAVYEQUIPMENT=War3_AddRaceSkill(thisRaceID,"Heavy Armor",
		"Up to 48.9% percent of Physical resistance and up to 32.4% Magical resistance.\nAlso reduces your speed by 90/80/70/60 percent.\nMax level gives you shopmenu item plates.",false,4);
		SKILL_NIGHT_GUARDS_HELM=War3_AddRaceSkill(thisRaceID,"Night Guard's Helm",
		"25/50/75/100% Immunity to Headshots",false,4);
		SKILL_MAGIC_ARMOR=War3_AddRaceSkill(thisRaceID,"Night Guard's Eqiupment",
		"Spys do less damage per level on your back.\nWhen firing you slow down by 35%/30%/25%/20% & 5%/10%/15%/20% increased damage.",false,4);
		ABILITY_PURPLE_WARD=War3_AddRaceSkill(thisRaceID,"Turtled Ward",
		"Turtles your enemies! (Slows down enemies greatly)\nRequires 4 skill levels to use.",false,4);
		ULTIMATE_REINFORCE=War3_AddRaceSkill(thisRaceID,"Holding Ground",
		"Buffs physical defense up to 54.5% and immunity to crits for 1/2/3/4 seconds,\nthen up to 27.2% continued resistance for 5/4/3/2 seconds.",true,4);
		W3SkillCooldownOnSpawn( thisRaceID, ULTIMATE_REINFORCE,
		GetConVarFloat(ultCooldownCvar_SPAWN) );
//DO NOT FORGET THE END!!!
		War3_CreateRaceEnd(thisRaceID);
		War3_SetDependency(thisRaceID, SKILL_NIGHT_GUARDS_HELM, SKILL_HEAVYEQUIPMENT, 4);
		War3_SetDependency(thisRaceID, SKILL_MAGIC_ARMOR, SKILL_NIGHT_GUARDS_HELM, 4);
	}
}

public W3CvarCooldownHandler(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new Float:value = StringToFloat(newValue);
	if(value>0.0)
	W3SkillCooldownOnSpawn( thisRaceID, ULTIMATE_REINFORCE, value );
}

public OnSkillLevelChanged(client,race,skill,newskilllevel)
{
	InitPassiveSkills(client);
    /*if(race==thisRaceID)
    {
      CloseHandle(SONG_TIMER_HANDLE);
      SONG_TIMER_HANDLE=CreateTimer(song_timer_seconds[newskilllevel],Timer_Song,_,TIMER_REPEAT);
    } */
}

public InitPassiveSkills(client)
{
	if(War3_GetRace(client)==thisRaceID)
	{
		new skilllevel_InitPassiveSkills=War3_GetSkillLevel(client,thisRaceID,SKILL_HEAVYEQUIPMENT);
		War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
		War3_SetBuff(client,fSlow,thisRaceID,SSpeed[skilllevel_InitPassiveSkills]);
		War3_SetBuff(client,fArmorPhysical,thisRaceID,PhysicalResistance[skilllevel_InitPassiveSkills]);
		War3_SetBuff(client,fArmorMagic,thisRaceID,MagicalResistance[skilllevel_InitPassiveSkills]);
	}
}

public RemovePassiveSkills(client)
{
	War3_SetBuff(client,fSlow,thisRaceID,1.0);
	War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	War3_SetBuff(client,fArmorPhysical,thisRaceID,0.0);
	War3_SetBuff(client,fArmorMagic,thisRaceID,0.0);
	War3_SetBuff(client,fDamageModifier,thisRaceID,0.0);
}

//public OnUltimateCommand(client,ability,bool:pressed)
//{
/* ***************************  ability *************************************/

public OnAbilityCommand(client,ability,bool:pressed)
{
	//if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
    if(War3_GetRace(client)==thisRaceID && ability==0 && pressed && IsPlayerAlive(client))
	{
		new skill_level=War3_GetSkillLevel(client,thisRaceID,ABILITY_PURPLE_WARD);
		if(skill_level>0)
		{
			if (!wardCheck(client)) 
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
}

public OnWar3EventSpawn(client)
{
	RemoveWards(client);
	//War3_SetBuff(client,bBashed,thisRaceID,false);
}

// Wards
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

// If we create a vortex that removes 1 vortex per player whom enters..??
// may have to revise this function
public RemoveWards(client)
{
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

// This is where you need to create the Black Vortex ward
// EFFECTs !
// Find map positions for every approved Steam map,
// The mark those locations for each map in an array or something
//
// Need to setup some sounds when a player walks thru this vortex!
//
// Thought about vortexs disappearing once 1 player enters 1 vortex.
//
//healing wards
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
						PrintCenterText(i,"Your being Turtled! QUICK -->> Open Chatbox and type: antiwards");
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
				new userid=GetClientUserId(i);
				CreateTimer(1.0,Slow_Turtled_Disable,userid);
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

public Action:Slow_Turtled_Disable(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
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

//public OnItemLost(client,item){ //deactivate passives , client may have disconnected
//	if(item==shopItem[SOCK])
//	{


public OnWar3EventDeath(victim)
{
	if(TurtledWard[victim])
	{
		if(War3_GetRace(victim)==thisRaceID)
		{
			InitPassiveSkills(victim);
			TurtledWard[victim]=false;
		}
		else if(ValidPlayer(victim))
		{
			War3_SetBuff(victim,fSlow,thisRaceID,1.0);
			War3_SetBuff(victim,fMaxSpeed,thisRaceID,1.0);
			TurtledWard[victim]=false;
		}
	// Check to see if owner of ward died.. then remove speed reduction
/*	new owner = victim;
 	for(new i=0;i<MAXPLAYERSCUSTOM;i++) // victim is i
	{
		if(TurtledOwnerWard[owner][i]==1) // If owner died and victim has turtled -remove it.
		{
			if(ValidPlayer(i))
			{
				if(War3_GetRace(i)==thisRaceID)
				{
					InitPassiveSkills(i);
					TurtledWard[i]=false;
					TurtledOwnerWard[owner][i]=0;  // Reset victim #
				}
				else
				{
					War3_SetBuff(i,fSlow,thisRaceID,1.0);
					War3_SetBuff(i,fMaxSpeed,thisRaceID,1.0);
					TurtledWard[i]=false;
					TurtledOwnerWard[owner][i]=0;  // Reset victim #
				}
			}
		}
	}
			if(War3_GetRace(victim)==thisRaceID&&ValidPlayer(victim))
			{
				InitPassiveSkills(victim);
				TurtledWard[victim]=false;
			}
			else
			{
				War3_SetBuff(victim,fSlow,thisRaceID,1.0);
				War3_SetBuff(victim,fMaxSpeed,thisRaceID,1.0);
				TurtledWard[victim]=false;
			}*/
	}
}

// Night Guardsman Helm
public OnClientPutInServer(client){
	SDKHook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
}
public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(War3_GetRace(client)==thisRaceID && (buttons & IN_ATTACK) && War3_SkillNotInCooldown(client,thisRaceID,SKILL_MAGIC_ARMOR,false))
	{
	new String:pWeapon[64];
	GetClientWeapon(client, pWeapon, 64);
	if(!IsEquipmentMelee(pWeapon))
		{
			new skilllevel=War3_GetSkillLevel(client,thisRaceID,SKILL_MAGIC_ARMOR);
			if(skilllevel>0)
			{
				War3_SetBuff(client,fSlow,thisRaceID,SlowSpeedDuringFireChance[skilllevel]);
				War3_SetBuff(client,fDamageModifier,thisRaceID,IncreasedDamageWhileShooting[skilllevel]);
				CreateTimer(1.5,Disable_Slowspeed,GetClientUserId(client));
				War3_CooldownMGR(client,1.5,thisRaceID,SKILL_MAGIC_ARMOR,true,false);
				return Plugin_Continue;
			}
		}
	}
	return Plugin_Continue;
}

public Action:SDK_Forwarded_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{

	if(War3_GetRace(victim)==thisRaceID)
	{
		new Oil_item = War3_GetItemIdByShortname("oil");
		new Owns_item = War3_GetOwnsItem(attacker,Oil_item);
/*	if(War3_GetRace(victim)==thisRaceID||War3_GetRace(attacker)==thisRaceID)
 	{
    PrintToChatAll("inflictor: %i",inflictor);
    PrintToChatAll("damagetype: %i",damagetype);
    PrintToChatAll("hitbox: %i",hitbox);
    PrintToChatAll("hitgroup: %i",hitgroup);
	damage=0.0;
	}*/
    //PrintToChatAll("Oil_item: %i",Oil_item);
    //PrintToChatAll("Owns_item: %i",Owns_item);
						//SKILL_MAGIC_ARMOR //
		new skilllevel_PassiveSkills=War3_GetSkillLevel(victim,thisRaceID,SKILL_NIGHT_GUARDS_HELM);
		new skilllevel_MagicArmorPassiveSkills=War3_GetSkillLevel(victim,thisRaceID,SKILL_MAGIC_ARMOR);

		//TF2_GetPlayerClass(attacker)==TFClass_Spy
			new String:spyweapon[64];
			if(ValidPlayer(attacker,true,true))
			{
				GetClientWeapon( attacker, spyweapon , 64);
			}
			else
			{
				spyweapon = "";
			}
			//StrEqual( wpnstr, "weapon_knife" )
			//if(!W3HasImmunity(attacker,Immunity_Skills)&&skilllevel_MagicArmorPassiveSkills>0&&War3_GetRace(victim)==thisRaceID&&TF2_GetPlayerClass(attacker)==TFClass_Spy&&War3_Chance(NightGuardsHelmChance[skilllevel_PassiveSkills])&&damagetype==135270528&&!Perplexed(victim)){
			if((Owns_item!=1)&&StrEqual( spyweapon, "tf_weapon_knife" )&&!W3HasImmunity(attacker,Immunity_Skills)&&skilllevel_MagicArmorPassiveSkills>0&&(damagetype==135270528||damagetype==134221952)&&!Perplexed(victim))
			//if(!W3HasImmunity(attacker,Immunity_Skills)&&skilllevel_MagicArmorPassiveSkills>0&&!Perplexed(victim))
			{
				//DP("weapon %s",spyweapon);
				//DP("damagetype %i hitbox %i hitgroup %i",damagetype,hitbox,hitgroup);
				damage=ReducedSpyDamage[skilllevel_MagicArmorPassiveSkills];
				new random = GetRandomInt(0,3);
				if(random==0){
					EmitSoundToAll(helmSound0,victim);
				}else if(random==1){
					EmitSoundToAll(helmSound1,victim);
				}else if(random==2){
					EmitSoundToAll(helmSound2,victim);
				}else{
					EmitSoundToAll(helmSound3,victim);
				}
				W3Hint(attacker,HINT_SKILL_STATUS,5.0,"Night Guardsmen Armor is really strong! Keep Hitting!");
				W3Hint(victim,HINT_SKILL_STATUS,5.0,"Spy Backstab Damage Reduction - %i damage to you per hit.",RoundToNearest(damage));
				return Plugin_Changed;
			}

		// Helm protection
		if(skilllevel_PassiveSkills>0&&(Owns_item!=1)&&War3_Chance(NightGuardsHelmChance[skilllevel_PassiveSkills])&&hitgroup==1&&!Perplexed(victim))
		{
			if(!W3HasImmunity(attacker,Immunity_Skills))
			{
				damage=0.0;
				new random = GetRandomInt(0,3);
				if(random==0){
					EmitSoundToAll(helmSound0,victim);
				}else if(random==1){
					EmitSoundToAll(helmSound1,victim);
				}else if(random==2){
					EmitSoundToAll(helmSound2,victim);
				}else{
					EmitSoundToAll(helmSound3,victim);
				}
				if(War3_GetGame()==TF)
				{
					W3FlashScreen(victim,RGBA_COLOR_BLACK);
					decl Float:pos[3];
					GetClientEyePosition(victim, pos);
					pos[2] += 4.0;
					War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
				}
				return Plugin_Changed;
			}
		}

	// PLATES
		new skill=War3_GetSkillLevel(victim,thisRaceID,SKILL_HEAVYEQUIPMENT);
		if((skill==4)&&(Owns_item!=1)&&((hitgroup==2&&(hitbox==5||hitbox==4))||(hitgroup==3&&hitbox==3))&&!Perplexed(victim))
		{
			damage=0.0;
			new random = GetRandomInt(0,3);
			if(random==0){
				EmitSoundToAll(helmSound0,victim);
			}else if(random==1){
				EmitSoundToAll(helmSound1,victim);
			}else if(random==2){
				EmitSoundToAll(helmSound2,victim);
			}else{
				EmitSoundToAll(helmSound3,victim);
			}
			if(War3_GetGame()==TF)
			{
				W3FlashScreen(victim,RGBA_COLOR_WHITE);
				decl Float:pos[3];
				GetClientEyePosition(victim, pos);
				pos[2] += 4.0;
				War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
			}
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

//

public OnUltimateCommand(client,race,bool:pressed)
{
	new userid=GetClientUserId(client);
	if(race==thisRaceID && pressed && userid>1 && IsPlayerAlive(client) && !Silenced(client))
	{
		new ult_level=War3_GetSkillLevel(client,race,ULTIMATE_REINFORCE);
		if(ult_level>0)
		{

			if(War3_SkillNotInCooldown(client,thisRaceID,ULTIMATE_REINFORCE,true)) //not in the 0.2 second delay when we check stuck via moving
			{
				new Float:cooldown=GetConVarFloat(ultCooldownCvar_SPAWN);
				new skilllevel_Ultimate=War3_GetSkillLevel(client,thisRaceID,ULTIMATE_REINFORCE);
				new skilllevel_PassiveSkills=War3_GetSkillLevel(client,thisRaceID,SKILL_HEAVYEQUIPMENT);
				War3_SetBuff(client,fArmorPhysical,thisRaceID,PhysicalResistance[skilllevel_PassiveSkills]+UltimateResistance[skilllevel_Ultimate]);
				//War3_SetBuff(client,fArmorMagic,thisRaceID,MagicalResistance[skilllevel_PassiveSkills]+UltimateResistance[skilllevel_Ultimate]);

				TF2_AddCondition(client,TFCond_DefenseBuffed,NightGuardsUltimateReinforce[skilllevel_Ultimate]);

				//native  W3Hint(client,W3HintPriority:type=HINT_LOWEST,Float:duration=5.0,String:format[],any:...);
				W3Hint(client,HINT_SKILL_STATUS,(NightGuardsUltimateReinforce[skilllevel_Ultimate]-1.0),"REINFORCED ENABLED!");
				War3_CooldownMGR(client,cooldown,thisRaceID,ULTIMATE_REINFORCE,_,_);
				new useridX=GetClientUserId(client);
				CreateTimer(NightGuardsUltimateReinforce[skilllevel_Ultimate],Timer_Disable_Reinforce,useridX);
			}
		}
		else
		{
			W3MsgUltNotLeveled(client);

		}
	}
}

public Action:Timer_Disable_Reinforce(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	W3Hint(client,HINT_SKILL_STATUS,3.0,"REINFORCED REDUCING!");

	new skilllevel_Ultimate=War3_GetSkillLevel(client,thisRaceID,ULTIMATE_REINFORCE);
	new skilllevel_PassiveSkills=War3_GetSkillLevel(client,thisRaceID,SKILL_HEAVYEQUIPMENT);
	War3_SetBuff(client,fArmorPhysical,thisRaceID,PhysicalResistance[skilllevel_PassiveSkills]+UltimateReducedResistance[skilllevel_Ultimate]);
	//War3_SetBuff(client,fArmorMagic,thisRaceID,MagicalResistance[skilllevel_PassiveSkills]+UltimateResistance[skilllevel_Ultimate]);

	TF2_AddCondition(client,TFCond_DefenseBuffed,NightGuardsUltimateReducedReinforce[skilllevel_Ultimate]);

	CreateTimer(NightGuardsUltimateReducedReinforce[skilllevel_Ultimate],Timer_Disable_ReducedReinforce,userid);

	//InitPassiveSkills(client);
}

public Action:Timer_Disable_ReducedReinforce(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	W3Hint(client,HINT_SKILL_STATUS,5.0,"REINFORCED DISABLED!");
	InitPassiveSkills(client);
}



public Action:Disable_Slowspeed(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	if(ValidPlayer(client))
	{
		new skilllevel_InitPassiveSkills=War3_GetSkillLevel(client,thisRaceID,SKILL_HEAVYEQUIPMENT);
		War3_SetBuff(client,fSlow,thisRaceID,SSpeed[skilllevel_InitPassiveSkills]);
		War3_SetBuff(client,fDamageModifier,thisRaceID,0.0);
		//War3_SetBuff(client,fMaxSpeed,thisRaceID,1.0);
	}
}

stock bool:IsEquipmentMelee(const String:weapon[])
{
	return (StrEqual(weapon,"tf_weapon_knife") ||
	StrEqual(weapon,"tf_weapon_shovel") ||
	StrEqual(weapon,"tf_weapon_wrench") ||
	StrEqual(weapon,"tf_weapon_bat") ||
	StrEqual(weapon,"tf_weapon_bat_wood") ||
	StrEqual(weapon,"tf_weapon_bonesaw") ||
	StrEqual(weapon,"tf_weapon_bottle") ||
	StrEqual(weapon,"tf_weapon_club") ||
	StrEqual(weapon,"tf_weapon_fireaxe") ||
	StrEqual(weapon,"tf_weapon_fists") ||
	StrEqual(weapon,"tf_weapon_sword"));
}
