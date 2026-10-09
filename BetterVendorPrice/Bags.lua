-- Cheapest bag slot to destroy when the bags are full, stack aware. Never destroys anything itself: it highlights
-- the slot in the bags and says in chat which one it is when the main bags get full, after restacking (Restack.lua).
local _, BVP = ...
local L = BVP.L

-- Only the main bags count: loot goes there. The reagent bag and profession bags can still have room.
local FIRST_BAG, LAST_BAG = Enum.BagIndex.Backpack, Enum.BagIndex.Bag_4
local RECENT = 3600 -- seconds of gains used to guess how much more of an item will drop

-- itemID -> list of {time, count gained}, this session only
local gains = {}
local lastTotals -- itemID -> count in all bags at the previous scan
local busy = {} -- open merchant/bank/mail/trade... windows: items gained there are not drops

BVP:On("PLAYER_INTERACTION_MANAGER_FRAME_SHOW", function(_, kind) busy[kind] = true end)
BVP:On("PLAYER_INTERACTION_MANAGER_FRAME_HIDE", function(_, kind) busy[kind] = nil end)

local function recentGain(itemID, now)
  local list = gains[itemID]
  if not list then return 0 end
  local n = 0
  for i = #list, 1, -1 do
    if now - list[i][1] > RECENT then
      table.remove(list, i)
    else
      n = n + list[i][2]
    end
  end
  return n
end

local function recordGains(totals, now)
  if lastTotals and not next(busy) then
    for id, n in pairs(totals) do
      local d = n - (lastTotals[id] or 0)
      if d > 0 then
        gains[id] = gains[id] or {}
        table.insert(gains[id], {now, d})
      end
    end
  end
  lastTotals = totals
end

-- Scans the bags. Returns the number of free main bag slots and the candidate slot to destroy (nil if none).
-- Items restacking would free a slot of are skipped: that slot comes back for free (scored again once merged).
function BVP:ScanBags(restackable)
  local now = GetTime()
  local totals = {}
  for bag = FIRST_BAG, Enum.BagIndex.ReagentBag do
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info then totals[info.itemID] = (totals[info.itemID] or 0) + info.stackCount end
    end
  end
  recordGains(totals, now)

  local free, best = 0, nil
  for bag = FIRST_BAG, LAST_BAG do
    local numFree, bagFamily = C_Container.GetContainerNumFreeSlots(bag)
    if bagFamily == 0 then -- profession bags only take their own kind of items
      free = free + numFree
      for slot = 1, C_Container.GetContainerNumSlots(bag) do
        local c = self:ScoreSlot(bag, slot, now)
        if c and not restackable[c.link] and
          (not best or c.score < best.score or (c.score == best.score and c.value < best.value)) then best = c end
      end
    end
  end
  return free, best
end

-- {bag, slot, itemID, link, count, stackSize, value, score} or nil when the slot is empty or never a candidate.
function BVP:ScoreSlot(bag, slot, now)
  local info = C_Container.GetContainerItemInfo(bag, slot)
  if not info or info.hasNoValue or info.isLocked then return end
  if C_Container.GetContainerItemQuestInfo(bag, slot).isQuestItem then return end
  if self:IsKept(info.itemID) then return end
  local _, _, _, _, _, _, _, stackSize, _, _, unitPrice = C_Item.GetItemInfo(info.itemID)
  -- no vendor price (or vendors refuse it) doesn't mean worthless: Hearthstone, quest items...
  if not unitPrice or unitPrice <= 0 or not self:IsSellable(info.itemID) then return end
  local count = info.stackCount
  -- a stack that isn't full yet is worth what it will likely hold: as much more as dropped lately, up to full
  local extra = math.min(math.max(stackSize - count, 0), recentGain(info.itemID, now))
  return {
    bag = bag,
    slot = slot,
    itemID = info.itemID,
    link = info.hyperlink,
    count = count,
    stackSize = stackSize,
    value = count * unitPrice,
    score = (count + extra) * unitPrice
  }
end

function BVP:CandidateText(c)
  local s = c.link
  if c.stackSize > 1 then s = s .. (" %d/%d"):format(c.count, c.stackSize) end
  s = s .. " " .. C_CurrencyInfo.GetCoinTextureString(c.value)
  if c.score > c.value then
    s = s .. " " ..
          string.format(L["(worth %s with the drops coming in)"], C_CurrencyInfo.GetCoinTextureString(c.score))
  end
  return s
end

-- Says what restacking could free and which slot is the cheapest (full: when the bags just got full).
function BVP:Report(full)
  if self.restackable > 0 then self:Print(L["Restacking would free %d slot(s): /bvp restack"], self.restackable) end
  if self.candidate then
    self:Print((full and L["Bags full, cheapest slot: %s"] or L["Cheapest slot: %s"]),
               self:CandidateText(self.candidate))
  else
    self:Print(L["No vendorable item in the main bags."])
  end
