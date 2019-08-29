--[[
   BetterVendorPrice by MooreaTV moorea@ymail.com (c) 2019 All rights reserved
   Licensed under LGPLv3 - No Warranty
   (contact the author if you need a different license)

   Get this addon binary release using curse/twitch client or on wowinterface
   The source of the addon resides on https://github.com/mooreatv/BetterVendorPrice
   (and the MoLib library at https://github.com/mooreatv/MoLib)

   Releases detail/changes are on https://github.com/mooreatv/BetterVendorPrice/releases

   Intial concept inspired by "Vendor Price" by Icesythe7 with a brand new implementation
   and different individual, current stack, full stack pricing information

   ]] --
--
-- our name, our empty default (and unused) anonymous ns
local addon, _ns = ...

-- Table and base functions created by MoLib
local BVP = _G[addon]
-- localization
BVP.L = BVP:GetLocalization()
local L = BVP.L

-- BVP.debug = 9 -- to debug before saved variables are loaded

BVP.slashCmdName = "bvp"
BVP.addonHash = "@project-abbreviated-hash@"
BVP.savedVarName = "betterVendorPriceSaved"
BVP.showFullStack = true

-- Events handling

local additionalEventHandlers = {

  PLAYER_ENTERING_WORLD = function(_self, ...)
    BVP:Debug("OnPlayerEnteringWorld " .. BVP:Dump(...))
    BVP:CreateOptionsPanel()
  end

}

BVP:RegisterEventHandlers(additionalEventHandlers)

--

function BVP:Help(msg)
  BVP:PrintDefault("BetterVendorPrice: " .. msg .. "\n" .. "/bvp config -- open addon config.\n" ..
                     "/bvp bug -- report a bug or issue.\n" ..
                     "/bvp debug on/off/level -- for debugging on at level or off.\n" ..
                     "/bvp version -- shows addon version.\n" ..
                     "/bvp fs -- toggle showing full stack value.")
end

function BVP.Slash(arg) -- can't be a : because used directly as slash command
  BVP:Debug("Got slash cmd: %", arg)
  if #arg == 0 then
    BVP:Help("commands, you can use the first letter of each:")
    return
  end
  local cmd = string.lower(string.sub(arg, 1, 1))
  local posRest = string.find(arg, " ")
  local rest = ""
  if not (posRest == nil) then
    rest = string.sub(arg, posRest + 1)
  end
  if cmd == "v" then
    -- version
    BVP:PrintDefault("BetterVendorPrice " .. BVP.manifestVersion ..
                       " (@project-abbreviated-hash@) by MooreaTv (moorea@ymail.com)")
  elseif cmd == "b" then
    local subText = L["Please submit on discord or on https://|cFF99E5FFbit.ly/vendorbug|r  or email"]
    BVP:PrintDefault(L["Better Vendor Price bug report open: "] .. subText)
    -- base molib will add version and date/timne
    BVP:BugReport(subText, "@project-abbreviated-hash@\n\n" .. L["Bug report from slash command"])
  elseif cmd == "c" then
    -- Show config panel
    -- InterfaceOptionsList_DisplayPanel(BVP.optionsPanel)
    InterfaceOptionsFrame:Show() -- onshow will clear the category if not already displayed
    InterfaceOptionsFrame_OpenToCategory(BVP.optionsPanel) -- gets our name selected
  elseif BVP:StartsWith(arg, "debug") then
    -- debug
    if rest == "on" then
      BVP:SetSaved("debug", 1)
    elseif rest == "off" then
      BVP:SetSaved("debug", nil)
    else
      BVP:SetSaved("debug", tonumber(rest))
    end
    BVP:PrintDefault("BetterVendorPrice debug now %", BVP.debug)
  elseif BVP:StartsWith(arg, "fs") then
	-- show full stack
	if BVP.showFullStack == false then
	 BVP.showFullStack = true
	else 
	 BVP.showFullStack = false;
	end
  else
    BVP:Help('unknown command "' .. arg .. '", usage:')
  end
end

-- Run/set at load time:

-- Slash

SlashCmdList["BetterVendorPrice_Slash_Command"] = BVP.Slash

SLASH_BetterVendorPrice_Slash_Command1 = "/bvp"

-- Options panel

function BVP:CreateOptionsPanel()
  if BVP.optionsPanel then
    BVP:Debug("Options Panel already setup")
    return
  end
  BVP:Debug("Creating Options Panel")

  local p = BVP:Frame(L["Better Vendor Price"])
  BVP.optionsPanel = p
  p:addText(L["Better Vendor Price options"], "GameFontNormalLarge"):Place()
  p:addText(L["These options let you control the behavior of BetterVendorPrice"] .. " " .. BVP.manifestVersion ..
              " @project-abbreviated-hash@"):Place()
  p:addText(L["Get Auction House DataBase (|cFF99E5FFAHDB|r) to see auction information on the toolip!"]):Place(0,16)

  p:addText(L["Development, troubleshooting and advanced options:"]):Place(40, 20)

  p:addButton("Bug Report", L["Get Information to submit a bug."] .. "\n|cFF99E5FF/bvp bug|r", "bug"):Place(4, 20)

  local debugLevel = p:addSlider(L["Debug level"], L["Sets the debug level"] .. "\n|cFF99E5FF/bvp debug X|r", 0, 9, 1,
                                 "Off"):Place(16, 30)

  function p:refresh()
    BVP:Debug("Options Panel refresh!")
    if BVP.debug then
      -- expose errors
      xpcall(function()
        self:HandleRefresh()
      end, geterrorhandler())
    else
      -- normal behavior for interface option panel: errors swallowed by caller
      self:HandleRefresh()
    end
  end

  function p:HandleRefresh()
    p:Init()
    debugLevel:SetValue(BVP.debug or 0)
  end

  function p:HandleOk()
    BVP:Debug(1, "BVP.optionsPanel.okay() internal")
    local sliderVal = debugLevel:GetValue()
    if sliderVal == 0 then
      sliderVal = nil
      if BVP.debug then
        BVP:PrintDefault("BVP options setting debug level changed from % to OFF.", BVP.debug)
      end
    else
      if BVP.debug ~= sliderVal then
        BVP:PrintDefault("BVP options setting debug level changed from % to %.", BVP.debug, sliderVal)
      end
    end
    BVP:SetSaved("debug", sliderVal)
  end

  function p:cancel()
    BVP:Debug("Options screen cancelled, not making any changes.")
  end

  function p:okay()
    BVP:Debug(3, "BVP.optionsPanel.okay() wrapper")
    if BVP.debug then
      -- expose errors
      xpcall(function()
        self:HandleOk()
      end, geterrorhandler())
    else
      -- normal behavior for interface option panel: errors swallowed by caller
      self:HandleOk()
    end
  end
  -- Add the panel to the Interface Options
  InterfaceOptions_AddCategory(BVP.optionsPanel)
end

function BVP.ToolTipHook(t)
  local name, link = t:GetItem()
  if not link then
    BVP:Debug(1, "No item link for % on %", name, t:GetName())
    return
  end
  local auctionData = {}
  if AuctionDB and AuctionDB.AHGetAuctionInfoByLink then
    auctionData = AuctionDB:AHGetAuctionInfoByLink(link)
  end
  if auctionData.numAuctions then
    t:AddLine(
      BVP:format(L["AHDB last scan: % |4auction:auctions;, % |4item:total items;"], auctionData.numAuctions, auctionData.quantity))
  end
  if auctionData.minBid then
    SetTooltipMoney(t, auctionData.minBid, "STATIC", L["AHDB minbid"], L[" (per item)"])
  end
  if auctionData.minBuyout then
    SetTooltipMoney(t, auctionData.minBuyout, "STATIC", L["AHDB buyout"], L[" (per item)"])
  end
  local _, _, _, _, _, _, _, itemStackCount, _, _, itemSellPrice = GetItemInfo(link)
  BVP:Debug(2, "% Item % indiv sell price % stack size % (%)", t:GetName(), name, itemSellPrice, itemStackCount, link)
  if not itemSellPrice or itemSellPrice <= 0 then
    BVP:Debug(1, "Bad/no price for % (%): %", name, link, itemSellPrice)
    return
  end
  if itemStackCount > 1 then
    local c = GetMouseFocus()
    if not c then
      error("nil GetMouseFocus()")
    end
    BVP:Debug(3, "Mouse focus is on % % % %", c:GetName(), c:GetObjectType(), c.count, c.Count)
    -- This my finding to make it work for AH listings for instance
    local bn = c:GetName() and (c:GetName() .. "Count")
    local count = c.count or (c.Count and c.Count:GetText()) or (c.Quantity and c.Quantity:GetText()) or
                    (bn and _G[bn] and _G[bn]:GetText())
    count = tonumber(count) or 1
    if count <= 1 then
      count = 1
    end
    local curValue = count * itemSellPrice
    local maxValue = itemStackCount * itemSellPrice
    SetTooltipMoney(t, itemSellPrice, "STATIC", L["Vendors for:"], string.format(L[" (per item)"], count))
    if count > 1 and count ~= itemStackCount then
      SetTooltipMoney(t, curValue, "STATIC", L["Vendors for:"], string.format(L[" (current stack of %d)"], count))
    end
    
    if BVP.showFullStack == true then
		SetTooltipMoney(t, maxValue, "STATIC", L["Vendors for:"], string.format(L[" (full stack of %d)"], itemStackCount))
    end
  else
    SetTooltipMoney(t, itemSellPrice, "STATIC", L["Vendors for:"], L[" (item doesn't stack)"])
  end
  BVP:Debug(2, "t is % : %", t:GetName(), t.numMoneyFrames)
  return true
end

GameTooltip:HookScript("OnTooltipSetItem", BVP.ToolTipHook)
ItemRefTooltip:HookScript("OnTooltipSetItem", BVP.ToolTipHook)

--
BVP:Debug("bvp main file loaded")
