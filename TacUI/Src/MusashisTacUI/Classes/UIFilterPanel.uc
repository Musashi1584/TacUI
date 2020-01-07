//-----------------------------------------------------------
//	Class:	UIFilterPanel
//	Author: Musashi
//	
//-----------------------------------------------------------
class UIFilterPanel extends UIListPanel;

const ButtonWidth = 250;
const ButtonHeight = 40;

var private bool bUseRadioButtons;

var private string Title;
//var private UIButton ToggleAllButton;
var privatewrite UIEventHandler OnFilterChangedHandler;


simulated static function UIFilterPanel CreateFilterPanel(
	class<UIFilterPanel> ClassIn,
	UiPanel ParentPanelIn,
	string TitleIn,
	bool bUseRadioButtonsIn
)
{
	local UIFilterPanel This;

	This = UIFilterPanel(class'UIListPanel'.static.CreateListPanel(ClassIn, ParentPanelIn, 'FilterList', TitleIn));
	This.OnFilterChangedHandler = class'UIEventHandler'.static.CreateHandler();
	This.bUseRadioButtons = bUseRadioButtonsIn;

	return This;
}

public function UIFilterCheckbox AddFilter(
	name FilterName,
	string FilterLabel,
	EInventorySlot InventorySlotIn,
	bool bChecked,
	bool bDisabled = false
)
{
	local UIFilterCheckbox Checkbox;

	Checkbox = class'UIFilterCheckbox'.static.CreateCheckbox(
		List,
		FilterName,
		FilterLabel,
		bChecked,
		bDisabled
	);

	Checkbox.OnCheckedChangedHandler.AddHandler(HandleFilterChanged);
	
	return Checkbox;
}

public function ResetFilters()
{
	List.ClearItems();
}

simulated function UIFilterCheckbox GetFilter(name FilterName)
{
	local UIFilterCheckbox Filter;
	local int Index;

	for (Index = 0; Index < List.GetItemCount(); Index++)
	{
		Filter = UIFilterCheckbox(List.GetItem(Index));
		if (Filter.MCName == FilterName)
		{
			return Filter;
		}
	}
	return none;
}

private function HandleFilterChanged(Object Source) {
	local UIFilterCheckbox Filter;
	local int Index;

	if(bUseRadioButtons)
	{
		// uncheck others
		for (Index = 0; Index < List.ItemCount; Index++)
		{
			Filter = UIFilterCheckbox(List.GetItem(Index));
			if(!Filter.Checkbox.bIsDisabled && Filter != Source)
			{
				Filter.Checkbox.SetChecked(false, false);
			}
		}
		// (un-)check clicked
		//UIFilterCheckbox(Source).Checkbox.SetChecked(!UIFilterCheckbox(Source).Checkbox.bChecked, false);
	}

	`LOG(default.class @ GetFuncName() @ `ShowVar(UIFilterCheckbox(Source).Checkbox.bChecked) @ `ShowVar(OnFilterChangedHandler),, 'TacUI');

	OnFilterChangedHandler.Dispatch(self);
}


//private function HandleAllNoneClicked(UIButton Source) {
//	local UIFilterCheckbox ListItem;
//	local bool bChecked;
//
//	// check all if at least one filter is unchecked ; uncheck all otherwise
//
//	bChecked = false;
//	foreach Filters(ListItem)
//	{
//		if(!ListItem.Checkbox.bIsDisabled && !ListItem.Checkbox.bChecked) bChecked = true;
//	}
//
//	foreach Filters(ListItem)
//	{
//		if(!ListItem.Checkbox.bIsDisabled ) ListItem.Checkbox.SetChecked(bChecked);
//	}
//
//	OnFilterChangedHandler.Dispatch(self);
//
//	XComHQPresentationLayer(Movie.Pres).GetCamera().Move( vect(0,0,-10) );
//	XComHQPresentationLayer(Movie.Pres).GetCamera().SetZoom(2);
//}



