#define PLUGIN_VERSION "0.0.0.1"
/**
 * File: War3Source_ShopItems.sp
 * Description: The shop items that come with War3Source.
 * Author(s): Anthony Iacono
 *
 *-- Added mypiggybank  == Cash Regen for MVM
 *-- Uncomment line 143 in order to enable it.
 *--
 *-- El Diablo
 *-- www.war3evo.com
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
//#include "W3SIncs/colors"
#include <sdktools>

#include <cstrike>

enum ITEMENUM{
	POSTHASTE=0,
	TRINKET,
	LIFETUBE,
	SNAKE_BRACELET,
	FORTIFIED_BRACER,
	CASH_REGEN
	/*
	//basic "Accessories"
	striders
	
	soulscream ring , Alchemist's Bones, charged hammer
	Trinket of Restoration
	sustainer
	
	//support
	ring of the teacher
	Refreshing Ornament
	Shield of the Five
	helm
	headdress
	
	//protective
	Iron Shield
	daemonic breastplate
	frostfield plate	
	behe's heart
	snake bracelet
	barbed armor
	//combata
	spell shards??? needs some recoding
	thunderclaw
	modk of brilliance
	warclept - attack speed
	//morph 
	shiel dbreakder
	frostburn
	some leech 
	
	
	
	
	
	
	*/
}

new ItemID[MAXITEMS];

// Regen Cash
new bool:CASH_REGEN_PLAYERS[MAXPLAYERSCUSTOM]=false;
new MVM_CURRENT_CASH[MAXPLAYERSCUSTOM]=0;
//new Handle:g_tCash;
new Handle:cvarAmount;
new Handle:cvarTime;
new bool:Enable_Cash_Regen=false;
new String:MyPiggyBankSound[]="war3source/piggybank/mypiggybank2.mp3";

//#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo = 
{
	name = "W3S - Shopitems2",
	author = "Ownz",
	description = "The shop items that come with War3Source.",
	version = "1.0.0.0",
	url = "http://war3source.com/"
};

public OnPluginStart()
{

	CreateConVar("war3evo_shopmenu2",PLUGIN_VERSION,"War3evo shopmenu 2",FCVAR_PLUGIN);
	//CreateTimer(1.0,test,_,TIMER_REPEAT);
	//W3CreateCvar("w3shop2items","loaded","is the shop2 loaded");
	cvarAmount = CreateConVar("sm_cashregen_amount", "20", "Amount of money generated per increment", _, true, 0.0, true, 1000.0);
	cvarTime = CreateConVar("sm_cashregen_time", "20", "Time between cash regens", _, true, 0.0);

	if(!HookEventEx("mvm_begin_wave", MVM_OnRoundStart))
	{
		PrintToServer("[War3Source] Could not hook the mvm_begin_wave event.");
	}
	if(!HookEventEx("teamplay_round_win", MVM_OnTeamplayRoundWin))
	{
		PrintToServer("[War3Source] Could not hook the teamplay_round_win event.");
	}
	if(!HookEventEx("mvm_wave_complete", MVM_OnRoundEnd))
	{
		PrintToServer("[War3Source] Could not hook the mvm_wave_complete event.");
	}
	if(!HookEventEx("mvm_mission_complete", MVM_OnRoundComplete))
	{
		PrintToServer("[War3Source] Could not hook the mvm_mission_complete event.");
	}
	if(!HookEventEx("mvm_pickup_currency", War3Source_MvMCurrencyEvent))
	{
		PrintToServer("[War3Source] Could not hook the mvm_pickup_currency event.");
	}

//	HookEvent("teamplay_setup_finished", OnTeamplaySetupFinished);
//	HookEvent("mvm_bomb_reset_by_player", OnRoundReset); //Start
//	HookEvent("mvm_mission_complete", OnRoundComplete); //End
//	HookEvent("mvm_wave_complete", OnRoundEnd);
//	HookEvent("mvm_bomb_deploy_reset_by_player", OnRoundDeployReset);
	//CreateTimer(GetConVarFloat(cvarTime), Timer_Cash, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(GetConVarFloat(cvarTime), Timer_Cash, _, TIMER_REPEAT);
}

//public Action:test(Handle:t,any:a){
	//DP("ItemID[FORTIFIED_BRACER]=%d ItemID[SNAKE_BRACELET]=%d ItemID[LIFETUBE]=%d",ItemID[FORTIFIED_BRACER],ItemID[SNAKE_BRACELET],ItemID[LIFETUBE]);
