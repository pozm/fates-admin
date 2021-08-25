local Utils = {}

Utils.Tween = function(Object, Style, Direction, Time, Goal)
    local TweenService = Services.TweenService
    local TInfo = TweenInfo.new(Time, Enum.EasingStyle[Style], Enum.EasingDirection[Direction])
    local Tween = TweenService.Create(TweenService, Object, TInfo, Goal)

    Tween.Play(Tween)

    return Tween
end

Utils.MultColor3 = function(Color, Delta)
    local clamp = math.clamp
    return Color3.new(clamp(Color.R * Delta, 0, 1), clamp(Color.G * Delta, 0, 1), clamp(Color.B * Delta, 0, 1));
end

Utils.Click = function(Object, Goal) -- Utils.Click(Object, "BackgroundColor3")
    local Hover = {
        [Goal] = Utils.MultColor3(Object[Goal], 0.9)
    }

    local Press = {
        [Goal] = Utils.MultColor3(Object[Goal], 1.2)
    }

    local Origin = {
        [Goal] = Object[Goal]
    }

    AddConnection(CConnect(Object.MouseEnter, function()
        Utils.Tween(Object, "Sine", "Out", .5, Hover);
    end));

    AddConnection(CConnect(Object.MouseLeave, function()
        Utils.Tween(Object, "Sine", "Out", .5, Origin);
    end));

    AddConnection(CConnect(Object.MouseButton1Down, function()
        Utils.Tween(Object, "Sine", "Out", .3, Press);
    end));

    AddConnection(CConnect(Object.MouseButton1Up, function()
        Utils.Tween(Object, "Sine", "Out", .4, Hover);
    end));
end

Utils.Blink = function(Object, Goal, Color1, Color2) -- Utils.Click(Object, "BackgroundColor3", NormalColor, OtherColor)
    local Normal = {
        [Goal] = Color1
    }

    local Blink = {
        [Goal] = Color2
    }

    local Tween = Utils.Tween(Object, "Sine", "Out", .5, Blink)
    CWait(Tween.Completed);

    Tween = Utils.Tween(Object, "Sine", "Out", .5, Normal)
    CWait(Tween.Completed);
end

Utils.Hover = function(Object, Goal)
    local Hover = {
        [Goal] = Utils.MultColor3(Object[Goal], 0.9)
    }

    local Origin = {
        [Goal] = Object[Goal]
    }

    AddConnection(CConnect(Object.MouseEnter, function()
        Utils.Tween(Object, "Sine", "Out", .5, Hover);
    end));

    AddConnection(CConnect(Object.MouseLeave, function()
        Utils.Tween(Object, "Sine", "Out", .5, Origin);
    end));
end

Utils.Draggable = function(Ui, DragUi)
    local DragSpeed = 0
    local StartPos
    local DragToggle, DragInput, DragStart, DragPos

    DragUi = Dragui or Ui
    local TweenService = Services.TweenService

    local function UpdateInput(Input)
        local Delta = Input.Position - DragStart
        local Position = UDim2.new(StartPos.X.Scale, StartPos.X.Offset + Delta.X, StartPos.Y.Scale, StartPos.Y.Offset + Delta.Y)

        Utils.Tween(Ui, "Linear", "Out", .25, {
            Position = Position
        });
        local Tween = TweenService.Create(TweenService, Ui, TweenInfo.new(0.25), {Position = Position});
        Tween.Play(Tween);
    end

    AddConnection(CConnect(Ui.InputBegan, function(Input)
        if ((Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch) and Services.UserInputService.GetFocusedTextBox(Services.UserInputService) == nil) then
            DragToggle = true
            DragStart = Input.Position
            StartPos = Ui.Position

            AddConnection(CConnect(Input.Changed, function()
                if (Input.UserInputState == Enum.UserInputState.End) then
                    DragToggle = false
                end
            end));
        end
    end));

    AddConnection(CConnect(Ui.InputChanged, function(Input)
        if (Input.UserInputType == Enum.UserInputType.MouseMovement or Input.UserInputType == Enum.UserInputType.Touch) then
            DragInput = Input
        end
    end));

    AddConnection(CConnect(Services.UserInputService.InputChanged, function(Input)
        if (Input == DragInput and DragToggle) then
            UpdateInput(Input)
        end
    end));
