#!/usr/bin/env lua
--[[
Guidelime Vanilla - Guide Export Tool

Standalone Lua 5.1+ script that reads SavedVariables and generates
a complete guide pack addon ready to install in Interface/AddOns/.

Usage:
    lua Tools/export-guides.lua <account> <server> <character> [output_dir] [pack_name]

Example:
    lua Tools/export-guides.lua MYACCOUNT Turtle MyChar
    lua Tools/export-guides.lua MYACCOUNT Turtle MyChar ./output MyCustomGuides

The script reads:
    WTF/Account/<account>/<server>/<character>/SavedVariables/GuidelimeVanillaDB.lua

And generates:
    <output_dir>/<PackName>/
        <PackName>.toc
        init.lua
        guides/
            Guide_Name_1.lua
            Guide_Name_2.lua
            ...
]]--

-- ============================================================================
-- HELPERS
-- ============================================================================

local function sanitizeFilename(name)
    -- Replace spaces and special chars with underscores
    local safe = name:gsub("[^%w%-_]", "_")
    -- Remove consecutive underscores
    safe = safe:gsub("_+", "_")
    -- Trim leading/trailing underscores
    safe = safe:gsub("^_+", ""):gsub("_+$", "")
    return safe
end

local function mkdirp(path)
    -- Cross-platform mkdir
    local sep = package.config:sub(1, 1) -- "/" on Unix, "\" on Windows
    if sep == "\\" then
        os.execute('mkdir "' .. path:gsub("/", "\\") .. '" 2>NUL')
    else
        os.execute('mkdir -p "' .. path .. '"')
    end
end

local function writeFile(path, content)
    local f, err = io.open(path, "w")
    if not f then
        print("ERROR: Cannot write " .. path .. ": " .. (err or "unknown"))
        return false
    end
    f:write(content)
    f:close()
    return true
end

-- Minimal Lua table parser for SavedVariables
-- Only handles the subset used by AceDB (strings, numbers, booleans, tables)
local function loadSavedVariables(filepath)
    local f, err = io.open(filepath, "r")
    if not f then
        return nil, "Cannot open file: " .. (err or filepath)
    end
    local content = f:read("*a")
    f:close()

    -- Create a sandboxed environment
    local env = {}
    local chunk, loadErr
    if loadstring then
        -- Lua 5.1
        chunk, loadErr = loadstring(content)
    else
        -- Lua 5.2+
        chunk, loadErr = load(content, filepath, "t", env)
    end

    if not chunk then
        return nil, "Parse error: " .. (loadErr or "unknown")
    end

    if setfenv then
        -- Lua 5.1
        setfenv(chunk, env)
    end

    local ok, runErr = pcall(chunk)
    if not ok then
        return nil, "Execution error: " .. (runErr or "unknown")
    end

    return env
end

-- Navigate nested table by dot-separated path
local function getNestedValue(tbl, ...)
    local current = tbl
    for _, key in ipairs({...}) do
        if type(current) ~= "table" then return nil end
        current = current[key]
    end
    return current
end


-- ============================================================================
-- MAIN
-- ============================================================================

local function main()
    local account = arg[1]
    local server = arg[2]
    local character = arg[3]
    local outputDir = arg[4] or "."
    local packName = arg[5] or "MyCustomGuides"

    if not account or not server or not character then
        print("Usage: lua export-guides.lua <account> <server> <character> [output_dir] [pack_name]")
        print("")
        print("Example:")
        print("  lua export-guides.lua MYACCOUNT Turtle MyChar")
        print("  lua export-guides.lua MYACCOUNT Turtle MyChar ./output MyPackName")
        os.exit(1)
    end

    -- Build path to SavedVariables
    local svPath = string.format(
        "WTF/Account/%s/%s/%s/SavedVariables/GuidelimeVanillaDB.lua",
        account, server, character
    )

    print("Reading: " .. svPath)

    local env, err = loadSavedVariables(svPath)
    if not env then
        print("ERROR: " .. err)
        os.exit(1)
    end

    -- Find the GuidelimeVanillaDB variable
    local db = env.GuidelimeVanillaDB
    if not db then
        print("ERROR: GuidelimeVanillaDB not found in saved variables")
        os.exit(1)
    end

    -- Navigate to GuideEditor.Guides
    -- AceDB stores per-character data in db.chars["CharName - RealmName"]
    local guides = nil
    if db.chars then
        for charKey, charData in pairs(db.chars) do
            if type(charData) == "table" and charData.GuideEditor and charData.GuideEditor.Guides then
                local found = charData.GuideEditor.Guides
                if next(found) then
                    guides = found
                    print("Found guides for: " .. charKey)
                    break
                end
            end
        end
    end

    -- Also check direct structure (some AceDB versions)
    if not guides and db.GuideEditor and db.GuideEditor.Guides then
        guides = db.GuideEditor.Guides
    end

    if not guides or not next(guides) then
        print("No custom guides found in SavedVariables")
        os.exit(0)
    end

    -- Count guides
    local count = 0
    for _ in pairs(guides) do count = count + 1 end
    print(string.format("Found %d custom guide(s)", count))

    -- Create output directory structure
    local addonDir = outputDir .. "/" .. packName
    local guidesDir = addonDir .. "/guides"
    mkdirp(guidesDir)

    -- Generate .toc file
    local tocContent = string.format([[## Interface: 11200
## Title: %s
## Notes: Custom guides exported from GuideLime Vanilla Guide Editor
## Dependencies: GuidelimeVanilla
## DefaultState: enabled

init.lua
]], packName)

    -- Generate init.lua
    local initLines = {
        'local GLV = LibStub("GuidelimeVanilla")',
        string.format('GLV.guidePackAddons["%s"] = "%s"', packName, packName),
        "",
    }

    -- Generate guide files and add to TOC
    local guideFiles = {}
    for guideName, guideData in pairs(guides) do
        local text = type(guideData) == "table" and guideData.text or guideData
        if type(text) == "string" and text ~= "" then
            local safeName = sanitizeFilename(guideName)
            if safeName == "" then safeName = "guide" end
            local filename = "guides/" .. safeName .. ".lua"

            -- Avoid duplicate filenames
            local idx = 1
            while guideFiles[filename] do
                filename = "guides/" .. safeName .. "_" .. idx .. ".lua"
                idx = idx + 1
            end
            guideFiles[filename] = true

            -- Write guide file
            local guideContent = string.format(
                'local GLV = LibStub("GuidelimeVanilla")\nGLV:RegisterGuide([[\n%s\n]], "%s")\n',
                text, packName
            )

            local guidePath = addonDir .. "/" .. filename
            if writeFile(guidePath, guideContent) then
                -- Add to TOC
                tocContent = tocContent .. filename .. "\n"
                print("  Exported: " .. guideName .. " -> " .. filename)
            end
        end
    end

    -- Write TOC and init.lua
    writeFile(addonDir .. "/" .. packName .. ".toc", tocContent)
    writeFile(addonDir .. "/init.lua", table.concat(initLines, "\n") .. "\n")

    print("")
    print("Export complete!")
    print("Output: " .. addonDir .. "/")
    print("")
    print("To use: Copy the '" .. packName .. "' folder to your Interface/AddOns/ directory")
end

main()
