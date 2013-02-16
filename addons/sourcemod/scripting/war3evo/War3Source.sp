
/*  This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
	War3source written by PimpinJuice (anthony) and Ownz (Dark Energy)
	War3Evo derived from War3Source written by El Diablo
	All rights reserved.
*/	

/*
* File: War3Source.sp
* Description: The main file for War3Source.
* Author(s): Anthony Iacono  & OwnageOwnz (DarkEnergy)
* All handle leaks have been considered.
* If you don't like it, read through the whole thing yourself and prove yourself wrong.
*/

#pragma semicolon 1


#define VERSION_NUM "1.2.4.1"
#define eVERSION_NUM "1.0.2.9" //(2/10/2013)
//#define REVISION_NUM 12321 //increment every release
#define REVISION_NUM 12415 //increment every release

/*DO NOT REMOVE THE OFFICIAL AUTHORS. YOU SHALL NOT DEPRIVE THEM OF THE CREDIT THEY DESERVE
** The orignal author of War3Source I have never known: PimpinJuice
** I, El Diablo, has done a great deal of rework to the source code,
** so I am giving myself the credit.  War3Evo is to be fast and clean for Team Fortress 2 only.
**
** The extensions for War3Source have been removed and is not needed.
** You may still need other extensions, but you will not need anything that starts
** with War3 as an extension.
**
** Unlike War3Source, War3evo's Shopmenu2 requires no War3 extensions to work,
** because I have rewritten it to work without the extentions.
** Since Ownz did not want to remove shopmenu2 extention,
** I am therefore removing his name from authors because Ownz would
** most definetly not approve of this mod.
**
** I believe I have rewritten this work almost entirely.
** I have removed just about all code relates to War3Source to the players,
** removed references to all other games other than Team Fortress 2,
** but there is still alot more that needs to be done.
**
** War3Evo was meant for Team Fortress 2 only.  The War3Source stuff has been
** optimized for Team Fortress 2.  It is meant to run super clean and highly
** optimized.  The code has been rewritten for speed and less downtime of the
** Team Fortress 2 server.  A lot of cool features is within War3Evo.
*
** Dagothur has added a great deal to the mod and has helped code new code
** for a few of the jobs.
*
** Axin has helped us test the code from the very beginning and has been
** with us all the way to the end.  He has helped us create new jobs for War3Evo.
*/
#define AUTHORS "El Diablo, Dagothur, and Axin"

//used for some special things in interface
#define WAR3MAIN

#include <sourcemod>
#include "W3SIncs/sdkhooks"
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/War3SourceMain"

public Plugin:myinfo= 
{
	name="War3Evo",
	author=AUTHORS,
	description="Brings a Warcraft like gamemode to the Source engine.",
	version=VERSION_NUM,
};

public APLRes:AskPluginLoad2Custom(Handle:myself,bool:late,String:error[],err_max)
{
	
	PrintToServer("--------------------------AskPluginLoad2Custom----------------------\n[War3Evo] Plugin loading...");
	

	new String:version[64];
	Format(version,sizeof(version),"%s by %s",VERSION_NUM,AUTHORS);
	new String:Eversion[64];
	Format(Eversion,sizeof(Eversion),"%s by %s",eVERSION_NUM,AUTHORS);
	CreateConVar("war3_version",version,"War3Evo version.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CreateConVar("a_war3_version",version,"War3Source version.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	CreateConVar("war3evo_version",Eversion,"War3Evolution version.",FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);



	if(!War3Source_InitNatives())
	{
		LogError("[War3Evo] There was a failure in creating the native based functions, definately halting.");
		return APLRes_Failure;
	}
	if(!War3Source_InitForwards())
	{
		LogError("[War3Evo] There was a failure in creating the forward based functions, definately halting.");
		return APLRes_Failure;
	}
	
	return APLRes_Success;
}

public OnPluginStart()
{
	
	PrintToServer("--------------------------OnPluginStart----------------------");
	
	if(GetExtensionFileStatus("sdkhooks.ext") < 1)
		SetFailState("SDK Hooks is not loaded.");
	
	if(!War3Source_HookEvents())
		SetFailState("[War3Evo] There was a failure in initiating event hooks.");
	if(!War3Source_InitCVars()) //especially sdk hooks
		SetFailState("[War3Evo] There was a failure in initiating console variables.");

	if(!War3Source_InitOffset())
		SetFailState("[War3Evo] There was a failure in finding the offsets required.");

	CreateTimer(0.1,DeciSecondLoop,_,TIMER_REPEAT);
		
	PrintToServer("[War3Evo] Plugin finished loading.\n-------------------END OnPluginStart-------------------");
	
/*	RegServerCmd("loadraces",CmdLoadRaces);
	
	RegConsoleCmd("dmgtest",CmdDmgTest);
	#if defined WAR3DEBUGBUILD
	//testihng commands here
	RegConsoleCmd("flashscreen",FlashTest);
	RegConsoleCmd("ubertest",UberTest);
//	RegConsoleCmd("fullskill",FullSkilltest);
*/
	RegConsoleCmd("war3refresh",refreshcooldowns);
	RegConsoleCmd("armortest",armortest);
/*	RegConsoleCmd("calltest",calltest);
	RegConsoleCmd("calltest2",calltest2);
	
	RegServerCmd("whichmode",cmdwhichmode);
	
	RegConsoleCmd("diamonds",cmddiamonds);
	#endif
	
*/
}

public Action:DeciSecondLoop(Handle:timer)
{
	// Boy, this is going to be fun.
	for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true))
		{
			//for(new i=0;i<=W3GetItemsLoaded()+War3_GetRacesLoaded();i++)
			//{
			//	PrintToServer("denybuff val: %d iter %d", buffdebuff[client][bBuffDeny][i],i);
			//}
			if(!W3IsPlayerXPLoaded(client))
			{
				if(GetGameTime()>LastLoadingHintMsg[client]+4.0)
				{
					PrintHintText(client,"%T","Loading XP... Please Wait",client);
					LastLoadingHintMsg[client]=GetGameTime();
				}
				continue;
			}
		}
	}
}

