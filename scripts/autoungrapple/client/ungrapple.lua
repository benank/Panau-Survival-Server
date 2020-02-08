timer = Timer()
function ray()
	local state = LocalPlayer:GetBaseState()
	if state == AnimationState.SGrappled
	or state == AnimationState.SHangFireHook
	or state == AnimationState.SHangToFall
	or state == AnimationState.SHanged
	or state == AnimationState.SHangstuntIdle
	or state == AnimationState.SReeledInToHang then
		local ray = Physics:Raycast(LocalPlayer:GetPosition() + Vector3.Down, Vector3.Down, 0, 3)
		if ray.distance < 3 and timer:GetSeconds() > 0.5 then
			Network:Send("TPME")
			timer:Restart()
		end
	end
end
Events:Subscribe("PreTick", ray)