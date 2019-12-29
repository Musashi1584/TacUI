//-----------------------------------------------------------
//	Class:	UIArmory_Loadout_TacUI
//	Author: Musashi
//	
//-----------------------------------------------------------
class UIArmory_Loadout_TacUI extends UIArmory_Loadout;

struct TUILockerItemTacUI
{
	var bool CanBeEquipped;
	var string DisabledReason;
	var XComGameState_Item Item;
	var name ItemCategory;
};

const LockerListWidth = 460;

var bool bLoadAll, bLoadFilters;
var EInventorySlot SelectedSlot;
var array<TUILockerItemTacUI> LockerItems;
var array<name> ActiveItemCategories;
var UIItemCategoryFilterPanel ItemCategoryFilterPanel;
var array<UIArmory_LoadoutItem_TacUI> LoadoutItems;
var private int LazyLoadIndex;

simulated function InitArmory(StateObjectReference UnitRef, optional name DispEvent, optional name SoldSpawnEvent, optional name NavBackEvent, optional name HideEvent, optional name RemoveEvent, optional bool bInstant = false, optional XComGameState InitCheckGameState)
{
	bLoadFilters = true;

	Movie.PreventCacheRecycling();

	super(UIArmory).InitArmory(UnitRef, DispEvent, SoldSpawnEvent, NavBackEvent, HideEvent, RemoveEvent, bInstant, InitCheckGameState);

	LocTag = XGParamTag(`XEXPANDCONTEXT.FindTag("XGParam"));

	InitializeTooltipData();
	InfoTooltip.SetPosition(1250, 430);

	MC.FunctionString("setLeftPanelTitle", m_strInventoryTitle);

	EquippedListContainer = Spawn(class'UIPanel', self);
	EquippedListContainer.bAnimateOnInit = false;
	EquippedListContainer.InitPanel('leftPanel');
	EquippedList = CreateList(EquippedListContainer);
	EquippedList.OnSelectionChanged = OnSelectionChanged;
	EquippedList.OnItemClicked = OnItemClicked;
	EquippedList.OnItemDoubleClicked = OnItemClicked;

	LockerListContainer = Spawn(class'UILockerListContainer', self);
	LockerListContainer.bAnimateOnInit = false;
	LockerListContainer.InitPanel('rightPanel');
	LockerList = CreateLockerList(LockerListContainer);
	LockerList.OnSelectionChanged = OnSelectionChanged;
	LockerList.OnItemClicked = OnItemClicked;
	LockerList.OnItemDoubleClicked = OnItemClicked;
	
	PopulateData();

	CreateItemCategoryFilterPanel();

	bLoadAll = true;
}

simulated function PopulateData()
{
	CreateSoldierPawn();
	UpdateEquippedList();
	//UpdateLockerList();
	ChangeActiveList(EquippedList, true);
}

simulated static function UIList CreateLockerList(UIPanel Container)
{
	local UIBGBox BG;
	local UIList ReturnList;

	BG = Container.Spawn(class'UIBGBox', Container);
	BG.InitBG('BG');

	ReturnList = Container.Spawn(class'UIList', Container);
	ReturnList.bStickyHighlight = false;
	ReturnList.bAutosizeItems = false;
	ReturnList.bAnimateOnInit = false;
	ReturnList.bSelectFirstAvailable = false;
	ReturnList.ItemPadding = 5;
	ReturnList.InitList('loadoutList', 0, 0, LockerListWidth,, false, false, class'UIUtilities_Controls'.const.MC_X2Background);

	// this allows us to send mouse scroll events to the list
	BG.ProcessMouseEvents(ReturnList.OnChildMouseEvent);
	return ReturnList;
}

simulated function CreateItemCategoryFilterPanel()
{
	ItemCategoryFilterPanel = class'UIItemCategoryFilterPanel'.static.CreateItemCategoryFilterPanel(
		LockerListContainer
	);
	ItemCategoryFilterPanel.SetPosition(LockerListWidth + 50, 0);
	//ItemCategoryFilterPanel.SetSize(203, 230);
	//ItemCategoryFilterPanel.SetPanelScale(0.7);
	ItemCategoryFilterPanel.Hide();
}

simulated function ChangeActiveList(UIList kActiveList, optional bool bSkipAnimation)
{
	local bool bEquppedList;
	
	bEquppedList = kActiveList == EquippedList;

	if(bEquppedList)
	{
		ReleaseAllPawns();
		CreateSoldierPawn();
		ItemCategoryFilterPanel.Hide();
		LockerList.DisableNavigation();
	}
	else
	{
		ReleaseAllPawns();
		ItemCategoryFilterPanel.Show();
		SetFirstVisibleIndex(LockerList);
		LockerList.EnableNavigation();
		LockerList.Navigator.SelectFirstAvailable();
	}


	`LOG(default.class @ GetFuncName() @ `ShowVar(bEquppedList) @ PawnLocationTag,, 'TacUI');

	super.ChangeActiveList(kActiveList, bSkipAnimation);
}

simulated function UpdateLockerList()
{
	local XComGameState_Item Item;
	local StateObjectReference ItemRef;
	local TUILockerItemTacUI LockerItem;
	local array<StateObjectReference> Inventory;
	local int Index;
	local TacUIFilters FilterState;
	local UIArmory_LoadoutItem_TacUI LoadoutItem;

	LockerList.SetWidth(LockerListWidth);
	
	`LOG(default.class @ GetFuncName() @ "Start",, 'TacUI');
	bLoadAll = false;

	SelectedSlot = GetSelectedSlot();

	// set title according to selected slot
	// Issue #118
	LocTag.StrValue0 = class'CHItemSlot'.static.SlotGetName(SelectedSlot);
	//LocTag.StrValue0 = m_strInventoryLabels[SelectedSlot];
	MC.FunctionString("setRightPanelTitle", `XEXPAND.ExpandString(m_strLockerTitle));

	GetInventory(Inventory);
	LockerItems.Length = 0;
	ActiveItemCategories.Length = 0;

	FilterState = GetFilterState();

	`LOG(default.class @ GetFuncName() @ "Gather Data Start",, 'TacUI');

	foreach Inventory(ItemRef)
	{
		Item = GetItemFromHistory(ItemRef.ObjectID);

		if (Item == none)
		{
			continue;
		}

		if(ShowInLockerList(Item, SelectedSlot) || bLoadAll)
		{
			LockerItem.Item = Item;
			LockerItem.DisabledReason = GetDisabledReason(Item, SelectedSlot);
			LockerItem.CanBeEquipped = LockerItem.DisabledReason == ""; // sorting optimization
			LockerItem.ItemCategory = class'X2TacUIHelper'.static.GetItemCategory(Item);
			if (LockerItem.CanBeEquipped)
			{
				// Collect all categories
				if (ActiveItemCategories.Find(LockerItem.ItemCategory) == INDEX_NONE)
				{
					ActiveItemCategories.AddItem(LockerItem.ItemCategory);
				}

				LockerItems.AddItem(LockerItem);
			}
		}
	}

	if (bLoadFilters)
		ItemCategoryFilterPanel.AddFilters(ActiveItemCategories, SelectedSlot);

	//LockerList.ClearItems();

	LockerItems.Sort(SortLockerListByUpgradesTacUI);
	LockerItems.Sort(SortLockerListByTierTacUI);
	LockerItems.Sort(SortLockerListByEquipTacUI);

	`LOG(default.class @ GetFuncName() @ "Gather Data End",, 'TacUI');
	// Dont clear the list for perfomance reasons, just hide the items
	if (LockerList.GetItemCount() > 0)
		HideAllLoadoutItems();

	`LOG(default.class @ GetFuncName() @ "Update UI Items Start",, 'TacUI');
	//for (Index = LockerItems.Length - 1; Index >= 0; Index--)
	for (Index = 0; Index < LockerItems.Length; Index++)
	{
		LockerItem = LockerItems[Index];

		if (!bLoadAll &&
			FilterState.CategoryFilters.Length > 0 &&
			FilterState.CategoryFilters.Find(LockerItem.ItemCategory) == INDEX_NONE)
		{
			continue;
		}

		LoadoutItem = FindItemById(LockerItem.Item.ObjectID);

		if (LoadoutItem != none)
		{
			LoadoutItem.Show();
			LoadoutItem.PopulateData(LockerItem.Item);
			//`LOG(default.class @ GetFuncName() @ "Update"  @ Index @ LockerItem.Item.GetMyTemplateName() @ LoadoutItem.Width @ LoadoutItem.IsVisible(),, 'TacUI');
		}
		else
		{
			LoadoutItem = UIArmory_LoadoutItem_TacUI(LockerList.CreateItem(class'UIArmory_LoadoutItem_TacUI'));
			LoadoutItem.InitLoadoutItem
			(
				LockerItem.Item,
				SelectedSlot,
				false,
				LockerItem.DisabledReason,
				LockerListWidth
			);
			//`LOG(default.class @ GetFuncName() @ "Create"  @ Index @ LockerItem.Item.GetMyTemplateName() @ LoadoutItem.Width @ LoadoutItem.IsVisible(),, 'TacUI');
		}
	}
	//LockerList.SetWidth(LockerListWidth);//538;
	RealizeItems();
	LockerList.RealizeList();
	`LOG(default.class @ GetFuncName() @ "Update UI Items End",, 'TacUI');

	// If we have an invalid SelectedIndex, just try and select the first thing that we can.
	// Otherwise let's make sure the Navigator is selecting the right thing.
	if(LockerList.SelectedIndex < 0 || LockerList.SelectedIndex >= LockerList.ItemCount)
		LockerList.Navigator.SelectFirstAvailable();
	else
	{
		LockerList.Navigator.SetSelected(LockerList.GetSelectedItem());
	}
	OnSelectionChanged(ActiveList, ActiveList.SelectedIndex);
}

simulated function RealizeItems(optional int StartingIndex)
{
	local int i;
	local float NextItemPosition;
	local UIPanel Item;

	if(StartingIndex > 0)
	{
		Item = LockerList.GetItem(StartingIndex - 1);
		if (Item != none && Item.bIsVisible)
		{
			if (LockerList.bIsHorizontal)
				NextItemPosition = Item.X + Item.Width + LockerList.ItemPadding;
			else
				NextItemPosition = Item.Y + Item.Height + LockerList.ItemPadding;
		}
	}

	for(i = StartingIndex; i < LockerList.ItemCount; ++i)
	{
		Item = LockerList.GetItem(i);
		if (Item != none && Item.bIsVisible)
		{
			if (LockerList.bIsHorizontal)
			{
				Item.SetX(NextItemPosition);
				NextItemPosition += Item.Width + (i < LockerList.ItemCount - 1) ? LockerList.ItemPadding : 0;
			}
			else
			{
				Item.SetY(NextItemPosition);
				NextItemPosition += Item.Height + (i < LockerList.ItemCount - 1) ? LockerList.ItemPadding : 0;
			}
		}
	}

	LockerList.TotalItemSize = NextItemPosition + LockerList.ItemWidthBuffer;
}

simulated function UIArmory_LoadoutItem_TacUI FindItemById(int ObjectID)
{
	local UIArmory_LoadoutItem_TacUI LoadoutItem;
	local int Index;

	for(Index = 0; Index < LockerList.GetItemCount(); ++ Index)
	{
		LoadoutItem = UIArmory_LoadoutItem_TacUI(LockerList.ItemContainer.ChildPanels[Index]);
		if(LoadoutItem != none && LoadoutItem.ItemRef.ObjectID == ObjectID)
		{
			return LoadoutItem;
		}
	}
	return none;
}

simulated function HideAllLoadoutItems()
{
	local UIArmory_LoadoutItem_TacUI LoadoutItem;
	local int Index;

	`LOG(default.class @ GetFuncName() @ "Start",, 'TacUI');
	for(Index = 0; Index < LockerList.GetItemCount(); ++ Index)
	{
		LoadoutItem = UIArmory_LoadoutItem_TacUI(LockerList.ItemContainer.ChildPanels[Index]);
		if(LoadoutItem != none)
		{
			LoadoutItem.Hide();
		}
	}
	`LOG(default.class @ GetFuncName() @ "End",, 'TacUI');
	//LockerList.RealizeItems();
	//LockerList.RealizeList();
}


simulated function OnSelectionChanged(UIList ContainerList, int ItemIndex)
{
	local UIArmory_LoadoutItem_TacUI ContainerSelection;
	local UIArmory_LoadoutItem EquippedSelection;
	local StateObjectReference EmptyRef, ContainerRef, EquippedRef;
	local XComGameState_Item ItemState;

	ContainerSelection = UIArmory_LoadoutItem_TacUI(ContainerList.GetSelectedItem());
	EquippedSelection = UIArmory_LoadoutItem(EquippedList.GetSelectedItem());

	ContainerRef = ContainerSelection != none ? ContainerSelection.ItemRef : EmptyRef;
	EquippedRef = EquippedSelection != none ? EquippedSelection.ItemRef : EmptyRef;

	if((ContainerSelection == none) || !ContainerSelection.IsDisabled)
		Header.PopulateData(GetUnit(), ContainerRef, EquippedRef);

	if (ContainerSelection != none && ContainerRef != EmptyRef)
	{
		ItemState = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ContainerRef.ObjectID));
		CreateItemPawn(ItemState);
	}
	else if(ContainerSelection != none)
	{
		ReleaseAllPawns();
	}

	InfoTooltip.HideTooltip();

	if(`ISCONTROLLERACTIVE)
	{
		ClearTimer(nameof(DelayedShowTooltip));
		SetTimer(0.21f, false, nameof(DelayedShowTooltip));
	}
	UpdateNavHelp();
}


simulated function OnCancel()
{
	if(ActiveList == EquippedList)
	{
		`LOG(default.class @ GetFuncName() @ "EquppedList" @ PawnLocationTag,, 'TacUI');

		ReleaseAllPawns();
		CreateSoldierPawn();

		// If we are in the tutorial and came from squad select when the medikit objective is active, don't allow backing out
		//if (!Movie.Pres.ScreenStack.HasInstanceOf(class'UISquadSelect') || class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M5_EquipMedikit') != eObjectiveState_InProgress)
		//{
		//	ActorPawn.SetHidden(true);
		//	ReleasePawn(true);
		//	PawnLocationTag = 'UIPawnLocation_Armory';
		//	CreateSoldierPawn();
		//	ActorPawn.SetHidden(false);
		//}
	}
	super.OnCancel(); // exits screen
}

simulated function ReleaseAllPawns()
{
	local int i;
	local UIArmory_Loadout_TacUI ArmoryScreen;
	local UIScreenStack ScreenStack;

	`LOG(default.class @ GetFuncName(),, 'TacUI');

	ScreenStack = `SCREENSTACK;
	for(i = ScreenStack.Screens.Length - 1; i >= 0; --i)
	{
		ArmoryScreen = UIArmory_Loadout_TacUI(ScreenStack.Screens[i]);
		if(ArmoryScreen != none)
		{
			ArmoryScreen.ReleasePawn(true);
		}
	}
}


simulated function CreateItemPawn(XComGameState_Item Item, optional Rotator DesiredRotation)
{
	local Rotator NoneRotation;
	local XGWeapon WeaponVisualizer;
	
	// Make sure to clean up Item actors left over from previous Armory screens.
	if(ActorPawn == none)
		ActorPawn = UIArmory(Movie.Stack.GetLastInstanceOf(class'UIArmory')).ActorPawn;

	// Clean up previous Item actor
	if( ActorPawn != none )
		ActorPawn.Destroy();

	WeaponVisualizer = XGWeapon(Item.GetVisualizer());
	if( WeaponVisualizer != none )
	{
		WeaponVisualizer.Destroy();
	}

	if (X2GremlinTemplate(Item.GetMyTemplate()) != none)
	{
		//@TODO Fix me i am broken
		//ActorPawn = Movie.Pres.GetUIPawnMgr().GetCosmeticPawn(eInvSlot_SecondaryWeapon, UnitReference.ObjectID);
	}
	else
	{
		class'XGItem'.static.CreateVisualizer(Item);
		WeaponVisualizer = XGWeapon(Item.GetVisualizer());
		ActorPawn = WeaponVisualizer.GetEntity();
	}

	if (ActorPawn != none)
	{
		PawnLocationTag = X2WeaponTemplate(Item.GetMyTemplate()).UIArmoryCameraPointTag;

		if (PawnLocationTag == '')
			PawnLocationTag = 'UIPawnLocation_WeaponUpgrade_Shotgun';

		if(DesiredRotation == NoneRotation)
			DesiredRotation = GetPlacementActor().Rotation;

		ActorPawn.SetLocation(GetPlacementActor().Location);
		ActorPawn.SetRotation(DesiredRotation);
		if (X2WeaponTemplate(Item.GetMyTemplate()) != none)
		{
			ActorPawn.SetDrawScale(0.4);
		}
		ActorPawn.SetHidden(false);
	}

	`LOG(default.class @ GetFuncName() @ ActorPawn @ PawnLocationTag,, 'TacUI');
}

simulated function OnItemClicked(UIList ContainerList, int ItemIndex)
{
	if(ContainerList != ActiveList) return;

	if(UIArmory_LoadoutItem(ContainerList.GetItem(ItemIndex)).IsDisabled)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClickNegative);
		return;
	}

	if(ContainerList == EquippedList)
	{
		UpdateLockerList();
		ChangeActiveList(LockerList);
	}
	else
	{
		ChangeActiveList(EquippedList);

		if(EquipItemOveride(UIArmory_LoadoutItem_TacUI(LockerList.GetSelectedItem())))
		{
			// Release soldier pawn to force it to be re-created when armor changes
			
			UpdateDataTacUI(true, false);
			
			if(bTutorialJumpOut && Movie.Pres.ScreenStack.HasInstanceOf(class'UISquadSelect'))
			{
				OnCancel();
			}
		}
		
		if (EquippedList.SelectedIndex < 0)
		{
			EquippedList.SetSelectedIndex(0);
		}
	}
}

simulated function UpdateDataTacUI(
	optional bool bRefreshPawn,
	optional bool bUpdateLockerList = true,
	optional bool bUpdateEquippedList = true)
{
	local Rotator CachedSoldierRotation;

	CachedSoldierRotation = ActorPawn.Rotation;

	// Release soldier pawn to force it to be re-created when armor changes
	if(bRefreshPawn)
		ReleaseAllPawns();

	if (bUpdateLockerList)
	{
		UpdateLockerList();
	}
	if (bUpdateEquippedList)
	{
		UpdateEquippedList();
	}
	
	CreateSoldierPawn(CachedSoldierRotation);

	Header.PopulateData(GetUnit());

	if (bRefreshPawn && `GAME != none)
	{
		`GAME.GetGeoscape().m_kBase.m_kCrewMgr.TakeCrewPhotobgraph(GetUnit().GetReference(), true);
	}
}

simulated function CreateSoldierPawn(optional Rotator DesiredRotation)
{
	local Rotator NoneRotation;
	local XComLWTuple OverrideTuple; //for issue #229
	local float CustomScale; // issue #229
	// Don't do anything if we don't have a valid UnitReference
	if( UnitReference.ObjectID == 0 ) return;

	if( DesiredRotation == NoneRotation )
	{
		if( ActorPawn != none )
			DesiredRotation = ActorPawn.Rotation;
		else
			DesiredRotation.Yaw = -16384;
	}

	RequestPawn(DesiredRotation);
	LoadSoldierEquipment();
	
	//start issue #229: instead of boolean check, always trigger event to check if we should use custom unit scale.
	CustomScale = GetUnit().UseLargeArmoryScale() ? LargeUnitScale : 1.0f;

	//set up a Tuple for return value
	OverrideTuple = new class'XComLWTuple';
	OverrideTuple.Id = 'OverrideUIArmoryScale';
	OverrideTuple.Data.Add(3);
	OverrideTuple.Data[0].kind = XComLWTVBool;
	OverrideTuple.Data[0].b = false;
	OverrideTuple.Data[1].kind = XComLWTVFloat;
	OverrideTuple.Data[1].f = CustomScale;
	OverrideTuple.Data[2].kind = XComLWTVObject;
	OverrideTuple.Data[2].o = GetUnit();
	`XEVENTMGR.TriggerEvent('OverrideUIArmoryScale', OverrideTuple, GetUnit(), none);
	
	//if the unit should use the large armory scale by default, then either they'll use the default scale
	//or a custom one given by a mod according to their character template
	if(OverrideTuple.Data[0].b || GetUnit().UseLargeArmoryScale()) 
	{
		CustomScale = OverrideTuple.Data[1].f;
		XComUnitPawn(ActorPawn).Mesh.SetScale(CustomScale);
	}
	//end issue #229

	// Prevent the pawn from obstructing mouse raycasts that are used to determine the position of the mouse cursor in 3D screens.
	XComHumanPawn(ActorPawn).bIgnoreFor3DCursorCollision = true;

	UIMouseGuard_RotatePawn(`SCREENSTACK.GetFirstInstanceOf(class'UIMouseGuard_RotatePawn')).SetActorPawn(ActorPawn);
}

