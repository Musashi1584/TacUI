//-----------------------------------------------------------
//	Class:	DataStructures_TacUI
//	Author: Musashi
//	
//-----------------------------------------------------------
class DataStructures_TacUI extends Object;

struct TacUIFilters
{
	var string FilterKey;
	var EInventorySlot InventorySlot;
	var int UnitStateObjectID;
	var array<name> CategoryFilters;

	structdefaultproperties
	{
		UnitStateObjectID = -1;
	}
};