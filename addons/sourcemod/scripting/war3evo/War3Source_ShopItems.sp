/**
 * File: War3Source_ShopItems.sp
 * Description: The shop items that come with War3Source.
 * Author(s): Anthony Iacono
 *--
 *-- Add all shopmenu items into the code, including War3Evo shopmenu items.
 *-- El Diablo
 *-- www.war3evo.com
 */
 
#pragma semicolon 1

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/sdkhooks"

#include <cstrike>

//plates
new String:helmSound0[]="physics/metal/metal_solid_impact_bullet1.wav";
new String:helmSound1[]="physics/metal/metal_solid_impact_bullet2.wav";
new String:helmSound2[]="physics/metal/metal_solid_impact_bullet3.wav";
new String:helmSound3[]="physics/metal/metal_solid_impact_bullet4.wav";

//global
//new ownerOffset;


enum{
	ANKH=0,
	BOOTS,
	CLAW,
	CLOAK,
	MASK,
	NECKLACE,
	FROST,
	HEALTH,
	TOME, 
	RESPAWN,
	SOCK,
	GLOVES,
	RING,
	MOLE,
	OIL,
	PLATES,
	HELM,
	SHIELD,
	GAUNTLET,
	FIREORB,
	HOPE,
	COURAGE,
	ARMBAND,
	ANTIWARD,
	INSTAUBER,
	ARMOR_PIERCING
}

new shopItem[MAXITEMS];//
new bool:bDidDie[65]; // did they die before spawning?
new Handle:BootsSpeedCvar;
new ActiveWeaponOffset;
new Handle:ClawsAttackCvar;
new Handle:MaskDeathCvar;
new bool:bFrosted[65]; // don't frost before unfrosted
new Handle:OrbFrostCvar;
new Handle:TomeCvar;
new bool:bSpawnedViaScrollRespawn[65]; // don't allow multiple scroll respawns
new Handle:SockCvar;
new Handle:RegenHPCSCvar;
new Handle:RegenHPTFCvar;

new Handle:MoleDeathmatchCvar;
new String:sOldModel[65][256]; // reset model after 10 seconds

new String:buyTombSound[256]; //="war3source/tomes.mp3";
new String:masksnd[256]; //="war3source/mask.mp3";
new maskSoundDelay[66];

// shield
new MoneyOffsetCS;
new Handle:ShieldRestrictionCvar;

// fireorb
new Float:g_fExtinguishNow[MAXPLAYERS];
const Float:fSecondsTillExtinguish = 3.0;



// Offsets
new OriginOffset,MyWeaponsOffset,AmmoOffset,Clip1Offset;

public Plugin:myinfo = 
{
	name = "W3S - Shopitems",
	author = "PimpinJuice",
	description = "The shop items that come with War3Source.",
	version = "1.0.0.0",
	url = "http://pimpinjuice.net/"
};

