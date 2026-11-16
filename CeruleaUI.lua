--[[
    CeruleaUI 1.2.0
    A small UI library for Roblox executors: window, tabs, cards, toggles, fields, sliders,
    keybinds, tables, charts, notifications, EN/RU (any language) switching and config files.

    local UI  = loadstring(game:HttpGet("https://raw.githubusercontent.com/<you>/<repo>/v1.0.0/CeruleaUI.lua"))()
    local win = UI.new({ Name = "Cerulea", Languages = { "en", "ru" } })

    Everything that shows text accepts either a translation key or a plain string: if the key is not
    found in the translations, the text itself is shown.
]]

local Players          = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local HttpService      = game:GetService("HttpService")
local player           = Players.LocalPlayer

local UI = { Version = "1.2.1" }

--==================== Theme ====================
UI.Theme = {
    bg     = Color3.fromRGB(9, 9, 11),
    card   = Color3.fromRGB(16, 16, 19),
    field  = Color3.fromRGB(10, 10, 13),
    head   = Color3.fromRGB(12, 12, 16),
    text   = Color3.fromRGB(244, 244, 246),
    body   = Color3.fromRGB(196, 196, 207),
    sub    = Color3.fromRGB(138, 138, 150),
    mono   = Color3.fromRGB(124, 124, 138),
    nav    = Color3.fromRGB(164, 164, 176),
    acc    = Color3.fromRGB(91, 107, 255),
    accT   = Color3.fromRGB(139, 152, 255),
    green  = Color3.fromRGB(61, 220, 132),
    red    = Color3.fromRGB(255, 107, 107),
    off    = Color3.fromRGB(42, 42, 51),
    line   = Color3.fromRGB(255, 255, 255),
    button = Color3.fromRGB(22, 22, 27),
    buttonHover = Color3.fromRGB(30, 30, 37),
}
UI.Fonts = {
    Sans = Enum.Font.Gotham, Bold = Enum.Font.GothamBold, Mono = Enum.Font.RobotoMono, Icon = Enum.Font.SourceSansBold,
}
local C, F = UI.Theme, UI.Fonts

--==================== Helpers ====================
local function new(class, props, children)
    local o = Instance.new(class)
    for k, v in pairs(props or {}) do o[k] = v end
    for _, c in ipairs(children or {}) do c.Parent = o end
    return o
end
local function corner(parent, r) return new("UICorner", { CornerRadius = UDim.new(0, r), Parent = parent }) end
local function stroke(parent, transparency, color)
    return new("UIStroke", { Color = color or C.line, Transparency = transparency, Thickness = 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border, Parent = parent })
end
local function frame(parent, props)
    props.BorderSizePixel = 0
    props.Parent = parent
    return new("Frame", props)
end
local function label(parent, props)
    local d = {
        BackgroundTransparency = 1, TextColor3 = C.text, Font = F.Sans, TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left, Text = "", Parent = parent,
    }
    for k, v in pairs(props) do d[k] = v end
    return new("TextLabel", d)
end
local function line(parent, y)
    return frame(parent, { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromOffset(0, y or 0), BackgroundColor3 = C.line, BackgroundTransparency = 0.94 })
end
local function tween(obj, props, t)
    TweenService:Create(obj, TweenInfo.new(t or 0.15, Enum.EasingStyle.Quad), props):Play()
end
local function pad(parent, t, b, l, r)
    return new("UIPadding", {
        PaddingTop = UDim.new(0, t), PaddingBottom = UDim.new(0, b), PaddingLeft = UDim.new(0, l), PaddingRight = UDim.new(0, r), Parent = parent,
    })
end
local function trySerif(lbl)
    pcall(function()
        lbl.FontFace = Font.new("rbxasset://fonts/families/Merriweather.json", Enum.FontWeight.Regular, Enum.FontStyle.Italic)
    end)
end

