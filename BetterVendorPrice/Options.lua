-- Options panel (Game Menu > Options > AddOns > Better Vendor Price), also reachable with /bvp config.
local _, BVP = ...
local L = BVP.L

-- {key, label, tooltip} checkboxes on BVP.db[key]
local CHECKBOXES = {
  {
    "showFullStack", L["Show full stack vendor price info"],
    L["Also show what a full stack sells for, not just the price per item"]
  },
  {"holdShiftForMore", L["Show all only when Shift is held"], L["Whether to require the shift key to show full info"]},
  {
    "highlightCheapest", L["Highlight the cheapest slot in the bags"],
    L["The item to throw away first when your bags are full: lowest vendor value, counting what a stack that is " ..
      "still filling up with drops will be worth. Never destroys anything itself."]
  }, {
    "reportFull", L["Chat message when the bags are full"],
    L["When your main bags (not the reagent or profession bags) get full, say which slot is the cheapest, or " ..
      "which item to restack to free a slot."]
  }, {
    "autoRestack", L["Restack when the bags are full"],
    L["When your main bags get full (and with /bvp cheapest), merge partial stacks of the same item to free " ..
      "slots, also into the reagent and profession bags. Only moves items. /bvp restack does it anytime."]
  }, {"debug", "Debug output", "Print detailed messages to the chat window."}
}

local refreshers = {}
local function Refresh() for _, fn in ipairs(refreshers) do fn() end end

local function tooltip(widget, title, text)
  widget:SetScript("OnEnter", function(w)
    GameTooltip:SetOwner(w, "ANCHOR_RIGHT")
    GameTooltip:SetText(title)
    GameTooltip:AddLine(text, 1, 1, 1, true)
    GameTooltip:Show()
  end)
  widget:SetScript("OnLeave", GameTooltip_Hide)
end

local function build()
  local panel = CreateFrame("Frame")
  panel.name = L["Better Vendor Price"]
  panel:SetScript("OnShow", Refresh)
  local t = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
  t:SetPoint("TOPLEFT", 16, -16)
  t:SetText(L["Better Vendor Price"] .. " (" .. BVP.version .. ")")
  local sub = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  sub:SetPoint("TOPLEFT", t, "BOTTOMLEFT", 0, -8)
  sub:SetText("All commands: |cFF99E5FF/bvp help|r")
  local ahdb = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
  ahdb:SetPoint("TOPLEFT", sub, "BOTTOMLEFT", 0, -8)
  ahdb:SetText("Install |cFF99E5FFAHDB|r (Auction House DataBase) for AH prices and history in the same tooltips.")

  local prev = ahdb
  for _, o in ipairs(CHECKBOXES) do
    local key = o[1]
    local cb = CreateFrame("CheckButton", nil, panel, "UICheckButtonTemplate")
    cb:SetPoint("TOPLEFT", prev, "BOTTOMLEFT", 0, prev == ahdb and -16 or -2)
    cb.Text:SetText(o[2])
    cb:SetScript("OnClick", function(b)
      BVP.db[key] = b:GetChecked() and true or false
      BVP:Fire("OPTION_CHANGED", key)
    end)
    tooltip(cb, o[2], o[3])
    refreshers[#refreshers + 1] = function() cb:SetChecked(BVP.db[key]) end
    prev = cb
  end

  BVP.category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
  Settings.RegisterAddOnCategory(BVP.category)
end

BVP:Listen("LOGIN", build)

BVP:AddCommand("config", function(self) Settings.OpenToCategory(self.category:GetID()) end,
               "config - open the options panel")
