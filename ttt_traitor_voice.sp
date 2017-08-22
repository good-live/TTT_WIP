#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ttt>
#include <ttt_voice_manager>
#include <multicolors>

public Plugin myinfo = 
{
	name = "TTT - Traitor Voice Handler", 
	author = "good_live", 
	description = "The default voice handler (Mute dead players for alive)", 
	version = "0.1", 
	url = "painlessgaming.eu"
};

bool g_bTVoice[MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	
	RegConsoleCmd("sm_tvoice", CMD_TVOICE);
}

public void OnAllPluginsLoaded()
{
	//lowest priority
	TTT_RegisterVoiceHandler(1);
}

public Action CMD_TVOICE(int client, int args)
{
	if (TTT_GetClientRole(client) != TTT_TEAM_TRAITOR)
	{
		CReplyToCommand(client, "%t%t", "TAG", "TTT_VOICE_TRAITOR_ONLY");
		return Plugin_Handled;
	}
	if (!IsPlayerAlive(client))
	{
		CReplyToCommand(client, "%t%t", "TAG", "TTT_VOICE_ALIVE_ONLY");
		return Plugin_Handled;
	}
	
	if (g_bTVoice[client])
	{
		CReplyToCommand(client, "%t%t", "TAG", "TTT_VOICE_LEAVE");
		g_bTVoice[client] = false;
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!TTT_IsClientValid(i))
				continue;
			//He can be heard by everybody again
			TTT_SetListenOverride(client, i, Listen_Default);
		}
	}
	else
	{
		CReplyToCommand(client, "%t%t", "TAG", "TTT_VOICE_JOIN");
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!TTT_IsClientValid(i) || !IsPlayerAlive(i) || TTT_GetClientRole(i) != TTT_TEAM_TRAITOR)
				continue;
			//He can be heard by other alive traitos
			TTT_SetListenOverride(client, i, Listen_Yes);
		}
	}
	return Plugin_Handled;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bTVoice[client] = false;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!TTT_IsClientValid(i))
			continue;
		TTT_SetListenOverride(client, i, Listen_Default);
		TTT_SetListenOverride(i, client, Listen_Default);
	}
}
