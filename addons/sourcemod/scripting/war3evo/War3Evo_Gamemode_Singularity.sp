#pragma semicolon 1

#include "W3SIncs/War3Source_Interface"  

public Plugin:myinfo = 
{
	name = "War3Source - Gamemode - Singularity",
	author = "Ted Theodore Logan",
	description = "Buying items is disabled, everyone spawns with 1 random item. Kill enemys to steal their item!",
	version = "1.0.3",
};

new Handle:SingularityActivatedCvar; // Singularity Mode activated?
new Handle:MaxItemsCvar; // How much items can one hold?
new Handle:WhitelistedItemsCvar; // Whitelisted Items
new Handle:RestrictedItemsCvar; // Restricted Items
new bool:bPlayingSingularity = false;

public OnPluginStart()
{
	SingularityActivatedCvar = CreateConVar("war3_singularity","1","Is Singularity activated?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	MaxItemsCvar = CreateConVar("war3_singularity_max_items","5","How many items can one hold in Singularity?");
	RestrictedItemsCvar = CreateConVar("war3_singularity_restrict","tome,mole,uberme,cgold1k,cgold10k","Disallow players to spawn with items, shortname separated by comma only ie: 'tome,mole'");
	WhitelistedItemsCvar = CreateConVar("war3_singularity_allow","tome","Allow players to buy items, shortname separated by comma only ie: 'tome,necklace'");
	
	HookConVarChange(SingularityActivatedCvar, ChangedSingularityCvar);
	//CreateTimer(30.0, AnnouncerTimer, _, TIMER_REPEAT);
}

public OnMapStart()
{
	if(GetConVarBool(SingularityActivatedCvar))
		bPlayingSingularity = true;
}

public RemoveAllItems()
{
	for(new client = 1; client <= MaxClients; client++)
		if(ValidPlayer(client))
			for(new x=1 ; x <= W3GetItemsLoaded(); x++)
				War3_SetOwnsItem(client, x, false);
}

public IsItemAllowed(String: shortname[])
{
	decl String:cvarstr[100];
	decl String:exploded[MAXITEMS][16];
	decl num;
	GetConVarString(WhitelistedItemsCvar, cvarstr, sizeof(cvarstr));
	if(strlen(cvarstr) > 0)
	{
		num = ExplodeString(cvarstr, ",", exploded, MAXITEMS, 16);
		for(new i=0; i < num; i++)
		{
			if(StrEqual(exploded[i], shortname, false))
				return true;
		}
	}
	return false;
}


public IsItemRestricted(String: shortname[])
{
	decl String:cvarstr[100];
	decl String:exploded[MAXITEMS][16];
	decl num;
	GetConVarString(RestrictedItemsCvar, cvarstr, sizeof(cvarstr));
	if(strlen(cvarstr) > 0)
	{
		num = ExplodeString(cvarstr, ",", exploded, MAXITEMS, 16);
		for(new i=0; i < num; i++)
		{
			if(StrEqual(exploded[i], shortname, false))
				return true;
		}
	}
	return false;
}

public GiveRandomItem(client)
{
	decl String:shortname[64];
	new random_item = GetRandomInt(1, W3GetItemsLoaded()); // 0 is the zeroth item
	W3GetItemShortname(random_item, shortname, sizeof(shortname));
	
	while IsItemRestricted(shortname) do
	{
		random_item = GetRandomInt(1, W3GetItemsLoaded()); // 0 is the zeroth item
		W3GetItemShortname(random_item, shortname, sizeof(shortname));
	}
	
	if(!War3_GetOwnsItem(client, random_item))
	{
		War3_SetOwnsItem(client, random_item, true);
		
		decl String:itemname[64];
		W3GetItemName(random_item, itemname, sizeof(itemname));
		War3_ChatMessage(client, "Received {green}\"%s\"", itemname);
	}
}

public AmountOfItems(client)
{
	new amount = 0;
	
	for(new x=1; x <= W3GetItemsLoaded(); x++)
		if(War3_GetOwnsItem(client, x))
			amount++;
	
	return amount;
}

public ChangedSingularityCvar(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	bPlayingSingularity = GetConVarBool(SingularityActivatedCvar);
	if(bPlayingSingularity)
	{
		PrintCenterTextAll("Activated Singularity!");
		RemoveAllItems();
		for(new client = 1; client <= MaxClients; client++)
			if(ValidPlayer(client))
				GiveRandomItem(client);
	}
	else
	{
		PrintCenterTextAll("Deactivated Singularity!");
		RemoveAllItems();
	}
}

public OnWar3Event(W3EVENT:event,client)
{
	if(bPlayingSingularity)
		if(event == CanBuyItem)
		{
			new itemID = W3GetVar(EventArg1);
			decl String:itemname[64];
			W3GetItemShortname(itemID, itemname, sizeof(itemname));
			
			if(IsItemAllowed(itemname)) { W3SetVar(EventArg2, 1);} // Allow all items to be dropped.
/*			{
				W3SetVar(EventArg2, 1);
			}
			else
			{
				W3SetVar(EventArg2, 0);
				PrintHintText(client, "You can't buy this item during Singularity!");
			}*/
		}
		
		else if(event == OnDeathPre)
		{
			new attacker = W3GetVar(EventArg1);
			new victim = client;
			new attacker_items = AmountOfItems(attacker);
			new MAX_ITEMS = GetConVarInt(MaxItemsCvar);
			
			if(ValidPlayer(attacker, true) && attacker != victim)
				if(MAX_ITEMS > attacker_items)
				{
					for(new x=1; x <= W3GetItemsLoaded(); x++)
						if(War3_GetOwnsItem(victim, x))
							if(!War3_GetOwnsItem(attacker, x))
							{
								decl String:itemname[64];
								W3GetItemName(x, itemname, sizeof(itemname));
								War3_SetOwnsItem(attacker, x, true);						
								PrintHintText(attacker, "Stole \"%s\"", itemname);
								if(attacker_items + 1 == MAX_ITEMS)
								{
									decl String:playerName[32];
									GetClientName(attacker, playerName, 32);
									//PrintCenterTextAll("%s has maxed out his loadout!", playerName);
								}
								break; // Only steal 1 item!
							}
				}
				else
					PrintHintText(attacker, "You can't steal anymore items!");
		}
}

public OnWar3EventSpawn(client)
{
	if(bPlayingSingularity)
		// Prevent people from cheating by simply switching class in TF2	
		if(AmountOfItems(client) == 0)
			GiveRandomItem(client);
}

/*
public Action:AnnouncerTimer(Handle:timer,any:userid)
{
	if(bPlayingSingularity)
	{
		new best_client = 0; // client id of the client with most items
		new client_items = 0;
		new max_items = 0; // amount of items the best player has
		
		for(new client = 1; client <= MaxClients; client++)
			if(ValidPlayer(client))
			{
				client_items = AmountOfItems(client);
				if(client_items > max_items)
				{
					max_items = client_items;
					best_client = client;
				}
			}
	
		if(max_items > 1)
		{
			decl String:playerName[32];
			GetClientName(best_client, playerName, 32);
			PrintCenterTextAll("%s is the biggest item whore with  %i items!", playerName, max_items);
		}
	}
} */