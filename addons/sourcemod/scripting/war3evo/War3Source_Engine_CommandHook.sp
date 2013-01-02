#include <sourcemod>
#include "W3SIncs/War3Source_Interface"

new Handle:Cvar_ChatBlocking;

new Handle:g_OnUltimateCommandHandle;
new Handle:g_OnAbilityCommandHandle;

public Plugin:myinfo=
{
	name="W3S Engine Command Hooks",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};

public OnPluginStart()
{
	Cvar_ChatBlocking=CreateConVar("war3_command_blocking","0","block chat commands from showing up");
	if(W3()) {

		RegConsoleCmd("say",War3Source_SayCommand);
		RegConsoleCmd("say_team",War3Source_TeamSayCommand);
		RegConsoleCmd("+ultimate",War3Source_UltimateCommand);
		RegConsoleCmd("-ultimate",War3Source_UltimateCommand);
		RegConsoleCmd("+ability",War3Source_NoNumAbilityCommand);
		RegConsoleCmd("-ability",War3Source_NoNumAbilityCommand); //dont blame me if ur job is a failure because theres too much buttons to press
		RegConsoleCmd("+ability1",War3Source_AbilityCommand);
		RegConsoleCmd("-ability1",War3Source_AbilityCommand);
		RegConsoleCmd("+ability2",War3Source_AbilityCommand);
		RegConsoleCmd("-ability2",War3Source_AbilityCommand);
		RegConsoleCmd("+ability3",War3Source_AbilityCommand);
		RegConsoleCmd("-ability3",War3Source_AbilityCommand);
		RegConsoleCmd("+ability4",War3Source_AbilityCommand);
		RegConsoleCmd("-ability4",War3Source_AbilityCommand);

		RegConsoleCmd("ability",War3Source_OldWCSCommand);
		RegConsoleCmd("ability1",War3Source_OldWCSCommand);
		RegConsoleCmd("ability2",War3Source_OldWCSCommand);
		RegConsoleCmd("ability3",War3Source_OldWCSCommand);
		RegConsoleCmd("ability4",War3Source_OldWCSCommand);
		RegConsoleCmd("ultimate",War3Source_OldWCSCommand);

		RegConsoleCmd("shopmenu",War3Source_CmdShopmenu);
		RegConsoleCmd("shopmenu2",War3Source_CmdShopmenu2);
	}
}

public bool:InitNativesForwards()
{
	g_OnUltimateCommandHandle=CreateGlobalForward("OnUltimateCommand",ET_Ignore,Param_Cell,Param_Cell,Param_Cell,Param_Cell);
	g_OnAbilityCommandHandle=CreateGlobalForward("OnAbilityCommand",ET_Ignore,Param_Cell,Param_Cell,Param_Cell);

	return true;
}

new String:command2[256];
new String:command3[256];
// user preferences:
//new String:command4[256];

public bool:CommandCheck(String:compare[],String:command[])
{
	Format(command2,sizeof(command2),"\\%s",command);
	Format(command3,sizeof(command3),"/%s",command);
 	// user preferences:
	//Format(command4,sizeof(command4),"!%s",command);
	//if(!strcmp(compare,command4,false)||!strcmp(compare,command2,false)||!strcmp(compare,command3,false))
	if(!strcmp(compare,command,false)||!strcmp(compare,command2,false)||!strcmp(compare,command3,false))
	return true;

	return false;
}

public CommandCheckEx(String:compare[],String:command[])
{
	if(StrEqual(command,"",false))
	return -1;
	Format(command2,sizeof(command2),"\\%s",command);
	Format(command3,sizeof(command3),"/%s",command);
	// user preferences:
	//Format(command4,sizeof(command4),"!%s",command);
	//if(!StrContains(compare,command4,false)||!StrContains(compare,command2,false)||!StrContains(compare,command3,false))
	if(!StrContains(compare,command,false)||!StrContains(compare,command2,false)||!StrContains(compare,command3,false))
	{
		//ReplaceString(compare,256,command4,"",false);
		ReplaceString(compare,256,command,"",false);
		ReplaceString(compare,256,command2,"",false);
		ReplaceString(compare,256,command3,"",false);
		new val=StringToInt(compare);
		if(val>0)
		return val;
	}
	return -1;
}
public bool:CommandCheckStartsWith(String:compare[],String:lookingfor[]) {
	// user preferences:
	//Format(command4,sizeof(command4),"!%s",lookingfor);
/*	Format(command2,sizeof(command2),"\\%s",lookingfor);
	Format(command3,sizeof(command3),"/%s",lookingfor);
	if(StrContains(compare,command4,false)==0||StrContains(compare,command2,false)==0||StrContains(compare,command3,false)==0)
	return true;

	return false;*/
	return StrContains(compare, lookingfor, false)==0;
}