-- base64 (own implementation, executors differ in what they provide)
local B64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function b64enc(data)
    local out = {}
    for i = 1, #data, 3 do
        local a, b, c = data:byte(i, i + 2)
        local n = a * 65536 + (b or 0) * 256 + (c or 0)
        local c1, c2, c3, c4 = math.floor(n / 262144) % 64, math.floor(n / 4096) % 64, math.floor(n / 64) % 64, n % 64
        out[#out + 1] = B64:sub(c1 + 1, c1 + 1) .. B64:sub(c2 + 1, c2 + 1)
            .. (b and B64:sub(c3 + 1, c3 + 1) or "=") .. (c and B64:sub(c4 + 1, c4 + 1) or "=")
    end
    return table.concat(out)
end
local B64R = {}
for i = 1, #B64 do B64R[B64:sub(i, i)] = i - 1 end
local function b64dec(str)
    str = str:gsub("[^%w%+/=]", "")
    local out = {}
    for i = 1, #str, 4 do
        local c1, c2, c3, c4 = str:sub(i, i), str:sub(i + 1, i + 1), str:sub(i + 2, i + 2), str:sub(i + 3, i + 3)
        local v1, v2 = B64R[c1], B64R[c2]
        if not v1 or not v2 then return nil end
        local v3, v4 = B64R[c3] or 0, B64R[c4] or 0
        local n = v1 * 262144 + v2 * 4096 + v3 * 64 + v4
        local b1, b2, b3 = math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256
        out[#out + 1] = string.char(b1)
        if c3 ~= "=" and c3 ~= "" then out[#out + 1] = string.char(b2) end
        if c4 ~= "=" and c4 ~= "" then out[#out + 1] = string.char(b3) end
    end
    return table.concat(out)
end
function UI.SanitizeName(n)
    n = tostring(n or ""):gsub("[%c/\\:%*%?\"<>|%.]", ""):gsub("^%s+", ""):gsub("%s+$", "")
    return n:sub(1, 40)
end

UI.Util = { new = new, corner = corner, stroke = stroke, frame = frame, label = label, line = line, tween = tween, Theme = C, Fonts = F }

-- Icons: a text glyph, an rbxasset id, or a PNG url. A url is downloaded once into <Folder>/icons and shown
-- through getcustomasset; the glyph stays visible until (and if) the image is ready.
local function resolveFile(win, src, sub)
    if src:find("^rbxasset") then return src end
    if not (getcustomasset and writefile and isfile and readfile) then return nil end
    local name = src:match("([^/]+)$") or "file.bin"
    local dir = win.Folder .. "/" .. sub
    pcall(function()
        if makefolder then
            if not (isfolder and isfolder(win.Folder)) then makefolder(win.Folder) end
            if not (isfolder and isfolder(dir)) then makefolder(dir) end
        end
    end)
    local path = dir .. "/" .. name
    if not isfile(path) then
        local ok, data = pcall(function() return game:HttpGet(src) end)
        if not ok or type(data) ~= "string" or #data < 100 then return nil end
        if not pcall(writefile, path, data) then return nil end
    end
    local ok, asset = pcall(getcustomasset, path)
    return ok and asset or nil
end
local function resolveImage(win, src) return resolveFile(win, src, "icons") end
-- returns { Paint(color) }
local function makeIcon(win, parent, src, glyph, size, pos, color, fontSize)
    local box = frame(parent, { Size = UDim2.fromOffset(size.X, size.Y), Position = pos, BackgroundTransparency = 1 })
    local txt = label(box, { Text = glyph or "•", Font = F.Icon, TextSize = fontSize or 17, TextColor3 = color, TextXAlignment = Enum.TextXAlignment.Center, Size = UDim2.fromScale(1, 1) })
    local obj = { Text = txt, Color = color }
    function obj:Paint(col)
        self.Color = col
        txt.TextColor3 = col
        if self.Image then self.Image.ImageColor3 = col end
    end
    if type(src) == "string" and (src:find("^https?://") or src:find("^rbxasset")) then
        task.spawn(function()
            local asset = resolveImage(win, src)
            if asset and box.Parent then
                local px = math.floor(math.min(size.X, size.Y) * 0.82)
                obj.Image = new("ImageLabel", {
                    BackgroundTransparency = 1, Image = asset, ImageColor3 = obj.Color, AnchorPoint = Vector2.new(0.5, 0.5),
                    Position = UDim2.fromScale(0.5, 0.5), Size = UDim2.fromOffset(px, px), Parent = box,
                })
                txt.Visible = false
            end
        end)
    elseif type(src) == "string" and src ~= "" then
        txt.Text = src
    end
    return obj
end
UI.Util.makeIcon = makeIcon

--==================== Window ====================
local Window = {}
Window.__index = Window
local Tab = {}
Tab.__index = Tab
local Card = {}
Card.__index = Card

function Window:Connect(signal, fn)
    local c = signal:Connect(fn)
    table.insert(self._conns, c)
    return c
end
function Window:AddCleanup(fn) table.insert(self._cleanup, fn) end

-- Translations: win:AddTranslations({ en = { key = "Text" }, ru = { key = "Текст" } })
function Window:AddTranslations(map)
    for lang, tbl in pairs(map) do
        self.Translations[lang] = self.Translations[lang] or {}
        for k, v in pairs(tbl) do self.Translations[lang][k] = v end
    end
    self:Refresh()
end
function Window:T(key)
    if type(key) == "function" then return tostring(key()) end
    local cur = self.Translations[self.Language]
    local en = self.Translations.en
    return (cur and cur[key]) or (en and en[key]) or tostring(key)
end
-- Keeps a text property in sync with the language. keyOrFn is a key, a plain string or a function.
function Window:Bind(obj, keyOrFn, prop)
    local e = { obj = obj, prop = prop or "Text", get = function() return self:T(keyOrFn) end }
    table.insert(self._bound, e)
    obj[e.prop] = e.get()
    return e
end
function Window:Refresh()
    for _, e in ipairs(self._bound) do
        if e.obj.Parent then
            local ok, v = pcall(e.get)
            if ok then e.obj[e.prop] = v end
        end
    end
end
function Window:SetLanguage(code)
    self.Language = code
    self:Refresh()
    for _, c in ipairs(self._langControls) do c:Set(code, true) end
    self:SetPref("Language", code)
    if self._onLanguage then task.spawn(self._onLanguage, code) end
end

-- Flags: every element with a `flag` keeps its value in win.Flags and can be saved / loaded
function Window:_flag(flag, value, setter)
    if not flag then return end
    self.Flags[flag] = value
    self._setters[flag] = setter
end

--==================== Segmented control (shared) ====================
-- items: { "code", ... } or { { key = "translationKey", code = "x" }, { text = "Literal", code = "y" } }
local function segmented(win, parent, items, bw, h, fs, default, onPick)
    local holder = frame(parent, { Size = UDim2.fromOffset(#items * bw + (#items - 1) * 2 + 4, h), BackgroundColor3 = C.card })
    corner(holder, 7)
    stroke(holder, 0.92)
    local obj, btns, value = { Holder = holder }, {}, default
    local function paint()
        for code, b in pairs(btns) do
            local on = (value == code)
            b.BackgroundColor3 = C.line
            b.BackgroundTransparency = on and 0.9 or 1
            b.TextColor3 = on and C.text or C.nav
        end
    end
    for i, it in ipairs(items) do
        if type(it) == "string" then it = { key = it, code = it } end
        local b = new("TextButton", {
            Font = F.Mono, TextSize = fs, AutoButtonColor = false, BorderSizePixel = 0,
            Size = UDim2.fromOffset(bw, h - 4), Position = UDim2.fromOffset(2 + (i - 1) * (bw + 2), 2), Parent = holder,
        })
        corner(b, 5)
        if it.text then b.Text = it.text else win:Bind(b, it.key) end
        btns[it.code] = b
        b.MouseButton1Click:Connect(function()
            win:PlaySound("click")
            value = it.code
            paint()
            if onPick then onPick(it.code) end
        end)
    end
    function obj:Set(code, silent)
        value = code
        paint()
        if not silent and onPick then onPick(code) end
    end
    function obj:Get() return value end
    paint()
    return obj
end

--==================== Constructor ====================
function UI.new(opts)
    opts = opts or {}
    for k, v in pairs(opts.Theme or {}) do C[k] = v end

    local name = opts.Name or "CeruleaUI"
    local env = (getgenv and getgenv()) or _G
    env.__CeruleaWindows = env.__CeruleaWindows or {}
    if env.__CeruleaWindows[name] then pcall(function() env.__CeruleaWindows[name]:Destroy() end) end

    local size = opts.Size or Vector2.new(728, 468)
    local sideW = opts.SidebarWidth or 158
    local topH = 40

    local folder = opts.Folder or name
    local prefs = {}
    if opts.Prefs ~= false and readfile and isfile then
        pcall(function()
            local path = folder .. "/_prefs.json"
            if isfile(path) then
                local d = HttpService:JSONDecode(readfile(path))
                if type(d) == "table" then prefs = d end
            end
        end)
    end
    -- saved accent colour is applied before anything is built
    if type(prefs.Accent) == "table" and #prefs.Accent == 3 then
        local ok, col = pcall(function() return Color3.fromRGB(prefs.Accent[1], prefs.Accent[2], prefs.Accent[3]) end)
        if ok then
            C.acc = col
            C.accT = col:Lerp(Color3.new(1, 1, 1), 0.28)
        end
    end

    local self = setmetatable({
        Prefs = prefs, Name = name, Flags = {}, Languages = opts.Languages or { "en" }, Translations = {},
        LanguageNames = opts.LanguageNames or {}, Tabs = {}, ToggleKey = opts.ToggleKey or Enum.KeyCode.RightShift,
        Folder = folder, SoundsUrl = opts.SoundsUrl, SoundsOn = opts.SoundsUrl ~= nil, SoundVolume = 0.5, _sounds = {}, Private = {}, _overlays = {}, _bound = {}, _setters = {}, _conns = {}, _cleanup = {}, _keybinds = {},
        _langControls = {}, _nav = {}, _order = 0, _lastSection = nil, _onLanguage = opts.OnLanguage, _onAccent = opts.OnAccent,
    }, Window)
    self.Language = opts.Language or self.Languages[1]
    if type(prefs.Language) == "string" and table.find(self.Languages, prefs.Language) then self.Language = prefs.Language end
    env.__CeruleaWindows[name] = self

    local gui = new("ScreenGui", { Name = name, ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = opts.DisplayOrder or 50 })
    if not pcall(function() gui.Parent = (gethui and gethui()) or game:GetService("CoreGui") end) then
        gui.Parent = player:WaitForChild("PlayerGui")
    end
    self.Gui = gui

    local win = frame(gui, {
        Size = UDim2.fromOffset(size.X, size.Y), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5),
        BackgroundColor3 = C.bg, ClipsDescendants = true,
    })
    corner(win, 14)
    stroke(win, 0.9)
    self.Frame = win
    local scale = new("UIScale", { Parent = win })
    local cam = workspace.CurrentCamera
    if cam then
        local vp = cam.ViewportSize
        scale.Scale = math.clamp(math.min(vp.X / (size.X + 52), vp.Y / (size.Y + 52)), 0.5, 1)
        local px, py = tonumber(prefs.PosX), tonumber(prefs.PosY)
        if px and py then
            local lx, ly = vp.X / scale.Scale / 2 - 120, vp.Y / scale.Scale / 2 - 60
            win.Position = UDim2.new(0.5, math.clamp(px, -lx, lx), 0.5, math.clamp(py, -ly, ly))
        end
    end
    self._scale = scale

    -- Top bar
    local top = frame(win, { Size = UDim2.new(1, 0, 0, topH), BackgroundTransparency = 1 })
    line(top, topH - 1)
    local logo = frame(top, { Size = UDim2.fromOffset(18, 18), Position = UDim2.fromOffset(14, 11), BackgroundTransparency = 1 })
    corner(logo, 9)
    new("UIStroke", { Color = C.accT, Thickness = 2, Parent = logo })
    local dot = frame(logo, { Size = UDim2.fromOffset(7, 7), Position = UDim2.fromOffset(5.5, 5.5), BackgroundColor3 = C.accT })
    corner(dot, 4)
    local left = frame(top, { Size = UDim2.fromOffset(0, topH), AutomaticSize = Enum.AutomaticSize.X, Position = UDim2.fromOffset(42, 0), BackgroundTransparency = 1 })
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = left })
    label(left, { Text = opts.Title or name, Font = F.Bold, TextSize = 13, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, topH), LayoutOrder = 1 })
    if opts.Subtitle then
        local st = label(left, { Font = F.Mono, TextSize = 10, TextColor3 = C.mono, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, topH), LayoutOrder = 2 })
        self:Bind(st, opts.Subtitle)
    end

    -- drag
    do
        local dragging, startPos, startMouse
        top.InputBegan:Connect(function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                dragging, startPos, startMouse = true, win.Position, i.Position
            end
        end)
        self:Connect(UserInputService.InputChanged, function(i)
            if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
                local d = (i.Position - startMouse) / scale.Scale
                win.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
            end
        end)
        self:Connect(UserInputService.InputEnded, function(i)
            if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
                if dragging then
                    self:SetPref("PosX", win.Position.X.Offset)
                    self:SetPref("PosY", win.Position.Y.Offset)
                end
                dragging = false
            end
        end)
    end

    -- right side of the top bar: status, language, minimize, close
    local right = frame(top, { Size = UDim2.fromOffset(0, topH), AutomaticSize = Enum.AutomaticSize.X, AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 0), BackgroundTransparency = 1 })
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = right })

    if opts.Status ~= false then
        local pill = frame(right, { Size = UDim2.fromOffset(0, 24), AutomaticSize = Enum.AutomaticSize.X, BackgroundColor3 = C.card, LayoutOrder = 1 })
        corner(pill, 7)
        stroke(pill, 0.93)
        pad(pill, 0, 0, 10, 10)
        new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 7), SortOrder = Enum.SortOrder.LayoutOrder, Parent = pill })
        local d = frame(pill, { Size = UDim2.fromOffset(6, 6), BackgroundColor3 = C.green, LayoutOrder = 1 })
        corner(d, 3)
        self._status = label(pill, {
            Text = opts.Status or 'Roblox <font color="#8b98ff">online</font>', RichText = true, Font = F.Mono, TextSize = 10,
            TextColor3 = Color3.fromRGB(201, 201, 212), AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 24), LayoutOrder = 2,
        })
    end

    if #self.Languages > 1 then
        local items = {}
        for _, code in ipairs(self.Languages) do table.insert(items, { text = code:upper(), code = code }) end
        local sw = segmented(self, right, items, 30, 24, 10, self.Language, function(code) self:SetLanguage(code) end)
        sw.Holder.LayoutOrder = 2
        table.insert(self._langControls, sw)
    end

    local function winBtn(txt, order, cb)
        local b = new("TextButton", { Text = txt, Font = F.Bold, TextSize = 16, TextColor3 = C.sub, BackgroundTransparency = 1, Size = UDim2.fromOffset(28, 28), AutoButtonColor = false, LayoutOrder = order, Parent = right })
        b.MouseEnter:Connect(function() tween(b, { TextColor3 = C.text }) end)
        b.MouseLeave:Connect(function() tween(b, { TextColor3 = C.sub }) end)
        b.MouseButton1Click:Connect(cb)
    end
    winBtn("–", 3, function() self:Hide() end)
    winBtn("×", 4, function() self:Hide() end)

    -- Sidebar and content
    local side = frame(win, { Size = UDim2.fromOffset(sideW, size.Y - topH), Position = UDim2.fromOffset(0, topH), BackgroundTransparency = 1 })
    frame(side, { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.new(1, -1, 0, 0), BackgroundColor3 = C.line, BackgroundTransparency = 0.94 })
    local navList = frame(side, { Size = UDim2.new(1, -16, 1, -40), Position = UDim2.fromOffset(8, 4), BackgroundTransparency = 1 })
    new("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = navList })
    self._side = navList
    self._footer = label(side, { Font = F.Mono, TextSize = 10, TextColor3 = C.mono, Position = UDim2.new(0, 18, 1, -26), Size = UDim2.new(1, -26, 0, 18) })

    self._content = frame(win, { Size = UDim2.new(1, -sideW, 1, -topH), Position = UDim2.fromOffset(sideW, topH), BackgroundTransparency = 1 })

    -- Toast area
    self._toasts = frame(gui, { Size = UDim2.new(0, 280, 1, -24), Position = UDim2.new(1, -296, 0, 12), BackgroundTransparency = 1 })
    new("UIListLayout", { VerticalAlignment = Enum.VerticalAlignment.Bottom, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = self._toasts })

    -- Keys: the window toggle key, keybind elements and "waiting for a key"
    self:Connect(UserInputService.InputBegan, function(input, processed)
        if self._listening then
            if input.UserInputType == Enum.UserInputType.Keyboard then
                local fn = self._listening
                self._listening = nil
                fn(input.KeyCode)
            end
            return
        end
        if processed then return end
        if input.KeyCode == self.ToggleKey then
            self:Toggle()
            return
        end
        for _, kb in ipairs(self._keybinds) do
            if kb.get() == input.KeyCode and kb.onPress then task.spawn(kb.onPress) end
        end
    end)
    return self
end

function Window:Show() self.Frame.Visible = true end
function Window:Hide() self.Frame.Visible = false end
function Window:Toggle() self.Frame.Visible = not self.Frame.Visible end
function Window:SetFooter(textOrKey) self:Bind(self._footer, textOrKey) end
function Window:SetStatus(richText) if self._status then self._status.Text = richText end end

function Window:Destroy()
    for _, f in ipairs(self._cleanup) do pcall(f) end
    for _, c in ipairs(self._conns) do pcall(function() c:Disconnect() end) end
    pcall(function() self.Gui:Destroy() end)
    local env = (getgenv and getgenv()) or _G
    if env.__CeruleaWindows and env.__CeruleaWindows[self.Name] == self then env.__CeruleaWindows[self.Name] = nil end
end

-- A second full-screen ScreenGui (for example a "low mode" screen). It is removed with the window.
function Window:CreateOverlay(name, order)
    local g = new("ScreenGui", { Name = name or "Overlay", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = order or 40, Enabled = false })
    if not pcall(function() g.Parent = (gethui and gethui()) or game:GetService("CoreGui") end) then
        g.Parent = player:WaitForChild("PlayerGui")
    end
    local root = frame(g, { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0) })
    table.insert(self._overlays, g)
    self:AddCleanup(function() g:Destroy() end)
    return g, root
