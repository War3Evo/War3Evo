#define PLUGIN_VERSION "0.0.0.1 (1/30/2013) 4:40AM EST"
/* ============================================================================ */
/*										                                        */
/*   naix.sp									                                */
/*   (c) 2009 Stinkyfax								                            */
/*										                                        */
/*										                                        */
/* ============================================================================	*/


#include <sourcemod>
#include <sdktools_functions>	//For teleport
#include <sdktools_sound>		//For sound effect
#include "W3SIncs/War3Source_Interface"
public W3ONLY(){} //unload this?

// Colors
#define COLOR_DEFAULT 0x01
#define COLOR_LIGHTGREEN 0x03
#define COLOR_GREEN 0x04 // DOD = Red //kinda already defiend in war3 interface

//Skills Settings
 
new Float:HPPercentHealPerKill[5] = { 0.0,0.05,  0.10,  0.15,  0.20 }; //SKILL_INFEST settings
//Skill 1_1 really has 5 settings, so it's not a mistake
new HPIncrease[5]       = { 0, 10, 20, 30, 40 };     //Increases Maximum health

new Float:feastPercent[5] = { 0.0, 0.04,  0.06,  0.08,  0.10 };   //Feast ratio (leech based on current victim hp


new Float:RageAttackSpeed[5] = {1.0, 1.15,  1.25,  1.3334,  1.4001 };   //Rage Attack Rate
new Float:RageDuration[5] = {0.0, 3.0,  4.0,   5.0,  6.0 };   //Rage duration

new bool:bDucking[MAXPLAYERSCUSTOM];
//End of skill Settings

new Handle:ultCooldownCvar;

new ClientTracer;
new Float:emptypos[3];
new Float:oldpos[MAXPLAYERSCUSTOM][3];
new Float:teleportpos[MAXPLAYERSCUSTOM][3];
new bool:inteleportcheck[MAXPLAYERSCUSTOM];


new thisRaceID, SKILL_INFEST, SKILL_BLOODBATH, SKILL_FEAST, ULT_RAGE;

new String:skill1snd[]="war3source/naix/predskill1.mp3";
new String:ultsnd[]="war3source/naix/predult.mp3";

public Plugin:myinfo = 
{
	name = "Race - Lifestealer",
	author = "Stinkyfax and Ownz (DarkEnergy)",
	description = "N'aix - the embodiment of lust and greed,\nbent on stealing the life of every living creature he encounters.",
	version = "1.0",
	url = "war3source.com"//http://sugardas.lt/~jozh/
};



public OnPluginStart()
{
	CreateConVar("war3evo_Naix",PLUGIN_VERSION,"War3evo Job Naix",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ultCooldownCvar=CreateConVar("war3_naix_ult_cooldown","20","Cooldown time for Rage.");
	
	LoadTranslations("w3s.race.naix.phrases");
}
public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==120)
	{
		thisRaceID=War3_CreateNewRaceT("naix");


		SKILL_INFEST = War3_AddRaceSkillT(thisRaceID, "Infest", false,4,"5-20%");
		SKILL_BLOODBATH = War3_AddRaceSkillT(thisRaceID, "BloodBath", false,4,"10-40");
		SKILL_FEAST = War3_AddRaceSkillT(thisRaceID, "Feast", false,4,"4-10%");
		ULT_RAGE = War3_AddRaceSkillT(thisRaceID, "Rage", true,4,"15-40%","3-6");
		
		War3_CreateRaceEnd(thisRaceID);
	}
}

stock bool:IsOurRace(client) {

  return War3_GetRace(client)==thisRaceID;
}


public OnMapStart() { //some precaches
  //PrecacheSound("npc/zombie/zombie_pain2.wav");
	War3_PrecacheSound(skill1snd);
	War3_PrecacheSound(ultsnd);
}

public OnWar3EventPostHurt(victim,attacker,amount){
	if(ValidPlayer(victim)&&W3Chance(W3ChanceModifier(attacker))&&ValidPlayer(attacker)&&IsOurRace(attacker)&&victim!=attacker){
		new level = War3_GetSkillLevel(attacker, thisRaceID, SKILL_FEAST);
		if(level>0&&!Hexed(attacker,false)&&W3Chance(W3ChanceModifier(attacker))){
			if(!W3HasImmunity(victim,Immunity_Skills)){	
				new targetHp = GetClientHealth(victim)+amount;
				new restore = RoundToNearest( float(targetHp) * feastPercent[level] );

				War3HealToHP(attacker,restore,War3_GetMaxHP(attacker)+HPIncrease[War3_GetSkillLevel(attacker,thisRaceID,SKILL_BLOODBATH)]);
			
				PrintToConsole(attacker,"%T","Feast +{amount} HP",attacker,restore);
			}
		}
	}
}
public OnWar3EventSpawn(client){
	if(IsOurRace(client)){
		new level = War3_GetSkillLevel(client, thisRaceID, SKILL_BLOODBATH);
		if(level>=0){ //zeroth level passive
			War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,HPIncrease[level]);
			
			//War3_SetMaxHP(client, War3_GetMaxHP(client) + HPIncrease[level]);
			War3_ChatMessage(client,"%T","Your Maximum HP Increased by {amount}",client,HPIncrease[level]);    
		}
	}
}