public OnPluginStart()
{
	HookEvent("round_start",RoundStartEvent);
	OriginOffset=FindSendPropOffs("CBaseEntity","m_vecOrigin");
	MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
	
	ActiveWeaponOffset=FindSendPropOffs("CBaseCombatCharacter","m_hActiveWeapon"); 
	
	Clip1Offset=FindSendPropOffs("CBaseCombatWeapon","m_iClip1");
	AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
	BootsSpeedCvar=CreateConVar("war3_shop_boots_speed","1.2","Boots speed, 1.2 is default");
	ClawsAttackCvar=CreateConVar("war3_shop_claws_damage",GameTF()?"10":"6","Claws of attack additional damage per bullet (CS) or per second (TF)");
	MaskDeathCvar=CreateConVar("war3_shop_mask_percent","0.50","Percent of damage rewarded for Mask of Death, from 0.0 - 1.0");
	OrbFrostCvar=CreateConVar("war3_shop_orb_speed","0.6","Orb of Frost speed, 1.0 is normal speed, 0.6 default for orb.");
	TomeCvar=CreateConVar("war3_shop_tome_xp","10","Experience awarded for Tome of Experience.");
	SockCvar=CreateConVar("war3_shop_sock_gravity","0.4","Gravity used for Sock of Feather, 0.4 is default for sock, 1.0 is normal gravity");
	RegenHPCSCvar=CreateConVar("war3_shop_ring_hp_cs","2","How much HP is regenerated for CS.");
	RegenHPTFCvar=CreateConVar("war3_shop_ring_hp_tf","4","How much HP is regenerated for TF.");

	MoleDeathmatchCvar=CreateConVar("war3_shop_mole_dm","0","Set this to 1 if server is deathmatch");
	
	//RegConsoleCmd("frostme",cmdfrostme);

	//CreateTimer(1.0,SecondLoop,_,TIMER_REPEAT);
	CreateTimer(0.1,PointOneSecondLoop,_,TIMER_REPEAT);
	CreateTimer(10.0,GrenadeLoop,_,TIMER_REPEAT);
	
	for(new i=1;i<=MaxClients;i++){
		maskSoundDelay[i]=War3_RegisterDelayTracker();
	}
	//plates & helm
	War3_PrecacheSound(helmSound0);
	War3_PrecacheSound(helmSound1);
	War3_PrecacheSound(helmSound2);
	War3_PrecacheSound(helmSound3);

	LoadTranslations("w3s.item.helm.phrases");
	LoadTranslations("w3s.item.hope.phrases");   // barrier of hope
	LoadTranslations("w3s.item.courage.phrases");
	LoadTranslations("w3s.item.antiward.phrases");
	LoadTranslations("w3s.item.uberme.phrases");
	LoadTranslations("w3s.item.fireorb.phrases");

	//shield
	ShieldRestrictionCvar=CreateConVar("war3_shop_shield_restriction","0","Set this to 1 if you want to forbid necklace+shield. 0 default");
	LoadTranslations("w3s.item.shield.phrases");
	if(GAMECSANY){
		MoneyOffsetCS=FindSendPropInfo("CCSPlayer","m_iAccount");
	}

	//ownerOffset = FindSendPropInfo("CBaseObject", "m_hBuilder");
}
new bool:war3ready;
public OnWar3LoadRaceOrItemOrdered(num)
{
	if(num==40){
	
		war3ready=true;
		for(new x=0;x<MAXITEMS;x++)
			shopItem[x]=0;
		if(War3_GetGame()==Game_CS) 
			shopItem[ANKH]=War3_CreateShopItemT("ankh",3,2000);
		
		shopItem[BOOTS]=War3_CreateShopItemT("boot",3,2500);
		
		shopItem[CLAW]=War3_CreateShopItemT("claw",3,5000);
		
		shopItem[CLOAK]=War3_CreateShopItemT("cloak",2,1000);
		
		shopItem[MASK]=War3_CreateShopItemT("mask",3,1500);
		
		shopItem[NECKLACE]=War3_CreateShopItemT("lace",2,800);
		//War3_CreateShopItemRef(shopItem[NECKLACE],"necklace_immunity");
		
		//if(War3_GetGame()!=Game_TF) 
		shopItem[FROST]=War3_CreateShopItemT("orb",3,2000);
		
		shopItem[RING]=War3_CreateShopItemT("ring",3,1500);
		
		
		if(War3_GetGame()!=Game_TF) 
			shopItem[HEALTH]=War3_CreateShopItemT("health",3,3000);
		
		shopItem[TOME]=War3_CreateShopItemT("tome",10,10000);
		War3_SetItemProperty(	shopItem[TOME], ITEM_USED_ON_BUY,true);
	
		if(War3_GetGame()!=Game_TF) 
			shopItem[RESPAWN]=War3_CreateShopItemT("scroll",15,6000);
		
		shopItem[SOCK]=War3_CreateShopItemT("sock",2,1500);
		
		if(War3_GetGame()==Game_CS) 
			shopItem[GLOVES]=War3_CreateShopItemT("glove",5,3000);
		
		
		if(War3_GetGame()!=Game_TF) 
			shopItem[MOLE]=War3_CreateShopItemT("mole",10,10000);

		shopItem[OIL]=War3_CreateShopItem("Oil of Penetration","oil","Coats your weapons with ability to penetrate plates and helm.",8,3500);

		shopItem[PLATES]=War3_CreateShopItem("Plates of Protection","plate","Prevents All Damage to Chest.",10,3500);

		shopItem[HELM]=War3_CreateShopItemT("helm",10,3500);

		shopItem[SHIELD]=War3_CreateShopItemT("shield",3,2000);

		shopItem[GAUNTLET]=War3_CreateShopItem("Gauntlet of Endurance","gauntlet","Increases max health by 50 HP",5,3000);

		shopItem[FIREORB]=War3_CreateShopItemT("fireorb", 10, 4000);

		shopItem[HOPE]=War3_CreateShopItemT("hope",10,3000);

		shopItem[COURAGE]=War3_CreateShopItemT("courage",4,3000);

		shopItem[ARMBAND]=War3_CreateShopItem("Armband of Repetition","armband","Increases attack speed by 15%",10,3000);

		shopItem[ANTIWARD]=War3_CreateShopItemT("antiward",3,3000);

		shopItem[INSTAUBER]=War3_CreateShopItemT("uberme",100,3000);
		War3_TFSetItemClasses(shopItem[INSTAUBER],medic);

		shopItem[ARMOR_PIERCING]=War3_CreateShopItem("Physical Armor Piercing","piercing",
		"Upgrades your weapons with ability to penetrate physical armor.\nRequires Oil of Penetration",20,3500);
	}
}
public OnMapStart()
{
	if(GAMECSGO){
		strcopy(buyTombSound,sizeof(buyTombSound),"music/war3source/tomes.mp3");
		strcopy(masksnd,sizeof(masksnd),"music/war3source/mask.mp3");
	}
	else
	{
		strcopy(buyTombSound,sizeof(buyTombSound),"war3source/tomes.mp3");
		strcopy(masksnd,sizeof(masksnd),"war3source/mask.mp3");
	}

	War3_PrecacheSound(buyTombSound);
	War3_PrecacheSound(masksnd);
	if(GAMECSGO) {
		// Theese models aren't always precached
		PrecacheModel("models/player/ctm_gsg9.mdl");
		PrecacheModel("models/player/tm_leet.mdl");
	}
}


//public Action:SecondLoop(Handle:timer,any:data)
//{
//
//}

public Action:PointOneSecondLoop(Handle:timer,any:data)
{
	if(war3ready){
		doCloak();
	}
	for(new client=1; client <= MaxClients; client++)
	{
		if(ValidPlayer(client, true))
		{
			new Float: fExtinguishTime = g_fExtinguishNow[client];
			if (fExtinguishTime > 0.0 && fExtinguishTime <= GetGameTime())
			{
				ExtinguishEntity(client);
				TF2_RemoveCondition(client, TFCond_OnFire);

				g_fExtinguishNow[client] = 0.0;
				War3_ChatMessage(client, "You have been extinguished...");
			}
		}
	}
}

public doCloak() //this loop should detec weapon chnage and add a new alpha
{
	for(new x=1;x<=MaxClients;x++)
	{
		//PrintToServer("%s",shopItem[CLOAK]);
		if(ValidPlayer(x,true)&&War3_GetOwnsItem(x,shopItem[CLOAK]))
		{
			War3_SetBuffItem(x,fInvisibilityItem,shopItem[CLOAK],0.5); // was 0.6
			
			///knife? melle?
			new ent=GetEntDataEnt2(x,ActiveWeaponOffset);//MyWeaponsOffset);//ActiveWeaponOffset);
			if(ent>0 && IsValidEdict(ent))
			{
				decl String:wepName[64];
				GetEdictClassname(ent,wepName,sizeof(wepName));
				if(StrEqual(wepName,"weapon_knife",false))
				{
					War3_SetBuffItem(x,fInvisibilityItem,shopItem[CLOAK],0.4);
				}
			}
		}
	}
	//CreateTimer(1.0,Cloak);
}

//gloves giving nades
public Action:GrenadeLoop(Handle:timer,any:data)
{
	if(war3ready&&War3_GetGame()==Game_CS){
		
		for(new x=1;x<=MaxClients;x++)
		{
			if(ValidPlayer(x,true)&&War3_GetOwnsItem(x,shopItem[GLOVES]))
			{
				new bool:has_grenade=false;
				for(new s=0;s<10;s++)
				{
					new ent=War3_CachedWeapon(x,s);
					if(ent>0 && IsValidEdict(ent))
					{
						decl String:wepName[64];
						GetEdictClassname(ent,wepName,sizeof(wepName));
						if(StrEqual(wepName,"weapon_hegrenade",false))
						{
							has_grenade=true;
						}
					}
				}
				if(!has_grenade)
				{
					GivePlayerItem(x,"weapon_hegrenade");
					PrintHintText(x,"%T","+HEGRENADE",x);
				}
			}
		}
	}
	//CreateTimer(10.0,Grenade);
}

