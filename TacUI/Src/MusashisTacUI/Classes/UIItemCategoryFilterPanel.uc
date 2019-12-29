//-----------------------------------------------------------
//	Class:	UIItemCategoryFilterPanel
//	Author: Musashi
//	
//-----------------------------------------------------------
class UIItemCategoryFilterPanel extends UIFilterPanel;

var protected EInventorySlot InventorySlot;

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

simulated function AddFilters(array<name> FilterNames, EInventorySlot InventorySlotIn)
{
	local XComGameState_LoadoutFilter LoadoutFilterGameState;
	local name FilterName;
	local int UnitStateObjectID;
	local TacUIFilters FilterState;
	local UIFilterCheckbox Filter;
	local bool bChecked;

	InventorySlot = InventorySlotIn;
	UnitStateObjectID = GetUnitObjectIDFromArmory();
	LoadoutFilterGameState = class'XComGameState_LoadoutFilter'.static.GetLoadoutFilterGameState();

	if (LoadoutFilterGameState != none && UnitStateObjectID > 0)
	{
		FilterState = LoadoutFilterGameState.GetFilter(UnitStateObjectID, InventorySlot);
	}

	//RemoveUnusedFilters(FilterNames);
	ResetFilters();
	foreach FilterNames(FilterName)
	{
		Filter = GetFilter(FilterName);
		bChecked = FilterState.CategoryFilters.Find(FilterName) != INDEX_NONE;

		if (Filter == none)
		{
			AddFilter(
				string(FilterName),
				InventorySlot,
				bChecked,
				false
			);
		}
		else
		{
			Filter.Checkbox.SetChecked(bChecked);
		}
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
	local int Index;

	LoadoutFilterGameState = class'XComGameState_LoadoutFilter'.static.GetLoadoutFilterGameState();

	for (Index = 0; Index < List.GetItemCount(); Index++)
	{
		Filter = UIFilterCheckbox(List.GetItem(Index));
		`LOG(default.class @ GetFuncName() @ `ShowVar(Filter.Checkbox.MCName) @ `ShowVar(Filter.Checkbox.bChecked),, 'TacUI');
		if (Filter.Checkbox.bChecked)
		{
			ActiveFilters.AddItem(Filter.MCName);
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
			FilterState.InventorySlot = InventorySlot;
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
		LoadoutScreen.bLoadFilters = false;
		LoadoutScreen.UpdateLockerList();
		LoadoutScreen.bLoadFilters = true;
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
	Height = 600
	bShrinkToFit = true
}