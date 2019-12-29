//-----------------------------------------------------------
//	Class:	UIArmory_LoadoutItem
//	Author: Musashi
//	
//-----------------------------------------------------------
class UIArmory_LoadoutItem_TacUI extends UIMechaListItem;

var bool IsLocked;
var bool IsInfinite;
var bool IsDisabled;

var bool bCanBeCleared;
var EInventorySlot EquipmentSlot; // only relevant if this item represents an equipment slot
var StateObjectReference ItemRef;
var X2ItemTemplate ItemTemplate;
var bool bLoadoutSlot;
var int ItemCount;

simulated function UIArmory_LoadoutItem_TacUI InitLoadoutItem(
	XComGameState_Item Item,
	EInventorySlot InitEquipmentSlot,
	optional bool InitSlot,
	optional string InitDisabledReason,
	optional int DefaultWidth = -1
)
{
	InitListItem(, DefaultWidth, DefaultWidth - 120);

	if (Item != none)
	{
		ItemRef = Item.GetReference();
		ItemTemplate = Item.GetMyTemplate();
	}
	
	EquipmentSlot = InitEquipmentSlot;

	if(InitSlot)
	{
		bLoadoutSlot = true;
		// Issue #118
		//SetSlotType(class'UIArmory_Loadout'.default.m_strInventoryLabels[int(InitEquipmentSlot)]);
		//SetSlotType(class'CHItemSlot'.static.SlotGetName(InitEquipmentSlot));
	}
	PopulateData();

	return self;
}

simulated function PopulateData(optional XComGameState_Item Item)
{
	local string Title;
	local string Category;
	local array<string> AttachmentIcons;
	local string Icon, Buffer;

	if(Item == None)
		Item = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ItemRef.ObjectID));

	Category = string(class'X2TacUIHelper'.static.GetItemCategory(Item));

	Title = ItemTemplate != none ? ItemTemplate.GetItemFriendlyName(Item.ObjectID) : "";

	//TacticalText = ItemTemplate != none ? ItemTemplate.GetItemTacticalText() : "";
	if (Item != None)
	{
		if (ItemTemplate.bInfiniteItem && !Item.HasBeenModified())
		{
			//SetInfinite(true);
		}
		else
		{
			Title @= "(" $ class'UIUtilities_Strategy'.static.GetXComHQ().GetNumItemInInventory(ItemTemplate.DataName) $ ")";
		}

		if (Item.GetMyWeaponUpgradeCount() > 0)
		{
			AttachmentIcons = Item.GetMyWeaponUpgradeTemplatesCategoryIcons();
			Buffer = "";

			foreach AttachmentIcons(Icon)
			{
				Buffer $= class'UIUtilities_Text'.static.InjectImage(Icon, 26, 26, -4);
			}

			Title @= Buffer;

			//class'UIUtilities_Text'.static.InjectImage(class'UIUtilities_Image'.const.HTML_AttentionIcon, 26, 26, -4);
		}
		
	}

	UpdateDataValue(Title, Category);
}


defaultproperties
{
	//LibID = "X2MechaListItem"
	bAnimateOnInit = false
	bCascadeFocus = false
}