//}

public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==10){

		for(new x=0;x<MAXITEMS;x++)
			ItemID[x]=0;

		ItemID[POSTHASTE]=War3_CreateShopItem2T("posthaste",10);
		if(ItemID[POSTHASTE]==0){
			DP("ERR ITEM ID RETURNED IS ZERO");
		}
		ItemID[TRINKET]=War3_CreateShopItem2T("trinket",15);
		ItemID[LIFETUBE]=War3_CreateShopItem2T("lifetube",40);
		ItemID[SNAKE_BRACELET]=War3_CreateShopItem2T("sbracelt",10);
		ItemID[FORTIFIED_BRACER]=War3_CreateShopItem2T("fbracer",10);
		//ItemID[CASH_REGEN]=War3_CreateShopItem2T("mvmcashregen",40);
		

	}
}
public OnMapStart()
{
	War3_PrecacheSound(MyPiggyBankSound);
}

public OnItem2Purchase(client,item)
{
//DP("purchase %d %d",client,item);
	if(item==ItemID[POSTHASTE] )
	{
		War3_SetBuffItem2(client,fMaxSpeed2,ItemID[POSTHASTE],1.034);
	}
	if(item==ItemID[TRINKET] ) 
	{
		War3_SetBuffItem2(client,fHPRegen,ItemID[TRINKET],0.5);
	}
	if(item==ItemID[LIFETUBE] ) 
	{
		War3_SetBuffItem2(client,fHPRegen,ItemID[LIFETUBE],1.0);
	}
	if(item==ItemID[FORTIFIED_BRACER]){
	
		War3_SetBuffItem2(client,iAdditionalMaxHealth,ItemID[FORTIFIED_BRACER],10);
		War3_SetBuffItem(client,fHPRegenDeny,ItemID[FORTIFIED_BRACER],true);
		War3_HealToMaxHP(client,10);
	}
	if(item==ItemID[CASH_REGEN])
	{
		CASH_REGEN_PLAYERS[client]=true;
		War3_ChatMessage(client,"{lightgreen}My Piggy Bank Appears before you!{default}");
		EmitSoundToClient(client,MyPiggyBankSound);
	}
}

public OnItem2Lost(client,item){ //deactivate passives , client may have disconnected
//DP("lost %d %d",client,item);
	if(item==ItemID[POSTHASTE]){
		War3_SetBuffItem2(client,fMaxSpeed2,ItemID[POSTHASTE],1.0);
	}
	if(item==ItemID[TRINKET] ) // boots of speed
	{
		War3_SetBuffItem2(client,fHPRegen,ItemID[TRINKET],0.0);
	}
	if(item==ItemID[LIFETUBE] ) // boots of speed
	{
		War3_SetBuffItem2(client,fHPRegen,ItemID[LIFETUBE],0.0);
	}
	if(item==ItemID[FORTIFIED_BRACER]){
		War3_SetBuffItem2(client,iAdditionalMaxHealth,ItemID[FORTIFIED_BRACER],0);
		War3_SetBuffItem(client,fHPRegenDeny,ItemID[FORTIFIED_BRACER],false);
	}
	if(item==ItemID[CASH_REGEN])
	{
		CASH_REGEN_PLAYERS[client]=false;
	}
}
public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
//sh has no shop2 items
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			if(!Perplexed(victim,false)&&War3_GetOwnsItem2(victim,ItemID[SNAKE_BRACELET]))
			{
				if(W3Chance(0.05))
				{
					War3_DamageModPercent(0.0); //NO DAMAMGE
					W3MsgEvaded(victim,attacker);
				}
			}
		}
	}
}
					//mvm_bomb_deploy_reset_by_player      OnRoundDeployReset
public MVM_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	//g_tCash = CreateTimer(GetConVarFloat(cvarTime), Timer_Cash, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	//DP("mvm_begin_wave");
	Enable_Cash_Regen=true;
}

public MVM_OnTeamplayRoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	//ClearTimer(g_tCash);    // if you lose, a round this is the event on mvm
	//DP("teamplay_round_win");
	Enable_Cash_Regen=false;
	for(new i = 1; i <= MaxClients; i++)
		{
			if(CASH_REGEN_PLAYERS[i])
			{
				War3_ChatMessage(i,"{lightgreen}My Piggy Bank Vanishes!{default}");
				//CASH_REGEN_PLAYERS[i]=false;
				War3_SetOwnsItem2(i,ItemID[CASH_REGEN],false);
				War3_ChatMessage(i,"{lightgreen}Please wait 20 seconds for money corrections!{default}");
				CreateTimer(20.0,EndOfRound_Timer_Cash,i);
			}
		}
}