public OnRaceChanged(client,oldrace,newrace)
{
	if(oldrace==thisRaceID){
		War3_SetBuff(client,iAdditionalMaxHealth,thisRaceID,0);
	}

}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	bDucking[client]=(buttons & IN_DUCK)?true:false;
	return Plugin_Continue;
}
//new Float:teleportTo[66][3];
public OnWar3EventDeath(victim,attacker){
	if(ValidPlayer(victim)&&ValidPlayer(attacker)&&IsOurRace(attacker)){
		new iSkillLevel=War3_GetSkillLevel(attacker,thisRaceID,SKILL_INFEST);
		if (iSkillLevel>0)
		{
			
			if (Hexed(attacker,false))  
			{	
				//decl String:name[50];
				//GetClientName(victim, name, sizeof(name));
				PrintHintText(attacker,"%T","Could not infest, you are hexed",attacker);
			}
			else if (W3HasImmunity(victim,Immunity_Skills))  
			{	
				//decl String:name[50];
				//GetClientName(victim, name, sizeof(name));
				PrintHintText(attacker,"%T","Could not infest, enemy immunity",attacker);
			}
			else{
				
				
				if(bDucking[attacker] && SkillAvailable(attacker,thisRaceID,SKILL_INFEST,true)){
					decl Float:location[3];
					GetClientAbsOrigin(victim,location);
					//.PrintToChatAll("%f %f %f",teleportTo[attacker][0],teleportTo[attacker][1],teleportTo[attacker][2]);
					War3_CachedPosition(victim,location);
					//PrintToChatAll("%f %f %f",teleportTo[attacker][0],teleportTo[attacker][1],teleportTo[attacker][2]);
					
					
					//CreateTimer(0.1,setlocation,attacker);
					
					//TeleportEntity(attacker, location, NULL_VECTOR, NULL_VECTOR);
					new bool:success = Teleport(attacker,location);
					if(success)
					{
						War3_CooldownMGR(attacker,10.0,thisRaceID,SKILL_INFEST,true,true);
					}
					//War3_CooldownMGR(attacker,10.0,thisRaceID,SKILL_INFEST,true,true);
				}
				
				new addHealth = RoundFloat(FloatMul(float(War3_GetMaxHP(victim)),HPPercentHealPerKill[iSkillLevel]));
				
				War3HealToHP(attacker,addHealth,War3_GetMaxHP(attacker)+HPIncrease[War3_GetSkillLevel(attacker,thisRaceID,SKILL_BLOODBATH)]);
				//Effects?
				//EmitAmbientSound("npc/zombie/zombie_pain2.wav",location);
				W3EmitSoundToAll(skill1snd,attacker);
			}
		}
	}
}
/*
public Action:setlocation(Handle:t,any:attacker){
	TeleportEntity(attacker, teleportTo[attacker], NULL_VECTOR, NULL_VECTOR);
}*/

public OnUltimateCommand(client,race,bool:pressed)
{
	if(race==thisRaceID && pressed && ValidPlayer(client,true))
	{
		new ultLevel=War3_GetSkillLevel(client,thisRaceID,ULT_RAGE);
		if(ultLevel>0)
		{
			//PrintToChatAll("level %d %f %f",ultLevel,RageDuration[ultLevel],RageAttackSpeed[ultLevel]);
			if(!Silenced(client)&&War3_SkillNotInCooldown(client,thisRaceID,ULT_RAGE,true ))
			{
				War3_ChatMessage(client,"%T","You rage for {amount} seconds, {amount} percent attack speed",client,
				COLOR_LIGHTGREEN, 
				RageDuration[ultLevel],
				COLOR_DEFAULT, 
				COLOR_LIGHTGREEN, 
				(RageAttackSpeed[ultLevel]-1.0)*100.0 ,
				COLOR_DEFAULT
				);

				War3_SetBuff(client,fAttackSpeed,thisRaceID,RageAttackSpeed[ultLevel]);
				
				CreateTimer(RageDuration[ultLevel],stopRage,client);
				W3EmitSoundToAll(ultsnd,client);
				W3EmitSoundToAll(ultsnd,client);
				War3_CooldownMGR(client,GetConVarFloat(ultCooldownCvar),thisRaceID,ULT_RAGE,_,_);
				
			}
			
			
		}
		else
		{
			PrintHintText(client,"%T","No Ultimate Leveled",client);
		}
	}
}
public Action:stopRage(Handle:t,any:client){
	War3_SetBuff(client,fAttackSpeed,thisRaceID,1.0);
	if(ValidPlayer(client,true)){
		PrintHintText(client,"%T","You are no longer in rage mode",client);
	}
}

