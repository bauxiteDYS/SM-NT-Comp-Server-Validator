#include <sourcemod>
#include <regex>
#include <md5stocks>

#pragma semicolon 1
#pragma newdecls required

#define PRNT_SRVR (1<<0)
#define PRNT_CNSL (1<<1)
#define PRNT_CHT (1<<2)
#define PRNT_ALL 7

char md5Hash[64];

bool g_validateCooldown;
bool g_validationResult;
bool g_validatedOnce;

static char g_competition[] = "Tournament: WW25 (v12)";

// need more files? Check for maps using built-in sm functions?
static char g_requiredFiles[][][] = {
	{"/addons/sourcemod/gamedata/neotokyo/chatprefix.txt","5e9f2b8d86dec81d059000687e287eae"},
	{"/addons/sourcemod/gamedata/neotokyo/loadout_rescue.txt","e47cd9d93c91824c637ba93b7eb2901f"},
	{"/addons/sourcemod/gamedata/neotokyo/physics_unstuck.txt","bc24f7a2060ca7e295311c7c3e91aef3"},
	{"/addons/sourcemod/gamedata/neotokyo/wincond.txt","fc5e4314de2e315b38635c33674e26b0"},
	{"/addons/sourcemod/configs/veto_maplist.ini","779e33a3daa68e2fee48c3373f6abd6d"},
	{"/addons/sourcemod/configs/clantags.cfg","57bbb5b295255185dac625fc7458e979"},
	{"/addons/sourcemod/configs/nt-capmover/nt_saitama_redux_ctg_a5.capzones.txt","073a4f8f70554689f24bcc6e1553cbde"},
};

// Plugins we need for ww25
static char g_compPlugins[][][] = {
	{"NT Comp Server Validator:WW25-v12","7e16f386c8788ba8a6d91970c28e568c"},
	{"Websocket:1.2","b26ee7a4531bbb3381852de4b956f2ec"},
	{"NT NoBlock:0.1.1","590b56240d1de0f1f3d0eab1b6623844"},
	{"NT Stuck Rescue:0.1.0","f3a95808b9f6ad6b421ac4fb1a9bf4b7"},
	{"NT Win Condition:0.0.10","56e945d0a73b48ac022e3033d2b5c62e"},
	{"NT Anti Ghosthop:4.2.1","ddefe6532d33f30be162a50734ccfe69"},
	{"NT Enforce Comp Values:0.2.0","709b8c5388d6d40d362e1bb375e0dc87"},
	{"NT Dead Chat Comp:0.1.1","6a82a82e4e93fd79689f004425655abf"},
	{"NT Competitive Fade Fix:0.5.8","d773588cf07c18905c9f1c7037460e5a"},
	{"NT Killer Info:0.3.0","164826c3a7426b40aab4bd58060524aa"},
	{"NT Loadout Rescue:0.4.2","2000fc22023ca78cdb9f974b129c7bd6"},
	{"NT Physics Unstuck:0.6.4","1332826817ba1e5c2f24a1261eaba033"},
	{"NT Water Nades:0.1.1","a21a386053e86a740f07d2029769375c"},
	{"NT Comp Warmup God Mode:0.1.1","15ccac4f75816e57ac56ee18b38a60bc"},
	{"NT Cap Mover:0.0.3","8b089a18647096700a32db72dfefcf56"},
	{"NT weapon drop fixes:0.3.0","71b6a998fb9b67b935ed8a02e5471459"},
	{"Neotokyo Competitive Plugin:3.0.2","f56957237372753342eb5a035ace4cdd"},
	{"Neotokyo FoV Changer:0.2.0","8b5f62a1c4a6ba31ccc8e6c8ac34345b"},
	{"Neotokyo SRS Quickswitch Limiter:1.2","566411eca8c8526190c0b65c80a02f25"},
	{"NEOTOKYO° Ghost spawn bias:0.2.3","bd9c5a020e9f164ccefdbc330b4a2c41"},
	{"NEOTOKYO° Anti Ghost Cap Deny:1.3.1","5d7553aca30836705df441794ca8aff5"},
	{"NEOTOKYO° Assist:1.0.1","bb07e35ccce0c1c29d7824f1b15ea203"},
	{"NEOTOKYO° Damage counter:0.7.6","907cc502a5561485bc23370ae96d03e5"},
	{"NEOTOKYO° Weapon Drop Tweaks:0.8.4","0a5f824ab41ccee5ab23ee4b2b3f413a"},
	{"NEOTOKYO° Ghost capture event:1.10.1","68bbd9de7fa3c5cae227cb560d7caa61"},
	{"NEOTOKYO° Temporary score saver:0.5.3","3b7ec801e09cbde1ffaf0e438d2cf275"},
	{"NEOTOKYO° Tachi fix:0.2.1","fd0966f6208a3b6801331cbcd430cc94"},
	{"NEOTOKYO° Teamkill Penalty Fix:1.0.1","86a03a21915d67c35f406c03368e92bb"},
	{"NEOTOKYO° Unlimited squad size:1.3","0095169f5969d367d583e7f91cf81fc0"},
	{"NEOTOKYO° Input tweaks:0.2.1","43072a5cd6b76383f9e980ebe8dba12b"},
	{"Neotokyo WebSocket:1.6.2","f0a7590c1d8981cae65f6e051d8421aa"},
	{"NT Competitive Vetos:1.3.1","fc1032006f22a773abb92f2d256502ee"},
	{"NT Competitive Clantag Updater:1.0.0","ec9d5255f71c5a47e8b9de3ffa31bdc4"},
	{"NT Observer PVS Bypass:0.1.0","38b909db2bf2bac46429c87676f36999"},
	{"NT Spectator Quick Target:1.0.1","eba2b55a2a1d0f2211f3ff9d8d067267"},
	{"NEOTOKYO° Vision modes for spectators:0.12","c57bfb66ada12c24ff0054ce65d42f29"},
	{"NT Team join chat commands:2.0.1","9b5feb2f6a119727f49a72e57b33d7d7"},
	{"NT Chat Prefixed:1.0.0","43b80623734b524aaf29430809b07899"},
	{"Automatic hud_reloadscheme:1.3.1","25ceea63a24a9917d8d93afda82d73fd"},
	{"NT admin score adjuster:0.1.0","147a02d12841e0dace9a3a5743eb9ee2"},
	{"NT Comp XP Printer:0.1.0","77e228a1ee0172cf44e331214ae825f1"},
};

