#define PLUGIN_VERSION "0.0.0.1"

#pragma semicolon 1
#include <sourcemod>

#define MOTDPANEL_TYPE_TEXT 0 /**< Treat msg as plain text */
#define MOTDPANEL_TYPE_INDEX 1 /**< Msg is auto determined by the engine */
#define MOTDPANEL_TYPE_URL 2 /**< Treat msg as an URL link */
#define MOTDPANEL_TYPE_FILE 3 /**< Treat msg as a filename to be openned */
#define COLOR_DEFAULT 0x01
#define COLOR_TEAM 0x03
#define COLOR_GREEN 0x04

//new Handle:DonateURL;

public Plugin:myinfo = {
	name = "War3Evo Engine ShowMOTD",
	author = "El Diablo",
	description = "Let's users view the vairous websites setup.",
	version = "0.2.1",
	url = "http://www.war3evo.com/"
};

public OnPluginStart() {
	CreateConVar("war3evo_ShowMOTD",PLUGIN_VERSION,"War3evo Show MOTD",FCVAR_PLUGIN);

	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	//RegConsoleCmd("updates", Command_Updates);
	//RegAdminCmd("sm_motd", Command_ShowMOTD, ADMFLAG_KICK, "sm_motd <#userid|name>");
	//DonateURL = CreateConVar("sm_doante_url","http://www.war3evo.com/donate.html","Set this to the URL of your donation website.");
}

/*
public Action:Command_ShowMOTD(client, args) {
	if (args != 1) {
		return Plugin_Handled;	
	}
	
	new String:Target[64];
	GetCmdArg(1, Target, sizeof(Target));
	
	new String:targetName[MAX_TARGET_LENGTH];
	new targetList[MAXPLAYERS], targetCount;
	new bool:tnIsMl;
	
	targetCount = ProcessTargetString(Target, client, targetList, sizeof(targetList), COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), tnIsMl);

	if(targetCount == 0) {
		ReplyToTargetError(client, COMMAND_TARGET_NONE);
	} else {
		for (new i=0; i<targetCount; i++) {
			PerformMOTD(client, targetList[i]);
		}
	}
	
	return Plugin_Continue;
} */