public OnW3Denyable(W3DENY:event,client)
{
	if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == shopItem[SHIELD]) && (War3_GetOwnsItem(client, shopItem[NECKLACE]) && GetConVarBool(ShieldRestrictionCvar)))
	{
		W3Deny();
		War3_ChatMessage(client, "Cannot wear Necklace and Shield at the same time.");
	}
	if((event == DN_CanBuyItem1) && (W3GetVar(EventArg1) == shopItem[NECKLACE]) && (War3_GetOwnsItem(client, shopItem[SHIELD])) && GetConVarBool(ShieldRestrictionCvar))
	{
		W3Deny();
		War3_ChatMessage(client, "Cannot wear Necklace and Shield at the same time.");
	}
}


public OnItemPurchase(client,item)
{
	if(item==shopItem[BOOTS] /*&& War3_GetGame()!=Game_TF*/) // boots of speed
	{
		War3_SetBuffItem(client,fMaxSpeed,shopItem[BOOTS],GetConVarFloat(BootsSpeedCvar));
		//War3_SetMaxSpeed(client,GetConVarFloat(BootsSpeedCvar),shopItem[1]);
		if(IsPlayerAlive(client))
			War3_ChatMessage(client,"%T","You strap on your boots",client);
	}
	if(item==shopItem[SOCK])
	{
		War3_SetBuffItem(client,fLowGravityItem,shopItem[SOCK],GetConVarFloat(SockCvar));
		//War3_SetMinGravity(client,GetConVarFloat(SockCvar),shopItem[10]);
		if(IsPlayerAlive(client))
			War3_ChatMessage(client,"%T","You pull on your socks",client);
	}
	if(item==shopItem[NECKLACE]) // immunity
	{
		War3_SetBuffItem(client,bImmunityUltimates,shopItem[NECKLACE],true);
	}
	if(War3_GetGame()!=Game_TF && item==shopItem[HEALTH] && IsPlayerAlive(client)) // health
	{
		//SetEntityHealth(client,GetClientHealth(client)+50);
		//War3_SetMaxHP(client,War3_GetMaxHP(client)+50);
		War3_SetBuffItem(client,iAdditionalMaxHealth,shopItem[HEALTH],50);
		War3_SetBuffItem(client,fHPRegenDeny,shopItem[HEALTH],true);
			
		War3_ChatMessage(client,"%T","+50 HP",client);
	}
	if(item==shopItem[TOME]) // tome of xp
	{
		new race=War3_GetRace(client);
		new add_xp=GetConVarInt(TomeCvar);
		if(add_xp<0)	add_xp=0;
		new bool:SteamCheck=false;
		if(add_xp!=0&&War3_IsInSteamGroup(client))
		{
			add_xp=add_xp*2;
			SteamCheck=true;
		}
		if(add_xp!=0&&ValidPlayer(client))
		{
			new AdminId:AdminID = GetUserAdmin(client);
			if (AdminID!=INVALID_ADMIN_ID)
			{
				if(GetAdminFlag(GetUserAdmin(client), Admin_Reservation))
				{
					//VIP
					if(SteamCheck)
						add_xp=add_xp*2; // Double more!  Which makes 4x
					else
						add_xp=add_xp*4; // Double more!  Which makes 4x
				}
			}
		}
		War3_SetXP(client,race,War3_GetXP(client,race)+add_xp);
		W3DoLevelCheck(client);
		War3_SetOwnsItem(client,item,false);
		War3_ChatMessage(client,"%T","+{amount} XP",client,add_xp);
		War3_ShowXP(client);
		if(IsPlayerAlive(client)){
			EmitSoundToAll(buyTombSound,client);
		}
		else{
			EmitSoundToClient(client,"war3source/tomes.mp3");
		}
		
	}
	if(item==shopItem[RING]) 
	{
		new Float:regen_hp=GetConVarFloat((War3_GetGame()==Game_CS)?RegenHPCSCvar:RegenHPTFCvar);
		War3_SetBuffItem(client,fHPRegen,shopItem[RING],regen_hp);
	}
	if(War3_GetGame()!=Game_TF && item==shopItem[RESPAWN])
	{
		bSpawnedViaScrollRespawn[client]=false;
		
		if(!IsPlayerAlive(client)&&GetClientTeam(client)>1){
			War3_ChatMessage(client,"%T","You will be respawned",client);
			CreateTimer(0.2,RespawnPlayerViaScrollRespawn,client);
			//CreateTimer(0.5,Reincarnate,GetClientUserId(client));
		}
		else{
			War3_ChatMessage(client,"%T","Next time you die you will respawn",client);
		}
	}
	if(item==shopItem[SHIELD])
	{
		if(ValidPlayer(client))
		{
			War3_SetBuffItem(client,bImmunitySkills,shopItem[SHIELD],true);
			War3_SetOwnsItem(client,item,true);
		}
	}

	if(item==shopItem[GAUNTLET])
	{
		if(ValidPlayer(client))
		{
			War3_SetBuffItem(client,iAdditionalMaxHealth,shopItem[GAUNTLET],50);
		}
	}

	if(item==shopItem[HOPE]&&ValidPlayer(client))
	{
		War3_SetOwnsItem(client,shopItem[HOPE],true);
		War3_SetBuffItem(client,bImmunityItems,shopItem[HOPE],true);
	}

	if(item==shopItem[COURAGE]&&ValidPlayer(client))
	{
		//War3_SetOwnsItem(client,item,true);
		//War3_SetBuffItem(client,fArmorPhysical,item,7.5); //mvm
		War3_SetBuffItem(client,fArmorPhysical,shopItem[COURAGE],3.0); //mvm
	}
	if(item==shopItem[ARMBAND]&&ValidPlayer(client))
	{
		War3_SetBuffItem(client,fAttackSpeed,shopItem[ARMBAND],1.15);
	}
	if(item==shopItem[ANTIWARD]&&ValidPlayer(client))
	{
		War3_SetBuffItem(client,bImmunityWards,shopItem[ANTIWARD],true);
	}
	if(item==shopItem[INSTAUBER]&&ValidPlayer(client))
	{
		if(TF2_GetPlayerClass(client)==TFClass_Medic)
		{
			if(GetEntProp(client, Prop_Send, "m_iClass") == 5)
			{
				//`EquipPlayerWeapon(client, tf_weapon_medigun);
				TF_SetUberLevel(client, 100.0);
				War3_SetOwnsItem(client,shopItem[INSTAUBER],false);
			}
			//War3_SetOwnsItem(client,item,true);
			//War3_SetBuffItem(client,fArmorPhysical,item,6.0);
		}
	}
}

