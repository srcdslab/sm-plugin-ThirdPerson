#if defined _ThirdPerson_included
	#endinput
#endif
#define _ThirdPerson_included

/**
 * Returns true if the player is using Mirror, false if not.
 *
 * @param client            The client index.
 *
 * @return                  True if using Mirror, false if not.
 * @error                   Invalid client index, not connected or not alive.
 */
native bool Mirror_Status(int client);

/**
 * Returns true if the player is using ThirdPerson, false if not.
 *
 * @param client            The client index.
 *
 * @return                  True if using TP, false if not.
 * @error                   Invalid client index, not connected or not alive.
 */
native bool ThirdPerson_Status(int client);

public SharedPlugin __pl_ThirdPerson = 
{
	name = "ThirdPerson",
	file = "ThirdPerson.smx",
#if defined REQUIRE_PLUGIN
	required = 1
#else
	required = 0
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_ThirdPerson_SetNTVOptional()
{
	MarkNativeAsOptional("Mirror_Status");
	MarkNativeAsOptional("ThirdPerson_Status");
}
#endif
