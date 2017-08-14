#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ttt>
#include <ttt_voice_manager>

public Plugin myinfo = 
{
	name = "TTT - Default Voice Handler", 
	author = "good_live", 
	description = "The default voice handler (Mute dead players for alive)", 
	version = "0.1", 
	url = "painlessgaming.eu"
};

public void OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnAllPluginsLoaded()
{
	//lowest priority
	TTT_RegisterVoiceHandler(0);
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	
	int client = GetClientOfUserId(event.GetInt("userid"));
	LoopValidClients(i)
	{
		TTT_SetListenOverride(i, client, Listen_Yes);
		if (!IsPlayerAlive(i))
			TTT_SetListenOverride(client, i, Listen_No);
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(event.GetInt("userid"));
	
	LoopValidClients(i)
	{
		if (IsPlayerAlive(i))
		{
			TTT_SetListenOverride(i, victim, Listen_No);
		}
		else
		{
			TTT_SetListenOverride(i, victim, Listen_Yes);
		}
	}
}
