local Keys = {
	["ESC"] = 322, ["F1"] = 288, ["F2"] = 289, ["F3"] = 170, ["F5"] = 166, ["F6"] = 167, ["F7"] = 168, ["F8"] = 169, ["F9"] = 56, ["F10"] = 57, 
	["~"] = 243, ["1"] = 157, ["2"] = 158, ["3"] = 160, ["4"] = 164, ["5"] = 165, ["6"] = 159, ["7"] = 161, ["8"] = 162, ["9"] = 163, ["-"] = 84, ["="] = 83, ["BACKSPACE"] = 177, 
	["TAB"] = 37, ["Q"] = 44, ["W"] = 32, ["E"] = 38, ["R"] = 45, ["T"] = 245, ["Y"] = 246, ["U"] = 303, ["P"] = 199, ["["] = 39, ["]"] = 40, ["ENTER"] = 18,
	["CAPS"] = 137, ["A"] = 34, ["S"] = 8, ["D"] = 9, ["F"] = 23, ["G"] = 47, ["H"] = 74, ["K"] = 311, ["L"] = 182,
	["LEFTSHIFT"] = 21, ["Z"] = 20, ["X"] = 73, ["C"] = 26, ["V"] = 0, ["B"] = 29, ["N"] = 249, ["M"] = 244, [","] = 82, ["."] = 81,
	["LEFTCTRL"] = 36, ["LEFTALT"] = 19, ["SPACE"] = 22, ["RIGHTCTRL"] = 70, 
	["HOME"] = 213, ["PAGEUP"] = 10, ["PAGEDOWN"] = 11, ["DELETE"] = 178,
	["LEFT"] = 174, ["RIGHT"] = 175, ["UP"] = 27, ["DOWN"] = 173,
	["NENTER"] = 201, ["N4"] = 108, ["N5"] = 60, ["N6"] = 107, ["N+"] = 96, ["N-"] = 97, ["N7"] = 117, ["N8"] = 61, ["N9"] = 118
}

ESX = nil
Citizen.CreateThread(function()
    while ESX == nil do 
        TriggerEvent('esx:getSharedObject', function(a)
            ESX = a 
        end)
    end 
end)

local color_white = {255, 255, 255}
local color_blue = {30, 70, 200}
local color_black = {0, 0, 0}
local defaultHeader = {"commonmenu", "interaction_bgd"}
local defaultMenu = { { name = "Vide" } }
local _intX, _intY = .23, .175
local _intW, _intH = .225, .035
local spriteW, spriteH = .225, .0675
local PMenu = {}
local parentSliderSize = .25
local drawSprite = DrawSprite
local BeginTextCommandWidth = BeginTextCommandWidth
local AddTextComponentSubstringPlayerName = AddTextComponentSubstringPlayerName
local SetTextFont = SetTextFont
local SetTextScale = SetTextScale
local EndTextCommandGetWidth = EndTextCommandGetWidth
local GetControlNormal = GetControlNormal
local RequestStreamedTextureDict = RequestStreamedTextureDict
local SetStreamedTextureDictAsNoLongerNeeded = SetStreamedTextureDictAsNoLongerNeeded
local IsInputDisabled = IsInputDisabled
local IsControlPressed = IsControlPressed
local IsDisabledControlPressed = IsDisabledControlPressed
local IsControlJustPressed = IsControlJustPressed
local UpdateOnscreenKeyboard = UpdateOnscreenKeyboard
local SetTextDropShadow = SetTextDropShadow
local SetTextEdge = SetTextEdge
local SetTextColour = SetTextColour
local SetTextJustification = SetTextJustification
local SetTextWrap = SetTextWrap
local SetTextEntry = SetTextEntry
local AddTextComponentString = AddTextComponentString
local DrawText = DrawText
local DrawRect = DrawRect
local AddTextEntry = AddTextEntry
local DisplayOnscreenKeyboard = DisplayOnscreenKeyboard
local GetOnscreenKeyboardResult = GetOnscreenKeyboardResult
local ShowCursorThisFrame = ShowCursorThisFrame
local DisableControlAction = DisableControlAction


local function MeasureStringWidth(str, font, scale)
	BeginTextCommandWidth("STRING")
	AddTextComponentSubstringPlayerName(str)
	SetTextFont(font or 0)
	SetTextScale(1.0, scale or 0)
	return EndTextCommandGetWidth(true)
end

