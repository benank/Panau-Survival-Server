function ModuleKick(args, sender)
	if IsValid(sender) then sender:Kick("One or more modules have stopped working, please reconnect to fix.") end
end
Network:Subscribe("Modules_StoppedWorking", ModuleKick)