//-----------------------------------------------------------
//	Class:	UIArmory_Loadout_TacUI
//	Author: Musashi
//	
//-----------------------------------------------------------
class UIArmory_Loadout_TacUI extends UIArmory_Loadout;

const LockerListWidth = 400;
const CategoryFilter = 'ItemCategory';
const WeaponTechFilter = 'WeaponTech';
const SortFilter = 'Sort';

var bool bLoadFilters, bAbortLoading;
var EInventorySlot SelectedSlot;
var array<TUILockerItemTacUI> LockerItems;
var array<name> ActiveItemCategories, ActiveWeaponTechs;
var UIArmory_LoadoutFilterPanel WeaponTechFilterPanel, ItemCategoryFilterPanel, SortPanel;
var array<UIArmory_LoadoutItem_TacUI> LoadoutItems;
var private int ListItemIndex, ItemCreatedIndex;
var private TacUIFilters WeaponTechFilterState, CategoryFilterState, SortState;
var array<name> SortByCategories;
var array<string> SortByCategoriesLocalized;

delegate int SortLockerItemsDelegate(TUILockerItemTacUI A, TUILockerItemTacUI B);

simulated function InitArmory(StateObjectReference UnitRef, optional name DispEvent, optional name SoldSpawnEvent, optional name NavBackEvent, optional name HideEvent, optional name RemoveEvent, optional bool bInstant = false, optional XComGameState InitCheckGameState)
{
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
	
	bLoadFilters = true;
	PopulateData();

	ItemCategoryFilterPanel = CreateFilterPanel(
		Caps(class'XGLocalizedData_TacUI'.default.CategoryFilterTitle),
		CategoryFilter, LockerListWidth + 5,
		0,
		true
	);
	
	WeaponTechFilterPanel = CreateFilterPanel(
		Caps(class'XGLocalizedData_TacUI'.default.TechFilterTitle),
		WeaponTechFilter,
		LockerListWidth + 5,
		0,
		true
	);

	SortPanel = CreateFilterPanel(
		Caps(class'XGLocalizedData_TacUI'.default.SortTitle),
		SortFilter,
		ItemCategoryFilterPanel.X + ItemCategoryFilterPanel.Width + 25,
		0,
		true
	);
	//SortPanel = CreateFilterPanel("SORT BY", SortFilter, LockerListWidth + 5, 0 , true);
}

simulated function PopulateData()
{
	local name SortKey;
	CreateSoldierPawn();
	UpdateEquippedList();
	ChangeActiveList(EquippedList, true);

	//SortByCategories.AddItem('Default');
	SortByCategories.AddItem('Category');
	SortByCategories.AddItem('Name');
	SortByCategories.AddItem('Tier');
	
	foreach SortByCategories(SortKey)
	{
		SortByCategoriesLocalized.AddItem(class'X2TacUIHelper'.static.GetLocalizedSort(SortKey));
	}
		
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

simulated function UIArmory_LoadoutFilterPanel CreateFilterPanel(
	string FilterTitle,
	name FilterCategory,
	int PanelX,
	int PanelY,
	optional bool bUseRadioButtonsIn = false
)
{
	local UIArmory_LoadoutFilterPanel This;
	This = class'UIArmory_LoadoutFilterPanel'.static.CreateLoadoutFilterPanel(
		LockerListContainer,
		FilterTitle,
		FilterCategory,
		bUseRadioButtonsIn
	);
	This.SetPosition(PanelX, PanelY);
	This.Hide();
	return This;
}

simulated function ChangeActiveList(UIList kActiveList, optional bool bSkipAnimation)
{
	local bool bEquppedList;
	
	bEquppedList = kActiveList == EquippedList;

	if(bEquppedList)
	{
		bAbortLoading = true;
		ReleaseAllPawns();
		CreateSoldierPawn();
		ItemCategoryFilterPanel.Hide();
		WeaponTechFilterPanel.Hide();
		SortPanel.Hide();
	}
	else
	{
		ReleasePawn();
		ItemCategoryFilterPanel.Show();
		WeaponTechFilterPanel.Show();
		SortPanel.Show();
	}

	//`LOG(default.class @ GetFuncName() @ `ShowVar(bEquppedList) @ PawnLocationTag,, 'TacUI');

	super.ChangeActiveList(kActiveList, bSkipAnimation);
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
		//`LOG(default.class @ GetFuncName() @ "EquppedList" @ PawnLocationTag,, 'TacUI');
	
		ReleaseAllPawns();
		CreateSoldierPawn();
	}
	super.OnCancel(); // exits screen
}

