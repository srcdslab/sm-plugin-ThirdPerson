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
bool g_bZombieSpawned = false;
bool g_bTeamManager = false;
bool g_bFullUpdate = false;

ConVar g_cvAllowThirdPerson;
ConVar g_cvForceCamera;

public Plugin myinfo =
{
	name = "ThirdPerson",
	author = "BotoX, maxime1907, .Rushaway",
	description = "Allow players/admins to toggle thirdperson on themselves/players.",
	version = "1.3.3"
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

	HookEvent("round_start", Event_RoundStart, EventHookMode_Pre);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);

	g_cvForceCamera = FindConVar("mp_forcecamera");
}

public void OnConVarChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	if(cvar == g_cvAllowThirdPerson && StringToInt(newVal) != 1)
	{
		SetConVarInt(g_cvAllowThirdPerson, 1);
	}
}

public void OnAllPluginsLoaded()
{
	g_bZombieReloaded = LibraryExists("zombiereloaded");
	g_bTeamManager = LibraryExists("TeamManager");
	g_bFullUpdate = LibraryExists("FullUpdate");
}

public void OnLibraryAdded(const char[] name)
{
	if (strcmp(name, "zombiereloaded", false) == 0)
	{
		g_bZombieReloaded = true;
	}
	else if (strcmp(name, "TeamManager", false) == 0)
	{
		g_bTeamManager = true;
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
	else if (strcmp(name, "TeamManager", false) == 0)
	{
		g_bTeamManager = false;
	}
	else if (strcmp(name, "FullUpdate", false) == 0)
	{
		g_bFullUpdate = false;
	}
}

public void OnClientPutInServer(int client)
{
	g_bThirdPerson[client] = false;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bZombieSpawned = false;
}

public Action Command_Mirror(int client, int args)
{
	if(!IsValidClient(client, true, true))
	{
		ReplyToCommand(client, "[SM] You may not use this command as you are not alive.");
		return Plugin_Handled;
	}

#if defined _zr_included
	if(!g_bZombieSpawned)
	{
		CReplyToCommand(client, "{green}[SM] {default}You may not use this command as there is no zombie spawned.");
		return Plugin_Handled;
	}
#endif

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

#if defined _zr_included
	if(!g_bZombieSpawned)
	{
		CReplyToCommand(client, "{green}[SM] {default}You may not use this command as there is no zombie spawned.");
		return Plugin_Handled;
	}
#endif

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
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client, true, false) && g_bThirdPerson[client] || g_bMirror[client])
	{
		int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
		if (g_bZombieReloaded && IsValidClient(attacker, false))
		{
			char sValue[256] = "zombie_claws_of_death";

			ConVar cvInfectEventWeapon = FindConVar("zr_infect_event_weapon");
			if (cvInfectEventWeapon != null)
				GetConVarString(cvInfectEventWeapon, sValue, sizeof(sValue));

			delete cvInfectEventWeapon;

			char sWeapon[64];
			GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));

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
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client))
	{
		ResetClient(client);
	}
	return Plugin_Continue;
}

#if defined _zr_included
public void ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	if (motherInfect && g_bTeamManager)
		g_bZombieSpawned = true;
}
#endif

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
	ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	if (!g_bZombieReloaded)
		CS_SwitchTeam(client, currentTeam);
	else
	{
		CS_SwitchTeam(client, CS_TEAM_T);
		if (!IsPlayerAlive(client))
		{
			ConVar cvRespawn = FindConVar("zr_respawn");
			if (cvRespawn.IntValue == 1)
				RequestFrame(RespawnClient, client);

			delete cvRespawn;
		}
	}
}

stock void RespawnClient(int client)
{
	if (IsClientInGame(client))
		CS_RespawnPlayer(client);
}

stock void MirrorOn(int client, bool notify = true)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0); 
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
	SetEntProp(client, Prop_Send, "m_iFOV", 120);
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

	char sValue[6];
	GetConVarString(g_cvForceCamera, sValue, 6);
	SendConVarValue(client, g_cvForceCamera, sValue);

	g_bMirror[client] = false;

	if (notify)
		CPrintToChat(client, "{darkblue}[Mirror]{default} is {red}OFF{default}.");
}

public int Native_Mirror(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	return g_bThirdPerson[client];
}

public int Native_ThirdPerson(Handle plugin, int params)
{
	int client = GetNativeCell(1);
	return g_bMirror[client];
}

stock bool IsValidClient(int client, bool bots = false, bool bAlive = false)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (bots == false || !IsFakeClient(client)) && (bAlive == false || IsPlayerAlive(client)))
	{
		return true;
	}
	return false;
}
