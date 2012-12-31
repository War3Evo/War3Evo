#include "../DO NOT COMPILE, only used during holidays for TF2 only"
/*
	You can compile this code when you need to use it for a special event.
	Disabling it as it is not default enabled.
*/



//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////
///////MAKE SURE YOU MODIFY THIS SOURCE/////////////
///////TO SUIT YOUR SERVER AS THIS IS A DIRECT COPY////////////
///////FROM WAR3EVO WORKING DIRECTORY/////////////////////////////
//////////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////////




#pragma semicolon 1


#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/sdkhooks"

#define MDL_GIFT "models/props_halloween/halloween_gift.mdl"

// map[map#][location on map][pos]
// This in in X,Y,Z locations on the map
// You can use the GPS plugin we created to go inside your game
// and post the locations in your console.
// Use the locations and then switch them out here:

// These are the locations for pl_barnblitz.  We used pl_barnblitz
// for our version.  You can use any map you like if you wish.
new String:map_name[64]="pl_barnblitz";

new Float:map_location_1[3]={4871.966308,-1812.883666,-119.955833};
new Float:map_location_2[3]={4402.739746,-2048.039550,-39.968750};
new Float:map_location_3[3]={4163.636230,-1119.608520,-155.968750};
new Float:map_location_4[3]={3490.529541,-1205.116943,56.031250};
new Float:map_location_5[3]={3293.396240,-1749.676391,-204.936111};
new Float:map_location_6[3]={2171.561279,-1346.550048,-151.968750};
new Float:map_location_7[3]={2058.839111,-2643.777099,-151.968750};
new Float:map_location_8[3]={794.858093,-1830.855346,-95.968750};
new Float:map_location_9[3]={709.635437,-2741.802001,-97.037849};
new Float:map_location_10[3]={376.198547,-244.738464,144.031250};
new Float:map_location_11[3]={1115.369873,-134.232040,128.031250};
new Float:map_location_12[3]={1017.569824,-1454.200805,-107.556350};
new Float:map_location_13[3]={307.800262,-1856.203491,182.138534};
new Float:map_location_14[3]={-79.535194,-923.747802,118.068901};
new Float:map_location_15[3]={4234.540039,-1503.245117,-51.463966};

enum XSoundType
{
	smallwin=0, ///not defined
	bigwin,
	loser,
	pig,
}

// if the player found a gift this round.
// # of times a player found a gift.
new playerfoundgift[66];
//new bool:giftISonMap=false;
new bool:RoundRunning=false;

// You can change the sounds you like to use here:
new String:holyshitSound[128]="war3source/holysh.mp3";
new String:cheerSound[128]="war3source/cheer.mp3";
new String:ohdisappointSound[128]="war3source/ohdisappoint2.mp3";
new String:pigssound[128]="war3source/pigs2.mp3";

public Plugin:myinfo =
{
	name = "[TF2] War3Source Gifts",
	author = "El Diablo",
	description = "Spawn a halloween gifts in random locations.",
	version = "1.0",
	url = "http://www.war3source.com"
}

public OnPluginStart()
{
	if(!HookEventEx("teamplay_round_win",War3Evo_Gifts_RoundOverEvent)) //usual win xp
	{
		PrintToServer("[War3Evo Gifts] Could not hook the teamplay_round_win event.");
	}
	if(!HookEventEx("teamplay_setup_finished",War3Evo_Gifts_RoundStartEvent)) //usual win xp
	{
		PrintToServer("[War3Evo Gifts] Could not hook the teamplay_round_start event.");
	}
	//strcopy(levelupSound,sizeof(levelupSound),"war3source/levelupcaster.mp3");

	War3_PrecacheSound(holyshitSound);
	War3_PrecacheSound(cheerSound);
	War3_PrecacheSound(ohdisappointSound);
	War3_PrecacheSound(pigssound);
}

public OnMapStart()
{
	PrecacheModel(MDL_GIFT, true);
	CreateTimer(60.0,DoGift,_,TIMER_REPEAT);
}

