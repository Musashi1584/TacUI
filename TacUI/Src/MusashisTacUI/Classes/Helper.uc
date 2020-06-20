//-----------------------------------------------------------
//	Class:	Helper
//	Author: Musashi
//	
//-----------------------------------------------------------


class Helper extends Object dependson(DataStructures_TacUI) config (Fake);

var config array<ProfileTime> ProfileTimes;

static function float GetTimeStamp()
{
	local int Year1, Month1, DayOfWeek1, Day1, Hour1, Min1, Sec1, MSec1;

	class'XComEngine'.static.GetClassDefaultObjectByName('Object').GetSystemTime(Year1, Month1, DayOfWeek1, Day1, Hour1, Min1, Sec1, MSec1);

	return float(Hour1 * 3600) + float(Min1 * 60) + float(Sec1) + float(MSec1) / 1000;
}

static function float StartProfiling(name ProfileName)
{
	local int Index;
	local ProfileTime NewProfile;

	Index = default.ProfileTimes.Find('ProfileName', ProfileName);

	if (Index != INDEX_NONE)
	{
		default.ProfileTimes[Index].StartTime = GetTimeStamp();
		return default.ProfileTimes[Index].StartTime;
	}

	NewProfile.ProfileName = ProfileName;
	NewProfile.StartTime = GetTimeStamp();
	default.ProfileTimes.AddItem(NewProfile);
	return NewProfile.StartTime;
}

static function float EndProfiling(name ProfileName)
{
	local int Index;
	local ProfileTime NewProfile;

	Index = default.ProfileTimes.Find('ProfileName', ProfileName);

	if (Index != INDEX_NONE)
	{
		default.ProfileTimes[Index].EndTime = GetTimeStamp();
		default.ProfileTimes[Index].ElapsedTime = default.ProfileTimes[Index].EndTime - default.ProfileTimes[Index].StartTime;
		return default.ProfileTimes[Index].ElapsedTime;
	}

	return 0;
}

static function float GetElapsedTime(name ProfileName)
{
	local int Index;
	local ProfileTime NewProfile;

	Index = default.ProfileTimes.Find('ProfileName', ProfileName);

	if (Index != INDEX_NONE)
	{
		return default.ProfileTimes[Index].ElapsedTime;
	}

	return 0;
}
