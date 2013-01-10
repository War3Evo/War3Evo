/*
File: offsets.inc
Description: Offset definitions.
Author(s): Anthony Iacono  
*/



new Handle:hSpawnPlayer;


public bool:War3Source_InitOffset()
{
	new bool:ret=true;
		
	
	
	new Handle:hGameConf=INVALID_HANDLE;
	hGameConf=LoadGameConfigFile("sm-tf2.games");
	if(hGameConf)
	{
		StartPrepSDKCall(SDKCall_Entity);
		PrepSDKCall_SetFromConf(hGameConf,SDKConf_Virtual,"ForceRespawn");
		hSpawnPlayer=EndPrepSDKCall();
		CloseHandle(hGameConf);
	}
	else
	{
		PrintToServer("[War3Source] Error, could not find configuration file for game.");
		ret=false;
	}
	return ret;
}

public War3Respawn(client)
{
	SDKCall(hSpawnPlayer,client);
}