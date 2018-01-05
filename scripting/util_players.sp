#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <geoip>

new bool:g_Hide[MAXPLAYERS + 1];
new bool:g_HideTeam[MAXPLAYERS + 1];
new bool:g_HideEnemy[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name = "Utility Kit - Players Module",
	author = "Ascyrii",
	description = "A large set of commands and useful stuffs.",
	version = "0.65",
	url = "http://www.coldcommunity.com"
}

public OnClientPutInServer(client)
{
	g_Hide[client] = false;
	g_HideTeam[client] = false;
	g_HideEnemy[client] = false;
	SDKHook(client, SDKHook_SetTransmit, shouldSetTransmit);
}

/*
*	Standard SetTransmit Hook.
*	Usage: Allow plugin developer to decide which entities are visible to the client.
*	@return		Plugin_Handled to hide entity, Plugin_Continue to show.
*/
public Action:shouldSetTransmit(entity, client) 
{ 
    if (client != entity && (0 < entity <= MaxClients) && IsClientInGame(client))
    { 
    	if(g_Hide[client])
    	{
        	return Plugin_Handled;
        }
        else if(g_HideTeam[client] && GetClientTeam(client) == GetClientTeam(entity))
        {
        	return Plugin_Handled;
        }
        else if(g_HideEnemy[client] && GetClientTeam(client) != GetClientTeam(entity))
        {
        	return Plugin_Handled;
        }
  	}
     
    return Plugin_Continue; 
}  

public OnPluginStart()
{
	LoadTranslations("common.phrases");

	RegAdminCmd("sm_player_stats", command_showServerPlayerInfo, ADMFLAG_GENERIC, "View information and run-time statistics about players in the server");
	RegAdminCmd("sm_changeteam", command_changePlayerTeam, ADMFLAG_GENERIC, "Change a player's team");
	RegAdminCmd("sm_get_cl_variable", command_getPlayerCvar, ADMFLAG_GENERIC, "Get the value of a player's cl_variable");

	RegConsoleCmd("sm_playerinfo", command_playerInfo, "View information about a player");
	RegConsoleCmd("sm_dox", command_playerInfo, "View information about a player");
	RegConsoleCmd("dox", command_playerInfo, "View information about a player");

	RegConsoleCmd("sm_hide", command_hidePlayers, "Hide all visible players");
	RegConsoleCmd("sm_hideplayers", command_hidePlayers, "Hide all visible players");
	RegConsoleCmd("sm_show", command_hidePlayers, "Hide all visible players");
	RegConsoleCmd("sm_showplayers", command_hidePlayers, "Hide all visible players");

	RegConsoleCmd("sm_hideteam", command_hideTeam, "Hide all the players on your team");
	RegConsoleCmd("sm_hideenemy", command_hideEnemy, "Hide all the enemies on your team");
	RegConsoleCmd("sm_showteam", command_hideTeam, "Hide all the players on your team");
	RegConsoleCmd("sm_showenemy", command_hideEnemy, "Hide all the enemies on your team");
}

