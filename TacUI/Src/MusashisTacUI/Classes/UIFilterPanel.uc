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
//var protected array<UIFilterCheckbox> Filters;
var private UIButton ToggleAllButton;
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
	
	return This;
}

public function UIFilterCheckbox AddFilter(string FilterLabel, EInventorySlot InventorySlotIn, bool bChecked, bool bDisabled = false)
{
	local UIFilterCheckbox Checkbox;

	//`LOG(default.class @ GetFuncName() @ `ShowVar(FilterLabel) @ `ShowVar(List),, 'TacUI');

	Checkbox = class'UIFilterCheckbox'.static.CreateCheckbox(
		List,
		FilterLabel,
		bChecked,
		bDisabled
	);

	Checkbox.OnCheckedChangedHandler.AddHandler(HandleFilterChanged);

	//Filters.AddItem(Checkbox);

	//NextY += FilterHeight + Padding;
	//
	//if(Height < NextY) {
	//	List.BG.SetHeight(NextY);
	//	//SetHeight(NextY);
	//}

	return Checkbox;
}

public function ResetFilters()
{
	List.ClearItems();
	//Filters.Length = 0;
	//NextY = 50 + Padding;
}


simulated function RemoveUnusedFilters(array<name> FilterNames)
{
	local UIFilterCheckbox Filter;
	local int Index, ItemCount;

	ItemCount = List.GetItemCount();

	for (Index = ItemCount - 1; Index >= 0; Index--)
	{
		Filter = UIFilterCheckbox(List.GetItem(Index));
		if (FilterNames.Find(Filter.MCName) == INDEX_NONE)
		{
			List.ItemContainer.RemoveChild(Filter);
		}
	}
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

//simulated function Show()
//{
//	//local UIFilterCheckbox Filter;
//
//	if(!bIsVisible)
//	{
//		//foreach Filters(Filter)
//		//{
//		//	Filter.Show();
//		//}
//		//ToggleAllButton.Show();
//		super.Show();
//	}
//}
//
//simulated function Hide()
//{
//	//local UIFilterCheckbox Filter;
//
//	if(bIsVisible)
//	{
//		//foreach Filters(Filter)
//		//{
//		//	Filter.Hide();
//		//}
//		//ToggleAllButton.Hide();
//		super.Hide();
//	}
//}


//======================================================================================================================
// HANDLERS
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
		// check clicked
		UIFilterCheckbox(Source).Checkbox.SetChecked(true, false);
	}

	`LOG(default.class @ GetFuncName() @ `ShowVar(UIFilterCheckbox(Source).Checkbox.bChecked) @ `ShowVar(OnFilterChangedHandler),, 'TacUI');

	OnFilterChangedHandler.Dispatch(self);
}

