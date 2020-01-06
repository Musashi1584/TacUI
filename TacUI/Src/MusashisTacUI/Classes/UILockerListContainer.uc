//-----------------------------------------------------------
//	Class:	UILockerListContainer
//	Author: Musashi	
//	
//-----------------------------------------------------------
class UILockerListContainer extends UIPanel;

simulated function OnInit()
{
	local UIBGBox BG;
	local UIPanel LoadoutList; 

	super.OnInit();

	BG = UIBGBox(GetChildByName('BG'));
	BG.SetSize(UIArmory_Loadout_TacUI(ParentPanel).LockerListWidth + 40, MC.GetNum("BG._height"));
	BG.SetPosition(MC.GetNum("BG._x") - 50, MC.GetNum("BG._y"));

	LoadoutList = GetChildByName('loadoutList');
	LoadoutList.SetPosition(MC.GetNum("loadoutList._x") - 50, MC.GetNum("loadoutList._y"));
}