end

--==================== Sounds ====================
-- opts.SoundsUrl = "https://.../sounds/" with <name>.ogg files. Files are downloaded once and played lazily.
local SOUND_VOLUME = { click = 0.8, hover = 0.35, tab = 0.7, on = 0.8, off = 0.7, success = 0.8, error = 0.8, notify = 0.7 }
function Window:PlaySound(name)
    if not self.SoundsOn or not self.SoundsUrl then return end
    local s = self._sounds[name]
    if s == false then return end
    if s == nil then
        self._sounds[name] = false
        task.spawn(function()
            local asset = resolveFile(self, self.SoundsUrl .. name .. ".ogg", "sounds")
            if not asset or not self.Gui.Parent then return end
            local snd = new("Sound", { SoundId = asset, Parent = self.Gui })
            self._sounds[name] = snd
            snd.Volume = (SOUND_VOLUME[name] or 0.7) * self.SoundVolume
            snd:Play()
        end)
        return
    end
    s.Volume = (SOUND_VOLUME[name] or 0.7) * self.SoundVolume
    s.TimePosition = 0
    s:Play()
end
function Window:SetSounds(on, volume)
    if on ~= nil then self.SoundsOn = on and true or false end
    if volume then self.SoundVolume = math.clamp(tonumber(volume) or 0.5, 0, 1) end
