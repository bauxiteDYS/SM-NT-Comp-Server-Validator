#include <regex>
#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name = "Comp Server Validator",
	description = "Validates (basic) or lists the server plugins, use sm_validate or sm_listplugins",
	author = "bauxite",
	version = "5v5-20241205",
	url = "https://github.com/bauxiteDYS/SM-NT-Comp-Server-Validator",
};

bool g_validateCooldown;

static char g_competition[] = "Tournament: Generic 5v5 2024-12-05";

static char g_cvarList[][][] = {
	{"sm_competitive_round_style", "1"},
	{"sm_competitive_round_limit", "15"},
	{"sm_competitive_nozanshi", "0"},
	{"sm_competitive_sudden_death", "1"},
	{"sm_competitive_ghost_overtime", "45"},
	{"sm_competitive_ghost_overtime_grace", "15"},
	{"sm_competitive_ghost_overtime_decay_exp", "0"},
	{"sv_minupdaterate", "66"},
	{"sv_mincmdrate", "66"},
	{"sv_minrate", "192000"},
	{"sv_cheats", "0"},
	{"sv_gravity", "800"},
	{"neo_round_timelimit", "2.26"},
	{"neo_ff_feedback", "0"},
	{"neo_teamkill_punish", "0"},
	{"sm_nt_squadautojoin", "1"},
	{"sm_nt_squadlock", "1"},
	{"sm_nt_fov_max", "90"},
	{"sv_accelerate", "10"},
	{"sv_airaccelerate", "10"},
	{"sv_footsteps", "1"},
	{"sv_friction", "4"},
	{"sv_stepsize", "18"},
	{"sv_backspeed", "0.6"},
	{"sv_unlag", "1"},
	{"sv_client_predict", "1"},
	{"sv_pausable", "0"},
	{"neo_disable_tie", "0"},
	{"neo_score_limit", "99"},
	{"kid_text_relay", "1"},
	{"kid_panel_duration", "9"},
	{"kid_printtopanel", "1"},
	{"sm_ntdrop_nodespawn", "1"},
	{"sm_nt_wincond_tiebreaker", "0"},
	{"sm_nt_wincond_swapattackers", "0"},
	{"sm_nt_wincond_captime", "0"},
	{"sm_nt_wincond_consolation_rounds", "0"},
	{"sm_nt_wincond_survivor_bonus", "1"},
	{"sm_nt_wincond_ghost_reward", "0"},
	{"sm_nt_wincond_ghost_reward_dead", "0"},
	{"sm_nt_ghost_bias_enabled", "1"},
	{"sm_nt_ghost_bias_rounds", "2"},
	{"sm_nt_anti_ghosthop_verbosity", "2"},
	{"sm_nt_anti_ghosthop_speed_scale", "1.0"},
	{"sm_nt_anti_ghosthop_n_extra_hops", "0"},
	{"sm_loadout_rescue_allow_loadout_change", "0"},
	{"sm_nt_assist_enabled", "1"},
	{"sm_nt_assist_damage", "50"},
	{"sm_nt_assist_half", "0"},
	{"sm_nt_assist_notifications", "1"},
	{"sm_ntdamage_assists", "0"},
};

// These plugins should be good for generic 5v5 without class limits in 2024 and the foreseeable future
// Have been tested extensively and appear to have no major bugs, and few features and fixes missing

