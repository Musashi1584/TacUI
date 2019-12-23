//-----------------------------------------------------------
//	Class:	X2TacUIHelper
//	Author: Musashi
//	
//-----------------------------------------------------------
class X2TacUIHelper extends Object;

static public function name GetItemCategory(XComGameState_Item Item)
{
	local X2ItemTemplate ItemTemplate;
	local name Category;

	ItemTemplate = Item.GetMyTemplate();

	Category = ItemTemplate != none ? ItemTemplate.ItemCat : '';

	if (Category == 'Weapon')
	{
		Category = X2WeaponTemplate(ItemTemplate).WeaponCat;
	}
	if (Category == 'Armor')
	{
		Category = X2ArmorTemplate(ItemTemplate).ArmorTechCat;
	}

	return Category;
}