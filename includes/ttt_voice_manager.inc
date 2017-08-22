#if defined _tttvoice_included
	#endinput
#endif
#define _tttvoice_included

/**
 * Register a VoiceHandler.
 *
 * @param priority	The priority of the voice handler.
 * @return			nothing.
 */
native int TTT_RegisterVoiceHandler(int priority);

/**
 * Set the ListenOverride for a specific reciever and sender.
 *
 * @return			nothing.
 */
native int TTT_SetListenOverride(int reciever, int sender, ListenOverride type);
