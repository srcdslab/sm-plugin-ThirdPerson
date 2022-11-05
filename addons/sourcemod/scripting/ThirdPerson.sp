#pragma semicolon 1

#include <sourcemod>
#include <cstrike>

#include <multicolors>
#include <zombiereloaded>

#undef REQUIRE_PLUGIN
#include <FullUpdate>
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
	author = "BotoX, maxime1907",
	description = "Allow players/admins to toggle thirdperson on themselves/players.",
	version = "1.1.0"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_thirdperson", Command_ThirdPerson, "Toggle thirdperson");
	RegConsoleCmd("sm_tp", Command_ThirdPerson, "Toggle thirdperson");
	RegConsoleCmd("sm_mirror", Command_Mirror, "Toggle Rotational Thirdperson view");

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);

	g_cvForceCamera = FindConVar("mp_forcecamera");

	if (GetEngineVersion() == Engine_CSGO)
	{
		g_cvAllowThirdPerson = FindConVar("sv_allow_thirdperson");
		if(g_cvAllowThirdPerson == INVALID_HANDLE)
			SetFailState("sv_allow_thirdperson not found!");
		
		SetConVarInt(g_cvAllowThirdPerson, 1);

		HookConVarChange(g_cvAllowThirdPerson, OnConVarChanged);
	}
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
	g_bFullUpdate = LibraryExists("FullUpdate");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "zombiereloaded"))
	{
		g_bZombieReloaded = true;
	}
	if (StrEqual(name, "FullUpdate"))
	{
		g_bFullUpdate = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "zombiereloaded"))
	{
		g_bZombieReloaded = false;
	}
	if (StrEqual(name, "FullUpdate"))
	{
		g_bFullUpdate = false;
	}
}

public void OnClientPutInServer(int client)
{
	g_bThirdPerson[client] = false;
}

public Action Command_Mirror(int client, int args)
{
	if(!IsValidClient(client, true))
	{
		ReplyToCommand(client, "[SM] You may not use this command as you are not alive.");
		return Plugin_Handled;
	}

	if (!g_bMirror[client])
		MirrorOn(client);
	else
		MirrorOff(client);
	return Plugin_Handled;
}

public Action Command_ThirdPerson(int client, int args)
{
	if(!IsValidClient(client, true))
	{
		ReplyToCommand(client, "[SM] You may not use this command as you are not alive.");
		return Plugin_Handled;
	}

	if(g_bThirdPerson[client])
		ThirdPersonOff(client);
	else
		ThirdPersonOn(client);
	
	return Plugin_Handled;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	char sWeapon[64];
	GetEventString(event, "weapon", sWeapon, sizeof(sWeapon));

	if (IsValidClient(client, _, false) && g_bThirdPerson[client] || g_bMirror[client])
	{
		if (g_bZombieReloaded && IsValidClient(attacker, _, false))
		{
			char sValue[256] = "zombie_claws_of_death";

			ConVar cvInfectEventWeapon = FindConVar("zr_infect_event_weapon");
			if (cvInfectEventWeapon != null)
				GetConVarString(cvInfectEventWeapon, sValue, sizeof(sValue));

			if (StrEqual(sWeapon, sValue, false))
				return Plugin_Continue;
		}

		if (g_bThirdPerson[client])
			ThirdPersonOff(client, true);
		if (g_bMirror[client])
			MirrorOff(client, true);

		int currentTeam = GetClientTeam(client);
		ChangeClientTeam(client, CS_TEAM_SPECTATOR);
		if (!g_bZombieReloaded)
			CS_SwitchTeam(client, currentTeam);
		else
			CS_SwitchTeam(client, CS_TEAM_T);
	}
	return Plugin_Continue;
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (IsValidClient(client, _, false))
	{
		if (g_bThirdPerson[client])
			ThirdPersonOff(client, true);
		if (g_bMirror[client])
			MirrorOff(client, true);
	}
	return Plugin_Continue;
}

void ThirdPersonOn(int client)
{
	if (GetEngineVersion() == Engine_CSGO)
	{
		ClientCommand(client, "thirdperson");
	}
	else
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
		SetEntProp(client, Prop_Send, "m_iFOV", 120);
	}

	g_bThirdPerson[client] = true;

	CPrintToChat(client, "{darkblue}[ThirdPerson]{default} is {green}ON{default}.");
}

void ThirdPersonOff(int client, bool notify = true)
{
	if (GetEngineVersion() == Engine_CSGO)
	{
		ClientCommand(client, "firstperson");
	}
	else
	{
		SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);
		SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
		SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
		SetEntProp(client, Prop_Send, "m_iFOV", 90);
	}

	g_bThirdPerson[client] = false;

	if (g_bFullUpdate)
		ClientFullUpdate(client);

	if (notify)
		CPrintToChat(client, "{darkblue}[ThirdPerson]{default} is {red}OFF{default}.");
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
		CPrintToChat(client, "{darkblue}[Mirror]{default} is {red}ON{default}.");
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

stock bool IsValidClient(int client, bool bAlive = false, bool checkTeam = true)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client) && (bAlive == false || IsPlayerAlive(client)))
	{
		if (checkTeam)
		{
			int currentTeam = GetClientTeam(client);
			if (currentTeam == CS_TEAM_T || currentTeam == CS_TEAM_CT)
				return true;
		}
		else
			return true;
	}
	return false;
}