function IsMouseInBounds(X, Y, Width, Height)
	local MX, MY = GetControlNormal(0, 239) + Width / 2, GetControlNormal(0, 240) + Height / 2
	return (MX >= X and MX <= X + Width) and (MY > Y and MY < Y + Height)
end

function PMenu:resetMenu()
	self.Data = { back = {}, currentMenu = "", intY = _intY, intX = _intX }
	self.Pag = { 1, 10, 1, 1 }
	self.Base = {
		Header = defaultHeader,
		Color = color_black,
		HeaderColor = color_blue,
		Title = CCore and CCore.user and CCore.user.name or "Menu",
		Checkbox = { Icon = { [0] = {"commonmenu", "shop_box_blank"}, [1] = {"commonmenu", "shop_box_tickb"} } }
	}
	self.Menu = {}
	self.Events = {}
	self.tempData = {}
	self.IsVisible = false
end

function PMenu:stringsplit(inputstr, sep)
	if not inputstr then return end
	if sep == nil then
		sep = "%s"
	end
	local t = {} ; i = 1
	for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
		t[i] = str
		i = i + 1
	end
	return t
end

local IsVisible = false

function IsMenuOpened()
	return IsVisible
end

function SetMenuVisible(bool)
	IsVisible = bool
end

function PMenu:CloseMenu(bypass)
	if self.IsVisible and (not self.Base.Blocked or bypass) then
		self.IsVisible = false
		if self.Events["onExited"] then self.Events["onExited"](self.Data, self) end
		SetMenuVisible(false)
		self:resetMenu()
	end
end