simulated function CreateSoldierPawn(optional Rotator DesiredRotation)
{
	super.CreateSoldierPawn(DesiredRotation);
	// Set desired rotation for mousegard to prevent leaking weapon rotation to pawn.
	UIMouseGuard_RotatePawn(`SCREENSTACK.GetFirstInstanceOf(class'UIMouseGuard_RotatePawn')).SetActorPawn(ActorPawn, DesiredRotation);
}

simulated function ReleaseAllPawns()
{
	local int i;
	local UIArmory_Loadout_TacUI ArmoryScreen;
	local UIScreenStack ScreenStack;

	//`LOG(default.class @ GetFuncName(),, 'TacUI');

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
		if (WeaponVisualizer != none)
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

		UIMouseGuard_RotatePawn(`SCREENSTACK.GetFirstInstanceOf(class'UIMouseGuard_RotatePawn')).SetActorPawn(ActorPawn, ActorPawn.Rotation);
	}

//	//`LOG(default.class @ GetFuncName() @ ActorPawn @ PawnLocationTag,, 'TacUI');
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
		bLoadFilters = true;
		LockerList.ClearItems();
		ChangeActiveList(LockerList);
		UpdateLockerList();
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
	
	CreateSoldierPawn();

	Header.PopulateData(GetUnit());

	if (bRefreshPawn && `GAME != none)
	{
		`GAME.GetGeoscape().m_kBase.m_kCrewMgr.TakeCrewPhotobgraph(GetUnit().GetReference(), true);
	}
}

simulated function RequestPawn(optional Rotator DesiredRotation)
{
	PawnLocationTag = 'UIPawnLocation_Armory';
	super.RequestPawn(DesiredRotation);
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
				if (ItemTacUI != none)
					return GetItemFromHistory(ItemTacUI.ItemRef.ObjectID); 
			}

			if(Item != none)
				return GetItemFromHistory(Item.ItemRef.ObjectID); 
		}
	}
	
	//Else we never found a target list + item
	//`LOG("Problem in UIArmory_Loadout for the UITooltip_InventoryInfo: couldn't match the active list at position -4 in this path: " $currentPath,,'uixcom');
	return none;
}