public War3Evo_Gifts_RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	new String:mapname[128];
	GetCurrentMap(mapname, 128);
	if(StrEqual(mapname,map_name))
	{
		PrintCenterTextAll("GIFT HUNT!  FIND YOUR GIFTS, LIMIT 3 PER ROUND!");
		PrintToChatAll("GIFT HUNT!  FIND YOUR GIFTS, LIMIT 3 PER ROUND!");
		PrintToChatAll("GIFT HUNT!  FIND YOUR GIFTS, LIMIT 3 PER ROUND!");
		PrintToChatAll("GIFT HUNT!  FIND YOUR GIFTS, LIMIT 3 PER ROUND!");
		PrintToChatAll("GIFT HUNT!  FIND YOUR GIFTS, LIMIT 3 PER ROUND!");
	}


	RoundRunning=true;
}

public War3Evo_Gifts_RoundOverEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	RoundRunning=false;
	for(new i=1;i<=65;i++)
	{
		playerfoundgift[i]=0;
	}

}


public Action:DoGift(Handle:timer,any:client)
{
	//if(giftISonMap==true)
	//	return Plugin_Handled;
	if(!RoundRunning)
		return Plugin_Handled;

	new String:mapname[128];
	GetCurrentMap(mapname, 128);
	//DP("Map check: %s",mapname);

	if(!StrEqual(mapname,map_name))
	{
		RoundRunning=false;
		for(new i=1;i<=65;i++)
		{
			playerfoundgift[i]=0;
		}
		return Plugin_Handled;
	}

	new map=GetRandomInt(1, 15);
 	new Float:l_pos[3];
	switch(map)
	{
		case 1:
		{
			l_pos=map_location_1;
		}
		case 2:
		{
			l_pos=map_location_2;
		}
		case 3:
		{
			l_pos=map_location_3;
		}
		case 4:
		{
			l_pos=map_location_4;
		}
		case 5:
		{
			l_pos=map_location_5;
		}
		case 6:
		{
			l_pos=map_location_6;
		}
		case 7:
		{
			l_pos=map_location_7;
		}
		case 8:
		{
			l_pos=map_location_8;
		}
		case 9:
		{
			l_pos=map_location_9;
		}
		case 10:
		{
			l_pos=map_location_10;
		}
		case 11:
		{
			l_pos=map_location_11;
		}
		case 12:
		{
			l_pos=map_location_12;
		}
		case 13:
		{
			l_pos=map_location_13;
		}
		case 14:
		{
			l_pos=map_location_14;
		}
		case 15:
		{
			l_pos=map_location_15;
		}
	}


//	if(!SetTeleportEndPoint(client,l_pos))
//	{
//		PrintToServer("[SM] GIFTS-- Could not find spawn point.");
//		return Plugin_Handled;
//	}
	l_pos[2] -= 10;

	if(GetEntityCount() >= GetMaxEntities()-32)
	{
		PrintToServer("[SM] GIFTS-- Entity limit is reached. Can't spawn anymore fake gifts. Change maps.");
		return Plugin_Handled;
	}

	new ent = CreateEntityByName("prop_physics_override");
	if(ent==-1)
		return Plugin_Handled;
	SetEntityModel(ent,MDL_GIFT);
	DispatchKeyValue(ent, "StartDisabled", "false");
	DispatchSpawn(ent);
	TeleportEntity(ent, l_pos, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(ent, MOVETYPE_NONE);
	DispatchKeyValue(ent, "ExplodeRadius", "100");
	// You can comment out ExplodeDamage if you want no damage to your players.
	DispatchKeyValue(ent, "ExplodeDamage", "5");
	DispatchKeyValue(ent, "ExplodeDamage", "0");
	SetEntProp(ent, Prop_Data, "m_takedamage", 2);
	AcceptEntityInput(ent, "Enable");
	HookSingleEntityOutput(ent, "OnBreak", OnGiftBreak, true);
	SDKHook(ent, SDKHook_Touch, OnGiftTouch);

	//giftISonMap=true;

	//PrintCenterTextAll("War3Evo.com wishes you a Happy Holidays!");
	//PrintToChatAll("War3Evo.com wishes you a Happy Holidays!");


	return Plugin_Handled;
}

public OnClientDisconnect(client)
{
	playerfoundgift[client]=0;
}

public OnGiftTouch(entity, client)
{
	if(ValidPlayer(client))
	{
		new String:playername[64];
		GetClientName(client,playername,64);

		new XSoundType:awardsound;

		if(playerfoundgift[client]<=3)
		{
			new howmanymore=3-playerfoundgift[client];
			PrintToChatAll("%s you have found %i so far.",playername,playerfoundgift[client]);
			PrintToChatAll("%s, you can find %i more gifts this round.",playername,howmanymore);
			if(playerfoundgift[client]>=3)
			{
				PrintToChatAll("%s, BE WARNED... YOUR NEXT GIFT WILL STUN YOU!",playername,howmanymore);
				PrintToChatAll("%s, you need to wait till next round to get more gifts!",playername,howmanymore);
			}
			playerfoundgift[client]=playerfoundgift[client]+1;

			// random gifts
			new map=GetRandomInt(1, 25);

			switch(map)
			{
			//native W3GiveXPGold(client,W3XPAwardedBy:awardreason=XPAwardByGeneric,xpamount=0,goldamount=0,String:awardstringreason[]);
				case 1:  // gold
				{
					new GiftAmount=GetRandomInt(25, 50);
					W3GiveXPGold(client,XPAwardByGeneric,0,GiftAmount,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i GOLD!",playername,playername,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i GOLD!",playername,playername,GiftAmount);
					awardsound=smallwin;
				}
				case 2:
				{
					new GiftAmount=GetRandomInt(50, 100);
					W3GiveXPGold(client,XPAwardByGeneric,0,GiftAmount,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i GOLD!",playername,playername,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i GOLD!",playername,playername,GiftAmount);
					awardsound=smallwin;
				}
				case 3:
				{
					new GiftAmount=GetRandomInt(100, 150);
					W3GiveXPGold(client,XPAwardByGeneric,0,GiftAmount,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i GOLD!",playername,playername,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i GOLD!",playername,playername,GiftAmount);
					awardsound=smallwin;
				}
				case 4:
				{
					new GiftAmount=GetRandomInt(150, 200);
					W3GiveXPGold(client,XPAwardByGeneric,0,GiftAmount,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i GOLD!",playername,playername,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i GOLD!",playername,playername,GiftAmount);
					awardsound=smallwin;
				}
				case 5:
				{
					new GiftAmount=GetRandomInt(200, 250);
					W3GiveXPGold(client,XPAwardByGeneric,0,GiftAmount,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i GOLD!",playername,playername,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i GOLD!",playername,playername,GiftAmount);
					awardsound=smallwin;
				}
				case 6:
				{
					new GiftAmount=GetRandomInt(250, 300);
					W3GiveXPGold(client,XPAwardByGeneric,0,GiftAmount,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i GOLD!",playername,playername,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i GOLD!",playername,playername,GiftAmount);
					awardsound=smallwin;
				}
				case 7:  //xp
				{
					new GiftAmount=GetRandomInt(100, 200);
					W3GiveXPGold(client,XPAwardByGeneric,GiftAmount,0,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					awardsound=smallwin;
				}
				case 8:
				{
					new GiftAmount=GetRandomInt(200, 300);
					W3GiveXPGold(client,XPAwardByGeneric,GiftAmount,0,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					awardsound=smallwin;
				}
				case 9:
				{
					new GiftAmount=GetRandomInt(300, 400);
					W3GiveXPGold(client,XPAwardByGeneric,GiftAmount,0,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					awardsound=smallwin;
				}
				case 10:
				{
					new GiftAmount=GetRandomInt(500, 600);
					W3GiveXPGold(client,XPAwardByGeneric,GiftAmount,0,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					awardsound=smallwin;
				}
				case 11:
				{
					new GiftAmount=GetRandomInt(700, 800);
					W3GiveXPGold(client,XPAwardByGeneric,GiftAmount,0,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					awardsound=smallwin;
				}
				case 12:
				{
					new GiftAmount=GetRandomInt(900, 1000);
					W3GiveXPGold(client,XPAwardByGeneric,GiftAmount,0,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					awardsound=smallwin;
				}
				case 13:
				{
					new GiftAmount=GetRandomInt(1000, 2000);
					W3GiveXPGold(client,XPAwardByGeneric,GiftAmount,0,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					awardsound=smallwin;
				}
				case 14:
				{
					new GiftAmount=GetRandomInt(3000, 4000);
					W3GiveXPGold(client,XPAwardByGeneric,GiftAmount,0,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					awardsound=smallwin;
				}
				case 15:
				{
					new GiftAmount=GetRandomInt(4000, 5000);
					W3GiveXPGold(client,XPAwardByGeneric,GiftAmount,0,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i XP!",playername,playername,GiftAmount);
					awardsound=bigwin;
				}
				case 16:  // XP & Gold
				{
					new GiftAmountXP=GetRandomInt(500, 5000);
					new GiftAmount=GetRandomInt(100, 250);
					W3GiveXPGold(client,XPAwardByGeneric,GiftAmountXP,GiftAmount,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i XP and %i GOLD!",playername,playername,GiftAmountXP,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i XP and %i GOLD!",playername,playername,GiftAmountXP,GiftAmount);
					awardsound=smallwin;
				}
				case 17:  // XP & Gold
				{
					new GiftAmountXP=GetRandomInt(5000, 10000);
					new GiftAmount=GetRandomInt(100, 250);
					W3GiveXPGold(client,XPAwardByGeneric,GiftAmountXP,GiftAmount,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i XP and %i GOLD!",playername,playername,GiftAmountXP,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i XP and %i GOLD!",playername,playername,GiftAmountXP,GiftAmount);
					awardsound=smallwin;
				}
				case 18:  // XP & Gold
				{
					new GiftAmountXP=GetRandomInt(10000, 15000);
					new GiftAmount=GetRandomInt(100, 250);
					W3GiveXPGold(client,XPAwardByGeneric,GiftAmountXP,GiftAmount,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i XP and %i GOLD!",playername,playername,GiftAmountXP,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i XP and %i GOLD!",playername,playername,GiftAmountXP,GiftAmount);
					awardsound=smallwin;
				}
				case 19:  // XP & Gold
				{
					new GiftAmountXP=GetRandomInt(15000, 20000);
					new GiftAmount=GetRandomInt(100, 250);
					W3GiveXPGold(client,XPAwardByGeneric,GiftAmountXP,GiftAmount,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i XP and %i GOLD!",playername,playername,GiftAmountXP,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i XP and %i GOLD!",playername,playername,GiftAmountXP,GiftAmount);
					awardsound=bigwin;
				}
				case 20:  // XP & Gold
				{
					new GiftAmountXP=GetRandomInt(20000, 25000);
					new GiftAmount=GetRandomInt(250, 500);
					W3GiveXPGold(client,XPAwardByGeneric,GiftAmountXP,GiftAmount,"finding this gift on our server!");
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i XP and %i GOLD!",playername,playername,GiftAmountXP,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i XP and %i GOLD!",playername,playername,GiftAmountXP,GiftAmount);
					awardsound=bigwin;
				}
				case 21:  // DIAMONDS
				{
					new GiftAmount=GetRandomInt(50, 250);
					new newdiamonds = War3_GetDiamonds(client) + GiftAmount;
					War3_SetDiamonds(client,newdiamonds);
					PrintCenterTextAll("%s found War3Evo Holiday Gift! %s Gains %i DIAMONDS!",playername,playername,GiftAmount);
					PrintToChatAll("%s found War3Evo Holiday Gift! %s Gains %i DIAMONDS!",playername,playername,GiftAmount);
					awardsound=smallwin;
				}
				case 22:  // BULLSHIT 1
				{
					//sm_timebomb <#userid|name>
					ServerCommand("sm_timebomb %s",playername);
					PrintCenterTextAll("%s found War3Evo Holiday Joke! %s Gains Timebomb!",playername,playername);
					PrintToChatAll("%s found War3Evo Holiday Joke! %s Gains Timebomb!",playername,playername);
					awardsound=loser;
				}
				case 23:  // BULLSHIT 1
				{
					//sm_timebomb <#userid|name>
					ServerCommand("sm_timebomb %s",playername);
					PrintCenterTextAll("%s found War3Evo Holiday Joke! %s Gains Timebomb!",playername,playername);
					PrintToChatAll("%s found War3Evo Holiday Joke! %s Gains Timebomb!",playername,playername);
					awardsound=loser;
				}
				case 24:  // BULLSHIT 2
				{
					//sm_beacon <#userid|name>
					ServerCommand("sm_beacon %s",playername);
					PrintCenterTextAll("%s found War3Evo Holiday Joke! %s Gains Beacon!",playername,playername);
					PrintToChatAll("%s found War3Evo Holiday Joke! %s Gains Beacon!",playername,playername);
					awardsound=loser;
				}
				case 25:  // BULLSHIT 2
				{
					//sm_beacon <#userid|name>
					ServerCommand("sm_beacon %s",playername);
					PrintCenterTextAll("%s found War3Evo Holiday Joke! %s Gains Beacon!",playername,playername);
					PrintToChatAll("%s found War3Evo Holiday Joke! %s Gains Beacon!",playername,playername);
					awardsound=loser;
				}
			}
		}
		else
		{
			TF2_StunPlayer(client, 6.0, _, TF_STUNFLAGS_LOSERSTATE);
			PrintCenterTextAll("%s stop hogging all the gifts!",playername,playername);
			PrintToChatAll("%s stop hogging all the gifts!",playername);
			awardsound=pig;
		}
/*
enum XSoundType
{
	smallwin=0, ///not defined
	bigwin,
	loser,
	pig,
}
*/

		switch(awardsound)
		{
		//native W3GiveXPGold(client,W3XPAwardedBy:awardreason=XPAwardByGeneric,xpamount=0,goldamount=0,String:awardstringreason[]);
			case smallwin:  // gold
			{
				if(IsPlayerAlive(client)){
					EmitSoundToAll(cheerSound,client);
				}
				else{
					EmitSoundToClient(client,cheerSound);
				}
			}
			case bigwin:  // gold
			{
				if(IsPlayerAlive(client)){
					EmitSoundToAll(holyshitSound,client);
				}
				else{
					EmitSoundToClient(client,holyshitSound);
				}
			}
			case loser:  // gold
			{
				if(IsPlayerAlive(client)){
					EmitSoundToAll(ohdisappointSound,client);
				}
				else{
					EmitSoundToClient(client,ohdisappointSound);
				}
			}
			case pig:  // gold
			{
				if(IsPlayerAlive(client)){
					EmitSoundToAll(pigssound,client);
				}
				else{
					EmitSoundToClient(client,pigssound);
				}
			}
		}
		//playerfoundgift[client]=playerfoundgift[client]+1;
	}

	OnGiftBreak(NULL_STRING, entity, client, 0.0);
}

public OnGiftBreak(const String:output[], caller, activator, Float:delay)
{
	UnhookSingleEntityOutput(caller, "OnBreak", OnGiftBreak);
	AcceptEntityInput(caller,"kill");
	//giftISonMap=false;
}


/*
SetTeleportEndPoint(client,Float:g_pos[3])
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
*/
