//-----------------------------------------------------------
//	Class:	UIFilterPanel
//	Author: Musashi
//	
//-----------------------------------------------------------
class UIFilterPanel extends UIListPanel;

const FilterHeight = 35;
const ButtonWidth = 250;
const ButtonHeight = 40;

var private bool bUseRadioButtons;

var private string Title;
var private float NextY;
var protected array<UIFilterCheckbox> Filters;
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

public function UIFilterCheckbox AddFilter(string FilterLabel, bool bChecked, bool bDisabled = false)
{
	local UIFilterCheckbox Checkbox;

	`LOG(default.class @ GetFuncName() @ `ShowVar(FilterLabel) @ `ShowVar(List),, 'TacUI');

	Checkbox = class'UIFilterCheckbox'.static.CreateCheckbox(
		List,
		FilterLabel,
		bChecked,
		bDisabled
	);

	Checkbox.OnCheckedChangedHandler.AddHandler(HandleFilterChanged);

	Filters.AddItem(Checkbox);

	NextY += FilterHeight + Padding;

	if(Height < NextY) {
		List.BG.SetHeight(NextY);
		//SetHeight(NextY);
	}

	return Checkbox;
}

public function ResetFilters()
{
	List.ClearItems();
	Filters.Length = 0;
	NextY = 50 + Padding;
}

simulated function Show()
{
	local UIFilterCheckbox Filter;

	if(!bIsVisible)
	{
		foreach Filters(Filter)
		{
			Filter.Show();
		}
		ToggleAllButton.Show();
		super.Show();
	}
}

simulated function Hide()
{
	local UIFilterCheckbox Filter;

	if(bIsVisible)
	{
		foreach Filters(Filter)
		{
			Filter.Hide();
		}
		ToggleAllButton.Hide();
		super.Hide();
	}
}


//======================================================================================================================
// HANDLERS
private function HandleAllNoneClicked(UIButton Source) {
	local UIFilterCheckbox ListItem;
	local bool bChecked;

	// check all if at least one filter is unchecked ; uncheck all otherwise

	bChecked = false;
	foreach Filters(ListItem)
	{
		if(!ListItem.Checkbox.bIsDisabled && !ListItem.Checkbox.bChecked) bChecked = true;
	}

	foreach Filters(ListItem)
	{
		if(!ListItem.Checkbox.bIsDisabled ) ListItem.Checkbox.SetChecked(bChecked);
	}

	OnFilterChangedHandler.Dispatch(self);

	XComHQPresentationLayer(Movie.Pres).GetCamera().Move( vect(0,0,-10) );
	XComHQPresentationLayer(Movie.Pres).GetCamera().SetZoom(2);
}


private function HandleFilterChanged(Object Source) {
	local UIFilterCheckbox Filter;

	if(bUseRadioButtons)
	{
		// uncheck others
		foreach Filters(Filter)
		{
			if(!Filter.Checkbox.bIsDisabled && Filter!=Source)
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