//plugins we require without any particular version (Default SM plugins etc)
static char g_defaultPlugins[][] = {
	"Client Preferences",
	"NT MapChooser",
	"Nextmap",
	"Map Nominations",
	"Rock The Vote",
};

// need more cvars?
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
	{"sv_maxupdaterate", "66"},
	{"sv_maxcmdrate", "66"},
	{"sv_maxrate", "576000"},
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
	{"sm_nt_capmover_enable", "1"},
	{"mp_timelimit", "0"},
	{"sv_alltalk", "0"},
	{"tv_enable", "1"},
	{"tv_maxclients", "0"},
	{"tv_transmitall", "1"},
};

//plugins we dont really care if they are on the server or not
static char g_otherPlugins[][] = {
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
	"Fun Commands",
	"Fun Votes",
	"Player Commands",
	"Reserved Slots",
	"Sound Commands",
	"RandomCycle",
	"SQL Admin Manager",
	"SQL Admins (Prefetch)",
	"SQL Admins (Threaded)",
	"Simple Adverts",
	"Advertisements",
	"Flip a Coin",
	"Flip a Coin / mini-game",
	"Empty Server map reloader",
	"Server restart and Map reloader",
	"NT Force to Spectator",
	"Force to Spectator",
	"NEOTOKYO OnRoundConcluded Event",
};

public Plugin myinfo = {
	name = "NT Comp Server Validator",
	description = "Validates (basic) or lists the server plugins, use sm_validate or sm_listplugins",
	author = "bauxite",
	version = "WW25-v12",
	url = "https://github.com/bauxiteDYS/SM-NT-Comp-Server-Validator",
};

public void OnPluginStart()
{
	RegAdminCmd("sm_validate", Cmd_Validate, ADMFLAG_GENERIC);
	RegAdminCmd("sm_listplugins", Cmd_ListPlugins, ADMFLAG_GENERIC);
	AddCommandListener(OnReady, "sm_ready");
}

public Action OnReady(int client, const char[] command, int argc)
{
	if(g_validatedOnce)
	{
		if(!g_validationResult)
		{
			PrintToChat(client, "[Server Validator] Warning! This server is NOT validated for %s, details should be in console somewhere", g_competition);
		}
			
		return Plugin_Continue;
	}
	
	ValidateServer();
	PrintToChat(client, "[Server Validator] Check console for validation result (visible to all)");
	return Plugin_Continue;
}

public void OnMapStart()
{
	g_validateCooldown = false;
	g_validationResult = false;
	g_validatedOnce = false;
}