static char g_compPlugins[][] = {
	"Comp Server Validator:5v5-20241205",
	"Websocket:1.2",
	"NT NoBlock:0.1.1",
	"NT Stuck Rescue:0.1.0",
	"NT Win Condition:0.0.10",
	"NT Anti Ghosthop:3.0.0",
	"NT Enforce Comp Values:0.2.0",
	"NT Dead Chat Comp:0.1.1",
	"NT Competitive Fade Fix:0.5.8",
	"NT Killer Info:0.2.7",
	"NT Loadout Rescue:0.4.2",
	"NT Physics Unstuck:0.6.4",
	"NT Water Nades:0.1.1",
	"NT Comp Warmup God Mode:0.1.1",
	"Neotokyo Competitive Plugin:3.0.2",
	"Neotokyo FoV Changer:0.2.0",
	"Neotokyo SRS Quickswitch Limiter:1.2",
	"NEOTOKYO° Ghost spawn bias:0.2.3",
	"NEOTOKYO° Anti Ghost Cap Deny:1.3.1",
	"NEOTOKYO° Assist:1.0.1",
	"NEOTOKYO° Damage counter:0.7.6",
	"NEOTOKYO° Weapon Drop Tweaks:0.8.4",
	"NEOTOKYO° Ghost capture event:1.10.1",
	"NEOTOKYO° Temporary score saver:0.5.3",
	"NEOTOKYO° Tachi fix:0.2.1",
	"NEOTOKYO° Teamkill Penalty Fix:1.0.1",
	"NEOTOKYO° Unlimited squad size:1.3",
	"NEOTOKYO° Input tweaks:0.2.1",
	"Neotokyo WebSocket:1.6.2",
};

//firstly the sourcemod plugins and then some commonly used plugins

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
	"Simple Adverts",
	"Advertisements",
	"NT Observer PVS Bypass",
	"NT Spectator Quick Target",
	"NEOTOKYO° Player count events",
	"NEOTOKYO° Vision modes for spectators",
	"NT Competitive Vetos",
	"NT Competitive Clantag Updater",
	"Automatic hud_reloadscheme",
	"NT Team join chat commands",
	"NT Chat Prefixed",
	"Flip a Coin",
	"Flip a Coin / mini-game",
	"Empty Server map reloader",
	"NT Force to Spectator",
	"Force to Spectator",
	"NEOTOKYO OnRoundConcluded Event",
	"No Block",
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
	
	ValidateServer(client, true);
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

