#priority 100
import crafttweaker.data.IData;
import crafttweaker.item.IItemStack;
import crafttweaker.liquid.ILiquidStack;
import crafttweaker.oredict.IOreDictEntry;

var metalStages = {
	abyssalnite: "two",
	aluminum: "three",
	aluminumBrass: "three",
	ardite: "four",
	blackIron: "three",
	bronze: "one",
	cobalt: "three",
	compressedIron: "four",
	constantan: "three",
	copper: "one",
	dawnstone: "two",
	dreadium: "two",
	electrum: "two",
	enhancedGalgadorian: "three",
	ethaxium: "two",
	fiery: "two",
	galgadorian: "three",
	gold: "two",
	invar: "three",
	iron: "two",
	knightslime: "four",
	lead: "three",
	manyullyn: "four",
	modularium: "three",
	nickel: "three",
	osmium: "four",
	pigiron: "three",
	platinum: "three",
	redstoneAlloy: "three",
	refinedCoralium: "one",
	reinforcedMetal: "three",
	silver: "three",
	steel: "three",
	steeleaf: "two",
	tin: "one",
	uranium: "four"
} as string[string];

//Value doesnt really matter here - but just put it to true
var partsToSkip as bool[string] = {
	"clump": true,
	"crystal": true,
	"dirtyDust": true,
	"shard": true
};

function isItemToKeep(item as IItemStack) as bool {
	return false; //Comment this out if there are mods we want kept

	var modsToKeep = [
	] as string[];

	var itemOwner as string = item.definition.owner;
	for modName in modsToKeep {
		if (itemOwner == modName) {
			return true;
		}
	}
	return false;
}

function unify(oreDictEntry as IOreDictEntry, preferredItem as IItemStack, liquid as ILiquidStack) {
	var hasLiquid = liquid as bool;

	for item in oreDictEntry.items {
		if (!item.matches(preferredItem)) {
			mods.jei.JEI.removeAndHide(item);

			furnace.remove(item);

			if (loadedMods.contains("immersiveengineering")) {
				mods.immersiveengineering.ArcFurnace.removeRecipe(item);
				mods.immersiveengineering.Crusher.removeRecipe(item);
				mods.immersiveengineering.MetalPress.removeRecipe(item);
			}

			if (loadedMods.contains("appliedenergistics2")) {
				mods.appliedenergistics2.Grinder.removeRecipe(item);
			}

			if (loadedMods.contains("astralsorcery")) {
				//TODO: Change to removeRecipe once fixed in AS
				mods.astralsorcery.Grindstone.removeReipce(item);
			}

			if (hasLiquid) {
				if (loadedMods.contains("embers")) {
					mods.embers.Stamper.remove(item);
					mods.embers.Melter.remove(item);
				}

				if (loadedMods.contains("tconstruct")) {
					mods.tconstruct.Casting.removeBasinRecipe(item);
					mods.tconstruct.Casting.removeTableRecipe(item);
					mods.tconstruct.Melting.removeRecipe(liquid, item);
				}
			}

			//Remove from Ore Dict
			oreDictEntry.remove(item);
		}
	}
}

//Returns item if it exists for that metal, or null
function getPreferredMetalItem(metalName as string, metalPartName as string) as IItemStack {
	return metalItems[metalName][metalPartName] as bool ? metalItems[metalName][metalPartName].items[0] : null;
}

//Returns liquid if it exists for that metal, or null
function getMetalLiquid(metalName as string) as ILiquidStack {
	return metalItems[metalName].liquid as bool ? metalItems[metalName].liquid.liquids[0] : null;
}

