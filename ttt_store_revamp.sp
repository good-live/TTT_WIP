#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <ttt_credits>
#include <ttt>

#pragma semicolon 1
#pragma newdecls required

#define ITEM_SIZE 67
#define HANDLER_SIZE 21

enum Item {
	String:sName[64],
	iParent,
	iTeam,
	iHandler
};

enum Handler {
	String:sIdentifier[16],
	Handle:hPlugin,
	Function:fnReset,
	Function:fnConfig,
	Function:fnUse,
	Function:fnRemove
}

public Plugin myinfo =
{
	name = "TTT - Store (Revamped)",
	author = "good_live (based on Zephyrus Store)",
	description = "The TTT store system.",
	version = "0.1",
	url = "painlessgaming.eu"
};

ArrayList g_aClientItems[MAXPLAYERS + 1] = {null, ...};
ArrayList g_aItems;
ArrayList g_aHandlers;
StringMap g_tShortCuts;
int g_iCategoryHandler = 1;

public void OnPluginStart()
{
	PrintToServer("Loading TTT - Store (Revamped) (Version 0.1)");

	g_aItems = new ArrayList(ITEM_SIZE);
	g_aHandlers = new ArrayList(HANDLER_SIZE);
	g_tShortCuts = new StringMap();

	RegConsoleCmd("sm_shop", CMD_OpenShop);
	RegConsoleCmd("sm_store", CMD_OpenStore);
	RegConsoleCmd("sm_inventory", CMD_OpenInventory);
	RegConsoleCmd("sm_inv", CMD_OpenInventory);
	RegConsoleCmd("sm_menu", CMD_OpenStore);
}

public void OnAllPluginsLoaded()
{
	//Only flatfile supported so far
	KeyValues kv = new KeyValues("Items");

	char sFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFile, sizeof(sFile), "configs/ttt/store/items.txt");

	kv.ImportFromFile(sFile);

	if(!kv.GotoFirstSubKey())
		SetFailState("[TTT-STORE] Config seems to be empty.");

	ReadConfigKey(kv);
}

void ReadConfigKey(KeyValues kv, int parent = -1)
{
	char sShortCut[16];
	char sType[16];
	int iHandlerIndex;
	int item[Item];
	int id;
	int handler[Handler];
	bool bSuccess;
	do
	{
		if(kv.GetNum("enabled", 1))
			continue;
		if(kv.GetNum("type", -1) == -1 && kv.GotoFirstSubKey())
		{
			//This is a category
			kv.GetString("shortcut", sShortCut, sizeof(sShortCut));
			kv.GetSectionName(item[sName], 16);

			item[iParent] = parent;
			item[iHandler] = g_iCategoryHandler;
			id = g_aItems.Push(item[0]);

			if(strlen(sShortCut) > 0)
				g_tShortCuts.SetValue(sShortCut, id, true);

			//Read the items from this category
			ReadConfigKey(kv, id);
			kv.GoBack();
		}
		else
		{
			kv.GetString("type", sType, sizeof(sType));

			iHandlerIndex = GetHandlerByType(sType);
			if(iHandlerIndex == -1)
				continue;

			g_aHandlers.GetArray(iHandlerIndex, handler[0], HANDLER_SIZE);

			//Call the handler and see if this item is correct
			bSuccess = true;
			if(handler[fnConfig]!=INVALID_FUNCTION)
			{
				Call_StartFunction(handler[hPlugin], handler[fnConfig]);
				Call_PushCellRef(kv);
				Call_Finish(bSuccess);
			}

			if(!bSuccess)
				continue;

			kv.GetString("shortcut", sShortCut, sizeof(sShortCut));
			kv.GetSectionName(item[sName], 16);

			item[iParent] = parent;
			item[iHandler] = iHandlerIndex;
			id = g_aItems.Push(item[0]);

			if(strlen(sShortCut) > 0)
				g_tShortCuts.SetValue(sShortCut, id, true);
		}
	} while (kv.GotoNextKey());
}

int GetHandlerByType(char[] sType)
{
	int handler[Handler];
	for (int i = 0, i < g_aHandlers.Length, i++)
	{
		g_aHandlers.GetArray(i, handler[0], HANDLER_SIZE);
		if(strcmp(handler[sIdentifier], sType)==0)
			return i;
	}
	return -1;
}

