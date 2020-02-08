class 'ModuleChecker'
function ModuleChecker:__init()
	oldnumModules = 0
	numModules = 0
	veryoldnumModules = 0
	missingmods = 0
	warnamt = 0
	maxWarnamt = 120 --how many warnings they should get before they are kicked
	warnTextamt = 30
	Events:Subscribe("ModuleChecker_Return", self, self.CountReturn)
	Events:Subscribe("RenderUpgradeSequence", self, self.RenderUpgradeSequence)
	Events:Subscribe("SecondTick", self, self.Fire)
end
function ModuleChecker:Fire(args)
	if args.Even then
		if numModules == veryoldnumModules then
			missingmods = 0
		elseif oldnumModules < numModules then
			oldnumModules = numModules
			warnamt = 0
		end
		numModules = 0
		Events:Fire("ModuleChecker_Send")
	end
	if not args.Even and oldnumModules > numModules then
		missingmods = oldnumModules - numModules
		veryoldnumModules = oldnumModules
		warnamt = warnamt + 1
		if warnamt > warnTextamt then
			warnamt = 0
			Chat:Print(tostring(missingmods).." module(s) has stopped working, please reconnect to fix!", Color.Red)
			--Network:Send("Modules_StoppedWorking")
		end
		if warnamt > maxWarnamt then
			--Network:Send("Modules_StoppedWorking")
		end
	end
end
function ModuleChecker:CountReturn()
	numModules = numModules + 1
end
function ModuleChecker:RenderUpgradeSequence()
	Events:Fire("Notification", {title = "Upgrading your experience", preset = "Upgrade", subtitle = "Patching modules"})
end
ModuleChecker = ModuleChecker()