//-----------------------------------------------------------
//	Class:	UIFilterCheckbox
//	Author: Musashi
//	
//-----------------------------------------------------------
class UIFilterCheckbox extends UIMechaListItem;

var privatewrite UIEventHandler OnCheckedChangedHandler;


public static function UIFilterCheckbox CreateCheckbox(
	UIList ParentPanelIn,
	optional string InitText,
	optional bool bInitChecked,
	optional bool bInitReadOnly,
	optional string ToolTipText
)
{
	local UIFilterCheckbox this;

	this = UIFilterCheckbox(ParentPanelIn.CreateItem(class'UIFilterCheckbox'));
	this.bAnimateOnInit = false;
	this.InitListItem(name(InitText));
	this.SetWidgetType(EUILineItemType_Checkbox);
	this.UpdateDataCheckboxTacUI(InitText, name(InitText), bInitChecked, none, OnClick);
	this.Checkbox.SetReadOnly(bInitReadOnly);
	if (ToolTipText != "")
		this.BG.SetTooltipText(ToolTipText, , , 10, , , , 0.0f);
	
	this.OnCheckedChangedHandler = class'UIEventHandler'.static.CreateHandler();
	this.Checkbox.onChangedDelegate = this.OnCheckboxChanged;

	return this;
}

simulated function UIMechaListItem UpdateDataCheckboxTacUI(string _CheckboxTitle,
									  name _CheckboxName,
									  bool bIsChecked,
									  delegate<OnCheckboxChangedCallback> _OnCheckboxChangedCallback = none,
									  optional delegate<OnClickDelegate> _OnClickDelegate = none)
{
	SetWidgetType(EUILineItemType_Checkbox);

	if( Checkbox == none )
	{
		Checkbox = Spawn(class'UICheckbox', self);
		Checkbox.bAnimateOnInit = false;
		Checkbox.bIsNavigable = false;
		Checkbox.LibID = class'UICheckbox'.default.AlternateLibID;
		Checkbox.InitCheckbox(_CheckboxName);
		Checkbox.SetX(width - 34);
		Desc.SetWidth(Width - 36);
		Checkbox.OnMouseEventDelegate = CheckboxMouseEvent;
	}

	OnClickDelegate = _OnClickDelegate;
	Checkbox.onChangedDelegate = _OnCheckboxChangedCallback;

	Checkbox.SetChecked(bIsChecked, false);
	Checkbox.Show();

	Desc.SetHTMLText(_CheckboxTitle);
	Desc.Show();

	return self;
}

simulated function OnCheckboxChanged(UICheckbox CheckboxControl)
{
	`LOG(default.class @ GetFuncName() @ `ShowVar(self.Desc.text) @ `ShowVar(CheckboxControl.bChecked) @ `ShowVar(self.OnCheckedChangedHandler),, 'TacUI');

	OnCheckedChangedHandler.Dispatch(self);
}

simulated function OnClick()
{
	Checkbox.SetChecked(!Checkbox.bChecked);
	`LOG(default.class @ GetFuncName() @ `ShowVar(Desc.text) @ `ShowVar(Checkbox.bChecked),, 'TacUI');
}