simulated function UpdateNavHelp()
{
	super.UpdateNavHelp();

	if(bUseNavHelp && ActiveList == LockerList)
	{
		if (!`ISCONTROLLERACTIVE)
		{
			NavHelp.AddLeftHelp(
				Caps(class'XGLocalizedData_TacUI'.default.ResetFilter),
				"",
				OnResetFilter,
				false,
				class'XGLocalizedData_TacUI'.default.ResetFilterTooltip,
				class'UIUtilities'.const.ANCHOR_BOTTOM_CENTER
			);
		}
	}
}

simulated function OnResetFilter()
{
	//`LOG(default.class @ GetFuncName(),, 'TacUI');
	class'XComGameState_LoadoutFilter'.static.ResetFilter(CategoryFilter, UnitReference.ObjectID, SelectedSlot);
	class'XComGameState_LoadoutFilter'.static.ResetFilter(WeaponTechFilter, UnitReference.ObjectID, SelectedSlot);
	class'XComGameState_LoadoutFilter'.static.ResetFilter(SortFilter, UnitReference.ObjectID, SelectedSlot);
	bAbortLoading = true;
	LockerList.ClearItems();
	UpdateLockerList();
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

simulated function TacUIFilters GetFilterState(name FilterCategory)
{
	local XComGameState_LoadoutFilter LoadoutFilterGameState;

	LoadoutFilterGameState = class'XComGameState_LoadoutFilter'.static.GetLoadoutFilterGameState();
	return LoadoutFilterGameState.GetFilter(FilterCategory, UnitReference.ObjectID, SelectedSlot);
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


simulated function int SortLockerListByNameAscTacUI(TUILockerItemTacUI A, TUILockerItemTacUI B)
{
	local string NameA, NameB;

	NameA = A.FriendlyNameLocalized;
	NameB = B.FriendlyNameLocalized;

	if (NameA < NameB) return 1;
	else if (NameA > NameB) return -1;
	else return 0;
}

simulated function int SortLockerListByCategoryAscTacUI(TUILockerItemTacUI A, TUILockerItemTacUI B)
{
	local string NameA, NameB;

	NameA = A.ItemCategoryLocalized;
	NameB = B.ItemCategoryLocalized;

	if (NameA < NameB) return 1;
	else if (NameA > NameB) return -1;
	else return 0;
}


public function QuickSortLockerItem(
	out array<TUILockerItemTacUI> Arr,
	int First,
	int Last,
	delegate<SortLockerItemsDelegate> SortDelegate
)
{
	local int PartitionIndex;
	if (First < Last) {
		PartitionIndex = Partition(Arr, First, Last, SortDelegate);
 
		QuickSortLockerItem(Arr, First, PartitionIndex - 1, SortDelegate);
		QuickSortLockerItem(Arr, PartitionIndex + 1, Last, SortDelegate);
	}
}

private function int Partition(
	out array<TUILockerItemTacUI> Arr,
	int First,
	int Last,
	delegate<SortLockerItemsDelegate> SortDelegate
)
{
	local TUILockerItemTacUI Pivot, Swap;
	local int Current, Index;

	Pivot = Arr[Last];
	Current = (First - 1);
 
	for (Index = First; Index < Last; Index++) {
		// Arr[Index] <= Pivot
		if (SortDelegate(Pivot, Arr[Index]) <= 0) {
			Current++;
 
			Swap = Arr[Current];
			Arr[Current] = Arr[Index];
			Arr[Index] = Swap;
		}
	}
 
	Swap = Arr[Current + 1];
	Arr[Current + 1] = Arr[Last];
	Arr[Last] = Swap;
 
	return Current + 1;
}

simulated function UpdateLockerList()
{
	GotoState('LoadLockerList');
}

simulated function SelectItem()
{
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

function LoadInventory()
{
	local XComGameState_Item Item;
	local StateObjectReference ItemRef;
	local TUILockerItemTacUI LockerItem;
	local array<StateObjectReference> Inventory;
	local array<String> LocalizedCategories, LocalizedTechs;

	//`LOG(default.class @ GetFuncName() @ "Start",, 'TacUI');

	LockerList.SetWidth(LockerListWidth);
	
	// set title according to selected slot
	// Issue #118
	LocTag.StrValue0 = class'CHItemSlot'.static.SlotGetName(SelectedSlot);
	//LocTag.StrValue0 = m_strInventoryLabels[SelectedSlot];
	MC.FunctionString("setRightPanelTitle", `XEXPAND.ExpandString(m_strLockerTitle));

	GetInventory(Inventory);
	LockerItems.Length = 0;
	ActiveItemCategories.Length = 0;
	ActiveWeaponTechs.Length = 0;

	//`LOG(default.class @ GetFuncName() @ "Gather Data Start",, 'TacUI');

	foreach Inventory(ItemRef)
	{
		Item = GetItemFromHistory(ItemRef.ObjectID);

		if (Item == none)
		{
			continue;
		}

		if(ShowInLockerList(Item, SelectedSlot))
		{
			LockerItem.Item = Item;
			LockerItem.DisabledReason = GetDisabledReason(Item, SelectedSlot);
			LockerItem.ItemCategory = class'X2TacUIHelper'.static.GetItemCategory(Item.GetMyTemplate());
			LockerItem.Tech = class'X2TacUIHelper'.static.GetItemTech(Item.GetMyTemplate());
			// sorting optimization
			LockerItem.CanBeEquipped = LockerItem.DisabledReason == ""; 
			LockerItem.ItemCategoryLocalized =  class'X2TacUIHelper'.static.GetLocalizedCategory(Item.GetMyTemplate());
			LockerItem.FriendlyNameLocalized = Caps(class'X2TacUIHelper'.static.StripTags(Item.GetMyTemplate().GetItemFriendlyName()));

			if (LockerItem.CanBeEquipped)
			{
				// Collect all filter items
				if (LockerItem.ItemCategory != '' && ActiveItemCategories.Find(LockerItem.ItemCategory) == INDEX_NONE)
				{
					ActiveItemCategories.AddItem(LockerItem.ItemCategory);
					LocalizedCategories.AddItem(class'X2TacUIHelper'.static.GetLocalizedCategory(Item.GetMyTemplate()));
				}

				if (LockerItem.Tech != '' && ActiveWeaponTechs.Find(LockerItem.Tech) == INDEX_NONE)
				{
					ActiveWeaponTechs.AddItem(LockerItem.Tech);
					LocalizedTechs.AddItem(class'X2TacUIHelper'.static.GetLocalizedTech(LockerItem.Tech));
				}

				LockerItems.AddItem(LockerItem);
			}
		}
	}

	if (bLoadFilters)
	{
		//`LOG(default.class @ GetFuncName() @ "LoadFilters",, 'TacUI');
		ItemCategoryFilterPanel.PopulateFilters(ActiveItemCategories, SelectedSlot, LocalizedCategories);
		SortPanel.PopulateFilters(SortByCategories, SelectedSlot, SortByCategoriesLocalized);

		WeaponTechFilterPanel.PopulateFilters(ActiveWeaponTechs, SelectedSlot, LocalizedTechs);
		WeaponTechFilterPanel.SetY(ItemCategoryFilterPanel.List.GetTotalHeight() + ItemCategoryFilterPanel.BGPaddingTop + 20);
	}

	if (SortState.FilterNames.Length == 0 || SortState.FilterNames.Find('Default') != INDEX_NONE)
	{
		QuickSortLockerItem(LockerItems, 0, LockerItems.Length - 1, SortLockerListByCategoryAscTacUI);
		QuickSortLockerItem(LockerItems, 0, LockerItems.Length - 1, SortLockerListByUpgradesTacUI);
		QuickSortLockerItem(LockerItems, 0, LockerItems.Length - 1, SortLockerListByTierTacUI);
	}
	else
	{
		if (SortState.FilterNames.Find('Category') != INDEX_NONE)
		{
			QuickSortLockerItem(LockerItems, 0, LockerItems.Length - 1, SortLockerListByTierTacUI);
			QuickSortLockerItem(LockerItems, 0, LockerItems.Length - 1, SortLockerListByCategoryAscTacUI);
		}
		if (SortState.FilterNames.Find('Name') != INDEX_NONE)
		{
			QuickSortLockerItem(LockerItems, 0, LockerItems.Length - 1, SortLockerListByNameAscTacUI);
		}
		if (SortState.FilterNames.Find('Tier') != INDEX_NONE)
		{
			QuickSortLockerItem(LockerItems, 0, LockerItems.Length - 1, SortLockerListByTierTacUI);
		}
	}
}

function bool CreateListItem(int Index)
{
	local TUILockerItemTacUI LockerItem;
	local UIArmory_LoadoutItem_TacUI LoadoutItem;
		
	LockerItem = LockerItems[Index];

	if (CategoryFilterState.FilterNames.Length > 0 &&
		CategoryFilterState.FilterNames.Find(LockerItem.ItemCategory) == INDEX_NONE)
	{
		return false;
	}

	if (WeaponTechFilterState.FilterNames.Length > 0 &&
		WeaponTechFilterState.FilterNames.Find(LockerItem.Tech) == INDEX_NONE)
	{
		return false;
	}

	LoadoutItem = UIArmory_LoadoutItem_TacUI(LockerList.CreateItem(class'UIArmory_LoadoutItem_TacUI'));
	LoadoutItem.InitLoadoutItem
	(
		LockerItem.Item,
		SelectedSlot,
		LockerListWidth
	);

	return true;
}

state LoadLockerList
{

Begin:
	//`LOG(default.class @ GetFuncName() @ "Start",, 'TacUI');
	bAbortLoading = false;
	LockerList.ClearItems();
	ListItemIndex = 0;
	ItemCreatedIndex = 0;
	SelectedSlot = GetSelectedSlot();
	CategoryFilterState = GetFilterState(CategoryFilter);
	WeaponTechFilterState = GetFilterState(WeaponTechFilter);
	SortState = GetFilterState(SortFilter);
	LoadInventory();
	//LockerList.SelectedIndex = 0;

	//`LOG(default.class @ GetFuncName() @ "Creating UI",, 'TacUI');
	while(ListItemIndex < LockerItems.Length && !bAbortLoading)
	{
		if (CreateListItem(ListItemIndex))
		{
			ItemCreatedIndex++;
		}

		if (ItemCreatedIndex % 10 == 0 && ItemCreatedIndex != 0)
		{
			sleep(0);
		}

		ListItemIndex++;
	}

	SelectItem();
	bLoadFilters = true;
	//LockerList.RealizeItems();
	//LockerList.RealizeList();
	
	//`LOG(default.class @ GetFuncName() @ "End",, 'TacUI');
}

defaultproperties
{
	//LibID = "LoadoutScreenMC";
}