//Teleportation


//bool:Teleport(client,Float:distance){
bool:Teleport(client,Float:endpos[3]){
	if(!inteleportcheck[client])
	{
		inteleportcheck[client]=false;
		new Float:angle[3];
		GetClientEyeAngles(client,angle);
		//new Float:endpos[3];
		new Float:startpos[3];
		GetClientEyePosition(client,startpos);
		//new Float:dir[3];
		//GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);

		//ScaleVector(dir, distance);

		//AddVectors(startpos, dir, endpos);

		GetClientAbsOrigin(client,oldpos[client]);


		ClientTracer=client;
		TR_TraceRayFilter(startpos,endpos,MASK_ALL,RayType_EndPoint,AimTargetFilter);
		TR_GetEndPosition(endpos);
/*
		if(enemyImmunityInRange(client,endpos)){
			W3MsgEnemyHasImmunity(client);
			return false;
		}
*/
		//new Float:distanceteleport=GetVectorDistance(startpos,endpos);
		//if(distanceteleport<200.0){
			//new String:buffer[100];
			//Format(buffer, sizeof(buffer), "%T", "Distance too short.", client);
			//PrintHintText(client,buffer);
		//	return false;
		//}
		//GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);///get dir again
		//ScaleVector(dir, distanceteleport-33.0);

		//AddVectors(startpos,dir,endpos);



		emptypos[0]=0.0;
		emptypos[1]=0.0;
		emptypos[2]=0.0;

		endpos[2]-=30.0;
		getEmptyLocationHull(client,endpos);

		if(GetVectorLength(emptypos)<1.0){
			new String:buffer[100];
			Format(buffer, sizeof(buffer), "%T", "NoEmptyLocation", client);
			PrintHintText(client,buffer);
			return false; //it returned 0 0 0
		}

		TeleportEntity(client,emptypos,NULL_VECTOR,NULL_VECTOR);
		//TeleportEntity(client,endpos,NULL_VECTOR,NULL_VECTOR);
		//EmitSoundToAll(teleportSound,client);
		//EmitSoundToAll(teleportSound,client);

		teleportpos[client][0]=emptypos[0];
		teleportpos[client][1]=emptypos[1];
		teleportpos[client][2]=emptypos[2];

		inteleportcheck[client]=true;
		CreateTimer(0.14,checkTeleport,client);

		return true;
	}

	return false;
}
public Action:checkTeleport(Handle:h,any:client){
	inteleportcheck[client]=false;
	new Float:pos[3];

	GetClientAbsOrigin(client,pos);

	if(GetVectorDistance(teleportpos[client],pos)<0.001)//he didnt move in this 0.1 second
	{
		TeleportEntity(client,oldpos[client],NULL_VECTOR,NULL_VECTOR);
		PrintHintText(client,"Can't Teleport Here");
		//War3_CooldownReset(client,TPFailCDResetToRace[client],TPFailCDResetToSkill[client]);
	}
	else{
		PrintHintText(client,"Teleported");
	}
}

public bool:AimTargetFilter(entity,mask)
{
	return !(entity==ClientTracer);
}


new absincarray[]={0,4,-4,8,-8,12,-12,18,-18,22,-22,25,-25};//,27,-27,30,-30,33,-33,40,-40}; //for human it needs to be smaller

public bool:getEmptyLocationHull(client,Float:originalpos[3]){


	new Float:mins[3];
	new Float:maxs[3];
	GetClientMins(client,mins);
	GetClientMaxs(client,maxs);

	new absincarraysize=sizeof(absincarray);

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

						TR_TraceHullFilter(pos,pos,mins,maxs,MASK_SOLID,CanHitThis,client);
						//new ent;
						if(!TR_DidHit(_))
						{
							AddVectors(emptypos,pos,emptypos); ///set this gloval variable
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

/*
public bool:enemyImmunityInRange(client,Float:playerVec[3])
{
	//ELIMINATE ULTIMATE IF THERE IS IMMUNITY AROUND
	new Float:otherVec[3];
	new team = GetClientTeam(client);

	for(new i=1;i<=MaxClients;i++)
	{
		if(ValidPlayer(i,true)&&GetClientTeam(i)!=team&&W3HasImmunity(i,Immunity_Ultimates))
		{
			GetClientAbsOrigin(i,otherVec);
			if(GetVectorDistance(playerVec,otherVec)<350)
			{
				return true;
			}
		}
	}
	return false;
}
*/