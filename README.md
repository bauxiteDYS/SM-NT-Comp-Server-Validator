# SM-Comp-Server-Validator
Sourcemod plugin to verify if Neotokyo competitive servers are setup properly.  
Currently checks server plugins against a hardcoded list of required plugins (+versions) and "validates" the server if all required plugins are present.    
It will also check a big list of important console variables (CVARS) to make sure they match what's typically used in competitive play.  

Install the plugin and use `!validate` in chat or `sm_validate` in console and it will print in console all the non-default plugins on the server and any from the required list that were not present. It will also print which CVARS are missing or have incorrect values, and the expected value.  

Use `!listplugins` to list all plugins on server.  

Mostly intended for Tournament servers, just a guide for semi-competitive servers (PUG).  
