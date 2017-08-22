#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <ttt>

#pragma semicolon 1
#pragma newdecls required

#define HANDLER_SIZE (MAXPLAYERS+1)*(MAXPLAYERS+1)+2

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
  ListenOverride:iVoiceMap[(MAXPLAYERS+1)*(MAXPLAYERS+1)+2]
}

ArrayList g_aHandlers;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
   CreateNative("TTT_RegisterVoiceHandler", Native_RegisterVoiceHandler);
   CreateNative("TTT_SetListenOverride", Native_SetListenOverride);
   return APLRes_Success;
}

public void OnPluginStart()
{
  g_aHandlers = new ArrayList(HANDLER_SIZE);
}


public void OnClientDisconnect(int client)
{
  //Reset all flags that are including this client
  int tempHandler[VoiceHandler];
  for(int i = 0; i < g_aHandlers.Length; i++)
  {
    g_aHandlers.GetArray(i, tempHandler[0], HANDLER_SIZE);
    for(int j = 1; j <= MaxClients; j++)
    {
      tempHandler[iVoiceMap][(MAXPLAYERS+1)*client+j] = Listen_Default;
      tempHandler[iVoiceMap][(MAXPLAYERS+1)*j+client] = Listen_Default;
    }
    g_aHandlers.SetArray(i, tempHandler[0], HANDLER_SIZE);
  }
}

public int Native_RegisterVoiceHandler(Handle plugin, int numParams)
{
  int tempHandler[VoiceHandler];
  for(int i = 0; i < g_aHandlers.Length; i++)
  {
    g_aHandlers.GetArray(i, tempHandler[0], HANDLER_SIZE);

    //Currently only one Handler per Plugin
    if(tempHandler[hPlugin] == plugin)
      return 0;
  }

  int priority = GetNativeCell(1);
  int Handler[VoiceHandler];
  Handler[iPriority] = priority;
  Handler[hPlugin] = plugin;
  g_aHandlers.PushArray(Handler[0], HANDLER_SIZE);
  SortADTArrayCustom(g_aHandlers, Handler_Comparator);
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
  int client = GetNativeCell(1);
  int target = GetNativeCell(2);
  ListenOverride flag = GetNativeCell(3);

  int tempHandler[VoiceHandler];
  for(int i = 0; i < g_aHandlers.Length; i++)
  {
    g_aHandlers.GetArray(i, tempHandler[0], HANDLER_SIZE);

    //This is the handler
    if(tempHandler[hPlugin] == plugin)
    {
      //This is no change
      if(tempHandler[iVoiceMap][(MAXPLAYERS+1)*client+target] == flag)
        return 0;
      tempHandler[iVoiceMap][(MAXPLAYERS+1)*client+target] = flag;
      int tempHandler2[VoiceHandler];
      if(flag == Listen_Default)
      {
        //Check if there is a handler with a lower priority to handle this
        for(int j = i-1; j >= 0; j--)
        {
          g_aHandlers.GetArray(j, tempHandler2[0], HANDLER_SIZE);
          if(tempHandler2[iVoiceMap][(MAXPLAYERS+1)*client+target] != Listen_Default)
          {
            SetListenOverride(client, target, view_as<ListenOverride>(tempHandler2[(MAXPLAYERS+1)*client+target]));
            return 0;
          }
        }
      }else{
        //Check if there is a handler with a higher priority to handle this
        for(int j = i+1; j < g_aHandlers.Length; j++)
        {
          g_aHandlers.GetArray(j, tempHandler2[0], HANDLER_SIZE);
          if(tempHandler2[iVoiceMap][(MAXPLAYERS+1)*client+target] != Listen_Default)
            return 0;
        }
      }
      SetListenOverride(client, target, tempHandler[iVoiceMap][(MAXPLAYERS+1)*client+target]);
      break;
    }
  }
  return 0;
}
