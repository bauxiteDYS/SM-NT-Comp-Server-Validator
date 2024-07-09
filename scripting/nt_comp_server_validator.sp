#include <sourcemod>

public Plugin myinfo = {
	name = "Comp Server Validator",
	description = "Validates (basic) or lists the server plugins, use sm_validate or sm_listplugins",
	author = "bauxite",
	version = "0.3.4",
	url = "https://github.com/bauxiteDYS/SM-NT-Comp-Server-Validator",
};

#define NUMBER_OF_COMP_PLUGINS 32

static char g_competition[] = "Generic 5v5 competitive server, Date: 2024-07-09";

bool g_matchedPluginsList[NUMBER_OF_COMP_PLUGINS];
bool g_validateCooldown;
bool g_listPlugins;

static char g_compPlugins[][] = {
	"Comp Server Validator:0.3.4",
	"No Block:1.0.0.0",
	"Automatic hud_reloadscheme:1.3.1",
	"NT Ghost Distribution:0.1.0",
	"NT Anti Ghosthop:3.0.0",
	"NT Team join chat commands:2.0",
	"NT Chat Prefixed:1.0.0",
	"NT Competitive Clantag Updater:0.6.1",
	"NT Enforce Comp Values:0.2.0",
	"NT Comp Warmup God Mode:0.1.1",
	"NT Dead Chat Comp:0.1.1",
	"NT Competitive Fade Fix:0.5.8",
	"NT Killer Info Display, streamlined for NT and with chat relay:0.1.9",
	"NT Loadout Rescue:0.4.2",
	"NT Physics Unstuck:0.6.4",
	"Neotokyo Competitive Plugin:3.0.2",
	"Neotokyo FoV Changer:0.2.0",
	"Neotokyo SRS Quickswitch Limiter:1.2",
	"NEOTOKYO OnRoundConcluded Event:0.1.0",
	"NEOTOKYO° Double cap prevention:2.0.3",
	"NEOTOKYO° Anti Ghost Cap Deny:1.3.1",
	"NEOTOKYO° Assist:1.0.1",
	"NEOTOKYO° Damage counter:0.7.6",
	"NEOTOKYO° Weapon Drop Tweaks:0.8.4",
	"NEOTOKYO° Ghost capture event:1.10.1",
	"NEOTOKYO° Input tweaks:0.2.1",
	"NEOTOKYO° Temporary score saver:0.5.3",
	"NEOTOKYO° Vision modes for spectators:0.12",
	"NEOTOKYO° Tachi fix:0.2.1",
	"NEOTOKYO° Teamkill Penalty Fix:1.0.1",
	"NEOTOKYO° Unlimited squad size:1.3",
};

static char g_defaultPlugins[][] = {
	"Admin File Reader",
	"Admin Help",
	"Admin Menu",
	"Anti-Flood",
	"Basic Ban Commands",
	"Basic Chat",
	"Basic Comm Control",
	"Basic Commands",
	"Basic Info Triggers",
	"Basic Votes",
	"Client Preferences",
	"Fun Commands",
	"Fun Votes",
	"MapChooser",
	"Nextmap",
	"Map Nominations",
	"Player Commands",
	"Reserved Slots",
	"Rock The Vote",
	"Sound Commands",
	"RandomCycle",
	"SQL Admin Manager",
	"SQL Admins (Prefetch)",
	"SQL Admins (Threaded)",
};

public void OnPluginStart()
{
	RegAdminCmd("sm_validate", Cmd_Validate, ADMFLAG_GENERIC);
	RegAdminCmd("sm_listplugins", Cmd_ListPlugins, ADMFLAG_GENERIC);
}

