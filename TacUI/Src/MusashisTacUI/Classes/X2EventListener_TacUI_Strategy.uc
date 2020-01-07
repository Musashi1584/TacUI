//-----------------------------------------------------------
//	Class:	X2EventListener_TacUI_Strategy
//	Author: Musashi
//	
//-----------------------------------------------------------
class X2EventListener_TacUI_Strategy extends X2EventListener;

static function array<X2DataTemplate> CreateTemplates()
{
	local array<X2DataTemplate> Templates;
	
	Templates.AddItem(CreateListenerTemplate_OnGetLocalizedCategory());

	return Templates;
}


static function CHEventListenerTemplate CreateListenerTemplate_OnGetLocalizedCategory()
{
	local CHEventListenerTemplate Template;

	`CREATE_X2TEMPLATE(class'CHEventListenerTemplate', Template, 'TacUIGetLocalizedCategory');

	Template.RegisterInTactical = true;
	Template.RegisterInStrategy = true;

	Template.AddCHEvent('GetLocalizedCategory', OnGetLocalizedCategory, ELD_Immediate);
	//`LOG("Register Event OnGetLocalizedCategory",, 'TacUI');

	return Template;
}

static function EventListenerReturn OnGetLocalizedCategory(Object EventData, Object EventSource, XComGameState GameState, Name Event, Object CallbackData)
{
	local XComLWTuple Tuple;
	local X2WeaponTemplate Template;
	local string Localization;

	Tuple = XComLWTuple(EventData);
	Template = X2WeaponTemplate(EventSource);

	Localization = class'X2TacUIHelper'.static.LocalizeCategory(Template.WeaponCat);

	if (Localization != "")
	{
		Tuple.Data[0].s = Localization;
		EventData = Tuple;
	}

	return ELR_NoInterrupt;
}