end

-- Restacks first (unless turned off) then reports.
function BVP:CheckBags(full)
  if not (self.db.autoRestack and self.restackable > 0) then
    self:Report(full)
    return
  end
  self:Restack(function(s, freed)
    s:Print(L["Restacked: %d main bag slot(s) freed."], freed)
    if not full or s.freeSlots == 0 then s:Report(full) end
  end)
end

-- Highlight in the default bag frames

local function highlight(button, on)
  local t = button.bvpCheapest
  if not t then
    if not on then return end
    t = button:CreateTexture(nil, "OVERLAY", nil, 7)
    t:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    t:SetBlendMode("ADD")
    t:SetVertexColor(1, 0.2, 0.2)
    t:SetPoint("CENTER")
    local w, h = button:GetSize()
    t:SetSize(w * 1.8, h * 1.8)
    button.bvpCheapest = t
  end
  t:SetShown(on)
end

function BVP:IsCandidateButton(button)
  local c = self.candidate
  return c and self.db.highlightCheapest and button.GetBagID and button:GetBagID() == c.bag and button:GetID() == c.slot
end

local function refreshFrame(frame)
  if not frame:IsShown() then return end
  for _, button in frame:EnumerateValidItems() do highlight(button, BVP:IsCandidateButton(button)) end
end

-- The default UI's bag frames (combined bags or one per bag). Not ContainerFrameUtil_EnumerateContainerFrames: its
-- list is created lazily by the first caller, which taints it when that's us (blocked actions when opening the bank).
local function bagFrames()
  local frames = {ContainerFrameCombinedBags}
  for _, frame in ipairs(ContainerFrameContainer.ContainerFrames) do table.insert(frames, frame) end
  return frames
end

function BVP:RefreshHighlight() for _, frame in ipairs(bagFrames()) do refreshFrame(frame) end end

function BVP:UpdateBags()
  local wasFree = self.freeSlots
  local restackableLinks
  self.restackable, restackableLinks = self:Restackable()
  self.freeSlots, self.candidate = self:ScanBags(restackableLinks)
  self:RefreshHighlight()
  if self.restacking then return end -- reports when done
  if self.freeSlots == 0 and wasFree ~= 0 and self.db.reportFull then self:CheckBags(true) end
end

-- Items never suggested: the ones kept with /bvp keep (account wide), e.g. a cheap fishing pole you still need.
function BVP:IsKept(itemID) return self.sv.keep[itemID] == true end

local function itemLink(itemID) return select(2, C_Item.GetItemInfo(itemID)) or ("item:" .. itemID) end

BVP:AddCommand("keep", function(self, rest)
  if rest:lower() == "list" then
    if not next(self.sv.keep) then
      self:Print(L["No kept items."])
      return
    end
    self:Print(L["Kept items (never suggested to throw away):"])
    for id in pairs(self.sv.keep) do print("  " .. itemLink(id)) end
    return
  end
  local id = tonumber(rest) or tonumber(rest:match("item:(%d+)"))
  if rest == "" then
    id = self.candidate and self.candidate.itemID
    if not id then
      self:Print(L["No cheapest slot to keep."])
      return
    end
  elseif not id then
    self:Print(L["usage: /bvp keep [item|list]"])
    return
  end
  self.sv.keep[id] = not self.sv.keep[id] or nil
  self:Print(self.sv.keep[id] and L["Keeping %s, it won't be suggested anymore."] or L["%s can be suggested again."],
             itemLink(id))
  self:UpdateBags()
  if rest == "" then self:Report(false) end
end, "keep [item|list] - never suggest that item (default: the cheapest slot) to throw away, again to undo")

BVP:Listen("LOGIN", function(self)
  for _, frame in ipairs(bagFrames()) do hooksecurefunc(frame, "UpdateItems", refreshFrame) end
  self:On("BAG_UPDATE_DELAYED", self.UpdateBags)
  self:UpdateBags()
end)

BVP:Listen("OPTION_CHANGED", function(self) self:RefreshHighlight() end)

-- Looting with full bags: say it again (not more than every 30s).
local lastFullError = 0
BVP:On("UI_ERROR_MESSAGE", function(self, _, msg)
  if msg ~= ERR_INV_FULL or not self.db.reportFull or self.restacking or self.freeSlots ~= 0 then return end
  local now = GetTime()
  if now - lastFullError < 30 then return end
  lastFullError = now
  self:CheckBags(true)
end)

BVP:AddCommand("cheapest", function(self)
  self:UpdateBags()
  self:CheckBags(false)
end, "cheapest - restack (unless turned off) and show which bag slot is the cheapest to throw away")