end

Utils.SmoothScroll = function(content, SmoothingFactor) -- by Elttob
    -- get the 'content' scrolling frame, aka the scrolling frame with all the content inside
    -- if smoothing is enabled, disable scrolling
    content.ScrollingEnabled = false

    -- create the 'input' scrolling frame, aka the scrolling frame which receives user input
    -- if smoothing is enabled, enable scrolling
    local input = Clone(content)

    input.ClearAllChildren(input);
    input.BackgroundTransparency = 1
    input.ScrollBarImageTransparency = 1
    input.ZIndex = content.ZIndex + 1
    input.Name = "_smoothinputframe"
    input.ScrollingEnabled = true
    input.Parent = content.Parent

    -- keep input frame in sync with content frame
    local function syncProperty(prop)
        AddConnection(CConnect(GetPropertyChangedSignal(content, prop), function()
            if prop == "ZIndex" then
                -- keep the input frame on top!
                input[prop] = content[prop] + 1
            else
                input[prop] = content[prop]
            end
        end));
    end

    syncProperty "CanvasSize"
    syncProperty "Position"
    syncProperty "Rotation"
    syncProperty "ScrollingDirection"
    syncProperty "ScrollBarThickness"
    syncProperty "BorderSizePixel"
    syncProperty "ElasticBehavior"
    syncProperty "SizeConstraint"
    syncProperty "ZIndex"
    syncProperty "BorderColor3"
    syncProperty "Size"
    syncProperty "AnchorPoint"
    syncProperty "Visible"

    -- create a render stepped connection to interpolate the content frame position to the input frame position
    local smoothConnection = AddConnection(CConnect(RenderStepped, function()
        local a = content.CanvasPosition
        local b = input.CanvasPosition
        local c = SmoothingFactor
        local d = (b - a) * c + a

        content.CanvasPosition = d
    end));

    AddConnection(CConnect(content.AncestryChanged, function()
        if content.Parent == nil then
            Destroy(input);
            Disconnect(smoothConnection);
        end
    end));
end

Utils.TweenAllTransToObject = function(Object, Time, BeforeObject) -- max transparency is max object transparency, swutched args bc easier command
    local Descendants = GetDescendants(Object);
    local OldDescentants = GetDescendants(BeforeObject);
    local Tween -- to use to wait

    Tween = Utils.Tween(Object, "Sine", "Out", Time, {
        BackgroundTransparency = BeforeObject.BackgroundTransparency
    })

    for i = 1, #Descendants do
        local v = Descendants[i]
        local IsText = IsA(v, "TextBox") or IsA(v, "TextLabel") or IsA(v, "TextButton")
        local IsImage = IsA(v, "ImageLabel") or IsA(v, "ImageButton")
        local IsScrollingFrame = IsA(v, "ScrollingFrame")

        if (IsA(v, "GuiObject")) then
            if (IsText) then
                Utils.Tween(v, "Sine", "Out", Time, {
                    TextTransparency = OldDescentants[i].TextTransparency,
                    TextStrokeTransparency = OldDescentants[i].TextStrokeTransparency,
                    BackgroundTransparency = OldDescentants[i].BackgroundTransparency
                })
            elseif (IsImage) then
                Utils.Tween(v, "Sine", "Out", Time, {
                    ImageTransparency = OldDescentants[i].ImageTransparency,
                    BackgroundTransparency = OldDescentants[i].BackgroundTransparency
                })
            elseif (IsScrollingFrame) then
                Utils.Tween(v, "Sine", "Out", Time, {
                    ScrollBarImageTransparency = OldDescentants[i].ScrollBarImageTransparency,
                    BackgroundTransparency = OldDescentants[i].BackgroundTransparency
                })
            else
                Utils.Tween(v, "Sine", "Out", Time, {
                    BackgroundTransparency = OldDescentants[i].BackgroundTransparency
                })
            end
        end
    end

    return Tween
end

