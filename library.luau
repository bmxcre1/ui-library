local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

Library = {}

function Library:CreateWindow(title, initialSize)
	local window = {}
	window.Tabs = {}
	window.ActiveTab = nil
	window.Dragging = false
	window.DragStart = Vector2.new(0, 0)
	window.StartPos = Vector2.new(0, 0)
    window.Opened = true
    window.TitleWidth = 0
	local mainSize = initialSize or Vector2.new(550, 400)
	local mainPos = Vector2.new(100, 100)
    local cornerRadius = 6
    local colors = {
        Background = Color3.fromRGB(15, 15, 15),
        TopBar = Color3.fromRGB(25, 25, 25),
        Accent = Color3.fromRGB(65, 120, 255),
        Text = Color3.fromRGB(230, 230, 230),
        ElementBg = Color3.fromRGB(35, 35, 35),
        Border = Color3.fromRGB(10, 10, 10)
    }
    
    local function createRoundedBox(radius, filled, zIndex)
        local shapes = {}
        shapes.TL = Drawing.new("Circle")
        shapes.TR = Drawing.new("Circle")
        shapes.BL = Drawing.new("Circle")
        shapes.BR = Drawing.new("Circle")
        shapes.R1 = Drawing.new("Square")
        shapes.R2 = Drawing.new("Square")
        
        for _, s in pairs(shapes) do
            if s.Type == "Circle" then
                s.Radius = radius
                s.Filled = filled
                s.NumSides = 20
            else
                s.Filled = filled
            end
            s.ZIndex = zIndex or 1
            s.Visible = true
        end
        
        return shapes
    end
    
    local function createRoundedTop(radius, filled, zIndex)
        local shapes = {}
        shapes.TL = Drawing.new("Circle")
        shapes.TR = Drawing.new("Circle")
        shapes.Main = Drawing.new("Square")
        shapes.Bottom = Drawing.new("Square")
        
        for _, s in pairs(shapes) do
            if s.Type == "Circle" then
                s.Radius = radius
                s.Filled = filled
                s.NumSides = 20
            else
                s.Filled = filled
            end
            s.ZIndex = zIndex or 1
            s.Visible = true
        end
        return shapes
    end
    
    local mainShapes = createRoundedBox(cornerRadius, true, 1)
    local topBarShapes = createRoundedTop(cornerRadius, true, 2)
    local function setShapesColor(shapes, color)
        for _, s in pairs(shapes) do s.Color = color end
    end
    setShapesColor(mainShapes, colors.Background)
    setShapesColor(topBarShapes, colors.TopBar)

	local titleText = Drawing.new("Text")
	titleText.Text = title:upper()
	titleText.Size = 18
	titleText.Color = colors.Text
	titleText.Visible = true
	titleText.Font = Drawing.Fonts.System
    titleText.Center = false
    titleText.ZIndex = 3

    local separator = Drawing.new("Line")
    separator.Thickness = 1
    separator.Color = Color3.new(1, 1, 1)
    separator.Transparency = 0.5 
    separator.Visible = true
    separator.ZIndex = 3
    local wasMousePressed = false

	local function isMouseOver(pos, size)
		local mX, mY = Mouse.X, Mouse.Y
		return mX >= pos.X and mX <= pos.X + size.X and mY >= pos.Y and mY <= pos.Y + size.Y
	end
    
    local function updatePositions()
        local r = cornerRadius
        local x, y = mainPos.X, mainPos.Y
        local w, h = mainSize.X, mainSize.Y

        mainShapes.TL.Position = Vector2.new(x + r, y + r)
        mainShapes.TR.Position = Vector2.new(x + w - r, y + r)
        mainShapes.BL.Position = Vector2.new(x + r, y + h - r)
        mainShapes.BR.Position = Vector2.new(x + w - r, y + h - r)
        mainShapes.R1.Position = Vector2.new(x + r, y)
        mainShapes.R1.Size = Vector2.new(w - 2 * r, h)
        mainShapes.R2.Position = Vector2.new(x, y + r)
        mainShapes.R2.Size = Vector2.new(w, h - 2 * r)

        local th = 40

        topBarShapes.TL.Position = Vector2.new(x + r, y + r)
        topBarShapes.TR.Position = Vector2.new(x + w - r, y + r)
        topBarShapes.Main.Position = Vector2.new(x + r, y)
        topBarShapes.Main.Size = Vector2.new(w - 2 * r, th)
        topBarShapes.Bottom.Position = Vector2.new(x, y + r)
        topBarShapes.Bottom.Size = Vector2.new(w, th - r)
        titleText.Position = mainPos + Vector2.new(15, 12)

        window.TitleWidth = math.clamp(titleText.TextBounds.X, 100, 300)
        
        local sepX = 15 + window.TitleWidth + 10
        local sepY = mainPos.Y + 10
        local sepH = 20
        
        separator.From = Vector2.new(mainPos.X + sepX, sepY)
        separator.To   = Vector2.new(mainPos.X + sepX, sepY + sepH)

        local tabX = 15 + window.TitleWidth + 22
        for _, tab in ipairs(window.Tabs) do
             tab.Btn.Position = mainPos + Vector2.new(tabX, 12)
             tabX = tabX + tab.Width + 25
             
             if tab == window.ActiveTab then
                 tab.Btn.Color = colors.Accent
                 local currentY = mainPos.Y + 60
                 for _, elem in ipairs(tab.Elements) do
                     elem:Update(Vector2.new(mainPos.X + 20, currentY))
                     currentY = currentY + elem.Height + 5
                 end
             else
                 tab.Btn.Color = Color3.fromRGB(150, 150, 150)
             end
        end
    end

    local function updateRoundedBox(shapes, pos, size, radius)
        local x, y = pos.X, pos.Y
        local w, h = size.X, size.Y
        local r = radius

        shapes.TL.Position = Vector2.new(x + r, y + r)
        shapes.TR.Position = Vector2.new(x + w - r, y + r)
        shapes.BL.Position = Vector2.new(x + r, y + h - r)
        shapes.BR.Position = Vector2.new(x + w - r, y + h - r)
        
        shapes.R1.Position = Vector2.new(x + r, y)
        shapes.R1.Size = Vector2.new(w - 2 * r, h)
        
        shapes.R2.Position = Vector2.new(x, y + r)
        shapes.R2.Size = Vector2.new(w, h - 2 * r)
    end

    function window:CreateTab(name)
        local tab = {
            Name = name,
            Elements = {},
            Visible = false,
            Width = 0
        }
        
        local tabBtn = Drawing.new("Text")
        tabBtn.Text = name
        tabBtn.Size = 16
        tabBtn.Color = Color3.fromRGB(150, 150, 150)
        tabBtn.Font = Drawing.Fonts.System
        tabBtn.Visible = true
        tab.Btn = tabBtn
        tab.Width = tabBtn.TextBounds.X
        if tab.Width == 0 then tab.Width = 50 end
        
        function tab:CreateSection(text)
            local sec = { Type = "Section", Height = 25 }
            
            local secTxt = Drawing.new("Text")
            secTxt.Text = text
            secTxt.Size = 14
            secTxt.Color = colors.Accent
            secTxt.Font = Drawing.Fonts.System
            secTxt.Visible = false
            sec.Txt = secTxt
            
            local secLine = Drawing.new("Square")
            secLine.Size = Vector2.new(mainSize.X - 40, 1)
            secLine.Color = colors.ElementBg
            secLine.Filled = true
            secLine.Visible = false
            sec.Line = secLine
            
            function sec:Update(pos)
                secTxt.Position = pos + Vector2.new(2, 0)
                secTxt.ZIndex = 3
                secLine.Position = pos + Vector2.new(0, 18)
                secLine.ZIndex = 3
            end
            
            function sec:SetVisible(vis)
                secTxt.Visible = vis
                secLine.Visible = vis
            end
            
            table.insert(tab.Elements, sec)
            return sec
        end
        
        function tab:CreateButton(text, callback)
            local btn = { Type = "Button", Height = 32, Callback = callback, ClickTime = 0 }
            local btnRadius = 5

            local btnBorderShapes = createRoundedBox(btnRadius, true, 3)
            setShapesColor(btnBorderShapes, colors.Border)
            for _, s in pairs(btnBorderShapes) do s.Visible = false end
            btn.BorderShapes = btnBorderShapes

            btn.Border = { Position = Vector2.new(0, 0), Size = Vector2.new(0, 0) }
            
            local btnBgShapes = createRoundedBox(btnRadius, true, 3)
            setShapesColor(btnBgShapes, colors.ElementBg)
            for _, s in pairs(btnBgShapes) do s.Visible = false end
            btn.BgShapes = btnBgShapes
            
            local btnTxt = Drawing.new("Text")
            btnTxt.Text = text
            btnTxt.Size = 13
            btnTxt.Color = colors.Text
            btnTxt.Font = Drawing.Fonts.System
            btnTxt.Visible = false
            btnTxt.Center = true
            btnTxt.ZIndex = 4
            btn.Txt = btnTxt
            
            function btn:Update(pos)
                local bSize = Vector2.new(mainSize.X - 40, 28)
                btn.Border.Position = pos
                btn.Border.Size = bSize
                updateRoundedBox(btn.BorderShapes, pos, bSize, btnRadius)
                
                local bgSize = Vector2.new(mainSize.X - 42, 26)
                updateRoundedBox(btn.BgShapes, pos + Vector2.new(1, 1), bgSize, btnRadius)
                
                btnTxt.Position = pos + Vector2.new((mainSize.X - 40)/2, 13)
                
                if os.clock() - btn.ClickTime > 0.1 then
                    setShapesColor(btn.BgShapes, colors.ElementBg)
                end
            end
            
            function btn:SetVisible(vis)
                for _, s in pairs(btn.BorderShapes) do s.Visible = vis end
                for _, s in pairs(btn.BgShapes) do s.Visible = vis end
                btnTxt.Visible = vis
            end
            
            table.insert(tab.Elements, btn)
            return btn
        end

        function tab:CreateToggle(text, callback)
             local tog = { Type = "Toggle", Height = 25, Callback = callback, State = false }

             local togOuter = Drawing.new("Circle")
             togOuter.Radius = 9
             togOuter.Filled = true
             togOuter.Color = colors.Accent
             togOuter.NumSides = 20
             togOuter.Visible = false
             togOuter.ZIndex = 3
             tog.Outer = togOuter

             local togHole = Drawing.new("Circle")
             togHole.Radius = 7
             togHole.Filled = true
             togHole.Color = colors.ElementBg
             togHole.NumSides = 20
             togHole.Visible = false
             togHole.ZIndex = 4
             tog.Hole = togHole

             local togInner = Drawing.new("Circle")
             togInner.Radius = 4
             togInner.Filled = true
             togInner.Color = colors.Accent
             togInner.NumSides = 20
             togInner.Visible = false
             togInner.ZIndex = 5
             tog.Inner = togInner

             local togTxt = Drawing.new("Text")
             togTxt.Text = text
             togTxt.Size = 14
             togTxt.Color = colors.Text
             togTxt.Font = Drawing.Fonts.System
             togTxt.Visible = false
             togTxt.ZIndex = 4
             tog.Txt = togTxt

             function tog:Update(pos)
                local circleCenter = pos + Vector2.new(10, 12)

                togOuter.Position = circleCenter
                togHole.Position = circleCenter
                togInner.Position = circleCenter

                togTxt.Position = pos + Vector2.new(28, 4)

                togInner.Visible = (tog.State and window.ActiveTab == tab)
             end

             function tog:SetVisible(vis)
                togOuter.Visible = vis
                togHole.Visible = vis
                togTxt.Visible = vis
                if vis and tog.State then togInner.Visible = true else togInner.Visible = false end
             end

             table.insert(tab.Elements, tog)
             return tog
        end
        
        function tab:CreateSlider(text, min, max, callback)
             local sld = { Type = "Slider", Height = 40, Callback = callback, Min = min, Max = max, Value = min }
             
             local sBg = Drawing.new("Square")
             sBg.Size = Vector2.new(mainSize.X - 40, 4)
             sBg.Filled = true
             sBg.Color = colors.ElementBg
             sBg.Visible = false
             sBg.ZIndex = 3
             sld.Bg = sBg
             
             local sFill = Drawing.new("Square")
             sFill.Size = Vector2.new(0, 4)
             sFill.Filled = true
             sFill.Color = colors.Accent
             sFill.Visible = false
             sFill.ZIndex = 4
             sld.Fill = sFill
             
             local sKnob = Drawing.new("Circle")
             sKnob.Radius = 6
             sKnob.Filled = true
             sKnob.Color = colors.Text
             sKnob.ZIndex = 5
             sKnob.Visible = false
             sld.Knob = sKnob
             
             local sTxt = Drawing.new("Text")
             sTxt.Text = text
             sTxt.Size = 14
             sTxt.Color = colors.Text
             sTxt.Font = Drawing.Fonts.System
             sTxt.Visible = false
             sTxt.ZIndex = 4
             sld.Txt = sTxt
             
             local sVal = Drawing.new("Text")
             sVal.Text = tostring(min)
             sVal.Size = 14
             sVal.Color = colors.Text
             sVal.Font = Drawing.Fonts.System
             sVal.Visible = false
             sVal.Center = true
             sVal.ZIndex = 4
             sld.Val = sVal
             
             function sld:Update(pos)
                sTxt.Position = pos
                sVal.Position = pos + Vector2.new(sBg.Size.X - 10, 0)
                
                sBg.Position = pos + Vector2.new(0, 20)
                sFill.Position = pos + Vector2.new(0, 20)
                
                local pct = (sld.Value - sld.Min) / (sld.Max - sld.Min)
                sFill.Size = Vector2.new(sBg.Size.X * pct, 4)
                
                sKnob.Position = sFill.Position + Vector2.new(sFill.Size.X, 2)
             end
             
             function sld:SetVisible(vis)
                sBg.Visible = vis
                sFill.Visible = vis
                sTxt.Visible = vis
                sVal.Visible = vis
                sKnob.Visible = vis
             end
             
             table.insert(tab.Elements, sld)
             return sld
        end
        
        function tab:CreateDropdown(text, options, callback, multi)
             local drop = { 
                 Type = "Dropdown", 
                 Height = 40,
                 Callback = callback, 
                 Options = options, 
                 Open = false,
                 Selected = multi and {} or (options[1] or ""),
                 Multi = multi or false,
                 ScrollIndex = 1,
                 MaxVisible = 6
             }
             
             local dropRadius = 5
             local dBgShapes = createRoundedBox(dropRadius, true, 3)
             setShapesColor(dBgShapes, colors.ElementBg)
             for _, s in pairs(dBgShapes) do s.Visible = false end
             drop.BgShapes = dBgShapes
             
             drop.Bg = { 
                 Position = Vector2.new(0, 0), 
                 Size = Vector2.new(mainSize.X - 40, 36) 
             }
             
             local dTxt = Drawing.new("Text")
             dTxt.Text = text .. ": " .. (drop.Multi and "None" or drop.Selected)
             dTxt.Size = 14
             dTxt.Color = colors.Text
             dTxt.Font = Drawing.Fonts.System
             dTxt.Visible = false
             dTxt.ZIndex = 4
             drop.Txt = dTxt
             
             local dArrow = Drawing.new("Triangle")
             dArrow.Color = colors.Text
             dArrow.Filled = true
             dArrow.Visible = false
             dArrow.ZIndex = 4
             drop.Arrow = dArrow
             
             local sUp = Drawing.new("Triangle")
             sUp.Color = colors.Text
             sUp.Filled = true
             sUp.Visible = false
             sUp.ZIndex = 5
             drop.ScrollUp = sUp
             
             local sDown = Drawing.new("Triangle")
             sDown.Color = colors.Text
             sDown.Filled = true
             sDown.Visible = false
             sDown.ZIndex = 5
             drop.ScrollDown = sDown

             local dListBg = Drawing.new("Square")
             dListBg.Filled = true
             dListBg.Color = Color3.fromRGB(28, 28, 28)
             dListBg.Visible = false
             dListBg.ZIndex = 4
             drop.ListBg = dListBg
             
             drop.OptionDrawings = {}
             
             function drop:Update(pos)
                drop.Bg.Position = pos
                drop.Bg.Size = Vector2.new(mainSize.X - 40, 36)
                updateRoundedBox(drop.BgShapes, pos, drop.Bg.Size, dropRadius)

                dTxt.Position = pos + Vector2.new(10, 11)
                
                local displayStr = ""
                if drop.Multi then
                    local selectedCount = 0
                    local first = nil
                    for k, v in pairs(drop.Selected) do
                        if v then
                             selectedCount = selectedCount + 1
                             if not first then first = k end
                        end
                    end
                    if selectedCount == 0 then displayStr = "None"
                    elseif selectedCount == 1 then displayStr = first
                    else displayStr = selectedCount .. " Selected" end
                else
                    displayStr = drop.Selected
                end
                dTxt.Text = text .. ": " .. displayStr
                
                local arrowCenter = pos + Vector2.new(drop.Bg.Size.X - 20, 18)
                if drop.Open then
                    dArrow.PointA = arrowCenter + Vector2.new(-5, 3)
                    dArrow.PointB = arrowCenter + Vector2.new(5, 3)
                    dArrow.PointC = arrowCenter + Vector2.new(0, -3)
                else
                    dArrow.PointA = arrowCenter + Vector2.new(-5, -3)
                    dArrow.PointB = arrowCenter + Vector2.new(5, -3)
                    dArrow.PointC = arrowCenter + Vector2.new(0, 3)
                end
                
                if drop.Open then
                     local currentOptY = pos.Y + 40
                     local centerX = pos.X + drop.Bg.Size.X / 2
                     
                     if drop.ScrollIndex > 1 then
                         local arrowY = currentOptY + 10
                         drop.ScrollUp.Visible = true
                         drop.ScrollUp.PointA = Vector2.new(centerX, arrowY - 5)
                         drop.ScrollUp.PointB = Vector2.new(centerX - 6, arrowY + 5)
                         drop.ScrollUp.PointC = Vector2.new(centerX + 6, arrowY + 5)
                         currentOptY = currentOptY + 20
                     else
                         drop.ScrollUp.Visible = false
                     end

                     local drawnCount = 0
                     for i = 0, drop.MaxVisible - 1 do
                         local realIdx = drop.ScrollIndex + i
                         if realIdx > #drop.Options then break end
                         
                         drawnCount = drawnCount + 1
                         local drawIdx = drawnCount
                         
                         if not drop.OptionDrawings[drawIdx] then
                             local optBg = Drawing.new("Square")
                             optBg.Color = Color3.fromRGB(28, 28, 28)
                             optBg.Filled = true
                             optBg.Visible = false
                             optBg.ZIndex = 2
                             
                             local optTxt = Drawing.new("Text")
                             optTxt.Color = colors.Text
                             optTxt.Size = 13
                             optTxt.Font = Drawing.Fonts.System
                             optTxt.Visible = false
                             optTxt.Center = true 
                             optTxt.ZIndex = 3
                             
                             drop.OptionDrawings[drawIdx] = {Bg = optBg, Txt = optTxt}
                         end
                         
                         local d = drop.OptionDrawings[drawIdx]
                         d.Bg.Visible = true
                         d.Bg.Position = Vector2.new(pos.X, currentOptY)
                         d.Bg.Size = Vector2.new(drop.Bg.Size.X, 24)
                         
                         d.Txt.Visible = true
                         d.Txt.Position = Vector2.new(pos.X + drop.Bg.Size.X/2, currentOptY + 12)
                         d.Txt.Text = drop.Options[realIdx]
                         
                         local isSelected = false
                         if drop.Multi then
                             isSelected = drop.Selected[drop.Options[realIdx]]
                         else
                             isSelected = (drop.Options[realIdx] == drop.Selected)
                         end
                         
                         if isSelected then
                             d.Txt.Color = colors.Accent
                         else
                             d.Txt.Color = colors.Text
                         end
                         
                         currentOptY = currentOptY + 26 
                     end
                     
                     for i = drawnCount + 1, #drop.OptionDrawings do
                         drop.OptionDrawings[i].Bg.Visible = false
                         drop.OptionDrawings[i].Txt.Visible = false
                     end
                     
                     if drop.ScrollIndex + drop.MaxVisible <= #drop.Options then
                         local arrowY = currentOptY + 10
                         drop.ScrollDown.Visible = true
                         drop.ScrollDown.PointA = Vector2.new(centerX, arrowY + 5)
                         drop.ScrollDown.PointB = Vector2.new(centerX - 6, arrowY - 5)
                         drop.ScrollDown.PointC = Vector2.new(centerX + 6, arrowY - 5)
                         currentOptY = currentOptY + 20
                     else
                         drop.ScrollDown.Visible = false
                     end
                     
                     drop.ListBg.Visible = true
                     drop.ListBg.Position = Vector2.new(pos.X, pos.Y + 40)
                     drop.ListBg.Size = Vector2.new(drop.Bg.Size.X, currentOptY - (pos.Y + 40))

                     drop.Height = 40
                else
                     drop.Height = 40
                     drop.ListBg.Visible = false
                     drop.ScrollUp.Visible = false
                     drop.ScrollDown.Visible = false
                     for _, d in pairs(drop.OptionDrawings) do
                         d.Bg.Visible = false
                         d.Txt.Visible = false
                     end
                end
             end
             
             function drop:SetVisible(vis)
                 for _, s in pairs(drop.BgShapes) do s.Visible = vis end
                 dTxt.Visible = vis
                 dArrow.Visible = vis
                 
                 if vis and drop.Open then
                     drop.ListBg.Visible = true
                     if drop.ScrollIndex > 1 then drop.ScrollUp.Visible = true end
                     if drop.ScrollIndex + drop.MaxVisible <= #drop.Options then drop.ScrollDown.Visible = true end
                     
                     for i = 1, math.min(drop.MaxVisible, #drop.Options) do
                         if drop.OptionDrawings[i] then
                             drop.OptionDrawings[i].Bg.Visible = true
                             drop.OptionDrawings[i].Txt.Visible = true
                         end
                     end
                 else
                     drop.ListBg.Visible = false
                     drop.ScrollUp.Visible = false
                     drop.ScrollDown.Visible = false
                     for _, d in pairs(drop.OptionDrawings) do
                         d.Bg.Visible = false
                         d.Txt.Visible = false
                     end
                 end
             end
             
             table.insert(tab.Elements, drop)
             return drop
        end

        table.insert(window.Tabs, tab)
        if #window.Tabs == 1 then
             window.ActiveTab = tab
             tab.Visible = true
        end
        return tab
    end

    task.spawn(function()
        local sliderDragging = nil 
        local toggleDebounce = false

            local stabilizer = Drawing.new("Line")
            stabilizer.Visible = true
            stabilizer.Transparency = 0.01
            stabilizer.ZIndex = 0

        while true do
            if window.Destroyed then pcall(function() stabilizer:Remove() end) break end
            task.wait()
            
            stabilizer.From = mainPos
            stabilizer.To = mainPos + Vector2.new(1, 1)

            if iskeypressed(0x5A) then
                if not toggleDebounce then
                    window.Opened = not window.Opened
                    toggleDebounce = true
                end
            else
                toggleDebounce = false
            end
            
            if not window.Opened then
                for _, s in pairs(mainShapes) do s.Visible = false end
                for _, s in pairs(topBarShapes) do s.Visible = false end
                titleText.Visible = false
                separator.Visible = false
                
                for _, tab in ipairs(window.Tabs) do
                    tab.Btn.Visible = false
                    for _, elem in ipairs(tab.Elements) do
                        elem:SetVisible(false)
                    end
                end
                
                continue
            end
            
            for _, s in pairs(mainShapes) do s.Visible = true end
            for _, s in pairs(topBarShapes) do s.Visible = true end
            titleText.Visible = true
            separator.Visible = true

            for _, tab in ipairs(window.Tabs) do
                local isTabActive = (window.ActiveTab == tab)
                
                tab.Btn.Visible = true
                
                for _, elem in ipairs(tab.Elements) do
                    elem:SetVisible(isTabActive)
                end
            end
            
            local isPressed = ismouse1pressed()
            local mousePos = Vector2.new(Mouse.X, Mouse.Y)
            
            if window.Dragging then
                if isPressed then
                    local delta = mousePos - window.DragStart
                    mainPos = window.StartPos + delta
                else
                    window.Dragging = false
                end
            end
            
            if isPressed and not wasMousePressed then
                local consumed = false
                local blockingDropdown = nil
                
                if window.ActiveTab then
                    for _, elem in ipairs(window.ActiveTab.Elements) do
                        if elem.Type == "Dropdown" and elem.Open then
                            blockingDropdown = elem
                            break
                        end
                    end
                end
                
                if blockingDropdown then
                    local overHeader = isMouseOver(blockingDropdown.Bg.Position, blockingDropdown.Bg.Size)
                    local overList = isMouseOver(blockingDropdown.ListBg.Position, blockingDropdown.ListBg.Size)
                    
                    if not overHeader and not overList then
                        blockingDropdown.Open = false
                        consumed = true
                    end
                end
                
                if not consumed then
                     local titleBar = { Position = mainPos, Size = Vector2.new(mainSize.X, 40) }
                     if not blockingDropdown and isMouseOver(titleBar.Position, titleBar.Size) and not sliderDragging then
                         local clickedTab = false
                         for _, tab in ipairs(window.Tabs) do
                             local btnPos = tab.Btn.Position
                             local clickW = tab.Width
                             if isMouseOver(btnPos, Vector2.new(clickW + 5, 20)) then
                                 window.ActiveTab = tab
                                 clickedTab = true
                                 break
                             end
                         end
                         
                         if not clickedTab then
                             window.Dragging = true
                             window.DragStart = mousePos
                             window.StartPos = mainPos
                         end
                     end
                     
                     if window.ActiveTab then
                         for _, elem in ipairs(window.ActiveTab.Elements) do
                             if blockingDropdown and elem ~= blockingDropdown then continue end
                             
                             if elem.Type == "Button" then
                                 if isMouseOver(elem.Border.Position, elem.Border.Size) then
                                     elem.ClickTime = os.clock()
                                     setShapesColor(elem.BgShapes, Color3.fromRGB(60, 60, 60))
                                     task.spawn(elem.Callback)
                                 end
                             elseif elem.Type == "Toggle" then
                                 local clickAreaPos = elem.Txt.Position - Vector2.new(30, 5)
                                 local clickAreaSize = Vector2.new(200, 25)
                                 if isMouseOver(clickAreaPos, clickAreaSize) then
                                     elem.State = not elem.State
                                     elem.Inner.Visible = elem.State
                                     task.spawn(function() elem.Callback(elem.State) end)
                                 end
                             elseif elem.Type == "Slider" then
                                 if isMouseOver(elem.Bg.Position - Vector2.new(0, 10), elem.Bg.Size + Vector2.new(0, 20)) then
                                     sliderDragging = elem
                                 end
                             elseif elem.Type == "Dropdown" then
                                 local clickedOption = false
                                 if elem.Open then
                                      local currentY = elem.Bg.Position.Y + 40
                                      
                                      if elem.ScrollIndex > 1 then
                                          if isMouseOver(Vector2.new(elem.Bg.Position.X, currentY), Vector2.new(elem.Bg.Size.X, 20)) then
                                              elem.ScrollIndex = math.max(1, elem.ScrollIndex - 1)
                                              clickedOption = true
                                          end
                                          currentY = currentY + 20
                                      end
                                      
                                      if not clickedOption then
                                          for i = 0, elem.MaxVisible - 1 do
                                              local realIdx = elem.ScrollIndex + i
                                              if realIdx > #elem.Options then break end
                                              
                                              local optPos = Vector2.new(elem.Bg.Position.X, currentY) 
                                              if isMouseOver(optPos, Vector2.new(elem.Bg.Size.X, 24)) then
                                                  local val = elem.Options[realIdx]
                                                  if elem.Multi then
                                                      if elem.Selected[val] then
                                                          elem.Selected[val] = nil
                                                      else
                                                          elem.Selected[val] = true
                                                      end
                                                      task.spawn(function() elem.Callback(elem.Selected) end)
                                                  else
                                                      elem.Selected = val
                                                      elem.Open = false
                                                      task.spawn(function() elem.Callback(elem.Selected) end)
                                                  end
                                                  clickedOption = true
                                                  break
                                              end
                                              currentY = currentY + 26
                                          end
                                      end
                                      
                                      if not clickedOption and (elem.ScrollIndex + elem.MaxVisible <= #elem.Options) then
                                          if isMouseOver(Vector2.new(elem.Bg.Position.X, currentY), Vector2.new(elem.Bg.Size.X, 20)) then
                                              elem.ScrollIndex = math.min(#elem.Options - elem.MaxVisible + 1, elem.ScrollIndex + 1)
                                              clickedOption = true
                                          end
                                      end
                                 end
                                 
                                 if not clickedOption and isMouseOver(elem.Bg.Position, Vector2.new(elem.Bg.Size.X, 36)) then
                                      elem.Open = not elem.Open
                                 end
                             end
                         end
                     end
                end
            end
            
            if isPressed and sliderDragging then
                local elem = sliderDragging
                local relX = mousePos.X - elem.Bg.Position.X
                local pct = math.clamp(relX / elem.Bg.Size.X, 0, 1)
                local newVal = math.floor(elem.Min + (elem.Max - elem.Min) * pct)
                
                if newVal ~= elem.Value then
                    elem.Value = newVal
                    elem.Val.Text = tostring(newVal)
                    task.spawn(function() elem.Callback(newVal) end)
                end
            end
            
            if not isPressed then
                sliderDragging = nil
            end
            
            wasMousePressed = isPressed
            updatePositions()
        end
    end)
    
    function window:Destroy()
        window.Destroyed = true
        
        for _, s in pairs(mainShapes) do pcall(function() s:Remove() end) end
        for _, s in pairs(topBarShapes) do pcall(function() s:Remove() end) end
        pcall(function() titleText:Remove() end)
        pcall(function() separator:Remove() end)
        
        for _, tab in ipairs(window.Tabs) do
            pcall(function() tab.Btn:Remove() end)
            for _, elem in ipairs(tab.Elements) do
                if elem.Type == "Section" then
                     pcall(function() elem.Txt:Remove() end)
                     pcall(function() elem.Line:Remove() end)
                elseif elem.Type == "Button" then
                     for _, s in pairs(elem.BorderShapes) do pcall(function() s:Remove() end) end
                     for _, s in pairs(elem.BgShapes) do pcall(function() s:Remove() end) end
                     pcall(function() elem.Txt:Remove() end)
                elseif elem.Type == "Toggle" then
                     pcall(function() elem.Outer:Remove() end)
                     pcall(function() elem.Hole:Remove() end)
                     pcall(function() elem.Inner:Remove() end)
                     pcall(function() elem.Txt:Remove() end)
                elseif elem.Type == "Slider" then
                     pcall(function() elem.Bg:Remove() end)
                     pcall(function() elem.Fill:Remove() end)
                     pcall(function() elem.Knob:Remove() end)
                     pcall(function() elem.Txt:Remove() end)
                     pcall(function() elem.Val:Remove() end)
                elseif elem.Type == "Dropdown" then
                     pcall(function() elem.Bg:Remove() end)
                     pcall(function() elem.Txt:Remove() end)
                     pcall(function() elem.Arrow:Remove() end)
                     pcall(function() elem.ScrollUp:Remove() end)
                     pcall(function() elem.ScrollDown:Remove() end)
                     pcall(function() elem.ListBg:Remove() end)
                     for _, d in pairs(elem.OptionDrawings) do
                         pcall(function() d.Bg:Remove() end)
                         pcall(function() d.Txt:Remove() end)
                     end
                end
            end
        end
    end

    return window
end

function Library:ShowDemo()
    local Win = Library:CreateWindow("Demo", Vector2.new(500, 400))
    local Tab1 = Win:CreateTab("Main")
    local Tab2 = Win:CreateTab("Settings")
    
    Tab1:CreateSection("Features")
    
    Tab1:CreateButton("fat", function()
        print("Hello from Matcha!")
    end)
    
     Tab1:CreateToggle("Enable Feature", function(state)
        print("Feature Enabled:", state)
    end)
    
    Tab1:CreateSection("Configuration")
    
    Tab1:CreateSlider("WalkSpeed", 16, 100, function(val)
        print("Speed:", val)
    end)
    
    Tab1:CreateDropdown("Theme", {"Dark", "Light", "Midnight", "Ocean"}, function(val)
        print("Theme selected:", val)
    end)
    
    Tab2:CreateSection("Preferences")
    
    Tab2:CreateButton("Reset Config", function()
        print("Config Reset")
    end)
    
    Tab2:CreateToggle("Dark Mode", function(state)
        print("Dark Mode:", state)
    end)
end

return Library
