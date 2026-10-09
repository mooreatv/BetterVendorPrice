--[[
   BetterVendorPrice by MooreaTV moorea@ymail.com (c) 2019-2026 All rights reserved
   Licensed under LGPLv3 - No Warranty
   (contact the author if you need a different license)

   Get this addon binary release using curse/twitch client or on wowinterface
   The source of the addon resides on https://github.com/mooreatv/BetterVendorPrice

   Releases detail/changes are on https://github.com/mooreatv/BetterVendorPrice/releases
   ]] --
-- BVP for WoW Forever (no libraries). The Classic/Mists/retail MoLib version is on the legacy branch.
local addonName, BVP = ...
_G.BetterVendorPrice = BVP

BVP.prefix = "|cFF99E5FFBetterVendorPrice:|r "
-- the packager substitutes the toc's version with the release tag; a source checkout still has the placeholder
BVP.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
if BVP.version:find("^@") then BVP.version = "dev" end
BVP.defaults = {
  debug = false,
  showFullStack = true, -- per item and full stack lines instead of a single one
  holdShiftForMore = false -- compact single line unless Shift is held
}

-- Localization: L["text"] is the translation or the text itself; the locale files (filled by the CurseForge
-- packager) set L["text"] = true when the translation is the same as the text.
BVP.L = setmetatable({}, {
  __index = function(t, k)
    rawset(t, k, k)
    return k
  end,
  __newindex = function(t, k, v) rawset(t, k, v == true and k or v) end
})
local L = BVP.L

function BVP:Print(msg, ...)
  if select("#", ...) > 0 then msg = msg:format(...) end
  print(self.prefix .. msg)
end

function BVP:Debug(msg, ...)
  if not (self.db and self.db.debug) then return end
  if select("#", ...) > 0 then msg = msg:format(...) end
  print("|cFF808080BVP debug:|r " .. msg)
end

-- Internal (non-Blizzard) callbacks between files.
local listeners = {}
function BVP:Listen(name, fn)
  listeners[name] = listeners[name] or {}
  table.insert(listeners[name], fn)
end

function BVP:Fire(name, ...) for _, fn in ipairs(listeners[name] or {}) do fn(self, ...) end end

-- Blizzard events: any number of handlers per event, called as fn(BVP, ...).
local frame = CreateFrame("Frame")
local handlers = {}
function BVP:On(event, fn)
  if not handlers[event] then
    handlers[event] = {}
    frame:RegisterEvent(event)
  end
  table.insert(handlers[event], fn)
end

frame:SetScript("OnEvent", function(_, event, ...) for _, fn in ipairs(handlers[event]) do fn(BVP, ...) end end)

BVP:On("ADDON_LOADED", function(self, name)
  if name ~= addonName then return end
  betterVendorPriceSaved = betterVendorPriceSaved or {}
  local sv = betterVendorPriceSaved
  local s = sv.settings or {}
  sv.settings = s
  for k, v in pairs(self.defaults) do if s[k] == nil then s[k] = v end end
  self.db = s
  self.sv = sv
end)

BVP:On("PLAYER_LOGIN", function(self) self:Fire("LOGIN") end)

function BVP:ParseOnOff(arg, current)
  arg = (arg or ""):lower()
  if arg == "on" then return true end
  if arg == "off" then return false end
  return not current
end

-- Slash commands: /bvp <command> <rest of line>
BVP.commands = {}
BVP.commandOrder = {}
function BVP:AddCommand(name, fn, help)
  self.commands[name] = {fn = fn, help = help}
  table.insert(self.commandOrder, name)
end

function BVP:Help()
  self:Print("%s commands (|cFF99E5FF/bvp <command>|r):", self.version)
  for _, name in ipairs(self.commandOrder) do print("  |cFF99E5FF/bvp|r " .. self.commands[name].help) end
end

SLASH_BetterVendorPrice1 = "/bvp"
SlashCmdList["BetterVendorPrice"] = function(msg)
  local cmd, rest = (msg or ""):match("^(%S*)%s*(.-)%s*$")
  local c = BVP.commands[cmd:lower()]
  if c then
    c.fn(BVP, rest)
  else
    BVP:Help()
  end
end

BVP:AddCommand("help", function(self) self:Help() end, "help - this list")
BVP:AddCommand("debug", function(self, rest)
  self.db.debug = self:ParseOnOff(rest, self.db.debug)
  self:Print("debug is now %s", tostring(self.db.debug))
end, "debug [on|off] - toggle debug output")
BVP:AddCommand("version", function(self) self:Print("version %s by MooreaTv (moorea@ymail.com)", self.version) end,
               "version - show BetterVendorPrice version")
BVP:AddCommand("bug", function(self)
  self:Print(L["Please submit on discord or on https://|cFF99E5FFbit.ly/vendorbug|r  or email"] ..
               " moorea@ymail.com (BetterVendorPrice %s)", self.version)
end, "bug - where to report a bug or issue")

-- Tooltip

local function sellLinePrice(data)
  for _, line in ipairs(data.lines or {}) do
    if line.type == Enum.TooltipDataLineType.SellPrice then return line.price end
  end
end

-- Whether vendors buy the item: some have a sell price in the item data but no "Sell Price" tooltip line
-- (e.g. Instant Poison) and vendors refuse them.
local sellable = {}
local function isSellable(itemID)
  if sellable[itemID] == nil then
    local data = C_TooltipInfo.GetItemByID(itemID)
    sellable[itemID] = data and sellLinePrice(data) ~= nil or false
  end
  return sellable[itemID]
end

local function addMoney(tt, copper, suffix) SetTooltipMoney(tt, copper, "STATIC", L["Vendors for:"], suffix) end

local function onItemTooltip(tt, data)
  local self = BVP
  if not self.db or not data or not data.id then return end
  local itemID = data.id
  local _, _, _, _, _, _, _, stackSize, _, _, unitPrice = C_Item.GetItemInfo(itemID)
  if not unitPrice or unitPrice <= 0 then return end
  -- the native line is the price of the whole stack under the mouse, which gives us its count
  local native = sellLinePrice(data)
  if not native and not isSellable(itemID) then return end
  local count = native and math.max(1, math.floor(native / unitPrice + 0.5)) or 1
  self:Debug("%s item %d unit price %d stack %d/%d", tt:GetName() or "?", itemID, unitPrice, count, stackSize)
  -- only what the native line doesn't already show: it has the current stack's price
  if stackSize <= 1 then
    if not native then addMoney(tt, unitPrice, L[" (item doesn't stack)"]) end
    return
  end
  local showPer = not (native and count == 1)
  local showFull = not (native and count == stackSize)
  local oneLine = not self.db.showFullStack or (self.db.holdShiftForMore and not IsShiftKeyDown())
  if showPer then
    if oneLine or not showFull then
      addMoney(tt, unitPrice, string.format(L[" (per; stacks to %d)"], stackSize))
    else
      addMoney(tt, unitPrice, L[" (per item)"])
    end
  end
  if showFull and not (oneLine and showPer) then
    addMoney(tt, stackSize * unitPrice, string.format(L[" (full stack of %d)"], stackSize))
  end
end

TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Item, onItemTooltip)
