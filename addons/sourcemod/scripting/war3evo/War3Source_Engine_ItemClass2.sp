

#include <sourcemod>
#include "W3SIncs/War3Source_Interface"


new totalItemsLoaded=0;  ///USE raceid=1;raceid<=GetRacesLoaded();raceid++ for looping
///race instance variables
//RACE ID = index of [MAXRACES], raceid 1 is raceName[1][32]

new String:itemName[MAXITEMS][64];
new String:itemShortname[MAXITEMS][16];
new String:itemDescription[MAXITEMS][512];

new itemGoldCost[MAXITEMS];
new itemProperty[MAXITEMS][W3ItemProp] ;

new itemOrderCvar[MAXITEMS];
new itemFlagsCvar[MAXITEMS];
new itemCatagoryCvar[MAXITEMS];

new bool:itemTranslated[MAXITEMS];

public Plugin:myinfo= 
{
	name="W3S Engine Item Class 2",
	author="Ownz (DarkEnergy)",
	description="War3Source Core Plugins",
	version="1.0",
	url="http://war3source.com/"
};




public OnPluginStart()
{
	
}

public bool:InitNativesForwards()
{


	CreateNative("War3_CreateShopItem2",NWar3_CreateShopItem);
	CreateNative("War3_CreateShopItem2T",NWar3_CreateShopItemT);
	
	CreateNative("War3_SetItem2Property",NWar3_SetItemProperty);	
	CreateNative("War3_GetItem2Property",NWar3_GetItemProperty);
	
	CreateNative("War3_GetItem2IdByShortname",NWar3_GetItemIdByShortname);
	
	//CreateNative("W3GetItem2Name",NW3GetItemName);
	//CreateNative("W3GetItem2Shortname",NW3GetItemShortname);
	//CreateNative("W3GetItem2Desc",NW3GetItemDesc);

	//CreateNative("W3GetItems2Loaded",Native_GetItemsLoaded);
	
	CreateNative("W3GetItem2Cost",NW3GetItemCost)


	//CreateNative("W3GetItemOrder",NW3GetItemOrder);
	CreateNative("W3Item2HasFlag",NW3ItemHasFlag);
	//CreateNative("W3GetItemCatagory",NW3GetItemCatagory);
	
	
	return true;
}

public NWar3_CreateShopItem(Handle:plugin,numParams)
{
	
	decl String:name[64],String:shortname[16],String:desc[512];
	GetNativeString(1,name,sizeof(name));
	GetNativeString(2,shortname,sizeof(shortname));
	GetNativeString(3,desc,sizeof(desc));
	new cost=GetNativeCell(4);
	new itemid=CreateNewItem(name,shortname,desc,cost);
	return itemid;
}
public NWar3_CreateShopItemT(Handle:plugin,numParams)
{
	
	decl String:name[64],String:shortname[16],String:desc[512];
	GetNativeString(1,shortname,sizeof(shortname));
	new cost=GetNativeCell(2);
	
	Format(name,sizeof(name),"%s_ItemName",shortname);
	
	Format(desc,sizeof(desc),"%s_ItemDesc",shortname);
	
	new itemid=CreateNewItem(name,shortname,desc,cost);
	itemTranslated[itemid]=true;
	
	/*
	if(StrEqual(shortname,"scroll")){
		Format(shortname,sizeof(shortname),"_scroll");   ///SHORTNAME IS ONLY USED ONCE BELOW
	}
	*/
	
	new String:buf[64];
	Format(buf,sizeof(buf),"w3s.item2.%s.phrases",shortname);
	LoadTranslations(buf);
	return itemid;
}

public NWar3_SetItemProperty(Handle:plugin,numParams)
{
	new item=GetNativeCell(1);
	new W3ItemProp:property=GetNativeCell(2);
	new any:value=GetNativeCell(3);
	SetItemProperty(item,property,value);
}
public NWar3_GetItemProperty(Handle:plugin,numParams)
{
	new item=GetNativeCell(1);
	new W3ItemProp:property=GetNativeCell(2);
	return GetItemProperty(item,property);
}
public NWar3_GetItemIdByShortname(Handle:plugin,numParams)
{

	new String:itemshortname[16],String:argstr[16];
	GetNativeString(1,argstr,16);
	new ItemsLoaded = W3GetItemsLoaded();
	for(new i=1;i<=ItemsLoaded;i++){
		GetItemShortname(i,itemshortname,sizeof(itemshortname));
		if(StrEqual(argstr,itemshortname)){
			return i;
		}
	}
	return 0;
}