public Action:Command_Say(client, args) {
	decl String:text[192];
	if (GetCmdArgString(text, sizeof(text)) < 1) {
		return Plugin_Continue;
	}
	
	new startidx;
	if (text[strlen(text)-1] == '"') {
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	decl String:message[15];
	BreakString(text[startidx], message, sizeof(message));
	
	if (strcmp(message, "!donate", false) == 0 || strcmp(message, "/donate", false) == 0 || strcmp(message, "donate", false) == 0)
	{

		new String:buffer[128];
		//GetConVarString(DonateURL, buffer, 127);
		//DonateURL
		//PerformDONATE(client,buffer);
		new String:steamid[32];
		new String:theclientname[64];
		GetClientAuthString(client,steamid,sizeof(steamid));
		GetClientName(client, theclientname, sizeof(theclientname));
		URLEncode(theclientname, sizeof(theclientname));
		URLEncode(steamid, sizeof(steamid));
		Format(buffer,sizeof(buffer),"http://www.war3evo.com/w3edonate.php?steamid=%s&clientname=%s",steamid,theclientname);
		PerformDONATE(client,buffer);
		return Plugin_Continue;
	}
	if (strcmp(message, "!bind", false) == 0 || strcmp(message, "/bind", false) == 0)
	{
		PerformDONATE(client,"http://youtu.be/N9jbRbBS61c");
		//PrintToChatAll("Unable to find website for video.");
		return Plugin_Continue;
	}
	if (strcmp(message, "!rules", false) == 0 || strcmp(message, "/rules", false) == 0)
	{
		PerformDONATE(client,"http://war3evo.com/forum/index.php?&topic=15.0");
		return Plugin_Continue;
	}
	if (strcmp(message, "!join", false) == 0 || strcmp(message, "/join", false) == 0)
	{
		PerformDONATE(client,"http://steamcommunity.com/groups/war3evo/members");
		return Plugin_Continue;
	}
	if (strcmp(message, "!updates", false) == 0 || strcmp(message, "/w3eupdates", false) == 0)
	{
		PerformDONATE(client,"http://war3evo.com/forum/index.php?topic=2.0");
		return Plugin_Continue;
	}
	if ( StrContains(message, "/song", false)==0)
	{
		songHelp(client);
		new String:buffer2[128];
		Format(buffer2,sizeof(buffer2),"http://war3evo.com/song/song.php?q=%s",text[startidx+6]);
		hiddenURL(client,buffer2);		
		return Plugin_Continue;
	} else if ( StrContains(message, "/youtube2", false)==0)
	{
		songHelp(client);
		new String:buffer2[128];
		
		Format(buffer2,sizeof(buffer2),"http://war3evo.com/song/youtube2.php?q=%s",text[startidx+10]);
		PerformDONATE(client,buffer2);		
		return Plugin_Continue;
	} else if ( StrContains(message, "/youtube", false)==0)
	{
		songHelp(client);
		new String:buffer2[128];
		Format(buffer2,sizeof(buffer2),"http://war3evo.com/song/youtube.php?q=%s",text[startidx+9]);
		hiddenURL(client,buffer2);		
		return Plugin_Continue;
	} else if ( StrContains(message, "/di2", false)==0)
	{
		new String:buffer2[128];
		Format(buffer2,sizeof(buffer2),"http://player.highstrike.org/play/");
		PerformDONATE(client,buffer2);
		songHelp(client);
		return Plugin_Continue;
	
	} else if ( StrContains(message, "/di", false)==0)
	{
		new String:buffer2[128];
		Format(buffer2,sizeof(buffer2),"http://player.highstrike.org/play/");
		hiddenURL(client,buffer2);
		songHelp(client);
		return Plugin_Continue;
	}
	
	
	if ( StrContains(message, "/stop", false)==0)
	{
		PrintToChat(client,"Stopping playback :(");
		
		hiddenURL(client,"about:blank");		
		return Plugin_Continue;
	}
	if ( StrContains(message, "/grooveshark", false)==0)
	{
		PrintToChat(client,"Loading GS...");
		PerformDONATE(client,"http://www.grooveshark.com");
		return Plugin_Continue;
	}
	return Plugin_Continue;
}
public songHelp(client)
{
		PrintToChat(client,"Yo this is Lord Dagothur trying to play your super sick song RIGHT MEOW. Type /stop to end the party. Command list:");
		PrintToChat(client,"/song <song> /youtube <song> /youtube2 <song> /grooveshark");
		PrintToChat(client,"/di /di2 (volume; change channel)");
		PrintToChat(client,"You can set the volume for /youtube by using /youtube2");
		PrintToChat(client,"Problem changing volume? Put the mouse a little higher");
}

public hiddenURL(client, String:url[])
{
	new Handle:setup = CreateKeyValues("data");
	
	KvSetString(setup, "title", "Musicspam");
	KvSetNum(setup, "type", MOTDPANEL_TYPE_URL);
	KvSetString(setup, "msg", url);
	
	ShowVGUIPanel(client, "info", setup, false);
	CloseHandle(setup);
	//return Plugin_Continue;
}



public PerformDONATE(client, String:DONATE_URL[128])
{
	ShowMOTDPanel(client, "War3Evo", DONATE_URL, MOTDPANEL_TYPE_URL);
	
}

// Example usage: index.php?a=URLEncode(param_1)&b=URLEncode(param_2)&c=URLEncode(param_3)
stock URLEncode(String:str[],len)
{
	// Make sure % is first to avoid collisions.
	new String:ReplaceThis[20][] = {"%", " ", "!", "*", "'", "(", ")", ";", ":", "@", "&", "=", "+", "$", ",", "/", "?", "#", "[", "]"};
	new String:ReplaceWith[20][] = {"%25", "%20", "%21", "%2A", "%27", "%28", "%29", "%3B", "%3A", "%40", "%26", "%3D", "%2B", "%24", "%2C", "%2F", "%3F", "%23", "%5B", "%5D"};
	for(new x=0;x<20;x++)
	{
		ReplaceString(str, len, ReplaceThis[x], ReplaceWith[x]);
	}
	if(strlen(str)>len-1){
		LogError("!donate encode url exceeded length: %s",str);
		//War3Failed("statistics encode url exceeded length"); //this should never happen as ReplaceString was fixed not to overwrite its length
	}
}
