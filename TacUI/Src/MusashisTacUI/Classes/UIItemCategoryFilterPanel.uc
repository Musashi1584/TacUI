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
	local name LocalFilter;

	foreach FilterNames(LocalFilter)
	{
		AddFilter(string(LocalFilter), false, false);
	}
}

simulated function OnFilterChanged(object Source)
{
	local UIFilterCheckbox Filter;
	local XComGameState_LoadoutFilter LoadoutFilterGameState;
	local TacUIFilters FilterState;
	local array<name> ActiveFilters;

	LoadoutFilterGameState = class'XComGameState_LoadoutFilter'.static.GetLoadoutFilterGameState();

	foreach Filters(Filter)
	{
		`LOG(default.class @ GetFuncName() @ `ShowVar(Filter.Desc.text) @ `ShowVar(Filter.Checkbox.bChecked),, 'TacUI');
		if (Filter.Checkbox.bChecked)
		{
			ActiveFilters.AddItem(name(Filter.Desc.text));
		}
	}

	if (LoadoutFilterGameState != none)
	{
		FilterState.UnitStateObjectID = UIArmory_Loadout_TacUI(ParentPanel).UnitReference.ObjectID;
		FilterState.CategoryFilters = ActiveFilters;
		LoadoutFilterGameState.AddFilter(FilterState);
	}

	`LOG(default.class @ GetFuncName() @ `ShowVar(Source) @ `ShowVar(LoadoutFilterGameState) @ `ShowVar(ActiveFilters.Length),, 'TacUI');
}

defaultProperties
{
	Width = 200
	Height = 230
}