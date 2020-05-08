# FreeCam (v0.3.1) for JC2-MP
**FreeCam** is a free/spectate camera module for the [Just Cause 2 Multiplayer Mod](http://store.steampowered.com/app/259080/).<br>
You can also add waypoints to a trajectory and let the camera follow that trajectory automatically (still in beta).<br>
It is also possible to save, load and delete these trajectories on the server which comes in handy to create checkpoints for races or borders for some area's.<br>


## Installation notes
It is required to run a JC2-MP server to run this script.
Go to the [jc-mp wiki page](http://wiki.jc-mp.com/Server) for more information on how to confingure your own server and put these FreeCam files in the 'scripts/' folder.<br>
Look into the 'shared/Config.lua' file to change some settings.<br>
Type (re/un)load freecam into the server console  to (re/un)load this module.<br>

## Usage
- Press V while in game to enter the FreeCam mode
- Use SHIFT to speedup, CTRL to slow down or Increase/Decrease trust on gamepad
- Press V again to exit and if the teleport option is set in Config.lua, the player will be teleported to that specific location
- Making trajectories (while in FreeCam mode):
	- numpad1/gamepad X: reset trajectory
	- numpad2/left mouse click/gamepad A: add waypoint to current trajectory
	- numpad3/gamepad B: start/stop auto follow trajectory mode (starting from the first waypoint)
	- numpad4: start/stop auto follow trajectory mode (starting from current camera position)
	- P: pause the auto follow trajectory mode
- Commands for saving trajectories and spawnpoints (white listed players only):
	- Type /freecam &lt;save/load/delete&gt; trajectory &lt;trajectory_name&gt; to manage trajectories
	- Type /freecam save position &lt;position_name&gt; to save positions

## For developers
- Events:
	- This module launches a "FreeCamChange" event with argument "active" on both client and serverside when the cam is (de)activated
- WhiteList: (See **'server/WhiteList.lua'**)
	- Add steam id's to this list if you want to limit this feature to some players
	- Only whitelisted players can save trajectories/spawnpoints
	- It is also possible to change permissions and force the specate view on the fly by firing a "FreeCam" Event (also documented in WhiteList.lua)


## ChangeLog
### Update v0.3.1
- Changed commands for managing trajectories and positions

### Update v0.3
- Added FreeCamChange events to notice other modules when the camera is (de)activated
- Added a whitelist + possibility to manipulate the permissions to this freecam

### Update v0.2
- Save single position in extra file in default spawnlocation format (T <name>, x, y, z)

### Update v0.1
- Some minor improvements and better gamepad support