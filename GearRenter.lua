GR = LibStub("AceAddon-3.0"):NewAddon("Gear Renter", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")

local options = {
  name = "GearRenter",
  handler = GR,
  type = 'group',
  args = {
    enable = {
      type = 'toggle',
      order = 1,
      name = 'Enabled',
      desc = 'Enable or disable this addon.',
      set = function(info, val) if (val) then GR:Enable() else GR:Disable() end end,
      get = function(info) return GR.enabledState end,
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

function GR:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("GearRenterDB", defaults)
  local parent = LibStub("AceConfig-3.0"):RegisterOptionsTable("GearRenter", options, {"GearRenter", "gr"})
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("GearRenter", "GearRenter")
  profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
  LibStub("AceConfig-3.0"):RegisterOptionsTable("GearRenter.profiles", profiles)
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("GearRenter.profiles", "Profiles", "GearRenter")

  self.queue = {}
  self.nextQueue = function() 
    if #self.queue > 0 then
      item = table.remove(self.queue, 1)
      func = item[1]
      args = slice(item, 2)

      -- if func == ContainerRefundItemPurchase then
      --  GR:Print("ContainerRefundItemPurchase")
      -- elseif func == BuyMerchantItem then
      --  GR:Print("BuyMerchantItem")
      -- elseif func == EquipItemByName then
      --  GR:Print("EquipItemByName")
      -- end

      func(unpack(args))
    else
      self.machine:set('none')
    end
  end
  self.machine = self.statemachine.create({
    initial = 'none',
    events = {
      {name = 'start', from = {'none', 'started', 'sold', 'bought', 'equipped'}, to = 'started'},
      {name = 'sell', from = 'started', to = 'sold'},
      {name = 'buy', from = 'sold', to = 'bought'},
      {name = 'equip', from = 'bought', to = 'equipped'},
      --{name = 'stop', from = {'none', 'started', 'sold', 'bought', 'equipped'}, to = 'none'}
    },
    callbacks = {
      onstart = function(self, event, from, to) 
        --GR:Print('start')
        GR.machine:sell()
      end,
      onsell = function(self, event, from, to) 
        --GR:Print('sell')
        GR:nextQueue()
      end,
      onbuy = function(self, event, from, to) 
        --GR:Print('buy')
        GR:nextQueue()
      end,
      onequip = function(self, event, from, to) 
        --GR:Print('equip')
        GR:nextQueue()
      end,
    }
  })
end

function GR:OnEnable()
  -- self:RegisterEvent("MERCHANT_SHOW")
  --self:RegisterEvent("BAG_UPDATE")
  --self:RegisterEvent("CURRENCY_DISPLAY_UPDATE")
  self:RegisterEvent("UNIT_INVENTORY_CHANGED")  
  self:RegisterChatCommand("rebuy", "Rebuy")
end

function GR:OnDisable()
  self:UnregisterChatCommand("rebuy")
  self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
end

function GR:UNIT_INVENTORY_CHANGED(event, unitID)
  self:ScheduleTimer(function()
    if self.machine:is('started') then
      self.machine:sell()  
    elseif self.machine:is('sold') then
      self.machine:buy()
    elseif self.machine:is('bought') then
      self.machine:equip()
    elseif self.machine:is('equipped') then
      self.machine:start()
    end
  end, 0.5)
end

function GR:Rebuy(input)
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
        end
      end
    end
  end
  
  self.machine:start()

 --  delay = 1
  -- for _,qi in ipairs(queue) do
 --    self:ScheduleTimer(function()
 --      func = qi[1]
 --      args = slice(qi, 2)
 --      func(unpack(args))
 --    end, delay)
 --    delay = delay + 2
  -- end
end
