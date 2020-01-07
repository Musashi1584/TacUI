//-----------------------------------------------------------
//	Class:	X2TacUIHelper
//	Author: Musashi
//	
//-----------------------------------------------------------
class X2TacUIHelper extends Object;

static public function name GetItemCategory(X2ItemTemplate ItemTemplate)
{
	local name Category;

	Category = ItemTemplate != none ? ItemTemplate.ItemCat : '';

	if (Category == 'Weapon')
	{
		Category = X2WeaponTemplate(ItemTemplate).WeaponCat;
	}
	if (Category == 'Armor')
	{
		Category = X2ArmorTemplate(ItemTemplate).ArmorClass;
	}

	return Category;
}

static public function name GetItemTech(X2ItemTemplate ItemTemplate)
{
	local name Category;

	Category = ItemTemplate != none ? ItemTemplate.ItemCat : '';

	if (Category == 'Weapon')
	{
		return X2WeaponTemplate(ItemTemplate).WeaponTech != '' ? X2WeaponTemplate(ItemTemplate).WeaponTech : '';
	}
	if (Category == 'Armor')
	{
		return X2ArmorTemplate(ItemTemplate).ArmorTechCat != '' ? X2ArmorTemplate(ItemTemplate).ArmorTechCat : '';
	}

	return '';
}

static public function string GetLocalizedSort(name Key)
{
	switch (Key)
	{
		case 'Default':
			return class'XGLocalizedData_TacUI'.default.SortByDefault;
			break;
		case 'Category':
			return class'XGLocalizedData_TacUI'.default.SortByCategory;
			break;
		case 'Name':
			return class'XGLocalizedData_TacUI'.default.SortByName;
			break;
		case 'Tier':
			return class'XGLocalizedData_TacUI'.default.SortByTier;
			break;
	}

	return "";
}


static public function string GetLocalizedTech(name Key)
{
	switch (Key)
	{
		case 'Unknown':
			return class'XGLocalizedData_TacUI'.default.ItemTechUnknown;
			break;
		case 'Conventional':
			return class'XGLocalizedData_TacUI'.default.ItemTechCV;
			break;
		case 'Magnetic':
			return class'XGLocalizedData_TacUI'.default.ItemTechMG;
			break;
		case 'Beam':
			return class'XGLocalizedData_TacUI'.default.ItemTechBM;
			break;
		case 'plated':
			return class'XGLocalizedData_TacUI'.default.ItemTechPlated;
			break;
		case 'powered':
			return class'XGLocalizedData_TacUI'.default.ItemTechPowered;
			break;
		case 'laser_lw':
			return class'XGLocalizedData_TacUI'.default.ItemTechLaserLW;
			break;
		case 'coilgun_lw':
			return class'XGLocalizedData_TacUI'.default.ItemTechCoilLW;
			break;
	}

	//`LOG(default.class @ GetFuncName() @ "Could not find localization for" @ Key,, 'TacUI');

	return CapFirstChar(Key);
}

static public function string LocalizeCategory(name Key)
{
	switch (Key)
	{
		case 'Default':
			return class'XGLocalizedData_TacUI'.default.SortByDefault;
			break;
		case 'Category':
			return class'XGLocalizedData_TacUI'.default.SortByCategory;
			break;
		case 'Name':
			return class'XGLocalizedData_TacUI'.default.SortByName;
			break;
		case 'Tier':
			return class'XGLocalizedData_TacUI'.default.SortByTier;
			break;
		case 'rifle':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryRifle;
			break;
		case 'sniper_rifle':
			return class'XGLocalizedData_TacUI'.default.ItemCategorySniperRifle;
			break;
		case 'shotgun':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryShotgun;
			break;
		case 'cannon':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryCannon;
			break;
		case 'vektor_rifle':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryVektorRifle;
			break;
		case 'bullpup':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryBullpup;
			break;
		case 'pistol':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryPistol;
			break;
		case 'sidearm':
			return class'XGLocalizedData_TacUI'.default.ItemCategorySidearm;
			break;
		case 'sword':
			return class'XGLocalizedData_TacUI'.default.ItemCategorySword;
			break;
		case 'gremlin':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryGremlin;
			break;
		case 'psiamp':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryPsiamp;
			break;
		case 'grenade_launcher':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryGrenadeLauncher;
			break;
		case 'claymore':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryClaymore;
			break;
		case 'wristblade':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryWristblade;
			break;
		case 'arcthrower':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryArcthrower;
			break;
		case 'combatknife':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryCombatknife;
			break;
		case 'holotargeter':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryHolotargeter;
			break;
		case 'sawedoffshotgun':
			return class'XGLocalizedData_TacUI'.default.ItemCategorySawedoffshotgun;
			break;
		case 'lw_gauntlet':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryLWGauntlet;
			break;
		case 'empty':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryEmpty;
			break;
		case 'Utility':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryUtility;
			break;
		case 'Tech':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryTech;
			break;
		case 'conventional':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryConventional;
			break;
		case 'plated':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryPlated;
			break;
		case 'powered':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryPowered;
			break;
		case 'sparkrifle':
			return class'XGLocalizedData_TacUI'.default.ItemCategorySparkrifle;
			break;
		case 'gauntlet':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryGauntlet;
			break;
		case 'Basic':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryBasic;
			break;
		case 'Unknown':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryUnknown;
			break;
		case 'Medium':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryMedium;
			break;
		case 'Light':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryLight;
			break;
		case 'Heavy':
			return class'XGLocalizedData_TacUI'.default.ItemCategoryHeavy;
			break;
	}

	return "";
}


static public function string GetLocalizedCategory(X2ItemTemplate Template)
{
	local string Category;
	
	Category = CapFirstChar(LocalizeCategory(GetItemCategory(Template)));

	if (Category == "")
	{
		Category = CapFirstChar(StripTags(Template.GetLocalizedCategory()));
	}

	if (Category == "" ||
		Caps(Category) == "UNKNOWN WEAPON CATEGORY" ||
		Caps(Category) == "UNKNOWN UTILITY CATEGORY")
	{
		//Category = StripTags(Template.AbilityDescName);
		Category = CapFirstChar(StripTags(GetItemCategory(Template)));
		//`LOG(default.class @ GetFuncName() @ "Could not find localization for" @ GetItemCategory(Template),, 'TacUI');
	}


	return Category;
}

static public final function string CapFirstChar(coerce string S)
{
	return Caps(Left(S, 1)) $ Locs(Right(S, Len(S) - 1));
}

static public final function string StripTags(coerce string S)
{
	local int Index;
	local string Char, Buffer;
	local bool bStrip;

	Buffer = "";

	for (Index = 0; Index < Len(S); Index++)
	{
		Char = Mid(S, Index, 1);

		if (Char == "<")
			bStrip = true;

		if (!bStrip)
			Buffer $= Char;

		if (Char == ">")
			bStrip = false;
	}

	return Buffer;
}