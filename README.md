# SM-Comp-Server-Validator
Sourcemod plugin to verify if NT Comp servers are setup properly
Currently checks server plugins against a hardcoded list of required plugins (+versions) and "validates" the server if all required plugins are present.  

Install the plugin and use `!validate` in chat or `sm_validate` in console and it will print in console all the non-default plugins on the server and any from the required list that were not present.  

Use `!listplugins` to list all plugins on server.  

Mostly intended for Tournament servers, just a guide for semi-competitive servers (PUG)  

  