//deactivate BUFFS AND PASSIVES
public OnItemLost(client,item){ //deactivate passives , client may have disconnected
	if(item==shopItem[SOCK])
	{
		War3_SetBuffItem(client,fLowGravityItem,shopItem[SOCK],1.0);
	}
	else if(item==shopItem[HEALTH]&&ValidPlayer(client))
	{
		War3_SetBuffItem(client,iAdditionalMaxHealth,shopItem[HEALTH],0);
		War3_SetBuffItem(client,fHPRegenDeny,shopItem[HEALTH],false);
		
		//War3_SetMaxHP(client,War3_GetMaxHP(client)-50);
		if(GetClientHealth(client)>War3_GetMaxHP(client)){
			SetEntityHealth(client,War3_GetMaxHP(client));
		}
	}
	else if(item==shopItem[BOOTS]){
		War3_SetBuffItem(client,fMaxSpeed,shopItem[BOOTS],1.0);
	}
	else if(item==shopItem[CLOAK])
	{
		War3_SetBuffItem(client,fInvisibilityItem,shopItem[CLOAK],1.0);
	}
	if(item==shopItem[NECKLACE]) // immunity
	{
		War3_SetBuffItem(client,bImmunityUltimates,shopItem[NECKLACE],false);
	}
	if(item==shopItem[RING]) 
	{
		War3_SetBuffItem(client,fHPRegen,shopItem[RING],0.0);
	}
	if(item==shopItem[SHIELD])
	{
		War3_SetBuffItem(client,bImmunitySkills,shopItem[SHIELD],false);
	}
	if(item==shopItem[GAUNTLET])
	{
		War3_SetBuffItem(client,iAdditionalMaxHealth,shopItem[GAUNTLET],0);
	}
	if(War3_GetOwnsItem(client,shopItem[HOPE]))
	{
		War3_SetBuffItem(client,bImmunityItems,shopItem[HOPE],false);
	}
	if(War3_GetOwnsItem(client,shopItem[COURAGE]))
	{
		War3_SetBuffItem(client,fArmorPhysical,shopItem[COURAGE],0.0);
	}
	if(War3_GetOwnsItem(client,shopItem[ARMBAND]))
	{
		War3_SetBuffItem(client,fAttackSpeed,shopItem[ARMBAND],1.0);
	}
	if(War3_GetOwnsItem(client,shopItem[ANTIWARD]))
	{
		War3_SetBuffItem(client,bImmunityWards,shopItem[ANTIWARD],false);
	}
}
///change ownership only, DO NOT RESET BUFFS here, do that in OnItemLost
public OnWar3EventDeath(client){
	if (ValidPlayer(client))
	{
		bDidDie[client]=true;

		g_fExtinguishNow[client] = 0.0; //fireorb

		if(War3_GetOwnsItem(client, shopItem[FIREORB]))
		{
			War3_SetOwnsItem(client, shopItem[FIREORB], false);
		}

		if(War3_GetOwnsItem(client,shopItem[BOOTS])) // boots
		{
			War3_SetOwnsItem(client,shopItem[BOOTS],false);
			War3_SetBuffItem(client,fMaxSpeed,shopItem[BOOTS],1.0);
		}
		if(War3_GetOwnsItem(client,shopItem[SOCK]))
		{
			War3_SetOwnsItem(client,shopItem[SOCK],false);
			War3_SetBuffItem(client,fLowGravityItem,shopItem[SOCK],1.0);
		}
		if(War3_GetOwnsItem(client,shopItem[CLAW])) // claws
		{
			War3_SetOwnsItem(client,shopItem[CLAW],false);
		}
		if(War3_GetOwnsItem(client,shopItem[CLOAK]))
		{
			War3_SetOwnsItem(client,shopItem[CLOAK],false); // cloak
			War3_SetBuffItem(client,fInvisibilityItem,shopItem[CLOAK],1.0);
		}
		if(War3_GetOwnsItem(client,shopItem[MASK]))
		{
			War3_SetOwnsItem(client,shopItem[MASK],false); // mask of death
		}
		if(War3_GetOwnsItem(client,shopItem[NECKLACE])) // immunity
		{
			War3_SetOwnsItem(client,shopItem[NECKLACE],false);
		}
		if(War3_GetOwnsItem(client,shopItem[FROST])) // orb of frost
		{
			War3_SetOwnsItem(client,shopItem[FROST],false);
		}
		if(War3_GetOwnsItem(client,shopItem[HEALTH]))
		{
			War3_SetOwnsItem(client,shopItem[HEALTH],false);
		}
		if(War3_GetGame()==Game_CS && War3_GetOwnsItem(client,shopItem[GLOVES])) // gloves
		{
			War3_SetOwnsItem(client,shopItem[GLOVES],false);
		}
		if(War3_GetOwnsItem(client,shopItem[RING])) // regen
		{
			War3_SetOwnsItem(client,shopItem[RING],false);
			
		}
		//dont delete mole
		if(War3_GetGame()!=Game_TF && War3_GetOwnsItem(client,shopItem[RESPAWN]))//&&!bSpawnedViaScrollRespawn[client])
		{
			CreateTimer(1.25,RespawnPlayerViaScrollRespawn,client);  ///default orc is 1.0, 1.25 so orc activates first
			
		}
		if(War3_GetOwnsItem(client,shopItem[OIL]))
		{
			War3_SetOwnsItem(client,shopItem[OIL],false);

		}
		if(War3_GetOwnsItem(client,shopItem[PLATES]))
		{
			War3_SetOwnsItem(client,shopItem[PLATES],false);

		}
		if(War3_GetOwnsItem(client,shopItem[HELM]))
		{
			War3_SetOwnsItem(client,shopItem[HELM],false);

		}
		if(War3_GetOwnsItem(client,shopItem[SHIELD]))
		{
			War3_SetOwnsItem(client,shopItem[SHIELD],false);
			War3_SetBuffItem(client,bImmunitySkills,shopItem[SHIELD],false);
		}
		if(War3_GetOwnsItem(client,shopItem[GAUNTLET]))
		{
			War3_SetOwnsItem(client,shopItem[GAUNTLET],false);
			War3_SetBuffItem(client,iAdditionalMaxHealth,shopItem[GAUNTLET],0);
		}
		if(War3_GetOwnsItem(client,shopItem[HOPE]))
		{
			War3_SetOwnsItem(client,shopItem[HOPE],false);
			War3_SetBuffItem(client,bImmunityItems,shopItem[HOPE],false);
		}
		if(War3_GetOwnsItem(client,shopItem[COURAGE]))
		{
			War3_SetOwnsItem(client,shopItem[COURAGE],false);
			War3_SetBuffItem(client,fArmorPhysical,shopItem[COURAGE],0.0);
		}
		if(War3_GetOwnsItem(client,shopItem[ARMBAND]))
		{
			War3_SetOwnsItem(client,shopItem[ARMBAND],false);
			War3_SetBuffItem(client,fAttackSpeed,shopItem[ARMBAND],1.0);
		}
		if(War3_GetOwnsItem(client,shopItem[ANTIWARD]))
		{
			War3_SetOwnsItem(client,shopItem[ANTIWARD],false);
			War3_SetBuffItem(client,bImmunityWards,shopItem[ANTIWARD],false);
		}
		if(War3_GetOwnsItem(client,shopItem[ARMOR_PIERCING]))
		{
			War3_SetOwnsItem(client,shopItem[ARMOR_PIERCING],false);
		}
	}
}