// Override function to RequestPawnByState instead of RequestPawnByID
simulated function RequestPawn(optional Rotator DesiredRotation)
{
	`LOG(default.class @ GetFuncName(),, 'TacUI');

	PawnLocationTag = 'UIPawnLocation_Armory';
	
	ActorPawn = Movie.Pres.GetUIPawnMgr().RequestPawnByState(self, GetUnit(), GetPlacementActor().Location, DesiredRotation);
	ActorPawn.GotoState('CharacterCustomization');
}

simulated function ReleasePawn(optional bool bForce)
{
	ActorPawn.SetHidden(true);
	Movie.Pres.GetUIPawnMgr().ReleasePawn(self, UnitReference.ObjectID, bForce);
	ActorPawn = none;
}

simulated function bool EquipItemOveride(UIArmory_LoadoutItem_TacUI Item)
{
	local UIArmory_LoadoutItem ItemDummy;
	local bool bResult;

	ItemDummy = Spawn(class'UIArmory_LoadoutItem', self);
	ItemDummy.Hide();

	ItemDummy.ItemRef = Item.ItemRef;
	ItemDummy.ItemTemplate = Item.ItemTemplate;

	bResult =  EquipItem(ItemDummy);
	RemoveChild(ItemDummy);
	return bResult;
}


simulated function XComGameState_Item TooltipRequestItemFromPath(string currentPath)
{
	local string ItemName, TargetList;
	local array<string> Path;
	local UIArmory_LoadoutItem Item;
	local UIArmory_LoadoutItem_TacUI ItemTacUI;

	Path = SplitString( currentPath, "." );	

	foreach Path(TargetList)
	{
		//Search the path for the target list matchup
		if( TargetList == string(ActiveList.MCName) )
		{
			ItemName = Path[Path.length-1];
			
			// if we've highlighted the DropItemButton, account for it in the path name
			if(ItemName == "bg")
				ItemName = Path[Path.length-3];
			if(ItemName == "mechaBG")
				ItemName = Path[Path.length-2];

			Item =  UIArmory_LoadoutItem(ActiveList.GetItemNamed(Name(ItemName)));
			
			if(Item == none)
			{
				ItemTacUI = UIArmory_LoadoutItem_TacUI(ActiveList.GetItemNamed(Name(ItemName)));
				return GetItemFromHistory(ItemTacUI.ItemRef.ObjectID); 
			}

			if(Item != none)
				return GetItemFromHistory(Item.ItemRef.ObjectID); 
		}
	}
	
	//Else we never found a target list + item
	`log("Problem in UIArmory_Loadout for the UITooltip_InventoryInfo: couldn't match the active list at position -4 in this path: " $currentPath,,'uixcom');
	return none;
}

