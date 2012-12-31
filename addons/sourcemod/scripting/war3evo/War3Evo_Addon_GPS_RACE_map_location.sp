#include "../DO NOT COMPILE, only used during holidays for TF2 only"
/*
	You can compile this code when you need to use it for a special event.
	Disabling it as it is not default enabled.
*/


/* ========================================================================== */
/*                                                                            */
/*   War3Evo_Addon_GPS_RACE_map_location.sp                                   */
/*   (c) 2012 El Diablo                                                      */
/*                                                                            */
/*   Gives you noclip with a press of a button to toggle on / off          */
/*   another button allows you to get your location.                          */
/* ========================================================================== */

#pragma semicolon 1    ///WE RECOMMEND THE SEMICOLON
#pragma tabsize 0     // doesn't mess with how you format your lines

//#include <clients>
//#include "W3SIncs/War3Source_Effects"
//#include "W3SIncs/sdkhooks"
#include "W3SIncs/War3Source_Interface"
//#include <halflife>

public W3ONLY(){} //unload this?

public Plugin:myinfo =
{
	 name = "GPS",
	 author = "El Diablo",
	 description = "Meet the GPS!",
	 version = "1.03",
	 url = "http://www.war3evo.com"
};

new thisRaceID;
new ABILITY_LOCATION,SKILL_MODE;

new bool:noclipmode[66];

//new Handle:teleport_x,Handle:teleport_y,Handle:teleport_z;

//new String:CurrentMap_tf2[64];

/* ***************************  OnWar3LoadRaceOrItemOrdered2 *************************************/

public OnWar3LoadRaceOrItemOrdered2(num)
{
	if(num==1)
	{
     thisRaceID=War3_CreateNewRace("GPS","gps");
     //SKILL_SPEED=War3_AddRaceSkill(thisRaceID,"Super Fast",
     //"Sonic Speed Buff",false,1);
     SKILL_MODE=War3_AddRaceSkill(thisRaceID,"Noclipflymode",
     "Noclip flymode",false,0);
     ABILITY_LOCATION=War3_AddRaceSkill(thisRaceID,"My current location",
     "(+ability) My location",false,0);
//DO NOT FORGET THE END!!!
     War3_CreateRaceEnd(thisRaceID);
  }
}

/* ***************************  OnRaceChanged *************************************/

public OnRaceChanged(client,oldrace,newrace)
{
    if(newrace==thisRaceID)
    {
       //War3_SetBuff(client,bFlyMode,oldrace,false);  //bNoMoveMode
       //War3_SetBuff(client,bNoClipMode,oldrace,false);
       //War3_SetBuff(client,fSlow,thisRaceID,0.0);
       War3_SetBuff(client,fMaxSpeed,thisRaceID,3.0);
    }
    else
    {
       //ar3_SetBuff(client,fSlow,thisRaceID,0.0);
       War3_SetBuff(client,fMaxSpeed,thisRaceID,1.00);
    }
}


/* ***************************  OnPluginStart *************************************/

//public OnPluginStart()
//{
//Create race specific Cvars here
//	teleport_x=CreateConVar("war3_location_x","0","X location");
//	teleport_y=CreateConVar("war3_location_y","0","Y location");
//	teleport_z=CreateConVar("war3_location_z","0","Z location");

//Hook events here!!!!
  //HookEvent("player_spawn",PlayerSpawnEvent);

//  HookConVarChange(teleport_x, W3CvarTele1);
//  HookConVarChange(teleport_y, W3CvarTele2);
//  HookConVarChange(teleport_z, W3CvarTele3);

//}

//public OnMapStart()
//{
  //GetCurrentMap(CurrentMap_tf2,64);

/*    for(new i;i<Maximum_Ki_array;i++)
    {
     Ki[i]=0.0;
    }*/

//}

/* ****************************** W3CvarCooldownHandler **************************

public W3CvarTele1(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new Float:value = StringToFloat(newValue);
    SetConVarFloat(teleport_x,value);
}
 ****************************** W3CvarCooldownHandler **************************

public W3CvarTele2(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new Float:value = StringToFloat(newValue);
    SetConVarFloat(teleport_y,value);
}
 ****************************** W3CvarCooldownHandler **************************

public W3CvarTele3(Handle:cvar, const String:oldValue[], const String:newValue[])
{
	new Float:value = StringToFloat(newValue);
    SetConVarFloat(teleport_z,value);
}

 ****************************** OnUltimateCommand ************************** */