public Action:DoAnkhAction(Handle:t,any:client){ //just respawned, passed that he didnt respawn from scroll, too bad if he respawned from orc or mage
	GivePlayerCachedDeathWPNFull(INVALID_HANDLE,client);
	War3_SetOwnsItem(client,shopItem[ANKH],false);
	War3_ChatMessage(client,"%T","You reincarnated with all your gear",client);
	
}
public Action:GivePlayerCachedDeathWeapons(Handle:t,any:client){ //not used because all items give full ammo in this case
	if(ValidPlayer(client,true)){
		for(new s=0;s<10;s++)
		{
			new ent=GetEntDataEnt2(client,MyWeaponsOffset+(s*4));
			if(ent>0 && IsValidEdict(ent))
			{
				new String:ename[64];
				GetEdictClassname(ent,ename,sizeof(ename));
				if(StrEqual(ename,"weapon_c4") || StrEqual(ename,"weapon_knife"))
				{
					continue; // DONT REMOVE THESE
				}
				W3DropWeapon(client,ent);
				UTIL_Remove(ent);
			}
		}
		// restore iAmmo
		for(new s=0;s<32;s++)
		{
			SetEntData(client,AmmoOffset+(s*4),War3_CachedDeadAmmo(client,s),4);
		}
		// give them their weapons
		for(new s=0;s<10;s++)
		{
			new String:wep_check[64];
			War3_CachedDeadWeaponName(client,s,wep_check,sizeof(wep_check));
			if(!StrEqual(wep_check,"") && !StrEqual(wep_check,"",false) && !StrEqual(wep_check,"weapon_c4") && !StrEqual(wep_check,"weapon_knife"))
			{
				new wep_ent=GivePlayerItem(client,wep_check);
				if(wep_ent>0) //DONT SET LESS AMMO ON FULL
				{
					SetEntData(wep_ent,Clip1Offset,War3_CachedDeadClip1(client,s),4);
				}
			}
		}
		War3_SetCSArmor(client,100);
		War3_SetCSArmorHasHelmet(client,true);
	}
}
public Action:GivePlayerCachedDeathWPNFull(Handle:h,any:client){
	if(ValidPlayer(client,true)){
		for(new s=0;s<10;s++)
		{
			new ent=GetEntDataEnt2(client,MyWeaponsOffset+(s*4));
			if(ent>0 && IsValidEdict(ent))
			{
				new String:ename[64];
				GetEdictClassname(ent,ename,sizeof(ename));
				if(StrEqual(ename,"weapon_c4") || StrEqual(ename,"weapon_knife"))
				{
					continue; // DONT REMOVE THESE
				}
				W3DropWeapon(client,ent);
				UTIL_Remove(ent);
			}
		}
		///NO RESETTING AMMO FOR FULL AMMO???
		// restore iAmmo    
		//for(new s=0;s<32;s++)
		//{
		//	SetEntData(client,AmmoOffset+(s*4),War3_CachedDeadAmmo(client,s),4);
		//}
		// give them their weapons
		for(new s=0;s<10;s++)
		{
			new String:wep_check[64];
			War3_CachedDeadWeaponName(client,s,wep_check,sizeof(wep_check));
			if(!StrEqual(wep_check,"") && !StrEqual(wep_check,"",false) && !StrEqual(wep_check,"weapon_c4") && !StrEqual(wep_check,"weapon_knife"))
			{
				//new wep_ent=
				GivePlayerItem(client,wep_check);
				//if(wep_ent>0)//DONT SET LESS AMMO ON FULL
				//{
				//	SetEntData(wep_ent,Clip1Offset,War3_CachedDeadClip1(client,s),4);
				//}
			}
		}
		War3_SetCSArmor(client,100);
		War3_SetCSArmorHasHelmet(client,true);
	}
}









public RoundStartEvent(Handle:event,const String:name[],bool:dontBroadcast)
{
	if(War3_GetGame()!=Game_TF)
	{
		if(!GetConVarBool(MoleDeathmatchCvar))
		{
			for(new x=1;x<=MaxClients;x++)
			{
				if(ValidPlayer(x,true)&&GetClientTeam(x)>1&&War3_GetOwnsItem(x,shopItem[MOLE]))
				{
					StartMole(x);
				}
			}
		}
	}
}

