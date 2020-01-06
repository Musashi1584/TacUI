//-----------------------------------------------------------
//	Class:	UIArmory_LoadoutItem_TacUI
//	Author: Musashi
//	Based on Robojumpers Squadselect robojumper_UISquadSelect_EquipItem
//-----------------------------------------------------------
class UIArmory_LoadoutItem_TacUI extends UIPanel;

const EquipmentTextX = 10;
const EquipmentTextY = 0;
const CategoryTextX = 10;
const CategoryTextY = 32;

var bool IsLocked;
var bool IsInfinite;
var bool IsDisabled;

var bool bCanBeCleared;
var EInventorySlot EquipmentSlot; // only relevant if this item represents an equipment slot
var StateObjectReference ItemRef;
var X2ItemTemplate ItemTemplate;
var bool bLoadoutSlot;
var int ItemCount;

var UIList List;
var UIPanel ButtonBG;
var UIBGBox EquipmentTextBG, CategoryTextBG;
var UIPanel WeaponImageParent;
var array<UIImage> WeaponImages;
var array<UIIcon> WeaponUpgradeIcons;
var UIText EquipmentText;
var UIText CategoryText;
var UIMask ImageMask;

var array<string> strImagePaths;
var array<string> strCategoryImages;
var array<string> WeaponUpgradeNames;
var array<string> WeaponUpgradeDescs;

var string strItemText, strItemCategory;
var bool bDisabled;


// Override InitPanel to run important listItem specific logic
simulated function UIPanel InitPanel(optional name InitName, optional name InitLibID)
{
	super.InitPanel(InitName, InitLibID);

	List = UIList(GetParent(class'UIList', true)); // list items must be owned by UIList.ItemContainer
	if(List == none || List.bIsHorizontal)
	{
		ScriptTrace();
	}

	SetWidth(List.width);
	// for consistency, our panel is an EmptyControl without a default height
	MC.FunctionNum("setHeight", Height);

	ButtonBG = Spawn(class'UIPanel', self);
	ButtonBG.bAnimateOnInit = false;
	ButtonBG.bIsNavigable = false;
	ButtonBG.InitPanel('', 'X2Button');
	//ButtonBG.InitPanel('', 'X2BackgroundSimple');
	ButtonBG.SetSize(Width, Height);
	// we don't have a flash control so our BG has to raise mouse events
	ButtonBG.ProcessMouseEvents(OnChildMouseEvent);
	// only exists to give the mask a good control to mask
	WeaponImageParent = Spawn(class'UIPanel', self);
	WeaponImageParent.bIsNavigable = false;
	WeaponImageParent.bAnimateOnInit = false;
	WeaponImageParent.InitPanel();
	WeaponImageParent.SetAlpha(0.5);

	SpawnWeaponImages(1);

	ImageMask = Spawn(class'UIMask', self);
	ImageMask.bAnimateOnInit = false;
	ImageMask.InitMask('', WeaponImageParent);
	ImageMask.SetPosition(2, 2);
	ImageMask.SetSize(Width - 4, Height - 4);


	EquipmentTextBG = Spawn(class'UIBGBox', self);
	EquipmentTextBG.bAnimateOnInit = bAnimateOnInit;
	EquipmentTextBG.bIsNavigable = false;
	EquipmentTextBG.InitBG('EquipmentTextBG', EquipmentTextX, EquipmentTextY + 2);
	EquipmentTextBG.SetAlpha(0.5);

	EquipmentText = Spawn(class'UIText', self);
	EquipmentText.bAnimateOnInit = false;
	EquipmentText.InitText();
	EquipmentText.SetPosition(EquipmentTextX, EquipmentTextY);
	EquipmentText.SetWidth(Width - 20);
	ShadowToTextField(EquipmentText, 2, 10, 1);

	CategoryTextBG = Spawn(class'UIBGBox', self);
	CategoryTextBG.bAnimateOnInit = bAnimateOnInit;
	CategoryTextBG.bIsNavigable = false;
	CategoryTextBG.InitBG('CategoryTextBG', CategoryTextX, CategoryTextY + 2);
	CategoryTextBG.SetAlpha(0.5);
	CategoryTextBG.SetPanelScale(0.7);

	CategoryText = Spawn(class'UIText', self);
	CategoryText.bAnimateOnInit = false;
	CategoryText.InitText();
	CategoryText.SetPosition(CategoryTextX, CategoryTextY);
	CategoryText.SetPanelScale(0.7);
	ShadowToTextField(CategoryText, 2, 10, 1);

	return self;
}