Utils.SetAllTrans = function(Object)
    Object.BackgroundTransparency = 1

    local Descendants = GetDescendants(Object);
    for i = 1, #Descendants do
        local v = Descendants[i]
        local IsText = IsA(v, "TextBox") or IsA(v, "TextLabel") or IsA(v, "TextButton")
        local IsImage = IsA(v, "ImageLabel") or IsA(v, "ImageButton")
        local IsScrollingFrame = IsA(v, "ScrollingFrame")

        if (IsA(v, "GuiObject")) then
            v.BackgroundTransparency = 1

            if (IsText) then
                v.TextTransparency = 1
            elseif (IsImage) then
                v.ImageTransparency = 1
            elseif (IsScrollingFrame) then
                v.ScrollBarImageTransparency = 1
            end
        end
    end
end

Utils.TweenAllTrans = function(Object, Time)
    local Tween -- to use to wait

    Tween = Utils.Tween(Object, "Sine", "Out", Time, {
        BackgroundTransparency = 1
    })

    local Descendants = GetDescendants(Object);
    for i = 1, #Descendants do
        local v = Descendants[i]
        local IsText = IsA(v, "TextBox") or IsA(v, "TextLabel") or IsA(v, "TextButton")
        local IsImage = IsA(v, "ImageLabel") or IsA(v, "ImageButton")
        local IsScrollingFrame = IsA(v, "ScrollingFrame")

        if (IsA(v, "GuiObject")) then
            if (IsText) then
                Utils.Tween(v, "Sine", "Out", Time, {
                    TextTransparency = 1,
                    BackgroundTransparency = 1
                })
            elseif (IsImage) then
                Utils.Tween(v, "Sine", "Out", Time, {
                    ImageTransparency = 1,
                    BackgroundTransparency = 1
                })
            elseif (IsScrollingFrame) then
                Utils.Tween(v, "Sine", "Out", Time, {
                    ScrollBarImageTransparency = 1,
                    BackgroundTransparency = 1
                })
            else
                Utils.Tween(v, "Sine", "Out", Time, {
                    BackgroundTransparency = 1
                })
            end
        end
    end

    return Tween
end

Utils.Notify = function(Caller, Title, Message, Time)
    if (not Caller or Caller == LocalPlayer) then
        local Notification = UI.Notification
        local NotificationBar = UI.NotificationBar

        local Clone = Clone(Notification)

        local function TweenDestroy()
            if (Utils and Clone) then
                local Tween = Utils.TweenAllTrans(Clone, .25)

                CWait(Tween.Completed)
                Destroy(Clone);
            end
        end

        Clone.Message.Text = Message
        Clone.Title.Text = Title or "Notification"
        Utils.SetAllTrans(Clone)
        Utils.Click(Clone.Close, "TextColor3")
        Clone.Visible = true

        if (len(Message) >= 35) then
            Clone.AutomaticSize = Enum.AutomaticSize.Y
            Clone.Message.AutomaticSize = Enum.AutomaticSize.Y
            Clone.Message.RichText = true
            Clone.Message.TextScaled = false
            Clone.Message.TextYAlignment = Enum.TextYAlignment.Top
            Clone.DropShadow.AutomaticSize = Enum.AutomaticSize.Y
        end

        Clone.Parent = NotificationBar

        coroutine.wrap(function()
            local Tween = Utils.TweenAllTransToObject(Clone, .5, Notification)

            CWait(Tween.Completed);
            wait(Time or 5);

            if (Clone) then
                TweenDestroy();
            end
        end)()

        AddConnection(CConnect(Clone.Close.MouseButton1Click, TweenDestroy));

        return Clone
    else
        local ChatRemote = Services.ReplicatedStorage.DefaultChatSystemChatEvents.SayMessageRequest
        ChatRemote.FireServer(ChatRemote, format("/w %s [FA] %s: %s", Caller.Name, Title, Message), "All");
    end
end

