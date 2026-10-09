<img src="https://raw.githubusercontent.com/mooreatv/BetterVendorPrice/master/BetterVendorPrice.png" height=150 width=150 align=right>

# Better Vendor Price (BVP) - WoW Forever edition

BVP shows what your items are really worth to a vendor (per item and per full stack, not just the stack you happen
to hold) and, when your bags are full, restacks them and tells you which item is the cheapest to throw away.

Made for WoW Forever, and the same version also works on retail. The Classic / Mists versions (and their MoLib
based code) are on the
[legacy](https://github.com/mooreatv/BetterVendorPrice/tree/legacy) branch.

## Bags full? BVP knows what to throw away

BVP highlights in your bags the item that's the cheapest to get rid of. When your bags get full, it first restacks
your partial stacks (also into the reagent and profession bags) to free slots without losing anything, then tells
you in chat which item it is.

It's smarter than "lowest vendor price": a stack that's still filling up with what you're looting counts for what it
will be worth. Say you have 4 of something that sells for 3s each and 2 of something else for 4s each, and both keep
dropping: if both stack to 5, throw away the 4, that slot is worth 15s full, the other one 20s. If they stack to 20
and 5, it's the other way around. BVP does that math for you.

It only looks at your main bags (where loot goes), not the reagent or profession bags, skips items that can't be
sold (Hearthstone, quest items...), and never destroys anything itself. Cheap but needed, like your fishing pole?
`/bvp keep` and it moves on to the next one.

## Tooltip info

The game's own "Sell Price" line is for the stack under the mouse. BVP adds only what that line doesn't tell you:
- the price per item and how many stack together,
- what a full stack sells for.

Works anywhere item tooltips show, including bags, vendors, item links in chat and the auction house.

For auction house prices and history in the same tooltips, also install
[AHDB](https://www.curseforge.com/wow/addons/auction-house-database) (Auction House DataBase): BVP shows the vendor
lines and AHDB the AH ones, no duplicates.

## Commands and options

- `/bvp cheapest`: restack and show the cheapest slot, anytime.
- `/bvp restack`: merge partial stacks to free bag slots.
- `/bvp keep`: never suggest the current cheapest item again; `/bvp keep <item>` for any item (again to undo),
  `/bvp keep list` to see them.
- `/bvp config`: options (Options > AddOns > Better Vendor Price): single line tooltip or only with Shift held,
  highlight, chat message when the bags are full, auto restacking.
- `/bvp` lists all commands.

## More information

Get the binary release using [curseforge](https://www.curseforge.com/wow/addons/better-vendor-price) client or other
addon manager or on wowinterface.

The source of the addon resides on https://github.com/mooreatv/BetterVendorPrice

Releases detail/changes are on https://github.com/mooreatv/BetterVendorPrice/releases
