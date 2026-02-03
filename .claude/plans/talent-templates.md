# Plan : Système de Templates de Talents

## Objectif
Créer un système de suggestion de talents qui affiche une fenêtre modale au level-up indiquant où placer le point de talent selon un template prédéfini.

## Architecture

```
GuidelimeVanilla/
├── Core/
│   └── Events/
│       └── Talents.lua          # Nouveau - Tracking et popup
├── TalentTemplates/
│   ├── Mage.lua                 # Templates Mage
│   ├── Warrior.lua              # Templates Warrior
│   ├── Priest.lua               # etc...
│   └── ...                      # (9 classes au total)
└── Frames/
    └── TalentPopup.xml          # Nouveau - Fenêtre modale
```

## 1. Structure des Templates

**Fichier : `TalentTemplates/Mage.lua`**
```lua
local GLV = LibStub("GuidelimeVanilla")

GLV:RegisterTalentTemplate("Mage", "Frost Leveling", "leveling", {
    -- Format: {tree, row, col} pour chaque niveau (10-60)
    [10] = {3, 1, 2},  -- Improved Frostbolt
    [11] = {3, 1, 2},  -- Improved Frostbolt (rank 2)
    [12] = {3, 1, 2},  -- Improved Frostbolt (rank 3)
    -- ... jusqu'au niveau 60
})

GLV:RegisterTalentTemplate("Mage", "Fire Leveling", "leveling", {
    [10] = {2, 1, 2},  -- Improved Fireball
    -- ...
})

GLV:RegisterTalentTemplate("Mage", "Frost Raiding", "endgame", {
    -- Template complet pour reset au 60
})
```

## 2. API de Registration

**Fichier : `Core/Events/Talents.lua`**
```lua
GLV.TalentTemplates = {}  -- {class = {templateName = {type, talents}}}

function GLV:RegisterTalentTemplate(class, name, templateType, talents)
    -- class: "Mage", "Warrior", etc.
    -- name: "Frost Leveling", "Fire Raiding"
    -- templateType: "leveling" ou "endgame"
    -- talents: table {[level] = {tree, row, col}}

    if not self.TalentTemplates[class] then
        self.TalentTemplates[class] = {}
    end

    self.TalentTemplates[class][name] = {
        type = templateType,
        talents = talents
    }
end
```

## 3. Conversion tree,row,col → Nom du talent

**Dans `Core/Events/Talents.lua`**
```lua
function GLV:GetTalentNameByPosition(tree, row, col)
    local numTalents = GetNumTalents(tree)
    for i = 1, numTalents do
        local name, icon, tier, column, rank, maxRank = GetTalentInfo(tree, i)
        if tier == row and column == col then
            return name, icon, maxRank
        end
    end
    return nil
end
```

## 4. Détection Level-Up et Popup

**Dans `Core/Events/Talents.lua`**
```lua
local TalentTracker = {}
GLV.TalentTracker = TalentTracker

function TalentTracker:Init()
    -- Enregistrer l'event PLAYER_LEVEL_UP
    GLV.Ace:RegisterEvent("PLAYER_LEVEL_UP", function(newLevel)
        self:OnLevelUp(newLevel)
    end)
end

function TalentTracker:OnLevelUp(newLevel)
    -- Vérifier si feature activée
    if not GLV.Settings:GetOption({"Talents", "Enabled"}) then return end
    if newLevel < 10 then return end  -- Pas de talents avant niveau 10

    local playerClass = UnitClass("player")
    local templateName = GLV.Settings:GetOption({"Talents", "ActiveTemplate", playerClass})

    if not templateName then return end

    local template = GLV.TalentTemplates[playerClass] and
                     GLV.TalentTemplates[playerClass][templateName]
    if not template then return end

    local suggestion = template.talents[newLevel]
    if not suggestion then return end

    local tree, row, col = suggestion[1], suggestion[2], suggestion[3]
    local talentName, talentIcon = GLV:GetTalentNameByPosition(tree, row, col)

    if talentName then
        self:ShowTalentPopup(talentName, talentIcon, tree)
    end
end
```

## 5. Fenêtre Modale Popup

