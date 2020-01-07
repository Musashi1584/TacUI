//-----------------------------------------------------------
//	Class:	UIFilterCheckbox
//	Author: Musashi
//	
//-----------------------------------------------------------
class UIFilterCheckbox extends UIMechaListItem;

var privatewrite UIEventHandler OnCheckedChangedHandler;

public static function UIFilterCheckbox CreateCheckbox(
	UIList ParentPanelIn,
	name PanelName,
	optional string InitText,
	optional bool bInitChecked,
	optional bool bInitReadOnly,
	optional string ToolTipText
)
{
	local UIFilterCheckbox this;

	//this = UIFilterCheckbox(ParentPanelIn.CreateItem(class'UIFilterCheckbox'));
	this = ParentPanelIn.Spawn(class'UIFilterCheckbox', ParentPanelIn.ItemContainer);

	this.bAnimateOnInit = false;
	this.InitListItem(PanelName);
	this.SetWidgetType(EUILineItemType_Checkbox);
	this.UpdateDataCheckbox(InitText, "", bInitChecked, this.OnCheckboxChanged, this.OnClick);
	this.Checkbox.SetReadOnly(bInitReadOnly);
	//if (ToolTipText != "")
	//	this.BG.SetTooltipText(ToolTipText, , , 10, , , , 0.0f);
	
	this.OnCheckedChangedHandler = class'UIEventHandler'.static.CreateHandler();

	return this;
}

simulated function OnCheckboxChanged(UICheckbox CheckboxControl)
{
	//`LOG(default.class @ GetFuncName() @ `ShowVar(self.Desc.text) @ `ShowVar(CheckboxControl.bChecked) @ `ShowVar(self.OnCheckedChangedHandler),, 'TacUI');

	OnCheckedChangedHandler.Dispatch(self);
}

simulated function OnClick()
{
	//`LOG(default.class @ GetFuncName(),, 'TacUI');
	Checkbox.SetChecked(!Checkbox.bChecked, true);
}