public StartMole(client)
{
	new Float:mole_time=5.0;
	PrintHintText(client,"%T","WARNING! MOLE IN {amount} SECONDS (item)!",client,mole_time);
	War3_ChatMessage(client,"%T","WARNING! MOLE IN {amount} SECONDS (item)!",client,mole_time);
	CreateTimer(0.2+mole_time,DoMole,client);
}
public Action:DoMole(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		new team=GetClientTeam(client);
		new searchteam=(team==2)?3:2;
		
		new Float:emptyspawnlist[100][3];
		new availablelocs=0;
		
		new Float:playerloc[3];
		new Float:spawnloc[3];
		new ent=-1;
		while((ent = FindEntityByClassname(ent,(searchteam==2)?"info_player_terrorist":"info_player_counterterrorist"))!=-1)
		{
			if(!IsValidEdict(ent)) continue;
			GetEntDataVector(ent,OriginOffset,spawnloc);
			
			new bool:is_conflict=false;
			for(new i=1;i<=MaxClients;i++)
			{
				if(ValidPlayer(i,true)){
					GetClientAbsOrigin(i,playerloc);
					if(GetVectorDistance(spawnloc,playerloc)<60.0)
					{
						is_conflict=true;
						break;
					}				
				}
			}
			if(!is_conflict)
			{
				emptyspawnlist[availablelocs][0]=spawnloc[0];
				emptyspawnlist[availablelocs][1]=spawnloc[1];
				emptyspawnlist[availablelocs][2]=spawnloc[2];
				availablelocs++;
			}
		}
		if(availablelocs==0)
		{
			War3_ChatMessage(client,"%T","This map does not have enemy spawn points, can not mole!",client);
			return;
		}
		GetClientModel(client,sOldModel[client],256);
		if(War3_GetGame() == Game_CS) {
			SetEntityModel(client,(searchteam==2)?"models/player/t_leet.mdl":"models/player/ct_urban.mdl");
		}
		else {
			SetEntityModel(client,(searchteam==2)?"models/player/tm_leet.mdl":"models/player/ctm_gsg9.mdl");
		}
		TeleportEntity(client,emptyspawnlist[GetRandomInt(0,availablelocs-1)],NULL_VECTOR,NULL_VECTOR);
		War3_ChatMessage(client,"%T","You have moled!",client);
		PrintHintText(client,"%T","You have moled!",client);
		War3_ShakeScreen(client,1.0,20.0,12.0);
		CreateTimer(10.0,ResetModel,client);
		
		War3_SetOwnsItem(client,shopItem[MOLE],false) ;
	}
	return;
}
public Action:ResetModel(Handle:timer,any:client)
{
	if(ValidPlayer(client,true))
	{
		SetEntityModel(client,sOldModel[client]);
		War3_ChatMessage(client,"%T","You are no longer disguised",client);
	}
}


public OnWar3EventSpawn(client){
	if( bFrosted[client])
	{
		bFrosted[client]=false;
		War3_SetBuffItem(client,fSlow,shopItem[FROST],1.0);
	}
	if(War3_GetGame()==Game_CS && (War3_GetOwnsItem(client,shopItem[ANKH])||W3IsDeveloper(client)) && bDidDie[client])
	{
		if(!bSpawnedViaScrollRespawn[client]){ //only if he didnt already respawn from the "respawn item" cuz that gives items too

			CreateTimer(0.1,DoAnkhAction,client);
		}
		
	}
	if(War3_GetOwnsItem(client,shopItem[HEALTH]))
	{
		//SetEntityHealth(client,GetClientHealth(client)+50);
		War3_SetBuffItem(client,iAdditionalMaxHealth,shopItem[HEALTH],50);
		War3_SetBuffItem(client,fHPRegenDeny,shopItem[HEALTH],true);
		//War3_SetMaxHP(client,War3_GetMaxHP(client)+50);
		War3_ChatMessage(client,"%T","+50 HP",client);
	}
	if(War3_GetOwnsItem(client,shopItem[SOCK]))
	{
		War3_SetBuffItem(client,fLowGravityItem,shopItem[SOCK],GetConVarFloat(SockCvar));
		//War3_SetMinGravity(client,GetConVarFloat(SockCvar),shopItem[10]);
		War3_ChatMessage(client,"%T","You pull on your socks",client);
	}
	if(War3_GetGame()!=Game_TF && War3_GetOwnsItem(client,shopItem[MOLE]) && GetConVarBool(MoleDeathmatchCvar)) // deathmatch
	{
		StartMole(client);
	}
	bDidDie[client]=false;
	
}

//
public Action:RespawnPlayerViaScrollRespawn(Handle:h,any:client)
{
	if(ValidPlayer(client)&&!IsPlayerAlive(client)) //not revived from something else
	{
		bSpawnedViaScrollRespawn[client]=true; ///prevent ankh from activating
		CS_RespawnPlayer(client);
		PrintCenterText(client,"%T","RESPAWNED!",client);
		CreateTimer(0.2,GivePlayerCachedDeathWPNFull,client);
		bSpawnedViaScrollRespawn[client]=false;
		War3_SetOwnsItem(client,shopItem[RESPAWN],false);
		War3_ChatMessage(client,"%T","Respawned by Scroll of Respawning",client);
		CreateTimer(1.0,NoLongerSpawnedViaScroll,client);
	}
}
public Action:NoLongerSpawnedViaScroll(Handle:t,any:client){
	bSpawnedViaScrollRespawn[client]=false;
}


// use? OnW3TakeDmgAll
/*
Trying to resolve:  I think we should try OnW3TakeDmgAll because it allows damage.
[SM] Displaying call stack trace for plugin "war3source/War3Source_Engine_DamageSystem.smx":
L 12/08/2012 - 02:58:58: [SM]   [0]  Line 455, War3Source_Engine_DamageSystem.sp::Native_War3_DealDamage()
L 12/08/2012 - 02:58:58: [SM] Plugin encountered error 25: Call was aborted
L 12/08/2012 - 02:58:58: [SM] Native "War3_DealDamage" reported: Error encountered while processing a dynamic native
L 12/08/2012 - 02:58:58: [SM] Displaying call stack trace for plugin "war3source/War3Source_013_SuccubusHunter.smx":
L 12/08/2012 - 02:58:58: [SM]   [0]  Line 213, War3Source_013_SuccubusHunter.sp::OnWar3EventPostHurt()
L 12/08/2012 - 03:06:15: Error log file session closed.

same error above except with shopmenu items
*/
//public OnWar3EventPostHurt(victim,attacker,damage){

