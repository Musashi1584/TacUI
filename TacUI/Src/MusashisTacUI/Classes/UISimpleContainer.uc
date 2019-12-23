//-----------------------------------------------------------
//	Class:	UISimpleContainer
//	Author: Musashi
//	
//-----------------------------------------------------------
class UISimpleContainer extends UIPanel;

const Padding = 5;

var UIX2PanelHeader Header;
var UIBGBox PanelBG;

simulated static function UISimpleContainer CreateSimpleContainer(class<UISimpleContainer> ClassIn, UiPanel ParentPanelIn)
{
	local UISimpleContainer This;

	This = ParentPanelIn.Spawn(ClassIn, ParentPanelIn);

	This.InitPanel();

	//This.PanelBG = This.Spawn(class'UIBGBox', This);
	//This.PanelBG.LibID = class'UIUtilities_Controls'.const.MC_X2Background;
	//This.PanelBG.InitBG('theBG', 0, 0, This.Width, This.Height);
	//PanelBG.SetAlpha(PanelBGAlpha);

	//This.PanelBG = This.Spawn(class'UIBGBox', This);
	//This.PanelBG.InitBG();
	//This.PanelBG.SetSize(This.Width, This.Height);
	//
	//This.Header = This.Spawn(class'UIX2PanelHeader', This);
	//This.Header.InitPanelHeader();
	//This.Header.SetX(Padding);
	//This.Header.SetHeaderWidth(This.Width - Padding);
	
	return This;
}

simulated function Show()
{
	if(!bIsVisible)
	{
		PanelBG.Show();
		Header.Show();
		super.Show();
	}
}

simulated function Hide()
{
	if(bIsVisible)
	{
		PanelBG.Hide();
		Header.Hide();
		super.Hide();
	}
}


public simulated function UiPanel SetSize(float InWidth, float InHeight)
{
	Width = InWidth;
	Height = InHeight;
	PanelBG.SetSize(InWidth, InHeight);
	Header.SetHeaderWidth(InWidth - Padding); // padding left only

	return self;
}

defaultProperties
{
	bAnimateOnInit = false;
	bIsNavigable = false;
	bCascadeFocus = false;
}