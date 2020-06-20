//-----------------------------------------------------------
//	Class:	UIArmory_LoadoutFilterPanel
//	Author: Musashi
//	
//-----------------------------------------------------------
class UIArmory_LoadoutFilterPanel extends UIFilterPanel;

var protected EInventorySlot InventorySlot;
var name FilterCategory;

simulated static function UIArmory_LoadoutFilterPanel CreateLoadoutFilterPanel(
	UiPanel ParentPanelIn,
	string FilterTitle,
	name FilterCategoryIn,
	optional bool bUseRadioButtonsIn = false
)
{
	local UIArmory_LoadoutFilterPanel This;

	This = UIArmory_LoadoutFilterPanel(class'UIFilterPanel'.static.CreateFilterPanel(
		class'UIArmory_LoadoutFilterPanel',
		ParentPanelIn,
		FilterTitle,
		bUseRadioButtonsIn
	));

	This.OnFilterChangedHandler.AddHandler(this.OnFilterChanged);
	This.FilterCategory = FilterCategoryIn;
	
	return This;
}

simulated function PopulateFilters(
	array<name> FilterNames,
	EInventorySlot InventorySlotIn,
	optional array<string> FilterLabels,
	optional bool bDefaultToFirst = false
)
{
	local XComGameState_LoadoutFilter LoadoutFilterGameState;
	local name FilterName;
	local int UnitStateObjectID;
	local TacUIFilters FilterState;
	local UIFilterCheckbox Filter;
	local bool bChecked;
	local int Index;

	InventorySlot = InventorySlotIn;
	UnitStateObjectID = GetUnitObjectIDFromArmory();
	LoadoutFilterGameState = class'XComGameState_LoadoutFilter'.static.GetLoadoutFilterGameState();

	`LOG(default.class @ GetFuncName() @ `ShowVar(UnitStateObjectID) @ `ShowVar(LoadoutFilterGameState.ObjectID),, 'TacUI');

	if (LoadoutFilterGameState != none && UnitStateObjectID > 0)
	{
		FilterState = LoadoutFilterGameState.GetFilter(FilterCategory, UnitStateObjectID, InventorySlot);
		`LOG(default.class @ GetFuncName() @ `ShowVar(FilterState.FilterNames.Length),, 'TacUI');
	}


	//RemoveUnusedFilters(FilterNames);
	ResetFilters();
	foreach FilterNames(FilterName, Index)
	{
		Filter = GetFilter(FilterName);
		bChecked = FilterState.FilterNames.Find(FilterName) != INDEX_NONE;

		// If nothing is selected yet use first option
		if (bDefaultToFirst && Index == 0 &&
			FilterState.FilterNames.Length == 0)
		{
			bChecked = true;
		}

		if (Filter == none)
		{
			AddFilter(
				FilterName,
				FilterLabels.Length > 0 ? FilterLabels[Index] : string(FilterName),
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

	if (FilterNames.Length == 0)
	{
		Hide();
	}
	else
	{
		Show();
	}

	`LOG(default.class @ GetFuncName() @ "End",, 'TacUI');
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
		//`LOG(default.class @ GetFuncName() @ `ShowVar(Filter.Checkbox.MCName) @ `ShowVar(Filter.Checkbox.bChecked),, 'TacUI');
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
			FilterState.FilterNames = ActiveFilters;
			LoadoutFilterGameState.AddFilter(FilterCategory, FilterState);
			`XCOMHISTORY.AddGameStateToHistory(NewGameState);
		}
	}

	ApplyFilters();

	//`LOG(default.class @ GetFuncName() @ `ShowVar(Source) @ `ShowVar(LoadoutFilterGameState) @ `ShowVar(ActiveFilters.Length),, 'TacUI');
}

simulated private function ApplyFilters()
{
	local UIScreenStack ScreenStack;
	local UIArmory_Loadout_TacUI LoadoutScreen;

	ScreenStack = `SCREENSTACK;
	LoadoutScreen = UIArmory_Loadout_TacUI(ScreenStack.GetFirstInstanceOf(class'UIArmory_Loadout_TacUI'));

	if (LoadoutScreen != none)
	{	
		LoadoutScreen.LockerList.ClearItems();
		LoadoutScreen.bAbortLoading = true;
		LoadoutScreen.bLoadFilters = false;
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
	Height = 600
	bShrinkToFit = true
}