end

--==================== Notifications ====================
function Window:Notify(text, seconds, kind)
    local accent = (kind == "error") and C.red or (kind == "success") and C.green or C.accT
    self:PlaySound(kind == "error" and "error" or kind == "success" and "success" or "notify")
    local t = frame(self._toasts, { Size = UDim2.new(1, 0, 0, 38), BackgroundColor3 = C.card, BackgroundTransparency = 1, LayoutOrder = math.floor(os.clock() * 1000) })
    corner(t, 9)
    local st = stroke(t, 1)
    local bar = frame(t, { Size = UDim2.fromOffset(3, 18), Position = UDim2.fromOffset(10, 10), BackgroundColor3 = accent, BackgroundTransparency = 1 })
    corner(bar, 2)
    local l = label(t, { Text = self:T(text), TextTransparency = 1, Font = F.Sans, TextSize = 12, Position = UDim2.fromOffset(22, 0), Size = UDim2.new(1, -30, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
    tween(t, { BackgroundTransparency = 0 }, 0.2)
    tween(st, { Transparency = 0.9 }, 0.2)
    tween(bar, { BackgroundTransparency = 0 }, 0.2)
    tween(l, { TextTransparency = 0 }, 0.2)
    task.delay(seconds or 3, function()
        if not t.Parent then return end
        tween(t, { BackgroundTransparency = 1 }, 0.25)
        tween(st, { Transparency = 1 }, 0.25)
        tween(bar, { BackgroundTransparency = 1 }, 0.25)
        tween(l, { TextTransparency = 1 }, 0.25)
        task.wait(0.3)
        t:Destroy()
    end)
end

--==================== Preferences (language, position, accent, last config) ====================
local function hasFiles() return writefile and readfile and isfile end
local function ensureFolder(folder)
    pcall(function() if makefolder and not (isfolder and isfolder(folder)) then makefolder(folder) end end)
end
function Window:GetPref(key, default)
    local v = self.Prefs[key]
    if v == nil then return default end
    return v
end
function Window:SetPref(key, value)
    self.Prefs[key] = value
    if not hasFiles() or self._prefSaving then return end
    self._prefSaving = true
    task.delay(0.6, function()
        self._prefSaving = false
        ensureFolder(self.Folder)
        pcall(function() writefile(self.Folder .. "/_prefs.json", HttpService:JSONEncode(self.Prefs)) end)
    end)
end

-- Recolour the whole interface (and overlays) with a new accent colour.
function Window:SetAccent(color)
    local oldA, oldT = C.acc, C.accT
    local newA = color
    local newT = color:Lerp(Color3.new(1, 1, 1), 0.28)
    C.acc, C.accT = newA, newT
    local function same(a, b) return a == b end
    local function fix(o)
        pcall(function()
            if o:IsA("GuiObject") then
                if same(o.BackgroundColor3, oldA) then o.BackgroundColor3 = newA elseif same(o.BackgroundColor3, oldT) then o.BackgroundColor3 = newT end
            end
            if o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox") then
                if same(o.TextColor3, oldA) then o.TextColor3 = newA elseif same(o.TextColor3, oldT) then o.TextColor3 = newT end
            end
            if o:IsA("ImageLabel") or o:IsA("ImageButton") then
                if same(o.ImageColor3, oldA) then o.ImageColor3 = newA elseif same(o.ImageColor3, oldT) then o.ImageColor3 = newT end
            end
            if o:IsA("UIStroke") then
                if same(o.Color, oldA) then o.Color = newA elseif same(o.Color, oldT) then o.Color = newT end
            end
            if o:IsA("ScrollingFrame") then
                if same(o.ScrollBarImageColor3, oldA) then o.ScrollBarImageColor3 = newA elseif same(o.ScrollBarImageColor3, oldT) then o.ScrollBarImageColor3 = newT end
            end
        end)
    end
    local roots = { self.Gui }
    for _, g in ipairs(self._overlays) do table.insert(roots, g) end
    for _, r in ipairs(roots) do
        fix(r)
        for _, d in ipairs(r:GetDescendants()) do fix(d) end
    end
    self:SetPref("Accent", { math.floor(newA.R * 255 + 0.5), math.floor(newA.G * 255 + 0.5), math.floor(newA.B * 255 + 0.5) })
    if self._onAccent then task.spawn(self._onAccent, newA, newT) end
end

--==================== Config files ====================
-- win.Private = { FlagName = true } keeps secrets (webhook URLs, keys) out of shared config strings
function Window:ExportFlags(forShare)
    local data = {}
    for k, v in pairs(self.Flags) do
        if forShare and self.Private[k] then continue end
        local tv = typeof(v)
        if tv == "EnumItem" then data[k] = v.Name
        elseif tv == "boolean" or tv == "number" or tv == "string" then data[k] = v end
    end
    return HttpService:JSONEncode(data)
end
function Window:ImportFlags(json)
    local ok, data = pcall(function() return HttpService:JSONDecode(json) end)
    if not ok or type(data) ~= "table" then return false end
    for k, v in pairs(data) do
        local setter = self._setters[k]
        if setter then pcall(setter, v) end
    end
    return true
end
function Window:_path(name) return self.Folder .. "/" .. UI.SanitizeName(name) .. ".json" end
function Window:SaveConfig(name)
    if not hasFiles() then return false, "executor has no file functions" end
    name = UI.SanitizeName(name)
    if name == "" then return false, "empty name" end
    ensureFolder(self.Folder)
    local ok, err = pcall(writefile, self:_path(name), self:ExportFlags())
    if ok then self:SetPref("LastConfig", name) end
    return ok, err
end
function Window:LoadConfig(name)
    if not hasFiles() then return false, "executor has no file functions" end
    name = UI.SanitizeName(name)
    local path = self:_path(name)
    if not isfile(path) then return false, "no such config" end
    local ok, content = pcall(readfile, path)
    if not ok then return false, content end
    local done = self:ImportFlags(content)
    if done then self:SetPref("LastConfig", name) end
    return done
end
function Window:DeleteConfig(name)
    if not (delfile and isfile) then return false, "executor has no delfile" end
    name = UI.SanitizeName(name)
    local path = self:_path(name)
    if not isfile(path) then return false, "no such config" end
    local ok, err = pcall(delfile, path)
    if ok and self.Prefs.LastConfig == name then self:SetPref("LastConfig", nil) end
    return ok, err
end
function Window:RenameConfig(old, new)
    if not hasFiles() or not delfile then return false, "executor has no file functions" end
    old, new = UI.SanitizeName(old), UI.SanitizeName(new)
    if new == "" then return false, "empty name" end
    if old == new then return true end
    if not isfile(self:_path(old)) then return false, "no such config" end
    if isfile(self:_path(new)) then return false, "name already used" end
    local ok, content = pcall(readfile, self:_path(old))
    if not ok then return false, content end
    local ok2, err = pcall(writefile, self:_path(new), content)
    if not ok2 then return false, err end
    pcall(delfile, self:_path(old))
    if self.Prefs.LastConfig == old then self:SetPref("LastConfig", new) end
    return true
end
function Window:ListConfigs()
    local names = {}
    if listfiles and isfolder and isfolder(self.Folder) then
        local ok, files = pcall(listfiles, self.Folder)
        if ok then
            for _, f in ipairs(files) do
                local n = tostring(f):match("([^/\\]+)%.json$")
                if n and n:sub(1, 1) ~= "_" then table.insert(names, n) end
            end
        end
    end
    table.sort(names)
    return names
end
-- Share a config as one line of text: "CRL1:<base64 of json>"
function Window:ExportString()
    return "CRL1:" .. b64enc(self:ExportFlags(true))
end
function Window:ImportString(str)
    str = tostring(str or ""):gsub("^%s+", ""):gsub("%s+$", "")
    local json
    if str:sub(1, 1) == "{" then
        json = str
    else
        json = b64dec((str:gsub("^CRL1:", "")))
    end
    if not json or json == "" then return false, "bad string" end
    if not self:ImportFlags(json) then return false, "bad string" end
    return true
end
-- Which config to load on start: env.CeruleaConfig (set by the user script) or the last used one.
function Window:AutoLoadConfig(override)
    local name = override
    if not name and self:GetPref("AutoLoad", true) then name = self.Prefs.LastConfig end
    if name and name ~= "" and self:LoadConfig(name) then return name end
    return nil
end

--==================== Tabs ====================
function Window:_next()
    self._order += 1
    return self._order
end

function Window:SelectTab(id)
    for k, tab in pairs(self.Tabs) do tab.Page.Visible = (k == id) end
    for k, n in pairs(self._nav) do
        local on = (k == id)
        tween(n.bg, { BackgroundTransparency = on and 0.93 or 1 })
        n.icon:Paint(on and C.text or C.sub)
        tween(n.txt, { TextColor3 = on and C.text or C.nav })
    end
end

-- o: id, title, icon, section, subtitle, heading = { a = key, b = key | name, literal = true }
function Window:AddTab(o)
    local id = o.id or tostring(#self.Tabs + 1)

    if o.section and o.section ~= self._lastSection then
        self._lastSection = o.section
        local holder = frame(self._side, { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = self:_next() })
        local l = label(holder, { Font = F.Mono, TextSize = 10, TextColor3 = C.mono, Position = UDim2.fromOffset(10, 14), Size = UDim2.new(1, -10, 0, 14) })
        self:Bind(l, o.section)
    end

    local item = frame(self._side, { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = C.line, BackgroundTransparency = 1, LayoutOrder = self:_next() })
    corner(item, 8)
    local ic = makeIcon(self, item, o.icon, o.glyph, Vector2.new(22, 32), UDim2.fromOffset(6, 0), C.sub)
    local txt = label(item, { Font = F.Sans, TextSize = 13, TextColor3 = C.nav, Position = UDim2.fromOffset(34, 0), Size = UDim2.new(1, -40, 1, 0) })
    self:Bind(txt, o.title or id)
    local btn = new("TextButton", { Text = "", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = item })
    btn.MouseButton1Click:Connect(function() self:PlaySound("tab") self:SelectTab(id) end)
    self._nav[id] = { bg = item, icon = ic, txt = txt }

    local page = new("ScrollingFrame", {
        Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 3, ScrollBarImageColor3 = C.mono,
        CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = self._content,
    })
    pad(page, 18, 18, 20, 20)
    new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })

    if o.heading then
        local h = frame(page, { Size = UDim2.new(1, 0, 0, 52), BackgroundTransparency = 1, LayoutOrder = 0 })
        local row = frame(h, { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1 })
        new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
        local a = label(row, { Font = F.Bold, TextSize = 26, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 36), LayoutOrder = 1 })
        self:Bind(a, o.heading.a)
        local b = label(row, { TextSize = 30, TextColor3 = C.accT, AutomaticSize = Enum.AutomaticSize.X, Size = UDim2.fromOffset(0, 36), LayoutOrder = 2 })
        trySerif(b)
        if o.heading.literal then b.Text = tostring(o.heading.b) else self:Bind(b, o.heading.b) end
        if o.subtitle then
            local s = label(h, { Font = F.Mono, TextSize = 10, TextColor3 = C.mono, Position = UDim2.fromOffset(0, 38), Size = UDim2.new(1, 0, 0, 14) })
            self:Bind(s, o.subtitle)
        end
    end

    local tab = setmetatable({ Win = self, Page = page, Id = id, _n = 1 }, Tab)
    self.Tabs[id] = tab
    if o.default or not self._selected then
        self._selected = true
        self:SelectTab(id)
    end
    return tab
end

function Tab:_next()
    self._n += 1
    return self._n
end

--==================== Cards ====================
local function buildCard(win, parent, o, size, order)
    local card = frame(parent, { Size = size, AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.card, LayoutOrder = order })
    corner(card, 12)
    stroke(card, 0.93)
    pad(card, 12, 12, 14, 14)
    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })
    local obj = setmetatable({ Win = win, Frame = card, _n = 0 }, Card)

    if o.title or o.index then
        local h = frame(card, { Size = UDim2.new(1, 0, 0, 18), BackgroundTransparency = 1, LayoutOrder = obj:_next() })
        if o.title then
            local t = label(h, { Font = F.Bold, TextSize = 13, Size = UDim2.new(1, -50, 1, 0) })
            win:Bind(t, o.title)
        end
        if o.index then
            label(h, { Text = o.index, Font = F.Mono, TextSize = 11, TextColor3 = C.mono, TextXAlignment = Enum.TextXAlignment.Right, Size = UDim2.fromScale(1, 1) })
        end
    end
    if o.sub then
        local s = label(card, { Font = F.Sans, TextSize = 11, TextColor3 = C.sub, Size = UDim2.new(1, 0, 0, 14), LayoutOrder = obj:_next() })
        win:Bind(s, o.sub)
    end
    if o.title or o.sub then
        frame(card, { Size = UDim2.new(1, 0, 0, 8), BackgroundTransparency = 1, LayoutOrder = obj:_next() })
    end
    return obj
