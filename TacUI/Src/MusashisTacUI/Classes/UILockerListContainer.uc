//-----------------------------------------------------------
//	Class:	UILockerListContainer
//	Author: Musashi	
//	
//-----------------------------------------------------------
class UILockerListContainer extends UIPanel;

simulated function OnInit()
{
	local UIBGBox BG;

	super.OnInit();
	
	BG = UIBGBox(GetChildByName('BG'));
	BG.SetSize(UIArmory_Loadout_TacUI(ParentPanel).LockerListWidth + 40, MC.GetNum("BG._height"));
}