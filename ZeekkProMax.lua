-- ZEEKK PRO MAX | Roblox Studio ModuleScript
-- Bu modul yalnizca yerel takip panelini calistirir; oyun mekaniklerini degistirmez.

return function()
-- ZEEKK PRO MAX | Muscle Legends temali takip paneli (duzeltilmis surum)
-- KURULUM: Roblox Studio > StarterPlayer > StarterPlayerScripts altina LocalScript olarak ekle.
-- Panel oyuna baglanmaz, oyunun verisini okumaz veya degistirmez. Kendi sayac, sure,
-- hatirlatici ve notlarini tutan yerel bir yardimcidir. Veriler yalnizca bu oturumda kalir.

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then
    warn("[ZeekkProMax] Bu betik bir LocalScript olmali (StarterPlayerScripts).")
    return
end
local playerGui = player:WaitForChild("PlayerGui")

local old = playerGui:FindFirstChild("ZeekkProMax")
if old then old:Destroy() end

local gui = Instance.new("ScreenGui")
gui.Name = "ZeekkProMax"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = playerGui

------------------------------------------------------------------------
-- Renkler ve yardimci fonksiyonlar
------------------------------------------------------------------------
local C = {
    bg = Color3.fromRGB(5, 15, 31),
    accent = Color3.fromRGB(20, 165, 255),
    title = Color3.fromRGB(83, 205, 255),
    panel = Color3.fromRGB(8, 27, 48),
    section = Color3.fromRGB(13, 59, 94),
    sectionText = Color3.fromRGB(105, 218, 255),
    row = Color3.fromRGB(12, 39, 65),
    text = Color3.fromRGB(230, 244, 255),
    muted = Color3.fromRGB(140, 180, 210),
    ok = Color3.fromRGB(90, 235, 180),
    off = Color3.fromRGB(48, 65, 82),
    on = Color3.fromRGB(0, 145, 220),
    action = Color3.fromRGB(0, 112, 190),
    input = Color3.fromRGB(7, 22, 38),
    closeBtn = Color3.fromRGB(24, 65, 99),
    white = Color3.new(1, 1, 1),
}

local function make(className, props, parent)
    local obj = Instance.new(className)
    for k, v in pairs(props) do obj[k] = v end
    obj.Parent = parent
    return obj
end

-- Listede siralama icin artan LayoutOrder
local order = 0
local function nextOrder()
    order = order + 1
    return order
end

-- "1500", "1.500" (binlik ayirac), "1,5" (ondalik), "2.5m", "3B" gibi girisleri sayiya cevirir
local MULT = { k = 1e3, m = 1e6, b = 1e9, t = 1e12, q = 1e15 }

local function isGrouped(n)
    local first, rest = n:match("^(%d+)(.*)$")
    if not first or #first > 3 or first:sub(1, 1) == "0" or rest == "" then return false end
    while #rest > 0 do
        if rest:match("^[%.,]%d%d%d") then rest = rest:sub(5) else return false end
    end
    return true
end

local function parseNumber(text)
    local s = tostring(text or ""):lower():gsub("%s", "")
    local num, suf = s:match("^([%d%.,]+)([kmbtq]?)$")
    if not num then return nil end
    local value
    if suf == "" and isGrouped(num) then
        value = tonumber((num:gsub("[%.,]", "")))
    else
        value = tonumber((num:gsub(",", ".")))
    end
    if not value or value ~= value or value == math.huge then return nil end
    if suf ~= "" then value = value * MULT[suf] end
    return value
end

local UNITS = { { 1e15, "Q" }, { 1e12, "T" }, { 1e9, "B" }, { 1e6, "M" } }

local function trimZeros(str)
    if str:find(".", 1, true) then
        str = str:gsub("0+$", "")
        str = str:gsub("%.$", "")
    end
    return str
end

local function fmt(n)
    if n ~= n then return "0" end
    local sign = n < 0 and "-" or ""
    n = math.abs(n)
    for _, u in ipairs(UNITS) do
        if n >= u[1] then
            return sign .. trimZeros(string.format("%.2f", n / u[1])) .. u[2]
        end
    end
    return sign .. trimZeros(string.format("%.2f", n))