public Action Cmd_ListPlugins(int client, int args)
{
	if (g_validateCooldown)
	{
		ReplyToCommand(client, "List Plugins is on cooldown, wait 7s");
		return Plugin_Stop;
	}
	
	g_listPlugins = true;
	ValidateServer(client);
	g_validateCooldown = true;
	CreateTimer(7.0, ResetValidateCooldown, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}

public Action Cmd_Validate(int client, int args)
{
	if (g_validateCooldown)
	{
		ReplyToCommand(client, "Validate is on cooldown, wait 7s");
		return Plugin_Stop;
	}
	
	ValidateServer(client);
	g_validateCooldown = true;
	CreateTimer(7.0, ResetValidateCooldown, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}

public Action ResetValidateCooldown(Handle timer)
{
	g_validateCooldown = false;
	return Plugin_Stop;
}

void ValidateServer(int client)
{
	if(SOURCEMOD_V_MAJOR != 1 || SOURCEMOD_V_MINOR  < 11)
	{
		char msg[] = "Sourcemod version less than 1.11 is not supported for comp";
		ReplyToCommand(client, msg);
		return;
	}
	
	bool missingPlugins;
	
	int pluginMatch;
	int totalPlugins;
	
	char pluginName[128];
	char pluginVersion[64];
	char lastPluginName[128];
	char pluginCompare[256];
	char msg[128];
	
	Handle PluginIter = GetPluginIterator();
	
	if(!g_listPlugins)
	{
		PrintToConsole(client, "<---- Plugins that aren't default or in comp list ---->");
		PrintToConsole(client, " ");
	}
	else
	{
		PrintToConsole(client, "<--------------- Plugins on the server --------------->");
		PrintToConsole(client, " ");
	}
	
	//
	while (MorePlugins(PluginIter))
	{
		Handle CurrentPlugin = ReadPlugin(PluginIter);
		
		bool defaultPlugin;
		bool unNamed;
		bool matched;
		
		if(!(GetPluginInfo(CurrentPlugin, PlInfo_Name, pluginName, sizeof(pluginName))))
		{
			GetPluginFilename(CurrentPlugin, pluginName, sizeof(pluginName));
			unNamed = true;
		}
		
		if(StrEqual(lastPluginName, pluginName, true))
		{
			//PrintToServer("duplicate plugin, skipping: %s", pluginName);
			continue;
		}
		
		strcopy(lastPluginName, sizeof(pluginName), pluginName);
		
		if(g_listPlugins)
		{
			PrintToConsole(client, "%s", pluginName);
			++totalPlugins;
			continue;
		}
		
		if(unNamed)
		{
			++totalPlugins;
			PrintToConsole(client, "Unnamed plugin: %s", pluginName);
			continue;
		}
		
		for(int i = 0; i < sizeof(g_defaultPlugins); i++)
		{
			if(StrEqual(g_defaultPlugins[i], pluginName, true))
			{
				defaultPlugin = true;
			}
		}
			
		if(defaultPlugin)
		{
			//PrintToServer("default plugin, ignoring: %s", pluginName);
			continue;
		}
		
		++totalPlugins;
		
		GetPluginInfo(CurrentPlugin, PlInfo_Version, pluginVersion, sizeof(pluginVersion));
		
		Format(pluginCompare, sizeof(pluginCompare), "%s:%s", pluginName, pluginVersion);
		
		for(int i = 0; i < sizeof(g_compPlugins); i++)
		{
			if(StrEqual(g_compPlugins[i], pluginCompare, true))
			{
				++pluginMatch;
				g_matchedPluginsList[i] = true;
				matched = true;
			}
		}
		
		if(!matched)
		{
			PrintToConsole(client, "%s", pluginCompare);
		}
	
	}
	//
	
	if(g_listPlugins)
	{
		PrintToConsole(client, "Total Plugins: %d", totalPlugins);
		PrintToConsole(client, " ");
		PrintToConsole(client, "<----------------------------------------------------->");
		
		g_listPlugins = false;
		delete PluginIter;
		return;
	}
		
	PrintToConsole(client, " ");
	PrintToConsole(client, "<----------------- Validation Result ----------------->");
	PrintToConsole(client, " ");
	PrintToConsole(client, g_competition);
	PrintToConsole(client, "Matched %d plugins out of %d required", pluginMatch, sizeof(g_compPlugins));
	PrintToConsole(client, "Total (non-default) plugins on server: %d", totalPlugins);
	
	if(pluginMatch == totalPlugins)
	{
		msg = "Server validated : it has only approved plugins with the correct version";
	}
	else if(pluginMatch == sizeof(g_compPlugins) && totalPlugins >= pluginMatch)
	{
		msg = "Server validated : It has all required comp plugins with the correct versions, but also additional unknown plugins";
	}
	else if(pluginMatch < sizeof(g_compPlugins))
	{
		msg = "Server is NOT suitable for comp as required plugins are missing, or not the correct versions";
		missingPlugins = true;
	}
	else
	{
		msg = "Something went wrong?";
	}
	
	PrintToConsoleAll(msg);
	PrintToChatAll(msg);
	PrintToServer(msg);
	
	if(!missingPlugins)
	{
		PrintToConsole(client, "There are no missing plugins!");
		PrintToConsole(client, " ");
		PrintToConsole(client, "<----------------------------------------------------->");
	}
	else
	{
		PrintToConsole(client, " ");
		PrintToConsole(client, "<------- Required plugins that are not present ------->");
		PrintToConsole(client, " ");
		
		for(int i = 0; i < sizeof(g_compPlugins); i++)
		{
			if(!g_matchedPluginsList[i])
			{
				PrintToConsole(client, "%s", g_compPlugins[i]);
			}
		
			g_matchedPluginsList[i] = false;
		}
		PrintToConsole(client, " ");
		PrintToConsole(client, "<----------------------------------------------------->");
	}
	
	delete PluginIter;
}
