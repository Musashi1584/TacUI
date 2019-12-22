//-----------------------------------------------------------
//	Class:	UIArmory_Loadout_TacUI
//	Author: Henning Waberg
//	
//-----------------------------------------------------------


class UIArmory_Loadout_TacUI extends UIArmory_Loadout;

var private bool bLoadAll;
var EInventorySlot SelectedSlot;
var array<TUILockerItem> LockerItems;


simulated function OnCancel()
{
	if(ActiveList == EquippedList)
	{
		`LOG(default.class @ GetFuncName() @ "EquppedList" @ PawnLocationTag,, 'TacUI');
		ScriptTrace();

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
	ScriptTrace();

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

simulated function ChangeActiveList(UIList kActiveList, optional bool bSkipAnimation)
{
	local bool bEquppedList;
	
	bEquppedList = kActiveList == EquippedList;

	if(bEquppedList)
	{
		ReleaseAllPawns();
		CreateSoldierPawn();
	}
	else
	{
		ReleaseAllPawns();
	}


	`LOG(default.class @ GetFuncName() @ `ShowVar(bEquppedList) @ PawnLocationTag,, 'TacUI');
	ScriptTrace();

	super.ChangeActiveList(kActiveList, bSkipAnimation);
}

simulated function UpdateLockerList()
{
	local XComGameState_Item Item;
	local StateObjectReference ItemRef;
	local TUILockerItem LockerItem;
	local array<StateObjectReference> Inventory;
	local int Index;
	
	EquippedList.width = 538;

	SelectedSlot = GetSelectedSlot();

	// set title according to selected slot
	// Issue #118
	LocTag.StrValue0 = class'CHItemSlot'.static.SlotGetName(SelectedSlot);
	//LocTag.StrValue0 = m_strInventoryLabels[SelectedSlot];
	MC.FunctionString("setRightPanelTitle", `XEXPAND.ExpandString(m_strLockerTitle));

	GetInventory(Inventory);
	LockerItems.Length = 0;
	foreach Inventory(ItemRef)
	{
		Item = GetItemFromHistory(ItemRef.ObjectID);
		if(ShowInLockerList(Item, SelectedSlot))
		{
			LockerItem.Item = Item;
			LockerItem.DisabledReason = GetDisabledReason(Item, SelectedSlot);
			LockerItem.CanBeEquipped = LockerItem.DisabledReason == ""; // sorting optimization
			if (LockerItem.CanBeEquipped)
			{
				LockerItems.AddItem(LockerItem);
			}
		}
	}

	LockerList.ClearItems();

	LockerItems.Sort(SortLockerListByUpgrades);
	LockerItems.Sort(SortLockerListByTier);
	LockerItems.Sort(SortLockerListByEquip);

	foreach LockerItems(LockerItem, Index)
	{
		if (Index <= 40)
		{
			UIArmory_LoadoutItem_TacUI(LockerList.CreateItem(class'UIArmory_LoadoutItem_TacUI')).InitLoadoutItem(LockerItem.Item, SelectedSlot, false, LockerItem.DisabledReason);
		}
	}

	SetTimer(0.1f, false, nameof(LazyLoadAll));

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

simulated function LazyLoadAll()
{
	local int Index;
	local TUILockerItem LockerItem;

	foreach LockerItems(LockerItem, Index)
	{
		if (Index > 40)
		{
			UIArmory_LoadoutItem_TacUI(LockerList.CreateItem(class'UIArmory_LoadoutItem_TacUI')).InitLoadoutItem(LockerItem.Item, SelectedSlot, false, LockerItem.DisabledReason);
		}
	}
}

simulated function OnSelectionChanged(UIList ContainerList, int ItemIndex)
{
	local UIArmory_LoadoutItem_TacUI ContainerSelection;
	local UIArmory_LoadoutItem EquippedSelection;
	local StateObjectReference EmptyRef, ContainerRef, EquippedRef;
	local XComGameState_Item Weapon;

	ContainerSelection = UIArmory_LoadoutItem_TacUI(ContainerList.GetSelectedItem());
	EquippedSelection = UIArmory_LoadoutItem(EquippedList.GetSelectedItem());

	ContainerRef = ContainerSelection != none ? ContainerSelection.ItemRef : EmptyRef;
	EquippedRef = EquippedSelection != none ? EquippedSelection.ItemRef : EmptyRef;

	if((ContainerSelection == none) || !ContainerSelection.IsDisabled)
		Header.PopulateData(GetUnit(), ContainerRef, EquippedRef);

	if (ContainerSelection != none && ContainerRef != EmptyRef)
	{
		Weapon = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(ContainerRef.ObjectID));
		CreateWeaponPawn(Weapon);
	}

	InfoTooltip.HideTooltip();

	if(`ISCONTROLLERACTIVE)
	{
		ClearTimer(nameof(DelayedShowTooltip));
		SetTimer(0.21f, false, nameof(DelayedShowTooltip));
	}
	UpdateNavHelp();
}

simulated function CreateWeaponPawn(XComGameState_Item Weapon, optional Rotator DesiredRotation)
{
	local Rotator NoneRotation;
	local XGWeapon WeaponVisualizer;
	
	// Make sure to clean up weapon actors left over from previous Armory screens.
	if(ActorPawn == none)
		ActorPawn = UIArmory(Movie.Stack.GetLastInstanceOf(class'UIArmory')).ActorPawn;

	// Clean up previous weapon actor
	if( ActorPawn != none )
		ActorPawn.Destroy();

	WeaponVisualizer = XGWeapon(Weapon.GetVisualizer());
	if( WeaponVisualizer != none )
	{
		WeaponVisualizer.Destroy();
	}

	class'XGItem'.static.CreateVisualizer(Weapon);
	WeaponVisualizer = XGWeapon(Weapon.GetVisualizer());
	ActorPawn = WeaponVisualizer.GetEntity();

	PawnLocationTag = X2WeaponTemplate(Weapon.GetMyTemplate()).UIArmoryCameraPointTag;

	if (PawnLocationTag == '')
		PawnLocationTag = 'UIPawnLocation_WeaponUpgrade_Shotgun';

	if(DesiredRotation == NoneRotation)
		DesiredRotation = GetPlacementActor().Rotation;

	ActorPawn.SetLocation(GetPlacementActor().Location);
	ActorPawn.SetRotation(DesiredRotation);
	ActorPawn.SetDrawScale(0.6);
	ActorPawn.SetHidden(false);

	`LOG(default.class @ GetFuncName() @ ActorPawn @ PawnLocationTag,, 'TacUI');
	ScriptTrace();
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
	ScriptTrace();

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
	local StateObjectReference PrevItemRef, NewItemRef;
	local XComGameState_Item PrevItem, NewItem;
	local bool CanEquip, EquipSucceeded, AddToFront, Removed, CanAdd;
	local XComGameState_HeadquartersXCom XComHQ;
	local XComNarrativeMoment EquipNarrativeMoment;
	local XGWeapon Weapon;
	local array<XComGameState_Item> PrevUtilityItems;
	local XComGameState_Unit UpdatedUnit;
	local XComGameState UpdatedState;
	local X2WeaponTemplate WeaponTemplate;
	local EInventorySlot InventorySlot;

	UpdatedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Equip Item");
	UpdatedUnit = XComGameState_Unit(UpdatedState.ModifyStateObject(class'XComGameState_Unit', GetUnit().ObjectID));
	
	// Issue #118 -- don't use utility items but the actual slot
	if (class'CHItemSlot'.static.SlotIsMultiItem(GetSelectedSlot()))
	{
		PrevUtilityItems = UpdatedUnit.GetAllItemsInSlot(GetSelectedSlot(), UpdatedState);
	}

	NewItemRef = Item.ItemRef;
	PrevItemRef = UIArmory_LoadoutItem(EquippedList.GetSelectedItem()).ItemRef;
	PrevItem = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(PrevItemRef.ObjectID));

	if(PrevItem != none)
	{
		PrevItem = XComGameState_Item(UpdatedState.ModifyStateObject(class'XComGameState_Item', PrevItem.ObjectID));
	}

	foreach UpdatedState.IterateByClassType(class'XComGameState_HeadquartersXCom', XComHQ)
	{
		break;
	}

	if(XComHQ == none)
	{
		XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
		XComHQ = XComGameState_HeadquartersXCom(UpdatedState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
	}

	// Attempt to remove previously equipped primary or secondary weapons
	WeaponTemplate = (PrevItem != none) ? X2WeaponTemplate(PrevItem.GetMyTemplate()) : none;
	InventorySlot = (WeaponTemplate != none) ? WeaponTemplate.InventorySlot : eInvSlot_Unknown;
	if( (InventorySlot == eInvSlot_PrimaryWeapon) || (InventorySlot == eInvSlot_SecondaryWeapon))
	{
		Weapon = XGWeapon(PrevItem.GetVisualizer());
		// Weapon must be graphically detach, otherwise destroying it leaves a NULL component attached at that socket
		XComUnitPawn(ActorPawn).DetachItem(Weapon.GetEntity().Mesh);

		Weapon.Destroy();
	}
	
	//issue #114: pass along item state in CanAddItemToInventory check, in case there's a mod that wants to prevent a specific item from being equipped. We also assign an itemstate to NewItem now, so we can use it for the full inventory check.
	NewItem = XComGameState_Item(`XCOMHISTORY.GetGameStateForObjectID(NewItemRef.ObjectID));

	Removed = (PrevItem == none || UpdatedUnit.RemoveItemFromInventory(PrevItem, UpdatedState));
	CanAdd = UpdatedUnit.CanAddItemToInventory(Item.ItemTemplate, GetSelectedSlot(), UpdatedState, NewItem.Quantity, NewItem);
	CanEquip = (Removed && CanAdd);
	`LOG(default.class @ GetFuncName() @ `ShowVar(Removed) @ `ShowVar(CanAdd),, 'TacUI');
	`LOG(default.class @ GetFuncName() @ `ShowVar(Item.ItemTemplate) @ `ShowVar(GetSelectedSlot()) @ `ShowVar(UpdatedState) @ `ShowVar(NewItem.Quantity) @ `ShowVar(NewItem),, 'TacUI');
	//end issue #114
	if(CanEquip)
	{
		GetItemFromInventory(UpdatedState, NewItemRef, NewItem);
		NewItem = XComGameState_Item(UpdatedState.ModifyStateObject(class'XComGameState_Item', NewItem.ObjectID));

		// Fix for TTP 473, preserve the order of Utility items
		if(PrevUtilityItems.Length > 0)
		{
			AddToFront = PrevItemRef.ObjectID == PrevUtilityItems[0].ObjectID;
		}

		//If this is an unmodified primary weapon, transfer weapon customization options from the unit.
		if (!NewItem.HasBeenModified() && GetSelectedSlot() == eInvSlot_PrimaryWeapon)
		{
			WeaponTemplate = X2WeaponTemplate(NewItem.GetMyTemplate());
			if (WeaponTemplate != none && WeaponTemplate.bUseArmorAppearance)
			{
				NewItem.WeaponAppearance.iWeaponTint = UpdatedUnit.kAppearance.iArmorTint;
			}
			else
			{
				NewItem.WeaponAppearance.iWeaponTint = UpdatedUnit.kAppearance.iWeaponTint;
			}
			NewItem.WeaponAppearance.nmWeaponPattern = UpdatedUnit.kAppearance.nmWeaponPattern;
		}
		
		EquipSucceeded = UpdatedUnit.AddItemToInventory(NewItem, GetSelectedSlot(), UpdatedState, AddToFront);

		if( EquipSucceeded )
		{
			if( PrevItem != none )
			{
				XComHQ.PutItemInInventory(UpdatedState, PrevItem);
			}

			if(class'XComGameState_HeadquartersXCom'.static.GetObjectiveStatus('T0_M5_EquipMedikit') == eObjectiveState_InProgress &&
			   NewItem.GetMyTemplateName() == class'UIInventory_BuildItems'.default.TutorialBuildItem)
			{
				`XEVENTMGR.TriggerEvent('TutorialItemEquipped', , , UpdatedState);
				bTutorialJumpOut = true;
			}
		}
		else
		{
			if(PrevItem != none)
			{
				UpdatedUnit.AddItemToInventory(PrevItem, GetSelectedSlot(), UpdatedState);
			}

			XComHQ.PutItemInInventory(UpdatedState, NewItem);
		}
	}

	UpdatedUnit.ValidateLoadout(UpdatedState);
	`XCOMGAME.GameRuleset.SubmitGameState(UpdatedState);

	if( EquipSucceeded && X2EquipmentTemplate(Item.ItemTemplate) != none)
	{
		if(X2EquipmentTemplate(Item.ItemTemplate).EquipSound != "")
		{
			`XSTRATEGYSOUNDMGR.PlaySoundEvent(X2EquipmentTemplate(Item.ItemTemplate).EquipSound);
		}

		if(X2EquipmentTemplate(Item.ItemTemplate).EquipNarrative != "")
		{
			EquipNarrativeMoment = XComNarrativeMoment(`CONTENT.RequestGameArchetype(X2EquipmentTemplate(Item.ItemTemplate).EquipNarrative));
			XComHQ = XComGameState_HeadquartersXCom(`XCOMHISTORY.GetSingleGameStateObjectForClass(class'XComGameState_HeadquartersXCom'));
			if(EquipNarrativeMoment != None)
			{
				if (Item.ItemTemplate.ItemCat == 'armor')
				{
					if (XComHQ.CanPlayArmorIntroNarrativeMoment(EquipNarrativeMoment) && !UpdatedUnit.IsResistanceHero())
					{
						UpdatedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Played Armor Intro List");
						XComHQ = XComGameState_HeadquartersXCom(UpdatedState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
						XComHQ.UpdatePlayedArmorIntroNarrativeMoments(EquipNarrativeMoment);
						`XCOMGAME.GameRuleset.SubmitGameState(UpdatedState);

						`HQPRES.UIArmorIntroCinematic(EquipNarrativeMoment.nmRemoteEvent, 'CIN_ArmorIntro_Done', UnitReference);
					}
				}
				else if (XComHQ.CanPlayEquipItemNarrativeMoment(EquipNarrativeMoment))
				{
					UpdatedState = class'XComGameStateContext_ChangeContainer'.static.CreateChangeState("Update Equip Item Intro List");
					XComHQ = XComGameState_HeadquartersXCom(UpdatedState.ModifyStateObject(class'XComGameState_HeadquartersXCom', XComHQ.ObjectID));
					XComHQ.UpdateEquipItemNarrativeMoments(EquipNarrativeMoment);
					`XCOMGAME.GameRuleset.SubmitGameState(UpdatedState);
					
					`HQPRES.UINarrative(EquipNarrativeMoment);
				}
			}
		}	
	}

	return EquipSucceeded;
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

//simulated function UIMechaListItem GetListItem(int ItemIndex, optional bool bDisableItem, optional string DisabledReason)
//{
//	local UIMechaListItem CustomizeItem;
//	local UIPanel Item;
//
//	if(List.ItemCount <= ItemIndex)
//	{
//		CustomizeItem = Spawn(class'UIMechaListItem', List.ItemContainer);
//		CustomizeItem.bAnimateOnInit = false;
//		CustomizeItem.InitListItem();
//	}
//	else
//	{
//		Item = List.GetItem(ItemIndex);
//		CustomizeItem = UIMechaListItem(Item);
//	}
//
//	CustomizeItem.SetDisabled(bDisableItem, DisabledReason != "" ? DisabledReason : m_strNeedsVeteranStatus);
//
//	return CustomizeItem;
//}
