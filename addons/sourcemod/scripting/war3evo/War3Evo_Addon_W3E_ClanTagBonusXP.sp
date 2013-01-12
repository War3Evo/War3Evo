/* ========================================================================== */
/*                                                                            */
/*   Filename.c                                                               */
/*   (c) 2001 Author                                                          */
/*                                                                            */
/*   Description                                                              */
/*                                                                            */
/* ========================================================================== */

#include "W3SIncs/War3Source_Interface"


new Handle:g_hGOMultipler = INVALID_HANDLE;
new Handle:g_hXPMultipler = INVALID_HANDLE;

public Plugin:myinfo=
{
	name="W3E Addon - ClanBonusXP",
	author="El Diablo",
	description="War3Evo Addon Plugin",
	version="1.0.0.9",
};

public OnPluginStart()
{
	g_hXPMultipler = CreateConVar("war3_bonusclan_xprate","2.0","Bonus XP Multipler", 0, true, 1.0);
	g_hGOMultipler = CreateConVar("war3_bonusclan_goldrate","2.0","Bonus Gold Multipler", 0, true, 1.0);

}


public OnWar3Event(W3EVENT:event,client)
{
	if(event==OnPreGiveXPGold && !IsFakeClient(client))
	{
		//new bool:bAwardBonus = false;
		new String:Cname[64];
		GetClientName(client,Cname,sizeof(Cname));
		if (StrContains(Cname,"-W3E-",true)==0 || StrContains(Cname,"-=|JFH|=-",true)==0)
		{
		//	bAwardBonus = true;
			W3SetVar(EventArg2,FloatMul(W3GetVar(EventArg2),GetConVarFloat(g_hXPMultipler)));
			W3SetVar(EventArg3,FloatMul(W3GetVar(EventArg3),GetConVarFloat(g_hGOMultipler)));
		}
		//if(bAwardBonus==true) {
			// Award dat bonus
//			W3SetVar(EventArg2,FloatMul(W3GetVar(EventArg2),GetConVarFloat(g_hXPMultipler)));
//			W3SetVar(EventArg3,FloatMul(W3GetVar(EventArg3),GetConVarFloat(g_hGOMultipler)));
		//}
	}

}
