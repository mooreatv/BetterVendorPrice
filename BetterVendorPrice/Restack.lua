-- Restacking: merges partial stacks of the same item to free main bag slots. Moves items around, never destroys
-- or sells anything. Sources are partial stacks in the main bags; targets can also be partial stacks in the reagent
-- bag or a profession bag (the item is already there, so it fits), which frees a main bag slot too.
local _, BVP = ...
local L = BVP.L

local MOVE_TIMEOUT = 3 -- seconds for a move to complete (items unlocked) before giving up
local MAX_MOVES = 100

local function isMainBag(bag)
  if bag > Enum.BagIndex.Bag_4 then return false end
  local _, bagFamily = C_Container.GetContainerNumFreeSlots(bag)
  return bagFamily == 0
end

-- hyperlink -> {max, main = {{bag, slot, count}...}, other = {...}} for the partial stacks; anyLocked when an item
-- in the bags is locked (being moved).
local function partialStacks()
  local items, anyLocked = {}, false
  for bag = Enum.BagIndex.Backpack, Enum.BagIndex.ReagentBag do
    local main = isMainBag(bag)
    for slot = 1, C_Container.GetContainerNumSlots(bag) do
      local info = C_Container.GetContainerItemInfo(bag, slot)
      if info and info.isLocked then
        anyLocked = true
      elseif info then
        local max = select(8, C_Item.GetItemInfo(info.itemID))
        if max and max > 1 and info.stackCount < max then
          local it = items[info.hyperlink]
          if not it then
            it = {max = max, main = {}, other = {}}
            items[info.hyperlink] = it
          end
          table.insert(main and it.main or it.other, {bag = bag, slot = slot, count = info.stackCount})
        end
      end
    end
  end
  return items, anyLocked
end

-- Main bag slots restacking that item would free: its main bag partial stacks minus the slots still needed once
-- the other bags' partial stacks are filled up.
local function slotsFreed(it)
  local total, room = 0, 0
  for _, s in ipairs(it.main) do total = total + s.count end
  for _, s in ipairs(it.other) do room = room + it.max - s.count end
  return #it.main - math.ceil(math.max(total - room, 0) / it.max)
end

-- Total main bag slots restacking would free, and the set of item links it would free slots of.
function BVP:Restackable()
  local n, links = 0, {}
  for link, it in pairs(partialStacks()) do
    local freed = slotsFreed(it)
    if freed > 0 then
      n = n + freed
      links[link] = true
    end
  end
  return n, links
end

-- Next {from, to, amount} move, or nil when nothing more to gain.
local function nextMove(items)
  for _, it in pairs(items) do
    if slotsFreed(it) > 0 then
      table.sort(it.main, function(a, b) return a.count < b.count end)
      -- fill the other bags first, else the fullest main bag stack, from the smallest one
      local to = it.other[1] or it.main[#it.main]
      local from = it.main[1]
      if from ~= to then return {from = from, to = to, amount = math.min(from.count, it.max - to.count)} end
    end
  end
end

local function mainFreeSlots()
  local n = 0
  for bag = Enum.BagIndex.Backpack, Enum.BagIndex.Bag_4 do
    if isMainBag(bag) then n = n + C_Container.GetContainerNumFreeSlots(bag) end
  end
  return n
end

local function finish(self, reason)
  local r = self.restacking
  self.restacking = nil
  if reason then self:Debug("restack stopped: %s", reason) end
  self:UpdateBags()
  if r.done then r.done(self, mainFreeSlots() - r.before) end
end

local function step(self, started)
  local r = self.restacking
  if not r then return end
  local items, anyLocked = partialStacks()
  if anyLocked then
    if GetTime() - started > MOVE_TIMEOUT then return finish(self, "items stayed locked") end
    C_Timer.After(0.1, function() step(self, started) end)
    return
  end
  if GetCursorInfo() then return finish(self, "something is on the cursor") end
  local m = nextMove(items)
  if not m or r.moves >= MAX_MOVES then return finish(self) end
  r.moves = r.moves + 1
  self:Debug("restack move %d: %d from %d/%d to %d/%d", r.moves, m.amount, m.from.bag, m.from.slot, m.to.bag, m.to.slot)
  if m.amount == m.from.count then
    C_Container.PickupContainerItem(m.from.bag, m.from.slot)
  else
    C_Container.SplitContainerItem(m.from.bag, m.from.slot, m.amount)
  end
  C_Container.PickupContainerItem(m.to.bag, m.to.slot)
  local now = GetTime()
  C_Timer.After(0.1, function() step(self, now) end)
end

-- Restacks, then calls done(self, slotsFreed).
function BVP:Restack(done)
  if self.restacking then return end
  self.restacking = {moves = 0, done = done, before = mainFreeSlots()}
  step(self, GetTime())
end

BVP:AddCommand("restack", function(self)
  self:Restack(function(s, freed) s:Print(L["Restacked: %d main bag slot(s) freed."], freed) end)
end, "restack - merge partial stacks to free bag slots")