Utils.MatchSearch = function(String1, String2)
    return String1 == sub(String2, 1, #String1);
end

Utils.StringFind = function(Table, String)
    for _, v in ipairs(Table) do
        if (Utils.MatchSearch(String, v)) then
            return v
        end
    end
end

Utils.GetPlayerArgs = function(Arg)
    Arg = lower(Arg);
    local SpecialCases = {"all", "others", "random", "me", "nearest", "farthest", "npcs", "allies", "enemies"}
    if (Utils.StringFind(SpecialCases, Arg)) then
        return Utils.StringFind(SpecialCases, Arg);
    end

    local CurrentPlayers = GetPlayers(Players);
    for i, v in next, CurrentPlayers do
        local Name, DisplayName = v.Name, v.DisplayName
        if (Name ~= DisplayName and Utils.MatchSearch(Arg, lower(DisplayName))) then
            return lower(DisplayName);
        end
        if (Utils.MatchSearch(Arg, lower(Name))) then
            return lower(Name);
        end
    end
end

Utils.ToolTip = function(Object, Message)
    local CloneToolTip
    local TextService = Services.TextService

    AddConnection(CConnect(Object.MouseEnter, function()
        if (Object.BackgroundTransparency < 1 and not CloneToolTip) then
            local TextSize = TextService.GetTextSize(TextService, Message, 12, Enum.Font.Gotham, Vector2.new(200, math.huge)).Y > 24

            CloneToolTip = Clone(UI.ToolTip)
            CloneToolTip.Text = Message
            CloneToolTip.TextScaled = TextSize
            CloneToolTip.Visible = true
            CloneToolTip.Parent = UI
        end
    end))

    AddConnection(CConnect(Object.MouseLeave, function()
        if (CloneToolTip) then
            Destroy(CloneToolTip);
            CloneToolTip = nil
        end
    end))

    if (LocalPlayer) then
        AddConnection(CConnect(Mouse.Move, function()
            if (CloneToolTip) then
                CloneToolTip.Position = UDim2.fromOffset(Mouse.X + 10, Mouse.Y + 10)
            end
        end))
    else
        delay(3, function()
            LocalPlayer = Players.LocalPlayer
            AddConnection(CConnect(Mouse.Move, function()
                if (CloneToolTip) then
                    CloneToolTip.Position = UDim2.fromOffset(Mouse.X + 10, Mouse.Y + 10)
                end
            end))
        end)
    end
end

Utils.ClearAllObjects = function(Object)
    local Children = GetChildren(Object);
    for i = 1, #Children do
        local Child = Children[i]
        if (IsA(Child, "GuiObject")) then
            Destroy(Child);
        end
    end
end

Utils.Rainbow = function(TextObject)
    local Text = TextObject.Text
    local Frequency = 1 -- determines how quickly it repeats
    local TotalCharacters = 0
    local Strings = {}

    TextObject.RichText = true

    for Character in gmatch(Text, ".") do
        if match(Character, "%s") then
            Strings[#Strings + 1] = Character
        else
            TotalCharacters = TotalCharacters + 1
            Strings[#Strings + 1] = {'<font color="rgb(%i, %i, %i)">' .. Character .. '</font>'}
        end
    end

    pcall(function()
        local Connection = AddConnection(CConnect(Heartbeat, function()
            local String = ""
            local Counter = TotalCharacters
    
            for _, CharacterTable in ipairs(Strings) do
                local Concat = ""
    
                if (type(CharacterTable) == "table") then
                    Counter = Counter - 1
                    local Color = Color3.fromHSV(-atan(math.tan((tick() + Counter/math.pi)/Frequency))/math.pi + 0.5, 1, 1)
    
                    CharacterTable = format(CharacterTable[1], floor(Color.R * 255), floor(Color.G * 255), floor(Color.B * 255))
                end
    
                String = String .. CharacterTable
            end
    
            TextObject.Text = String .. " "
        end));
        delay(150, function()
            Disconnect(Connection);
        end)
    end)
end

Utils.Vector3toVector2 = function(Vector)
    local Tuple = WorldToViewportPoint(Camera, Vector);
    return Vector2New(Tuple.X, Tuple.Y);
end

Utils.CheckTag = function(Plr)
    if (not Plr or not IsA(Plr, "Player")) then
        return nil
    end
    local UserId = tostring(Plr.UserId);
    local Tag = PlayerTags[gsub(UserId, ".", function(x)
        return byte(x);
    end)]
    return Tag or nil
end

Utils.AddTag = function(Tag)
    if (not Tag) then
        return
    end
    local PlrCharacter = GetCharacter(Tag.Player)
    if (not PlrCharacter) then
        return
    end
    local Billboard = InstanceNew("BillboardGui");
    Billboard.Parent = UI
    Billboard.Name = GenerateGUID(Services.HttpService);
    Billboard.AlwaysOnTop = true
    Billboard.Adornee = FindFirstChild(PlrCharacter, "Head") or nil
    Billboard.Enabled = FindFirstChild(PlrCharacter, "Head") and true or false
    Billboard.Size = UDim2.new(0, 200, 0, 50)
    Billboard.StudsOffset = Vector3New(0, 4, 0);

    local TextLabel = InstanceNew("TextLabel", Billboard);
    TextLabel.Name = GenerateGUID(Services.HttpService);
    TextLabel.TextStrokeTransparency = 0.6
    TextLabel.BackgroundTransparency = 1
    TextLabel.TextColor3 = Color3.new(0, 255, 0);
    TextLabel.Size = UDim2.new(0, 200, 0, 50);
    TextLabel.TextScaled = false
    TextLabel.TextSize = 15
    TextLabel.Text = format("%s (%s)", Tag.Name, Tag.Tag);

    if (Tag.Rainbow) then
        Utils.Rainbow(TextLabel)
    end
    if (Tag.Colour) then
        local TColour = Tag.Colour
        TextLabel.TextColor3 = Color3.fromRGB(TColour[1], TColour[2], TColour[3]);
    end

    local Added = AddConnection(CConnect(Tag.Player.CharacterAdded, function()
        Billboard.Adornee = WaitForChild(Tag.Player.Character, "Head");
    end));

    AddConnection(CConnect(Players.PlayerRemoving, function(plr)
        if (plr == Tag.Player) then
            Disconnect(Added);
            Destroy(Billboard);
        end
    end))
end

Utils.TextFont = function(Text, RGB)
    RGB = concat(RGB, ",")
    local New = {}
    gsub(Text, ".", function(x)
        New[#New + 1] = x
    end)
    return concat(map(New, function(i, letter)
        return format('<font color="rgb(%s)">%s</font>', RGB, letter)
    end)) .. " "
end

Utils.Thing = function(Object)
    local Container = InstanceNew("Frame")
    local Hitbox = InstanceNew("ImageButton")
    
    Container.Name = "Container"
    Container.Parent = Object.Parent
    Container.BackgroundTransparency = 1.000
    Container.BorderSizePixel = 0
    Container.Position = Object.Position
    Container.ClipsDescendants = true
    Container.Size = UDim2.fromOffset(Object.AbsoluteSize.X, Object.AbsoluteSize.Y)
    Container.ZIndex = Object
    
    Object.AutomaticSize = Enum.AutomaticSize.X
    Object.Size = UDim2.fromScale(1, 1)
    Object.Position = UDim2.fromScale(0, 0)
    Object.Parent = Container
    Object.TextTruncate = Enum.TextTruncate.None
    Object.ZIndex = Object.ZIndex + 2
    
    Hitbox.Name = "Hitbox"
    Hitbox.Parent = Container.Parent
    Hitbox.BackgroundTransparency = 1.000
    Hitbox.Size = Container.Size
    Hitbox.Position = Container.Position
    Hitbox.ZIndex = Object.ZIndex + 2
    
    local MouseOut = true
    
    AddConnection(CConnect(Hitbox.MouseEnter, function()
        if Object.AbsoluteSize.X > Container.AbsoluteSize.X then
            MouseOut = false
            repeat
                local Tween1 = Utils.Tween(Object, "Quad", "Out", .5, {
                    Position = UDim2.fromOffset(Container.AbsoluteSize.X - Object.AbsoluteSize.X, 0);
                })
                CWait(Tween1.Completed);
                wait(.5);
                local Tween2 = Utils.Tween(Object, "Quad", "Out", .5, {
                    Position = UDim2.fromOffset(0, 0);
                })
                CWait(Tween2.Completed);
                wait(.5);
            until MouseOut
        end
    end))

    AddConnection(CConnect(Hitbox.MouseLeave, function()
        MouseOut = true
        Utils.Tween(Object, "Quad", "Out", .25, {
            Position = UDim2.fromOffset(0, 0);
        })
    end))
    
    return Object
end