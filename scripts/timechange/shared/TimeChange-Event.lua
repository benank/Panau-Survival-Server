--	TimeChange by JasonMRC of Problem Solvers.

class 'TimeChangeEvent'

function TimeChangeEvent:__init()
	self.RunOnServer	=	true	--	Should TimeChange run on the Server-Side?	Default: true
	self.RunOnClient	=	true	--	Should TimeChange run on the Client-Side?	Default: true
	
	--						TimeChange	--	Event Extension					--
	--
	--	TimeChange is a backend module designed to be loaded and let run.
	--	TimeChange adds two events to both Server and Client, These events are:
	--	"TimeChange" and "SecondTick"
	--	Both contain a table.
	--	
	--	----------					"TimeChange" contains:					----------
	--	Name					Always contained:		Type:			Description:
	--	args.Minute				Yes						Number(0-59)	The current minute
	--	args.Hour				Yes						Number(0-23)	The current hour
	--	args.FifthMinute		No						Bool			If the event happened on a minute divisible by 5
	--	args.TenthMinute		No						Bool			If the event happened on a minute divisible by 10
	--	args.FifteenthMinute	No						Bool			If the event happened on a minute divisible by 15
	--	args.HalfHour			No						Bool			If the event happened on a halfhour(beginning or middle of the hour)
	--	args.HourChange			No						Bool			If the hour has changed.
	--	args.QuarterDaily		No						Bool			If the hour is a quarter of the day(Happens at 0, 6, 12, and 18 hours)
	--	args.DayChange			No						Bool			If the day has changed(Happens at midnight).
	--	
	--	----------					"SecondTick" contains:					----------
	--	Name					Always contained:		Type:			Description:
	--	args.Second				Yes						Number(0-59)	The current second
	--	args.Even				Yes						Bool			True or False if the second is even.
	--	
	
	self.CurrentSecond	=	tonumber(os.date("%S"))
	self.CurrentHour	=	tonumber(os.date("%H"))
	self.CurrentMinute	=	tonumber(os.date("%M"))
	
	self.FiveIntegerlyTable	=	{
		[0]		=	true,
		[5]		=	true,
		[10]	=	true,
		[15]	=	true,
		[20]	=	true,
		[25]	=	true,
		[30]	=	true,
		[35]	=	true,
		[40]	=	true,
		[45]	=	true,
		[50]	=	true,
		[55]	=	true,
	}
	self.TenIntegerlyTable	=	{
		[0]		=	true,
		[10]	=	true,
		[20]	=	true,
		[30]	=	true,
		[40]	=	true,
		[50]	=	true,
	}
	self.FifteenIntegerlyTable	=	{
		[0]		=	true,
		[15]	=	true,
		[30]	=	true,
		[45]	=	true,
	}
	self.QuarterDailyTable	=	{
		[0]		=	true,
		[6]		=	true,
		[12]	=	true,
		[18]	=	true,
	}
	
	self.Version		=	1.0		--	Do not change.
	
	local ServerActive	=	Server and self.RunOnServer
	local ClientActive	=	Client and self.RunOnClient
	if ServerActive or ClientActive then
		Events:Subscribe("PreTick", self, self.CalcTimeEvent)
	end
end

function TimeChangeEvent:CalcTimeEvent()
	local DiffSecond	=	self.CurrentSecond
	local DiffMinute	=	self.CurrentMinute
	local DiffHour		=	self.CurrentHour
	self.HourChange		=	false
	self.DayChange		=	false
	
	if tonumber(os.date("%S")) ~= self.CurrentSecond then
		self.CurrentSecond	=	tonumber(os.date("%S"))
	end
	if tonumber(os.date("%M")) ~= self.CurrentMinute then
		self.CurrentMinute	=	tonumber(os.date("%M"))
	end
	if tonumber(os.date("%H")) ~= self.CurrentHour then
		self.CurrentHour	=	tonumber(os.date("%H"))
		self.HourChange		=	true
	end
	
	if self.CurrentHour == 0 and self.CurrentMinute == 0 then
		self.DayChange	=	true
	end
	
	if DiffSecond ~= self.CurrentSecond then
		self:EventSecondChange()
	end
	if DiffHour ~= self.CurrentHour or DiffMinute ~= self.CurrentMinute then
		self:EventTimeChange()
	end
end

function TimeChangeEvent:ArrangeMinuteChangeTable()
	local ReturnTable	=	{
		Hour		=	self.CurrentHour,
		Minute		=	self.CurrentMinute,
	}
	if self.FiveIntegerlyTable[self.CurrentMinute] then
		ReturnTable.FifthMinute	=	true
	end
	if self.TenIntegerlyTable[self.CurrentMinute] then
		ReturnTable.TenthMinute	=	true
	end
	if self.FifteenIntegerlyTable[self.CurrentMinute] then
		ReturnTable.FifteenthMinute	=	true
	end
	if self.QuarterDailyTable[self.CurrentHour] and self.HourChange then
		ReturnTable.QuarterDaily	=	true
	end
	if self.CurrentMinute == 0 or self.CurrentMinute == 30 then
		ReturnTable.HalfHour	=	true
	end
	if self.HourChange then
		ReturnTable.HourChange	=	self.HourChange
	end
	if self.DayChange then
		ReturnTable.DayChange	=	self.DayChange
	end
	return ReturnTable
end

function TimeChangeEvent:ArrangeSecondChangeTable()
	local ReturnTable	=	{
		Second	=	self.CurrentSecond
	}
	if self.CurrentSecond%2 == 0 then
		ReturnTable.Even	=	true
	else
		ReturnTable.Even	=	false
	end
	return ReturnTable
end

function TimeChangeEvent:EventTimeChange()
	Events:Fire("TimeChange", self:ArrangeMinuteChangeTable())
end

function TimeChangeEvent:EventSecondChange()
	Events:Fire("SecondTick", self:ArrangeSecondChangeTable())
end

TimeChangeEvent = TimeChangeEvent()