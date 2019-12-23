//-----------------------------------------------------------
//	Class:	UIFilterPanel
//	Author: Musashi
//	
//-----------------------------------------------------------
class UIFilterPanel extends UISimpleContainer;

const FilterHeight = 35;
const ButtonWidth = 250;
const ButtonHeight = 40;

var private bool bUseRadioButtons;

var private string Title;
var private float NextY;
var private array<UIFilterCheckbox> Filters;
var private UIButton ToggleAllButton;
var private UIList FilterList;

simulated static function UIFilterPanel CreateFilterPanel(
	class<UIFilterPanel> ClassIn,
	UiPanel ParentPanelIn,
	string TitleIn,
	bool bUseRadioButtonsIn
)
{
	local UIFilterPanel This;

	This = UIFilterPanel(class'UISimpleContainer'.static.CreateSimpleContainer(ClassIn, ParentPanelIn));
	This.InitFilterPanel(TitleIn, bUseRadioButtonsIn);

	return This;
}

simulated function InitFilterPanel(string TitleIn, bool bUseRadioButtonsIn)
{
	`LOG(default.class @ GetFuncName() @ `ShowVar(TitleIn) @ bUseRadioButtonsIn,, 'TacUI');

	bUseRadioButtonsIn = bUseRadioButtonsIn;
	Title = TitleIn;
	
	NextY = 50 + Padding;
	
	//if(bUseRadioButtonsIn) {
	//	ToggleAllButton = Spawn(class'UIButton', self).InitButton('', "All/None", HandleAllNoneClicked);
	//	ToggleAllButton.SetSize(ButtonWidth, ButtonHeight);
	//	ToggleAllButton.SetPosition(Padding + 10, NextY);
	//	NextY += ButtonHeight + Padding * 2;
	//}

	FilterList = CreateList(self, name("FilterPanel" $ Title), Title);
	
	`LOG(default.class @ GetFuncName() @ `ShowVar(Width) @ `ShowVar(Height),, 'TacUI');
}

simulated static function UIList CreateList(UIPanel Container, name ListName, string ListTitle)
{
	local UIList ReturnList;
	local UIText Header;
	
	ReturnList = Container.Spawn(class'UIList', Container);
	ReturnList.bStickyHighlight = false;
	ReturnList.bAutosizeItems = false;
	ReturnList.bAnimateOnInit = false;
	ReturnList.bSelectFirstAvailable = false;
	ReturnList.BGPaddingLeft = 10;
	ReturnList.BGPaddingTop = 50;
	ReturnList.BGPaddingRight = 10;
	
	//ReturnList.ItemPadding = 5;
	ReturnList.InitList(ListName, 0, 50, Container.Width, Container.Height, false, true, class'UIUtilities_Controls'.const.MC_X2Background);
	ReturnList.BG.SetSize(Container.Width, Container.Height);

	// this allows us to send mouse scroll events to the list
	ReturnList.BG.ProcessMouseEvents(ReturnList.OnChildMouseEvent);

	//Header = Container.Spawn(class'UIX2PanelHeader', Container);
	//Header.InitPanelHeader('ListHeader', "", ListTitle);
	//Header.SetX(Padding);
	//Header.SetHeaderWidth(Container.Width - 5);

	Header = Container.Spawn(class'UIText', Container).InitText('ListHeader');
	Header.SetPosition(5, 5);
	Header.SetWidth(Container.Width - 5);
	Header.SetHtmlText(
		class'UIUtilities_Text'.static.AddFontInfo(
			class'UIUtilities_Text'.static.GetColoredText(ListTitle, eUIState_Header, class'UIUtilities_Text'.const.BODY_FONT_SIZE_2D),
			Container.Screen.bIsIn3D,
			true,
			true
		)
	);

	return ReturnList;
}

public function UIFilterCheckbox AddFilter(string FilterLabel, bool bChecked, bool bDisabled = false)
{
	local UIFilterCheckbox Checkbox;

	`LOG(default.class @ GetFuncName() @ `ShowVar(FilterLabel) @ `ShowVar(FilterList),, 'TacUI');

	Checkbox = class'UIFilterCheckbox'.static.CreateCheckbox(
		FilterList,
		FilterLabel,
		bChecked,

	);
	//Checkbox.SetPosition(0, NextY);

	Filters.AddItem(Checkbox);

	NextY += FilterHeight + Padding;

	if(Height < NextY) {
		FilterList.BG.SetHeight(NextY);
		//SetHeight(NextY);
	}

	return Checkbox;
}

public function ResetFilters()
{
	local UIFilterCheckbox Filter;
	FilterList.ClearItems();
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

	//OnChanged.Dispatch(self);

	XComHQPresentationLayer(Movie.Pres).GetCamera().Move( vect(0,0,-10) );
	XComHQPresentationLayer(Movie.Pres).GetCamera().SetZoom(2);
}


private function HandleFilterChanged(Object Source) {
	local UIFilterCheckbox ListItem;

	if(bUseRadioButtons)
	{
		// uncheck others
		foreach Filters(ListItem)
		{
			if(!ListItem.Checkbox.bIsDisabled && ListItem.Checkbox != Source)
			{
				ListItem.Checkbox.SetChecked(false, false);
			}
		}
		// check clicked
		UIFilterCheckbox(Source).Checkbox.SetChecked(true, false);
	}

	//OnChanged.Dispatch(self);
}

