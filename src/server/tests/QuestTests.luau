--[[
    Quest test suite. Run from execute_luau (Server mode) with:
        require(game.ServerScriptService.Server.tests.QuestTests).runAll()

    Tests fire QuestService events directly — no UI or NPC interaction needed.
    Requires one player to be in the session.
]]

local engine = require(script.Parent.Parent.Loader.Engine)

local QuestService     = engine:get("QuestService")
local PlayerService    = engine:get("PlayerService")
local InventoryService = engine:get("InventoryService")
local HttpService      = game:GetService("HttpService")

-- ── Helpers ──────────────────────────────────────────────────────────────────

local function getTestPlayer()
    local player = game:GetService("Players"):GetPlayers()[1]
    if not player then error("No player in session") end
    local playerClass
    for _ = 1, 20 do
        playerClass = PlayerService:get(player)
        if playerClass and playerClass.profile then break end
        task.wait(0.5)
    end
    if not (playerClass and playerClass.profile) then
        error("PlayerService did not load player in time")
    end
    return player, playerClass
end

local function resetQuests(playerClass, ids)
    playerClass.localData.quests = playerClass.localData.quests or {}
    for _, id in ipairs(ids) do
        if playerClass.localData.quests[id] then
            playerClass.localData.quests[id]:destroy()
            playerClass.localData.quests[id] = nil
        end
        playerClass.profile.Data.quests.active[id]    = nil
        playerClass.profile.Data.quests.completed[id] = nil
    end
end

local function markCompleted(playerClass, id)
    resetQuests(playerClass, { id })
    playerClass.profile.Data.quests.completed[id] = os.time()
end

local function addLoot(playerClass, lootKey, count)
    playerClass.profile.Data.inventory = playerClass.profile.Data.inventory or { loot = {} }
    local ids = {}
    for _ = 1, count do
        local id = HttpService:GenerateGUID(false)
        table.insert(ids, id)
        table.insert(playerClass.profile.Data.inventory.loot, { id = id, lootKey = lootKey, kg = 1 })
    end
    return ids
end

local function removeLoot(playerClass, ids)
    local loot = playerClass.profile.Data.inventory.loot
    for _, targetId in ipairs(ids) do
        for i, entry in ipairs(loot) do
            if entry.id == targetId then table.remove(loot, i) break end
        end
    end
end

local function countLoot(playerClass, lootKey)
    local count = 0
    for _, entry in ipairs(playerClass.profile.Data.inventory.loot or {}) do
        if entry.lootKey == lootKey then count += 1 end
    end
    return count
end

local function clearLoot(playerClass, lootKey)
    local loot = playerClass.profile.Data.inventory and playerClass.profile.Data.inventory.loot or {}
    for i = #loot, 1, -1 do
        if loot[i].lootKey == lootKey then table.remove(loot, i) end
    end
end

local function activeNode(playerClass, questId)
    local q = playerClass.profile.Data.quests.active[questId]
    return q and q.currentNode
end

-- ── Test runner ───────────────────────────────────────────────────────────────

local results = {}

local function test(name, fn)
    local ok, err = pcall(fn)
    table.insert(results, (ok and "  [PASS] " or "  [FAIL] ") .. name .. (ok and "" or "\n         " .. tostring(err)))
end

local function assert(cond, msg)
    if not cond then error(msg or "assertion failed", 2) end
end

local function wait() task.wait(0.05) end

-- ── Tests ─────────────────────────────────────────────────────────────────────

local QuestTests = {}

