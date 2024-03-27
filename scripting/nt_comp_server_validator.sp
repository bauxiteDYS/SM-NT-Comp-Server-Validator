#include <sourcemod>

public Plugin myinfo = {
	name = "NT Comp Server Validator",
	description = "Validates the server plugins and settings",
	author = "bauxite",
	version = "0.1.1",
	url = "",
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
	char Plugin_Name[128];
	char Plugin_Version[64];
	
	char Plugin_Compare[256];
	char Last_Plugin[256];
	
	Handle PluginIter = GetPluginIterator();
	
	while (MorePlugins(PluginIter))
	{
		Handle CurrentPlugin = ReadPlugin(PluginIter);
		
		GetPluginInfo(CurrentPlugin, PlInfo_Name, Plugin_Name, sizeof(Plugin_Name));
		GetPluginInfo(CurrentPlugin, PlInfo_Version, Plugin_Version, sizeof(Plugin_Version));
		
		Format(Plugin_Compare, sizeof(Plugin_Compare), "Name:%s Version:%s", Plugin_Name, Plugin_Version);
		
		if(!StrEqual(Last_Plugin, Plugin_Compare, true))
		{
			PrintToConsole(client, "%s", Plugin_Compare);
			PrintToServer("%s", Plugin_Compare);
			strcopy(Last_Plugin, sizeof(Plugin_Compare), Plugin_Compare);
		}
	}
	
	delete PluginIter;
}
