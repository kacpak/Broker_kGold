--[[
Name: Broker kGold
Description: Tracks your gold

Copyright 2008 Quaiche of Dragonblight

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
]]

local UpdateData
local playerName, playerRealm = UnitName("player"), GetRealmName()

local Profit	= 0
local Spent		= 0

------------------------------------------
-- Helper Functions
local function MoneyFormat(copper, isProfit)
	local moneyGold = floor(abs(copper / 10000))
	local moneySilver = floor(abs(mod(copper / 100, 100)))
	local moneyCopper = floor(abs(mod(copper, 100)))
	if (isProfit > 0 and copper ~= 0) then
		return string.format("|cff00ff00 %d|cffffcc00g |cff00ff00%d|cffc0c0c0s |cff00ff00%d|cff996600c|r", moneyGold, moneySilver, moneyCopper)
	elseif (isProfit < 0 and copper ~= 0) then
		return string.format("|cffff0000%d|cffffcc00g |cffff0000%d|cffc0c0c0s |cffff0000%d|cff996600c|r", moneyGold, moneySilver, moneyCopper)
	else
		return string.format("%d|cffffcc00g |cffffffff%d|cffc0c0c0s |cffffffff%d|cff996600c|r", moneyGold, moneySilver, moneyCopper)
	end
end
------------------------------------------
	
-- Create Broker
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataobj = ldb:GetDataObjectByName("kGold") or ldb:NewDataObject("kGold", {
	type = "data source", icon = [[Interface\minimap\tracking\auctioneer]], text = "You're broke",
	OnClick = function(self, button)
		if button == "RightButton" and IsShiftKeyDown() then
			kGoldDB = nil;
			UpdateData(self)
		else
			ToggleAllBags()
		end
	end,
	OnTooltipShow = function(tip)
		-- Dane o obecnej sesji
		tip:AddLine("Session")
		tip:AddDoubleLine("Earned", MoneyFormat(Profit, 1), 1, 1, 1, 1, 1, 1)
		tip:AddDoubleLine("Spent", MoneyFormat(Spent, -1), 1, 1, 1, 1, 1, 1)
		if Profit < Spent then
			tip:AddDoubleLine("Deficit: ", MoneyFormat(Spent - Profit, -1), 1, 0, 0, 1, 1, 1)
		elseif (Profit - Spent) > 0 then
			tip:AddDoubleLine("Profit: ", MoneyFormat(Profit - Spent, 1), 0, 1, 0, 1, 1, 1)
		end
		tip:AddLine(" ")
		
		-- Dane o wszystkich postaciach na realmie
		local totalGold = 0
		tip:AddLine("Characters")
		for k,_ in pairs(kGoldDB[playerRealm]) do
			if kGoldDB[playerRealm][k] then
				tip:AddDoubleLine(k, MoneyFormat(kGoldDB[playerRealm][k], 0), 1, 1, 1, 1, 1, 1)
				totalGold = totalGold + kGoldDB[playerRealm][k]
			end
		end
		tip:AddLine(" ")
		
		-- Total Gold
		tip:AddLine("Realm")
		tip:AddDoubleLine("Total: ", MoneyFormat(totalGold, 0), 1, 1, 1, 1, 1, 1)
		
		-- Currencies
		for i = 1, MAX_WATCHED_TOKENS do
			local name, count, extraCurrencyType, icon, itemID = GetBackpackCurrencyInfo(i)
			if name and i == 1 then
				tip:AddLine(" ")
				tip:AddLine("Currencies")
			end
			if name and count then tip:AddDoubleLine(name, count, 1, 1, 1) end
		end
		
		-- How to
		tip:AddLine(" ")
		tip:AddLine("|cff69ccf0Click|cffffd200 to toggle all bags|r")
		tip:AddLine("|cff69ccf0Shift + Right Click|cffffd200 to reset data|r")
	end,
})

-- Update Text when needed
function UpdateData(self, event, ...)
	if not IsLoggedIn() then return end
	local NewMoney = GetMoney();
	kGoldDB = kGoldDB or { };
	kGoldDB[playerRealm] = kGoldDB[playerRealm] or {};
	kGoldDB[playerRealm][playerName] = kGoldDB[playerRealm][playerName] or NewMoney;

	local OldMoney = kGoldDB[playerRealm][playerName] or NewMoney

	local Change = NewMoney - OldMoney -- Positive if we gain money
	if OldMoney > NewMoney then		-- Lost Money
		Spent = Spent - Change
	else							-- Gained Moeny
		Profit = Profit + Change
	end

	dataobj.text = MoneyFormat(NewMoney, 0)

	kGoldDB[playerRealm][playerName] = NewMoney
end

-- Register Events
local f = CreateFrame("Frame")
f:SetScript("OnEvent", function(self, event, ...) if self[event] then return self[event](self, event, ...) end end)
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_MONEY")
f:RegisterEvent("SEND_MAIL_MONEY_CHANGED")
f:RegisterEvent("SEND_MAIL_COD_CHANGED")
f:RegisterEvent("PLAYER_TRADE_MONEY")
f:RegisterEvent("TRADE_MONEY_CHANGED")
f.PLAYER_LOGIN = UpdateData
f.PLAYER_MONEY = UpdateData
f.SEND_MAIL_MONEY_CHANGED = UpdateData
f.SEND_MAIL_COD_CHANGED = UpdateData
f.PLAYER_TRADE_MONEY = UpdateData
f.TRADE_MONEY_CHANGED = UpdateData