end

local function signed(n)
    return (n >= 0 and "+" or "") .. fmt(n)
end

local function clock(sec)
    sec = math.max(0, math.floor(sec))
    local h = math.floor(sec / 3600)
    local m = math.floor((sec % 3600) / 60)
    local s = sec % 60
    if h > 0 then return string.format("%d:%02d:%02d", h, m, s) end
    return string.format("%02d:%02d", m, s)
end

------------------------------------------------------------------------
-- Ana pencere (telefon ekranina sigacak sekilde olceklenir)
------------------------------------------------------------------------
local main = make("Frame", {
    Name = "Main",
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.fromScale(0.94, 0.92),
    BackgroundColor3 = C.bg,
    BorderSizePixel = 0,
}, gui)
make("UISizeConstraint", { MaxSize = Vector2.new(360, 520), MinSize = Vector2.new(250, 200) }, main)
make("UICorner", { CornerRadius = UDim.new(0, 14) }, main)
make("UIStroke", { Color = C.accent, Thickness = 2 }, main)

local title = make("TextLabel", {
    Name = "Title",
    Size = UDim2.new(1, -52, 0, 48), Position = UDim2.fromOffset(12, 4),
    BackgroundTransparency = 1, Text = "🐉 ZEEKK PRO MAX",
    TextColor3 = C.title, Active = true,
    Font = Enum.Font.GothamBold, TextSize = 21, TextXAlignment = Enum.TextXAlignment.Left,
}, main)

local close = make("TextButton", {
    Size = UDim2.fromOffset(34, 32), Position = UDim2.new(1, -42, 0, 10),
    BackgroundColor3 = C.closeBtn, Text = "×",
    TextColor3 = C.white, Font = Enum.Font.GothamBold, TextSize = 22,
}, main)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, close)

local status = make("TextLabel", {
    Size = UDim2.new(1, -24, 0, 25), Position = UDim2.fromOffset(12, 52),
    BackgroundTransparency = 1, Text = "Hazır • Yerel takip paneli",
    TextColor3 = C.ok, Font = Enum.Font.Gotham, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
}, main)

local scroll = make("ScrollingFrame", {
    Size = UDim2.new(1, -20, 1, -92), Position = UDim2.fromOffset(10, 82),
    BackgroundColor3 = C.panel, BorderSizePixel = 0,
    ScrollBarThickness = 5, ScrollingDirection = Enum.ScrollingDirection.Y,
    CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, main)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, scroll)
make("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, scroll)
make("UIPadding", {
    PaddingTop = UDim.new(0, 8), PaddingLeft = UDim.new(0, 8),
    PaddingRight = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
}, scroll)

------------------------------------------------------------------------
-- Surukleme (fare ve dokunmatik), pencere ekran disina cikmaz
------------------------------------------------------------------------
local dragging, dragStart, startOffX, startOffY = false, nil, 0, 0

title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startOffX = main.Position.X.Offset
        startOffY = main.Position.Y.Offset
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

local dragConn = UserInputService.InputChanged:Connect(function(input)
    if dragging and dragStart
        and (input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        local limX = math.max(0, (gui.AbsoluteSize.X - main.AbsoluteSize.X) / 2)
        local limY = math.max(0, (gui.AbsoluteSize.Y - main.AbsoluteSize.Y) / 2)
        local x = math.clamp(startOffX + delta.X, -limX, limX)
        local y = math.clamp(startOffY + delta.Y, -limY, limY)
        main.Position = UDim2.new(0.5, x, 0.5, y)
    end
end)

-- Panel silinirse (betik yeniden calisirsa) baglantiyi temizle
gui.Destroying:Connect(function() dragConn:Disconnect() end)

------------------------------------------------------------------------
-- Durum satiri, bildirim (toast) ve gecmis kaydi
------------------------------------------------------------------------
local toast = make("TextLabel", {
    Name = "Toast", AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 8), Size = UDim2.fromOffset(300, 40),
    BackgroundColor3 = C.section, BackgroundTransparency = 0.05, BorderSizePixel = 0,
    Text = "", TextColor3 = C.white, TextWrapped = true,
    Font = Enum.Font.GothamBold, TextSize = 13, Visible = false,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 10) }, toast)