public OnAbilityCommand(client,ability,bool:pressed)
{
	//new userid=GetClientUserId(client);
	if(War3_GetRace(client)==thisRaceID && pressed && ability==0 && ValidPlayer(client))
	{
		new Float:vector_info[3];
		new Float:ang_info[3];
		GetClientAbsOrigin(client, vector_info);
		GetClientAbsAngles(client, ang_info);
		decl String:mapname[128];
		GetCurrentMap(mapname,sizeof(mapname));
		PrintToChatAll("Map Name: %s",mapname);
		PrintToChatAll("Vector..x:%f y:%f z:%f",vector_info[0],vector_info[1],vector_info[2]);
		PrintToChatAll("Angle..x:%f y:%f z:%f",ang_info[0],ang_info[1],ang_info[2]);
		PrintToChatAll("---------------------------------------------------------");
	}
	if(War3_GetRace(client)==thisRaceID && pressed && ability==2 && ValidPlayer(client))
	{
		if(noclipmode[client]==false)
		{
			War3_SetBuff(client,bNoClipMode,thisRaceID,true);
			War3_SetBuff(client,bFlyMode,thisRaceID,true);
			PrintToChatAll("Noclip/Flymode on");
			noclipmode[client]=true;
		}
		else
		{
			War3_SetBuff(client,bNoClipMode,thisRaceID,false);
			War3_SetBuff(client,bFlyMode,thisRaceID,false);
			PrintToChatAll("Noclip/Flymode off");
			noclipmode[client]=false;
		}
	}
}


/*public PlayerSpawnEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	//new userid=GetEventInt(event,"userid");
//	new userteam=GetEventInt(event,"team");
	//new victim=GetClientOfUserId(userid);
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	//new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
    //War3_CooldownRemaining(client,raceid,skillNum);
    // War3_CooldownReset(client,raceid,skillNum);
   //War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar_SPAWN),thisRaceID,ULTIMATE_HANDS_OF_DEATH,false,_);
    if(client>0 && StrEqual(CurrentMap_tf2,"trade_unusual_a4_1",false))
       {
       if(GetClientTeam(client)==TEAM_RED) // red
            {
             new Float:VecPos[3];
             VecPos[0] = -1696.612426;
             VecPos[1] = -799.301818;
             VecPos[2] = 672.031250;
             new Float:AngPos[3];
             AngPos[0] = 0.000000;
             AngPos[1] = 97.048339;
             AngPos[2] = 0.0;
			 //new Float:Angles[3];
             //GetClientAbsAngles(client, Angles[3]);
			 //War3_CachedAngle(client,Angles);
			 //War3_CachedPosition(client,VecPos);

			 TeleportEntity(client, VecPos, AngPos, NULL_VECTOR);
            }
       if(GetClientTeam(client)==TEAM_BLUE) // blue
            {
             new Float:VecPos[3];
             VecPos[0] = -1750.257080;
             VecPos[1] = 1867.106323;
             VecPos[2] = 457.547241;
             new Float:AngPos[3];
             AngPos[0] = 0.000000;
             AngPos[1] = -91.548133;
             AngPos[2] = 0.0;

			 //new Float:Angles[3];
             //GetClientAbsAngles(client, Angles[3]);
			 //War3_CachedAngle(client,Angles);
			 //War3_CachedPosition(client,VecPos);

			 TeleportEntity(client, VecPos, AngPos, NULL_VECTOR);
            }
       }
      //PrintToChatAll("spawn");
      //SetEntityMoveType(client, MOVETYPE_WALK);
//      new TmpRaceID = War3_GetRace(client);
  //    W3ResetAllBuffRace(client,TmpRaceID);
      //War3_SetBuff(client,bBashed,TmpRaceID,false);  //bNoMoveMode

	//reset all buffs for each race and item
//	for(new buffindex=0;buffindex<MaxBuffLoopLimit;buffindex++)
//	{
//		ResetBuff(client,W3Buff:buffindex);
//	}

 }
 */