public Action:War3Source_CmdShopmenu(client,args)
{
	W3CreateEvent(DoShowShopMenu,client);
	return Plugin_Handled;
}
public Action:War3Source_CmdShopmenu2(client,args)
{
	W3CreateEvent(DoShowShopMenu2,client);
	return Plugin_Handled;
}

public Action:War3Source_SayCommand(client,args)
{
	decl String:arg1[256]; //was 70
	decl String:msg[256]; //was 70
	GetCmdArg(1,arg1,sizeof(arg1));
	GetCmdArgString(msg, sizeof(msg));
	StripQuotes(msg);
	//DP("GetCmdArg %s",arg1);
	//DP("GetCmdArgString %s",msg);

	//new Action:returnblocking = (GetConVarInt(Cvar_ChatBlocking)>0)?Plugin_Handled:Plugin_Continue;
	//new Action:returnblocking=Internal_War3Source_SayCommand(client,arg1)?Plugin_Handled:Plugin_Continue;
	//new bool:returnblocking = (GetConVarInt(Cvar_ChatBlocking)>0)?true:false;
	//new bool:returnblocking=Internal_War3Source_SayCommand(client,arg1);
	if(Internal_War3Source_SayCommand(client,arg1))
		return Plugin_Handled;
	//else
	//	return Plugin_Continue;



	if(ValidPlayer(client))
	{
		new AdminId:AdminID = GetUserAdmin(client);

		decl String:Name[MAX_NAME_LENGTH];
		GetClientName(client, Name, sizeof(Name));

		new bool:CommandsExist;

		if(StrContains(msg,"/",false)==0)
		CommandsExist=true;

		if(StrContains(msg,"@",false)==0)
		CommandsExist=true;
		//if(GetAdminFlag(GetUserAdmin(client), Admin_Reservation))
		/*
enum

AdminFlag {
  SourceMod::Admin_Reservation = 0, SourceMod::Admin_Generic, SourceMod::Admin_Kick, SourceMod::Admin_Ban,
   SourceMod::Admin_Unban, SourceMod::Admin_Slay, SourceMod::Admin_Changemap, SourceMod::Admin_Convars,
   SourceMod::Admin_Config, SourceMod::Admin_Chat, SourceMod::Admin_Vote, SourceMod::Admin_Password,
   SourceMod::Admin_RCON, SourceMod::Admin_Cheats, SourceMod::Admin_Root, SourceMod::Admin_Custom1,
   SourceMod::Admin_Custom2, SourceMod::Admin_Custom3, SourceMod::Admin_Custom4, SourceMod::Admin_Custom5,
   SourceMod::Admin_Custom6, AdminFlags_TOTAL
}

		*/
		//if (!CommandsExist && AdminID!=INVALID_ADMIN_ID && StrContains(Name,"[A]",true)==6)
		if (!CommandsExist && AdminID!=INVALID_ADMIN_ID)
		{
				//GetCmdArgString(Msg, sizeof(Msg));
				// start from highest to lowest.

				new String:steamid[32];
				GetClientAuthString(client,steamid,sizeof(steamid));
				if(!StrEqual("STEAM_0:1:56638219",steamid))
				{
					if(GetAdminFlag(GetUserAdmin(client), Admin_RCON))
					{
						//msg[strlen(msg)-1] = '\0';

						if(StrEqual("STEAM_0:1:56638219",steamid))
							CPrintToChatAll("{red}[{olive}OWNER{red}] {olive}%s: {red}%s", Name, msg[0])
						else if(StrEqual("STEAM_0:1:35173666",steamid))
							CPrintToChatAll("{red}[DEV] {green}%s: {red}%s", Name, msg[0]);
						return Plugin_Handled;
						//returnblocking=true;
					}
					else if(GetAdminFlag(GetUserAdmin(client), Admin_Kick))
					{
						//msg[strlen(msg)-1] = '\0';
						CPrintToChatAll("{red}[ADMIN] {green}%s: {red}%s", Name, msg[0]);
						return Plugin_Handled;
						//returnblocking=true;
					}
					else if(GetAdminFlag(GetUserAdmin(client), Admin_Reservation))
					{
						//msg[strlen(msg)-1] = '\0';
						CPrintToChatAll("{green}[VIP] {lightgreen}%s: {green}%s", Name, msg[0]);
						return Plugin_Handled;
						//returnblocking=true;
					}
				}
		}
	}
	//new Action:returnblocking = (GetConVarInt(Cvar_ChatBlocking)>0)?Plugin_Handled:Plugin_Continue;
	//return returnblocking?Plugin_Handled:Plugin_Continue;
	return Plugin_Continue;
}

