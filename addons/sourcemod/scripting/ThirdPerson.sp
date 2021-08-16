#pragma semicolon 1

#include <sourcemod>
#include <cstrike>
#include <FullUpdate>
#include <multicolors>
#include <zombiereloaded>

#pragma newdecls required

bool g_bThirdPerson[MAXPLAYERS + 1] = { false, ... };

bool g_bZombieReloaded = false;

public Plugin myinfo =
{
	name = "ThirdPerson",
	author = "BotoX, maxime1907",
	description = "Allow players/admins to toggle thirdperson on themselves/players.",
	version = "1.1"
}

public void OnPluginStart()
{
	RegConsoleCmd("sm_tp", Command_ThirdPerson, "Toggle thirdperson");

	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public void OnAllPluginsLoaded()
{
	g_bZombieReloaded = LibraryExists("zombiereloaded");
}

public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "zombiereloaded"))
	{
		g_bZombieReloaded = true;
	}
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "zombiereloaded"))
	{
		g_bZombieReloaded = false;
	}
}

public void OnClientPutInServer(int client)
{
	g_bThirdPerson[client] = false;
}

public Action Command_ThirdPerson(int client, int args)
{
	if(!IsValidClient(client, true))
		return Plugin_Handled;

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

	if (IsValidClient(client, _, false) && g_bThirdPerson[client])
	{
		if (g_bZombieReloaded && IsValidClient(attacker, _, false) && StrEqual(sWeapon, "zombie_claws_of_death", false))
			return Plugin_Continue;

		ThirdPersonOff(client, true);

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
	if (IsValidClient(client, _, false) && g_bThirdPerson[client])
		ThirdPersonOff(client, true);
	return Plugin_Continue;
}

void ThirdPersonOn(int client)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", 0);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 1);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 0);
	SetEntProp(client, Prop_Send, "m_iFOV", 120);

	g_bThirdPerson[client] = true;

	CPrintToChat(client, "{cyan}[ThirdPerson]{default} is {green}ON{default}.");
}

void ThirdPersonOff(int client, bool notify = true)
{
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", client);
	SetEntProp(client, Prop_Send, "m_iObserverMode", 0);
	SetEntProp(client, Prop_Send, "m_bDrawViewmodel", 1);
	SetEntProp(client, Prop_Send, "m_iFOV", 90);

	g_bThirdPerson[client] = false;

	ClientFullUpdate(client);

	if (notify)
		CPrintToChat(client, "{cyan}[ThirdPerson]{default} is {red}OFF{default}.");
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