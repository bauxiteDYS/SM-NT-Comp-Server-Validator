#include <sourcemod>

public Plugin myinfo = {
	name = "Comp Server Validator",
	description = "Validates the server plugins",
	author = "bauxite",
	version = "0.1.7",
	url = "https://github.com/bauxiteDYS/SM-NT-Comp-Server-Validator",
};

static char g_compPlugins[][] = {
	"Comp Server Validator:0.1.7",
	"No Block:1.0.0.0",
	"Automatic hud_reloadscheme:1.3.1",
	"NT Anti Ghosthop:2.0.5",
	"NT Team join chat commands:2.0",
	"NT Chat Prefixed:1.0.0",
	"NT Competitive Clantag Updater:0.6.1",
	"NT Enforce Comp Values:0.2.0",
	"NT Comp Warmup God Mode:0.1.2",
	"NT Dead Chat Comp:0.1.1",
	"NT Competitive Fade Fix:0.5.7",
	"NT Ghost Distribution:0.1.0",
	"NT Killer Info Display, streamlined for NT and with chat relay:0.1.9",
	"NT Loadout Rescue:0.4.2",
	"NT Physics Unstuck:0.6.4",
	"Neotokyo Competitive Plugin:3.0.1",
	"Neotokyo FoV Changer:0.2.0",
	"Neotokyo SRS Quickswitch Limiter:1.2",
	"NEOTOKYO OnRoundConcluded Event:0.1.0",
	"NEOTOKYO° Anti Ghost Cap Deny:1.3.1",
	"NEOTOKYO° Assist:1.0.1",
	"NEOTOKYO° Damage counter:0.7.5",
	"NEOTOKYO° Double cap prevention:2.0.3",
	"NEOTOKYO° Weapon Drop Tweaks:0.8.4",
	"NEOTOKYO° Ghost capture event:1.10.1",
	"NEOTOKYO° Input tweaks:0.2.1",
	"NEOTOKYO° Restart Fix:1.0.01",
	"NEOTOKYO° Temporary score saver:0.5.3",
	"NEOTOKYO° Vision modes for spectators:0.12",
	"NEOTOKYO° Tachi fix:0.2.1",
	"NEOTOKYO° Teamkill Penalty Fix:1.0.1",
	"NEOTOKYO° Unlimited squad size:1.3",
};

public void OnPluginStart()
{
	RegAdminCmd("sm_validate", Cmd_Validate, ADMFLAG_GENERIC);
}

public Action Cmd_Validate(int client, int args)
{
	ValidateServer(client);
	
	return Plugin_Handled;
}

void ValidateServer(int client)
{
	int pluginMatch;
	int totalPlugins;
	
	char pluginName[128];
	char pluginVersion[64];
	
	char pluginCompare[256];
	char lastPlugin[256];
	
	Handle PluginIter = GetPluginIterator();
	
	PrintToConsole(client, "--------- Plugins On Server ---------");
	
	while (MorePlugins(PluginIter))
	{
		Handle CurrentPlugin = ReadPlugin(PluginIter);
		
		bool matched;
		
		if(!GetPluginInfo(CurrentPlugin, PlInfo_Name, pluginName, sizeof(pluginName)))
		{
			++totalPlugins;
			PrintToServer("Plugin didn't have a name, adding it to the total plugins count");
		}
		
		GetPluginInfo(CurrentPlugin, PlInfo_Version, pluginVersion, sizeof(pluginVersion));
		
		Format(pluginCompare, sizeof(pluginCompare), "%s:%s", pluginName, pluginVersion);
		
		if(!StrEqual(lastPlugin, pluginCompare, true))
		{
			PrintToConsole(client, "%s", pluginCompare);

			strcopy(lastPlugin, sizeof(pluginCompare), pluginCompare);
			
			++totalPlugins;
			
			for(int i = 0; i < sizeof(g_compPlugins); i++)
			{
				if(StrEqual(g_compPlugins[i], pluginCompare, true))
				{
					pluginMatch += 1;
					matched = true;
				}
			}
			
			if(!matched)
			{
				PrintToServer("Plugin didn't match or isn't on the comp list: %s", pluginCompare);
			}
		}
	}
	
	PrintToConsole(client, "--------- Validation Result ---------");
	
	PrintToConsole(client, "Matched %d plugins out of %d required", pluginMatch, sizeof(g_compPlugins));
	PrintToConsole(client, "Total plugins on server: %d", totalPlugins);
	
	if(pluginMatch == totalPlugins)
	{
		char msg[] = "Server validated : it has only approved plugins with the correct version"
		
		PrintToConsoleAll(msg);
		PrintToChatAll(msg);
		PrintToServer(msg);
	}
	else if(pluginMatch == sizeof(g_compPlugins))
	{
		char msg[] = "Server validated : It has all required comp plugins with the correct version, but also additional unknown plugins"
		
		PrintToConsoleAll(msg);
		PrintToChatAll(msg);
		PrintToServer(msg);
	}
	else
	{
		char msg[] = "Server is NOT suitable for comp as required plugins are missing, or not the correct versions"
		
		PrintToConsoleAll(msg);
		PrintToChatAll(msg);
		PrintToServer(msg);
	}
	
	PrintToConsole(client, "-------------------------------------");
	
	delete PluginIter;
}
