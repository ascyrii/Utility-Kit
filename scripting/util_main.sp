#include <sourcemod>

enum Modules
{
	bool:Players,
	bool:Entities
};
new g_Modules[Modules]

public Plugin:myinfo =
{
	name = "Utility Kit",
	author = "Ascyrii",
	description = "A large set of commands and useful stuffs.",
	version = "0.65",
	url = "http://www.coldcommunity.com"
};

public OnPluginStart()
{
	RegAdminCmd("utility_modules", command_listModules, ADMFLAG_RCON, "List all actively loaded modules");
	scanModules();
}

public Action:command_listModules(client, args)
{
	if(g_Modules[Players] == true)
	{
		ReplyToCommand(client, "[Utility Kit] Players is loaded and running.");
	}
	else ReplyToCommand(client, "[Utility Kit] Players is not running.");

	if(g_Modules[Entities])
	{
		ReplyToCommand(client, "[Utility Kit] Entities is loaded and running.");
	}
	else ReplyToCommand(client, "[Utility Kit] Entities is not running.");
	return Plugin_Handled;
}

public OnAllPluginsLoaded()
{
	scanModules();
}

public scanModules()
{
	(GetCommandFlags("sm_info") != INVALID_FCVAR_FLAGS) ? (g_Modules[Players] = true) : (g_Modules[Players] = false);
	(GetCommandFlags("sm_entinfo") != INVALID_FCVAR_FLAGS) ? (g_Modules[Entities] = true) : (g_Modules[Entities] = false);
}
