function DaysToSeconds(days)
    return days * 60 * 60 * 24
end

function SecondsToDays(seconds)
    return seconds / 60 / 60 / 24
end

--[[
    Returns date of expiriy in string format YYYY-MM-DD

    args (in table):
        is_new_landclaim (bool): whether or not this landclaim was just placed

        if is_new_landclaim is not specified, you must include instead:
            radius (number): radius of the landclaim
            new_radius (number): radius of the landclaim being used
]]
function GetLandclaimExpireDate(args)

    local days_to_add = args.is_new_landclaim and
        Config.base_landclaim_lifetime or
        math.clamp(1, math.ceil(args.new_radius / args.radius, 10) * Config.base_landclaim_lifetime)

    return GetLandclaimExpireDateFromTime(os.time() + DaysToSeconds(days_to_add))

end

-- returns date of expiry in format YYYY-MM-DD
function GetLandclaimExpireDateFromTime(time)
    local time_table = os.date("*t", time)
    return string.format("%s-%s-%s", time_table.year, time_table.month, time_table.day)
end

-- Gets the number of days until a landclaim expires
function GetLandclaimDaysTillExpiry(expire_date)
    local split = expire_date:split("-")
    local seconds = os.time{year = split[1], month = split[2], day = split[3]} - os.time()
    return math.floor(SecondsToDays(seconds))
end