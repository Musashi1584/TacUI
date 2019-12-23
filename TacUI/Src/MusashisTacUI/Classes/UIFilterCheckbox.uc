//-----------------------------------------------------------
//	Class:	UIFilterCheckbox
//	Author: Musashi
//	
//-----------------------------------------------------------
class UIFilterCheckbox extends UIMechaListItem;

public static function UIFilterCheckbox CreateCheckbox(
	UIList ParentPanelIn,
	optional string InitText,
	optional bool bInitChecked,
	optional delegate<OnCheckboxChangedCallback> StatusChangedDelegate,
	optional bool bInitReadOnly
)
{
	local UIFilterCheckbox this;

	this = UIFilterCheckbox(ParentPanelIn.CreateItem(class'UIFilterCheckbox'));
	this.bAnimateOnInit = false;
	this.InitListItem(name(InitText));
	this.SetWidgetType(EUILineItemType_Checkbox);
	this.UpdateDataCheckbox(InitText, "", bInitChecked, StatusChangedDelegate);
	//this.Checkbox.SetReadOnly(m_bIsPlayingGame);
	//this.BG.SetTooltipText(m_strDifficultyTutorialDesc, , , 10, , , , 0.0f);
	//this.InitCheckbox(InitName, InitText, bInitChecked, StatusChangedDelegate, bInitReadOnly);
	//this.SetTextStyle(class'UICheckbox'.const.STYLE_TEXT_ON_THE_RIGHT);
	
	return this;
}