end

local function columns(win, tab, widths)
    local row = frame(tab.Page, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, LayoutOrder = tab:_next() })
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Top, Parent = row })
    local count = #widths
    local i = 0
    return row, function()
        i += 1
        local w = widths[i]
        return UDim2.new(w, -math.ceil(10 * (count - 1) * w), 0, 0), i
    end
end

local function parseWidths(n)
    if type(n) == "table" then return n end
    local t = {}
    for i = 1, n do t[i] = 1 / n end
    return t
end

function Tab:AddCard(o)
    return buildCard(self.Win, self.Page, o or {}, UDim2.new(1, 0, 0, 0), self:_next())
end

-- tab:AddColumns(2) or tab:AddColumns({ 0.6, 0.4 }) -> object with :AddCard(o)
function Tab:AddColumns(n)
    local win, tab = self.Win, self
    local row, nextSize = columns(win, tab, parseWidths(n))
    local cols = {}
    function cols:AddCard(o)
        local size, i = nextSize()
        return buildCard(win, row, o or {}, size, i)
    end
    return cols
end

function Card:_next()
    self._n += 1
    return self._n
end

function Card:_row(textKey, h)
    local r = frame(self.Frame, { Size = UDim2.new(1, 0, 0, h or 32), BackgroundTransparency = 1, LayoutOrder = self:_next() })
    line(r, 0)
    if textKey then
        local l = label(r, { Font = F.Sans, TextSize = 12, TextColor3 = C.body, Size = UDim2.new(0.55, 0, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
        self.Win:Bind(l, textKey)
    end
    return r
end

function Card:AddLabel(o)
    if type(o) == "string" then o = { text = o } end
    local l = label(self.Frame, { Font = F.Sans, TextSize = o.size or 12, TextColor3 = o.color or C.sub, Size = UDim2.new(1, 0, 0, o.height or 20), TextWrapped = true, LayoutOrder = self:_next() })
    self.Win:Bind(l, o.text)
    return l
end

-- o: text, primary, callback
function Card:AddButton(o)
    local wrap = frame(self.Frame, { Size = UDim2.new(1, 0, 0, 40), BackgroundTransparency = 1, LayoutOrder = self:_next() })
    return UI._button(self.Win, wrap, o, UDim2.new(1, 0, 0, 32), UDim2.new())
end

function UI._button(win, parent, o, size, pos)
    local b = new("TextButton", {
        Position = pos, Size = size, AutoButtonColor = false, Font = F.Bold, TextSize = 12, BorderSizePixel = 0,
        BackgroundColor3 = o.primary and C.acc or C.button, TextColor3 = o.primary and Color3.new(1, 1, 1) or Color3.fromRGB(228, 228, 236), Parent = parent,
    })
    corner(b, 8)
    if not o.primary then stroke(b, 0.91) end
    win:Bind(b, o.text)
    local base = b.BackgroundColor3
    b.MouseEnter:Connect(function() tween(b, { BackgroundColor3 = o.primary and C.accT or C.buttonHover }) win:PlaySound("hover") end)
    b.MouseLeave:Connect(function() tween(b, { BackgroundColor3 = base }) end)
    b.MouseButton1Click:Connect(function() win:PlaySound("click") if o.callback then task.spawn(o.callback) end end)
    return b
end

-- o: text, default, flag, callback(value)
function Card:AddToggle(o)
    local win = self.Win
    local r = self:_row(o.text)
    local state = o.default and true or false
    local track = new("TextButton", { Text = "", AutoButtonColor = false, BorderSizePixel = 0, Size = UDim2.fromOffset(34, 18), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Parent = r })
    corner(track, 9)
    local knob = frame(track, { Size = UDim2.fromOffset(14, 14), BackgroundColor3 = Color3.new(1, 1, 1) })
    corner(knob, 7)
    local function paint(animate)
        local g1 = { BackgroundColor3 = state and C.acc or C.off }
        local g2 = { Position = state and UDim2.fromOffset(18, 2) or UDim2.fromOffset(2, 2) }
        if animate then
            tween(track, g1)
            tween(knob, g2)
        else
            track.BackgroundColor3 = g1.BackgroundColor3
            knob.Position = g2.Position
        end
    end
    local obj = {}
    function obj:Set(v, silent)
        state = v and true or false
        paint(true)
        if o.flag then win.Flags[o.flag] = state end
        if not silent and o.callback then task.spawn(o.callback, state) end
    end
    function obj:Get() return state end
    paint(false)
    win:_flag(o.flag, state, function(v) obj:Set(v) end)
    track.MouseButton1Click:Connect(function() obj:Set(not state) win:PlaySound(state and "on" or "off") end)
    return obj
end

-- o: text, default, numeric, min, max, readonly, width, placeholder, flag, callback(value)
function Card:AddField(o)
    local win = self.Win
    local r = self:_row(o.text)
    local value = o.numeric and (tonumber(o.default) or 0) or tostring(o.default == nil and "" or o.default)
    local box = new("TextBox", {
        Text = tostring(value), Font = F.Mono, TextSize = 11, TextColor3 = Color3.fromRGB(201, 201, 212), BackgroundColor3 = C.field, BorderSizePixel = 0,
        ClearTextOnFocus = false, TextTruncate = Enum.TextTruncate.AtEnd, TextEditable = not o.readonly, PlaceholderText = o.placeholder or "", PlaceholderColor3 = C.mono,
        Size = UDim2.fromOffset(o.width or 140, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Parent = r,
    })
    corner(box, 7)
    stroke(box, 0.92)
    pad(box, 0, 0, 10, 10)
    local obj = {}
    function obj:Set(v, silent)
        if o.numeric then
            v = tonumber(v)
            if v == nil then box.Text = tostring(value) return end
            if o.min then v = math.max(o.min, v) end
            if o.max then v = math.min(o.max, v) end
        else
            v = tostring(v)
        end
        value = v
        box.Text = tostring(value)
        if o.flag then win.Flags[o.flag] = value end
        if not silent and o.callback then task.spawn(o.callback, value) end
    end
    function obj:Get() return value end
    win:_flag(o.flag, value, function(v) obj:Set(v) end)
    if not o.readonly then box.FocusLost:Connect(function() obj:Set(box.Text) end) end
    return obj
end

-- o: text, items, default, width (button width), flag, callback(code)
function Card:AddSegmented(o)
    local win = self.Win
    local r = self:_row(o.text)
    local first = o.items[1]
    local default = o.default or (type(first) == "string" and first or first.code)
    local obj
    obj = segmented(win, r, o.items, o.width or 52, 26, 11, default, function(code)
        if o.flag then win.Flags[o.flag] = code end
        if o.callback then task.spawn(o.callback, code) end
    end)
    obj.Holder.AnchorPoint = Vector2.new(1, 0.5)
    obj.Holder.Position = UDim2.new(1, 0, 0.5, 0)
    win:_flag(o.flag, default, function(v) obj:Set(v) end)
    return obj
end

-- Language row: shows every language from UI.new({ Languages = ... })
function Card:AddLanguage(o)
    local win = self.Win
    o = o or {}
    local items = {}
    for _, code in ipairs(win.Languages) do
        table.insert(items, { text = win.LanguageNames[code] or code:upper(), code = code })
    end
    local r = self:_row(o.text or "Language")
    local obj = segmented(win, r, items, o.width or 62, 26, 11, win.Language, function(code) win:SetLanguage(code) end)
    obj.Holder.AnchorPoint = Vector2.new(1, 0.5)
    obj.Holder.Position = UDim2.new(1, 0, 0.5, 0)
    table.insert(win._langControls, obj)
    win:_flag("Language", win.Language, function(v) win:SetLanguage(v) end)
    return obj
end

-- o: text, min, max, default, step, flag, callback(value)
function Card:AddSlider(o)
    local win = self.Win
    local r = self:_row(o.text)
    local min, max, step = o.min or 0, o.max or 100, o.step or 1
    local value = o.default or min
    local valueLbl = label(r, { Font = F.Mono, TextSize = 11, TextColor3 = C.mono, TextXAlignment = Enum.TextXAlignment.Right, AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -126, 0.5, 0), Size = UDim2.fromOffset(46, 20) })
    local hit = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundTransparency = 1, Size = UDim2.fromOffset(116, 22), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Parent = r })
    local trackBar = frame(hit, { Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0.5, -2), BackgroundColor3 = C.off })
    corner(trackBar, 2)
    local fill = frame(trackBar, { Size = UDim2.fromScale(0, 1), BackgroundColor3 = C.acc })
    corner(fill, 2)
    local knob = frame(trackBar, { Size = UDim2.fromOffset(12, 12), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = Color3.new(1, 1, 1) })
    corner(knob, 6)

    local obj = {}
    local function paint()
        local p = (max == min) and 0 or math.clamp((value - min) / (max - min), 0, 1)
        fill.Size = UDim2.fromScale(p, 1)
        knob.Position = UDim2.fromScale(p, 0.5)
        valueLbl.Text = tostring(value)
    end
    function obj:Set(v, silent)
        v = tonumber(v)
        if not v then return end
        v = math.clamp(math.floor(v / step + 0.5) * step, min, max)
        value = tonumber(string.format("%.4f", v))
        paint()
        if o.flag then win.Flags[o.flag] = value end
        if not silent and o.callback then task.spawn(o.callback, value) end
    end
    function obj:Get() return value end
    paint()
    win:_flag(o.flag, value, function(v) obj:Set(v) end)

    local dragging = false
    local function fromX(x)
        local rel = math.clamp((x - trackBar.AbsolutePosition.X) / math.max(trackBar.AbsoluteSize.X, 1), 0, 1)
        obj:Set(min + rel * (max - min))
    end
    hit.InputBegan:Connect(function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            fromX(i.Position.X)
        end
    end)
    win:Connect(UserInputService.InputChanged, function(i)
        if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then fromX(i.Position.X) end
    end)
    win:Connect(UserInputService.InputEnded, function(i)
        if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
    return obj
end

-- o: text, default (Enum.KeyCode), flag, callback(key) on change, onPress() when the key is pressed, windowToggle = true
function Card:AddKeybind(o)
    local win = self.Win
    local r = self:_row(o.text)
    local key = o.default or Enum.KeyCode.Unknown
    local btn = new("TextButton", {
        Text = key.Name, Font = F.Mono, TextSize = 11, TextColor3 = Color3.fromRGB(201, 201, 212), BackgroundColor3 = C.field, BorderSizePixel = 0, AutoButtonColor = false,
        Size = UDim2.fromOffset(o.width or 90, 26), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, 0, 0.5, 0), Parent = r,
    })
    corner(btn, 7)
    stroke(btn, 0.92)
    local obj = {}
    function obj:Set(k, silent)
        if type(k) == "string" then k = Enum.KeyCode[k] end
        if typeof(k) ~= "EnumItem" then return end
        key = k
        btn.Text = key.Name
        if o.flag then win.Flags[o.flag] = key end
        if o.windowToggle then win.ToggleKey = key end
        if not silent and o.callback then task.spawn(o.callback, key) end
    end
    function obj:Get() return key end
    table.insert(win._keybinds, { get = function() return key end, onPress = o.onPress })
    win:_flag(o.flag, key, function(v) obj:Set(v) end)
    if o.windowToggle then win.ToggleKey = key end
    btn.MouseButton1Click:Connect(function()
        btn.Text = "..."
        win._listening = function(k)
            if k == Enum.KeyCode.Escape then btn.Text = key.Name else obj:Set(k) end
        end
    end)
    return obj
