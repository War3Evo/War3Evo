#pragma semicolon 1


#include <sourcemod>
#include "W3SIncs/War3Source_Interface"
#include "W3SIncs/sdkhooks"

new Spam[66];

public Plugin:myinfo =
{
	name = "Weapon Blocker",
	author = "El Diablo",
	description = "Weapon Blocker",
	version = "1.0.0.0",
	url = "http://Www.war3evo.Com"
};


public OnClientPutInServer(client){
	SDKHook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitch);
}

public OnClientDisconnect(client){
	SDKUnhook(client,SDKHook_WeaponSwitchPost,SDK_OnWeaponSwitch);
}

public SDK_OnWeaponSwitch(client, weapon)
{
//
	//DP("weapon from OnWeaponSwitch = %i",weapon);
	if (ValidPlayer(client))
	{
		new activeweapon = FindSendPropOffs("CTFPlayer", "m_hActiveWeapon");
		new THEweapon = GetEntDataEnt2(client, activeweapon);
		if(IsValidEntity(THEweapon))
		{
			new weaponindex = GetEntProp(THEweapon, Prop_Send, "m_iItemDefinitionIndex");
			//DP("weaponindex = %i",weaponindex);
			if(weaponindex==998)
			{
				//TF2_RemoveWeaponSlot(client, 1);
				CreateTimer(0.1, WpnCheck,client);
				Spam[client]=10;
				new weaponX = GetPlayerWeaponSlot(client, 0);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
			}
		}

		//decl String:weaponName[128];
		//GetEdictClassname(THEweapon, weaponName, sizeof(weaponName));
		//DP("Weapon name: %s",weaponName);
	}
	//return Plugin_Continue;
	//return true;
}

public Action:WpnCheck(Handle:timer, any:client)
{
	//FakeClientCommand(client, "slot1");
	if (ValidPlayer(client))
	{
		PrintCenterText(client,"Due to sourcemod bugs, The Vaccinator is not allowed! All Weapons Cooldown %i seconds.",Spam[client]);
		new weaponX = GetPlayerWeaponSlot(client, 0);
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", weaponX);
		Spam[client]=Spam[client]-1;
		if(Spam[client]>0)
			CreateTimer(1.0, WpnCheck,client);
	}
}