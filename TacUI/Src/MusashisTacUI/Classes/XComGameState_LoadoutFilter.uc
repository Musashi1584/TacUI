//-----------------------------------------------------------
//	Class:	XComGameState_LoadoutFilter
//	Author: Musashi
//	
//-----------------------------------------------------------
class XComGameState_LoadoutFilter extends  XComGameState_BaseObject;

var private array<TacUIFilters> UIFilters;

public static function XComGameState_LoadoutFilter GetLoadoutFilterGameState()
{
	return XComGameState_LoadoutFilter(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LoadoutFilter', true));
}

public static function CreateLoadoutFilterGameState(out XComGameState NewGameState)
{
	local XComGameState_LoadoutFilter LoadoutFilterGameState;
	
	LoadoutFilterGameState = XComGameState_LoadoutFilter(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_LoadoutFilter', true));

	if (LoadoutFilterGameState == none || LoadoutFilterGameState.ObjectID == 0)
	{
		LoadoutFilterGameState = XComGameState_LoadoutFilter(NewGameState.CreateNewStateObject(class'XComGameState_LoadoutFilter'));
		NewGameState.AddStateObject(LoadoutFilterGameState);
	}
}

public function AddFilter(TacUIFilters Filter)
{
	local int Index;

	Index = UIFilters.Find('UnitStateObjectID', Filter.UnitStateObjectID);
	if (Index != INDEX_NONE)
	{
		UIFilters[Index] = Filter;
	}
	else
	{
		UIFilters.AddItem(Filter);
	}
}

public function TacUIFilters GetFilter(int UnitStateObjectID)
{
	local TacUIFilters Filter;
	local int Index;

	Index = UIFilters.Find('UnitStateObjectID', UnitStateObjectID);
	if (Index != INDEX_NONE)
	{
		Filter = UIFilters[Index];
	}

	return Filter;
}