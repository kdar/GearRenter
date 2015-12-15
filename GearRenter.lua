GearRenter = LibStub("AceAddon-3.0"):NewAddon("Gear Renter", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local LibDialog = LibStub("LibDialog-1.0")

local options = {
  name = "GearRenter",
  handler = GearRenter,
  type = 'group',
  args = {
    enable = {
      type = 'toggle',
      order = 1,
      name = 'Enabled',
      width = 'double',
      desc = 'Enable or disable this addon.',
      get = function(info) return GearRenter.db.profile.enabled end,
      set = function(info, val) if (val) then GearRenter:Enable() else GearRenter:Disable() end end,
    },
    newline1 = {type = "description", order = 2, name = "\n"},
    alertHeader = {
      order = 3,
      type = "header",
      name = "Alerts",
    },
    alertgroup1 = {
      name = 'Expire alert 1',
      type = 'group',
      inline = true,
      order = 4,
      args = {
        alertEnabled = {
          type = 'toggle',
          order = 1,
          name = 'Enable alert 1',
          width = 'double',
          desc = 'This will pop up an alert window when one of your pieces of gear is about to expire.',
          get = function(info) return GearRenter.db.profile.alerts[1].enabled end,
          set = function(info, val)
            GearRenter:EnableAlert(1, val)
            GearRenter.alerts[1].shown = false
          end,
        },
        newline2 = {type = "description", order = 2, name = "\n"},
        alertMinutes = {
          type = 'range',
          order = 3,
          name = 'Remaining minutes',
          width = 'double',
          desc = 'The remaining amount of minutes the gear has to be at in order to trigger the alert.',
          min = 5,
          max = 120,
          step = 1,
          get = function(info) return GearRenter.db.profile.alerts[1].minutes end,
          set = function(info, val)
            GearRenter.db.profile.alerts[1].minutes = val
            GearRenter.alerts[1].shown = false
          end,
        }
      }
    },
    newline3 = {type = "description", order = 5, name = "\n"},
    alertgroup2 = {
      name = 'Expire alert 2',
      type = 'group',
      inline = true,
      order = 6,
      args = {
        alertEnabled = {
          type = 'toggle',
          order = 1,
          name = 'Enable alert 2',
          width = 'double',
          desc = 'This will pop up an alert window when one of your pieces of gear is about to expire.',
          get = function(info) return GearRenter.db.profile.alerts[2].enabled end,
          set = function(info, val)
            GearRenter:EnableAlert(2, val)
            GearRenter.alerts[2].shown = false
          end,
        },
        newline4 = {type = "description", order = 2, name = "\n"},
        alertMinutes = {
          type = 'range',
          order = 3,
          name = 'Remaining minutes',
          width = 'double',
          desc = 'The remaining amount of minutes the gear has to be at in order to trigger the alert.',
          min = 5,
          max = 120,
          step = 1,
          get = function(info) return GearRenter.db.profile.alerts[2].minutes end,
          set = function(info, val)
            GearRenter.db.profile.alerts[2].minutes = val
            GearRenter.alerts[2].shown = false
          end,
        }
      }
    },
    newline5 = {type = "description", order = 7, name = "\n"},
    progressHeader = {
      order = 8,
      type = "header",
      name = "Progress bar",
    },
    progressgroup1 = {
      name = '',
      type = 'group',
      inline = true,
      order = 9,
      args = {
        progressLock = {
          type = 'toggle',
          order = 1,
          name = 'Lock progress',
          desc = 'Lock or unlock the progress bar.',
          get = function(info) return GearRenter.db.profile.progress.locked end,
          set = function(info, val)
            if val then
              GearRenterProgressFrame:Hide()
              GearRenter:LockProgress()
            else
              GearRenterProgressFrame:Show()
              GearRenter:UnlockProgress()
            end
          end,
        },
        progressResetPosition = {
          name = 'Reset position',
          type = 'execute',
          order = 2,
          func = function() GearRenter.ResetProgressPos() end
        }
      }
    },
    newline6 = {type = "description", order = 10, name = "\n"},
    timerHeader = {
      order = 11,
      type = "header",
      name = "Timer",
    },
    timerEnable = {
      type = 'toggle',
      order = 12,
      name = 'Enable timer',
      desc = 'Enables or disables the timer.',
      get = function(info) return GearRenter.db.profile.timer.enabled end,
      set = function(info, val)
        if (val) then
          GearRenter:EnableTimer()
        else
          GearRenter:DisableTimer()
        end
      end,
    },
    timerLock = {
      type = 'toggle',
      order = 13,
      name = 'Lock timer',
      desc = 'Lock or unlock the timer bar.',
      get = function(info) return GearRenter.db.profile.timer.locked end,
      set = function(info, val)
        if val then
          GearRenter:LockTimer()
        else
          GearRenter:UnlockTimer()
        end
      end,
    },
    timerResetPosition = {
      name = 'Reset position',
      type = 'execute',
      order = 14,
      func = function() GearRenter.ResetTimerPos() end
    }
  },
}

local defaults = {
  profile = {
    enabled = true,
    progress = {
      locked = true,
      position = {
        from = "TOP",
        to = "TOP",
        x = 0,
        y = -160
      }
    },
    timer = {
      enabled = false,
      locked = true,
      position = {
        from = "TOP",
        to = "TOP",
        x = 0,
        y = -100
      }
    },
    alerts = {
      {
        enabled = true,
        minutes = 30
      },
      {
        enabled = true,
        minutes = 15
      }
    }
  }
}

function slice(list, index)
  return { select(index, unpack(list)) }
end

function table_fold(list, fn)
  local acc
  for k, v in ipairs(list) do
    if 1 == k then
      acc = v
    else
      acc = fn(acc, v)
    end
  end
  return acc
end

function GearRenter:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("GearRenterDB", defaults)
  local parent = LibStub("AceConfig-3.0"):RegisterOptionsTable("GearRenter", options, {"GearRenter", "gr"})
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("GearRenter", "GearRenter")
  profiles = LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db)
  LibStub("AceConfig-3.0"):RegisterOptionsTable("GearRenter.profiles", profiles)
  LibStub("AceConfigDialog-3.0"):AddToBlizOptions("GearRenter.profiles", "Profiles", "GearRenter")

  self.fetchTooltip = CreateFrame("GAMETOOLTIP", "fetchTooltip")

  self.queue = {}
  self.alerts = {
    {
      shown = false,
      enteringWorld = 0
    },
    {
      shown = false,
      enteringWorld = 0
    }
  }

  StaticPopupDialogs["GEAR_RENTER_ALERT"] = {
    text = "Your PVP gear will expire in |cffffff00%d|r minutes!",
    button1 = "Ok",
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    sound = 'levelup2',
    preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
  }

  GearRenterProgressFrame:SetUserPlaced(true)
  GearRenterUtil.applyDragFunctionality(GearRenterProgressFrame, GearRenter.db.profile.progress.position, defaults.profile.progress.position)

  LibDialog:Register("GearRenterSellChoice", {
    hide_on_escape = true,
    text = "This merchant is not a conquest or honor vendor.\n\nWould you like to:",
    checkboxes = {
      {
        label = "Sell all refundable conquest gear",
        get_value = function(self, data)
          return data.sellConquest
        end,
        set_value = function(self, value, data, mouseButton, down)
          if mouseButton == "LeftButton" then
            data.sellConquest = not data.sellConquest
          end
        end
      },
      {
        label = "Try to sell all refundable honor gear",
        get_value = function(self, data)
          return data.sellHonor
        end,
        set_value = function(self, value, data, mouseButton, down)
          if mouseButton == "LeftButton" then
            data.sellHonor = not data.sellHonor
          end
        end
      }
    },
    buttons = {
      {
        text = "Do It!",
        on_click = function(dialog, data)
          GearRenter:SellToGenericVendor(data.sellConquest, data.sellHonor)
          return false
        end
      },
      {
        text = "Cancel"
      }
    }
  })

  -- LibDialog:Register("GearRenterGenericDialog", {
  --   hide_on_escape = true,
  --   buttons = {
  --     {
  --       text = "Ok",
  --       on_click = function(dialog, data)
  --         return false
  --       end
  --     }
  --   }
  -- })

  GearRenterSets:Initialize()

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

