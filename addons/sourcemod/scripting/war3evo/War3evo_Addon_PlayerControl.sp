




#pragma semicolon 1
//#pragma tabsize 0     // doesn't mess with how you format your lines

#include <sourcemod>
#include "W3SIncs/sdkhooks"
#include "W3SIncs/War3Source_Interface"

new bool:BossMode = false;
new String:helmSound0[]="physics/metal/metal_solid_impact_bullet1.wav";
new String:helmSound1[]="physics/metal/metal_solid_impact_bullet2.wav";
new String:helmSound2[]="physics/metal/metal_solid_impact_bullet3.wav";
new String:helmSound3[]="physics/metal/metal_solid_impact_bullet4.wav";

public Plugin:myinfo= {
	name="Bossmode",
	author="El Diablo",
	description="Prevents all players from hurting eachother no matter what team.",
	version="1.0",
	url="http://www.war3evo.com/"
};



public OnPluginStart()
{
	RegAdminCmd("sm_bossmode",Command_Bossmode,ADMFLAG_CHEATS,"Allows an administrator to toggle boss mode where players can't damage each other.");

	War3_PrecacheSound(helmSound0);
	War3_PrecacheSound(helmSound1);
	War3_PrecacheSound(helmSound2);
	War3_PrecacheSound(helmSound3);
}

public OnMapStart()
{
	BossMode=false;
}


public Action:Command_Bossmode(client, args)
{
	ToggleBossMode(client);
	LogAction(client, -1, "%N has toggled BOSSMODE.", client);
	return Plugin_Handled;
}

ToggleBossMode(client)
{
	if(BossMode==true)
	{
		BossMode=false;
		War3_ChatMessage(client,"Bossmode is now Off.");
	} else {
		BossMode=true;
		War3_ChatMessage(client,"Bossmode is now On.");
	}
}


public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(IS_PLAYER(victim)&&IS_PLAYER(attacker)&&victim>0&&attacker>0&&attacker!=victim&&BossMode)
	{
		new vteam=GetClientTeam(victim);
		new ateam=GetClientTeam(attacker);
		if(vteam!=ateam)
		{
			War3_DamageModPercent(0.0);
			new random = GetRandomInt(0,3);
			if(random==0){
				EmitSoundToAll(helmSound0,attacker);
			}else if(random==1){
				EmitSoundToAll(helmSound1,attacker);
			}else if(random==2){
				EmitSoundToAll(helmSound2,attacker);
			}else{
				EmitSoundToAll(helmSound3,attacker);
			}
			if(War3_GetGame()==TF){
				W3FlashScreen(victim,RGBA_COLOR_BLACK);
				decl Float:pos[3];
				GetClientEyePosition(victim, pos);
				pos[2] += 4.0;
				War3_TF_ParticleToClient(0, "miss_text", pos); //to the attacker at the enemy pos
			}
		}
	}
}