end

-- o: text, colors = { Color3, ... }, default (index), flag, callback(index, color)
function Card:AddSwatches(o)
    local win = self.Win
    local r = self:_row(o.text)
    local value = o.default or 1
    local marks = {}
    local obj = {}
    local function paint()
        for i, m in ipairs(marks) do m.Transparency = (i == value) and 0 or 1 end
    end
    for i, col in ipairs(o.colors) do
        local b = new("TextButton", {
            Text = "", AutoButtonColor = false, BorderSizePixel = 0, BackgroundColor3 = col, Size = UDim2.fromOffset(16, 16),
            AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(#o.colors - i) * 23, 0.5, 0), Parent = r,
        })
        corner(b, 8)
        marks[i] = new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 2, Parent = b })
        b.MouseButton1Click:Connect(function() obj:Set(i) end)
    end
    function obj:Set(i, silent)
        i = tonumber(i)
        if not i or not o.colors[i] then return end
        value = i
        paint()
        if o.flag then win.Flags[o.flag] = value end
        if not silent and o.callback then task.spawn(o.callback, value, o.colors[value]) end
    end
    function obj:Get() return value end
    paint()
    win:_flag(o.flag, value, function(v) obj:Set(v) end)
    return obj
end

-- Bar chart: obj:SetData({ 1, 4, 2, ... })
function Card:AddChart(o)
    o = o or {}
    local h = o.height or 108
    local plot = frame(self.Frame, { Size = UDim2.new(1, 0, 0, h), BackgroundTransparency = 1, ClipsDescendants = true, LayoutOrder = self:_next() })
    for i = 1, 3 do
        frame(plot, { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, i / 4, 0), BackgroundColor3 = C.line, BackgroundTransparency = 0.94 })
    end
    local bars = frame(plot, { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1 })
    local obj = {}
    local pool, lastSig = {}, nil
    function obj:SetData(values)
        local n = #values
        if n < 1 then bars:ClearAllChildren() pool, lastSig = {}, nil return end
        local sig = table.concat(values, ",")
        if sig == lastSig then return end -- nothing changed: do not restart the animation
        lastSig = sig
        local maxV = 1
        for _, v in ipairs(values) do maxV = math.max(maxV, v) end
        if #pool ~= n then -- the number of bars changed: build them once
            bars:ClearAllChildren()
            pool = {}
            for i = 1, n do
                local bar = frame(bars, {
                    AnchorPoint = Vector2.new(0, 1), Position = UDim2.new((i - 1) / n, 0, 1, 0), Size = UDim2.new(1 / n, -4, 0, 0),
                })
                corner(bar, 3)
                new("UIGradient", { Rotation = 90, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 0.7) }), Parent = bar })
                pool[i] = bar
            end
        end
        for i, v in ipairs(values) do
            local last = (i == n)
            local ht = math.max(3 / h, (v / maxV) * (1 - 8 / h))
            local bar = pool[i]
            bar.BackgroundColor3 = last and C.accT or C.acc
            bar.BackgroundTransparency = last and 0 or 0.3
            tween(bar, { Size = UDim2.new(1 / n, -4, ht, 0) }, 0.35)
        end
    end
    if o.data then obj:SetData(o.data) end
    return obj
