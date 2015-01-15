GearRenter = LibStub("AceAddon-3.0"):NewAddon("Gear Renter", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local options = {
  name = "GearRenter",
  handler = GearRenter,
  type = 'group',
  args = {
    enable = {
      type = 'toggle',
      order = 1,
      name = 'Enabled',
      desc = 'Enable or disable this addon.',
      set = function(info, val) if (val) then GearRenter:Enable() else GearRenter:Disable() end end,
      get = function(info) return GearRenter.enabledState end,
    },
  },
}

local defaults = {
  profile = {
    
  }
}

function slice(list, index) 
  return { select(index, unpack(list)) } 
end

function GearRenter:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("GearRenterDB", defaults)
  local parent = LibStub("AceConfig-3.0"):RegisterOptionsTable("GearRenter", options, {"GearRenter", "gr"})
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("GearRenter", "GearRenter")
  profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
  LibStub("AceConfig-3.0"):RegisterOptionsTable("GearRenter.profiles", profiles)
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("GearRenter.profiles", "Profiles", "GearRenter")

  self.queue = {}  
  -- self.machine = self.statemachine.create({
  --   initial = 'none',
  --   events = {
  --     {name = 'start', from = {'none', 'started', 'sold', 'bought', 'equipped'}, to = 'started'},
  --     {name = 'sell', from = 'started', to = 'sold'},
  --     {name = 'buy', from = 'sold', to = 'bought'},
  --     {name = 'equip', from = 'bought', to = 'equipped'},
  --     --{name = 'stop', from = {'none', 'started', 'sold', 'bought', 'equipped'}, to = 'none'}
  --   },
  --   callbacks = {
  --     onstart = function(self, event, from, to) 
  --       --GearRenter:Print('start')
  --       GearRenter.machine:sell()
  --     end,
  --     onsell = function(self, event, from, to) 
  --       --GearRenter:Print('sell')
  --       GearRenter:NextQueue()
  --     end,
  --     onbuy = function(self, event, from, to) 
  --       --GearRenter:Print('buy')
  --       GearRenter:NextQueue()
  --     end,
  --     onequip = function(self, event, from, to) 
  --       --GearRenter:Print('equip')
  --       GearRenter:NextQueue()
  --     end,
  --   }
  -- })
end

function GearRenter:NextQueue()
  if #self.queue > 0 then
    item = table.remove(self.queue, 1)
    func = item[1]
    args = slice(item, 2)

    -- if func == ContainerRefundItemPurchase then
    --  GearRenter:Print("ContainerRefundItemPurchase")
    -- elseif func == BuyMerchantItem then
    --  GearRenter:Print("BuyMerchantItem")
    -- elseif func == EquipItemByName then
    --  GearRenter:Print("EquipItemByName")
    -- end

    func(unpack(args))
  else
    -- self.machine:set('none')
  end
end

function GearRenter:OnEnable()
  --self:RegisterEvent("UNIT_INVENTORY_CHANGED")  
  self:RegisterChatCommand("rebuy", "Rebuy")
end

function GearRenter:OnDisable()
  self:UnregisterChatCommand("rebuy")
  --self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
end

-- function GearRenter:UNIT_INVENTORY_CHANGED(event, unitID)
--   self:ScheduleTimer(function()
--     if self.machine:is('started') then
--       self.machine:sell()  
--     elseif self.machine:is('sold') then
--       self.machine:buy()
--     elseif self.machine:is('bought') then
--       self.machine:equip()
--     elseif self.machine:is('equipped') then
--       self.machine:start()
--     end
--   end, 0.5)
-- end

function GearRenter:Rebuy_OnClick()
  self:Rebuy()
end

function GearRenter:Rebuy()
  if not MerchantFrame:IsShown() then
    self:Print("Not at a merchant.")
    return
  end

  local currencies = {GetMerchantCurrencies()}
  local currencyNames = {}
  for _, currency in ipairs(currencies) do
    if currency ~= CONQUEST_CURRENCY and currency ~= HONOR_CURRENCY then
      self:Print("This merchant is not a conquest or honor vendor.")
      return
    end
    name, _, _, _, _, _, _ = GetCurrencyInfo(currency)
    currencyNames[name] = true
  end

  self.queue = {}
  for slotID=1,19 do
    money, itemCount, refundSec, currecycount, hasEnchants = GetContainerItemPurchaseInfo(-2, slotID, true)
    _, currencyQuantity, currencyName = GetContainerItemPurchaseCurrency(-2, slotID, 1, true)
    if currencyNames[currencyName] ~= nil and not(refundSec == nil) and refundSec > 0 and not hasEnchants then
      local itemID = GetInventoryItemID("player", slotID)
      _, itemLink, _, _, _, _, _, _, _, _, _ = GetItemInfo(itemID)   
      itemID = string.match(itemLink, "item:(%d+)")     

      for x=1,GetMerchantNumItems() do
        --local item, _, _, _, _, _, _ = GetMerchantItemInfo(x)
        local link = GetMerchantItemLink(x)
        local id = string.match(link, "item:(%d+)")  
        if itemID == id then
          --self:Print(string.format("Selling/buying/equipping %s", itemName))
          table.insert(self.queue, {ContainerRefundItemPurchase, -2, slotID})
          table.insert(self.queue, {BuyMerchantItem, x, 1})
          table.insert(self.queue, {EquipItemByName, link})
          -- doing this twice actually helps it to work
          table.insert(self.queue, {EquipItemByName, link})
        end
      end
    end
  end
  
  -- self.machine:start()

  GearRenterProgressFrame:Show();
  GearRenterProgressBar:SetMinMaxValues(0, 1);
  local queueLen = #self.queue;  

  self.repeatTimer = self:ScheduleRepeatingTimer(function()
    self:NextQueue()

    local progress = 1 - (#self.queue/queueLen)
    GearRenterProgressBar:SetValue(progress)
    GearRenterProgressBarText:SetText("Renting "..floor(progress * 100).."%")

    if #self.queue <= 0 then
      self:CancelTimer(self.repeatTimer)
      GearRenterProgressFrame:Hide();
    end
  end, 1)
end
