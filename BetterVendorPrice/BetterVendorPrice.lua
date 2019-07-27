--[[
   BetterVendorPrice by MooreaTV moorea@ymail.com (c) 2019 All rights reserved
   Licensed under LGPLv3 - No Warranty
   (contact the author if you need a different license)

   Get this addon binary release using curse/twitch client or on wowinterface
   The source of the addon resides on https://github.com/mooreatv/BetterVendorPrice
   (and the MoLib library at https://github.com/mooreatv/MoLib)

   Releases detail/changes are on https://github.com/mooreatv/BetterVendorPrice/releases
   ]] --
--
-- our name, our empty default (and unused) anonymous ns
local addon, _ns = ...

-- Table and base functions created by MoLib
local BVP = _G[addon]
-- localization
BVP.L = BVP:GetLocalization()
local L = BVP.L

BVP.debug = 9 -- to debug before saved variables are loaded

BVP.EventHdlrs = {

  PLAYER_ENTERING_WORLD = function(_self, ...)
    BVP:Debug("OnPlayerEnteringWorld " .. BVP:Dump(...))
    BVP:CreateOptionsPanel()
  end,

  ADDON_LOADED = function(_self, _event, name)
    BVP:Debug(9, "Addon % loaded", name)
    if name ~= addon then
      return -- not us, return
    end
    -- check for dev version (need to split the tags or they get substituted)
    if BVP.manifestVersion == "@" .. "project-version" .. "@" then
      BVP.manifestVersion = "vX.YY.ZZ"
    end
    BVP:PrintDefault("BetterVendorPrice " .. BVP.manifestVersion .. " by MooreaTv: type /bvp for command list/help.")
    if betterVendorPriceSaved == nil then
      BVP:Debug("Initialized empty saved vars")
      betterVendorPriceSaved = {}
    end
    betterVendorPriceSaved.addonVersion = BVP.manifestVersion
    betterVendorPriceSaved.addonHash = "@project-abbreviated-hash@"
    BVP:deepmerge(BVP, nil, betterVendorPriceSaved)
    BVP:Debug(3, "Merged in saved variables.")
  end
}

function BVP:OnEvent(event, first, ...)
  BVP:Debug(8, "OnEvent called for % e=% %", self:GetName(), event, first)
  local handler = BVP.EventHdlrs[event]
  if handler then
    return handler(self, event, first, ...)
  end
  BVP:Error("Unexpected event without handler %", event)
end

function BVP:Help(msg)
  BVP:PrintDefault("BetterVendorPrice: " .. msg .. "\n" .. "/bvp config -- open addon config\n" ..
                     "/bvp debug on/off/level -- for debugging on at level or off.\n" ..
                     "/bvp version -- shows addon version")
end

-- returns 1 if changed, 0 if same as live value
-- number instead of boolean so we can add them in handleOk
-- (saved var isn't checked/always set)
function BVP:SetSaved(name, value)
  local changed = (value ~= self[name])
  self[name] = value
  betterVendorPriceSaved[name] = value
  BVP:Debug(8, "(Saved) Setting % set to % - betterVendorPriceSaved=%", name, value, betterVendorPriceSaved)
  if changed then
    return 1
  else
    return 0
  end
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
  if cmd == "s" then
    -- show
    BVP:ShowGrid()
  elseif cmd == "h" then
    BVP:HideGrid()
  elseif cmd == "t" then
    BVP:ToggleGrid()
  elseif cmd == "i" then
    local sec = 8
    BVP:PrintDefault("BetterVendorPrice showing display (debug) info for % seconds", sec)
    BVP:ShowDisplayInfo(sec)
  elseif cmd == "v" then
    -- version
    BVP:PrintDefault("BetterVendorPrice " .. BVP.manifestVersion ..
                       " (@project-abbreviated-hash@) by MooreaTv (moorea@ymail.com)")
  elseif BVP:StartsWith(arg, "coord") then
    if BVP.coordinateShown then
      BVP:PrintDefault("BetterVendorPrice coordinates update OFF, keeping visible for a few seconds.")
      BVP:HideCoordinates()
    else
      BVP:PrintDefault("BetterVendorPrice coordinates ON.")
      BVP:ShowCoordinates(true)
    end
  elseif cmd == "c" then
    -- Show config panel
    -- InterfaceOptionsList_DisplayPanel(BVP.optionsPanel)
    InterfaceOptionsFrame:Show() -- onshow will clear the category if not already displayed
    InterfaceOptionsFrame_OpenToCategory(BVP.optionsPanel) -- gets our name selected
  elseif cmd == "e" then
    -- copied from BetterVendorPrice, as augment on event trace
    UIParentLoadAddOn("Blizzard_DebugTools")
    -- hook our code, only once/if there are no other hooks
    if EventTraceFrame:GetScript("OnShow") == EventTraceFrame_OnShow then
      EventTraceFrame:HookScript("OnShow", function()
        EventTraceFrame.ignoredEvents = BVP:CloneTable(BVP.etraceIgnored)
        BVP:PrintDefault("Restored ignored etrace events: %", BVP.etraceIgnored)
      end)
    else
      BVP:Debug(3, "EventTraceFrame:OnShow already hooked, hopefully to ours")
    end
    -- save or anything starting with s that isn't the start/stop commands of actual eventtrace
    if BVP:StartsWith(rest, "s") and rest ~= "start" and rest ~= "stop" then
      BVP:SetSaved("etraceIgnored", BVP:CloneTable(EventTraceFrame.ignoredEvents))
      BVP:PrintDefault("Saved ignored etrace events: %", BVP.etraceIgnored)
    elseif BVP:StartsWith(rest, "c") then
      EventTraceFrame.ignoredEvents = {}
      BVP:PrintDefault("Cleared the current event filters")
    else -- leave the other sub commands unchanged, like start/stop and n
      BVP:Debug("Calling  EventTraceFrame_HandleSlashCmd(%)", rest)
      EventTraceFrame_HandleSlashCmd(rest)
    end
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
  else
    BVP:Help('unknown command "' .. arg .. '", usage:')
  end
end

-- Run/set at load time:

-- Slash

SlashCmdList["PixelPerfectAlign_Slash_Command"] = BVP.Slash

SLASH_PixelPerfectAlign_Slash_Command1 = "/bvp"

-- Events handling
BVP.frame = CreateFrame("Frame")

BVP.frame:SetScript("OnEvent", BVP.OnEvent)
for k, _ in pairs(BVP.EventHdlrs) do
  BVP.frame:RegisterEvent(k)
end

-- Options panel

function BVP:CreateOptionsPanel()
  if BVP.optionsPanel then
    BVP:Debug("Options Panel already setup")
    return
  end
  BVP:Debug("Creating Options Panel")

  local p = BVP:Frame(L["BetterVendorPrice"])
  BVP.optionsPanel = p
  p:addText(L["BetterVendorPrice options"], "GameFontNormalLarge"):Place()
  p:addText(L["These options let you control the behavior of BetterVendorPrice"] .. " " .. BVP.manifestVersion ..
              " @project-abbreviated-hash@"):Place()

  p:addText(L["Development, troubleshooting and advanced options:"]):Place(40, 20)

  p:addButton(L["Reset minimap button"], L["Resets the minimap button to back to initial default location"], function()
    BVP:SetSaved("buttonPos", nil)
    BVP:SetupMenu()
  end):Place(4, 20)

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
        BVP:PrintDefault("Options setting debug level changed from % to OFF.", BVP.debug)
      end
    else
      if BVP.debug ~= sliderVal then
        BVP:PrintDefault("Options setting debug level changed from % to %.", BVP.debug, sliderVal)
      end
    end
    BVP:SetSaved("debug", sliderVal)
  end

  function p:cancel()
    BVP:Warning("Options screen cancelled, not making any changes.")
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

--
BVP:Debug("bvp main file loaded")