simulated function onTextSizeRealized_EquipmentText()
{
	EquipmentTextBG.SetSize(EquipmentText.Width + 5, EquipmentText.Height);
}

simulated function onTextSizeRealized_CategoryText()
{
	CategoryTextBG.SetSize(CategoryText.Width * 0.75, CategoryText.Height * 0.7);
}

simulated function SpawnWeaponImages(int num)
{
	local int i;

	for (i = 0; i < num; i++)
	{
		if (i == WeaponImages.Length)
		{
			WeaponImages.AddItem(Spawn(class'UIImage', WeaponImageParent));
			WeaponImages[i].bAnimateOnInit = false;
			WeaponImages[i].InitImage('');
		}
		// haxhaxhax -- primary weapons are bigger than the others, which is normally handled by the image stack
		// but we need to do it manually
		if (EquipmentSlot == eInvSlot_PrimaryWeapon ||
			(X2WeaponTemplate(ItemTemplate) != none &&
				(X2WeaponTemplate(ItemTemplate).WeaponCat == 'pistol' ||
				 X2WeaponTemplate(ItemTemplate).WeaponCat == 'sidearm'))
		)
		{
			WeaponImages[i].SetPosition(102, -24);
			WeaponImages[i].SetSize(192, 96);
		}
		else
		{
			WeaponImages[i].SetPosition(70, -40);
			WeaponImages[i].SetSize(256, 128);
		}
		WeaponImages[i].Show();
	}
	for (i = num; i < WeaponImages.Length; i++)
	{
		WeaponImages[i].Hide();
	}
}

simulated function SpawnUpgradeIcons(int num)
{
	local int i;
	
	for (i = 0; i < num; i++)
	{
		if (i == WeaponUpgradeIcons.Length)
		{
			WeaponUpgradeIcons.AddItem(Spawn(class'UIIcon', self));
			WeaponUpgradeIcons[i].bIsNavigable = false;
			WeaponUpgradeIcons[i].bAnimateOnInit = false;
			WeaponUpgradeIcons[i].bCascadeFocus = true;
			WeaponUpgradeIcons[i].InitIcon('');
			WeaponUpgradeIcons[i].bDisableSelectionBrackets = true;
			WeaponUpgradeIcons[i].SetSize(20, 20);
			WeaponUpgradeIcons[i].SetPosition(width - 25 - ((i / 2) * 23), ((Height / 2) - (WeaponUpgradeIcons[i].Height + 3)) + ((i % 2) * 23));
			//WeaponUpgradeIcons[i].OnClickedDelegate = OnClickedUpgradeIcon;
		}
		WeaponUpgradeIcons[i].Show();
	}
	for (i = num; i < WeaponUpgradeIcons.Length; i++)
	{
		WeaponUpgradeIcons[i].Hide();
	}
}

simulated function UIArmory_LoadoutItem_TacUI InitLoadoutItem(
	XComGameState_Item Item,
	EInventorySlot InitEquipmentSlot,
	optional int DefaultWidth = -1
)
{	
	//bDisabled = bLocked;
	EquipmentSlot = InitEquipmentSlot;

	if (Item != none)
	{
		ItemRef = Item.GetReference();
		ItemTemplate = Item.GetMyTemplate();
	}

	strItemText = "";

	strImagePaths.Length = 0;
	strCategoryImages.Length = 0;
	
	strItemText = ItemTemplate.GetItemFriendlyName();

	if (!ItemTemplate.bInfiniteItem || Item.HasBeenModified())
	{
		strItemText @= "(" $ class'UIUtilities_Strategy'.static.GetXComHQ().GetNumItemInInventory(ItemTemplate.DataName) $ ")";
	}

	strItemCategory = class'X2TacUIHelper'.static.GetLocalizedCategory(ItemTemplate) @ "[" $ Item.GetMyTemplate().Tier $ "]";
	strImagePaths = Item.GetWeaponPanelImages();
		
	strCategoryImages.Length = 0;
	WeaponUpgradeNames.Length = 0;
	WeaponUpgradeDescs.Length = 0;
	GetUpgradeInfo(Item, EquipmentSlot, strCategoryImages, WeaponUpgradeNames, WeaponUpgradeDescs);

	if (!bIsInited)
	{
		InitPanel();
	}
	
	PopulateData();

	return self;
}

