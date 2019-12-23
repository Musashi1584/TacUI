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
		"ITEM CATEGORY",
		true
	));
	
	return This;
}

simulated function AddFilters(array<name> Filter)
{
	local name LocalFilter;

	foreach Filter(LocalFilter)
	{
		AddFilter(string(LocalFilter), false, false);
	}
}

defaultProperties
{
	Width = 200
	Height = 230
}