make("UIStroke", { Color = C.accent, Thickness = 1.5 }, toast)

local function setStatus(text)
    status.Text = text
end

local toastToken = 0
local function notify(text)
    setStatus(text)
    toast.Text = text
    toast.Visible = true
    toastToken = toastToken + 1
    local token = toastToken
    task.delay(4, function()
        if toastToken == token and toast.Parent then toast.Visible = false end
    end)
end

local logLines = {}
local logLabel -- asagida olusturulur

local function renderLog()
    if not logLabel then return end
    if #logLines == 0 then
        logLabel.Text = "Henüz kayıt yok."
    else
        logLabel.Text = table.concat(logLines, "\n")
    end
end

local function addLog(text)
    table.insert(logLines, 1, os.date("%H:%M") .. "  " .. text)
    while #logLines > 40 do table.remove(logLines) end
    renderLog()
end

------------------------------------------------------------------------
-- Bolum basligi
------------------------------------------------------------------------
local function section(name)
    local label = make("TextLabel", {
        Size = UDim2.new(1, -4, 0, 28), BackgroundColor3 = C.section, BorderSizePixel = 0,
        Text = name, TextColor3 = C.sectionText, LayoutOrder = nextOrder(),
        Font = Enum.Font.GothamBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left,
    }, scroll)
    make("UICorner", { CornerRadius = UDim.new(0, 7) }, label)
    make("UIPadding", { PaddingLeft = UDim.new(0, 9) }, label)
end

------------------------------------------------------------------------
-- Takip satirlari
-- tur: counter (sayac), goal (hedefli sayac), value (deger/fark),
--      reminder (geri sayim hatirlaticisi), note (not defteri)
------------------------------------------------------------------------
local states = {}
local byName = {}

local function setEnabled(st, on)
    st.enabled = on
    st.toggle.Text = on and "AÇIK" or "KAPALI"
    st.toggle.BackgroundColor3 = on and C.on or C.off
    for _, ctl in ipairs(st.controls) do
        ctl.TextTransparency = on and 0 or 0.55
        if ctl:IsA("TextBox") then ctl.TextEditable = on end
    end
    if st.kind == "reminder" then
        st.deadline = on and (os.time() + math.floor(st.minutes * 60)) or nil
    end
    st.refresh()
end

local HOLDER_WIDTH = { counter = 56, goal = 74, value = 144, reminder = 100, note = 160 }