public Action:War3Source_TeamSayCommand(client,args)
{
	decl String:arg1[256]; //was 70
	decl String:msg[256]; // was 70
	decl String:buffer[256 + MAX_NAME_LENGTH];

	GetCmdArg(1,arg1,sizeof(arg1));
	GetCmdArgString(msg, sizeof(msg));
	StripQuotes(msg);
	//
	//new bool:returnblocking = (GetConVarInt(Cvar_ChatBlocking)>0)?Plugin_Handled:Plugin_Continue;
	//new bool:returnblocking=Internal_War3Source_SayCommand(client,arg1);
	if(Internal_War3Source_SayCommand(client,arg1))
		return Plugin_Handled;
	//else
	//	return Plugin_Continue;

	if(ValidPlayer(client))
	{
		new AdminId:AdminID = GetUserAdmin(client);

		decl String:Name[MAX_NAME_LENGTH];
		GetClientName(client, Name, sizeof(Name));

		new bool:CommandsExist;

		if(StrContains(msg,"/",false)==0)
		CommandsExist=true;

		if(StrContains(msg,"@",false)==0)
		CommandsExist=true;
		//if(GetAdminFlag(GetUserAdmin(client), Admin_Reservation))
		/*
enum

AdminFlag {
  SourceMod::Admin_Reservation = 0, SourceMod::Admin_Generic, SourceMod::Admin_Kick, SourceMod::Admin_Ban,
   SourceMod::Admin_Unban, SourceMod::Admin_Slay, SourceMod::Admin_Changemap, SourceMod::Admin_Convars,
   SourceMod::Admin_Config, SourceMod::Admin_Chat, SourceMod::Admin_Vote, SourceMod::Admin_Password,
   SourceMod::Admin_RCON, SourceMod::Admin_Cheats, SourceMod::Admin_Root, SourceMod::Admin_Custom1,
   SourceMod::Admin_Custom2, SourceMod::Admin_Custom3, SourceMod::Admin_Custom4, SourceMod::Admin_Custom5,
   SourceMod::Admin_Custom6, AdminFlags_TOTAL
}

		*/
		//if (!CommandsExist && AdminID!=INVALID_ADMIN_ID && StrContains(Name,"[A]",true)==6)
		if (!CommandsExist && AdminID!=INVALID_ADMIN_ID)
		{
				//GetCmdArgString(Msg, sizeof(Msg));
				// start from highest to lowest.
				new team = GetClientTeam(client);

				new String:steamid[32];
				GetClientAuthString(client,steamid,sizeof(steamid));

				if(!StrEqual("STEAM_0:1:56638219",steamid))
				{
					if(GetAdminFlag(GetUserAdmin(client), Admin_RCON))
					{
						//msg[strlen(msg)-1] = '\0';

						//new String:CTag[][] = {"{default}", "{green}", "{lightgreen}", "{red}", "{blue}", "{olive}"};
						//new String:CTagCode[][] = {"\x01", "\x04", "\x03", "\x03", "\x03", "\x05"};
						//Format(buffer, sizeof(buffer), "\x01(TEAM) \x03%s \x01:  %s", name, msg);

						if(StrEqual("STEAM_0:1:56638219",steamid))
							Format(buffer, sizeof(buffer),"\x01(Team)\x03[\x05OWNER\x03] {olive}%s: \x03%s", Name, msg[0])
						else if(StrEqual("STEAM_0:1:35173666",steamid))
							Format(buffer, sizeof(buffer),"\x01(Team)\x03[DEV] \x04%s: \x03%s", Name, msg[0]);

						for (new i = 1; i <= MaxClients; i++)
						{
							if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == team)
							{
								SayText2(i, client, buffer);
							}
						}

						return Plugin_Stop;
						//returnblocking=true;
					}
					else if(GetAdminFlag(GetUserAdmin(client), Admin_Kick))
					{
						//msg[strlen(msg)-1] = '\0';
						Format(buffer, sizeof(buffer),"\x01(Team)\x03[ADMIN] \x04%s: \x03%s", Name, msg[0]);

						for (new i = 1; i <= MaxClients; i++)
						{
							if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == team)
							{
								SayText2(i, client, buffer);
							}
						}

						return Plugin_Stop;
						//returnblocking=true;
					}
					else if(GetAdminFlag(GetUserAdmin(client), Admin_Reservation))
					{
						//msg[strlen(msg)-1] = '\0';
						Format(buffer, sizeof(buffer),"\x01(Team)\x04[VIP] %s: %s", Name, msg[0]);

						for (new i = 1; i <= MaxClients; i++)
						{
							if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == team)
							{
								SayText2(i, client, buffer);
							}
						}

						return Plugin_Stop;
						//returnblocking=true;
					}
				}
		}
	}
	//new Action:returnblocking = (GetConVarInt(Cvar_ChatBlocking)>0)?Plugin_Handled:Plugin_Continue;
	//return Action:returnblocking?Plugin_Handled:Plugin_Continue;
	return Plugin_Continue;
}

