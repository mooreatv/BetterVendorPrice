-- Kept items: never suggested to throw away (account wide), e.g. a cheap fishing pole you still need. Set with
-- /bvp keep [item] (default: the cheapest slot) or in the /bvp keep list window: drop items on it, Ctrl+Right click
-- them in the bags while it is shown, or type a name / ID in its box; its X buttons (or /bvp unkeep) remove them.
local _, BVP = ...
local L = BVP.L

local ROW_H = 22

local frame -- the window, built on first use
local rows = {}

local function refreshWindow() if frame and frame:IsShown() then frame:Refresh() end end

function BVP:IsKept(itemID) return self.sv.keep[itemID] == true end

local function itemLink(id)
  local name, link = C_Item.GetItemInfo(id)
  if not name then C_Item.RequestLoadItemDataByID(id) end
  return link or ("item:" .. id)
end

-- Item id from an id, a link or a name (exact, any case: kept items first, then any item the client knows).
local function toItemID(text)
  text = (text or ""):match("^%s*(.-)%s*$")
  if text == "" then return nil end
  local id = tonumber(text) or tonumber(text:match("item:(%d+)"))
  if id then return id end
  local name = text:lower()
  for kept in pairs(BVP.sv.keep) do
    local n = C_Item.GetItemInfo(kept)
    if n and n:lower() == name then return kept end
  end
  return (C_Item.GetItemInfoInstant(text))
end

function BVP:SetKept(id, kept)
  if (self.sv.keep[id] or false) == kept then return end
  self.sv.keep[id] = kept or nil
  self:Print(kept and L["Keeping %s, it won't be suggested anymore."] or L["%s can be suggested again."], itemLink(id))
  self:UpdateBags()
  refreshWindow()
end

-- Kept item IDs by name (not cached yet: by ID, after the named ones).
local function sortedIDs()
  local ids = {}
  for id in pairs(BVP.sv.keep) do ids[#ids + 1] = id end
  table.sort(ids, function(a, b)
    local na, nb = C_Item.GetItemInfo(a) or "~", C_Item.GetItemInfo(b) or "~"
    if na ~= nb then return na < nb end
    return a < b
  end)
  return ids
end

-- Window

-- An item held on the cursor (picked up from the bags) is kept, and goes back to its bag slot.
local function dropCursor()
  local kind, id = GetCursorInfo()
  if kind ~= "item" then return false end
  ClearCursor()
  BVP:SetKept(id, true)
  return true
end

local function getRow(i)
  if rows[i] then return rows[i] end
  local r = CreateFrame("Button", nil, frame.child)
  r:SetHeight(ROW_H)
  r:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
  r:SetPoint("TOPRIGHT", 0, -(i - 1) * ROW_H)
  r.icon = r:CreateTexture(nil, "ARTWORK")
  r.icon:SetSize(ROW_H - 4, ROW_H - 4)
  r.icon:SetPoint("LEFT", 2, 0)
  r.remove = CreateFrame("Button", nil, r, "UIPanelCloseButton")
  r.remove:SetSize(ROW_H, ROW_H)
  r.remove:SetPoint("RIGHT")
  r.remove:SetScript("OnClick", function() BVP:SetKept(r.id, false) end)
  r.name = r:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  r.name:SetPoint("LEFT", r.icon, "RIGHT", 6, 0)
  r.name:SetPoint("RIGHT", r.remove, "LEFT", -4, 0)
  r.name:SetJustifyH("LEFT")
  r.name:SetWordWrap(false)
  local hl = r:CreateTexture(nil, "HIGHLIGHT")
  hl:SetAllPoints()
  hl:SetColorTexture(1, 1, 1, 0.1)
  r:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetItemByID(self.id)
    GameTooltip:Show()
  end)
  r:SetScript("OnLeave", GameTooltip_Hide)
  r:SetScript("OnReceiveDrag", dropCursor)
  r:SetScript("OnClick", dropCursor)
  rows[i] = r
  return r
end

