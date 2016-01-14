--[[
Name: Broker kGold
Description: Tracks your gold

Copyright 2016 Mateusz Kasprzak

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
local function GetCoinString(copper, colorChange)
	local colorChange = colorChange or false
	local isProfit = copper >= 0
	local copper = abs(copper)

	local mCopper = mod(copper, 100)
	local mSilver = floor(mod(copper / 100, 100))
	local mGold = floor(copper / 10000)

	local numberColor = "|cffffffff"
	if (colorChange and copper > 0) then
		numberColor = isProfit and "|cff00ff00" or "|cffff0000"
	end

	return numberColor..mGold.."|cffffcc00g "..numberColor..mSilver.."|cffc0c0c0s "..numberColor..mCopper.."|cff996600c|r"
end
------------------------------------------
	
-- Create Broker
local ldb = LibStub:GetLibrary("LibDataBroker-1.1")
local dataobj = ldb:GetDataObjectByName("kGold") or ldb:NewDataObject("kGold", {
	type = "data source", icon = [[Interface\minimap\tracking\auctioneer]], text = "You're broke",
	OnClick = function(self, button)
		if button == "RightButton" and IsShiftKeyDown() then
			kGoldDB = nil;
			OnEvent(self)
		else
			ToggleAllBags()
		end
	end,
	OnTooltipShow = function(tip)
		-- Dane o obecnej sesji
		tip:AddLine("Session")
		if Profit < Spent then
			tip:AddDoubleLine("Deficit", GetCoinString(Profit - Spent, true), 1, 0, 0, 1, 1, 1)
		elseif (Profit - Spent) > 0 then
			tip:AddDoubleLine("Profit", GetCoinString(Profit - Spent, true), 0, 1, 0, 1, 1, 1)
		end
		tip:AddDoubleLine("Earned", GetCoinString(Profit, true), 1, 1, 1, 1, 1, 1)
		tip:AddDoubleLine("Spent", GetCoinString(-Spent, true), 1, 1, 1, 1, 1, 1)
		tip:AddLine(" ")
		
		-- Dane o wszystkich postaciach na realmie
		local totalGold = 0
		tip:AddLine("Characters")
		for k,_ in pairs(kGoldDB[playerRealm]) do
			if kGoldDB[playerRealm][k] then
				tip:AddDoubleLine(k, GetCoinString(kGoldDB[playerRealm][k]), 1, 1, 1, 1, 1, 1)
				totalGold = totalGold + kGoldDB[playerRealm][k]
			end
		end
		tip:AddLine(" ")
		
		-- Total Gold
		tip:AddLine("Realm")
		tip:AddDoubleLine("Total", GetCoinString(totalGold), 1, 1, 1, 1, 1, 1)
		
		-- Currencies
		for i = 1, MAX_WATCHED_TOKENS do
			local name, count, icon, _ = GetBackpackCurrencyInfo(i)
			if name and i == 1 then
				tip:AddLine(" ")
				tip:AddLine("Currencies")
			end
			if name and count then tip:AddDoubleLine("|T"..icon..":0|t"..name, count, 1, 1, 1) end
		end
		
		-- How to
		tip:AddLine(" ")
		tip:AddLine("|cff69ccf0Click|cffffd200 to toggle all bags|r")
		tip:AddLine("|cff69ccf0Shift + Right Click|cffffd200 to reset data|r")
	end,
})

-- Update Text when needed
function OnEvent(self, event, ...)
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

	dataobj.text = GetCoinString(NewMoney)

	kGoldDB[playerRealm][playerName] = NewMoney
end

-- Register Events
local f = CreateFrame("Frame")
f:SetScript("OnEvent", OnEvent)
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("PLAYER_MONEY")
f:RegisterEvent("SEND_MAIL_MONEY_CHANGED")
f:RegisterEvent("SEND_MAIL_COD_CHANGED")
f:RegisterEvent("PLAYER_TRADE_MONEY")
f:RegisterEvent("TRADE_MONEY_CHANGED")