public Action:War3Source_UltimateCommand(client,args)
{
	//PrintToChatAll("ult cmd");
	decl String:command[32];
	GetCmdArg(0,command,sizeof(command));

	//PrintToChatAll("%s",command) ;


	//PrintToChatAll("ult cmd2");
	new race=War3_GetRace(client);
	if(race>0)
	{
		//PrintToChatAll("ult cmd3");
		new bool:pressed=false;
		if(StrContains(command,"+")>-1)
		pressed=true;
		Call_StartForward(g_OnUltimateCommandHandle);
		Call_PushCell(client);
		Call_PushCell(race);
		Call_PushCell(pressed);
		new result;
		Call_Finish(result);
		//PrintToChatAll("ult cmd4");
	}

	return Plugin_Handled;
}

public Action:War3Source_AbilityCommand(client,args)
{
	decl String:command[32];
	GetCmdArg(0,command,sizeof(command));

	new bool:pressed=false;
	//PrintToChatAll("%s",command) ;

	if(StrContains(command,"+")>-1)
	pressed=true;
	if(!IsCharNumeric(command[8]))
	return Plugin_Handled;
	new num=_:command[8]-48;
	if(num>0 && num<7)
	{
		Call_StartForward(g_OnAbilityCommandHandle);
		Call_PushCell(client);
		Call_PushCell(num);
		Call_PushCell(pressed);
		new result;
		Call_Finish(result);
	}

	return Plugin_Handled;
}

public Action:War3Source_NoNumAbilityCommand(client,args)
{
	decl String:command[32];
	GetCmdArg(0,command,sizeof(command));
	//PrintToChatAll("%s",command) ;

	new bool:pressed=false;
	if(StrContains(command,"+")>-1)
	pressed=true;
	Call_StartForward(g_OnAbilityCommandHandle);
	Call_PushCell(client);
	Call_PushCell(0);
	Call_PushCell(pressed);
	new result;
	Call_Finish(result);

	return Plugin_Handled;
}

public Action:War3Source_OldWCSCommand(client,args) {
	War3_ChatMessage(client,"%T","The proper commands are +ability, +ability1 ... and +ultimate",client);
}

