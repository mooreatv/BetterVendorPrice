<img src="https://raw.githubusercontent.com/mooreatv/BetterVendorPrice/master/BetterVendorPrice.png" height=150 width=150 align=right>

# Better Vendor Price (BVP) - WoW Forever edition

BVP shows what your items are really worth to a vendor: per item and per full stack, not just the stack you
happen to hold.

The Classic / Mists / retail versions (and their MoLib based code) are on the
[legacy](https://github.com/mooreatv/BetterVendorPrice/tree/legacy) branch.

## Tooltip info

The game's own "Sell Price" line is for the stack under the mouse. BVP adds only what that line doesn't tell you:
- the price per item and how many stack together,
- what a full stack sells for.

Works anywhere item tooltips show, including bags, vendors, item links in chat and the auction house.
`/bvp config` lets you use a single line instead, or only show everything while Shift is held.

For auction house prices and history in the same tooltips, also install
[AHDB](https://www.curseforge.com/wow/addons/auction-house-database) (Auction House DataBase): BVP shows the vendor
lines and AHDB the AH ones, no duplicates.

## Why is it useful?

Sometimes the regular vendor price isn't enough to decide what to keep and what to discard.

Say you have 4 of something that sells for 12s (3s each) and 2 of something else for 8s (4s each), and both keep
dropping. If both stack
to 5, get rid of the 4: that slot is worth 15s full, the other one 20s. But if one stacks to 20 and the other to 5 or
10, the math changes. BVP tells you the stack sizes and full stack prices so you don't have to know them.

## More information

`/bvp` lists all commands.

Get the binary release using [curseforge](https://www.curseforge.com/wow/addons/better-vendor-price) client or other
addon manager or on wowinterface.

The source of the addon resides on https://github.com/mooreatv/BetterVendorPrice

Releases detail/changes are on https://github.com/mooreatv/BetterVendorPrice/releases