public MVM_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	Enable_Cash_Regen=false;
	for(new i = 1; i <= MaxClients; i++)
		{
			if(CASH_REGEN_PLAYERS[i])
			{
				War3_ChatMessage(i,"{lightgreen}My Piggy Bank Vanishes!{default}");
				//CASH_REGEN_PLAYERS[i]=false;
				War3_SetOwnsItem2(i,ItemID[CASH_REGEN],false);
				War3_ChatMessage(i,"{lightgreen}Please wait 20 seconds for money corrections!{default}");
				CreateTimer(20.0,EndOfRound_Timer_Cash,i);
			}
		}
}

public MVM_OnRoundComplete(Handle:event, const String:name[], bool:dontBroadcast)
{
	Enable_Cash_Regen=false;
	for(new i = 1; i <= MaxClients; i++)
		{
			if(CASH_REGEN_PLAYERS[i])
			{
				War3_ChatMessage(i,"{lightgreen}My Piggy Bank Vanishes!{default}");
				//CASH_REGEN_PLAYERS[i]=false;
				War3_SetOwnsItem2(i,ItemID[CASH_REGEN],false);
				War3_ChatMessage(i,"{lightgreen}Please wait 20 seconds for money corrections!{default}");
				CreateTimer(20.0,EndOfRound_Timer_Cash,i);
			}
		}
}

public Action:EndOfRound_Timer_Cash(Handle:g_Timer, any:i)
{
	if(!IsValidClient(i) || IsFakeClient(i))
	{
		//Plugin_Continue;
	}
	else
	{
		War3_ChatMessage(i,"{lightgreen}My Piggy Bank is correcting your funds!{default}");
		War3_ChatMessage(i,"{lightgreen}Don't forget to buy another My Piggy Bank, if you can afford it!{default}");
		new CurrentCash = GetEntProp(i, Prop_Send, "m_nCurrency");
		if (MVM_CURRENT_CASH[i]>CurrentCash)
		{
			CurrentCash=MVM_CURRENT_CASH[i];
		}
		if(CurrentCash <= 0 ) SetEntProp(i, Prop_Send, "m_nCurrency", 4000);
		if(CurrentCash <= 32767 - GetConVarInt(cvarAmount)) SetEntProp(i, Prop_Send, "m_nCurrency", CurrentCash + GetConVarInt(cvarAmount));
		MVM_CURRENT_CASH[i]=0;
	}

	return Plugin_Continue;
}

// pickup money
public War3Source_MvMCurrencyEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new i = GetEventInt(event, "player");
	//new currency = GetEventInt(event, "currency");

	if (ValidPlayer(i, true))
	{
		new CurrentCash = GetEntProp(i, Prop_Send, "m_nCurrency");
		if (MVM_CURRENT_CASH[i]<CurrentCash)
		{
			MVM_CURRENT_CASH[i]=CurrentCash;
		}
	}

}

public Action:Timer_Cash(Handle:g_Timer)
{
	//DP("Timer for Cash Regen");
	if(Enable_Cash_Regen==true)
	{
	//DP("if(Enable_Cash_Regen==true)");
	for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsValidClient(i) || IsFakeClient(i)) continue;
			//DP("Cash Regen MaxClients %i",i);
			if(CASH_REGEN_PLAYERS[i]==true)
			{
				new CurrentCash = GetEntProp(i, Prop_Send, "m_nCurrency");
				if (MVM_CURRENT_CASH[i]<CurrentCash)
				{
					MVM_CURRENT_CASH[i]=CurrentCash;
				}
				else
				{
					CurrentCash=MVM_CURRENT_CASH[i];
				}
				if(CurrentCash <= 32767 - GetConVarInt(cvarAmount)) SetEntProp(i, Prop_Send, "m_nCurrency", CurrentCash + GetConVarInt(cvarAmount));
			}
		}
	}
	return Plugin_Continue;
}

stock IsValidClient(client, bool:replay = true)
{
	if(client <= 0 || client > MaxClients || !IsClientInGame(client) || GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if(replay && (IsClientSourceTV(client) || IsClientReplay(client))) return false;
	return true;
}

stock ClearTimer(&Handle:g_Timer)
{
	if(g_Timer != INVALID_HANDLE)
	{
		KillTimer(g_Timer);
		g_Timer = INVALID_HANDLE;
	}
}