/*

public Action:calltest(client,args){
	new Handle:plugins[100];
	new Function:funcs[100];
	new length;
	
	new Handle:iter = GetPluginIterator();
	new Handle:pl;
	new Function:func;

	while (MorePlugins(iter))
	{
		pl = ReadPlugin(iter);
		func=GetFunctionByName(pl,"CheckWar3Compatability");
		if(func!=INVALID_FUNCTION){
			plugins[length]=pl;
			funcs[length]=func;
			length++;
			
		}
	}
	CloseHandle(iter);
	
	
	
	for(new i=0;i<1000;i++){
		Call_StartForward(g_CheckCompatabilityFH);
		Call_PushString(interfaceVersion);
		Call_Finish(dummyreturn);
	}
	
}
public Action:calltest2(client,args){
	new Handle:plugins[100];
	new Function:funcs[100];
	new length;
	
	new Handle:iter = GetPluginIterator();
	new Handle:pl;
	new Function:func;
	while (MorePlugins(iter))
	{
		pl = ReadPlugin(iter);
		func=GetFunctionByName(pl,"CheckWar3Compatability");
		if(func!=INVALID_FUNCTION){
			plugins[length]=pl;
			funcs[length]=func;
			length++;
			
		}
	}
	CloseHandle(iter);
	
	for(new i=0;i<1000;i++){
	
		for(new x=0;x<length;x++){
			
			Call_StartFunction(plugins[x],funcs[x]);
			Call_PushString(interfaceVersion);
			Call_Finish(dummyreturn);
		}
	}
}?*/
public Action:armortest(client,args){
	if(W3IsDeveloper(client)){
		for(new i=1;i<=MaxClients;i++){
			new String:arg[10];
			GetCmdArg(1,arg,sizeof(arg));
			new Float:num=StringToFloat(arg);
			War3_SetBuff(i,fArmorPhysical,1,num);
			War3_SetBuff(i,fArmorMagic,1,num);
		}
	}
}/*
public Action:CmdDmgTest(client,args){
	War3_DealDamage(client,50,_,_,"testdmg");
}
public Action:CmdLoadRaces(args){
	PrintToServer("FORCE LOADING ALL RACES AND ITEMS");
	LoadRacesAndItems();
	return Plugin_Handled;
}*/
public Action:refreshcooldowns(client,args){
	if(W3IsDeveloper(client)){
			new raceid=War3_GetRace(client);
			if(raceid>0){
	for( new skillnum=1;skillnum<=War3_GetRaceSkillCount(raceid);skillnum++){
		War3_CooldownMGR(client,0.0,raceid,skillnum,false,false);
	}
			}
	}
}
/*
public Action:FlashTest(client,args){
	if(args==6){
		new String:arg[32];
		GetCmdArg(1,arg,sizeof(arg));
		new r=StringToInt(arg);
		GetCmdArg(2,arg,sizeof(arg));
		new g=StringToInt(arg);
		GetCmdArg(3,arg,sizeof(arg));
		new b=StringToInt(arg);
		GetCmdArg(4,arg,sizeof(arg));
		new a=StringToInt(arg);
		GetCmdArg(5,arg,sizeof(arg));
		new Float:duration=StringToFloat(arg);
		
		GetCmdArg(6,arg,sizeof(arg));
		new Float:duration2=StringToFloat(arg);
		
		new Handle:hBf=StartMessageOne("Fade",client);
		if(hBf!=INVALID_HANDLE)
		{
			BfWriteShort(hBf,RoundFloat(duration*255));
			BfWriteShort(hBf,RoundFloat(duration2*255));
			BfWriteShort(hBf,0x0001); 
			BfWriteByte(hBf,r);
			BfWriteByte(hBf,g);
			BfWriteByte(hBf,b);
			BfWriteByte(hBf,a);
			EndMessage();
		}
		
	}
}
public Action:UberTest(client,args){
	if(W3IsDeveloper(client)){
		ReplyToCommand(client,"is ubered? %s",War3_IsUbered(client)?"true":"false");
		if(args==2){
			new String:buf[10];
			GetCmdArg(1,buf,sizeof(buf));
			new n1=StringToInt(buf);
			GetCmdArg(2,buf,sizeof(buf));
			new n2=StringToInt(buf);
			War3_SetXP(client,n1,n2);
		}
		if(args==1){
			new String:buf[10];
			GetCmdArg(1,buf,sizeof(buf));
			new n1=StringToInt(buf);
			
			if(!War3_GetOwnsItem(client,n1)){
				
	W3SetVar(TheItemBoughtOrLost,n1);
	W3CreateEvent(DoForwardClientBoughtItem,client);
			}
			else{
	ReplyToCommand(client,"Already haz item %d",n1);
	
			}
		}
	}
}



public Action:FullSkilltest(client,args){
	new race=War3_GetRace(client);
	new SkillCount = War3_GetRaceSkillCount(race);
	for(new i=1;i<=SkillCount;i++){
		War3_SetSkillLevelINTERNAL(client,race,i,4);
	}
}







*/