public Action Cmd_ListPlugins(int client, int args)
{
	if (g_validateCooldown)
	{
		ReplyToCommand(client, "[Server Validator] List Plugins is on cooldown, wait 5s");
		return Plugin_Stop;
	}
	
	ValidateServer(true);
	g_validateCooldown = true;
	CreateTimer(5.0, ResetValidateCooldown, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}

public Action Cmd_Validate(int client, int args)
{
	if (g_validateCooldown)
	{
		ReplyToCommand(client, "[Server Validator] Validate is on cooldown, wait 5s");
		return Plugin_Stop;
	}
	
	ValidateServer();
	g_validateCooldown = true;
	CreateTimer(5.0, ResetValidateCooldown, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}

public Action ResetValidateCooldown(Handle timer)
{
	g_validateCooldown = false;
	return Plugin_Stop;
}

void ValidateServer(bool listPlugins = false)
{
	int sm_major;
	int sm_minor;
	int sm_patch;
	
	GetSmVersion(sm_major, sm_minor, sm_patch);
	
	if(sm_major != 1 || sm_minor < 11)
	{
		char msg[] = "[Server Validator] Sourcemod version less than 1.11 is not supported for comp";
		PrintMsg(msg, PRNT_CHT | PRNT_CNSL);
		return;
	}
	
	char pathBuff[PLATFORM_MAX_PATH];
	char fileBuff[128];
	char baseFolder[] = "/addons/sourcemod/plugins/";
	char allServerPlugins[128][128];
	char msg[128];
	int dupes;
	int pluginMatch;
	int totalPlugins;
	int unique;
	bool matchedDefaultList[128];
	bool matchedCompList[128];
	bool missingPlugins;
	
	if(!listPlugins)
	{
		PrintMsg("<---- Plugins that aren't default or in comp list ---->", PRNT_CNSL | PRNT_SRVR);
		PrintMsg(" ", PRNT_CNSL | PRNT_SRVR);
	}
	else
	{
		PrintMsg("<--------------- Plugins on the server --------------->", PRNT_CNSL | PRNT_SRVR);
		PrintMsg(" ", PRNT_CNSL | PRNT_SRVR);
	}
	
	for(int pluginNum = 1; pluginNum <= 128; pluginNum++)
	{
		Handle CurrentPlugin = FindPluginByNumber(pluginNum);
		
		if(!IsValidHandle(CurrentPlugin) || CurrentPlugin == INVALID_HANDLE)
		{
			continue;
		}
		
		char pluginName[128];
		char pluginVersion[64];
		char pluginCompare[192];
	
		bool otherPlugin;
		bool unNamed;
		bool matched;
		bool dupe;
		
		if(!(GetPluginInfo(CurrentPlugin, PlInfo_Name, pluginName, sizeof(pluginName))))
		{
			GetPluginFilename(CurrentPlugin, pluginName, sizeof(pluginName));
			unNamed = true;
		}
		
		for(int i = 0; i < sizeof(allServerPlugins); i++)
		{
			if(StrEqual(allServerPlugins[i], pluginName, true))
			{
				++totalPlugins;
				dupes++;
				dupe = true;
			}
		}
		
		if(dupe)
		{
			PrintMsg("Dupe plugin: %s", PRNT_CNSL | PRNT_SRVR, pluginName);
			continue;
		}
		
		++unique;
		
		strcopy(allServerPlugins[unique - 1], sizeof(pluginName), pluginName);
		
		if(unNamed)
		{
			++totalPlugins;
			PrintMsg("Unnamed plugin: %s", PRNT_CNSL | PRNT_SRVR, pluginName);
			continue;
		}
		
		if(!listPlugins)
		{
			for(int i = 0; i < sizeof(g_otherPlugins); i++)
			{
				if(StrEqual(g_otherPlugins[i], pluginName, true))
				{
					otherPlugin = true;
				}
			}
			
			if(otherPlugin)
			{
				continue;
			}
		}
		
		++totalPlugins;
		
		GetPluginInfo(CurrentPlugin, PlInfo_Version, pluginVersion, sizeof(pluginVersion));
		
		Format(pluginCompare, sizeof(pluginCompare), "%s:%s", pluginName, pluginVersion);
		
		if(!listPlugins)
		{
			for(int i = 0; i < sizeof(g_defaultPlugins); i++)
			{
				if(StrEqual(g_defaultPlugins[i], pluginName, true))
				{
					matchedDefaultList[i] = true;
					matched = true;
					++pluginMatch;
				}
			}
			
			for(int i = 0; i < sizeof(g_compPlugins); i++)
			{
				if(StrEqual(g_compPlugins[i][0], pluginCompare, true))
				{
					GetPluginFilename(CurrentPlugin, fileBuff, sizeof(fileBuff));
					Format(pathBuff, sizeof(pathBuff), "%s%s", baseFolder, fileBuff);
					
					MD5_File(pathBuff, md5Hash, sizeof(md5Hash));
					//PrintToServer("%s", md5Hash);
					
					if(StrEqual(md5Hash, g_compPlugins[i][1], false))
					{
						matchedCompList[i] = true;
						matched = true;
						++pluginMatch;
					}
				}
			}
		
			if(!matched)
			{
				PrintMsg("%s", PRNT_CNSL | PRNT_SRVR, pluginCompare);
			}
		}
		
		if(listPlugins)
		{
			PrintMsg("%s", PRNT_CNSL | PRNT_SRVR, pluginCompare);
		}
	}
	
	if(listPlugins)
	{
		PrintMsg(" ", PRNT_CNSL | PRNT_SRVR);
		PrintMsg("Total Plugins: %d", PRNT_CNSL | PRNT_SRVR, totalPlugins);
		if(dupes > 0)
		{
			PrintMsg("Total Duplicates: %d !!!", PRNT_CNSL | PRNT_SRVR, dupes);
		}
		PrintMsg(" ", PRNT_CNSL | PRNT_SRVR);
		PrintMsg("<----------------------------------------------------->", PRNT_CNSL | PRNT_SRVR);
		
		listPlugins = false;
		return;
	}
		
	PrintMsg(" ", PRNT_CNSL | PRNT_SRVR);
	PrintMsg("<------------------ Plugins Result ------------------->", PRNT_CNSL | PRNT_SRVR);
	PrintMsg(" ", PRNT_CNSL | PRNT_SRVR);
	PrintMsg(g_competition, PRNT_CNSL | PRNT_SRVR);
	PrintMsg("Matched %d plugins out of %d required", PRNT_CNSL | PRNT_SRVR, pluginMatch, sizeof(g_compPlugins) + sizeof(g_defaultPlugins));
	PrintMsg("Total (non-default) plugins on server: %d", PRNT_CNSL | PRNT_SRVR, totalPlugins);
	if(dupes > 0)
	{
		PrintMsg("Total Duplicates: %d !!!", PRNT_CNSL | PRNT_SRVR, dupes);
	}
	PrintMsg(" ", PRNT_CNSL | PRNT_SRVR);
	PrintMsg("<------------------------CVARS------------------------>", PRNT_CNSL | PRNT_SRVR);
	PrintMsg(" ", PRNT_CNSL | PRNT_SRVR);
	
	bool cvarsMatched = ValidateServerCvars();
	
	PrintMsg(" ", PRNT_CNSL | PRNT_SRVR);
	
	
	PrintMsg("<------------------------Files------------------------>", PRNT_CNSL | PRNT_SRVR);
	PrintMsg(" ", PRNT_CNSL | PRNT_SRVR);
	
	bool allFilesExist = DoFilesExist();
	
	PrintMsg(" ", PRNT_CNSL | PRNT_SRVR);
	PrintMsg("<----------------- Validation Result ----------------->", PRNT_CNSL | PRNT_SRVR);
	PrintMsg(" ", PRNT_CNSL | PRNT_SRVR);
	
	if(pluginMatch == (sizeof(g_compPlugins) + sizeof(g_defaultPlugins)))
	{
		missingPlugins = false;
	}
	else
	{
		missingPlugins = true;
	}
	
	if(!allFilesExist)
	{
		g_validationResult = false;
		strcopy(msg, sizeof(msg), "[Server Validator] Server is NOT suitable for this comp, files are missing");
	}
	else if(dupes > 0)
	{
		g_validationResult = false;
		strcopy(msg, sizeof(msg), "[Server Validator] Server is NOT suitable for this comp, it has duplicate plugins, remove them and try again");
	}
	else if(totalPlugins == pluginMatch && !missingPlugins && cvarsMatched)
	{
		g_validationResult = true;
		strcopy(msg, sizeof(msg), "[Server Validator] Server validated : it has only approved plugins with the correct version and correct settings");
	}
	else if(totalPlugins == pluginMatch && !missingPlugins && !cvarsMatched)
	{
		g_validationResult = false;
		strcopy(msg, sizeof(msg), "[Server Validator] Need admin approval : it has only approved plugins with the correct version, settings need admin approval");
	}
	else if(!missingPlugins && totalPlugins >= pluginMatch)
	{
		g_validationResult = false;
		strcopy(msg, sizeof(msg), "[Server Validator] Need admin approval : It has all required comp plugins, but also additional unknown plugins");
	}
	else if(missingPlugins)
	{
		g_validationResult = false;
		strcopy(msg, sizeof(msg), "[Server Validator] Server is NOT suitable for this comp as required plugins are missing, or not the correct versions");
	}
	else
	{
		g_validationResult = false;
		strcopy(msg, sizeof(msg), "[Server Validator] Something went wrong?");
	}
	
	PrintMsg(msg, PRNT_ALL);
	
	if(!missingPlugins)
	{
		PrintMsg("[Server Validator] There are no missing plugins!", PRNT_CNSL | PRNT_SRVR);
		PrintMsg(" ", PRNT_CNSL | PRNT_SRVR);
		PrintMsg("<----------------------------------------------------->", PRNT_CNSL | PRNT_SRVR);
	}
	else
	{
		PrintMsg(" ", PRNT_CNSL | PRNT_SRVR);
		PrintMsg("<------- Required plugins that are not present ------->", PRNT_CNSL | PRNT_SRVR);
		PrintMsg(" ", PRNT_CNSL | PRNT_SRVR);
		
		for(int i = 0; i < sizeof(g_defaultPlugins); i++)
		{
			if(!matchedDefaultList[i])
			{
				PrintMsg("%s", PRNT_CNSL | PRNT_SRVR, g_defaultPlugins[i]);
			}
		
			matchedDefaultList[i] = false;
		}
		
		for(int i = 0; i < sizeof(g_compPlugins); i++)
		{
			if(!matchedCompList[i])
			{
				PrintMsg("%s", PRNT_CNSL | PRNT_SRVR, g_compPlugins[i][0]);
			}
		
			matchedCompList[i] = false;
		}
		PrintMsg(" ", PRNT_CNSL | PRNT_SRVR);
		PrintMsg("<----------------------------------------------------->", PRNT_CNSL | PRNT_SRVR);
	}
	
	g_validatedOnce = true;
}

/*
	for(int i = 0; i < sizeof(g_requiredFiles); i++)
	{
		MD5_File(g_requiredFiles[i], md5Hash, sizeof(md5Hash));
		PrintToServer("%s", g_requiredFiles[i]);
		PrintToServer("%s", md5Hash);
		md5Hash[0] = '\0';
	}
*/

bool DoFilesExist()
{
	bool filesMatched = true;
	
	for(int iFile = 0; iFile < sizeof(g_requiredFiles); iFile++)
	{
		if(!FileExists(g_requiredFiles[iFile][0]))
		{
			PrintMsg("%s - Not found", PRNT_CNSL | PRNT_SRVR, g_requiredFiles[iFile][0]);
			filesMatched = false;
		}
		else
		{
			MD5_File(g_requiredFiles[iFile][0], md5Hash, sizeof(md5Hash));
			if(!StrEqual(md5Hash, g_requiredFiles[iFile][1], false))
			{
				filesMatched = false;
				PrintMsg("%s - Wrong hash", PRNT_CNSL | PRNT_SRVR, g_requiredFiles[iFile][0]);
			}
		}
	}
	
	if(filesMatched)
	{
		PrintMsg("All files are present", PRNT_CNSL | PRNT_SRVR);
	}
	
	return filesMatched;
}

bool ValidateServerCvars()
{
	bool cvarsMatched = true;
	
	for(int i = 0; i < sizeof(g_cvarList); i++)
	{
		char buff[64];
		ConVar cvar = FindConVar(g_cvarList[i][0]);
		
		if(!IsValidHandle(cvar))
		{
			cvarsMatched = false;
			PrintMsg("%s - Not found", PRNT_CNSL | PRNT_SRVR, g_cvarList[i][0]);
			continue;
		}
		
		cvar.GetString(buff, sizeof(buff));
		
		if(StringToFloat(buff) != StringToFloat(g_cvarList[i][1]))
		{
			cvarsMatched = false;
			PrintMsg("%s - Incorrect value", PRNT_CNSL | PRNT_SRVR, g_cvarList[i][0]);
			PrintMsg("  Current value: %s - Required value: %s", PRNT_CNSL | PRNT_SRVR, buff, g_cvarList[i][1]);
		}
	}
	
	if(cvarsMatched)
	{
		PrintMsg("All CVARS matched", PRNT_CNSL | PRNT_SRVR);
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

void PrintMsg(const char[] msg, int flags, any ...)
{
	char newMsg[128];
	
	VFormat(newMsg, sizeof(newMsg), msg, 3);
	
	if (flags & PRNT_SRVR)
	{
		PrintToServer(newMsg);
	}

	if (flags & PRNT_CHT)
	{
		PrintToChatAll(newMsg);
	}

	if (flags & PRNT_CNSL)
	{
		PrintToConsoleAll(newMsg);
	}
}
