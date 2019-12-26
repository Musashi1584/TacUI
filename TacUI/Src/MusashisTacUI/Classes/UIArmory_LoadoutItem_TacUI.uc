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
	optional string InitDisabledReason
)
{
	InitListItem();

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
	}

	UpdateDataValue(Title, Category);
}


simulated function UIArmory_LoadoutItem_TacUI SetLocked(bool Locked)
{
	//if(IsLocked != Locked)
	//{
	//	IsLocked = Locked;
	//	MC.FunctionBool("setLocked", IsLocked);
	//
	//	if(!IsLocked)
	//		OnLoseFocus();
	//}
	return self;
}


defaultproperties
{
	//width = 313;
	//height = 38;
	bAnimateOnInit = false
	LibID = "X2MechaListItem"
	bCascadeFocus = false
}