#include <sourcemod>

public Plugin myinfo = {
	name = "Comp Server Validator",
	description = "Validates the server plugins and settings",
	author = "bauxite",
	version = "0.1.7",
	url = "",
};

static char g_compPlugins[][] = {
	"Admin File Reader:1.11.0.6939",
	"No Block:1.0.0.0",
	"NT Team join chat commands:2.0",
	"NT Force to Spectator:1.0",
	"NEOTOKYO° Damage counter:0.7.5",
	"NEOTOKYO° Ghost capture event:1.10.1",
	"Flip a Coin / mini-game:0.1.3",
	"NEOTOKYO° Temporary score saver:0.5.3",
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
	
	while (MorePlugins(PluginIter))
	{
		Handle CurrentPlugin = ReadPlugin(PluginIter);
		
		if(!GetPluginInfo(CurrentPlugin, PlInfo_Name, pluginName, sizeof(pluginName)))
		{
			++totalPlugins;
			ReplyToCommand(client, "a plugin didn't have a name, adding it to the total plugins count anyway");
		}
		
		GetPluginInfo(CurrentPlugin, PlInfo_Version, pluginVersion, sizeof(pluginVersion));
		
		Format(pluginCompare, sizeof(pluginCompare), "%s:%s", pluginName, pluginVersion);
		
		if(!StrEqual(lastPlugin, pluginCompare, true))
		{
			ReplyToCommand(client, "%s", pluginCompare);

			strcopy(lastPlugin, sizeof(pluginCompare), pluginCompare);
			
			++totalPlugins;
			
			for(int i = 0; i < sizeof(g_compPlugins); i++)
			{
				if(StrEqual(g_compPlugins[i], pluginCompare, true))
				{
					pluginMatch += 1
				}
			}
		}
	}
	
	
	ReplyToCommand(client, "Matched plugins %d out of %d required", pluginMatch, sizeof(g_compPlugins));
	ReplyToCommand(client, "Total plugins on server %d", totalPlugins);
	
	if(pluginMatch == totalPlugins)
	{
		ReplyToCommand(client, "Server Validated and has only approved plugins");
	}
	else if(pluginMatch == sizeof(g_compPlugins))
	{
		ReplyToCommand(client, "Server has all comp plugins and also some extra plugins");
	}
	else
	{
		ReplyToCommand(client, "Server is NOT suitable for comp");
	}
	
	delete PluginIter;
}