function handlePreferredMetalItem(metalName as string, metalPartName as string, metal as IOreDictEntry[string], preferredMetalItem as IItemStack, metalLiquid as ILiquidStack, doFurnace as bool, metalStage as string) {
	var hasLiquid = metalLiquid as bool;

	//Add preferredMetalItem to oreDict if it does not exist already
	if (!(metal[metalPartName] in preferredMetalItem)) {
		metal[metalPartName].add(preferredMetalItem);
	}

	/*
		Remove Metal Recipes
	*/
	recipes.remove(preferredMetalItem);
	furnace.remove(preferredMetalItem);

	/*
		Stage Metal Item
	*/
	if (metalStage != "") {
		mods.ItemStages.addItemStage(metalStage, preferredMetalItem);
		//mods.recipestages.Recipes.setRecipeStage(metalStage, preferredMetalItem);
	}

	/*
		Add Metal Recipes
	*/
	//==============================
	//Embers
	if ((metalPartName == "ingot" | metalPartName == "plate") & hasLiquid) {
		mods.embers.Stamper.remove(preferredMetalItem);

		var stamp as IItemStack = metalPartName == "ingot" ? <embers:stamp_bar> : <embers:stamp_plate>;
		mods.embers.Stamper.add(preferredMetalItem, metalLiquid * 144, stamp);
	}

	//==============================
	//Tinker's Construct
	if (hasLiquid) {
		var fluidAmount as int = 0;

		if (metalPartName == "ingot" | metalPartName == "plate") {
			fluidAmount = 144;
		} else if (metalPartName == "rod") {
			fluidAmount = 72;
		} else if (metalPartName == "block") {
			fluidAmount = 1296;
		} else if (metalPartName == "gear") {
			fluidAmount = 576;
		} else if (metalPartName == "nugget") {
			fluidAmount = 16;
		}

		mods.tconstruct.Melting.removeRecipe(metalLiquid, preferredMetalItem);
		if (fluidAmount != 0) {
			mods.tconstruct.Melting.addRecipe(metalLiquid * fluidAmount, preferredMetalItem);
		}

		//Casting
		if (metalPartName == "block") {
			var consumeCast = false;

			mods.tconstruct.Casting.removeBasinRecipe(preferredMetalItem);
			mods.tconstruct.Casting.addBasinRecipe(preferredMetalItem, null, metalLiquid, fluidAmount, consumeCast);
		} else {
			var tinkersCast as IItemStack = null;
			var consumeCast = false;

			if (metalPartName == "ingot") {
				tinkersCast = <tconstruct:cast_custom>;
			} else if (metalPartName == "gear") {
				tinkersCast = <tconstruct:cast_custom:4>;
			} else if (metalPartName == "plate") {
				tinkersCast = <tconstruct:cast_custom:3>;
			} else if (metalPartName == "nugget") {
				tinkersCast = <tconstruct:cast_custom:1>;
			}

			if (tinkersCast as bool) {
				mods.tconstruct.Casting.removeTableRecipe(preferredMetalItem);
				mods.tconstruct.Casting.addTableRecipe(preferredMetalItem, tinkersCast, metalLiquid, fluidAmount, consumeCast);
			}
		}
	}

	//==============================
	//Immersive Engineering
	var immersivePressMold as IItemStack = null;
	var immersivePressInputCount = 1;
	var immersivePressOutputCount = 1;
	var immersivePressEnergy = 2400;

	if (metalPartName == "plate") {
		immersivePressMold = <immersiveengineering:mold>;
	} else if (metalPartName == "gear") {
		immersivePressMold = <immersiveengineering:mold:1>;
		immersivePressInputCount = 4;
	} else if (metalPartName == "rod") {
		immersivePressOutputCount = 2;
		immersivePressMold = <immersiveengineering:mold:2>;
	}

	//If immersive mold isnt null, remove/create recipes
	if (immersivePressMold as bool) {
		mods.immersiveengineering.MetalPress.removeRecipe(preferredMetalItem);
		mods.immersiveengineering.MetalPress.addRecipe(
			preferredMetalItem * immersivePressOutputCount, //Output
			metalItems[metalName].ingot.items[0], //Input
			immersivePressMold, //Mold
			immersivePressEnergy, //Energy
			immersivePressInputCount //Input Count
		);
	}

	//Add ingot -> dust in crusher
	if (metalPartName == "dust") {
		//TODO: Temp fix to re-add ore crushing recipes. Fix up to only remove (or add, whichever) recipes that would prevent duplicate ingot -> dust
		//mods.immersiveengineering.Crusher.removeRecipe(preferredMetalItem);
		mods.immersiveengineering.Crusher.addRecipe(preferredMetalItem, metalItems[metalName].ingot.items[0], 256);
	}

	//Remove ingot recipes, mainly for preventing ore doubling recipes
	//Re-create alloy recipes etc elsewhere
	if (metalPartName == "ingot") {
		mods.immersiveengineering.ArcFurnace.removeRecipe(preferredMetalItem);
	}

	//Dust can only be used in arc furnace
	if (metalPartName == "dust") {
		var defaultArcEnergyPerTick as int = 512;
		var defaultArcTickTime as int = 100;
		var arcGivesSlag as bool = false;
		mods.immersiveengineering.ArcFurnace.addRecipe(
			metalItems[metalName].ingot.items[0],
			metal[metalPartName],
			arcGivesSlag ? <ore:itemSlag>.firstItem : null,
			defaultArcTickTime,
			defaultArcEnergyPerTick
		);
	}

	//==============================
	//Primal Tech
	if (metalPartName == "plate") {
		mods.primaltech.StoneAnvil.addRecipe(preferredMetalItem, metalItems[metalName].ingot.items[0]);
	} else if (metalPartName == "rod" & metalItems[metalName].plate as bool) {
		mods.primaltech.StoneAnvil.addRecipe(preferredMetalItem, metalItems[metalName].plate.items[0]);
	} else if (metalPartName == "block") {
		mods.primaltech.StoneAnvil.addRecipe(metalItems[metalName].ingot.items[0] * 9, preferredMetalItem);
	}
}

for metalName, metal in metals {
	var metalLiquid = getMetalLiquid(metalName);
	var hasLiquid = metalLiquid as bool;

	//Stage liquid containers
	if (metalStages[metalName] != "" & hasLiquid) {
		var liquidContainers = [
			<ceramics:clay_bucket>,
			<forge:bucketfilled>,
			<thebetweenlands:syrmorite_bucket_filled>,
			<thebetweenlands:weedwood_bucket_filled>
		] as IItemStack[];

		for liquidContainer in liquidContainers {
			var data as IData = null;
			if (liquidContainer.matches(<ceramics:clay_bucket>)) {
				data = {
					fluids: {
						FluidName: metalLiquid.name,
						Amount: 1000
					}
				};
			} else {
				data = {
					FluidName: metalLiquid.name,
					Amount: 1000
				};
			}

			mods.ItemStages.addItemStage(metalStages[metalName], liquidContainer.withTag(data));
		}
	}

	for partName, part in metal {
		if (part as bool & !(partsToSkip in partName)) {
			var preferredMetalItem = getPreferredMetalItem(metalName, partName);

			unify(part, preferredMetalItem, metalLiquid);

			if (preferredMetalItem as bool) {
				var metalStage = (metalStages in metalName) ? metalStages[metalName] : "";

				handlePreferredMetalItem(metalName, partName, metal, preferredMetalItem, metalLiquid, partName == "ingot", metalStage);
			}
		}
	}
}