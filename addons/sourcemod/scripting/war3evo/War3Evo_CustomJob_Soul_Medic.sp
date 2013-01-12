#pragma semicolon 1

#include "W3SIncs/War3Source_Interface"
#include <tf2_stocks>

public Plugin:myinfo =
{
	name = "War3Source Race - Soul Medic",
	author = "Glider",
	description = "The Soul Medic race for War3Source.",
	version = "1.0",
};

//=======================================================================
//                             VARIABLES
//=======================================================================

new thisRaceID;
new SKILL_SHARED_PAIN, SKILL_BOOST_BEAM, SKILL_SOUL_BOUND, ULT_SOUL_SWAP;

// Amount of Damage to reflect onto your healing buddy
new Float:fSharedPainPercentage[5] = {0.0, 0.1, 0.2, 0.3, 0.4};

// Percentage of how to boost your buddys damage
new Float:fDamageBoost[5] = {1.0, 1.15, 1.2, 1.25, 1.3};

// How long ubercharge lasts from ultimate
//new Float:fFreeUberTime[5] = {0.0, 1.0, 2.0, 3.0, 4.0};
new Float:fFreeUberTime[5] = {0.0, 2.0, 3.0, 4.0, 5.0};

// Soul Bound
//new Float:fUberTime[5] = {0.0, 1.0, 2.0, 2.0, 3.0};
new Float:fUberTime[5] = {0.0, 2.0, 3.0, 4.0, 5.0};
new Float:fPriceMedicPays[5] = {1.0, 0.8, 0.6, 0.4, 0.2};

new const Float:SOULBOUND_COOLDOWN = 15.0; // was 30.0
new const Float:ULT_COOLDOWN = 30.0;  // was 60.0

//=======================================================================
//                                 INIT
//=======================================================================

public OnWar3PluginReady(){
	thisRaceID = War3_CreateNewRace("Soul Medic", "soulmedic");
	SKILL_SHARED_PAIN = War3_AddRaceSkill(thisRaceID, "Shared Pain", "The person you're healing takes 10/20/30/40% of your damage", false, 4);
	SKILL_BOOST_BEAM = War3_AddRaceSkill(thisRaceID, "Boost Beam", "The person you're healing deals 15/20/25/30% more damage", false, 4);
	SKILL_SOUL_BOUND = War3_AddRaceSkill(thisRaceID, "Soul Bound", "If the person you're healing takes lethal damage you will give him uber for 2/3/4/5 seconds costing you 80/60/40/20% HP CD: 15s", false, 4);
	ULT_SOUL_SWAP = War3_AddRaceSkill(thisRaceID, "Soul Swap", "You swap HP with your partner. You become ubered for 2/3/4/5 seconds. CD: 30s", false, 4);

	War3_CreateRaceEnd(thisRaceID);
}

public OnPluginStart()
{
	if(War3_GetGame() != Game_TF)
		SetFailState("Only works in the TF2 engine! %i", War3_GetGame());
}


//=======================================================================
//                                 Stocks
//=======================================================================

stock TF2_GetCurrentWeaponClass(client, String:name[], maxlength)
{
	if( client > 0 )
	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (index > 0)
			GetEntityNetClass(index, name, maxlength);
	}
}

stock TF2_GetHealingTarget(client)
{
	new String:classname[64];
	TF2_GetCurrentWeaponClass(client, classname, sizeof(classname));

	if( StrEqual(classname, "CWeaponMedigun") )
	{
		new index = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if( GetEntProp(index, Prop_Send, "m_bHealing") == 1 )
		{
			return GetEntPropEnt(index, Prop_Send, "m_hHealingTarget");
		}
	}

	return -1;
}

//=======================================================================
//                        Shared Pain/Boost Beam/Soul Bound
//=======================================================================

