WhiteList = {
	"STEAM_0:1:31147722",
    "STEAM_0:0:47613644",
    "STEAM_0:1:37351623",
    "STEAM_0:1:82883843"
}

-- NOTES:

-- This whitelist is for defining the defaults when the "useWhiteList" flag is set in 'shared/Config.lua'

-- To adjust permissions or to force this specate view ingame, fire a "FreeCam" event on the server-side
-- with the following parameters:
--		args.player: player
--		args.perm: (optional) true: give player permission to (de)activate the view
--							  false: remove permission from player to (de)activate the view
--		args.active: (optional) true: activate FreeCam for player
--								false: deactivate FreeCam for this player
--		args.restore: (optional) true: restore the default permission


-- For example: If you want to force this view to a specific player do:
-- Events:Fire("FreeCam", {["player"] = player,
--						   ["perm"] = false,
--						   ["active"] = true})

-- To restore the default do:
-- Events:Fire("FreeCam", {["player"] = player,
--						   ["restore"] = true,
--						   ["active"] = false})