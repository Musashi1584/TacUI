//-----------------------------------------------------------
//	Class:	UIListPanel
//	Author: Musashi
//	
//-----------------------------------------------------------
class UIListPanel extends UIPanel;

const Padding = 5;
const BGPaddingTop = 50;

var public UIList List;
var public UIText Header;

simulated static function UIListPanel CreateListPanel(
	class<UIListPanel> ClassIn,
	UIPanel ParentPanelIn,
	name ListName,
	string ListTitle
)
{
	local UIListPanel This;

	This = ParentPanelIn.Spawn(ClassIn, ParentPanelIn);
	This.InitPanel();
	This.CreateList(ListName, ListTitle);

	return This;
}

simulated function UIList CreateList(name ListName, string ListTitle)
{
	List = Spawn(class'UIList', self);
	List.bStickyHighlight = false;
	List.bAutosizeItems = false;
	List.bAnimateOnInit = false;
	List.bSelectFirstAvailable = false;
	List.BGPaddingTop = BGPaddingTop;
	List.InitList(ListName, 0, BGPaddingTop, Width, Height, false, true, class'UIUtilities_Controls'.const.MC_X2Background);
	List.BG.SetSize(Width, Height);

	// this allows us to send mouse scroll events to the list
	List.BG.ProcessMouseEvents(List.OnChildMouseEvent);

	Header = Spawn(class'UIText', self).InitText('ListHeader');
	Header.SetPosition(Padding, Padding*2);
	Header.SetWidth(Width - Padding);
	Header.SetHtmlText(
		class'UIUtilities_Text'.static.AddFontInfo(
			class'UIUtilities_Text'.static.GetColoredText(ListTitle, eUIState_Header, class'UIUtilities_Text'.const.BODY_FONT_SIZE_2D),
			Screen.bIsIn3D,
			true,
			true
		)
	);

	return List;
}

simulated function Show()
{
	if(!bIsVisible)
	{
		Header.Show();
		List.Show();
		super.Show();
	}
}

simulated function Hide()
{
	if(bIsVisible)
	{
		Header.Hide();
		List.Hide();
		super.Hide();
	}
}

defaultProperties
{
	bAnimateOnInit = false;
	bIsNavigable = false;
	bCascadeFocus = false;
}