function QuestTests.runAll()
    results = {}
    local player, playerClass = getTestPlayer()
    local data = playerClass.profile.Data

    -- initialise quest tables if missing (fresh session)
    data.quests = data.quests or { active = {}, completed = {} }
    data.quests.active    = data.quests.active    or {}
    data.quests.completed = data.quests.completed or {}

    table.insert(results, "Quest Test Suite — " .. os.date("%H:%M:%S"))
    table.insert(results, "")
    table.insert(results, "── TalkToGemal ─────────────────────────────────────────")

    test("quest starts (no requirements)", function()
        resetQuests(playerClass, { "TalkToGemal" })
        local ok = QuestService:addQuest(player, "TalkToGemal")
        assert(ok, "addQuest returned false")
        assert(playerClass.localData.quests["TalkToGemal"], "no instance created")
    end)

    test("speakToNPC Gemal → quest completes", function()
        resetQuests(playerClass, { "TalkToGemal" })
        QuestService:addQuest(player, "TalkToGemal")
        QuestService.events.speakToNPC:Fire(player, { npc = "Grandpa_Gemal" })
        wait()
        assert(data.quests.completed["TalkToGemal"], "quest not in completed")
    end)

    test("speakToNPC Gemal → +50 coins reward", function()
        resetQuests(playerClass, { "TalkToGemal" })
        QuestService:addQuest(player, "TalkToGemal")
        local before = data.coins
        QuestService.events.speakToNPC:Fire(player, { npc = "Grandpa_Gemal" })
        wait()
        assert(data.coins == before + 50, `expected {before + 50} coins, got {data.coins}`)
    end)

    test("speakToNPC wrong NPC → quest stays active", function()
        resetQuests(playerClass, { "TalkToGemal" })
        QuestService:addQuest(player, "TalkToGemal")
        QuestService.events.speakToNPC:Fire(player, { npc = "Donnie" })
        wait()
        assert(not data.quests.completed["TalkToGemal"], "quest completed on wrong NPC")
        assert(data.quests.active["TalkToGemal"], "quest left active table")
    end)

    table.insert(results, "")
    table.insert(results, "── TalkToDonnie ────────────────────────────────────────")

    test("requires TalkToGemal completed", function()
        resetQuests(playerClass, { "TalkToDonnie", "TalkToGemal" })
        local ok = QuestService:addQuest(player, "TalkToDonnie")
        assert(not ok, "addQuest should fail without TalkToGemal done")
    end)

    test("can be added after TalkToGemal done", function()
        resetQuests(playerClass, { "TalkToDonnie" })
        markCompleted(playerClass, "TalkToGemal")
        local ok = QuestService:addQuest(player, "TalkToDonnie")
        assert(ok, "addQuest returned false")
    end)

    test("speakToNPC Donnie → quest completes", function()
        resetQuests(playerClass, { "TalkToDonnie" })
        markCompleted(playerClass, "TalkToGemal")
        QuestService:addQuest(player, "TalkToDonnie")
        QuestService.events.speakToNPC:Fire(player, { npc = "Donnie" })
        wait()
        assert(data.quests.completed["TalkToDonnie"], "quest not completed")
    end)

    table.insert(results, "")
    table.insert(results, "── HelpDonnie ──────────────────────────────────────────")

    test("collectLoot x3 titanium → advances to returnToDonnie", function()
        resetQuests(playerClass, { "HelpDonnie" })
        markCompleted(playerClass, "TalkToGemal")
        clearLoot(playerClass, "titanium")
        QuestService:addQuest(player, "HelpDonnie")
        assert(activeNode(playerClass, "HelpDonnie") == "collectTitanium", "wrong start node")
        QuestService.events.collectLoot:Fire(player, { lootKey = "titanium", kg = 1 })
        QuestService.events.collectLoot:Fire(player, { lootKey = "titanium", kg = 1 })
        QuestService.events.collectLoot:Fire(player, { lootKey = "titanium", kg = 1 })
        wait()
        assert(activeNode(playerClass, "HelpDonnie") == "returnToDonnie",
            `expected returnToDonnie, got {activeNode(playerClass, "HelpDonnie")}`)
    end)

    test("collectLoot wrong type → no progress", function()
        resetQuests(playerClass, { "HelpDonnie" })
        markCompleted(playerClass, "TalkToGemal")
        clearLoot(playerClass, "titanium")
        QuestService:addQuest(player, "HelpDonnie")
        QuestService.events.collectLoot:Fire(player, { lootKey = "iron", kg = 1 })
        QuestService.events.collectLoot:Fire(player, { lootKey = "iron", kg = 1 })
        wait()
        assert(activeNode(playerClass, "HelpDonnie") == "collectTitanium", "advanced on wrong loot type")
    end)

    test("checkExistingInventory: titanium in bag at quest start counts", function()
        resetQuests(playerClass, { "HelpDonnie" })
        markCompleted(playerClass, "TalkToGemal")
        local ids = addLoot(playerClass, "titanium", 3)
        QuestService:addQuest(player, "HelpDonnie")
        wait()
        local node = activeNode(playerClass, "HelpDonnie")
        removeLoot(playerClass, ids)
        assert(node == "returnToDonnie", `expected returnToDonnie, got {node}`)
    end)

    test("turn-in → quest completes, rusty drill granted", function()
        resetQuests(playerClass, { "HelpDonnie" })
        markCompleted(playerClass, "TalkToGemal")
        data.drill = { type = nil }
        local ids = addLoot(playerClass, "titanium", 3)
        QuestService:addQuest(player, "HelpDonnie")
        wait()
        QuestService.events.speakToNPC:Fire(player, { npc = "Donnie" })
        wait()
        removeLoot(playerClass, ids) -- clean up any leftover test entries
        assert(data.quests.completed["HelpDonnie"], "quest not completed")
        assert(data.drill and data.drill.type == "rusty",
            `expected drill.type "rusty", got {data.drill and data.drill.type or "nil"}`)
    end)

    test("turn-in → titanium removed from inventory", function()
        resetQuests(playerClass, { "HelpDonnie" })
        markCompleted(playerClass, "TalkToGemal")
        addLoot(playerClass, "titanium", 3)
        QuestService:addQuest(player, "HelpDonnie")
        wait()
        QuestService.events.speakToNPC:Fire(player, { npc = "Donnie" })
        wait()
        assert(countLoot(playerClass, "titanium") == 0,
            `expected 0 titanium, got {countLoot(playerClass, "titanium")}`)
    end)

    table.insert(results, "")
    table.insert(results, "── HelpLadySaphire ─────────────────────────────────────")

    test("coinsChanged ≥5000 → advances to returnToLadySaphire", function()
        resetQuests(playerClass, { "HelpLadySaphire" })
        markCompleted(playerClass, "TalkToGemal")
        QuestService:addQuest(player, "HelpLadySaphire")
        assert(activeNode(playerClass, "HelpLadySaphire") == "raiseFunds", "wrong start node")
        data.coins = 5000
        QuestService.events.coinsChanged:Fire(player, 5000)
        wait()
        assert(activeNode(playerClass, "HelpLadySaphire") == "returnToLadySaphire",
            `expected returnToLadySaphire, got {activeNode(playerClass, "HelpLadySaphire")}`)
    end)

    test("coinsChanged <5000 → stays on raiseFunds", function()
        resetQuests(playerClass, { "HelpLadySaphire" })
        markCompleted(playerClass, "TalkToGemal")
        QuestService:addQuest(player, "HelpLadySaphire")
        data.coins = 4999
        QuestService.events.coinsChanged:Fire(player, 4999)
        wait()
        assert(activeNode(playerClass, "HelpLadySaphire") == "raiseFunds",
            `expected raiseFunds, got {activeNode(playerClass, "HelpLadySaphire")}`)
    end)

    test("turn-in with correct optionId → completes, coins removed, geode given", function()
        resetQuests(playerClass, { "HelpLadySaphire" })
        markCompleted(playerClass, "TalkToGemal")
        QuestService:addQuest(player, "HelpLadySaphire")
        data.coins = 5000
        QuestService.events.coinsChanged:Fire(player, 5000)
        wait()
        local geodesBefore = countLoot(playerClass, "geode")
        QuestService.events.speakToNPC:Fire(player, { npc = "Lady_Saphire", option = { id = "saphire_have_raised_enough" } })
        wait()
        assert(data.quests.completed["HelpLadySaphire"], "quest not completed")
        assert(data.coins == 0, `expected 0 coins, got {data.coins}`)
        assert(countLoot(playerClass, "geode") == geodesBefore + 1,
            `expected {geodesBefore + 1} geodes, got {countLoot(playerClass, "geode")}`)
    end)

    test("turn-in with wrong optionId → stays active", function()
        resetQuests(playerClass, { "HelpLadySaphire" })
        markCompleted(playerClass, "TalkToGemal")
        QuestService:addQuest(player, "HelpLadySaphire")
        data.coins = 5000
        QuestService.events.coinsChanged:Fire(player, 5000)
        wait()
        QuestService.events.speakToNPC:Fire(player, { npc = "Lady_Saphire", option = { id = "some_other_option" } })
        wait()
        assert(not data.quests.completed["HelpLadySaphire"], "quest completed on wrong optionId")
    end)

    table.insert(results, "")
    table.insert(results, "── LostRowan ───────────────────────────────────────────")

    test("full chain: findRowan → getGeode → convinceRowan → reportBack → complete", function()
        resetQuests(playerClass, { "LostRowan" })
        markCompleted(playerClass, "TalkToGemal")
        QuestService:addQuest(player, "LostRowan")
        assert(activeNode(playerClass, "LostRowan") == "findRowan", "wrong start node")

        QuestService.events.speakToNPC:Fire(player, { npc = "Rowan" })
        wait()
        assert(activeNode(playerClass, "LostRowan") == "getGeode",
            `expected getGeode, got {activeNode(playerClass, "LostRowan")}`)

        QuestService.events.collectLoot:Fire(player, { lootKey = "geode", kg = 1 })
        wait()
        assert(activeNode(playerClass, "LostRowan") == "convinceRowan",
            `expected convinceRowan, got {activeNode(playerClass, "LostRowan")}`)

        QuestService.events.speakToNPC:Fire(player, { npc = "Rowan" })
        wait()
        assert(activeNode(playerClass, "LostRowan") == "reportBack",
            `expected reportBack, got {activeNode(playerClass, "LostRowan")}`)

        QuestService.events.speakToNPC:Fire(player, { npc = "Worried_Dad" })
        wait()
        assert(data.quests.completed["LostRowan"], "LostRowan not completed")
    end)

    table.insert(results, "")
    table.insert(results, "── SaveLilPups ──────────────────────────────────────────")

    test("requires HelpLadySaphire completed", function()
        resetQuests(playerClass, { "SaveLilPups", "HelpLadySaphire" })
        local ok = QuestService:addQuest(player, "SaveLilPups")
        assert(not ok, "addQuest should fail without HelpLadySaphire done")
    end)

    test("collectLoot x10 amethyst → advances to returnToSaphire", function()
        resetQuests(playerClass, { "SaveLilPups" })
        markCompleted(playerClass, "HelpLadySaphire")
        clearLoot(playerClass, "amethyst")
        QuestService:addQuest(player, "SaveLilPups")
        assert(activeNode(playerClass, "SaveLilPups") == "collectAmethyst", "wrong start node")
        for _ = 1, 10 do
            QuestService.events.collectLoot:Fire(player, { lootKey = "amethyst", kg = 1 })
        end
        wait()
        assert(activeNode(playerClass, "SaveLilPups") == "returnToSaphire",
            `expected returnToSaphire, got {activeNode(playerClass, "SaveLilPups")}`)
    end)

    test("9 amethyst → stays on collectAmethyst", function()
        resetQuests(playerClass, { "SaveLilPups" })
        markCompleted(playerClass, "HelpLadySaphire")
        clearLoot(playerClass, "amethyst")
        QuestService:addQuest(player, "SaveLilPups")
        for _ = 1, 9 do
            QuestService.events.collectLoot:Fire(player, { lootKey = "amethyst", kg = 1 })
        end
        wait()
        assert(activeNode(playerClass, "SaveLilPups") == "collectAmethyst",
            `expected collectAmethyst, got {activeNode(playerClass, "SaveLilPups")}`)
    end)

    test("turn-in → completes, +5000 coins, amethyst removed", function()
        resetQuests(playerClass, { "SaveLilPups" })
        markCompleted(playerClass, "HelpLadySaphire")
        clearLoot(playerClass, "amethyst")
        QuestService:addQuest(player, "SaveLilPups")
        for _ = 1, 10 do
            QuestService.events.collectLoot:Fire(player, { lootKey = "amethyst", kg = 1 })
        end
        wait()
        local coinsBefore = data.coins
        QuestService.events.speakToNPC:Fire(player, { npc = "Lady_Saphire", option = { id = "saphire_lil_pups_turn_in" } })
        wait()
        assert(data.quests.completed["SaveLilPups"], "SaveLilPups not completed")
        assert(data.coins == coinsBefore + 5000, `expected {coinsBefore + 5000} coins, got {data.coins}`)
        assert(countLoot(playerClass, "amethyst") == 0,
            `expected 0 amethyst remaining, got {countLoot(playerClass, "amethyst")}`)
    end)

    -- ── Summary ───────────────────────────────────────────────────────────────

    table.insert(results, "")
    local passed = 0
    local failed = 0
    for _, r in ipairs(results) do
        if r:find("%[PASS%]") then passed += 1
        elseif r:find("%[FAIL%]") then failed += 1
        end
    end
    table.insert(results, string.format("─────────────────────────────────────────────────────"))
    table.insert(results, string.format("  %d passed  |  %d failed  |  %d total", passed, failed, passed + failed))

    return "\n" .. table.concat(results, "\n") .. "\n"
end

return QuestTests