public OnW3TakeDmgAll(victim,attacker,Float:damage)
{
	if(!W3IsOwnerSentry(attacker)&&W3GetDamageIsBullet()&&ValidPlayer(victim)&&ValidPlayer(attacker,true)&&GetClientTeam(victim)!=GetClientTeam(attacker))
	{
		//DP("bullet 1 claw %d vic alive%d",War3_GetOwnsItem(attacker,shopItem[CLAW]),ValidPlayer(victim,true,true));
		//new vteam=GetClientTeam(victim);
		//new ateam=GetClientTeam(attacker);
		
		if(!W3HasImmunity(victim,Immunity_Items)&&!Perplexed(attacker))
		{
			if(War3_GetOwnsItem(attacker,shopItem[CLAW])&&ValidPlayer(victim,true,true)&&W3Chance(W3ChanceModifier(attacker))) // claws of attack
			{
				new Float:dmg=GetConVarFloat(ClawsAttackCvar);
				if(dmg<0.0) 	dmg=0.0;
				
				//SetEntityHealth(victim,new_hp);
				if(GameTF()){
					//DP("%f",W3ChanceModifier(attacker));
					if(W3ChanceModifier(attacker)<0.99){
					dmg*=W3ChanceModifier(attacker);
					}
					else{
						dmg*=0.50;
					}
				}
			//	DP("%f",dmg);
				if(War3_DealDamage(victim,RoundFloat(dmg),attacker,_,"claws",W3DMGORIGIN_ITEM,W3DMGTYPE_PHYSICAL,_,_,true)){ //real damage with indicator
				
					PrintToConsole(attacker,"%T","+{amount} Claws Damage",attacker,War3_GetWar3DamageDealt());
				}
			}
				
			if( War3_GetOwnsItem(attacker,shopItem[FROST]) && !bFrosted[victim])
			{
				/*new chance;
				switch (TF2_GetPlayerClass(attacker))
				{
					case TFClass_Scout:
					{
						chance = 55;
					}
					case TFClass_Sniper:
					{
						chance = 90;
					}
					case TFClass_Soldier:
					{
						chance = 45;
					}
					case TFClass_DemoMan:
					{
						chance = 80;
					}
					case TFClass_Medic:
					{
						chance = 30;
					}
					case TFClass_Heavy:
					{
						chance = 5;
					}
					case TFClass_Pyro:
					{
						chance = 5;
					}
					case TFClass_Spy:
					{
						chance = 65;
					}
					case TFClass_Engineer:
					{
						chance = 5;
					}
					default:
					{
						chance = 10;
					}
				}
				if(GetRandomInt(1, 100) <= chance) */
				if(W3Chance(W3ChanceModifier(attacker)))
				{
					new Float:speed_frost=GetConVarFloat(OrbFrostCvar);
					if(speed_frost<=0.0) speed_frost=0.01; // 0.0 for override removes
					if(speed_frost>1.0)	speed_frost=1.0;
					War3_SetBuffItem(victim,fSlow,shopItem[FROST],speed_frost);
					bFrosted[victim]=true;
				
					//PrintToConsole(attacker,"%T","ORB OF FROST!",attacker);
					//PrintToConsole(victim,"%T","Frosted, reducing your speed",victim);
					PrintHintText(victim,"Frosted, reducing your speed!");
					CreateTimer(2.0,Unfrost,victim);
				}
			}
	

			if(War3_GetOwnsItem(attacker,shopItem[MASK]) && W3Chance(W3ChanceModifier(attacker))) // Mask of death
			{
				new Float:hp_percent=GetConVarFloat(MaskDeathCvar);
				if(hp_percent<0.0)	hp_percent=0.0;
				if(hp_percent>1.0)	hp_percent=1.0;  //1 = 100%
				//new add_hp=RoundFloat(FloatMul(float(damage),hp_percent));
				new add_hp=RoundFloat(FloatMul(damage,hp_percent));
				if(add_hp>40)	add_hp=40; // awp or any other weapon, just limit it
				War3_HealToBuffHP(attacker,add_hp);
				/*
				tock EmitSoundToAll(const String:sample[],
	                 entity = SOUND_FROM_PLAYER,
	                 channel = SNDCHAN_AUTO,
	                 level = SNDLEVEL_NORMAL,
	                 flags = SND_NOFLAGS,
	                 Float:volume = SNDVOL_NORMAL,
	                 pitch = SNDPITCH_NORMAL,
	                 speakerentity = -1,
	                 const Float:origin[3] = NULL_VECTOR,
	                 const Float:dir[3] = NULL_VECTOR,
	                 bool:updatePos = true, */
	                 
				if(War3_TrackDelayExpired(maskSoundDelay[attacker])){
					EmitSoundToAll(masksnd,attacker);
					War3_TrackDelay(maskSoundDelay[attacker],0.25);
				}
				if(War3_TrackDelayExpired(maskSoundDelay[victim])){
					EmitSoundToAll(masksnd,victim);
					War3_TrackDelay(maskSoundDelay[victim],0.25);
				}
				PrintToConsole(attacker,"%T","+{amount} Mask leeched HP",attacker,add_hp);
			}
		}
	}
}
/*
bool:IS_sentryowner(client,pSentry)
{
	if(ValidPlayer(client))
	{
		if(IsValidEntity(pSentry)&&TF2_GetPlayerClass(client)==TFClass_Engineer)
		{
			//DP("Looking for sentry owner");
			//new iSentry = GetEntPropEnt(pSentry, Prop_Send, "m_hBuilder");
			//if(iSentry==client)
			//{
			//	return true;
			//}
			decl String:netclass[32];
			GetEntityNetClass(pSentry, netclass, sizeof(netclass));

			if (strcmp(netclass, "CObjectSentrygun") == 0 || strcmp(netclass, "CObjectTeleporter") == 0 || strcmp(netclass, "CObjectDispenser") == 0)
			{
				if (GetEntDataEnt2(pSentry, ownerOffset) == client)
					return true;
			}
		}
	}
	return false;
}
*/
public Action:Unfrost(Handle:timer,any:client)
{
	bFrosted[client]=false;
	//War3_SetOverrideSpeed(client,0.0,shopItem[6]);
	War3_SetBuffItem(client,fSlow,shopItem[FROST],1.0);
	if(ValidPlayer(client))
	{
	
		PrintToConsole(client,"%T","REGAINED SPEED from frost",client);
	}
}


public Action:cmdfrostme(victim,args){

	W3ApplyBuffSimple(victim,fSlow,0,0.1,2.0);
	//War3_SetBuffItem(victim,fSlow,shopItem[FROST],0.1);
	
	//bFrosted[victim]=true;
	
	PrintToConsole(victim,"%T","Frosted, reducing your speed",victim);
	CreateTimer(2.0,Unfrost,GetClientUserId(victim));
}