local function refreshRows()
  local ids = sortedIDs()
  for i, id in ipairs(ids) do
    local r = getRow(i)
    r.id = id
    local name, _, quality = C_Item.GetItemInfo(id)
    if not name then C_Item.RequestLoadItemDataByID(id) end
    r.icon:SetTexture(C_Item.GetItemIconByID(id))
    r.name:SetText((name or ("item " .. id)) .. " |cFF808080(" .. id .. ")|r")
    if quality then
      local cr, cg, cb = C_Item.GetItemQualityColor(quality) -- 4th value is the hex string, not an alpha
      r.name:SetTextColor(cr, cg, cb)
    else
      r.name:SetTextColor(1, 1, 1)
    end
    r:Show()
  end
  for i = #ids + 1, #rows do rows[i]:Hide() end
  frame.child:SetHeight(math.max(1, #ids * ROW_H))
  frame.empty:SetShown(#ids == 0)
end

local function build()
  local f = CreateFrame("Frame", "BetterVendorPriceKeep", UIParent, "BackdropTemplate")
  frame = f
  f:Hide()
  f:SetSize(340, 440)
  f:SetPoint("CENTER", 200, 0)
  f:SetFrameStrata("DIALOG")
  f:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = {left = 11, right = 11, top = 11, bottom = 11}
  })
  f:EnableMouse(true)
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() if not GetCursorInfo() then f:StartMoving() end end)
  f:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)
  f:SetScript("OnReceiveDrag", dropCursor)
  f:SetScript("OnMouseUp", dropCursor)
  tinsert(UISpecialFrames, "BetterVendorPriceKeep") -- Escape closes it

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", 0, -16)
  title:SetText(L["Better Vendor Price: kept items"])
  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -6, -6)

  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  hint:SetPoint("TOPLEFT", 20, -40)
  hint:SetPoint("RIGHT", -20, 0)
  hint:SetJustifyH("LEFT")
  hint:SetText(L["Never suggested to throw away. Drop items from your bags on this window, Ctrl+Right click them " ..
                 "in your bags, or type an item's name or ID in this box:"])

  local edit = CreateFrame("EditBox", nil, f, "InputBoxTemplate")
  edit:SetSize(200, 20)
  edit:SetPoint("TOPLEFT", 26, -80)
  edit:SetAutoFocus(false)
  local function add()
    local text = edit:GetText()
    local id = toItemID(text)
    if id then
      BVP:SetKept(id, true)
      edit:SetText("")
      edit:ClearFocus()
    elseif text ~= "" then
      BVP:Print(L["Unknown item %s, use its link or id."], text)
    end
  end
  edit:SetScript("OnEnterPressed", add)
  edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
  local addButton = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
  addButton:SetSize(70, 22)
  addButton:SetText(L["Keep"])
  addButton:SetScript("OnClick", add)
  addButton:SetPoint("LEFT", edit, "RIGHT", 8, 0)

  local inset = CreateFrame("Frame", nil, f, "BackdropTemplate")
  inset:SetPoint("TOPLEFT", 16, -108)
  inset:SetPoint("BOTTOMRIGHT", -16, 16)
  inset:SetBackdrop({bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1})
  inset:SetBackdropColor(0, 0, 0, 0.4)
  inset:SetBackdropBorderColor(0.4, 0.4, 0.4, 1)
  f.empty = inset:CreateFontString(nil, "OVERLAY", "GameFontDisable")
  f.empty:SetPoint("CENTER")
  f.empty:SetText(L["Drop items here"])

  local scroll = CreateFrame("ScrollFrame", "BetterVendorPriceKeepScroll", inset, "UIPanelScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", 4, -4)
  scroll:SetPoint("BOTTOMRIGHT", -26, 4)
  local child = CreateFrame("Frame", nil, scroll)
  child:SetSize(270, 1)
  scroll:SetScript("OnSizeChanged", function(_, w) child:SetWidth(w) end)
  scroll:SetScrollChild(child)
  f.child = child

  f.Refresh = refreshRows
  f:SetScript("OnShow", refreshRows)
end

function BVP:ToggleKeepWindow()
  if not frame then build() end
  frame:SetShown(not frame:IsShown())
end

-- Names and icons of items not cached yet arrive later.
local refreshPending
BVP:On("GET_ITEM_INFO_RECEIVED", function()
  if refreshPending or not (frame and frame:IsShown()) then return end
  refreshPending = true
  C_Timer.After(0.2, function()
    refreshPending = nil
    refreshWindow()
  end)
end)

BVP:Listen("LOGIN", function(self)
  -- Ctrl+Right click on a bag item while the window is shown keeps it. Modified bag clicks never use (sell) the item,
  -- they go through HandleModifiedItemClick (Ctrl alone also previews gear in the dressing room).
  hooksecurefunc("HandleModifiedItemClick", function(link)
    if not (frame and frame:IsShown() and IsControlKeyDown() and GetMouseButtonClicked() == "RightButton") then
      return
    end
    local id = link and tonumber(link:match("item:(%d+)"))
    if id then self:SetKept(id, true) end
  end)
end)

BVP:AddCommand("keep", function(self, rest)
  if rest:lower() == "list" then
    self:ToggleKeepWindow()
    return
  end
  if rest == "" then
    local id = self.candidate and self.candidate.itemID
    if not id then
      self:Print(L["No cheapest slot to keep."])
      return
    end
    self:SetKept(id, true)
    self:Report(false)
    return
  end
  local id = toItemID(rest)
  if not id then
    self:Print(L["Unknown item %s, use its link or id."], rest)
    return
  end
  self:SetKept(id, true)
end, "keep [item|list] - never suggest that item (id, link or name; default: the cheapest slot) to throw away; " ..
                 "list: the kept items window")

BVP:AddCommand("unkeep", function(self, rest)
  local id = toItemID(rest)
  if not id or not self.sv.keep[id] then
    self:Print(L["Not a kept item: %s (see /bvp keep list)"], rest)
    return
  end
  self:SetKept(id, false)
end, "unkeep item - the item (id, link or name) can be suggested to throw away again")