public OnW3TakeDmgBulletPre(victim,attacker,Float:damage)
{
	if(ValidPlayer(victim, true) && (War3_GetRace(victim) == thisRaceID))
	{
		new skill = War3_GetSkillLevel(victim, thisRaceID, SKILL_SHARED_PAIN);
		if(skill >= 0 && damage > 0.0)
		{
			if (TF2_GetPlayerClass(victim) == TFClass_Medic)
			{
				new HealVictim = TF2_GetHealingTarget(victim);
				if (ValidPlayer(HealVictim, true))
				{
					new Float:fMedicDamagePercentage = 1.0 - fSharedPainPercentage[skill];
					new damageForBuddy = RoundToFloor(damage * fMedicDamagePercentage);

					new String:buddyname[64];
					GetClientName(HealVictim, buddyname, sizeof(buddyname));

					new String:healername[64];
					GetClientName(victim, healername, sizeof(healername));

					War3_DamageModPercent(fMedicDamagePercentage);
					War3_DealDamage(HealVictim, damageForBuddy, attacker, W3GetDamageType(), "sharedpain", _, _, _, true);

					W3Hint(victim, HINT_COOLDOWN_COUNTDOWN, 1.0, "%s takes %i points of damage for you!", buddyname, damageForBuddy);
					W3Hint(HealVictim, HINT_COOLDOWN_COUNTDOWN, 1.0, "%s passed on %i points of damage to you!", healername, damageForBuddy);
				}
			}
		}
	}

	if(ValidPlayer(attacker, true))
	{
		for(new healer=1; healer <= MaxClients; healer++)
		{
			if(ValidPlayer(healer, true) && (War3_GetRace(healer) == thisRaceID) && (TF2_GetPlayerClass(healer) == TFClass_Medic))
			{
				new skill = War3_GetSkillLevel(healer, thisRaceID, SKILL_BOOST_BEAM);
				if(skill > 0)
				{
					new HealVictim = TF2_GetHealingTarget(victim);
					if (HealVictim == attacker)
					{
						War3_DamageModPercent(fDamageBoost[skill]);
					}
				}
			}
		}
	}

	if(ValidPlayer(victim, true))
	{
		for(new healer=1; healer <= MaxClients; healer++)
		{
			if(ValidPlayer(healer, true) && (War3_GetRace(healer) == thisRaceID) && (TF2_GetPlayerClass(healer) == TFClass_Medic))
			{
				new skill = War3_GetSkillLevel(healer, thisRaceID, SKILL_SOUL_BOUND);
				if(skill > 0)
				{
					new HealVictim = TF2_GetHealingTarget(healer);
					if (HealVictim == victim)
					{
						if (damage + 10 >= GetClientHealth(victim))
						{
							new HealerMaxHP = War3_GetMaxHP(healer);
							new PriceToPay = RoundToCeil(HealerMaxHP * fPriceMedicPays[skill]);

							new String:buddyname[64];
							GetClientName(victim, buddyname, sizeof(buddyname));

							new String:healername[64];
							GetClientName(healer, healername, sizeof(healername));

							new HealerCurHP = GetClientHealth(healer);
							if (HealerCurHP < PriceToPay || !War3_SkillNotInCooldown(healer, thisRaceID, SKILL_SOUL_BOUND, true))
							{
								War3_ChatMessage(victim, "{green}%s{default} couldn't pay the price to save you.", healername);
								War3_ChatMessage(healer, "You couldn't pay the price to save {green}%s{default}", buddyname);
							}
							else
							{
								War3_DamageModPercent(0.0);
								TF2_AddCondition(victim, TFCond_Ubercharged, fUberTime[skill]);

								War3_ChatMessage(victim, "{green}%s{default} paid some HP to save you", healername);
								War3_ChatMessage(healer, "You paid some HP to save {green}%s{default}'s life!", buddyname);

								SetEntityHealth(healer, HealerCurHP - PriceToPay);

								War3_CooldownMGR(healer, SOULBOUND_COOLDOWN, thisRaceID, SKILL_SOUL_BOUND);
							}
						}
					}
				}
			}
		}
	}
}

//=======================================================================
//                               Soul Swap
//=======================================================================

public OnUltimateCommand(client,race,bool:pressed)
{
	if(ValidPlayer(client, true) &&
		race == thisRaceID &&
		pressed &&
		War3_SkillNotInCooldown(client, thisRaceID, ULT_SOUL_SWAP, true) &&
		!Silenced(client))
	{
		if (TF2_GetPlayerClass(client) == TFClass_Medic)
		{
			new skill = War3_GetSkillLevel(client, thisRaceID, ULT_SOUL_SWAP);
			if (skill > 0)
			{
				new HealVictim = TF2_GetHealingTarget(client);
				if (ValidPlayer(HealVictim, true))
				{
					new fVictimCurHP = GetClientHealth(HealVictim);
					//new fVictimMaxHP = War3_GetMaxHP(HealVictim);
					//new fVictimPercentageHP = fVictimCurHP / fVictimMaxHP;

					new fHealerCurHP = GetClientHealth(client);
					//new fHealerMaxHP = War3_GetMaxHP(client);
					//new fHealerPercentageHP = fHealerCurHP / fHealerMaxHP;

					//if(fVictimPercentageHP < fHealerPercentageHP)
					//{
					//new HealerNewHP = (fHealerMaxHP * fVictimPercentageHP);
					//new VictimNewHP = (fVictimMaxHP * fHealerPercentageHP);

					new HealerNewHP = fVictimCurHP;
					new VictimNewHP = fHealerCurHP;

					if (VictimNewHP <= 0)
						VictimNewHP = 1;

					if (HealerNewHP <= 0)
						HealerNewHP = 1;

					SetEntityHealth(HealVictim, VictimNewHP);
					SetEntityHealth(client, HealerNewHP);

					new String:buddyname[64];
					GetClientName(HealVictim, buddyname, sizeof(buddyname));

					new String:healername[64];
					GetClientName(client, healername, sizeof(healername));

					War3_ChatMessage(client, "You swapped your health with {green}%s{default} (%i -> %i)", buddyname, (fHealerCurHP), HealerNewHP);
					War3_ChatMessage(HealVictim, "{green}%s{default} swapped his health with you (%i -> %i)", healername, (fVictimCurHP), VictimNewHP);

					TF2_AddCondition(client, TFCond_Ubercharged, fFreeUberTime[skill]);

					War3_CooldownMGR(client, ULT_COOLDOWN, thisRaceID, ULT_SOUL_SWAP);
					//}
					//else
					//{
					//	War3_ChatMessage(client, "You cannot swap with someone who has more HP than you!");
					//}
				}
				else
				{
					War3_ChatMessage(client, "You are not healing anyone!");
				}
			}
		}
		else
		{
			War3_ChatMessage(client, "You are not a medic, you are doing it WRONG!");
		}

	}
}