public OnWar3Event(W3EVENT:event,client){
	if(event==ClearPlayerVariables){
		bDidDie[client]=false;
	}
	if(event == CanBuyItem)
	{
		new item = W3GetVar(EventArg1);
		new Owns_item = War3_GetOwnsItem(client,shopItem[OIL]);
		W3SetVar(EventArg2, 1);
		if(item==shopItem[ARMOR_PIERCING] && (Owns_item!=1))
		{
			W3SetVar(EventArg2, 0);
			//decl String:msgbuffer[256 + MAX_NAME_LENGTH];
			//Format(msgbuffer, sizeof(msgbuffer),"\x01[\x04War3Evo\x01] You must by Oil of Penetration before you can by this upgrade.", itembuffer);
			CSayText2(client,client,"\x01[\x04War3Evo\x01] \x05You must by Oil of Penetration before you can by this item.");
			//War3_ChatMessage(client, "You must by Oil of Penetration before you can by this upgrade.");
			//War3_SetGold(client,100);
			//War3_SetOwnsItem(client,item,false);
			//PrintToChat(client,"Store refunded your gold.");
		}
		else if(item==shopItem[INSTAUBER] && TF2_GetPlayerClass(client)!=TFClass_Medic)
		{
			W3SetVar(EventArg2, 0);
			War3_ChatMessage(client, "Only Medics can buy this item!");
			//War3_SetGold(client,100);
			//War3_SetOwnsItem(client,item,false);
			//PrintToChat(client,"Store refunded your gold.");
		}
	}
}

public OnClientPutInServer(client){
	SDKHook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
}

public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_TraceAttack,SDK_Forwarded_TraceAttack);
}

// plates  & helm
public Action:SDK_Forwarded_TraceAttack(victim, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	//PrintToChatAll("Hitgroup: %i",hitgroup);
	//PrintToChatAll("Hitbox: %i",hitbox);
	//PrintToChatAll("Damage Type: %i",damagetype);
	//PrintToChatAll("Ammo Type: %i",ammotype);
	//damage=0.0;
	//return Plugin_Changed;   War3_GetItemIdByShortname(String:itemshortname[])
	//new String[64]:Oil_shortname = "oil";
	new Oil_item = War3_GetItemIdByShortname("oil");
	new Owns_item = War3_GetOwnsItem(attacker,Oil_item);
	//   	if(Owns_item!=1)
	//    {
	//        damage=damage+(damage*0.10);
	//    }
	//plates
	if((Owns_item!=1)&&((hitgroup==2&&(hitbox==5||hitbox==4))||(hitgroup==3&&hitbox==3))&&War3_GetOwnsItem(victim,shopItem[PLATES])&&!Perplexed(victim)){
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
	}
	// helms
	if((Owns_item!=1)&&hitgroup==1&&War3_GetOwnsItem(victim,shopItem[HELM])&&!Perplexed(victim)){
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
		if(War3_GetGame()==TF){
			W3FlashScreen(victim,RGBA_COLOR_BLACK);
			decl Float:pos[3];
			GetClientEyePosition(victim, pos);
			pos[2] += 4.0;
			War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
		}
	}
	return Plugin_Changed;
}

stock GetMoney(player)
{
	return GetEntData(player,MoneyOffsetCS);
}

stock SetMoney(player,money)
{
	SetEntData(player,MoneyOffsetCS,money);
}

stock TF_SetUberLevel(client, Float:uberlevel)
{
	new index = GetPlayerWeaponSlot(client, 1);
	if (index > 0)
		SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", uberlevel*0.01);
}


//fireorb
public OnW3TakeDmgBullet(victim,attacker,Float:damage)
{
	//new String:GetWeapon1[64];
	//GetClientWeapon( attacker, GetWeapon1 , 64);
	//DP(GetWeapon1);

	if (!W3IsOwnerSentry(attacker)&&ValidPlayer(victim, true) && ValidPlayer(attacker) && victim != attacker)
	{
		if ((GetClientTeam(victim) != GetClientTeam(attacker)) && (!W3HasImmunity(victim, Immunity_Items)))
		{
			//new chance = RoundFloat(100.0 * W3ChanceModifier(attacker));
			/*new chance;
			switch (TF2_GetPlayerClass(attacker))
			{
				case TFClass_Scout:
				{
					chance = 55;
				}
				case TFClass_Sniper:
				{
					chance = 90;
				}
				case TFClass_Soldier:
				{
					chance = 45;
				}
				case TFClass_DemoMan:
				{
					chance = 80;
				}
				case TFClass_Medic:
				{
					chance = 30;
				}
				case TFClass_Heavy:
				{
					chance = 10;
				}
				case TFClass_Pyro:
				{
					chance = 100;
				}
				case TFClass_Spy:
				{
					chance = 65;
				}
				case TFClass_Engineer:
				{
					chance = 10;
				}
				default:
				{
					chance = 10;
				}
			}
			*/
			//if(GetRandomInt(1, 100) <= chance)
			if(W3Chance(W3ChanceModifier(attacker)))
			{
				if(War3_GetOwnsItem(attacker, shopItem[FIREORB]) && !(TF2_IsPlayerInCondition(victim, TFCond_OnFire)) && !Perplexed(attacker))
				{
					new String:GetWeapon[64];
					if(ValidPlayer(attacker,true,true))
					{
						GetClientWeapon( attacker, GetWeapon , 64);
					}
					else
					{
						GetWeapon = "";
					}
					new bool:WeaponIsCritial=false;
					new activeweapon = FindSendPropOffs("CTFPlayer", "m_hActiveWeapon");
					new weapon = GetEntDataEnt2(attacker, activeweapon);
					if(IsValidEntity(weapon))
					{
						new weaponindex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
						switch(weaponindex)
						{
						//594  makes The Phlogistinator Over powered
							case 163,349,457,38,594:
							{
								WeaponIsCritial=true;
							}
						}
					}
					//DP(GetWeapon);//
					//StrEqual( wpnstr, "weapon_knife" )
					//if(!W3HasImmunity(attacker,Immunity_Skills)&&skilllevel_MagicArmorPassiveSkills>0&&War3_GetRace(victim)==thisRaceID&&TF2_GetPlayerClass(attacker)==TFClass_Spy&&War3_Chance(NightGuardsHelmChance[skilllevel_PassiveSkills])&&damagetype==135270528&&!Perplexed(victim)){
					if(!WeaponIsCritial)
					{
						TF2_IgnitePlayer(victim, attacker);
						g_fExtinguishNow[victim] = GetGameTime() + fSecondsTillExtinguish;
					}
//					else
//					{
//						DP("Fireorb Blocked");
//					}
				}
			}
		}
	}
}