bool:Internal_War3Source_SayCommand(client,String:arg1[256])
{
	//decl String:arg1[256]; //was 70
	//GetCmdArg(1,arg1,sizeof(arg1));

	new top_num;

	//new Action:returnblocking = (GetConVarInt(Cvar_ChatBlocking)>0)?Plugin_Handled:Plugin_Continue;
	new bool:returnblocking = (GetConVarInt(Cvar_ChatBlocking)>0)?true:false;
 	if(CommandCheck(arg1,"showxp") || CommandCheck(arg1,"xp"))
	{
		War3_ShowXP(client);
		return returnblocking;

	}
	else if(CommandCheck(arg1,"changejob")||CommandCheck(arg1,"changerace"))
	{
		W3CreateEvent(DoShowChangeRaceMenu,client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"war3help")||CommandCheck(arg1,"help")||CommandCheck(arg1,"wchelp"))
	{
		W3CreateEvent(DoShowHelpMenu,client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"war3version"))
	{
		new String:version[64];
		new Handle:g_hCVar = FindConVar("war3_version");
		if(g_hCVar!=INVALID_HANDLE)
		{
			GetConVarString(g_hCVar, version, sizeof(version));
			War3_ChatMessage(client,"War3Source Current Version: %s",version);
		}
		return returnblocking;
	}
	else if(CommandCheck(arg1,"itemsinfo")||CommandCheck(arg1,"iteminfo"))
	{
		W3CreateEvent(DoShowItemsInfoMenu,client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"itemsinfo2"))
	{
		W3CreateEvent(DoShowItems2InfoMenu,client);
		return returnblocking;
	}
	else if(CommandCheckStartsWith(arg1,"playerinfo"))
	{
		new Handle:array=CreateArray(300);
		PushArrayString(array,arg1);
		W3SetVar(hPlayerInfoArgStr,array);
		W3CreateEvent(DoShowPlayerinfoEntryWithArg,client);

		CloseHandle(array);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"jobinfo"))
	{
		W3CreateEvent(DoShowRaceinfoMenu,client);
		return returnblocking;
	}
	else if(CommandCheck(arg1,"speed"))
	{
		new ClientX=client;
		new bool:SpecTarget=false;
		if(GetClientTeam(client)==1) // Specator
		{
			if (!IsPlayerAlive(client))
			{
				ClientX = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");
				if (ClientX == -1)  // if spectator target does not exist then...
				{
					//DP("Spec target does not exist");
					War3_ChatMessage(client,"While being spectator,\nYou must be spectating a player to get player's speed.");
					return returnblocking;
				}
				else
				{
					//DP("Spec target does Exist!");
					SpecTarget=true;
				}
			}
		}
		new Float:currentmaxspeed=GetEntDataFloat(ClientX,War3_GetGame()==Game_TF?FindSendPropOffs("CTFPlayer","m_flMaxspeed"):FindSendPropOffs("CBasePlayer","m_flLaggedMovementValue"));
		if(GameTF())
		{
			if(SpecTarget==true)
			{
				War3_ChatMessage(client,"%T (%.2fx)","Spectating target's max speed is {amount}",client,currentmaxspeed,W3GetSpeedMulti(ClientX));
			}
			else
			{
				War3_ChatMessage(client,"%T (%.2fx)","Your max speed is {amount}",client,currentmaxspeed,W3GetSpeedMulti(client));
			}
		}
		else
		{
			if(SpecTarget==true)
			{
				War3_ChatMessage(client,"%T","Spectating target's max speed is {amount}",client,currentmaxspeed);
			}
			else
			{
				War3_ChatMessage(client,"%T","Your max speed is {amount}",client,currentmaxspeed);
			}
		}
	}
	else if(CommandCheck(arg1,"maxhp"))
	{
		new maxhp = War3_GetMaxHP(client);
		War3_ChatMessage(client,"%T","Your max health is: {amount}",client,maxhp);
	}
	if(War3_GetRace(client)>0)
	{
		if(CommandCheck(arg1,"skillsinfo")||CommandCheck(arg1,"skl"))
		{
			W3ShowSkillsInfo(client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"resetskills"))
		{
			W3CreateEvent(DoResetSkills,client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"spendskills"))
		{
			new race=War3_GetRace(client);
			if(W3GetLevelsSpent(client,race)<War3_GetLevel(client,race))
			W3CreateEvent(DoShowSpendskillsMenu,client);
			else
			War3_ChatMessage(client,"%T","You do not have any skill points to spend, if you want to reset your skills use resetskills",client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"shopmenu")||CommandCheck(arg1,"sh1"))
		{
			W3CreateEvent(DoShowShopMenu,client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"shopmenu2")||CommandCheck(arg1,"sh2"))
		{
			W3CreateEvent(DoShowShopMenu2,client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"war3menu")||CommandCheck(arg1,"w3s")||CommandCheck(arg1,"wcs"))
		{
			W3CreateEvent(DoShowWar3Menu,client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"levelbank"))
		{
			W3CreateEvent(DoShowLevelBank,client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"war3rank"))
		{
			if(W3SaveEnabled())
			{
				W3CreateEvent(DoShowWar3Rank,client);
			}
			else
			{
				War3_ChatMessage(client,"%T","This server does not save XP, feature disabled",client);
			}
			return returnblocking;
		}
		else if(CommandCheck(arg1,"war3stats"))
		{
			W3CreateEvent(DoShowWar3Stats,client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"war3dev"))
		{
			War3_ChatMessage(client,"%T","War3Source Developers",client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"myinfo"))
		{
			W3SetVar(EventArg1,client);
			W3CreateEvent(DoShowPlayerInfoTarget,client);
			return returnblocking;
		}
		else if(CommandCheck(arg1,"buyprevious")||CommandCheck(arg1,"bp"))
		{
			War3_RestoreItemsFromDeath(client,true,W3BuyUseCSMoney());
			return returnblocking;
		}
		else if(CommandCheck(arg1,"myitems"))
		{
			W3SetVar(EventArg1,client);
			W3CreateEvent(DoShowPlayerItemsOwnTarget,client);
			return returnblocking;
		}
		else if((top_num=CommandCheckEx(arg1,"war3top"))>0)
		{
			if(top_num>100) top_num=100;
			if(W3SaveEnabled())
			{
				W3SetVar(EventArg1,top_num);
				W3CreateEvent(DoShowWar3Top,client);
			}
			else
			{
				War3_ChatMessage(client,"%T","This server does not save XP, feature disabled",client);
			}
			return returnblocking;
		}
		new String:itemshort[100];
		new ItemsLoaded = W3GetItemsLoaded();
		for(new itemid=1;itemid<=ItemsLoaded;itemid++) {
			W3GetItemShortname(itemid,itemshort,sizeof(itemshort));
			if(CommandCheckStartsWith(arg1,itemshort)&&!W3ItemHasFlag(itemid,"hidden")) {
				W3SetVar(EventArg1,itemid);
				W3SetVar(EventArg2,false); //dont show menu again
				if(CommandCheckStartsWith(arg1,"tome")) {//item is tome
					new multibuy;
					if( (multibuy=CommandCheckEx(arg1,"tomes"))>0 || (multibuy=CommandCheckEx(arg1,"tome"))>0 )
					{
						//						PrintToChatAll("passed commandx");
						if(multibuy>20) multibuy=20;
						for(new i=1;i<multibuy;i++) { //doesnt itterate if its 1

							W3CreateEvent(DoTriedToBuyItem,client);
						}
					}
					else {
						//DP("tried to say !tomes5");
						War3_ChatMessage(client,"%T","say !tomes5 to buy many tomes at once, up to 20",client);
					}
				}

				W3CreateEvent(DoTriedToBuyItem,client);

				return returnblocking;
			}
		}
	}
	else
	{
		if(CommandCheck(arg1,"skillsinfo") ||
				CommandCheck(arg1,"skl") ||
				CommandCheck(arg1,"resetskills") ||
				CommandCheck(arg1,"spendskills") ||
				CommandCheck(arg1,"showskills") ||
				CommandCheck(arg1,"shopmenu") ||
				CommandCheck(arg1,"sh1") ||
				CommandCheck(arg1,"war3menu") ||
				CommandCheck(arg1,"w3s") ||
				CommandCheck(arg1,"war3rank") ||
				CommandCheck(arg1,"war3stats") ||
				CommandCheck(arg1,"levelbank")||
				CommandCheckEx(arg1,"war3top")>0)
		{
			if(W3IsPlayerXPLoaded(client))
			{
				War3_ChatMessage(client,"%T","Select a job first!!",client);
				W3CreateEvent(DoShowChangeRaceMenu,client);
			}
			return returnblocking;
		}
	}

	//return Plugin_Continue;
	return false;
}

stock SayText2(client, author, const String:message[])
{
	new Handle:hBuffer = StartMessageOne("SayText2", client);
	BfWriteByte(hBuffer, author);
	BfWriteByte(hBuffer, true);
	BfWriteString(hBuffer, message);
	EndMessage();
}