public OnMapStart()
{
	PrintToServer("OnMapStart");
	W3CreateEvent(UNLOADPLUGINSBYMODE,0); // not something that is considered unapprovable but make sure your defines have naming schemas like War3Event_Blah

	DoWar3InterfaceExecForward();
	
	LoadRacesAndItems();
	
	CreateTimer(5.0, CheckCvars, 0);

	OneTimeForwards();

}

///test script
public Action:CheckCvars(Handle:timer, any:client)
{
	new Handle:convarList = INVALID_HANDLE, Handle:conVar = INVALID_HANDLE;
	new bool:isCommand;
	new flags;
	new String:buffer[70], String:buffer2[70], String:desc[256];
	
	convarList = FindFirstConCommand(buffer, sizeof(buffer), isCommand, flags, desc, sizeof(desc));
	if(convarList == INVALID_HANDLE)
		return Plugin_Handled;
	
	do
	{
		// don't print commands or convars without the NOTIFY flag
		if(isCommand || (!isCommand && (flags & FCVAR_NOTIFY == 0)))
			continue;
		
		conVar = FindConVar(buffer);
		GetConVarString(conVar, buffer2, sizeof(buffer2));
		SetConVarString(conVar, buffer2, false, false);
		CloseHandle(conVar);
		
	} while(FindNextConCommand(convarList, buffer, sizeof(buffer), isCommand, flags, desc, sizeof(desc)));
	
	if(convarList != INVALID_HANDLE)
		CloseHandle(convarList);
	
	return Plugin_Handled;
}




public Action:OnGetGameDescription(String:gameDesc[64])
{
	if(GetConVarInt(hChangeGameDescCvar)>0)
	{
		Format(gameDesc,sizeof(gameDesc),"War3Evo %s",VERSION_NUM);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public OnAllPluginsLoaded() //called once only, will not call again when map changes
{
	PrintToServer("OnAllPluginsLoaded");
}


LoadRacesAndItems()
{	

	PrintToServer("RACE ITEM LOAD");
	new Float:starttime=GetEngineTime();
	//ordered loads
	new res;
	for(new i;i<=MAXRACES*10;i++)
	{
		Call_StartForward(g_OnWar3PluginReadyHandle);
		Call_PushCell(i);
		Call_Finish(res);
	}

	//orderd loads 2
	for(new i;i<=MAXRACES*10;i++)
	{
		Call_StartForward(g_OnWar3PluginReadyHandle2);
		Call_PushCell(i);
		Call_Finish(res);
	}
		
	//unorderd loads
	Call_StartForward(g_OnWar3PluginReadyHandle3);
	Call_Finish(res);
	

	PrintToServer("RACE ITEM LOAD FINISHED IN %.2f seconds",GetEngineTime()-starttime);
	
	DelayedWar3SourceCfgExecute();
	
}

DelayedWar3SourceCfgExecute()
{
		if(FileExists("cfg/war3source.cfg"))
		{
			ServerCommand("exec war3source.cfg");
			PrintToServer("[War3Evo] Executing war3source.cfg");
		}
		else
		{
			PrintToServer("[War3Evo] Could not find war3source.cfg, we recommend all servers have this file");
	}

}

public OnClientPutInServer(client)
{
	LastLoadingHintMsg[client]=GetGameTime();
	//DatabaseSaveXP now handles clearing of vars and triggering retrieval
}

public OnClientDisconnect(client)
{
	//DatabaseSaveXP now handles clearing of vars and triggering retrieval
}