simulated function ResetAvailableEquipment()
{
	local XComGameState_Unit UnitState;
	local XComGameState NewGameState;
	local int idx;

	bGearStripped = false;
	bItemsStripped = false;
	bWeaponsStripped = false;

	if(StrippedUnits.Length > 0)
	{
		NewGameState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Reset Available Equipment");

		for(idx = 0; idx < StrippedUnits.Length; idx++)
		{
			UnitState = XComGameState_Unit(NewGameState.ModifyStateObject(class'XComGameState_Unit', StrippedUnits[idx].ObjectID));
			UnitState.EquipOldItems(NewGameState);
		}

		`GAMERULES.SubmitGameState(NewGameState);
	}

	StrippedUnits.Length = 0;
	UpdateNavHelp();
	//UpdateLockerList();
}

simulated function SetFirstVisibleIndex(UIList List)
{
	local int Index;
	local UIPanel ListItem;

	List.ClearSelection();

	for (Index = 0; Index < List.GetItemCount(); Index++)
	{
		ListItem = List.GetItem(Index);
		if (ListItem.IsVisible())
		{
			List.SetSelectedIndex(Index, true);
			return;
		}
	}
}

simulated function TacUIFilters GetFilterState()
{
	local XComGameState_LoadoutFilter LoadoutFilterGameState;

	LoadoutFilterGameState = class'XComGameState_LoadoutFilter'.static.GetLoadoutFilterGameState();
	return LoadoutFilterGameState.GetFilter(UnitReference.ObjectID, SelectedSlot);
}



simulated function int SortLockerListByEquipTacUI(TUILockerItemTacUI A, TUILockerItemTacUI B)
{
	if(A.CanBeEquipped && !B.CanBeEquipped) return 1;
	else if(!A.CanBeEquipped && B.CanBeEquipped) return -1;
	else return 0;
}

simulated function int SortLockerListByTierTacUI(TUILockerItemTacUI A, TUILockerItemTacUI B)
{
	local int TierA, TierB;

	TierA = A.Item.GetMyTemplate().Tier;
	TierB = B.Item.GetMyTemplate().Tier;

	if (TierA > TierB) return 1;
	else if (TierA < TierB) return -1;
	else return 0;
}

simulated function int SortLockerListByUpgradesTacUI(TUILockerItemTacUI A, TUILockerItemTacUI B)
{
	local int UpgradesA, UpgradesB;

	// Start Issue #306
	UpgradesA = A.Item.GetMyWeaponUpgradeCount();
	UpgradesB = B.Item.GetMyWeaponUpgradeCount();
	// End Issue #306

	if (UpgradesA > UpgradesB)
	{
		return 1;
	}
	else if (UpgradesA < UpgradesB)
	{
		return -1;
	}
	else
	{
		return 0;
	}
}


auto state LazyLoadAll
{

	function LoadInventory()
	{
		local XComGameState_Item Item;
		local StateObjectReference ItemRef;
		local TUILockerItemTacUI LockerItem;
		local array<StateObjectReference> Inventory;
		

		if (bLoadAll)
		{
			LockerItems.Length = 0;
			GetInventory(Inventory);

			foreach Inventory(ItemRef)
			{
				Item = GetItemFromHistory(ItemRef.ObjectID);

				if (Item != none)
				{
					LockerItem.Item = Item;
					LockerItem.DisabledReason = GetDisabledReason(Item, SelectedSlot);
					LockerItem.CanBeEquipped = LockerItem.DisabledReason == ""; // sorting optimization
					LockerItem.ItemCategory = class'X2TacUIHelper'.static.GetItemCategory(Item);
					if (LockerItem.CanBeEquipped)
					{
						LockerItems.AddItem(LockerItem);
					}
				}
			}

			LockerItems.Sort(SortLockerListByUpgradesTacUI);
			LockerItems.Sort(SortLockerListByTierTacUI);
			LockerItems.Sort(SortLockerListByEquipTacUI);
		}
	}

	function LazyLoadUIItems(int Index)
	{
		local TUILockerItemTacUI LockerItem;
		local UIArmory_LoadoutItem_TacUI LoadoutItem;
		
		LockerItem = LockerItems[Index];

		LoadoutItem = UIArmory_LoadoutItem_TacUI(LockerList.CreateItem(class'UIArmory_LoadoutItem_TacUI'));
		LoadoutItem.InitLoadoutItem
		(
			LockerItem.Item,
			eInvSlot_PrimaryWeapon,
			false,
			LockerItem.DisabledReason
		);
		//LockerList.MoveItemToBottom(LoadoutItem);
		LoadoutItem.Hide();
		`LOG(default.class @ GetFuncName() @ Index @ LockerItem.Item.GetMyTemplateName() @ LoadoutItem.Width,, 'TacUI');
	}


Begin:
	//LazyLoadIndex = 0;
	//LoadInventory();

	//while(bLoadAll)
	//{
	//	if (LazyLoadIndex >= LockerItems.Length)
	//	{
	//		bLoadAll = false;
	//		//LockerList.SetWidth(LockerListWidth);//538;
	//		RealizeItems();
	//		LockerList.RealizeList();
	//		`LOG(default.class @ GetFuncName() @ "RealizeList",, 'TacUI');
	//		break;
	//	}
	//
	//	LazyLoadUIItems(LazyLoadIndex);
	//	if (LazyLoadIndex % 10 == 0)
	//	{
	//		sleep(0.1);
	//	}
	//	LazyLoadIndex++;
	//}
}

defaultproperties
{
	//LibID = "LoadoutScreenMC";
}
