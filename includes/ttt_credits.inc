#if defined _tttcredits_included
	#endinput
#endif
#define _tttcredits_included




#if !defined REQUIRE_PLUGIN
public __pl_INTERFACE_SetNTVOptional()
{
	MarkNativeAsOptional("TTT_GetClientCredits");
	MarkNativeAsOptional("TTT_SetClientCredits");
	MarkNativeAsOptional("TTT_GiveClientCredits");
}
#endif


public SharedPlugin __pl_tttcredits =
{
	name = "tttcredits",
	file = "ttt_credits.smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};

/**
 * Get the credits from a client.
 *
 * @param client	The client index.
 * @return			The amount of credits.
 */
native int TTT_GetClientCredits(int client);

/**
 * Set the credits from a client.
 *
 * @param client	The client index.
 * @param amount	The amount of credits.
 * @return void
 */
native void TTT_SetClientCredits(int client, int amount);

/**
 * Give a client some credits.
 *
 * @param client	The client index.
 * @param amount	The amount of credits.
 * @return void
 */
native void TTT_GiveClientCredits(int client, int amount);