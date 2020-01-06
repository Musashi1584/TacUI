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
	}
}

public static function ResetFilter(name FilterCategory, int UnitStateObjectID, EInventorySlot InventorySlot)
{
	local XComGameState_LoadoutFilter LoadoutFilterGameState;
	local XComGameState NewGameState;
	local TacUIFilters Filter;

	LoadoutFilterGameState = class'XComGameState_LoadoutFilter'.static.GetLoadoutFilterGameState();
	NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Reset Loadout Filter State");
	LoadoutFilterGameState = XComGameState_LoadoutFilter(NewGameState.ModifyStateObject(LoadoutFilterGameState.Class, LoadoutFilterGameState.ObjectID));
			
	Filter = LoadoutFilterGameState.GetFilter(FilterCategory, UnitStateObjectID, InventorySlot);
	Filter.FilterNames.Length = 0;
	LoadoutFilterGameState.AddFilter(FilterCategory, Filter);
	`XCOMHISTORY.AddGameStateToHistory(NewGameState);
}

public function AddFilter(name FilterCategory, TacUIFilters Filter)
{
	local int Index;

	Index = UIFilters.Find('FilterKey', FilterCategory $ Filter.UnitStateObjectID $ Filter.InventorySlot);

	Filter.FilterKey =  FilterCategory $ Filter.UnitStateObjectID $ Filter.InventorySlot;

	if (Index != INDEX_NONE)
	{
		UIFilters[Index] = Filter;
	}
	else
	{
		UIFilters.AddItem(Filter);
	}
}

public function TacUIFilters GetFilter(name FilterCategory, int UnitStateObjectID, EInventorySlot InventorySlot)
{
	local TacUIFilters Filter;
	local int Index;

	Index = UIFilters.Find('FilterKey', FilterCategory $ UnitStateObjectID $ InventorySlot);
	if (Index != INDEX_NONE)
	{
		Filter = UIFilters[Index];
	}

	return Filter;
}