void ValidateServer(int client, bool listPlugins = false)
{
	int sm_major;
	int sm_minor;
	int sm_patch;
	
	GetSmVersion(sm_major, sm_minor, sm_patch);
	
	if(sm_major != 1 && sm_minor < 11)
	{
		char msg[] = "Sourcemod version less than 1.11 is not supported for comp";
		ReplyToCommand(client, msg);
		return;
	}
	
	char g_serverPlugins[128][128];
	char pluginName[128];
	char pluginVersion[64];
	char pluginCompare[192];
	char msg[128];
	int dupes;
	int pluginMatch;
	int totalPlugins;
	int unique;
	bool g_matchedPluginsList[128];
	bool missingPlugins;
	Handle PluginIter = GetPluginIterator();
	
	if(!listPlugins)
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
		bool dupe;
		
		if(!(GetPluginInfo(CurrentPlugin, PlInfo_Name, pluginName, sizeof(pluginName))))
		{
			GetPluginFilename(CurrentPlugin, pluginName, sizeof(pluginName));
			unNamed = true;
		}
		
		for(int i = 0; i < sizeof(g_serverPlugins); i++)
		{
			if(StrEqual(g_serverPlugins[i], pluginName, true))
			{
				dupes++;
				dupe = true;
			}
		}
		
		if(dupe)
		{
			PrintToConsole(client, "Dupe plugin: %s", pluginName);
			continue;
		}
		
		++unique;
		
		strcopy(g_serverPlugins[unique - 1], sizeof(pluginName), pluginName);
		
		if(unNamed)
		{
			++totalPlugins;
			PrintToConsole(client, "Unnamed plugin: %s", pluginName);
			continue;
		}
		
		if(!listPlugins)
		{
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
		}
		
		++totalPlugins;
		
		pluginVersion[0] = '\0';
		GetPluginInfo(CurrentPlugin, PlInfo_Version, pluginVersion, sizeof(pluginVersion));
		
		Format(pluginCompare, sizeof(pluginCompare), "%s:%s", pluginName, pluginVersion);
		
		if(!listPlugins)
		{
			for(int i = 0; i < sizeof(g_compPlugins); i++)
			{
				if(StrEqual(g_compPlugins[i], pluginCompare, true))
				{
					g_matchedPluginsList[i] = true;
					matched = true;
					++pluginMatch;
				}
			}
		
			if(!matched)
			{
				PrintToConsole(client, "%s", pluginCompare);
			}
		}
		
		if(listPlugins)
		{
			PrintToConsole(client, "%s", pluginCompare);
		}
	}
	//
	
	if(listPlugins)
	{
		PrintToConsole(client, " ");
		PrintToConsole(client, "Total Plugins: %d", totalPlugins);
		if(dupes > 0)
		{
			PrintToConsole(client, "Total Duplicates: %d !!!", dupes);
		}
		PrintToConsole(client, " ");
		PrintToConsole(client, "<----------------------------------------------------->");
		
		listPlugins = false;
		delete PluginIter;
		return;
	}
		
	PrintToConsole(client, " ");
	PrintToConsole(client, "<------------------ Plugins Result ------------------->");
	PrintToConsole(client, " ");
	PrintToConsole(client, g_competition);
	PrintToConsole(client, "Matched %d plugins out of %d required", pluginMatch, sizeof(g_compPlugins));
	PrintToConsole(client, "Total (non-default) plugins on server: %d", totalPlugins);
	if(dupes > 0)
	{
		PrintToConsole(client, "Total Duplicates: %d !!!", dupes);
	}
	PrintToConsole(client, " ");
	PrintToConsole(client, "<------------------------CVARS------------------------>");
	PrintToConsole(client, " ");
	bool cvarsMatched = ValidateServerCvars(client);
	PrintToConsole(client, " ");
	PrintToConsole(client, "<----------------- Validation Result ----------------->");
	PrintToConsole(client, " ");
	
	if(pluginMatch == totalPlugins && cvarsMatched)
	{
		msg = "Server validated : it has only approved plugins with the correct version and correct settings";
	}
	else if(pluginMatch == totalPlugins && !cvarsMatched)
	{
		msg = "Server mostly validated : it has only approved plugins with the correct version, settings need admin approval";
	}
	else if(pluginMatch == sizeof(g_compPlugins) && totalPlugins >= pluginMatch)
	{
		msg = "Validation needs admin approval : It has all required comp plugins, but also additional unknown plugins";
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

bool ValidateServerCvars(int client)
{
	bool cvarsMatched = true;
	
	for(int i = 0; i < sizeof(g_cvarList); i++)
	{
		char buff[64];
		ConVar cvar = FindConVar(g_cvarList[i][0]);
		
		if(!IsValidHandle(cvar))
		{
			cvarsMatched = false;
			PrintToConsole(client, "%s - Not found", g_cvarList[i][0]);
			continue;
		}
		
		cvar.GetString(buff, sizeof(buff));
		
		if(!StrEqual(buff, g_cvarList[i][1], false))
		{
			cvarsMatched = false;
			PrintToConsole(client, "%s - Incorrect value", g_cvarList[i][0]);
			PrintToConsole(client, "- Current value: %s - Required value: %s", buff, g_cvarList[i][1]);
		}
	}
	
	return cvarsMatched;
}

// Passes the SemVer of the running SourceMod installation by reference.
// Returns false on failure, and true on success.
stock bool GetSmVersion(int& out_major, int& out_minor, int& out_patch)
{
	static int major = -1, minor, patch;

	if (major == -1) {
		// https://regexr.com/89i7n
		Regex re = new Regex("\\d{1,2}\\.\\d{1,2}\\.\\d{1,2}");
		if (!re) {
			return false;
		}

		char version[7+1]; // N.NN.NN\0
		FindConVar("sourcemod_version").GetString(version, sizeof(version));
		if (re.Match(version) == -1) {
			delete re;
			return false;
		}

		char versions[3][3];
		if (sizeof(versions) != ExplodeString(version, ".", versions,
			sizeof(versions), sizeof(versions[]))) {
			delete re;
			return false;
		}
		delete re;

		if (!StringToIntEx(versions[0], major)) { return false; }
		if (!StringToIntEx(versions[1], minor)) { return false; }
		if (!StringToIntEx(versions[2], patch)) { return false; }
    }
	out_major = major;
	out_minor = minor;
	out_patch = patch;
	return true;
}