function PMenu:GetButtons(customMenu)
	local menu = customMenu or self.Data.currentMenu
	local menuData = self.Menu and self.Menu[menu]
	local allButtons = menuData and menuData.b

	if not allButtons then return {} end
	local tblFilter = {}
	allButtons = type(allButtons) == "function" and allButtons(self) or allButtons
	if not allButtons or type(allButtons) ~= "table" then return {} end
	if self.Events and self.Events["onLoadButtons"] then allButtons = self.Events["onLoadButtons"](self, menu, allButtons) or allButtons end
	for _,v in pairs(allButtons) do
		if v and type(v) == "table" and (v.canSee and (type(v.canSee) == "function" and v.canSee() or v.canSee == true) or v.canSee == nil) and (not menuData.filter or string.find(string.lower(v.name), menuData.filter)) then
			if v.customSlidenum then v.slidenum = type(v.customSlidenum) == "function" and v.customSlidenum() or v.customSlidenum end
			local max = type(v.slidemax) == "function" and v.slidemax(v, self) or v.slidemax
			if type(max) == "number" then
				local tbl = {}
				for i = 0, max do
					tbl[#tbl + 1] = i
				end
				max = tbl
			end
			if max then
				v.slidenum = v.slidenum or 1
				local slideName = max[v.slidenum]
				if slideName then
					v.slidename = slideName and type(slideName) == "table" and slideName.name or tostring(slideName)
				end
			end
			tblFilter[#tblFilter + 1] = v
		end
	end
	if #tblFilter <= 0 then tblFilter = defaultMenu end
	self.tempData = { tblFilter, #tblFilter }
	return tblFilter, #tblFilter
end

function PMenu:OpenMenu(stringName, boolBack)
	if stringName and not self.Menu[stringName] then return end
	local newButtons, currentButtonsCount = self:GetButtons(stringName)
	--if not boolBack and (newButtons and newButtons[self.Pag[3]] and newButtons[self.Pag[3]].name ~= string.lower(stringName)) then
	if not boolBack and self.Data and self.Data.back then	
		self.Data.back[#self.Data.back + 1] = self.Data.currentMenu
	end
	if boolBack then
		self.Data.back[#self.Data.back] = nil
	end

	local intSelect = boolBack and self.Pag[4] or 1
	local max = math.max(10, math.min(intSelect))
	self.Pag = { max - 9, max, intSelect, self.Pag[3] or 1 } -- min, max, current, ancien menu
	self.tempData = { newButtons, currentButtonsCount }
	self.Data.currentMenu = stringName
	if self.Events and self.Events["onButtonSelected"] then self.Events["onButtonSelected"](self.Data.currentMenu, self.Pag[3], self.Data.back, newButtons[1] or {}, self) end
end

function PMenu:Back()
	local historyCount = #self.Data.back
	if historyCount == 1 and not self.Base.Blocked then
		self:CloseMenu()
	elseif historyCount > 1 and not self.Base.BackBlocked then
		self:OpenMenu(self.Data.back[#self.Data.back], true)
		if self.Events["onBack"] then self.Events["onBack"](self.Data, self) end
	end
end

function PMenu:CreateMenu(tableMenu, tempData)
	if (self.Base and self.Base.Blocked and self.IsVisible and IsMenuOpened()) or not tableMenu then return end
	if not self.IsVisible and tableMenu then
		self:resetMenu()
		tableMenu.Base = tableMenu.Base or {}
		for k,v in pairs(tableMenu.Base) do
			if k == "Header" then RequestStreamedTextureDict(v[1]) SetStreamedTextureDictAsNoLongerNeeded(v[1]) end
			self.Base[k] = v
		end
		tableMenu.Data = tableMenu.Data or {}
		for k,v in pairs(tableMenu.Data) do
			self.Data[k] = v
		end
		tableMenu.Events = tableMenu.Events or {}
		for k,v in pairs(tableMenu.Events) do
			self.Events[k] = v
		end
		tableMenu.Menu = tableMenu.Menu or {}
		for k,v in pairs(tableMenu.Menu) do
			self.Menu[k] = v
		end
		self.Data.temp = tempData
		self.Base.CustomHeader = self.Base.Header and self.Base.Header[2] ~= "interaction_bgd"
		_intY = self.Base.CustomHeader and .205 or .17
		if self.Events["onButtonSelected"] then
			-- maybe get buttons
			local allButtons, count = self:GetButtons()
			self.tempData = { allButtons, count }
			self.Events["onButtonSelected"](self.Data.currentMenu, 1, {}, allButtons[1] or {}, self)
		end
		self:OpenMenu(self.Data.currentMenu)
		local boolVisible = self.Base and self.Base.Blocked or not self.IsVisible
		self.IsVisible = boolVisible
		SetMenuVisible(boolVisible)
		if self.IsVisible and self.Events and self.Events["onOpened"] then self.Events["onOpened"](self.Data, self) end
	else
		self:CloseMenu(true)
	end
end

function PMenu:ProcessControl()
	local keyT = IsInputDisabled and IsInputDisabled(2) and 0 or 1
	local boolUP, boolDOWN, boolRIGHT, boolLEFT = IsControlPressed(1, Keys["UP"]), IsControlPressed(1, Keys["DOWN"]), IsControlPressed(1, Keys["RIGHT"]), IsControlPressed(1, Keys["LEFT"])
	local currentMenu = self.Menu and self.Menu[self.Data.currentMenu]
	local currentButtons, currentButtonsCount = table.unpack(self.tempData)
	local currentBtn = currentButtons and currentButtons[self.Pag[3]]
	if currentMenu and currentMenu.refresh then
		self:GetButtons()
	end
	if (boolUP or boolDOWN) and currentButtonsCount and self.Pag[3] then
		if boolDOWN and (self.Pag[3] < currentButtonsCount) or boolUP and (self.Pag[3] > 1) then
			self.Pag[3] = self.Pag[3] + (boolDOWN and 1 or -1)
			if currentButtonsCount > 10 and (boolUP and (self.Pag[3] < self.Pag[1]) or (boolDOWN and (self.Pag[3] > self.Pag[2]))) then
				self.Pag[1] = self.Pag[1] + (boolDOWN and 1 or -1)
				self.Pag[2] = self.Pag[2] + (boolDOWN and 1 or -1)
			end
		else
			self.Pag = { boolUP and currentButtonsCount - 9 or 1, boolUP and currentButtonsCount or 10, boolDOWN and 1 or currentButtonsCount, self.Pag[4] or 1 }
			if currentButtonsCount > 10 and (boolUP and (self.Pag[3] > self.Pag[2]) or (boolDOWN and (self.Pag[3] < self.Pag[1]))) then
				self.Pag[1] = self.Pag[1] + (boolDOWN and -1 or 1)
				self.Pag[2] = self.Pag[2] + (boolDOWN and -1 or 1)
			end
		end
		if self.Events["onButtonSelected"] then
			self.Events["onButtonSelected"](self.Data.currentMenu, self.Pag[3], self.Data.back, currentButtons[self.Pag[3]] or {}, self)
		end
		Citizen.Wait(125)
	end
	if (boolRIGHT or boolLEFT) and currentBtn then
		local slide = currentBtn.slide or currentMenu.slide or self.Events["onSlide"]
		if currentMenu.slidemax or currentBtn and currentBtn.slidemax or self.Events["onSlide"] or slide then
			local changeTo = currentMenu.slidemax and currentMenu or currentBtn.slidemax and currentBtn
			if changeTo and not changeTo.slidefilter or changeTo and not tableHasValue(changeTo.slidefilter, self.Pag[3]) then
				currentBtn.slidenum = currentBtn.slidenum or 0
				local max = type(changeTo.slidemax) == "function" and (changeTo.slidemax(currentBtn, self) or 0) or changeTo.slidemax
				if type(max) == "number" then
					local tbl = {}
					for i = 0, max do
						tbl[#tbl + 1] = i
					end
					max = tbl
				end
				currentBtn.slidenum = currentBtn.slidenum + (boolRIGHT and 1 or -1)
				if (boolRIGHT and (currentBtn.slidenum > #max) or boolLEFT and (currentBtn.slidenum < 1)) then
					currentBtn.slidenum = boolRIGHT and 1 or #max
				end
				local slideName = max[currentBtn.slidenum]
				currentBtn.slidename = slideName and type(slideName) == "table" and slideName.name or tostring(slideName)
				local Offset = MeasureStringWidth(currentBtn.slidename, 0, 0.35)
				currentBtn.offset = Offset
				if slide then slide(self.Data, currentBtn, self.Pag[3], self) end
				Citizen.Wait(currentMenu.slidertime or 175)
			end
		end
		if currentBtn.parentSlider ~= nil and ((boolLEFT and currentBtn.parentSlider < 1.5 + parentSliderSize) or (boolRIGHT and currentBtn.parentSlider > .5 - parentSliderSize)) then
			currentBtn.parentSlider = boolLEFT and round(currentBtn.parentSlider + .01, 2) or round(currentBtn.parentSlider - .01, 2)
			if self.Events["onSlider"] then self.Events["onSlider"](self, self.Data, currentBtn, self.Pag[3], allButtons, currentBtn.parentSlider - parentSliderSize) end
			Citizen.Wait(10)
		end
	end
	if currentMenu and currentMenu.extra or currentBtn and currentBtn.opacity then
		if currentBtn.advSlider and IsDisabledControlPressed(0, 24) then
			local x, y, w = table.unpack(self.Data.advSlider)
			local left, right = IsMouseInBounds(x - 0.01, self.Height, .015, .03), IsMouseInBounds(x - w + 0.01, self.Height, .015, .03)
			if left or right then
				local advPadding = 1
				currentBtn.advSlider[3] = math.max(currentBtn.advSlider[1], math.min(currentBtn.advSlider[2], right and currentBtn.advSlider[3] - advPadding or left and currentBtn.advSlider[3] + advPadding ))
				self.Events["onAdvSlide"](self, self.Data, currentBtn, self.Pag[3], currentButtons)
			end
			Citizen.Wait(75)
		end
	end
	if IsControlJustPressed(1, 202) and UpdateOnscreenKeyboard() ~= 0 then
		self:Back()
		Citizen.Wait(100)
	end
	if self.Pag[3] and currentButtonsCount and self.Pag[3] > currentButtonsCount then
		self.Pag = { 1, 10, 1, self.Pag[4] or 1 }
	end
end

function DrawText2(intFont, stirngText, floatScale, intPosX, intPosY, color, boolShadow, intAlign, addWarp)
	SetTextFont(intFont)
	SetTextScale(floatScale, floatScale)
	if boolShadow then
		SetTextDropShadow(0, 0, 0, 0, 0)
		SetTextEdge(0, 0, 0, 0, 0)
	end
	SetTextColour(color[1], color[2], color[3], 255)
	if intAlign == 0 then
		SetTextCentre(true)
	else
		SetTextJustification(intAlign or 1)
		if intAlign == 2 then
			SetTextWrap(.0, addWarp or intPosX)
		end
	end
	SetTextEntry("STRING")
	AddTextComponentString(stirngText)
	DrawText(intPosX, intPosY)
end

function PMenu:drawMenuButton(button, intX, intY, boolSelected, intW, intH, intID)
	local tableColor, add, currentMenuData = boolSelected and (button.colorSelected or { 255, 255, 255, 255 }) or (button.colorFree or { 0, 0, 0, 100 }), .0, self.Menu[self.Data.currentMenu]
	DrawRect(intX, intY, intW, intH, tableColor[1], tableColor[2], tableColor[3], tableColor[4])
	tableColor = boolSelected and {0, 0, 0} or {255, 255, 255}
	local stringPrefix = (((button.r and (((CCore and (CCore.jobRank < button.r or CCore.copRank < button.r)) or (button.rfunc and not button.rfunc())) and "~r~" or "")) or "") .. (self.Events["setPrefix"] and self.Events["setPrefix"](button, self.Data) or "")) or ""
	DrawText2(0, (button.price and "> " or "") .. stringPrefix .. (button.name or ""), .275, intX - intW / 2 + .005, intY - intH / 2 + .0025, tableColor)
	local unkCheckbox = currentMenuData and currentMenuData.checkbox or button.checkbox ~= nil and button.checkbox
	local slide = button.slidemax and button or currentMenuData
	local slideExist = slide and slide.slidemax and (not slide.slidefilter or not tableHasValue(slide.slidefilter, intID))
	if button.name and self.Menu[string.lower(button.name)] and not currentMenuData.item and not slideExist then
		--drawSprite("commonmenutu", "arrowright", intX + (intW / 2.2), intY, .009, .018, 0.0, tableColor[1], tableColor[2], tableColor[3], 255)
		add = .0125
	end

	if unkCheckbox ~= nil and (button.checkbox ~= nil or currentMenuData and currentMenuData.checkbox ~= nil) then
		local bool = unkCheckbox ~= nil and (type(unkCheckbox) == "function" and unkCheckbox(GetPlayerPed(-1), button, self.Base.currentMenu, self)) or unkCheckbox
		bool = bool and bool == true and 1 or 0
		if not self.Base.Checkbox["Icon"] or self.Base.Checkbox["Icon"][bool] then
			local successIcon = self.Base.Checkbox["Icon"] and self.Base.Checkbox["Icon"][bool]
			if successIcon and successIcon[1] and successIcon[2] then
				local checkboxColor = boolSelected and bool == 0 and {0, 0, 0} or {255, 255, 255}
				drawSprite(successIcon[1], successIcon[2], intX + (intW / 2.2), intY, .023, .045, 0.0, checkboxColor[1], checkboxColor[2], checkboxColor[3], 255)
				return
			end
		end
	elseif slideExist or button.ask or button.slidename then
		local max = slideExist and slide and (type(slide.slidemax) == "function" and slide.slidemax(button, self) or slide.slidemax)
		if (max and type(max) == "number" and max > 0 or type(max) == "table" and #max > 0) or not slideExist then
			local defaultIndex = slideExist and button.slidenum or 1
			local slideText = button.ask and (type(button.ask) == "function" and button.ask(self) or button.askValue or button.ask) or (button.slidename or (type(max) == "number" and (defaultIndex - 1) or type(max[defaultIndex]) == "table" and max[defaultIndex].name or tostring(max[defaultIndex])))
			slideText = tostring(slideText)
			if boolSelected and slideExist then
				drawSprite("commonmenu", "arrowright", intX + (intW / 2) - .01025, intY + 0.0004, .009, .018, 0.0, tableColor[1], tableColor[2], tableColor[3], 255)
				button.offset = MeasureStringWidth(slideText, 0, .275)
				drawSprite("commonmenu", "arrowleft", intX + (intW / 2) - button.offset - .016, intY + 0.0004, .009, .018, 0.0, tableColor[1], tableColor[2], tableColor[3], 255)
			end
			local textX = (not boolSelected or button.ask) and -.004 or - .0135
			DrawText2(0, slideText, .275, intX + intW / 2 + textX,  intY - intH / 2 + .00375, tableColor, false, 2)
			intX = boolSelected and intX - .0275 or intX - .0125
		end
	end

	if button.parentSlider ~= nil then
		local rectX, rectY = intX + .0925, intY + 0.005
		local proW, proH = .1, 0.01
		drawSprite("mpleaderboard", "leaderboard_female_icon", intX + (intW / 2) - .01025, intY + 0.0004, .0156, .0275, 0.0, tableColor[1], tableColor[2], tableColor[3], 255)
		drawSprite("mpleaderboard", "leaderboard_male_icon", intX - .015, intY + 0.0004, .0156, .0275, 0.0, tableColor[1], tableColor[2], tableColor[3], 255)
		local slideW = proW * button.parentSlider
		DrawRect(rectX - proW / 2, rectY - proH / 2, proW, proH, 4, 32, 57, 255)
		DrawRect(rectX - slideW / 2, rectY - proH / 2, proW * parentSliderSize, proH, 57, 116, 200, 255)
		DrawRect(rectX - proW / 2, rectY - proH / 2, .002, proH + 0.005, tableColor[1], tableColor[2], tableColor[3], 255)
	end
	local textBonus = (self.Events["setBonus"] and self.Events["setBonus"](button, self.Data.currentMenu, self)) or (button.amount and button.amount) or (button.price and "~g~" .. math.floor(button.price) .. "$")
	if textBonus and string.len(textBonus) > 0 then
		DrawText2(0, textBonus, .275, intX + (intW / 2) - .005 - add,  intY - intH / 2 + .00375, tableColor, true, 2)
	end
end

local function MultilineFormat(str, size)
	if tostring(str) then
		local PixelPerLine = _intW + .025
		local AggregatePixels = 0
		local output = ""
		local words = stringsplit(tostring(str), " ")
		for i = 1, #words do
			local offset = MeasureStringWidth(words[i], 0, size)
			AggregatePixels = AggregatePixels + offset
			if AggregatePixels > PixelPerLine then
				output = output .. "\n" .. words[i] .. " "
				AggregatePixels = offset + 0.003
			else
				output = output .. words[i] .. " "
				AggregatePixels = AggregatePixels + 0.003
			end
		end
		return output
	end
end

function PMenu:DrawButtons(tableButtons)
	local padding, pd = 0.0175, 0.0475
	for intID, data in ipairs(tableButtons) do
		local shouldDraw = intID >= self.Pag[1] and intID <= self.Pag[2]
		if shouldDraw then
			local boolSelected = intID == self.Pag[3]
			self:drawMenuButton(data, self.Width - _intW / 2, self.Height, boolSelected, _intW, _intH - 0.005, intID)
			self.Height = self.Height + pd - padding
			if boolSelected and IsControlJustPressed(1, 201) and data.name ~= "Vide" then
				if self.Events["setCheckbox"] then self.Events["setCheckbox"](self.Data, data) end
				local slideEvent = data.slide or self.Events["onSlide"]
				if slideEvent or data.checkbox ~= nil then
					if not slideEvent then
						data.checkbox = not data.checkbox
					else
						slideEvent(self.Data, data, intID, self)
					end
				end
				local selectFunc, shouldContinue = self.Events["onSelected"], false
				if selectFunc then
					if data.slidemax and not data.slidenum and type(data.slidemax) == "table" then data.slidenum = 1 data.slidename = data.slidemax[1] end
					data.slidenum = data.slidenum or 1
					if data.ask and not data.askX then
						data.askValue = nil
						if data.name then AddTextEntry('FMMC_KEY_TIP8', data.askTitle or data.name) end
						local askValue = type(data.ask) == "function" and data.ask(self) or data.ask
						DisplayOnscreenKeyboard(false, "FMMC_KEY_TIP8", "", askValue or "", "", "", "", 60)
						while UpdateOnscreenKeyboard() == 0 do
							Citizen.Wait(50)
							if UpdateOnscreenKeyboard() == 1 and GetOnscreenKeyboardResult() and string.len(GetOnscreenKeyboardResult()) >= 1 then
								data.askValue = GetOnscreenKeyboardResult()
							end
						end
					end
					shouldContinue = selectFunc(self, self.Data, data, self.Pag[3], tableButtons)
				end
				if not shouldContinue and self.Menu[string.lower(data.name)] then
					self:OpenMenu(string.lower(data.name))
				end
			end
		end
	end
end

function PMenu:DrawHeader(intCount)
	local parentHeader, childHeader = table.unpack(self.Base.Header)
	local boolHeader = parentHeader and string.len(parentHeader) > 0
	local currentMenu = self.Menu[self.Data.currentMenu]
	local stringCounter = currentMenu and currentMenu["customSub"] and currentMenu["customSub"]() or string.format("%s/%s", self.Pag[3], intCount)
	if boolHeader then
		local intH = self.Base.CustomHeader and 0.1025 or spriteH
		drawSprite(parentHeader, childHeader, self.Width - spriteW / 2, self.Height - intH / 2, spriteW, intH, .0, self.Base.HeaderColor[1], self.Base.HeaderColor[2], self.Base.HeaderColor[3], 215)
		self.Height = self.Height - 0.03
		if not self.Base.CustomHeader then
			DrawText2(1, self.Base.Title, .7, self.Width  - spriteW / 2, self.Height - intH / 2 + .0125, color_white, false, 0)
		end
	end
	self.Height = self.Height + 0.06
	local rectW, rectH = _intW, _intH - .005
	DrawRect(self.Width - rectW / 2, self.Height - rectH / 2, rectW, rectH, self.Base.Color[1], self.Base.Color[2], self.Base.Color[3], 255)
	self.Height = self.Height + 0.005
	DrawText2(0, firstToUpper(self.Data.currentMenu), .275, self.Width - rectW + .005, self.Height - rectH - 0.0015, color_white, true)
	self.Height = self.Height + 0.005
	DrawText2(0, stringCounter, .275, self.Width - rectW / 2 + .11, self.Height - _intH, color_white, true, 2)
	if currentMenu and currentMenu.charCreator then
		local spriteW, spriteH = .225, .21
		self.Height = self.Height + spriteH - 0.01
		drawSprite("pause_menu_pages_char_mom_dad", "mumdadbg", self.Width - spriteW / 2, self.Height - spriteH / 2, spriteW, spriteH, .0, 255, 255, 255, 255)
		drawSprite("pause_menu_pages_char_mom_dad", "vignette", self.Width - spriteW / 2, self.Height - spriteH / 2, spriteW, spriteH, .0, 255, 255, 255, 255)
		if currentMenu.father then
			spriteW, spriteH = .11875, .2111
			drawSprite("char_creator_portraits", currentMenu.father, self.Width - spriteW / 2, self.Height - spriteH / 2, spriteW, spriteH, .0, 255, 255, 255, 255)
		end
		if currentMenu.mother then
			spriteW, spriteH = .11875, .2111
			local customX = self.Width - .1
			drawSprite("char_creator_portraits", currentMenu.mother, customX - spriteW / 2, self.Height - spriteH / 2, spriteW, spriteH, 0.0, 255, 255, 255, 255)
			self.Height = self.Height + 0.01
		end
	end
	self.Height = self.Height + 0.005
end



function PMenu:DrawHelpers(tableButtons)
	local hasHelp = self.Base.Description or self.Menu[self.Data.currentMenu] and self.Menu[self.Data.currentMenu].Description or tableButtons[self.Pag[3]] and tableButtons[self.Pag[3]].Description
	if hasHelp then
		local intH, scale = 0.0275, 0.275
		self.Height = self.Height - 0.015
		DrawRect(self.Width - _intW / 2, self.Height, _intW, 0.0025, 0, 0, 0, 255)
		local descText = MultilineFormat(hasHelp, scale)
		local Linecount = #stringsplit(descText, "\n")
		local nwintH = intH + (Linecount == 1 and 0 or ( (Linecount + 1) * 0.0075))
		self.Height = self.Height + intH / 2
		DrawSprite("commonmenu", "gradient_bgd", self.Width - _intW / 2, self.Height + nwintH / 2 - 0.015, _intW, nwintH, .0, 255, 255, 255, 255)
		DrawText2(0, descText, scale, self.Width - _intW + .005, self.Height - 0.01, color_white)
	end
end

function stringsplit(inputstr, sep)
    if not inputstr then return end
    if sep == nil then
        sep = "%s"
    end
    local t = {} ; i = 1
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

function PMenu:DrawExtra(tableButtons)
	ShowCursorThisFrame()
	DisableControlAction(0, 1, true)
	DisableControlAction(0, 2, true)
	DisableControlAction(0, 24, true)
	DisableControlAction(0, 25, true)
	local button = tableButtons[self.Pag[3]]
	if button and button.opacity ~= nil then
		local proW, proH = _intW, 0.055
		self.Height =  self.Height - 0.01
		drawSprite("commonmenu", "gradient_bgd", self.Width - proW / 2, self.Height + proH / 2, proW, proH, 0.0, 255, 255, 255, 255)
		self.Height = self.Height + 0.005
		DrawText2(0, "0%", 0.275, self.Width - _intW + .005, self.Height, color_white, false, 1)
		DrawText2(0, "Opacité", 0.275, self.Width - _intW / 2, self.Height, color_white, false, 0)
		DrawText2(0, "100%", 0.275, self.Width - 0.005, self.Height, color_white, false, 2)
		self.Height = self.Height + .033
		local rectW, rectH = .215, 0.015
		local customW = rectW * ( 1 - button.opacity )
		local rectX, rectY = self.Width - rectW / 2 - 0.005, self.Height
		local customX = self.Width - customW / 2 - 0.005
		DrawRect(rectX, rectY, rectW, rectH, 245, 245, 245, 255)
		DrawRect(customX, rectY, customW, rectH, 87, 87, 87, 255)
		if IsDisabledControlPressed(0, 24) and IsMouseInBounds(rectX, rectY, rectW, rectH) then
			local mouseXPos = GetControlNormal(0, 239) - proH / 2
			button.opacity = round(math.max(0.0, math.min(1.0, mouseXPos / rectW)), 2)
			self.Events["onSlide"](self.Data, button, self.Pag[3], self)
		end
		self.Height = self.Height + 0.025
	end

	if button and button.advSlider ~= nil then
		local proW, proH = _intW, 0.055
		drawSprite("commonmenu", "gradient_bgd", self.Width - proW / 2, self.Height + proH / 2, proW, proH, 0.0, 255, 255, 255, 255)
		self.Height = self.Height + 0.005
		button.advSlider[3] = button.advSlider[3] or 0
		DrawText2(0, tostring(button.advSlider[1]), 0.275, self.Width - _intW + .005, self.Height, color_white, false, 1)
		DrawText2(0, "Variations disponibles", 0.275, self.Width - _intW / 2, self.Height, color_white, false, 0)
		DrawText2(0, tostring(button.advSlider[2]), 0.275, self.Width - 0.005, self.Height, color_white, false, 2)
		self.Height = self.Height + .03
		drawSprite("commonmenu", "arrowright", self.Width - 0.01, self.Height, .015, .03, 0.0, 255, 255, 255, 255)
		drawSprite("commonmenu", "arrowleft", self.Width - proW + 0.01, self.Height, .015, .03, 0.0, 255, 255, 255, 255)
		local rectW, rectH = .19, 0.015
		local rectX, rectY = self.Width - proW / 2, self.Height
		DrawRect(rectX, rectY, rectW, rectH, 87, 87, 87, 255)
		local sliderW = rectW / (button.advSlider[2] + 1)
		local sliderWFocus = button.advSlider[2] * (sliderW / 2)
		local customX = rectX - sliderWFocus + (sliderW * ( button.advSlider[3] / button.advSlider[2] )) * button.advSlider[2]
		DrawRect(customX, rectY, sliderW, rectH, 245, 245, 245, 255)
		self.Data.advSlider = { self.Width, self.Height, proW }
	end
end

function PMenu:Draw()
	local tableButtons, intCount = table.unpack(self.tempData)
	self.Height = self.Base and self.Base.intY or _intY
	self.Width = self.Base and self.Base.intX or _intX
	if tableButtons and intCount and not self.Invisible then
		self:DrawHeader(intCount) -- 0.03ms
		self:DrawButtons(tableButtons) -- 0.04ms
		self:DrawHelpers(tableButtons) -- 0.00ms
		local currentMenu, currentButton = self.Menu[self.Data.currentMenu], self.Pag[3] and tableButtons and tableButtons[self.Pag[3]]
		if currentMenu and (currentMenu.extra or currentButton and currentButton.opacity) then
			self:DrawExtra(tableButtons)
		end
		if currentMenu and currentMenu.useFilter then
			--local keyFilter = Keys[0]["F"]
			DisableControlAction(1, 23, true)
			if IsDisabledControlJustPressed(1, 23) then
				AskEntry(function(n)
					currentMenu.filter = n and string.len(n) > 0 and string.lower(n) or false
					self:GetButtons()
				end, "Filtre", 30, currentMenu.filter)
			end
		end -- 0.00ms
	end
	if self.Events and self.Events["onRender"] then self.Events["onRender"](self, tableButtons, tableButtons[self.Pag[3]], self.Pag[3]) end
end

function CloseMenu(force)
	return PMenu:CloseMenu(force)
end

function CreateMenu(arrayMenu, tempData)
	return PMenu:CreateMenu(arrayMenu, tempData)
end

function OpenMenu(stringName)
	return PMenu:OpenMenu(stringName)
end

function AskEntry(callback, name, lim, default)
	AddTextEntry('FMMC_KEY_TIP8', name or "Montant")
	DisplayOnscreenKeyboard(false, "FMMC_KEY_TIP8", "", default, "", "", "", lim or 60)

	while UpdateOnscreenKeyboard() == 0 do
		Citizen.Wait(10)
		if UpdateOnscreenKeyboard() >= 1 then
			callback(GetOnscreenKeyboardResult())
			break
		end
	end
end

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if PMenu.IsVisible then
			PMenu:Draw()
		end
	end
end)

Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		if PMenu.IsVisible and not PMenu.Invisible then
			PMenu:ProcessControl()
		end
	end
end)

function firstToUpper(str)
    return (str:gsub("^%l", string.upper))
end