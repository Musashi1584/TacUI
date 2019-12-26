//-----------------------------------------------------------
//	Class:	UIItemCategoryFilterPanel
//	Author: Musashi
//	
//-----------------------------------------------------------
class UIItemCategoryFilterPanel extends UIFilterPanel;

simulated static function UIItemCategoryFilterPanel CreateItemCategoryFilterPanel(
	UiPanel ParentPanelIn
)
{
	local UIItemCategoryFilterPanel This;

	This = UIItemCategoryFilterPanel(class'UIFilterPanel'.static.CreateFilterPanel(
		class'UIItemCategoryFilterPanel',
		ParentPanelIn,
		"FILTER BY",
		true
	));

	This.OnFilterChangedHandler.AddHandler(this.OnFilterChanged);
	
	return This;
}

simulated function AddFilters(array<name> FilterNames)
{
	local XComGameState_LoadoutFilter LoadoutFilterGameState;
	local name LocalFilter;
	local int UnitStateObjectID;
	local TacUIFilters FilterState;

	UnitStateObjectID = GetUnitObjectIDFromArmory();
	LoadoutFilterGameState = class'XComGameState_LoadoutFilter'.static.GetLoadoutFilterGameState();

	if (LoadoutFilterGameState != none && UnitStateObjectID > 0)
	{
		FilterState = LoadoutFilterGameState.GetFilter(UnitStateObjectID);
	}

	foreach FilterNames(LocalFilter)
	{
		AddFilter(
			string(LocalFilter),
			FilterState.CategoryFilters.Find(LocalFilter) != INDEX_NONE,
			false
		);
	}
}

simulated function OnFilterChanged(object Source)
{
	local UIFilterCheckbox Filter;
	local XComGameState_LoadoutFilter LoadoutFilterGameState;
	local TacUIFilters FilterState;
	local array<name> ActiveFilters;
	local XComGameState NewGameState;
	local int UnitStateObjectID;

	LoadoutFilterGameState = class'XComGameState_LoadoutFilter'.static.GetLoadoutFilterGameState();

	foreach Filters(Filter)
	{
		`LOG(default.class @ GetFuncName() @ `ShowVar(Filter.Checkbox.MCName) @ `ShowVar(Filter.Checkbox.bChecked),, 'TacUI');
		if (Filter.Checkbox.bChecked)
		{
			ActiveFilters.AddItem(Filter.Checkbox.MCName);
		}
	}

	if (LoadoutFilterGameState != none)
	{
		UnitStateObjectID = GetUnitObjectIDFromArmory();
		if (UnitStateObjectID > 0)
		{
			NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Loadout Filter State");
			LoadoutFilterGameState = XComGameState_LoadoutFilter(NewGameState.ModifyStateObject(LoadoutFilterGameState.Class, LoadoutFilterGameState.ObjectID));
			FilterState.UnitStateObjectID = UnitStateObjectID;
			FilterState.CategoryFilters = ActiveFilters;
			LoadoutFilterGameState.AddFilter(FilterState);
			`XCOMHISTORY.AddGameStateToHistory(NewGameState);
		}
	}

	ApplyFilters();

	`LOG(default.class @ GetFuncName() @ `ShowVar(Source) @ `ShowVar(LoadoutFilterGameState) @ `ShowVar(ActiveFilters.Length),, 'TacUI');
}

simulated private function ApplyFilters()
{
	local UIScreenStack ScreenStack;
	local UIArmory_Loadout_TacUI LoadoutScreen;

	ScreenStack = `SCREENSTACK;
	LoadoutScreen = UIArmory_Loadout_TacUI(ScreenStack.GetFirstInstanceOf(class'UIArmory_Loadout_TacUI'));

	if (LoadoutScreen != none)
	{
		LoadoutScreen.UpdateLockerList();
	}
}

simulated public function int GetUnitObjectIDFromArmory()
{
	local UIScreenStack ScreenStack;
	local UIArmory ArmoryScreen;

	ScreenStack = `SCREENSTACK;
	ArmoryScreen = UIArmory(ScreenStack.GetFirstInstanceOf(class'UIArmory'));
	if (ArmoryScreen != none && ArmoryScreen.UnitReference.ObjectID > 0)
	{
		return ArmoryScreen.UnitReference.ObjectID;
	}

	return 0;
}

defaultProperties
{
	Width = 200
	Height = 230
}