// one icon per upgrade!
simulated function GetUpgradeInfo(XComGameState_Item Item, EInventorySlot inEquipmentSlot, out array<string> Images, out array<string> Names, out array<string> Descs)
{
	local int i, j, totalslots, filledimages;
	local array<X2WeaponUpgradeTemplate> Upgrades;
	local string strBest;
	Upgrades = Item.GetMyWeaponUpgradeTemplates();
	for (i = 0; i < Upgrades.Length; i++)
	{
		strBest = "";
		if (Upgrades[i] != none)
		{
			for (j = 0; j < Upgrades[i].UpgradeAttachments.Length; j++)
			{
				if (Upgrades[i].UpgradeAttachments[j].InventoryCategoryIcon != "")
				{
					if (Upgrades[i].UpgradeAttachments[j].ApplyToWeaponTemplate == Item.GetMyTemplateName())
					{
						strBest = Upgrades[i].UpgradeAttachments[j].InventoryCategoryIcon;
						break; // j-loop
					}
					// fallback for when attachments don't have them properly set up for certain weapons
					strBest = Upgrades[i].UpgradeAttachments[j].InventoryCategoryIcon;
				}
			}
			if (strBest == "")
			{
				// indicate missing one by highlighting, grimy's loot mod tends to not have them be set up properly
				strBest = "img:///UILibrary_robojumperSquadSelect.implants_available";
			}
		}
		if (strBest == "")
		{
			// we don't have an upgrade there, show empty
			strBest = class'UIUtilities_Image'.const.PersonalCombatSim_Empty;
		}
		Images.AddItem(strBest);
		Names.AddItem(Upgrades[i].GetItemFriendlyName());
		Descs.AddItem(Item.GetUpgradeEffectForUI(Upgrades[i]));
		
	}
	// empty slots, but only if we are primary or the user wants to explicitely see them
	//if (inEquipmentSlot == eEquipmentSlot_PrimaryWeapon
	if (true == false)
	{
		// keep in sync with UIArmory_WeaponUpgrade.UpdateSlots(). Thanks Firaxis
		totalslots = 0;
		if (X2WeaponTemplate(Item.GetMyTemplate()) != none)
		{
			totalSlots = X2WeaponTemplate(Item.GetMyTemplate()).NumUpgradeSlots;
			// this is not checked in UIArmory_WeaponUpgrade but in UIArmory_MainMenu essentially (via UIUtilities_Strategy.GetWeaponUpgradeAvailability())
			if (totalSlots > 0)
			{
				if (`XCOMHQ.bExtraWeaponUpgrade)
				{
					totalSlots++;
				}
				if (`XCOMHQ.ExtraUpgradeWeaponCats.Find(X2WeaponTemplate(Item.GetMyTemplate()).WeaponCat) != INDEX_NONE)
				{
					totalSlots++;
				}
			}
		}
		filledimages = Images.Length;
		for (i = 0; i < totalslots - filledimages; i++)
		{
			Images.AddItem(class'UIUtilities_Image'.const.PersonalCombatSim_Empty);
			Names.AddItem("");
			Descs.AddItem("");
		}
	}
}

simulated function PopulateData()
{
	local int i;
	UpdateTexts();
	if (!bDisabled)
	{
		ButtonBG.MC.FunctionVoid("enable");
	}
	else
	{
		ButtonBG.MC.FunctionVoid("disable");
	}
	SpawnWeaponImages(strImagePaths.Length);
	for (i = strImagePaths.Length - 1; i >= 0; i--)
	{
		WeaponImages[i].LoadImage(strImagePaths[i]);
	}
	SpawnUpgradeIcons(strCategoryImages.Length);
	for (i = 0; i < strCategoryImages.Length; i++)
	{
		WeaponUpgradeIcons[i].LoadIcon(strCategoryImages[i]);
		if (WeaponUpgradeIcons[i].bHasTooltip)
		{
			WeaponUpgradeIcons[i].RemoveTooltip();
		}
		WeaponUpgradeIcons[i].SetTooltipText(WeaponUpgradeDescs[i], WeaponUpgradeNames[i]);
	}
	// don't have the text go behind the icons
	EquipmentText.SetWidth(Width - 10 - ((FCeil(float(strCategoryImages.Length) / 2.0)) * 25));
}

