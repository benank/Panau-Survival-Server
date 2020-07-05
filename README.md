# Panau-Survival-Server
All server code for the JC2MP server Panau Survival

## Getting Set Up
1. Clone the repo into your JC2MP server directory.
2. Set `IKnowWhatImDoing` to true in the server's config.
3. Delete `server.db` in case you've run the server before to ensure a clean start.
4. Edit line 5 of `scripts/inventory/server/sLootManager.lua` and replace `"lootspawns/lootspawns.txt"` with `"lootspawns_old.txt"`. This will allow the loot to spawn using the old loot spawns data file.
5. Copy `scripts/modelchanger/shModelLocations_old.lua` to `scripts/modelchanger/shared/shModelLocations.lua`
5. Copy `scripts/modelchanger/shModelLocationsObject.lua` to `scripts/modelchanger/shared/shModelLocationsObject.lua`
5. You're all set!

## Contributing Guidelines
Want to help development? Awesome! Here are a couple guidelines for helping out.

1. Fork the repository.
2. Make your changes in your newly forked repo.
3. Submit a pull request.

I'll review your changes and let you know if there are any problems. If it's all good, I'll merge it with the main repo!

If you'd like to be more involved with development, send me (Lord Farquaad) a DM on [Discord](https://discord.gg/DWGfX3b) telling me a bit about your experience and I'll add you to the developer channel.

## What's not open source?
There are a few things that aren't open source because of privacy and exploitation concerns. These items are:
 - Server database
 - Loot spawns
 - Vehicle spawns
 - Player model locations
 - Discord module