end

--==================== Tab-level elements ====================
-- tab:AddButtonRow({ { text = "save", primary = true, callback = f, width = 140 }, ... })
function Tab:AddButtonRow(list)
    local row = frame(self.Page, { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, LayoutOrder = self:_next() })
    new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = row })
    local out = {}
    for i, b in ipairs(list) do
        local btn = UI._button(self.Win, row, b, UDim2.fromOffset(b.width or 120, 32), UDim2.new())
        btn.LayoutOrder = i
        out[i] = btn
    end
    return out
end

-- tab:AddStats({ { icon = "◎", title = key, value = "0", sub = key, index = "01" }, ... }) -> list of { SetValue }
function Tab:AddStats(list)
    local win = self.Win
    local row, nextSize = columns(win, self, parseWidths(#list))
    local out = {}
    for _, s in ipairs(list) do
        local size, i = nextSize()
        local c = frame(row, { Size = UDim2.new(size.X.Scale, size.X.Offset, 0, 108), BackgroundColor3 = C.card, LayoutOrder = i })
        corner(c, 12)
        stroke(c, 0.93)
        if s.index then label(c, { Text = s.index, Font = F.Mono, TextSize = 11, TextColor3 = C.mono, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(1, -54, 0, 10), Size = UDim2.fromOffset(40, 16) }) end
        local ibox = frame(c, { Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(12, 12), BackgroundColor3 = C.field })
        corner(ibox, 9)
        stroke(ibox, 0.92)
        makeIcon(win, ibox, s.icon, s.glyph, Vector2.new(34, 34), UDim2.new(), C.nav)
        local t = label(c, { Font = F.Bold, TextSize = 13, Position = UDim2.fromOffset(56, 12), Size = UDim2.new(1, -110, 0, 34), TextTruncate = Enum.TextTruncate.AtEnd })
        win:Bind(t, s.title)
        local v = label(c, { Text = tostring(s.value or 0), Font = F.Bold, TextSize = 28, Position = UDim2.fromOffset(14, 54), Size = UDim2.new(1, -28, 0, 34) })
        local sub = label(c, { Font = F.Mono, TextSize = 10, TextColor3 = C.mono, Position = UDim2.fromOffset(14, 88), Size = UDim2.new(1, -28, 0, 16), TextTruncate = Enum.TextTruncate.AtEnd })
        if s.sub then win:Bind(sub, s.sub) end
        local obj = {}
        function obj:SetValue(x) v.Text = tostring(x) end
        function obj:SetSub(keyOrFn) win:Bind(sub, keyOrFn) end
        table.insert(out, obj)
    end
    return out
end

-- Table. cells: string | number | { key = k } | { fn = function } | { pill = key }
-- tab:AddTable({ columns = { "name", "date" }, widths = { 1, 1 }, index = "01", rows = { { "a", "b" } } })
local function pillCell(win, parent, key)
    local p = frame(parent, { Size = UDim2.fromOffset(72, 20), Position = UDim2.new(0, 0, 0.5, -10), BackgroundColor3 = C.acc, BackgroundTransparency = 0.84 })
    corner(p, 6)
    local d = frame(p, { Size = UDim2.fromOffset(5, 5), Position = UDim2.fromOffset(8, 7.5), BackgroundColor3 = C.accT })
    corner(d, 3)
    local t = label(p, { Font = F.Mono, TextSize = 10, TextColor3 = C.accT, Position = UDim2.fromOffset(20, 0), Size = UDim2.new(1, -20, 1, 0) })
    win:Bind(t, key)
end

function Tab:AddTable(o)
    local win = self.Win
    local box = frame(self.Page, { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.card, ClipsDescendants = true, LayoutOrder = self:_next() })
    corner(box, 12)
    stroke(box, 0.93)
    new("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Parent = box })

    local widths = o.widths or {}
    local total = 0
    for i = 1, #o.columns do widths[i] = widths[i] or 1 total += widths[i] end
    local xs, acc = {}, 0
    for i, w in ipairs(widths) do
        xs[i] = acc / total
        acc += w
    end
    local function cellProps(i)
        return { Position = UDim2.new(xs[i], i == 1 and 14 or 4, 0, 0), Size = UDim2.new(widths[i] / total, -8, 1, 0) }
    end

    local head = frame(box, { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.head, LayoutOrder = 1 })
    line(head, 29)
    for i, key in ipairs(o.columns) do
        local g = cellProps(i)
        local l = label(head, { Font = F.Mono, TextSize = 10, TextColor3 = C.mono, Position = g.Position, Size = g.Size, TextTruncate = Enum.TextTruncate.AtEnd })
        win:Bind(l, key)
    end
    if o.index then label(head, { Text = o.index, Font = F.Mono, TextSize = 11, TextColor3 = C.mono, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(1, -54, 0, 7), Size = UDim2.fromOffset(40, 16) }) end

    local obj, n = {}, 1
    function obj:AddRow(cells, onClick)
        n += 1
        local r = frame(box, { Size = UDim2.new(1, 0, 0, 36), BackgroundTransparency = 1, LayoutOrder = n })
        if onClick then
            local hit = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = C.acc, BackgroundTransparency = 1, BorderSizePixel = 0, Size = UDim2.fromScale(1, 1), ZIndex = 2, Parent = r })
            hit.MouseEnter:Connect(function() tween(hit, { BackgroundTransparency = 0.93 }) end)
            hit.MouseLeave:Connect(function() tween(hit, { BackgroundTransparency = 1 }) end)
            hit.MouseButton1Click:Connect(function() task.spawn(onClick) end)
        end
        if n > 2 then line(r, 0) end
        for i, v in ipairs(cells) do
            local g = cellProps(i)
            if type(v) == "table" and v.pill then
                local holder = frame(r, { Position = g.Position, Size = g.Size, BackgroundTransparency = 1 })
                pillCell(win, holder, v.pill)
            else
                local l = label(r, { Font = F.Sans, TextSize = 12, TextColor3 = Color3.fromRGB(216, 216, 226), Position = g.Position, Size = g.Size, TextTruncate = Enum.TextTruncate.AtEnd })
                if type(v) == "table" and v.key then win:Bind(l, v.key)
                elseif type(v) == "table" and v.fn then win:Bind(l, v.fn)
                else l.Text = tostring(v) end
            end
        end
    end
    function obj:Clear()
        for _, c in ipairs(box:GetChildren()) do
            if c:IsA("Frame") and c.LayoutOrder > 1 then c:Destroy() end
        end
        n = 1
    end
    for _, cells in ipairs(o.rows or {}) do obj:AddRow(cells) end
    return obj
end

-- Scrollable list with a checkbox, a name, an info text and a numeric limit per item
-- tab:AddItemList({ items, headers = { on, item, have }, height, enabled(item), setEnabled(item, v), name(item),
--                   info(item), value(item), setValue(item, n) }) -> { Refresh() }
function Tab:AddItemList(o)
    local win = self.Win
    local rowH = o.rowHeight or 32
    local box = frame(self.Page, { Size = UDim2.new(1, 0, 0, o.height or 262), BackgroundColor3 = C.card, ClipsDescendants = true, LayoutOrder = self:_next() })
    corner(box, 12)
    stroke(box, 0.93)
    local head = frame(box, { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = C.head })
    line(head, 29)
    local hd = o.headers or {}
    local function headLabel(key, pos, size, align)
        if not key then return end
        local l = label(head, { Font = F.Mono, TextSize = 10, TextColor3 = C.mono, Position = pos, Size = size, TextXAlignment = align or Enum.TextXAlignment.Left })
        win:Bind(l, key)
    end
    headLabel(hd.on, UDim2.fromOffset(14, 0), UDim2.fromOffset(40, 30))
    headLabel(hd.item, UDim2.fromOffset(44, 0), UDim2.fromOffset(160, 30))
    headLabel(hd.have, UDim2.new(1, -190, 0, 0), UDim2.fromOffset(176, 30), Enum.TextXAlignment.Right)

    local scroll = new("ScrollingFrame", {
        Position = UDim2.fromOffset(0, 30), Size = UDim2.new(1, 0, 1, -30), BackgroundTransparency = 1, BorderSizePixel = 0,
        ScrollBarThickness = 3, ScrollBarImageColor3 = C.mono, CanvasSize = UDim2.fromOffset(0, #o.items * rowH), Parent = box,
    })
    local infos, paints, boxes = {}, {}, {}
    for i, item in ipairs(o.items) do
        local r = frame(scroll, { Size = UDim2.new(1, 0, 0, rowH), Position = UDim2.fromOffset(0, (i - 1) * rowH), BackgroundTransparency = 1 })
        if i > 1 then line(r, 0) end

        local cb = new("TextButton", { Text = "", AutoButtonColor = false, BorderSizePixel = 0, Size = UDim2.fromOffset(16, 16), Position = UDim2.fromOffset(14, (rowH - 16) / 2), Parent = r })
        corner(cb, 5)
        stroke(cb, 0.85)
        local tick = frame(cb, { Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(5, 5), BackgroundColor3 = Color3.new(1, 1, 1) })
        corner(tick, 3)
        local function paint()
            local on = o.enabled(item)
            cb.BackgroundColor3 = on and C.acc or C.field
            tick.Visible = on
        end
        paint()
        paints[item] = paint
        cb.MouseButton1Click:Connect(function()
            o.setEnabled(item, not o.enabled(item))
            paint()
        end)

        local nameLbl = label(r, { Font = F.Sans, TextSize = 12, TextColor3 = Color3.fromRGB(216, 216, 226), Position = UDim2.fromOffset(44, 0), Size = UDim2.new(1, -190, 1, 0), TextTruncate = Enum.TextTruncate.AtEnd })
        win:Bind(nameLbl, function() return o.name(item) end)

        if o.info then
            local info = label(r, { Font = F.Mono, TextSize = 11, TextColor3 = C.mono, TextXAlignment = Enum.TextXAlignment.Right, Position = UDim2.new(1, -128, 0, 0), Size = UDim2.fromOffset(52, rowH) })
            infos[item] = info
            info.Text = tostring(o.info(item))
        end
        if o.value then
            local boxF = new("TextBox", {
                Text = tostring(o.value(item)), Font = F.Mono, TextSize = 11, TextColor3 = Color3.fromRGB(201, 201, 212), BackgroundColor3 = C.field, BorderSizePixel = 0,
                ClearTextOnFocus = false, Size = UDim2.fromOffset(52, 22), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -18, 0.5, 0), Parent = r,
            })
            corner(boxF, 6)
            stroke(boxF, 0.92)
            boxes[item] = boxF
            boxF.FocusLost:Connect(function()
                local v = tonumber(boxF.Text)
                if v then o.setValue(item, math.max(0, math.floor(v))) end
                boxF.Text = tostring(o.value(item))
            end)
        end
    end
    local obj = {}
    function obj:Refresh()
        if o.info then
            for item, l in pairs(infos) do l.Text = tostring(o.info(item)) end
        end
        for _, paint in pairs(paints) do paint() end
        if o.value then
            for item, b in pairs(boxes) do b.Text = tostring(o.value(item)) end
        end
    end
    return obj
end

return UI
