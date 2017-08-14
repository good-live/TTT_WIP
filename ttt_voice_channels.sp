#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ttt>
#include <ttt_voice_manager>
#include <multicolors>

public Plugin myinfo = 
{
	name = "TTT - Voice Channels", 
	author = "good_live", 
	description = "Allows admins to create several voice channels", 
	version = "0.1", 
	url = "painlessgaming.eu"
};

int g_iPlayerChannel[MAXPLAYERS + 1] =  { -1, ... };
int g_iChannelCount;

public void OnPluginStart()
{	
	RegAdminCmd("sm_vcreate", CMD_VCREATE, ADMFLAG_GENERIC);
	RegAdminCmd("sm_vclose", CMD_VCLOSE, ADMFLAG_GENERIC);
	RegAdminCmd("sm_vadd", CMD_VADD, ADMFLAG_GENERIC);
	RegAdminCmd("sm_vleave", CMD_VLEAVE, ADMFLAG_GENERIC);
	RegAdminCmd("sm_vkick", CMD_VKICK, ADMFLAG_GENERIC);
	
	LoadTranslations("common.phrases");
}

public void OnAllPluginsLoaded()
{
	//High priority
	TTT_RegisterVoiceHandler(3);
}

public Action CMD_VCREATE(int client, int args)
{
	AddClientToChannel(g_iChannelCount++, client);
	CReplyToCommand(client, "%t%t", "TAG", "CHANNEL_CREATED")
	return Plugin_Handled;
}

public Action CMD_VADD(int client, int args)
{
	if (args < 1)
		CReplyToCommand(client, "[SM] Usage: sm_vadd <player>");
	
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
				arg, 
				client, 
				target_list, 
				MAXPLAYERS, 
				0, 
				target_name, 
				sizeof(target_name), 
				tn_is_ml)) > 0)
	{
		for (int i = 0; i < target_count; i++)
		{
			/* Kick everyone else first */
			if (target_list[i] == client)
			{
				continue;
			}
			else
			{
				AddClientToChannel(target_list[i], g_iPlayerChannel[client]);
			}
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	
	return Plugin_Handled;
}

public Action CMD_VLEAVE(int client, int args)
{
	AddClientToChannel(-1, client);
	return Plugin_Handled;
}

public Action CMD_VKICK(int client, int args)
{
	if (args < 1)
		CReplyToCommand(client, "[SM] Usage: sm_vkick <player>");
	
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
				arg, 
				client, 
				target_list, 
				MAXPLAYERS, 
				0, 
				target_name, 
				sizeof(target_name), 
				tn_is_ml)) > 0)
	{
		for (int i = 0; i < target_count; i++)
		{
			KickClientFromChannel(target_list[i]);
		}
	}
	else
	{
		ReplyToTargetError(client, target_count);
	}
	return Plugin_Handled;
}

public Action CMD_VCLOSE(int client, int args)
{
	if (g_iPlayerChannel[client] == -1)
	{
		CReplyToCommand(client, "%t%t", "TAG", "NO_CHANNEL");
		return Plugin_Handled;
	}
	CloseChannel(g_iPlayerChannel[client]);
	return Plugin_Handled;
}

void CloseChannel(int channel)
{
	//Kick all players from this channel
	for (int i = 1; i <= MaxClients; i++)
	{
		if (g_iPlayerChannel[i] == channel)
		{
			AddClientToChannel(-1, i);
			CPrintToChat(i, "%t%t", "TAG", "CHANNEL_CLOSED")
		}
	}
}

bool KickClientFromChannel(int client)
{
	if (g_iPlayerChannel[client] == -1)
		return false;
	
	CPrintToChat(client, "%t%t", "TAG", "KICKED_FROM_CHANNEL");
	return true;
}


void AddClientToChannel(int channel, int client)
{
	int oldChannel = g_iPlayerChannel[client];
	g_iPlayerChannel[client] = channel;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (i == client)
			continue;
		if (g_iPlayerChannel[client] != channel)
		{
			TTT_SetListenOverride(client, i, Listen_No);
			TTT_SetListenOverride(i, client, Listen_No);
			
			if (oldChannel == g_iPlayerChannel[client])
				CPrintToChat(i, "%t%t", "TAG", "CLIENT_LEFT_YOUR_CHANNEL", client);
		}
		else
		{
			if (channel == -1)
			{
				TTT_SetListenOverride(client, i, Listen_Default);
				TTT_SetListenOverride(i, client, Listen_Default);
			}
			else
			{
				TTT_SetListenOverride(client, i, Listen_Yes);
				TTT_SetListenOverride(i, client, Listen_Yes);
			}
			CPrintToChat(i, "%t%t", "TAG", "CLIENT_JOINED_YOUR_CHANNEL", client);
		}
	}
}