/*
*	Command: sm_get_cl_variable <client> <cl_convar>
*	Usage: Get the value of a player's client variable.
*/
public Action:command_getPlayerCvar(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[Utility Kit] Invalid Usage: sm_get_cl_variable <player> <cl_convar>");
		return Plugin_Handled;
	}

	decl String:arg[32], String:vari[32];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, vari, sizeof(vari));

	new String:targetName[MAX_TARGET_LENGTH];
	new targets[MAXPLAYERS + 1], targetCount;
	new bool:multiLang;
 
	if ((targetCount = ProcessTargetString(
			arg,
			client,
			targets,
			1,
			COMMAND_FILTER_CONNECTED,
			targetName,
			sizeof(targetName),
			multiLang)) <= 0)
	{

		ReplyToCommand(client, "[Utility Kit] Invalid Target: %s", arg);
		return Plugin_Handled;
	}

	for(new i = 0; i < targetCount; i++)
	{
		new target = targets[i];
		decl String:varVal[32];

		GetClientInfo(target, vari, varVal, sizeof(varVal));
		ReplyToCommand(client, "[Utility Kit] %s's value of %s: %s", targetName[i], vari, varVal);
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

/*
*	Command: sm_changeteam <client> <team num/name>
*	Usage: Change a client's team forcefully.
*/
public Action:command_changePlayerTeam(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "[Utility Kit] Invalid Usage: sm_changeteam <player> <team id/name>");
		return Plugin_Handled;
	}

	decl String:arg[32], String:team[32];
	GetCmdArg(1, arg, sizeof(arg));
	GetCmdArg(2, team, sizeof(team));

	new String:targetName[MAX_TARGET_LENGTH];
	new targets[MAXPLAYERS + 1], targetCount;
	new bool:multiLang;
 
	if ((targetCount = ProcessTargetString(
			arg,
			client,
			targets,
			1,
			COMMAND_FILTER_CONNECTED,
			targetName,
			sizeof(targetName),
			multiLang)) <= 0)
	{

		ReplyToCommand(client, "[Utility Kit] Invalid Target: %s", arg);
		return Plugin_Handled;
	}

	for(new i = 0; i < targetCount; i++)
	{
		new target = targets[i];
		decl String:teamName[32];
		new bool:number = IsCharNumeric(arg[0]);
		if(!number) //Check if argument is a team index or team name
		{
			if(StringToTeam(team) == -1)
			{
				ReplyToCommand(client, "[Utility Kit] Invalid Team: %s", team);
				return Plugin_Handled;
			}

			ChangeClientTeam(target, StringToTeam(team));
			GetTeamName(StringToTeam(team), teamName, sizeof(teamName));
			ReplyToCommand(client, "[Utility Kit] Switched %s to %s", targetName[i], teamName);
			return Plugin_Handled;
		}
		else
		{
			ChangeClientTeam(target, StringToInt(team));
			GetTeamName(StringToInt(team), teamName, sizeof(teamName));
			ReplyToCommand(client, "[Utility Kit] Switched %s to %s", targetName[i], teamName);
			return Plugin_Handled;
		}
	}

	return Plugin_Handled;
}

/*
*	Stock StringToTeam
*	@param team 	Team name
*	@return    		Team index
*	@error     		-1
*	Usage: Get a team index based on the team name (if found).
*/
stock StringToTeam(const String:team[])
{
	if(StrContains(team, "CT", false) != -1 || StrContains(team, "Counter", false) != -1)
	{
		return 2;
	}
	else if(StrContains(team, "T", false) != -1 || StrContains(team, "Terrorist", false))
	{
		return 3;
	}
	else if(StrContains(team, "Rebel", false) != -1 || StrContains(team, "Red", false) != -1)
	{
		return 3;
	}
	else if(StrContains(team, "Combine", false) != -1 || StrContains(team, "Blu", false) != -1)
	{
		return 2;
	}
	else if(StrContains(team, "Spec", false) != -1 || StrContains(team, "Spectator", false) != -1)
	{
		return 1;
	}
	else return -1;
}

/*
*	Command: sm_player_stats <NO ARGS>
*	Usage: Get generic information about all the current clients in the server.
*/
public Action:command_showServerPlayerInfo(client, args)
{
	new bots = 0, players = 0, Float:avgLatency[MAXPLAYERS + 1] = 0.0;
	new team1 = 0, team2 = 0, team3 = 0;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && i != 0)
		{
			if(IsFakeClient(i)) //Count as bot, not player..
			{
				bots++; 
				continue;
			}

			avgLatency[players] = GetClientLatency(i, NetFlow_Outgoing);
			players++; //Total player count

			switch(GetClientTeam(i))
			{
				case 0, 1: 
				{
					team1++;
				}
				
				case 2: 
				{
					team2++;
				}

				case 3: 
				{
					team3++;
				}
			}
		}
	}


	new ping, lat;

	for(new p = 0; p <= players; p++)
	{
		avgLatency[p] -= (0.5 / 100 + GetTickInterval() * 1.0); //We'll just assume 100 cmdrate. 
		ping = RoundFloat(avgLatency[p] * 1000.0);
		lat += ping;
	}

	lat = (lat / players);

	decl String:teamName[3][32];
	GetTeamName(1, teamName[0], sizeof(teamName[]));
	GetTeamName(2, teamName[1], sizeof(teamName[]));
	GetTeamName(3, teamName[2], sizeof(teamName[]));
	ReplyToCommand(client, "Current Players: %i\nCurrent Bots: %i\nAverage Latency: %i\nPlayers on team %s: %i\nPlayers on team %s: %i\nPlayers on team %s: %i", players, bots, lat, teamName[0], team1, teamName[1], team2, teamName[2], team3);
	return Plugin_Handled;
}

/*
*	Commands: sm_hideX
*	Usage: Implement and use the SetTransmit Hook.
*/
public Action:command_hideEnemy(client, args)
{
	if(!g_HideEnemy[client]) 
	{
		ReplyToCommand(client, "[Utility Kit] All players on the enemy team are now hidden");
		g_HideEnemy[client] = true;
	}
	else 
	{
		ReplyToCommand(client, "[Utility Kit] All players on the enemy team are now visible");
		g_HideEnemy[client] = false;
	}

	return Plugin_Handled;
}