function string AddAppropriateColor(string InString)
{
	local string strColor;
	
	if (bDisabled)
		strColor = class'UIUtilities_Colors'.const.DISABLED_HTML_COLOR;
	else if (ItemRef.ObjectID == 0)
		strColor = class'UIUtilities_Colors'.const.WARNING_HTML_COLOR;
	//else if (bIsFocused)
	//	strColor = class'UIUtilities_Colors'.const.BLACK_HTML_COLOR;
	else
		strColor = class'UIUtilities_Colors'.const.NORMAL_HTML_COLOR;
		
	return "<font color='#" $ strColor $ "'>" $ InString $ "</font>";
}

function UpdateTexts()
{
	EquipmentText.SetText(AddAppropriateColor(strItemText), onTextSizeRealized_EquipmentText);
	CategoryText.SetSubTitle(AddAppropriateColor(Caps(strItemCategory)), onTextSizeRealized_CategoryText);
}

simulated function OnReceiveFocus()
{
	super.OnReceiveFocus();
	UpdateTexts();
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	UpdateTexts();
}

simulated function OnClickedUpgradeIcon()
{
	if (`XCOMHQ.bModularWeapons)
	{
		SetTimer(0.1f, false, nameof(GoToUpgradeScreen));
	}
}

simulated function GoToUpgradeScreen()
{
	if (!bDisabled)
	{
		`HQPRES.UIArmory_WeaponUpgrade(ItemRef);
	}
}

simulated function AnimateIn(optional float Delay = -1.0)
{
	WeaponImageParent.AddTweenBetween("_alpha", 0, WeaponImageParent.Alpha, class'UIUtilities'.const.INTRO_ANIMATION_TIME, Delay);
	WeaponImageParent.AddTweenBetween("_x", WeaponImageParent.X + 50, WeaponImageParent.X, class'UIUtilities'.const.INTRO_ANIMATION_TIME * 2, Delay, "easeoutquad");
	
	EquipmentText.AddTweenBetween("_alpha", 0, EquipmentText.Alpha, class'UIUtilities'.const.INTRO_ANIMATION_TIME, Delay);
	CategoryText.AddTweenBetween("_alpha", 0, CategoryText.Alpha, class'UIUtilities'.const.INTRO_ANIMATION_TIME, Delay);
}


simulated function OnChildMouseEvent(UIPanel control, int cmd)
{
	switch( cmd )
	{
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
		OnReceiveFocus();
		//SetNavigatorFocus();
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_OUT:
		OnLoseFocus();
		break;
	case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
		//OnClick();
		break;
	}
}

simulated function bool OnUnrealCommand(int cmd, int arg)
{
	local bool bHandled;

	if ( !CheckInputIsReleaseOrDirectionRepeat(cmd, arg) )
		return false;
	
	bHandled = true;
	switch (cmd)
	{
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			//OnClick();
			break;
		default:
			bHandled = false;
			break;
	}

	return bHandled || Navigator.OnUnrealCommand(cmd, arg);
}

static function ShadowToTextField(
	UIText Panel,
	int ShadowBlur = 3,
	int ShadowStrength = 15,
	float ShadowAlpha = 0.25
)
{
	local string Path;
	local UIMovie Mov;
	Path = string(Panel.MCPath) $ ".text";
	Mov = Panel.Movie;

	Mov.SetVariableString(Path $ ".shadowStyle", "s{0,0}{0,0){0,0}t{0,0}");
	Mov.SetVariableNumber(Path $ ".shadowColor", 0);
	Mov.SetVariableNumber(Path $ ".shadowBlurX", ShadowBlur);
	Mov.SetVariableNumber(Path $ ".shadowBlurY", ShadowBlur);
	Mov.SetVariableNumber(Path $ ".shadowStrength", ShadowStrength);
	Mov.SetVariableNumber(Path $ ".shadowAngle", 0);
	Mov.SetVariableNumber(Path $ ".shadowAlpha", ShadowAlpha);
	Mov.SetVariableNumber(Path $ ".shadowDistance", 0);
}

//simulated function SetNavigatorFocus()
//{
//	robojumper_UISquadSelect_ListItem(GetParent(class'robojumper_UISquadSelect_ListItem', true)).SetSelectedNavigation();
//	List.SetSelectedItem(self);
//}

defaultproperties
{
	height=65
	bAnimateOnInit=false
	bCascadeFocus = false
}