local function buildRow(def)
    local st = { name = def.name, kind = def.kind, enabled = false, controls = {} }
    states[#states + 1] = st
    byName[def.name] = st
    local holderW = HOLDER_WIDTH[def.kind]

    local row = make("Frame", {
        Name = def.name, Size = UDim2.new(1, -4, 0, 56),
        BackgroundColor3 = C.row, BorderSizePixel = 0, LayoutOrder = nextOrder(),
    }, scroll)
    make("UICorner", { CornerRadius = UDim.new(0, 8) }, row)

    make("TextLabel", {
        Size = UDim2.new(1, -86, 0, 22), Position = UDim2.fromOffset(9, 4),
        BackgroundTransparency = 1, Text = def.name, TextColor3 = C.text,
        Font = Enum.Font.GothamBold, TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    st.toggle = make("TextButton", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 5),
        Size = UDim2.fromOffset(66, 22), BackgroundColor3 = C.off, Text = "KAPALI",
        TextColor3 = C.white, Font = Enum.Font.GothamBold, TextSize = 10,
    }, row)
    make("UICorner", { CornerRadius = UDim.new(0, 7) }, st.toggle)

    st.info = make("TextLabel", {
        Position = UDim2.fromOffset(9, 30), Size = UDim2.new(1, -(holderW + 24), 0, 22),
        BackgroundTransparency = 1, Text = "", TextColor3 = C.muted,
        Font = Enum.Font.Gotham, TextSize = 11,
        TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd,
    }, row)

    local holder = make("Frame", {
        AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -6, 0, 30),
        Size = UDim2.fromOffset(holderW, 22), BackgroundTransparency = 1,
    }, row)
    make("UIListLayout", {
        FillDirection = Enum.FillDirection.Horizontal,
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        VerticalAlignment = Enum.VerticalAlignment.Center,
        SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 4),
    }, holder)

    local ctlOrder = 0

    local function newButton(text, w, onClick)
        ctlOrder = ctlOrder + 1
        local b = make("TextButton", {
            Size = UDim2.fromOffset(w, 22), BackgroundColor3 = C.action, Text = text,
            TextColor3 = C.white, Font = Enum.Font.GothamBold, TextSize = 11,
            LayoutOrder = ctlOrder,
        }, holder)
        make("UICorner", { CornerRadius = UDim.new(0, 6) }, b)
        b.MouseButton1Click:Connect(function()
            if not st.enabled then
                setStatus(st.name .. ": önce takibi aç (KAPALI → AÇIK)")
                return
            end
            onClick()
        end)
        st.controls[#st.controls + 1] = b
        return b
    end

    local function newBox(placeholder, w, text, onCommit)
        ctlOrder = ctlOrder + 1
        local t = make("TextBox", {
            Size = UDim2.fromOffset(w, 22), BackgroundColor3 = C.input, Text = text or "",
            PlaceholderText = placeholder, PlaceholderColor3 = C.muted,
            TextColor3 = C.white, Font = Enum.Font.Gotham, TextSize = 11,
            ClearTextOnFocus = false, TextEditable = false, LayoutOrder = ctlOrder,
        }, holder)
        make("UICorner", { CornerRadius = UDim.new(0, 6) }, t)
        t.FocusLost:Connect(function(enterPressed)
            if st.enabled then onCommit(t, enterPressed) end
        end)
        st.controls[#st.controls + 1] = t
        return t
    end

    if def.kind == "counter" then
        st.count = 0
        newButton("-", 26, function()
            st.count = math.max(0, st.count - 1)
            st.refresh()
        end)
        newButton("+", 26, function()
            st.count = st.count + 1
            st.refresh()
        end)
        st.refresh = function() st.info.Text = "Sayı: " .. fmt(st.count) end
        st.reset = function() st.count = 0 end

    elseif def.kind == "goal" then
        st.count, st.target, st.reached = 0, def.target or 10, false
        newBox("hedef", 44, fmt(st.target), function(t)
            local n = parseNumber(t.Text)
            if n and n >= 1 then
                st.target = math.floor(n)
                st.reached = st.count >= st.target
            end
            t.Text = fmt(st.target)
            st.refresh()
        end)
        newButton("+", 26, function()
            st.count = st.count + 1
            if st.count >= st.target and not st.reached then
                st.reached = true
                notify("🎯 " .. st.name .. ": hedefe ulaştın!")
                addLog("🎯 " .. st.name .. " hedefine ulaşıldı (" .. fmt(st.target) .. ")")
            end
            st.refresh()
        end)
        st.refresh = function()
            local pct = math.min(100, math.floor(st.count / st.target * 100))
            st.info.Text = fmt(st.count) .. " / " .. fmt(st.target) .. "  (%" .. pct .. ")"
        end
        st.reset = function()
            st.count, st.reached = 0, false
        end

    elseif def.kind == "value" then
        st.start, st.current = nil, nil
        local valueBox
        valueBox = newBox("değer gir", 84, "", function(t)
            local n = parseNumber(t.Text)
            if not n then
                setStatus(st.name .. ": geçersiz sayı (örnek: 1500, 2.5m, 3b)")
                t.Text = st.current and fmt(st.current) or ""
                return
            end
            if st.start == nil then st.start = n end
            st.current = n
            t.Text = fmt(n)
            st.refresh()
        end)
        newButton("SIFIRLA", 56, function()
            if st.current then
                st.start = st.current
                setStatus(st.name .. ": başlangıç noktası güncellendi")
            end
            st.refresh()
        end)
        st.refresh = function()
            if st.current then
                st.info.Text = "Şimdi " .. fmt(st.current) .. " • Fark " .. signed(st.current - st.start)
            else
                st.info.Text = "Değeri yazıp Enter'a bas"
            end
        end
        st.reset = function()
            st.start, st.current = nil, nil
            valueBox.Text = ""
        end

    elseif def.kind == "reminder" then
        st.minutes, st.done = def.minutes or 10, 0
        newBox("dk", 40, fmt(st.minutes), function(t)
            local n = parseNumber(t.Text)
            if n and n >= 1 then st.minutes = math.min(1440, math.floor(n)) end
            t.Text = fmt(st.minutes)
            st.deadline = os.time() + st.minutes * 60
            st.refresh()
        end)
        newButton("YAPTIM", 52, function()
            st.done = st.done + 1
            st.deadline = os.time() + st.minutes * 60
            addLog("✔ " .. st.name .. " — yapıldı (" .. st.done .. ")")
            st.refresh()
        end)
        st.refresh = function()
            if st.enabled and st.deadline then
                st.info.Text = "Kalan " .. clock(st.deadline - os.time()) .. " • Yapılan " .. st.done
            else
                st.info.Text = "Aralık " .. fmt(st.minutes) .. " dk • Yapılan " .. st.done
            end
        end
        st.reset = function()
            st.done = 0
            if st.enabled then st.deadline = os.time() + st.minutes * 60 end
        end

    elseif def.kind == "note" then
        st.count = 0
        local noteBox
        local addNote
        noteBox = newBox("notunu yaz", 112, "", function(_, enterPressed)
            if enterPressed then addNote() end
        end)
        addNote = function()
            local text = (noteBox.Text:gsub("^%s*(.-)%s*$", "%1"))
            if text == "" then
                setStatus(st.name .. ": önce notu yaz")
                return
            end
            local len = utf8.len(text)
            if len and len > 120 then text = text:sub(1, utf8.offset(text, 121) - 1) end
            st.count = st.count + 1
            addLog("📝 [" .. st.name .. "] " .. text)
            noteBox.Text = ""
            setStatus(st.name .. ": not kaydedildi")
            st.refresh()
        end
        newButton("EKLE", 44, addNote)
        st.refresh = function() st.info.Text = "Not sayısı: " .. fmt(st.count) end
        st.reset = function() st.count = 0 end
    end

    st.toggle.MouseButton1Click:Connect(function()
        setEnabled(st, not st.enabled)
        setStatus(st.name .. (st.enabled and " takibi açıldı" or " takibi kapatıldı"))
    end)

    setEnabled(st, false) -- baslangic gorunumu
end

local SECTIONS = {
    { title = "⚔️ SAVAŞ TAKİBİ", items = {
        { name = "Savaş notu", kind = "note" },
        { name = "Hedef takibi notu", kind = "note" },
        { name = "Rakip karşılaşma kaydı", kind = "counter" },
        { name = "Arena hatırlatıcısı", kind = "reminder", minutes = 10 },
        { name = "Patron savaşı hatırlatıcısı", kind = "reminder", minutes = 15 },
    } },
    { title = "💪 GELİŞİM TAKİBİ", items = {
        { name = "Antrenman takibi", kind = "counter" },
        { name = "Ağırlık kaldırma takibi", kind = "counter" },
        { name = "Yeniden doğuş hedefi", kind = "goal", target = 10 },
        { name = "Güç gelişimi", kind = "value" },
        { name = "Dayanıklılık gelişimi", kind = "value" },
        { name = "Çeviklik gelişimi", kind = "value" },
    } },
    { title = "🐾 HAYVAN VE ÖDÜL TAKİBİ", items = {
        { name = "Yumurta hatırlatıcısı", kind = "reminder", minutes = 30 },
        { name = "Hayvan envanteri notu", kind = "note" },
        { name = "Koleksiyon takibi", kind = "counter" },
        { name = "Günlük ödül hatırlatıcısı", kind = "reminder", minutes = 60 },
        { name = "Sandık kontrol listesi", kind = "counter" },
    } },
}

for _, sec in ipairs(SECTIONS) do
    section(sec.title)
    for _, def in ipairs(sec.items) do
        buildRow(def)
    end
end

------------------------------------------------------------------------
-- Hizli islemler
------------------------------------------------------------------------
local function addAction(name, callback)
    local button = make("TextButton", {
        Size = UDim2.new(1, -4, 0, 36), BackgroundColor3 = C.action, Text = name,
        TextColor3 = C.white, Font = Enum.Font.GothamBold, TextSize = 12,
        LayoutOrder = nextOrder(),
    }, scroll)
    make("UICorner", { CornerRadius = UDim.new(0, 8) }, button)
    button.MouseButton1Click:Connect(callback)
end

local quick = { train = 0, reward = 0 }

section("🛠️ HIZLI İŞLEMLER")

addAction("💪 Antrenman yaptım — not ekle", function()
    quick.train = quick.train + 1
    addLog("💪 Antrenman yapıldı (" .. quick.train .. ". kez)")
    local st = byName["Antrenman takibi"]
    if st and st.enabled then
        st.count = st.count + 1
        st.refresh()
    end
    setStatus("Antrenman notu kaydedildi (" .. quick.train .. ". kez, bu oturum).")
end)

addAction("🎁 Ödülleri kontrol ettim — not ekle", function()
    quick.reward = quick.reward + 1
    addLog("🎁 Ödüller kontrol edildi (" .. quick.reward .. ". kez)")
    local st = byName["Günlük ödül hatırlatıcısı"]
    if st and st.enabled then
        st.done = st.done + 1
        st.deadline = os.time() + st.minutes * 60
        st.refresh()
    end
    setStatus("Ödül kontrol notu kaydedildi (" .. quick.reward .. ". kez, bu oturum).")
end)

addAction("↺ Bütün sayaçları sıfırla", function()
    for _, st in ipairs(states) do
        st.reset()
        st.refresh()
    end
    quick.train, quick.reward = 0, 0
    addLog("↺ Sayaçlar sıfırlandı")
    setStatus("Bütün sayaçlar sıfırlandı.")
end)

addAction("🧹 Geçmişi temizle", function()
    logLines = {}
    renderLog()
    setStatus("Geçmiş temizlendi.")
end)

addAction("🛑 Bütün takip anahtarlarını kapat", function()
    for _, st in ipairs(states) do
        setEnabled(st, false)
    end
    setStatus("Bütün takipler kapatıldı.")
end)

------------------------------------------------------------------------
-- Gecmis / notlar
------------------------------------------------------------------------
section("📝 GEÇMİŞ VE NOTLAR (bu oturum)")

logLabel = make("TextLabel", {
    Size = UDim2.new(1, -4, 0, 0), AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = C.row, BorderSizePixel = 0, LayoutOrder = nextOrder(),
    Text = "", TextColor3 = C.text, TextWrapped = true, RichText = false,
    Font = Enum.Font.Gotham, TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
}, scroll)
make("UICorner", { CornerRadius = UDim.new(0, 8) }, logLabel)
make("UIPadding", {
    PaddingTop = UDim.new(0, 8), PaddingBottom = UDim.new(0, 8),
    PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9),
}, logLabel)
renderLog()

------------------------------------------------------------------------
-- Hatirlatici sayaci (her saniye); panel silinince dongu kendiliginden biter
------------------------------------------------------------------------
task.spawn(function()
    while gui.Parent do
        task.wait(1)
        local t = os.time()
        for _, st in ipairs(states) do
            if st.kind == "reminder" and st.enabled and st.deadline then
                if t >= st.deadline then
                    st.deadline = t + st.minutes * 60
                    notify("⏰ " .. st.name .. " zamanı!")
                    addLog("⏰ " .. st.name .. " hatırlatıldı")
                end
                st.refresh()
            end
        end
    end
end)

------------------------------------------------------------------------
-- Kapat / yeniden ac
------------------------------------------------------------------------
local reopen = make("TextButton", {
    Size = UDim2.fromOffset(54, 42), Position = UDim2.new(0, 12, 0.5, -21),
    BackgroundColor3 = Color3.fromRGB(0, 105, 190), Text = "ZP",
    TextColor3 = C.white, Font = Enum.Font.GothamBlack, TextSize = 17,
    Visible = false,
}, gui)
make("UICorner", { CornerRadius = UDim.new(0, 12) }, reopen)

close.MouseButton1Click:Connect(function()
    main.Visible = false
    reopen.Visible = true
end)
reopen.MouseButton1Click:Connect(function()
    main.Visible = true
    reopen.Visible = false
end)

end
