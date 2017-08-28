#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <ttt>

#pragma semicolon 1
#pragma newdecls required

#define HANDLER_SIZE (MAXPLAYERS+1)*(MAXPLAYERS+1)+2
#define MAX_HANDLERS 6

public Plugin myinfo = 
{
	name = "TTT - Voice Manager", 
	author = "good_live", 
	description = "An overall system to manage the voice flags in TTT", 
	version = "0.1", 
	url = "painlessgaming.eu"
};

enum VoiceHandler {
	iPriority, 
	Handle:hPlugin, 
	ListenOverride:iVoiceMap[4098]
}

int g_iHandlers[MAX_HANDLERS][VoiceHandler];
int g_iHandlerAmount = -1;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	CreateNative("TTT_RegisterVoiceHandler", Native_RegisterVoiceHandler);
	CreateNative("TTT_SetListenOverride", Native_SetListenOverride);
	return APLRes_Success;
}

public void OnPluginStart()
{
	
}


public void OnClientDisconnect(int client)
{
	//Reset all flags that are including this client
	for (int i = 0; i <= g_iHandlerAmount; i++)
	{
		for (int j = 1; j <= MaxClients; j++)
		{
			g_iHandlers[i][iVoiceMap][(MAXPLAYERS + 1) * client + j] = Listen_Default;
			g_iHandlers[i][iVoiceMap][(MAXPLAYERS + 1) * j + client] = Listen_Default;
			if (IsClientConnected(j))
			{
				PrintToChat(j, "You can hear %N now (DEFAULT)", client);
				PrintToChat(client, "You can hear %i now (DEFAULT)", j);
			}
		}
	}
}

public int Native_RegisterVoiceHandler(Handle plugin, int numParams)
{
	for (int i = 0; i <= g_iHandlerAmount; i++)
	{
		//Currently only one Handler per Plugin
		if (g_iHandlers[i][hPlugin] == plugin)
			return 0;
	}
	
	if (g_iHandlerAmount++ >= MAX_HANDLERS)
		return 0;
	
	g_iHandlers[g_iHandlerAmount][iPriority] = GetNativeCell(1);
	g_iHandlers[g_iHandlerAmount][hPlugin] = plugin;
	
	return 0;
}

public int Handler_Comparator(int i, int j, Handle array, Handle hndl)
{
	int temp_item[VoiceHandler];
	int temp_item2[VoiceHandler];
	
	GetArrayArray(array, i, temp_item[0]);
	GetArrayArray(array, j, temp_item2[0]);
	
	return temp_item[iPriority] - temp_item2[iPriority];
}

public int Native_SetListenOverride(Handle plugin, int numParams)
{
	int reciever = GetNativeCell(1);
	int sender = GetNativeCell(2);
	ListenOverride flag = GetNativeCell(3);
	
	for (int i = 0; i <= g_iHandlerAmount; i++)
	{
		//This is the handler
		if (g_iHandlers[i][hPlugin] == plugin)
		{
			//This is no change
			if (g_iHandlers[i][iVoiceMap][(MAXPLAYERS + 1) * reciever + sender] == flag)
				return 0;
			g_iHandlers[i][iVoiceMap][(MAXPLAYERS + 1) * reciever + sender] = flag;
			if (flag == Listen_Default)
			{
				//Check if there is a handler with a lower priority to handle this
				int iIndex = -1;
				for (int j = 0; j <= g_iHandlerAmount; j++)
				{
					if(g_iHandlers[j][iPriority] > g_iHandlers[i]{iPriority})
						continue;
					if (g_iHandlers[j][iVoiceMap][(MAXPLAYERS + 1) * reciever + sender] != Listen_Default)
					{
						iIndex = j;
						break;
					}
				}
				if(iIndex == -1)
				{
					SetListenOverride(reciever, sender, Listen_Default);
				}
				else
				{
					SetListenOverride(reciever, sender, view_as<ListenOverride>(g_iHandlers[iIndex][iVoiceMap][(MAXPLAYERS + 1) * reciever + sender]));
					if(IsClientConnected(reciever))
						PrintToChat(reciever, "Setting your listening flag for %N to %i", sender, g_iHandlers[iIndex][iVoiceMap][(MAXPLAYERS + 1) * reciever + sender]);
				}
			} else {
				//Check if there is a handler with a higher priority to handle this
				for (int j = 0; j <= g_iHandlerAmount; j++)
				{
					if(g_iHandlers[j][iPriority] <= g_iHandlers[i]{iPriority})
						continue;
					if (g_iHandlers[j][iVoiceMap][(MAXPLAYERS + 1) * reciever + sender] != Listen_Default)
						return 0;
				}
			}
			SetListenOverride(reciever, sender, g_iHandlers[i][iVoiceMap][(MAXPLAYERS + 1) * reciever + sender]);
			if(IsClientConnected(reciever))
				PrintToChat(reciever, "Setting your listening flag for %N to %i", sender, g_iHandlers[i][iVoiceMap][(MAXPLAYERS + 1) * reciever + sender]);
			break;
		}
	}
	return 0;
}
