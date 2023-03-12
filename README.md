The orignal author of War3Source I have never known: PimpinJuice

The other author of War3Source: Ownz currently operates www.war3source.com

War3Source Evolution: https://github.com/War3Evo/War3Source-EVO

I, El Diablo, has done a great deal of rework to the source code,
War3Evo is to be fast and clean for Team Fortress 2 only.
We removed all other game modes (CS:S, CS:GO, L4D, etc.) from
the orignal War3Source in the purpose of creating a more clean and fast
mod for Team Fortress 2.

The extensions for War3Source have also been removed and is not needed.
You may still need other extensions, but you will not need anything that starts
with "War3" as an extension.

Unlike War3Source, War3evo's Shopmenu2 requires no War3 extensions to work,
because I have rewritten it to work without the extensions.
Since Ownz did not want to remove shopmenu2 extension,
I am therefore removing his name from authors because Ownz would
most definetly not approve of this mod.

I believe I have rewritten this work almost entirely with the help of a few people.
I have removed just about all code relates to War3Source to the players,
War3Source name still exists throughout the code, and my attempt to remove all
references has been lost.

We have had people claim we was the creators of War3Source, and was blaming us for
DDOSing their servers with the code.  It is one of the reasons we have began to remove
references from war3source from our code.  We believe the DDOSing is caused be some
of the War3Source shopmenu2 extensions and the War3Source_Engine_Statistics.sp

We highly recommand you do not use War3Source_Engine_Statistics.sp in your server.

War3Evo is meant for Team Fortress 2 only.  If you wish to use War3Evo for other games,
please create a new branch for it and remove all Team Fortress 2 code.

The War3Source stuff has been optimized for Team Fortress 2.
It is meant to run super clean and highly optimized.
The code has been rewritten for speed and less downtime of the
Team Fortress 2 server.

We recommand you use Dev-2.0 if you wish to use the latest of the coolest features
that War3Evo has the offer.  Just beware that this version maybe unstable as we was still
in the process of debugging it.

War3Evo Master branch is the most Stable version of War3Evo.

Dagothur has added a great deal to the mod and has helped code new code
for a few of the jobs.

Axin has helped us test the code from the very beginning and has been
with us all the way to the end.  He has helped us create new jobs for War3Evo.


We are happy to thank all those whom have supported us.

We are giving this as open source code and that maybe someone else can continue
the War3Evo tradition.

- El Diablo (16th Feb 2013)




About the installation...

You will need nearly the same extensions required for War3Source to run, except the War3Source exclusive extensions that start with War3.
You will probably not get any support from war3source.com.   To make this run, your knowledge on how sourcemod runs and how war3source runs will help you alot on getting this to run.

The extensions included are for linux, you may need to search for windows extensions from www.sourcemod.net

You will have to modifiy the War3Source_Engine_CommandHook.sp:
- line 185 and line 279 above OWNER put your own STEAMID in there, else you will not be able to chat in game as root.

War3Evo_Addon_SteamTools_Allow_Job_Group_Checker.sp
- modify line 35 with your steamgroup ID

War3Evo_Addon_W3E_ClanTagBonusXP.sp
- modify line 39 with your clan tag

Do not compile these files for your server
(If you want to use them.. then modify them to suit your needs before you include):
These files are for examples or other uses that are not common for normal operation.

War3evo_Addon_NewPlayerOnly_Join_Sound.sp
War3evo_Addon_Weapon_Blocker.sp
War3evo_Addon_Gifts.sp
War3evo_Addon_GPS_RACE_map_location.sp
War3evo_KDRsystem.sp
War3evo_Gamemode_Singularity.sp
War3evo_Engine_Statistics.sp
War3evo_ShopItems2_MVM.sp
War3evo_CustomJob_ROBOT_MotherBot.sp

Include for MVM ONLY:

War3Evo_CustomJob_Transmutation_Sorcerer.sp
War3evo_ShopItems2_MVM.sp

Do not include in MVM:

War3evo_ShopItems2.sp
