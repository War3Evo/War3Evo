

#include <sourcemod>
#include "W3SIncs/sdkhooks"
#include "W3SIncs/War3Source_Interface"






///caching player angles, pos, ducking, weapons etc
new Float:pfAngle[MAXPLAYERSCUSTOM][3];
new Float:pfPos[MAXPLAYERSCUSTOM][3];
new bool:pbDucking[MAXPLAYERSCUSTOM];
new piWeapon[MAXPLAYERSCUSTOM][10]; //10 is probably slot number
new piWeaponClip[MAXPLAYERSCUSTOM][10]; //loaded in gun
new piWeaponAmmo[MAXPLAYERSCUSTOM][32]; //32 types of ammo?
new piWeaponDeadClip[MAXPLAYERSCUSTOM][10]; 
new piWeaponDeadAmmo[MAXPLAYERSCUSTOM][32]; 
new String:psWeaponName[MAXPLAYERSCUSTOM][10][32];//cached weapon name

new MyWeaponsOffset; //get weapon per slot
new Clip1Offset;
new AmmoOffset;

public Plugin:myinfo= 
{
	name="W3S Engine Death Weapons",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};



public OnPluginStart()
{
	MyWeaponsOffset=FindSendPropOffs("CBaseCombatCharacter","m_hMyWeapons");
	if(MyWeaponsOffset==-1)
	{
		PrintToServer("[War3Source] Error finding weapon list offset.");
	}
	Clip1Offset=FindSendPropOffs("CBaseCombatWeapon","m_iClip1");
	if(Clip1Offset==-1)
	{
		PrintToServer("[War3Source] Error finding clip1 offset.");
	}
	AmmoOffset=FindSendPropOffs("CBasePlayer","m_iAmmo");
	if(AmmoOffset==-1)
	{
		PrintToServer("[War3Source] Error finding ammo offset.");
	}
}

public bool:InitNativesForwards()
{
	CreateNative("War3_CachedAngle",Native_War3_CachedAngle);
	CreateNative("War3_CachedPosition",Native_War3_CachedPosition);
	CreateNative("War3_CachedDucking",Native_War3_CachedDucking);
	CreateNative("War3_CachedWeapon",Native_War3_CachedWeapon);
	CreateNative("War3_CachedClip1",Native_War3_CachedClip1);
	CreateNative("War3_CachedAmmo",Native_War3_CachedAmmo);
	CreateNative("War3_CachedDeadClip1",Native_War3_CachedDeadClip1);
	CreateNative("War3_CachedDeadAmmo",Native_War3_CachedDeadAmmo);
	CreateNative("War3_CachedDeadWeaponName",Native_War3_CDWN);
	return true;
}


public Native_War3_CachedAngle(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);	
	SetNativeArray(2,pfAngle[client],3);
}

public Native_War3_CachedPosition(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	SetNativeArray(2,pfPos[client],3);
}

public Native_War3_CachedDucking(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	return (pbDucking[client])?1:0;
}

public Native_War3_CachedWeapon(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new iter=GetNativeCell(2);
	if( iter>=0 && iter<10)
	{
		return piWeapon[client][iter];
	}
	return 0;
}

public Native_War3_CachedClip1(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new iter=GetNativeCell(2);
	if( iter>=0 && iter<10)
	{
		return piWeaponClip[client][iter];
	}
	return 0;
}

public Native_War3_CachedAmmo(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new id=GetNativeCell(2);
	if( id>=0 && id<32)
	{
		return piWeaponAmmo[client][id];
	}
	return 0;
}

public Native_War3_CachedDeadClip1(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new iter=GetNativeCell(2);
	if( iter>=0 && iter<10)
	{
		return piWeaponDeadClip[client][iter];
	}
	return 0;
}

public Native_War3_CachedDeadAmmo(Handle:plugin,numParams)
{
	new client=GetNativeCell(1);
	new id=GetNativeCell(2);
	if( id>=0 && id<32)
	{
		return piWeaponDeadAmmo[client][id];
	}
	return 0;
}

public Native_War3_CDWN(Handle:plugin,numParams) //cached weapon name?
{
	new client=GetNativeCell(1);
	new iter=GetNativeCell(2);
	if( iter>=0 && iter<10)
	{
		SetNativeString(3,psWeaponName[client][iter],GetNativeCell(4));
	}
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{	

	//PrintToServer("2");
	//SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", Float:{0.0,0.0,0.0});
}
public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_PreThink, OnPreThink);
    SDKHook(client, SDKHook_PostThinkPost, OnPreThink);
}
public OnPreThink(client)
{
    //PrintToServer("prethink");
	//SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", Float:{10.0,0.0,0.0});
}

new skipaframe;
// Game Frame tracking
public OnGameFrame()
{
	/*for(new client=1;client<=MaxClients;client++)
	{
		if(ValidPlayer(client,true))//&&!bIgnoreTrackGF[client])
		{
			PrintToServer("1");
			SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", Float:{0.0,0.0,0.0});
		}
	}*/
	skipaframe--;
	if(skipaframe<0){
		skipaframe=1;
		for(new client=1;client<=MaxClients;client++)
		{
			if(ValidPlayer(client,true))//&&!bIgnoreTrackGF[client])
			{
				
				GetClientEyeAngles(client,pfAngle[client]);
				GetClientAbsOrigin(client,pfPos[client]);
				//new cur_wep=0;
				for(new slot=0;slot<10;slot++)
				{
					// null values
					piWeapon[client][slot]=0;
				}
				for(new ammotype=0;ammotype<32;ammotype++)
				{
					piWeaponAmmo[client][ammotype]=GetEntData(client,AmmoOffset+(ammotype*4),4);
				}
				for(new slot=0;slot<10;slot++)
				{
					new ent=GetEntDataEnt2(client,MyWeaponsOffset+(slot*4));
					if(ent>0)
					{
						piWeapon[client][slot]=ent;
						piWeaponClip[client][slot]=GetEntData(ent,Clip1Offset,4);
						//piWeapon[x][cur_wep]=ent;
						//piWeaponClip[x][cur_wep]=GetEntData(ent,Clip1Offset,4);
						//++cur_wep;
					}
				}
			}
		}
	}
}
public OnWar3EventDeath(victim){
	if(ValidPlayer(victim)){
		for(new slot=0;slot<10;slot++)
		{
			strcopy(psWeaponName[victim][slot],64,"");
			new ent=piWeapon[victim][slot];
			if(ent)
			{
				if(IsValidEdict(ent))
				{
					piWeaponDeadClip[victim][slot]=GetEntData(ent,Clip1Offset,4);
					GetEdictClassname(ent,psWeaponName[victim][slot],64);
				}
			}
		}
		for(new ammotype=0;ammotype<32;ammotype++)
		{
			piWeaponDeadAmmo[victim][ammotype]=GetEntData(victim,AmmoOffset+(ammotype*4),4);
		}	
	}
}



