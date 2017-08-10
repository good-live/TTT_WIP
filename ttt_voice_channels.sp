#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <ttt>

public Plugin myinfo =
{
  name = "TTT - Voice Channels"
  author = "good_live"
  description = "Allows admins to create several voice channels"
  version = "0.1"
  url = "painlessgaming.eu"
};

StringMap g_hVoiceChannels;

int g_iPlayerChannel[MAXPLAYERS+1] = {-1, ...};
int g_iChannelCount;

public void OnPluginStart()
{
  //High priority
  TTT_RegisterVoiceHandler(3);

  g_hVoiceChannels = new StringMap();

  RegAdminCmd("sm_vcreate", CMD_VCREATE, ADMFLAG_GENERIC);
  RegAdminCmd("sm_vclose", CMD_VCLOSE, ADMFLAG_GENERIC);
  RegAdminCmd("sm_vadd", CMD_VADD, ADMFLAG_GENERIC);
  RegAdminCmd("sm_vjoin" CMD_VJOIN, ADMFLAG_GENERIC);
  RegAdminCmd("sm_vleave" CMD_VLEAVE, ADMFLAG_GENERIC);
  RegAdminCmd("sm_vkick" CMD_VKICK, ADMFLAG_GENERIC);
}

public Action CMD_VCREATE(int client, int args)
{
  if(args < 1)
  {
    CReplyToCommand("client", "%t%t", "TAG", "TTT_VOICE_CHANNELS_MISSING_NAME");
    return Plugin_Handled;
  }

  char sName[32];
  GetCmdArg(1, sName, sizeof(sName));
  AddClientToChannel(CreateChannel(sName), client);
}

public Action CMD_VCLOSE(int client, int args)
{
  if(g_iPlayerChannel[client] == -1)
  {
    CReplyToCommand("client", "%t%t", "TAG", "TTT_VOICE_CHANNELS_NO_CHANNEL");
    return Plugin_Handled;
  }
  CloseChannel(channel);
}

int CreateChannel(char[] sName)
{
  int index = g_iChannelCount;
  if(g_hVoiceChannels.GetValue(sName, index))
    return index;

  g_hVoiceChannels.SetString("sName", index, false);
  g_iChannelCount++;
  return index;
}

void CloseChannel(int channel)
{

  //Kick all players from this channel
  for(int i = 1; i <= MaxClients; i++)
  {
    if(g_iPlayerChannel[client] == channel)
      AddClientToChannel(-1, client);
  }

  StringMapSnapshot snapshot = g_hVoiceChannels.Snapshot();
  char sId[8];
  for(int i = 0; i < snapshot.Length; i++)
  {
    snapshot.GetKey(i, sId, sizeof(sId));
    if(channel == StringToInt(sId))
    {
      g_hVoiceChannels.Remove(i);
      break;
    }
  }
  delete snapshot;
}

void AddClientToChannel(int channel, int client)
{
  g_iPlayerChannel[client] = channel;
  for(int i = 1; i <= MaxClients; i++)
  {
    if(g_iPlayerChannel[client] != channel)
    {
      TTT_SetListenOverride(client, i, Listen_No);
      TTT_SetListenOverride(i, client, Listen_No);
    }
    else
    {
      TTT_SetListenOverride(client, i, Listen_Yes);
      TTT_SetListenOverride(i, client, Listen_Yes);
    }
  }
}