public NW3GetItemName(Handle:plugin,numParams)
{
	new itemid=GetNativeCell(1);
	new String:str[64];
	GetItemName(itemid,str,sizeof(str));
	SetNativeString(2,str,GetNativeCell(3));
}
public NW3GetItemShortname(Handle:plugin,numParams)
{
	new itemid=GetNativeCell(1);

	new String:str[16];
	GetItemShortname(itemid,str,sizeof(str));
	SetNativeString(2,str,GetNativeCell(3));
	
}
public NW3GetItemDescription(Handle:plugin,numParams)
{
	new itemid=GetNativeCell(1);

	new String:str[512];
	GetItemDescription(itemid,str,sizeof(str));
	SetNativeString(2,str,GetNativeCell(3));
}
public Native_GetItemsLoaded(Handle:plugin,numParams)
{
	return totalItemsLoaded;
}


public NW3GetItemCost(Handle:plugin,numParams)
{
	new itemid=GetNativeCell(1);
	return W3GetCvarInt(itemGoldCost[itemid]);
}


public NW3GetItemOrder(Handle:plugin,numParams)
{
	new itemid=GetNativeCell(1);
	return W3GetCvarInt(itemOrderCvar[itemid]);
}
public NW3ItemHasFlag(Handle:plugin,numParams)
{
	new itemid=GetNativeCell(1);
	new String:buf[1000];
	W3GetCvar(itemFlagsCvar[itemid],buf,sizeof(buf));
	
	new String:flagsearch[32];
	GetNativeString(2,flagsearch,sizeof(flagsearch));
	
	return (StrContains(buf,flagsearch)>-1);
}
public NW3GetItemCatagory(Handle:plugin,numParams)
{
	new itemid=GetNativeCell(1);
	new String:buf[1000];
	W3GetCvar(itemCatagoryCvar[itemid],buf,sizeof(buf));
	SetNativeString(2,buf,GetNativeCell(3));
}











CreateNewItem(String:titemname[] ,String:titemshortname[] ,String:titemdescription[], itemcostgold){
	
	if(totalItemsLoaded+1==MAXITEMS){ //make sure we didnt reach our item capacity limit
		LogError("MAX ITEMS REACHED, CANNOT REGISTER %s",titemname);
		return -1;
	}
	
	//first item registering, fill in the  zeroth  along
	if(totalItemsLoaded==0){
		
		Format(itemName[0],31,"ZEROTH ITEM");

	}
	else{
		decl String:shortnameexisted[16];
		new ItemsLoaded = W3GetItemsLoaded();
		for(new i=1;i<=ItemsLoaded;i++){
			GetItemShortname(i,shortnameexisted,sizeof(shortnameexisted));
			if(StrEqual(titemshortname,shortnameexisted)){
				return i; //item already exists
			}
		}
	}
	
	
	
	totalItemsLoaded++;
	new titemid=totalItemsLoaded;
	
	strcopy(itemName[titemid], 31, titemname);
	strcopy(itemShortname[titemid], 15, titemshortname);
	strcopy(itemDescription[titemid], 511, titemdescription);
	
	new String:cvarstr[32];
	Format(cvarstr,sizeof(cvarstr),"%s_goldcost",titemshortname);
	itemGoldCost[titemid]=W3CreateCvarInt(cvarstr,itemcostgold,"item cost with gold");
	

	Format(cvarstr,sizeof(cvarstr),"%s_itemorder",titemshortname);
	itemOrderCvar[titemid]=W3CreateCvarInt(cvarstr,titemid*100,"item order");
	
	Format(cvarstr,sizeof(cvarstr),"%s_itemflags",titemshortname);
	itemFlagsCvar[titemid]=W3CreateCvar(cvarstr,"","item flags");
	
	Format(cvarstr,sizeof(cvarstr),"%s_itemcatagory",titemshortname);
	itemCatagoryCvar[titemid]=W3CreateCvar(cvarstr,"","item catagory");
	
	return titemid; //this will be the new item's id / index
}
GetItemName(itemid,String:str[],len){
	if(itemTranslated[itemid]){
		
		new String:buf[64];
		Format(buf,sizeof(buf),"%T",itemName[itemid],GetTrans());
		strcopy(str,len,buf);
	}
	else{
		strcopy(str,len,itemName[itemid]);
	}
}
GetItemShortname(itemid,String:str[],len){
	strcopy(str,len,itemShortname[itemid]);

}
GetItemDescription(itemid,String:str[],len){
	if(itemTranslated[itemid]){
		new String:buf[512];
		Format(buf,sizeof(buf),"%T",itemDescription[itemid],GetTrans());
		strcopy(str,len,buf);
	}
	else{
		strcopy(str,len,itemDescription[itemid]);
	}
}



SetItemProperty(item,W3ItemProp:ITEMproperty,any:value)  {
	itemProperty[item][ITEMproperty]=value;
}
GetItemProperty(item,W3ItemProp:ITEMproperty){
	return itemProperty[item][ITEMproperty];
}
