function GearRenter:RunQueue(countFn, total)
  table.insert(self.queue, {function()
    for i=1,#self.alerts do
      self.alerts[i].shown = false
      self.alerts[i].enteringWorld = 0
    end

    self:TimerTick()

    return true
  end})

  GearRenterProgressFrame:Show();
  GearRenterProgressFrameBar:SetMinMaxValues(0, 1)
  GearRenterProgressFrameBar:SetValue(0)
  local queueLen = #self.queue;

  self.rentTimer = self:ScheduleRepeatingTimer(function()
    self:NextQueue()

    local progress = 1 - (#self.queue/queueLen)
    GearRenterProgressFrameBar:SetValue(progress)
    GearRenterProgressFrameBarText:SetText("Renting "..countFn().."/"..total.." - "..floor(progress * 100).."%")

    if #self.queue <= 0 then
      self:CancelTimer(self.rentTimer)
      GearRenterProgressFrame:Hide();
    end
  end, 0.1)
end

function GearRenter:NextQueue()
  if #self.queue > 0 then
    item = self.queue[1]
    if item == nil then
      return
    end

    func = item[1]
    args = slice(item, 2)

    ret = func(unpack(args))
    if ret then
      table.remove(self.queue, 1)
      return true
    end
  else
    -- self.machine:set('none')
  end

  return false
end

function GearRenter:OnEnable()
  self:RegisterEvent("PLAYER_ENTERING_WORLD")
  self:RegisterChatCommand("rebuy", "Rebuy")

  GearRenterFrame:Show()

  for i=1,#self.db.profile.alerts do
    self:EnableAlert(i, self.db.profile.alerts[i].enabled)
  end

  if self.db.profile.timer.enabled then
    self:EnableTimer()
  else
    self:DisableTimer()
  end

  if GearRenter.db.profile.progress.locked then
    self:LockProgress()
  else
    self:UnlockProgress()
  end

  if GearRenter.db.profile.timer.locked then
    self:LockTimer()
  else
    self:UnlockTimer()
  end

  self.db.profile.enabled = true
end

function GearRenter:OnDisable()
  self:UnregisterChatCommand("rebuy")
  self:UnregisterEvent("PLAYER_ENTERING_WORLD")

  GearRenterFrame:Hide()

  for i=1,#self.db.profile.alerts do
    self:EnableAlert(i, false)
  end

  self:DisableTimer()

  self.db.profile.enabled = false
end

function GearRenter:ResetProgressPos()
  GearRenterProgressFrame:ClearAllPoints()
  GearRenterProgressFrame:reset()
end

function GearRenter:ResetTimerPos()
  GearRenter.timerBar.frame:ClearAllPoints()
  GearRenter.timerBar.frame:reset()
end

function GearRenter:CreateTimerBar()
  if self.timerBar ~= nil then
    return
  end

  self.timerBar = {}

  f = CreateFrame('Frame', nil, UIParent)
  f:SetMovable(true)
  f:SetFrameStrata('BACKGROUND')
  f:SetClampedToScreen(true)
  f:SetWidth(150)
  f:SetHeight(20)
  f:SetBackdrop({bgFile = "Interface\\TargetingFrame\\UI-StatusBar",
                 tile = true, tileSize = 16, edgeSize = 16,
                 insets = { left = 0, right = 0, top = 0, bottom = 0 }})
  f:SetBackdropColor(0,0,0,0.5)
  GearRenterUtil.applyDragFunctionality(f, GearRenter.db.profile.timer.position, defaults.profile.timer.position)

  f:SetScript('OnEnter', function(self)
    if self.tooltipText == nil then
      return
    end
    GameTooltip:SetOwner(self, "ANCHOR_TOP")
    GameTooltip:SetText(self.tooltipText)
    GameTooltip:Show()
  end)
  f:SetScript("OnLeave", function(self) GameTooltip:Hide() end)

  self.timerBar.frame = f

  borderSize = 4
  local border1=f:CreateTexture(nil,"BACKGROUND")
  border1:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
  border1:SetPoint("TOPLEFT",0,borderSize)
  border1:SetSize(f:GetWidth(), borderSize)
  border1:SetVertexColor(0, 0, 0, 1)

  local border2=f:CreateTexture(nil,"BACKGROUND")
  border2:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
  border2:SetPoint("TOPLEFT",f:GetWidth(),borderSize)
  border2:SetSize(borderSize, f:GetHeight()+(borderSize*2))
  border2:SetVertexColor(0, 0, 0, 1)

  local border3=f:CreateTexture(nil,"BACKGROUND")
  border3:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
  border3:SetPoint("TOPLEFT",0,-f:GetHeight())
  border3:SetSize(f:GetWidth(), borderSize)
  border3:SetVertexColor(0, 0, 0, 1)

  local border4=f:CreateTexture(nil,"BACKGROUND")
  border4:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
  border4:SetPoint("TOPLEFT",-borderSize,borderSize)
  border4:SetSize(borderSize, f:GetHeight()+(borderSize*2))
  border4:SetVertexColor(0, 0, 0, 1)

  local value1 = CreateFrame('StatusBar', nil, self.timerBar.frame)
  value1:EnableMouse(false)
  value1:SetAllPoints(self.timerBar.frame)
  --value1:SetPoint("TOPLEFT", self.timerBar.frame, "TOPLEFT", 0, -12)
  self.timerBar.value1 = value1

  local value2 = CreateFrame('StatusBar', nil, self.timerBar.value1)
  value2:EnableMouse(false)
  value2:SetAllPoints(self.timerBar.frame)
  --value2:SetPoint("BOTTOMRIGHT", self.timerBar.frame, "BOTTOMRIGHT", 0, 12)
  self.timerBar.value2 = value2

  local blank = CreateFrame('StatusBar', nil, self.timerBar.value2)
  blank:EnableMouse(false)
  blank:SetAllPoints(self.timerBar.frame)
  self.timerBar.blank = blank

  local text = blank:CreateFontString(nil, 'OVERLAY', 'GameFontHighlight')
  text:SetShadowColor(0, 0, 0, 0.6)
  text:SetShadowOffset(1.5, -1.5)
  text:SetPoint('CENTER')
  self.timerBar.text = text

  self.timerBar.value2:SetMinMaxValues(0, 1)
  self.timerBar.value2:SetValue(0)
  self.timerBar.value1:SetMinMaxValues(0, 1)
  self.timerBar.value1:SetValue(0)
  self.timerBar.text:SetText("Renting")

  self.timerBar.value2:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  self.timerBar.value2:GetStatusBarTexture():SetHorizTile(true)

  self.timerBar.value1:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
  self.timerBar.value1:GetStatusBarTexture():SetHorizTile(true)
end

function GearRenter:SetBarFrameSize(frame, width, height)
  name = frame:GetName()
  frame:SetSize(width, height)
  _G[name.."Bar"]:SetSize(width, height)
  _G[name.."BarText"]:SetSize(width-10, height+8)
  _G[name.."BarBorder"]:SetSize(width+8, height+4)
end

function GearRenter:EnableAlert(which, enabled)
  self.db.profile.alerts[which].enabled = enabled

  if enabled then
    if self.expiresTimer == nil then
      self.expiresTimer = self:ScheduleRepeatingTimer("CheckExpires", 5)
    end
  else
    if not self.db.profile.alerts[1].enabled and self.db.profile.alerts[1].enabled then
      self:CancelTimer(self.expiresTimer)
      self.expiresTimer = nil
    end
  end
end

function GearRenter:LockProgress()
  GearRenter.db.profile.progress.locked = true
  --GearRenterProgressFrame:EnableMouse(false)
  GearRenterProgressFrame:lock()
end

function GearRenter:UnlockProgress()
  GearRenter.db.profile.progress.locked = false
  --GearRenterProgressFrame:EnableMouse(true)
  GearRenterProgressFrame:unlock()
end

function GearRenter:EnableTimer()
  self:CreateTimerBar()

  self.db.profile.timer.enabled = true
  self.timerBar.frame:Show()

  self.timerTimer = self:ScheduleRepeatingTimer(self.TimerTick, 30)
  self:ScheduleTimer(self.TimerTick, 3)

  self:RegisterEvent("UNIT_INVENTORY_CHANGED")
end

function GearRenter:DisableTimer()
  self.db.profile.timer.enabled = false

  if self.timerBar ~= nil and self.timerBar.frame ~= nil then
    self.timerBar.frame:Hide()
  end

  self:CancelTimer(self.timerTimer)

  self:UnregisterEvent("UNIT_INVENTORY_CHANGED")
end

function GearRenter:UNIT_INVENTORY_CHANGED(event, unit)
  if #self.queue == 0 and unit == "player" then
    self:TimerTick()
  end
end

function GearRenter:TimerTick()
  if GearRenter.db.profile.timer.enabled == false then
    return
  end

  lowestHonorSecs = nil
  lowestConquestSecs = nil
  for slotID=1,18 do
    -- This forces the purchase info to actually load. If you don't do this,
    -- the purchase info will sometimes come back empty. I'm not sure if
    -- there is a cleaner API to do this.
    GearRenter.fetchTooltip:SetInventoryItem("player", slotID)
    _, _, refundSec, _, hasEnchants = GetContainerItemPurchaseInfo(-2, slotID, true)
    _, _, currencyName = GetContainerItemPurchaseCurrency(-2, slotID, 1, true)
    if refundSec ~= nil and not hasEnchants then
      if currencyName == "Honor Points" and (lowestHonorSecs == nil or refundSec < lowestHonorSecs) then
        lowestHonorSecs = refundSec
      elseif currencyName == "Conquest Points" and (lowestConquestSecs == nil or refundSec < lowestConquestSecs) then
        lowestConquestSecs = refundSec
      end
    end
  end

  lowestSecs = lowestHonorSecs or lowestConquestSecs
  if lowestConquestSecs ~= nil and lowestSecs ~= nil and lowestConquestSecs < lowestSecs then
    lowestSecs = lowestConquestSecs
  end

  if lowestSecs ~= nil then
    GearRenter.timerBar.frame:Show();

    bar1, bar2 = GearRenter.timerBar.value1, GearRenter.timerBar.value2
    if lowestHonorSecs ~= nil and (lowestConquestSecs == nil or lowestHonorSecs < lowestConquestSecs) then
      bar2, bar1 = GearRenter.timerBar.value1, GearRenter.timerBar.value2
    end
    bar1:SetMinMaxValues(0, 7200)
    bar1:SetValue(lowestHonorSecs or 0)
    --bar1:SetStatusBarColor(0, 0.7, 1.0, 0.8)
    bar1:SetStatusBarColor(0, 0.44, 0.87, 0.8)

    bar2:SetMinMaxValues(0, 7200)
    bar2:SetValue(lowestConquestSecs or 0)
    bar2:SetStatusBarColor(0.64, 0.21, 0.93, 0.8)
    --bar2:SetStatusBarColor(0.67, 0, 0.83, 0.8)

    tooltip = {}
    if lowestHonorSecs == nil then
      table.insert(tooltip, "All honor gear has expired")
    else
      table.insert(tooltip, string.format("Lowest honor piece time left: %.2d:%.2d\n", lowestHonorSecs/(60*60), lowestHonorSecs/60%60))
    end
    table.insert(tooltip, "\n")
    if lowestConquestSecs == nil then
      table.insert(tooltip, "All conquest gear has expired")
    else
      table.insert(tooltip, string.format("Lowest conquest piece time left: %.2d:%.2d", lowestConquestSecs/(60*60), lowestConquestSecs/60%60))
    end
    GearRenter.timerBar.frame.tooltipText = table.concat(tooltip)

    GearRenter.timerBar.text:SetText(string.format("Rent: %.2d:%.2d", lowestSecs/(60*60), lowestSecs/60%60))
  else
    GearRenter.timerBar.text:SetText("No rentable gear!")
    GearRenter.timerBar.value1:SetValue(0)
    GearRenter.timerBar.value2:SetValue(0)
  end
end

function GearRenter:LockTimer()
  GearRenter.db.profile.timer.locked = true
  if self.timerBar ~= nil and self.timerBar.frame ~= nil then
    self.timerBar.frame:lock()
  end
end

function GearRenter:UnlockTimer()
  GearRenter.db.profile.timer.locked = false
  if self.timerBar ~= nil and self.timerBar.frame ~= nil then
    self.timerBar.frame:unlock()
  end
end

function GearRenter:PLAYER_ENTERING_WORLD()
  local instanceType = select(2, IsInInstance())

  if instanceType ~= "arena" then
    for i=1,#self.alerts do
      if self.alerts[i].enteringWorld > 0 then
        self:Alert(i, self.alerts[i].enteringWorld)
        self.alerts[i].enteringWorld = 0
      end
    end
  end

  self:ScheduleTimer(self.TimerTick, 1)
end

function GearRenter:CheckExpires()
  lowestSecs = nil
  which = 1
  for slotID=1,18 do
    _, _, refundSec, _, hasEnchants = GetContainerItemPurchaseInfo(-2, slotID, true)

    if not hasEnchants then
      if self.db.profile.alerts[1].enabled and not self.alerts[1].shown and refundSec ~= nil and refundSec <= ((self.db.profile.alerts[1].minutes+1)*60) then
        if lowestSecs == nil or refundSec < lowestSecs then
          lowestSecs = refundSec
          which = 1
        end
      end

      if self.db.profile.alerts[2].enabled and not self.alerts[2].shown and refundSec ~= nil and refundSec <= ((self.db.profile.alerts[2].minutes+1)*60) then
        if lowestSecs == nil or refundSec < lowestSecs then
          lowestSecs = refundSec
          which = 2
        end
      end
    end
  end

  if lowestSecs ~= nil then
    self:Alert(which, lowestSecs)
  else
    --self:Print("reset?")
    --self.alerts[which].shown = false
  end
end

function GearRenter:Alert(which, secs)
  if not self.alerts[which].shown then
    local instanceType = select(2, IsInInstance())
    if instanceType == "arena" then
      --self:Print("Gear is expiring!")
      self.alerts[which].enteringWorld = secs
    else
      StaticPopup_Show("GEAR_RENTER_ALERT", secs / 60)
      self.alerts[which].shown = true
    end
  end
end

function GearRenter:Rebuy_OnClick()
  self:Rebuy()
end

function GearRenter:Rebuy()
  if not MerchantFrame:IsShown() then
    self:Print("Not at a merchant.")
    return
  end

  local merchCurrencies = {GetMerchantCurrencies()}
  local currencies = {}
  local currencyAmounts = {}
  local isHonorConquestVendor = false
  for _, currency in ipairs(merchCurrencies) do
    if currency == CONQUEST_CURRENCY or currency == HONOR_CURRENCY then
      name, currentAmount, _, _, _, _, _ = GetCurrencyInfo(currency)
      currencies[name] = currency
      currencyAmounts[name] = currentAmount
      isHonorConquestVendor = true
    end
  end

  if not isHonorConquestVendor then
    LibDialog:Spawn("GearRenterSellChoice", {})
    return
  end

  -- Cancel the timer if it is still going on from before.
  self:CancelTimer(self.rentTimer)

  self.queue = {}
  local itemRentCount = 0
  local itemRentTotal = 0
  local items = {}
  local preventHonorCap = nil
  for slotID=1,18 do
    _, _, refundSec, _, hasEnchants = GetContainerItemPurchaseInfo(-2, slotID, true)
    _, currencyQuantity, currencyName = GetContainerItemPurchaseCurrency(-2, slotID, 1, true)
    if currencies[currencyName] ~= nil and not(refundSec == nil) and refundSec > 0 and not hasEnchants then
      itemRentTotal = itemRentTotal + 1

      local itemID = GetInventoryItemID("player", slotID)
      _, itemLink, _, _, _, _, _, _, _, _, _ = GetItemInfo(itemID)
      itemID = string.match(itemLink, "item:(%d+)")

      items[itemID] = {
        currencyName = currencyName;
        currencyQuantity = currencyQuantity;
        slotID = slotID;
        itemID = itemID
      }

      -- an issue occurs with honor points as it has a cap of 4000.
      -- For example, let's say we have 2000 honor. We want to rebuy
      -- the helmet which is 2250. We can't buy the helmet outright because
      -- we only have 2000, and we can't sell the helmet because 2250+2000 = 4250.
      -- Our solution is to buy some dummy items and resell them when we're done.
      if currencyName == "Honor Points" and currencyAmounts[currencyName] < currencyQuantity and (currencyQuantity + currencyAmounts[currencyName]) > 4000 then
        preventHonorCap = {}
      end
    end
  end

  -- maximally figure out what combination of items we need to buy to exhaust
  -- the greatest amount of honor
  if preventHonorCap ~= nil then
    local costs = {{3500}, {2250}, {1750,1250}, {1250,1250}, {1750}, {1250}}

    for x=1,#costs do
      local sum = table_fold(costs[x], function(a, b)
        return a + b
      end)

      if currencyAmounts["Honor Points"] >= sum then
        preventHonorCap = {
          costs = costs[x];
          items = {} --items we will buy at the start of the queue, and sell at the end
        }

        -- adjust the currency amounts for honor so when we test for currency
        -- in adding queue items below, it gets the right value.
        currencyAmounts["Honor Points"] = currencyAmounts["Honor Points"] - sum
        break
      end
    end
  end

  for x=1,GetMerchantNumItems() do
    --local item, _, _, _, _, _, _ = GetMerchantItemInfo(x)
    local link = GetMerchantItemLink(x)
    local id = string.match(link, "item:(%d+)")

    -- prevent honor capping
    if preventHonorCap ~= nil and #preventHonorCap["costs"] ~= 0 then
      local _, itemValue, _, _ = GetMerchantItemCostItem(x, 1)
      local maxStack = GetMerchantItemMaxStack(x)

      -- we don't want to buy reagents. so skip things that have stack != 1
      if maxStack == 1 then
        -- find items we can purchase to prevent cap
        for i=1,#preventHonorCap["costs"] do
          if itemValue == preventHonorCap["costs"][i] then
            table.insert(preventHonorCap["items"], {
              merchantIndex = x;
              itemID = id
            })
            table.remove(preventHonorCap["costs"], i)
            break
          end
        end
      end
    end

    if items[id] ~= nil then
      local currencyName = items[id]["currencyName"]
      local currencyQuantity = items[id]["currencyQuantity"]
      local slotID = items[id]["slotID"]
      local itemID = items[id]["itemID"]

      --self:Print(string.format("Selling/buying/equipping %s", itemName))
      -- if we have enough currency to buy this, then buy -> sell
      if currencyAmounts[currencyName] >= currencyQuantity then
        table.insert(self.queue, {function(index)
          BuyMerchantItem(index, 1)
          return true
        end, x})
        table.insert(self.queue, {function(slotID)
          ContainerRefundItemPurchase(-2, slotID)
          return true
        end, slotID})
        table.insert(self.queue, {function(slotID)
          return GetInventoryItemID("player", slotID) == nil
        end, slotID})
      else -- if we don't have enough currency to buy this, then sell -> buy
        -- refund the item from the player slot
        table.insert(self.queue, {function(slotID)
          ContainerRefundItemPurchase(-2, slotID)
          return true
        end, slotID})
        -- wait for it to leave the player slot in order to continue
        table.insert(self.queue, {function(slotID)
          return GetInventoryItemID("player", slotID) == nil
        end, slotID})
        -- buy the merchant item. it'll randomly go in our bags
        table.insert(self.queue, {function(index)
          BuyMerchantItem(index, 1)
          return true
        end, x})
      end

      -- find where the item is in our bags before continuing
      table.insert(self.queue, {function(itemID)
        found = false
        for bag=0, NUM_BAG_SLOTS do
          for bagSlot=1, GetContainerNumSlots(bag) do
            if GetContainerItemID(bag, bagSlot) == tonumber(itemID) then
              found = true
            end
          end
        end

        return found
      end, itemID})
      -- equip the item. keep trying until we do
      table.insert(self.queue, {function(link, slotID)
        if GetInventoryItemID("player", slotID) ~= nil then
          itemRentCount = itemRentCount + 1
          return true
        end

        EquipItemByName(link, slotID)
        return false
      end, link, slotID})
    end
  end

  -- adjust the queue so we buy extra honor items and sell them afterwards
  if preventHonorCap ~= nil then
    for x=1,#preventHonorCap["items"] do
      -- insert buying at beginning of queue
      table.insert(self.queue, 1, {function(index)
        BuyMerchantItem(index, 1)
        return true
      end, preventHonorCap["items"][x]["merchantIndex"]})

      -- insert selling at end of queue
      table.insert(self.queue, {function(itemID)
        for bag=0, NUM_BAG_SLOTS do
          for bagSlot=1, GetContainerNumSlots(bag) do
            if GetContainerItemID(bag, bagSlot) == tonumber(itemID) then
              ContainerRefundItemPurchase(bag, bagSlot)
            end
          end
        end

        return true
      end, preventHonorCap["items"][x]["itemID"]})
    end
  end

  self:RunQueue(function() return itemRentCount end, itemRentTotal)
end

function GearRenter:SellToGenericVendor(sellConquest, sellHonor)
  if not MerchantFrame:IsShown() then
    self:Print("Not at a merchant.")
    return
  end

  if not sellConquest and not sellHonor then
    return
  end

  -- Cancel the timer if it is still going on from before.
  self:CancelTimer(self.rentTimer)

  self.queue = {}
  itemSellCount = 0
  itemSellTotal = 0
  for slotID=1,18 do
    _, _, refundSec, _, hasEnchants = GetContainerItemPurchaseInfo(-2, slotID, true)
    _, currencyQuantity, currencyName = GetContainerItemPurchaseCurrency(-2, slotID, 1, true)
    if ((sellConquest and currencyName == "Conquest Points") or (sellHonor and currencyName == "Honor Points")) and
        not(refundSec == nil) and refundSec > 0 and not hasEnchants then
      itemSellTotal = itemSellTotal + 1

      table.insert(self.queue, {function(slotID)
        ContainerRefundItemPurchase(-2, slotID)
        return true
      end, slotID})
      table.insert(self.queue, {function(slotID)
        if GetInventoryItemID("player", slotID) == nil then
          itemSellCount = itemSellCount + 1
          return true
        end

        return false
      end, slotID})
    end
  end

  self:RunQueue(function() return itemSellCount end, itemSellTotal)
end
