#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <multicolors>

#undef REQUIRE_PLUGIN
#tryinclude <zombiereloaded>
#tryinclude <FullUpdate>
#define REQUIRE_PLUGIN

#pragma newdecls required

bool g_bThirdPerson[MAXPLAYERS + 1] = { false, ... };
bool g_bMirror[MAXPLAYERS + 1] = { false, ... };

bool g_bZombieReloaded = false;
bool g_bFullUpdate = false;

ConVar g_cvAllowThirdPerson;
ConVar g_cvForceCamera;

public Plugin myinfo =
{
	name = "ThirdPerson",
	author = "BotoX, maxime1907, .Rushaway",
	description = "Allow players/admins to toggle thirdperson on themselves/players.",
	version = "1.3.7"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegPluginLibrary("ThirdPerson");

	CreateNative("Mirror_Status", Native_Mirror);
	CreateNative("ThirdPerson_Status", Native_ThirdPerson);

	return APLRes_Success;
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_thirdperson", Command_ThirdPerson, "Toggle thirdperson");
	RegConsoleCmd("sm_tp", Command_ThirdPerson, "Toggle thirdperson");
	RegConsoleCmd("sm_mirror", Command_Mirror, "Toggle Rotational Thirdperson view");

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);

	g_cvForceCamera = FindConVar("mp_forcecamera");
}

public void OnConVarChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	if(cvar == g_cvAllowThirdPerson && StringToInt(newVal) != 1)
	{
		g_cvAllowThirdPerson.SetInt(1);
	}
}

public void OnAllPluginsLoaded()
{
	g_bZombieReloaded = LibraryExists("zombiereloaded");
	g_bFullUpdate = LibraryExists("FullUpdate");
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, "zombiereloaded", false) == 0)
	{
		g_bZombieReloaded = true;
	}
	else if (strcmp(name, "FullUpdate", false) == 0)
	{
		g_bFullUpdate = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, "zombiereloaded", false) == 0)
	{
		g_bZombieReloaded = false;
	}
	else if (strcmp(name, "FullUpdate", false) == 0)
	{
		g_bFullUpdate = false;
	}
}

public void OnClientPutInServer(int client)
{
	g_bThirdPerson[client] = false;
	g_bMirror[client] = false;
}

public void OnClientDisconnect(int client)
{
	g_bThirdPerson[client] = false;
	g_bMirror[client] = false;
}

public Action Command_Mirror(int client, int args)
{
	if(!IsValidClient(client, true, true))
	{
		ReplyToCommand(client, "[SM] You may not use this command as you are not alive.");
		return Plugin_Handled;
	}

	if(g_bThirdPerson[client])
		ThirdPersonOff(client, false);

	if (!g_bMirror[client])
		MirrorOn(client);
	else
		MirrorOff(client);
	
	return Plugin_Handled;
}

public Action Command_ThirdPerson(int client, int args)
{
	if(!IsValidClient(client, true, true))
	{
		ReplyToCommand(client, "[SM] You may not use this command as you are not alive.");
		return Plugin_Handled;
	}

	if (g_bMirror[client])
		MirrorOff(client);

	if(g_bThirdPerson[client])
		ThirdPersonOff(client, true);
	else
		ThirdPersonOn(client);
	
	return Plugin_Handled;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client, true, false) && (g_bThirdPerson[client] || g_bMirror[client]))
	{
		int attacker = GetClientOfUserId(event.GetInt("attacker"));
		if (g_bZombieReloaded && IsValidClient(attacker, false))
		{
			char sValue[256] = "zombie_claws_of_death";

			ConVar cvInfectEventWeapon = FindConVar("zr_infect_event_weapon");
			if (cvInfectEventWeapon != null)
				cvInfectEventWeapon.GetString(sValue, sizeof(sValue));

			delete cvInfectEventWeapon;

			char sWeapon[64];
			event.GetString("weapon", sWeapon, sizeof(sWeapon));

			if (!StrEqual(sWeapon, sValue, false))
				ResetClient(client, true);
		}
		else
		{
			ResetClient(client, true);
		}
	}
	return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (IsValidClient(client, true))
	{
		ResetClient(client);
	}
	return Plugin_Continue;
}

void ThirdPersonOn(int client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
	SetEntProp(client, Prop_Send, "m_iFOV", 120);

	g_bThirdPerson[client] = true;

	CPrintToChat(client, "{darkblue}[ThirdPerson]{default} is {green}ON{default}.");
}

void ThirdPersonOff(int client, bool notify = true)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
	SetEntProp(client, Prop_Send, "m_iFOV", 90);

	g_bThirdPerson[client] = false;

#if defined _FullUpdate_Included
	if (g_bFullUpdate)
		ClientFullUpdate(client);
#endif

	if (notify)
		CPrintToChat(client, "{darkblue}[ThirdPerson]{default} is {red}OFF{default}.");
}

stock void ResetClient(int client, bool bFixUI = false)
{
	if (g_bThirdPerson[client])
		ThirdPersonOff(client, true);
	if (g_bMirror[client])
		MirrorOff(client, true);
	if (bFixUI)
		FixClientUI(client);
}

stock void FixClientUI(int client)
{
	int currentTeam = GetClientTeam(client);
	if (currentTeam < CS_TEAM_T)
		return;

	ChangeClientTeam(client, CS_TEAM_SPECTATOR);

	// Always put the client back in their own team: forcing CS_TEAM_T before the mother zombie
	// spawned gives the engine a spawnable T and it restarts the round (Game_Commencing).
	CS_SwitchTeam(client, currentTeam);

	if (g_bZombieReloaded && !IsPlayerAlive(client))
	{
		ConVar cvRespawn = FindConVar("zr_respawn");
		if (cvRespawn != null && cvRespawn.IntValue == 1)
			RequestFrame(RespawnClient, GetClientUserId(client));

		delete cvRespawn;
	}
}

stock void RespawnClient(int userid)
{
	int client = GetClientOfUserId(userid);
	if (!client || IsPlayerAlive(client))
		return;

	// The client may have been moved to spectator in the meantime (e.g. sm_spec)
	if (GetClientTeam(client) < CS_TEAM_T)
		return;

	CS_RespawnPlayer(client);
}

stock void MirrorOn(int client, bool notify = true)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
	SetEntProp(client, Prop_Send, "m_iFOV", 120);

	if (!IsFakeClient(client))
		SendConVarValue(client, g_cvForceCamera, "1");

	g_bMirror[client] = true;

	if (notify)
		CPrintToChat(client, "{darkblue}[Mirror]{default} is {green}ON{default}.");
}

stock void MirrorOff(int client, bool notify = true)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", -1);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
	SetEntProp(client, Prop_Send, "m_iFOV", 90);

	if (!IsFakeClient(client))
	{
		char sValue[6];
		g_cvForceCamera.GetString(sValue, 6);
		SendConVarValue(client, g_cvForceCamera, sValue);
	}

	g_bMirror[client] = false;

	if (notify)
		CPrintToChat(client, "{darkblue}[Mirror]{default} is {red}OFF{default}.");
}

public int Native_Mirror(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	return g_bMirror[client];
}

public int Native_ThirdPerson(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	return g_bThirdPerson[client];
}

stock bool IsValidClient(int client, bool bots = false, bool bAlive = false)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (bots == false || !IsFakeClient(client)) && (bAlive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	return false;
}