**Fichier : `Frames/TalentPopup.xml`**
```xml
<Frame name="GLV_TalentPopup" parent="UIParent" hidden="true"
       frameStrata="DIALOG" toplevel="true" movable="true">
    <Size><AbsDimension x="250" y="100"/></Size>
    <Anchors>
        <Anchor point="CENTER"/></Anchors>
    <Backdrop bgFile="Interface\DialogFrame\UI-DialogBox-Background"
              edgeFile="Interface\DialogFrame\UI-DialogBox-Border" tile="true">
        <EdgeSize><AbsValue val="16"/></EdgeSize>
    </Backdrop>
    <Layers>
        <Layer level="ARTWORK">
            <Texture name="$parentIcon">
                <Size><AbsDimension x="32" y="32"/></Size>
                <Anchors><Anchor point="LEFT" x="15" y="10"/></Anchors>
            </Texture>
            <FontString name="$parentTitle" inherits="GameFontNormalLarge">
                <Anchors><Anchor point="TOP" y="-10"/></Anchors>
            </FontString>
            <FontString name="$parentText" inherits="GameFontHighlight">
                <Anchors><Anchor point="TOP" relativeTo="$parentTitle"
                         relativePoint="BOTTOM" y="-5"/></Anchors>
            </FontString>
        </Layer>
    </Layers>
    <Frames>
        <Button name="$parentOKButton" inherits="UIPanelButtonTemplate" text="OK">
            <Size><AbsDimension x="60" y="22"/></Size>
            <Anchors><Anchor point="BOTTOM" y="15"/></Anchors>
            <Scripts>
                <OnClick>this:GetParent():Hide()</OnClick>
            </Scripts>
        </Button>
    </Frames>
</Frame>
```

**Dans `Core/Events/Talents.lua`**
```lua
function TalentTracker:ShowTalentPopup(talentName, talentIcon, treeIndex)
    local popup = getglobal("GLV_TalentPopup")
    if not popup then return end

    local treeName = GetTalentTabInfo(treeIndex)

    getglobal("GLV_TalentPopupIcon"):SetTexture(talentIcon)
    getglobal("GLV_TalentPopupTitle"):SetText("Talent Point!")
    getglobal("GLV_TalentPopupText"):SetText("Put 1 point in:\n|cFFFFFF00" ..
                                              talentName .. "|r\n(" .. treeName .. ")")

    popup:Show()
end
```

## 6. Settings

**Fichier : `Settings.lua`** - Ajouter aux defaults
```lua
Talents = {
    Enabled = true,
    ActiveTemplate = {},  -- {[class] = templateName}
    ShowEndgameAtSixty = true,
},
```

**Options à ajouter dans l'UI :**
- Checkbox "Enable Talent Suggestions"
- Dropdown "Select Template" (par classe, filtré par type "leveling")
- Checkbox "Show Endgame Template at 60"

## 7. Template Endgame au niveau 60

Quand le joueur atteint le niveau 60 et a `ShowEndgameAtSixty = true` :
1. Afficher une popup spéciale "Congratulations on level 60!"
2. Proposer de voir le template endgame recommandé
3. Option : lien vers un site externe ou affichage dans une frame dédiée

## Fichiers à créer/modifier

### Nouveaux fichiers
- `Core/Events/Talents.lua` - Logique principale
- `Frames/TalentPopup.xml` - Frame de la popup
- `TalentTemplates/Mage.lua`
- `TalentTemplates/Warrior.lua`
- `TalentTemplates/Priest.lua`
- `TalentTemplates/Rogue.lua`
- `TalentTemplates/Hunter.lua`
- `TalentTemplates/Warlock.lua`
- `TalentTemplates/Paladin.lua`
- `TalentTemplates/Shaman.lua`
- `TalentTemplates/Druid.lua`

### Fichiers à modifier
- `GuidelimeVanilla.toc` - Ajouter les nouveaux fichiers
- `Settings.lua` - Ajouter options Talents
- `Core.lua` - Initialiser TalentTracker

## Vérification

1. `/reload` en jeu
2. Activer les suggestions de talents dans Settings
3. Sélectionner un template pour la classe
4. Level up (ou utiliser `/script TalentTracker:OnLevelUp(15)` pour test)
5. Vérifier que la popup s'affiche avec le bon talent
6. Cliquer OK et vérifier que la popup se ferme
7. Tester au niveau 60 pour le template endgame

## Phases d'implémentation

### Phase 1 : Infrastructure (d'abord)
1. Créer `Core/Events/Talents.lua` avec l'API de registration
2. Créer `Frames/TalentPopup.xml`
3. Ajouter settings dans `Settings.lua`
4. Mettre à jour `GuidelimeVanilla.toc`

### Phase 2 : Templates (ensuite)
1. Créer les fichiers de templates pour chaque classe
2. Remplir avec au moins 1 template leveling par classe
3. (Optionnel) Ajouter templates endgame

### Phase 3 : UI Settings (enfin)
1. Ajouter dropdown de sélection de template dans les settings
2. Ajouter toggle enable/disable