public Action:command_hideTeam(client, args)
{
	if(!g_HideTeam[client]) 
	{
		ReplyToCommand(client, "[Utility Kit] All players on your team are now hidden");
		g_HideTeam[client] = true;
	}
	else 
	{
		ReplyToCommand(client, "[Utility Kit] All players on your team are now visible");
		g_HideTeam[client] = false;
	}

	return Plugin_Handled;
}

public Action:command_hidePlayers(client, args)
{
	if(!g_Hide[client]) 
	{
		ReplyToCommand(client, "[Utility Kit] All players are now hidden");
		g_Hide[client] = true;
	}
	else 
	{
		ReplyToCommand(client, "[Utility Kit] All players are now visible");
		g_Hide[client] = false;
	}

	return Plugin_Handled;
}

/*
*	Command:sm_playerinfo <client>
*	Usage: Get a list of information on the client, essential to reporting rulebreakers, etc..
*/
public Action:command_playerInfo(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[Utility Kit] Invalid Usage: sm_info <player>");
		return Plugin_Handled;
	}

	decl String:arg[MAX_NAME_LENGTH];
	GetCmdArgString(arg, sizeof(arg));

	new String:targetName[MAX_TARGET_LENGTH];
	new targets[MAXPLAYERS + 1], targetCount;
	new bool:multiLang;
 
	if ((targetCount = ProcessTargetString(
			arg,
			client,
			targets,
			1,
			COMMAND_FILTER_CONNECTED,
			targetName,
			sizeof(targetName),
			multiLang)) <= 0)
	{

		ReplyToCommand(client, "[Utility Kit] Invalid Target: %s", arg);
		return Plugin_Handled;
	}

	for(new i = 0; i < targetCount; i++)
	{
		new target = targets[i];

		decl String:textfmt[256], String:steam[64];
		new Handle:imenu = CreateMenu(infoMenu);

		Format(textfmt, sizeof(textfmt), "Name: %s", targetName);
		AddMenuItem(imenu, "1", textfmt);

		GetClientAuthId(target, AuthId_Engine, steam, sizeof(steam));
		Format(textfmt, sizeof(textfmt), "Game SteamID: %s", steam);
		AddMenuItem(imenu, "2", textfmt, ITEMDRAW_CONTROL);

		GetClientAuthId(target, AuthId_Steam2, steam, sizeof(steam));
		Format(textfmt, sizeof(textfmt), "Steam2ID: %s", steam);
		AddMenuItem(imenu, "3", textfmt);

		GetClientAuthId(target, AuthId_Steam3, steam, sizeof(steam));
		Format(textfmt, sizeof(textfmt), "Steam3ID: %s", steam);
		AddMenuItem(imenu, "4", textfmt);

		if(CheckCommandAccess(client, "sm_rcon", ADMFLAG_RCON))
		{
			GetClientIP(target, steam, sizeof(steam), true);
			Format(textfmt, sizeof(textfmt), "IP: %s", steam);
			AddMenuItem(imenu, "5", textfmt);

			decl String:country[50];
			GeoipCountry(steam, country, sizeof(country));
			Format(textfmt, sizeof(textfmt), "Country: %s", country);
			AddMenuItem(imenu, "6", textfmt);

			Format(textfmt, sizeof(textfmt), "Serial: %i", GetClientSerial(client));
			AddMenuItem(imenu, "7", textfmt);
		}

		AddMenuItem(imenu, "All", "Print");

		SetMenuPagination(imenu, 9);
		DisplayMenu(imenu, client, MENU_TIME_FOREVER);
	}

	return Plugin_Handled;
}

public infoMenu(Handle:imenu, MenuAction:ma, client, param2) 
{
	decl String:info[64], String:display[64];
	GetMenuItem(imenu, param2, info, sizeof(info), _, display, sizeof(display));
	if(ma == MenuAction_Select)
	{
		if(StrEqual(info, "All", false))
		{
			for(new i = 0; i <= GetMenuItemCount(imenu); i++)
			{
				GetMenuItem(imenu, i, info, sizeof(info), _, display, sizeof(display));
				if(StrEqual(display, "Print", false)) continue;
				ReplyToCommand(client, "[Utility Kit] %s", display);
			}
		}
		else ReplyToCommand(client, "%s", display);
	}
}