//Item Stuff
ArrayList GetPlayerItems(int client)
{
	if (g_aClientItems[client] == null) {
		g_aClientItems[client] = new ArrayList();
	}

	return g_aClientItems[client];
}

//Menu Stuff
void DisplayShopMenu(int client, int category = -1, bool inv = false)
{
	int item[Item];
	char sId[16];
	char sItem[32];
	bool bHasClientItem;

	Menu menu = new Menu(Menu_Shop);

	if(category == -1)
	{
		menu.SetTitle("%T\n%T", "SHOP_TITLE", client, "SHOP_CREDITS", client, TTT_GetClientCredits(client));
	}
	else
	{
		g_aItems.GetArray(category, item[0], ITEM_SIZE);
		menu.SetTitle("%s\n%T", item[sName], "SHOP_CREDITS", client, TTT_GetClientCredits(client));
	}

	for (int i = 0; i < g_aItems.Length; i++)
	{
		bHasClientItem = HasClientItem(i);
		if(inv && !bHasClientItem)
			continue;

		g_aItems.GetArray(i, item[0], ITEM_SIZE);

		if(item[iParent] != category)
			continue;

		//Check if he is in the right team
		if(!(item[iTeam] & TTT_GetClientRole(client)))
			continue;

		IntToString(i, sId, sizeof(sId));

		if(item[iHandler] == g_iCategoryHandler)
		{
			//This is a category (Simply display it)
			menu.AddItem(sId, item[sName]);
		}else{
			//This is an item (We need to determine some stuff)
			if(!inv)
			{
				//Has he bought the item
				if(!bHasClientItem)
				{
					//Check if he reached the limit
					if(TODO)
					{
					}
					//Check if he has enough credits
					else if(!TTT_GetClientCredits(client))
					{
						Format(sItem, sizeof(sItem), "%T", "SHOP_ITEM_NO_CREDITS",client, item[sName]);
						menu.AddItem(sId, sItem, ITEMDRAW_DISABLED);
					}
					else
					{
						Format(sItem, sizeof(sItem), "%T", "SHOP_ITEM",client, item[sName]);
						menu.AddItem(sId, sItem);
					}
				}
				else
				{
					Format(sItem, sizeof(sItem), "%T", "SHOP_ITEM_BOUGHT",client, item[sName]);
					menu.AddItem(sId, sItem);
				}
			}
		}
	}
}

public int Menu_Store(Menu menu, MenuAction action, int client, int param2)
{
	if (action == MenuAction_End)
		CloseHandle(menu);
	else if (action == MenuAction_Select)
	{
			char sAction[16];
			GetMenuItem(menu, param2, sAction, sizeof(sAction));
			if(strcmp(sAction, "inv")==0)
				DisplayShopMenu(client, -1, true);
			else
				DisplayShopMenu(client);
	}
}

//Commands
public Action CMD_OpenShop(int client, int args)
{
	if(!client)
	{
		CReplyToCommand(client, "This can only be used by players");
		return Plugin_Handled;
	}

	DisplayShop(client);
	return Plugin_Handled;
}

public Action CMD_OpenStore(int client, int args)
{
	if(!client)
	{
		CReplyToCommand(client, "This can only be used by players");
		return Plugin_Handled;
	}

	char sTitle[32];
	Format(sTitle, sizeof(sTitle), "%T", "STORE_TITLE", client);
	char sShop[32];
	Format(sShop, sizeof(sShop), "%T", "STORE_SHOP", client);
	char sInv[32];
	Format(sInv, sizeof(sInv), "%T", "STORE_INV", client);

	Menu menu = new Menu(Menu_Store);
	menu.SetTitle(sTitle);
	menu.AddItem(sShop, "shop");
	menu.AddItem(sInv, "inv");
	menu.Display(client, MENU_TIME_FOREVER);

	return Plugin_Handled;
}

public Action CMD_OpenInventory(int client, int args)
{
	if(!client)
	{
		CReplyToCommand(client, "This can only be used by players");
		return Plugin_Handled;
	}

	DisplayShop(client, -1 ,true);

	return Plugin_Handled;
}
