//-----------------------------------------------------------
//	Class:	DataStructures_TacUI
//	Author: Musashi
//	
//-----------------------------------------------------------
class DataStructures_TacUI extends Object;

struct TUILockerItemTacUI
{
	var bool CanBeEquipped;
	var string DisabledReason;
	var XComGameState_Item Item;
	var name ItemCategory;
	var name Tech;
	var string ItemCategoryLocalized;
	var string FriendlyNameLocalized;
};


struct TacUIFilters
{
	var string FilterKey;
	var EInventorySlot InventorySlot;
	var int UnitStateObjectID;
	var array<name> FilterNames;

	structdefaultproperties
	{
		UnitStateObjectID = -1;
	}
};

struct ProfileTime
{
	var name ProfileName;
	var float StartTime;
	var float EndTime;
	var float ElapsedTime;
};