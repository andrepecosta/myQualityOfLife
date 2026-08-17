-- myQualityOfLife
-- Gen1Recomp API 2 mod. Configurable quality-of-life pack with Move Editor.
return function(mod)
  local MAIN_SCREEN = "PMEQoLMain"
  local BATTLE_SCREEN = "PMEQoLBattle"
  local POKEMON_SCREEN = "PMEQoLPokemon"
  local MISC_SCREEN = "PMEQoLMisc"
  local CHEATS_SCREEN = "PMEQoLCheats"
  local QUICK_HM_SCREEN = "PMEQoLQuickHM"
  local QUICK_HM_HOTKEY_SCREEN = "PMEQoLQuickHMHotkey"
  local QUICK_HM_KEY_CAPTURE_SCREEN = "PMEQoLQuickHMKeyCapture"
  local QUICK_HM_PAD_CAPTURE_SCREEN = "PMEQoLQuickHMPadCapture"
  local ENCOUNTER_HOTKEY_SCREEN = "PMEQoLEncounterHotkey"
  local ENCOUNTER_KEY_CAPTURE_SCREEN = "PMEQoLEncounterKeyCapture"
  local ENCOUNTER_PAD_CAPTURE_SCREEN = "PMEQoLEncounterPadCapture"
  local WILD_POKEMON_SCREEN = "PMEQoLWildPokemon"
  local BAG_SORT_SCREEN = "PMEQoLBagSort"
  local MOVE_SCREEN = "PlayerMoveEditorMoves"
  local PICK_SCREEN = "PlayerMoveEditorPick"

  local target = nil
  local targetSlot = nil
  local forcedExp = setmetatable({}, { __mode = "k" })

  local DEFAULTS = {
    fast_run = "OFF",          -- OFF / ON / ON+SURF
    auto_run = false,
    instant_text = false,
    itemfinder = "OFF",       -- OFF / ON / HAVE ITEM
    type_fixes = false,
    fast_center = false,
    fast_save = false,
    never_miss = false,
    always_crit = false,
    infinite_pp = false,
    always_catch = false,
    exp_multiplier = "OFF",    -- OFF / 1.5X / 2X / 3X / 4X
    game_corner_multiplier = "OFF", -- OFF / 2X / 3X / 5X / 10X
    challenge_mode = "OFF",    -- OFF / MAX / +1 ... +20
    force_encounter = "OFF",    -- OFF / ON (area level) / FIRST (party lead level)
    encounter_hotkey = "f6",
    encounter_gamepad = "OFF",
    wild_select = "OFF",       -- OFF / ON
    wild_pokemon = "RATTATA",
    exp_share = "OFF",         -- OFF / ACTIVE (shown as GEN1) / SMART
    move_info = false,
    move_editor = "OFF",       -- TODOS / BASE / OFF
    forget_hm = false,
    unlimited_tm = false,
    quick_hm = "OFF",          -- OFF / ON / IGNORE
    quick_hm_hotkey = "shift",
    quick_hm_gamepad = "OFF",
    max_dv = false,
    bag_sort = "OFF",          -- OFF / NAME / QUANTITY / TYPE
    pikachu_evo = false,
  }

  local MISC_KEYS = { "fast_run", "auto_run", "instant_text", "itemfinder", "type_fixes", "fast_center", "fast_save", "bag_sort" }
  local BATTLE_KEYS = { "exp_share", "move_info" }
  local POKEMON_KEYS = { "forget_hm", "unlimited_tm", "quick_hm", "quick_hm_hotkey", "quick_hm_gamepad", "max_dv", "pikachu_evo" }
  local CHEAT_KEYS = { "never_miss", "always_crit", "infinite_pp", "always_catch", "exp_multiplier", "game_corner_multiplier", "challenge_mode", "move_editor",
    "force_encounter", "encounter_hotkey", "encounter_gamepad", "wild_select", "wild_pokemon" }

  local function get(key)
    local value=mod.save:get(key, DEFAULTS[key])
    if key=="force_encounter" and type(value)=="boolean" then
      if not value then return "OFF" end
      return mod.save:get("encounter_level","AREA")=="FIRST" and "FIRST" or "ON"
    end
    if key=="wild_select" and type(value)=="boolean" then return value and "ON" or "OFF" end
    if key=="wild_select" and value=="FIRST" then return "ON" end
    return value
  end

  local function persist(game)
    if game and game.writeSave then
      pcall(function() game:writeSave() end)
    end
  end

  local function set(game, key, value)
    mod.save:set(key, value)
    persist(game)
  end

  local function resetKeys(game, keys)
    for _, key in ipairs(keys) do mod.save:set(key, DEFAULTS[key]) end
    persist(game)
  end

  local function resetAll(game)
    resetKeys(game, MISC_KEYS)
    resetKeys(game, BATTLE_KEYS)
    resetKeys(game, POKEMON_KEYS)
    resetKeys(game, CHEAT_KEYS)
  end

  local function confirmReset(game,text,onConfirm)
    local TextBox=require("src.render.TextBox")
    game.stack:push(TextBox.new(game,text,nil,{
      defaultNo=true,
      choice=function(yes)
        if yes and onConfirm then onConfirm() end
      end,
    }))
  end

  local function boolText(v) return v and "ON" or "OFF" end
  local function toggle(game, key) set(game, key, not get(key)) end

  local menuCycleDirection=1

  local function cycle(game, key, values)
    local cur = get(key)
    local idx = 1
    for i, v in ipairs(values) do if v == cur then idx = i break end end
    if menuCycleDirection<0 then idx=(idx-2)%#values+1
    else idx=idx%#values+1 end
    set(game, key, values[idx])
  end

  local CHALLENGE_VALUES={"OFF","MAX"}
  for bonus=1,20 do CHALLENGE_VALUES[#CHALLENGE_VALUES+1]="+"..bonus end

  local function hotkeyText(key)
    key=tostring(key or "shift")
    local names={
      shift="SHIFT", lctrl="LEFT CTRL", rctrl="RIGHT CTRL",
      lalt="LEFT ALT", ralt="RIGHT ALT", capslock="CAPS LOCK",
      pageup="PAGE UP", pagedown="PAGE DOWN",
    }
    return names[key] or key:upper()
  end

  local function gamepadText(button)
    button=tostring(button or "OFF")
    local names={
      leftshoulder="L1",rightshoulder="R1",
      lefttrigger="L2",righttrigger="R2",
      leftstick="L3",rightstick="R3",
    }
    local raw=button:match("^joy:(%d+)$")
    if raw then return "JOY "..raw end
    return names[button] or button:upper()
  end

  local BLOCKED_HOTKEYS={
    up=true,down=true,left=true,right=true,w=true,a=true,s=true,d=true,
    z=true,x=true,["return"]=true,space=true,backspace=true,escape=true,tab=true,
    ["1"]=true,["2"]=true,["3"]=true,["4"]=true,["5"]=true,
    f1=true,f2=true,f5=true,f10=true,
  }

  local BLOCKED_PAD_HOTKEYS={
    a=true,b=true,x=true,y=true,back=true,start=true,guide=true,
    dpup=true,dpdown=true,dpleft=true,dpright=true,
  }

  local SIDE_OPTION_KEYS={}
  for _,keys in ipairs({MISC_KEYS,BATTLE_KEYS,POKEMON_KEYS,CHEAT_KEYS}) do
    for _,key in ipairs(keys) do SIDE_OPTION_KEYS[key]=true end
  end
  SIDE_OPTION_KEYS.quick_hm_hotkey=nil
  SIDE_OPTION_KEYS.quick_hm_gamepad=nil
  SIDE_OPTION_KEYS.encounter_hotkey=nil
  SIDE_OPTION_KEYS.encounter_gamepad=nil
  SIDE_OPTION_KEYS.wild_pokemon=nil

  local MOD_MENU_TITLES={
    ["MOD OPTIONS"]=true,["MISC"]=true,["BATTLE OPTIONS"]=true,
    ["POKEMON OPTIONS"]=true,["CHEATS"]=true,["QUICK HM HOTKEY"]=true,
    ["ENCOUNTER HOTKEY"]=true,["KEYBOARD HOTKEY"]=true,
    ["CONTROLLER HOTKEY"]=true,["WILD POKEMON"]=true,
    ["MOVE EDITOR"]=true,["REPLACE MOVE"]=true,["AUTO SORT"]=true,
    ["QUICK HM"]=true,
  }
  local rawListMenuNew=mod.ui.ListMenu.new
  mod.ui.ListMenu.new=function(game,title,items,opts)
    local menu=rawListMenuNew(game,title,items,opts)
    local isModMenu=MOD_MENU_TITLES[tostring(title)]
      or tostring(title):match(" LV%.%d+$")~=nil
    if not isModMenu then return menu end
    menu.wrap=true
    local oldUpdate=menu.update
    menu.update=function(self,dt)
      local input=self.game and self.game.input
      local count=self.items and #self.items or 0
      if count>0 and input and input:wasPressed("up") and (self.index or 1)<=1 then
        self.index=count
        self.scroll=math.max(0,count-(tonumber(self.rows) or 7))
        return
      elseif count>0 and input and input:wasPressed("down") and (self.index or 1)>=count then
        self.index=1
        self.scroll=0
        return
      end
      local item=self.items and self.items[self.index or 1]
      local direction=input and input:wasPressed("left") and -1
        or input and input:wasPressed("right") and 1 or nil
      if direction and item and SIDE_OPTION_KEYS[item.value] and self.onChoose then
        menuCycleDirection=direction
        self.onChoose(item,self)
        menuCycleDirection=1
        return
      end
      return oldUpdate(self,dt)
    end
    return menu
  end

  -- Preserve the highlighted option when a settings screen is rebuilt.
  -- Values are more stable than row numbers because AUTO RUN can appear/disappear.
  local menuCursor = {}

  local function rememberCursor(screen, menu)
    if not screen or not menu then return end
    local item = menu.items and menu.items[menu.index or 1]
    menuCursor[screen] = {
      value = item and item.value or nil,
      index = tonumber(menu.index) or 1,
    }
  end

  local function restoreCursor(screen, menu)
    local state = menuCursor[screen]
    if not state or not menu or not menu.items or #menu.items == 0 then return menu end
    local idx
    if state.value ~= nil then
      for i, item in ipairs(menu.items) do
        if item.value == state.value then idx = i break end
      end
    end
    idx = idx or math.max(1, math.min(state.index or 1, #menu.items))
    menu.index = idx
    local rows = tonumber(menu.rows) or 7
    if idx > rows then menu.scroll = idx - rows else menu.scroll = 0 end
    return menu
  end

  local function refresh(menu, game, screen)
    rememberCursor(screen, menu)
    if menu and menu.close then menu:close()
    elseif game and game.stack then game.stack:pop() end
    mod.ui.push(game, screen)
  end

  local function pageAligned(menu)
    local oldUpdate=menu.update
    menu.update=function(self,dt)
      local input=self.game and self.game.input
      local direction
      if input and input:wasPressed("left") then
        direction=-1; self.mqolPageDir="left"; self.mqolPageFrames=0
      elseif input and input:wasPressed("right") then
        direction=1; self.mqolPageDir="right"; self.mqolPageFrames=0
      elseif self.mqolPageDir and input and input:isDown(self.mqolPageDir) then
        self.mqolPageFrames=(self.mqolPageFrames or 0)+1
        if self.mqolPageFrames>=18 and (self.mqolPageFrames-18)%6==0 then
          direction=self.mqolPageDir=="left" and -1 or 1
        end
      else
        self.mqolPageDir=nil; self.mqolPageFrames=0
      end
      if direction then
        self.index=math.max(1,math.min(#self.items,self.index+direction*self.rows))
        self.scroll=math.floor((self.index-1)/self.rows)*self.rows
        local enabled=self.pageJump; self.pageJump=false
        local held=self.holdDir; self.holdDir=nil
        oldUpdate(self,dt); self.pageJump=enabled
        self.holdDir=held
        return
      end
      return oldUpdate(self,dt)
    end
    return menu
  end

  local HM_MOVES = { CUT=true, FLY=true, SURF=true, STRENGTH=true, FLASH=true }

  local function moveName(game, id)
    if id == nil then return "EMPTY" end
    local def = game and game.data and game.data.moves and game.data.moves[id]
    if not def then def = mod.content.moves:get(id) end
    return (def and def.name) or tostring(id)
  end

  local function monName(game, mon)
    if not mon then return "UNKNOWN" end
    local def = game and game.data and game.data.pokemon and game.data.pokemon[mon.species]
    if not def then def = mod.content.pokemon:get(mon.species) end
    return (def and def.name) or mon.nickname or mon.species or "UNKNOWN"
  end

  local GEN1_TYPE_NAMES = {
    NORMAL="NORMAL", FIGHTING="FIGHTING", FLYING="FLYING", POISON="POISON",
    GROUND="GROUND", ROCK="ROCK", BUG="BUG", GHOST="GHOST", FIRE="FIRE",
    WATER="WATER", GRASS="GRASS", ELECTRIC="ELECTRIC", PSYCHIC="PSYCHIC",
    ICE="ICE", DRAGON="DRAGON",
  }

  local function typeName(game, raw)
    if raw == nil then return "--" end
    if type(raw) == "table" then
      local v = raw.name or raw.id or raw.key or raw.type
      if v ~= nil then return typeName(game, v) end
      return "--"
    end
    local key = tostring(raw):upper():gsub("[%s%-]", "_")
    if GEN1_TYPE_NAMES[key] then return GEN1_TYPE_NAMES[key] end
    -- Some builds store a type id and expose the display name separately.
    local data = game and game.data
    local types = data and (data.types or data.type)
    local tdef = types and (types[raw] or types[key])
    if type(tdef) == "table" then
      local name = tdef.name or tdef.id or tdef.key
      if name then return tostring(name):upper() end
    elseif tdef ~= nil then
      return tostring(tdef):upper()
    end
    return tostring(raw):upper()
  end

  local function moveInfo(game, id)
    local def = game and game.data and game.data.moves and game.data.moves[id]
    if not def then def = mod.content.moves:get(id) end
    if not def then return "--  PP--\nPWR-- ACC--" end
    local moveType=def.type or def.moveType or def.typeId or def.type_id
    local power=def.power
    local accuracy=def.accuracy
    if get("type_fixes") then
      if id=="KARATE_CHOP" then moveType="FIGHTING"
      elseif id=="SAND_ATTACK" then moveType="GROUND"
      elseif id=="GUST" then moveType="FLYING"
      elseif id=="LICK" then moveType="GHOST"; power=40
      elseif id=="LOW_KICK" then power=60
      elseif id=="SUBMISSION" then accuracy=90 end
    end
    local typ = typeName(game, moveType)
    -- Some data tables expose display strings such as "PSYCHIC TYPE".
    -- The footer already represents the Type field, so keep only the type name.
    typ = tostring(typ):gsub("[%s_%-]*TYPE$", "")
    if typ == "" then typ = "--" end
    local pp = tostring(def.pp or def.basePP or "--")
    local pwr = tonumber(power)
    local acc = tonumber(accuracy)
    local pwrText = (pwr and pwr > 0) and tostring(math.floor(pwr + 0.5)) or "--"
    local accText
    if not acc then accText = "--"
    elseif acc <= 1 then accText = tostring(math.floor(acc * 100 + 0.5))
    else accText = tostring(math.floor(acc + 0.5)) end
    -- Numeric fields first keep navigation visually stable when type names vary in width.
    -- Requested order: Power, Accuracy, PP, Type.
    return ("PWR%s ACC%s\nPP%s %s"):format(pwrText, accText, pp, typ)
  end

  -- BASE = Gen 1 learnset/TM legality. The loaded recomp tables are Gen 1;
  -- if a build exposes per-version variants, merge those too.
  local function addLearnset(set, def)
    if type(def) ~= "table" then return end
    for _, id in ipairs(def.level1Moves or {}) do set[id] = true end
    for _, row in ipairs(def.learnset or {}) do if row.move then set[row.move] = true end end
    for _, id in ipairs(def.tmhm or {}) do if not HM_MOVES[id] then set[id] = true end end
  end

  local function addNaturalMoves(set,def)
    if type(def)~="table" then return end
    for _,id in ipairs(def.level1Moves or {}) do set[id]=true end
    for _,row in ipairs(def.learnset or {}) do
      local id=type(row)=="table" and (row.move or row.id) or row
      if id then set[id]=true end
    end
  end

  local function addPreEvolutionMoves(set,pokemon,speciesId,seen)
    if type(pokemon)~="table" or not speciesId then return end
    seen=seen or {}
    if seen[speciesId] then return end
    seen[speciesId]=true
    for candidateId,candidate in pairs(pokemon) do
      if type(candidate)=="table" then
        for _,evolution in ipairs(candidate.evolutions or {}) do
          local target=type(evolution)=="table" and (evolution.species or evolution.into)
          if target==speciesId then
            addNaturalMoves(set,candidate)
            addPreEvolutionMoves(set,pokemon,candidateId,seen)
          end
        end
      end
    end
  end

  local function baseMoves(game, mon)
    local set = {}
    local data = game and game.data
    if not data or not data.pokemon or not mon then return set end
    addLearnset(set, data.pokemon[mon.species])
    addPreEvolutionMoves(set,data.pokemon,mon.species)
    -- Forward-compatible probes for caches/builds exposing R/B/Y side tables.
    local candidates = {
      data.pokemon_red, data.pokemon_blue, data.pokemon_yellow,
      data.red and data.red.pokemon, data.blue and data.blue.pokemon,
      data.yellow and data.yellow.pokemon,
      data.versions and data.versions.red and data.versions.red.pokemon,
      data.versions and data.versions.blue and data.versions.blue.pokemon,
      data.versions and data.versions.yellow and data.versions.yellow.pokemon,
    }
    for _, tbl in ipairs(candidates) do
      if type(tbl) == "table" then
        addLearnset(set, tbl[mon.species])
        addPreEvolutionMoves(set,tbl,mon.species)
      end
    end
    for id in pairs(HM_MOVES) do set[id] = nil end
    return set
  end

  -- ---------------- options screens ----------------
  mod.content.screens:register(MAIN_SCREEN, {
    new = function(game)
      local items = {
        { label="BATTLE OPTIONS", value="battle" },
        { label="POKEMON", value="pokemon" },
        { label="MISC", value="misc" },
        { label="CHEATS", value="cheats" },
        { label="RESET DEFAULT ALL", value="reset_all" },
      }
      local menu = mod.ui.ListMenu.new(game, "MOD OPTIONS", items, {
        pageJump=true,
        onChoose=function(item, menu)
          if not item then return end
          if item.value == "battle" then mod.ui.push(game,BATTLE_SCREEN)
          elseif item.value == "pokemon" then mod.ui.push(game,POKEMON_SCREEN)
          elseif item.value == "misc" then mod.ui.push(game,MISC_SCREEN)
          elseif item.value == "cheats" then mod.ui.push(game,CHEATS_SCREEN)
          elseif item.value == "reset_all" then
            confirmReset(game,"Reset ALL options\nto defaults?",function()
              resetAll(game)
              refresh(menu,game,MAIN_SCREEN)
            end)
          end
        end,
      })
      return restoreCursor(MAIN_SCREEN, menu)
    end,
  })

  mod.content.screens:register(MISC_SCREEN, {
    new = function(game)
      local items = {
        { label="FAST RUN", right=tostring(get("fast_run")), value="fast_run" },
      }
      if get("fast_run") ~= "OFF" then
        items[#items+1] = { label="AUTO RUN", right=boolText(get("auto_run")), value="auto_run" }
      end
      items[#items+1] = { label="INSTANT TEXT", right=boolText(get("instant_text")), value="instant_text" }
      items[#items+1] = { label="ITEMFINDER", right=tostring(get("itemfinder")), value="itemfinder" }
      items[#items+1] = { label="TYPE FIXES", right=boolText(get("type_fixes")), value="type_fixes" }
      items[#items+1] = { label="FAST CENTER", right=boolText(get("fast_center")), value="fast_center" }
      items[#items+1] = { label="FAST SAVE", right=boolText(get("fast_save")), value="fast_save" }
      items[#items+1] = { label="RESET DEFAULTS", value="reset" }
      local menu = mod.ui.ListMenu.new(game, "MISC", items, {
        pageJump=true,
        onChoose=function(item, menu)
          if not item then return end
          if item.value == "fast_run" then cycle(game,"fast_run",{"OFF","ON","ON+SURF"})
          elseif item.value == "auto_run" then toggle(game,"auto_run")
          elseif item.value == "instant_text" then toggle(game,"instant_text")
          elseif item.value == "itemfinder" then cycle(game,"itemfinder",{"OFF","ON","HAVE ITEM"})
          elseif item.value == "type_fixes" then toggle(game,"type_fixes")
          elseif item.value == "fast_center" then toggle(game,"fast_center")
          elseif item.value == "fast_save" then toggle(game,"fast_save")
          elseif item.value == "reset" then
            confirmReset(game,"Reset MISC options\nto defaults?",function()
              resetKeys(game,MISC_KEYS)
              refresh(menu,game,MISC_SCREEN)
            end)
            return
          end
          refresh(menu,game,MISC_SCREEN)
        end,
      })
      return restoreCursor(MISC_SCREEN, menu)
    end,
  })

  mod.content.screens:register(BATTLE_SCREEN, {
    new = function(game)
      local items = {
        {label="EXP SHARE", right=(get("exp_share")=="ACTIVE" and "GEN1" or tostring(get("exp_share"))), value="exp_share"},
        {label="MOVE INFO", right=boolText(get("move_info")), value="move_info"},
        {label="RESET DEFAULTS", value="reset"},
      }
      local menu = mod.ui.ListMenu.new(game,"BATTLE OPTIONS",items,{
        onChoose=function(item,menu)
          if item.value == "exp_share" then cycle(game,"exp_share",{"OFF","ACTIVE","SMART"})
          elseif item.value == "reset" then
            confirmReset(game,"Reset BATTLE options\nto defaults?",function()
              resetKeys(game,BATTLE_KEYS)
              refresh(menu,game,BATTLE_SCREEN)
            end)
            return
          else toggle(game,item.value) end
          refresh(menu,game,BATTLE_SCREEN)
        end,
      })
      return restoreCursor(BATTLE_SCREEN, menu)
    end,
  })

  mod.content.screens:register(POKEMON_SCREEN, {
    new = function(game)
      local items = {
        {label="FORGET HM", right=boolText(get("forget_hm")), value="forget_hm"},
        {label="REUSABLE TMS", right=boolText(get("unlimited_tm")), value="unlimited_tm"},
        {label="QUICK HM", right=tostring(get("quick_hm")), value="quick_hm"},
        {label="MAX DV", right=boolText(get("max_dv")), value="max_dv"},
      }
      if get("quick_hm")~="OFF" then
        items[#items+1]={label="HM HOTKEY",right=hotkeyText(get("quick_hm_hotkey")),value="quick_hm_hotkey"}
      end
      items[#items+1]={label="PIKACHU EVO", right=boolText(get("pikachu_evo")), value="pikachu_evo"}
      items[#items+1]={label="RESET DEFAULTS", value="reset"}
      local menu = mod.ui.ListMenu.new(game,"POKEMON OPTIONS",items,{
        onChoose=function(item,menu)
          if item.value == "quick_hm" then cycle(game,"quick_hm",{"OFF","ON","IGNORE"})
          elseif item.value == "quick_hm_hotkey" then
            mod.ui.push(game,QUICK_HM_HOTKEY_SCREEN)
            return
          elseif item.value == "reset" then
            confirmReset(game,"Reset POKEMON options\nto defaults?",function()
              resetKeys(game,POKEMON_KEYS)
              refresh(menu,game,POKEMON_SCREEN)
            end)
            return
          else toggle(game,item.value) end
          refresh(menu,game,POKEMON_SCREEN)
        end,
      })
      return restoreCursor(POKEMON_SCREEN, menu)
    end,
  })

  mod.content.screens:register(QUICK_HM_HOTKEY_SCREEN, {
    new=function(game)
      local items={
        {label="KEYBOARD",right=hotkeyText(get("quick_hm_hotkey")),value="keyboard"},
        {label="CONTROLLER",right=gamepadText(get("quick_hm_gamepad")),value="controller"},
      }
      if get("quick_hm_gamepad")~="OFF" then
        items[#items+1]={label="DISABLE CONTROLLER",value="disable_controller"}
      end
      local menu
      menu=mod.ui.ListMenu.new(game,"QUICK HM HOTKEY",items,{
        onChoose=function(item)
          if not item then return end
          if item.value=="keyboard" then
            mod.ui.push(game,QUICK_HM_KEY_CAPTURE_SCREEN)
          elseif item.value=="controller" then
            mod.ui.push(game,QUICK_HM_PAD_CAPTURE_SCREEN)
          elseif item.value=="disable_controller" then
            set(game,"quick_hm_gamepad","OFF")
            refresh(menu,game,QUICK_HM_HOTKEY_SCREEN)
          end
        end,
      })
      return menu
    end,
  })

  mod.content.screens:register(QUICK_HM_KEY_CAPTURE_SCREEN, {
    new=function(game)
      local menu=mod.ui.ListMenu.new(game,"KEYBOARD HOTKEY",{
        {label="PRESS A KEY"},
        {label="ESC TO CANCEL"},
      },{rows=2})
      menu.onKeyPressed=function(self,key)
        if key=="escape" or key=="backspace" then
          game.stack:pop()
          return
        end
        if key=="lshift" or key=="rshift" then key="shift" end
        if BLOCKED_HOTKEYS[key] then
          self.items[1].label="KEY NOT AVAILABLE"
          return
        end
        set(game,"quick_hm_hotkey",key)
        game.stack:pop()
        local parent=game.stack:top()
        refresh(parent,game,QUICK_HM_HOTKEY_SCREEN)
      end
      return menu
    end,
  })

  mod.content.screens:register(QUICK_HM_PAD_CAPTURE_SCREEN, {
    new=function(game)
      local menu=mod.ui.ListMenu.new(game,"CONTROLLER HOTKEY",{
        {label="PRESS A BUTTON"},
        {label="B TO CANCEL"},
      },{rows=2})
      menu.quickHMHotkeyCapture=true
      local function capture(self,button)
        if button=="b" then game.stack:pop() return end
        if BLOCKED_PAD_HOTKEYS[button] then
          self.items[1].label="BUTTON NOT AVAILABLE"
          return
        end
        set(game,"quick_hm_gamepad",button)
        game.stack:pop()
        local parent=game.stack:top()
        refresh(parent,game,QUICK_HM_HOTKEY_SCREEN)
      end
      menu.onGamepadPressed=function(self,button) capture(self,button) end
      menu.onJoystickPressed=function(self,button) capture(self,"joy:"..tostring(button)) end
      menu.onGamepadAxis=function(self,axis,value)
        if value<0.65 then return end
        local button=axis=="triggerleft" and "lefttrigger"
          or axis=="triggerright" and "righttrigger" or nil
        if button then capture(self,button) end
      end
      return menu
    end,
  })

  mod.content.screens:register(CHEATS_SCREEN, {
    new = function(game)
      local items = {
        {label="NEVER MISS", right=boolText(get("never_miss")), value="never_miss"},
        {label="ALWAYS CRIT", right=boolText(get("always_crit")), value="always_crit"},
        {label="INFINITE PP", right=boolText(get("infinite_pp")), value="infinite_pp"},
        {label="ALWAYS CATCH", right=boolText(get("always_catch")), value="always_catch"},
        {label="EXP MULTIPLIER", right=tostring(get("exp_multiplier")), value="exp_multiplier"},
        {label="GAME CORNER", right=tostring(get("game_corner_multiplier")), value="game_corner_multiplier"},
        {label="CHALLENGE MODE", right=tostring(get("challenge_mode")), value="challenge_mode"},
        {label="MOVE EDITOR", right=tostring(get("move_editor")), value="move_editor"},
        {label="FORCE ENCOUNTER", right=tostring(get("force_encounter")), value="force_encounter"},
      }
      if get("force_encounter")~="OFF" then
        items[#items+1]={label="ENCOUNTER HOTKEY",right=hotkeyText(get("encounter_hotkey")),value="encounter_hotkey"}
      end
      items[#items+1]={label="WILD SELECT",right=tostring(get("wild_select")),value="wild_select"}
      if get("wild_select")~="OFF" then
        local species=mod.content.pokemon:get(get("wild_pokemon"))
        items[#items+1]={label="WILD POKEMON",right=(species and species.name) or tostring(get("wild_pokemon")),value="wild_pokemon"}
      end
      items[#items+1]={label="RESET DEFAULTS",value="reset"}
      local menu = mod.ui.ListMenu.new(game,"CHEATS",items,{
        onChoose=function(item,menu)
          if item.value == "move_editor" then
            cycle(game,"move_editor",{"TODOS","BASE","OFF"})
          elseif item.value == "exp_multiplier" then
            cycle(game,"exp_multiplier",{"OFF","1.5X","2X","3X","4X"})
          elseif item.value == "game_corner_multiplier" then
            cycle(game,"game_corner_multiplier",{"OFF","2X","3X","5X","10X"})
          elseif item.value == "challenge_mode" then
            cycle(game,"challenge_mode",CHALLENGE_VALUES)
          elseif item.value == "encounter_hotkey" then
            mod.ui.push(game,ENCOUNTER_HOTKEY_SCREEN)
            return
          elseif item.value == "wild_pokemon" then
            mod.ui.push(game,WILD_POKEMON_SCREEN)
            return
          elseif item.value == "wild_select" then
            cycle(game,"wild_select",{"OFF","ON"})
          elseif item.value == "force_encounter" then
            cycle(game,"force_encounter",{"OFF","ON","FIRST"})
          elseif item.value == "reset" then
            confirmReset(game,"Reset CHEATS options\nto defaults?",function()
              resetKeys(game,CHEAT_KEYS)
              refresh(menu,game,CHEATS_SCREEN)
            end)
            return
          else
            toggle(game,item.value)
          end
          refresh(menu,game,CHEATS_SCREEN)
        end,
      })
      return restoreCursor(CHEATS_SCREEN, menu)
    end,
  })

  mod.content.screens:register(WILD_POKEMON_SCREEN, { new=function(game)
    local rows={}
    for id,def in mod.content.pokemon:each() do
      local dex=tonumber(def and def.dex)
      if dex and dex>=1 and dex<=151 then
        rows[#rows+1]={id=id,name=(def and def.name) or tostring(id),index=dex}
      end
    end
    table.sort(rows,function(a,b) if a.index==b.index then return a.name<b.name end return a.index<b.index end)
    local items={}
    for _,row in ipairs(rows) do items[#items+1]={label=row.name,right=(row.id==get("wild_pokemon") and "SELECTED" or nil),value=row.id} end
    local menu=mod.ui.ListMenu.new(game,"WILD POKEMON",items,{rows=7,pageJump=true,keyRepeat=true,onChoose=function(item)
      if not item then return end
      set(game,"wild_pokemon",item.value)
      game.stack:pop()
      local parent=game.stack:top()
      refresh(parent,game,CHEATS_SCREEN)
    end})
    return pageAligned(menu)
  end})

  mod.content.screens:register(ENCOUNTER_HOTKEY_SCREEN, { new=function(game)
    local items={{label="KEYBOARD",right=hotkeyText(get("encounter_hotkey")),value="keyboard"},
      {label="CONTROLLER",right=gamepadText(get("encounter_gamepad")),value="controller"}}
    if get("encounter_gamepad")~="OFF" then items[#items+1]={label="DISABLE CONTROLLER",value="disable"} end
    local menu
    menu=mod.ui.ListMenu.new(game,"ENCOUNTER HOTKEY",items,{onChoose=function(item)
      if item.value=="keyboard" then mod.ui.push(game,ENCOUNTER_KEY_CAPTURE_SCREEN)
      elseif item.value=="controller" then mod.ui.push(game,ENCOUNTER_PAD_CAPTURE_SCREEN)
      else set(game,"encounter_gamepad","OFF"); refresh(menu,game,ENCOUNTER_HOTKEY_SCREEN) end
    end})
    return menu
  end})

  mod.content.screens:register(ENCOUNTER_KEY_CAPTURE_SCREEN, { new=function(game)
    local menu=mod.ui.ListMenu.new(game,"KEYBOARD HOTKEY",{{label="PRESS A KEY"},{label="ESC TO CANCEL"}},{rows=2})
    menu.onKeyPressed=function(self,key)
      if key=="escape" or key=="backspace" then game.stack:pop(); return end
      if key=="lshift" or key=="rshift" then key="shift" end
      if BLOCKED_HOTKEYS[key] then self.items[1].label="KEY NOT AVAILABLE"; return end
      set(game,"encounter_hotkey",key); game.stack:pop(); local parent=game.stack:top(); refresh(parent,game,ENCOUNTER_HOTKEY_SCREEN)
    end
    return menu
  end})

  mod.content.screens:register(ENCOUNTER_PAD_CAPTURE_SCREEN, { new=function(game)
    local menu=mod.ui.ListMenu.new(game,"CONTROLLER HOTKEY",{{label="PRESS A BUTTON"},{label="B TO CANCEL"}},{rows=2})
    menu.encounterHotkeyCapture=true
    local function capture(self,button)
      if button=="b" then game.stack:pop(); return end
      if BLOCKED_PAD_HOTKEYS[button] then self.items[1].label="BUTTON NOT AVAILABLE"; return end
      set(game,"encounter_gamepad",button); game.stack:pop(); local parent=game.stack:top(); refresh(parent,game,ENCOUNTER_HOTKEY_SCREEN)
    end
    menu.onGamepadPressed=function(self,button) capture(self,button) end
    menu.onJoystickPressed=function(self,button) capture(self,"joy:"..tostring(button)) end
    menu.onGamepadAxis=function(self,axis,value)
      if value<0.65 then return end
      local button=axis=="triggerleft" and "lefttrigger" or axis=="triggerright" and "righttrigger" or nil
      if button then capture(self,button) end
    end
    return menu
  end})

  mod.hooks:wrap("ui.start_menu.items", function(next, game, items)
    local out = next(game, items)
    if type(out) ~= "table" then return out end
    if get("fast_save") then
      for _, row in ipairs(out) do
        if row and row.label == "SAVE" then
          row.onSelect=function()
            game:writeSave()
            require("src.core.Sound").play(game.data,"Save")
          end
          break
        end
      end
    end
    return out
  end)

  -- Keep START focused on gameplay. The mod's configuration lives in the
  -- native OPTIONS menu alongside the engine's own settings.
  mod.hooks:wrap("ui.options.rows", function(next,game,rows)
    local out=next(game,rows)
    if type(out)~="table" then return out end
    out[#out+1]={
      id="my_quality_of_life",
      label="myQualityOfLife",
      activate=function(g) mod.ui.push(g,MAIN_SCREEN) end,
    }
    return out
  end)

  -- Configurable keyboard/controller shortcuts. They claim the configured
  -- input only during free overworld control; everywhere else the engine
  -- receives its normal input.
  local Game=require("src.core.Game")
  local quickHMContextAction
  local function areaEncounterChoices(game)
    local ow=game.overworld
    local top=game.stack and game.stack:top()
    local busy=not ow or top~=ow or ow.transitioning
      or (ow.runner and ow.runner.isRunning and ow.runner:isRunning())
      or (ow.scriptMoves and #ow.scriptMoves>0) or ow.engaging or ow.emote
    if busy or not game.save or not game.save.party or #game.save.party==0 then return nil end
    local map,p=ow.map,ow.player
    local encDef=map and game.data.encounters[map.id]
    if not (map and p) then return nil end
    local tableDefs,terrain={},nil
    if p.surfing and map:isWaterCell(p.cellX,p.cellY) then
      terrain="WATER"
      if encDef and encDef.water and encDef.water.slots
          and (tonumber(encDef.water.rate) or 0)>0 then
        tableDefs[#tableDefs+1]=encDef.water.slots
      end
      -- On water, show every species catchable on this map: Surf plus all
      -- three fishing rods. Duplicate species are merged below.
      local FieldDefaults=require("src.world.FieldDefaults")
      local fishing=FieldDefaults.field(game.data,"fishing") or {}
      for _,rod in ipairs({"OLD_ROD","GOOD_ROD","SUPER_ROD"}) do
        local def=fishing[rod]
        local pool
        if def then
          if def.always then pool={def.always}
          elseif def.pool then pool=def.pool
          elseif def.perMap then
            local groups=game.data.field and game.data.field[def.perMap]
            pool=groups and groups[map.id]
          end
        end
        if pool then tableDefs[#tableDefs+1]=pool end
      end
    elseif encDef and map:isGrassCell(p.cellX,p.cellY) then
      if encDef.grass and encDef.grass.slots
          and (tonumber(encDef.grass.rate) or 0)>0 then
        tableDefs[1]=encDef.grass.slots
      end
      terrain="GRASS"
    else
      local indoor=game.data.field.indoorEncounters
      if encDef and indoor and map.def.index>=indoor.firstIndoorMap
          and map.def.tileset~=indoor.excludedTileset
          and encDef.grass and encDef.grass.slots
          and (tonumber(encDef.grass.rate) or 0)>0 then
        tableDefs[1]=encDef.grass.slots
        terrain="CAVE"
      end
    end
    if #tableDefs==0 then return nil end
    local choices,bySpecies={},{}
    for _,slots in ipairs(tableDefs) do
      for _,slot in ipairs(slots or {}) do
        if slot and slot.species then
          local row=bySpecies[slot.species]
          if not row then
            local def=mod.content.pokemon:get(slot.species)
            row={species=slot.species,name=(def and def.name) or tostring(slot.species),levels={}}
            bySpecies[slot.species]=row
            choices[#choices+1]=row
          end
          row.levels[#row.levels+1]=tonumber(slot.level) or 5
        end
      end
    end
    return #choices>0 and choices or nil,terrain
  end

  local function beginForcedEncounter(game,choice)
    local ow=game.overworld
    if not (ow and choice and choice.species) then return false end
    local lead=game.save and game.save.party and game.save.party[1]
    local levels=choice.levels or {}
    local level=levels[#levels>0 and love.math.random(#levels) or 1] or 5
    if get("force_encounter")=="FIRST" then
      level=math.max(2,math.min(100,tonumber(lead and lead.level) or tonumber(level) or 5))
    end
    local challenge=tostring(get("challenge_mode") or "OFF")
    if challenge~="OFF" then
      local highest=1
      for _,mon in ipairs((game.save and game.save.party) or {}) do
        highest=math.max(highest,tonumber(mon.level) or 1)
      end
      local bonus=tonumber(challenge:match("^%+(%d+)$")) or 0
      level=math.min(100,highest+bonus)
    end
    local BattleState=require("src.battle.BattleState")
    local battle=BattleState.newWild(game,choice.species,level)
    if not battle then return false end
    battle.checkpointOrigin={kind="forced_wild_encounter",map=ow.map and ow.map.id}
    battle.onFinish=function(result) ow:afterBattle(result,battle) end
    ow:pushBattle(battle)
    return true
  end

  local function forceWildEncounter(game)
    if get("force_encounter")=="OFF" then return false end
    local choices,terrain=areaEncounterChoices(game)
    if not choices then return false end
    if tostring(get("wild_select") or "OFF")=="ON" then
      local species=tostring(get("wild_pokemon") or "RATTATA")
      if not mod.content.pokemon:get(species) then return false end
      local levels={}
      for _,choice in ipairs(choices) do
        for _,level in ipairs(choice.levels or {}) do levels[#levels+1]=level end
      end
      return beginForcedEncounter(game,{species=species,levels=levels})
    end
    local items={}
    for _,choice in ipairs(choices) do items[#items+1]={label=choice.name,value=choice} end
    local rows=math.min(6,#items)
    local menu=mod.ui.ListMenu.new(game,terrain.." POKEMON",items,{
      rows=rows,wrap=true,
      onChoose=function(item,self)
        if not (item and item.value) then return end
        if self and self.close then self:close() else game.stack:pop() end
        beginForcedEncounter(game,item.value)
      end,
    })
    menu.isOpaque=false
    menu.draw=function(self)
      local Font=require("src.render.Font")
      local Theme=require("src.ui.Theme")
      local Strings=require("src.core.Strings")
      local height=math.min(17,4+self.rows*2)
      love.graphics.setColor(1,1,1,1)
      Font.drawBox(6,0,14,height)
      love.graphics.setColor(0,0,0,1)
      Font.draw(Strings(self.title),64,8)
      for row=1,self.rows do
        local index=self.scroll+row
        local item=self.items[index]
        if not item then break end
        local y=24+(row-1)*16
        Font.draw(item.label,72,y)
        if index==self.index then Font.drawCode(Theme.cursor,64,y) end
      end
    end
    game.stack:push(menu)
    return true
  end

  mod.hooks:wrap("encounter.species",function(next,enc,ctx)
    local out=next(enc,ctx)
    local challenge=tostring(get("challenge_mode") or "OFF")
    if not out or challenge=="OFF" then return out end
    local copy={}
    for key,value in pairs(out) do copy[key]=value end
    if challenge~="OFF" then
      local highest=1
      for _,mon in ipairs((Game.save and Game.save.party) or {}) do highest=math.max(highest,tonumber(mon.level) or 1) end
      local bonus=tonumber(challenge:match("^%+(%d+)$")) or 0
      copy.level=math.min(100,highest+bonus)
    end
    return copy
  end)

  mod.hooks:wrap("trainer.party",function(next,trainerClass,partyIndex,party)
    local out=next(trainerClass,partyIndex,party)
    local challenge=tostring(get("challenge_mode") or "OFF")
    if challenge=="OFF" or type(out)~="table" then return out end
    local highest=1
    for _,mon in ipairs((Game.save and Game.save.party) or {}) do
      highest=math.max(highest,tonumber(mon.level) or 1)
    end
    local bonus=tonumber(challenge:match("^%+(%d+)$")) or 0
    local target=math.min(100,highest+bonus)
    local scaled={}
    for index,slot in ipairs(out) do
      local copy={}
      for key,value in pairs(slot) do copy[key]=value end
      copy.level=math.max(tonumber(copy.level) or 1,target)
      scaled[index]=copy
    end
    return scaled
  end)

  local function openQuickHMFromHotkey(game)
    if get("quick_hm")=="OFF" then return false end
    local ow=game.overworld
    local top=game.stack and game.stack:top()
    local busy=not ow or top~=ow or ow.transitioning
      or (ow.runner and ow.runner.isRunning and ow.runner:isRunning())
      or (ow.scriptMoves and #ow.scriptMoves>0)
      or ow.engaging or ow.emote
    if busy then return false end
    if quickHMContextAction and quickHMContextAction(game) then return true end
    mod.ui.push(game,QUICK_HM_SCREEN)
    return true
  end

  local oldGameKeyPressed=Game.keypressed
  Game.keypressed=function(self,key)
    local encounterKey=tostring(get("encounter_hotkey") or "f6")
    local encounterMatches=(encounterKey=="shift" and (key=="lshift" or key=="rshift")) or key==encounterKey
    if encounterMatches and forceWildEncounter(self) then return end
    local configured=tostring(get("quick_hm_hotkey") or "shift")
    local matches=(configured=="shift" and (key=="lshift" or key=="rshift"))
                  or key==configured
    if matches and openQuickHMFromHotkey(self) then return end
    return oldGameKeyPressed(self,key)
  end

  local oldGamepadPressed=Game.gamepadpressed
  Game.gamepadpressed=function(self,joystick,button)
    local top=self.stack and self.stack:top()
    -- Capture before the engine reserves shoulders/triggers for game speed.
    if top and top.quickHMHotkeyCapture and top.onGamepadPressed then
      top:onGamepadPressed(button)
      return
    end
    if top and top.encounterHotkeyCapture and top.onGamepadPressed then
      top:onGamepadPressed(button)
      return
    end
    local encounterPad=tostring(get("encounter_gamepad") or "OFF")
    if encounterPad~="OFF" and button==encounterPad and forceWildEncounter(self) then return end
    local configured=tostring(get("quick_hm_gamepad") or "OFF")
    if configured~="OFF" and button==configured
       and openQuickHMFromHotkey(self) then return end
    return oldGamepadPressed(self,joystick,button)
  end

  local oldJoystickPressed=Game.joystickpressed
  Game.joystickpressed=function(self,joystick,button)
    local recognized=false
    if joystick and joystick.isGamepad then
      local ok,value=pcall(joystick.isGamepad,joystick)
      recognized=ok and value==true
    end
    local top=self.stack and self.stack:top()
    if not recognized and top and top.quickHMHotkeyCapture
       and top.onJoystickPressed then
      top:onJoystickPressed(button)
      return
    end
    if not recognized and top and top.encounterHotkeyCapture and top.onJoystickPressed then
      top:onJoystickPressed(button)
      return
    end
    if not recognized and tostring(get("encounter_gamepad") or "OFF")==("joy:"..tostring(button))
       and forceWildEncounter(self) then return end
    local configured=tostring(get("quick_hm_gamepad") or "OFF")
    if not recognized and configured==("joy:"..tostring(button))
       and openQuickHMFromHotkey(self) then return end
    return oldJoystickPressed(self,joystick,button)
  end


  -- Controllers that expose LT/RT only as analog axes never raise
  -- gamepadpressed. Capture and use those axes with the same canonical names
  -- as controllers that report them as lefttrigger/righttrigger buttons.
  local oldGamepadAxis=Game.gamepadaxis
  Game.gamepadaxis=function(self,joystick,axis,value)
    local top=self.stack and self.stack:top()
    if top and top.quickHMHotkeyCapture and top.onGamepadAxis then
      top:onGamepadAxis(axis,value)
      return
    end
    if top and top.encounterHotkeyCapture and top.onGamepadAxis then
      top:onGamepadAxis(axis,value)
      return
    end
    local button=axis=="triggerleft" and "lefttrigger"
      or axis=="triggerright" and "righttrigger" or nil
    self.mqolQuickHMAxisLatch=self.mqolQuickHMAxisLatch or {}
    self.mqolEncounterAxisLatch=self.mqolEncounterAxisLatch or {}
    if button then
      if value<=0.35 then self.mqolEncounterAxisLatch[axis]=false end
      if tostring(get("encounter_gamepad") or "OFF")==button and value>=0.65
         and not self.mqolEncounterAxisLatch[axis] then
        self.mqolEncounterAxisLatch[axis]=true
        if forceWildEncounter(self) then return end
      end
      if value<=0.35 then self.mqolQuickHMAxisLatch[axis]=false end
      local down=value>=0.65
      if tostring(get("quick_hm_gamepad") or "OFF")==button and down
         and not self.mqolQuickHMAxisLatch[axis] then
        self.mqolQuickHMAxisLatch[axis]=true
        if openQuickHMFromHotkey(self) then return end
      end
    end
    return oldGamepadAxis(self,joystick,axis,value)
  end

  -- ---------------- Move Editor (stable v1.1 behavior + filters/info) ----------------
  mod.content.screens:register(MOVE_SCREEN, {
    new=function(game)
      local mon = target and target.mon
      if not mon then return mod.ui.ListMenu.new(game,"MOVE EDITOR",{{label="NO POKEMON SELECTED"}}) end
      local items = {}
      for slot=1,4 do
        local mv = (mon.moves or {})[slot]
        items[#items+1] = {label=("SLOT %d  %s"):format(slot,moveName(game,mv and mv.id)),value=slot}
      end
      return mod.ui.ListMenu.new(game,("%s  LV.%d"):format(monName(game,mon),mon.level or 0),items,{
        onChoose=function(item)
          if not item or not item.value then return end
          targetSlot=item.value
          mod.ui.push(game,PICK_SCREEN)
        end,
      })
    end,
  })

  mod.content.screens:register(PICK_SCREEN, {
    new=function(game)
      local mon, slot = target and target.mon, targetSlot
      if not mon or not slot then return mod.ui.ListMenu.new(game,"CHOOSE MOVE",{{label="NOT AVAILABLE"}}) end
      local allowed = get("move_editor") == "BASE" and baseMoves(game,mon) or nil
      local rows = {}
      for id, def in mod.content.moves:each() do
        if (not allowed or allowed[id]) and (get("move_editor") ~= "BASE" or not HM_MOVES[id]) then
          rows[#rows+1] = {id=id,name=(def and def.name) or tostring(id)}
        end
      end
      table.sort(rows,function(a,b) if a.name==b.name then return tostring(a.id)<tostring(b.id) end return a.name<b.name end)
      local items={}
      for _,row in ipairs(rows) do items[#items+1]={label=row.name,value=row.id} end
      local menu
      menu = mod.ui.ListMenu.new(game,"REPLACE MOVE",items,{
        rows=5,
        pageJump=true,
        keyRepeat=true,
        footer=(items[1] and moveInfo(game,items[1].value)) or "NO MOVES AVAILABLE",
        onChoose=function(item,picker)
          local id=item and item.value
          if id==nil then return end
          local def=game.data and game.data.moves and game.data.moves[id]
          local basePP=def and tonumber(def.pp)
          mon.moves=mon.moves or {}
          local old=mon.moves[slot]
          if not old then old={id=id,pp=basePP or 0}; mon.moves[slot]=old
          else
            old.id=id
            if basePP then
              local ppUps=tonumber(old.ppUps) or 0
              old.pp=basePP + ppUps*math.floor(basePP/5)
            else old.pp=tonumber(old.pp) or 0 end
          end
          if picker and picker.close then picker:close() elseif game.stack then game.stack:pop() end
          if game.stack and game.stack.pop then game.stack:pop() end
          mod.ui.push(game,MOVE_SCREEN)
        end,
      })
      pageAligned(menu)
      local originalUpdate=menu.update
      menu.update=function(self,dt)
        originalUpdate(self,dt)
        local item=self.items[self.index]
        self.footer=item and moveInfo(game,item.value) or "NO MOVES AVAILABLE"
      end
      return menu
    end,
  })

  mod.hooks:wrap("ui.party.submenu", function(next, game, items, mon, ctx)
    local out=next(game,items,mon,ctx)
    if type(out)~="table" then out=items end
    if ctx and ctx.battle then return out end
    if get("move_editor") == "OFF" then return out end
    out[#out+1]={
      label="MOVE EDITOR",
      onSelect=function(selectedMon,selectedGame)
        target={mon=selectedMon,place="PARTY"}; targetSlot=nil
        if selectedGame and selectedGame.stack then selectedGame.stack:pop() end
        mod.ui.push(selectedGame,MOVE_SCREEN)
      end,
    }
    return out
  end)

  -- ---------------- battle toggles ----------------
  local function typeFixedMove(move)
    if not get("type_fixes") or not move then return move end
    local patch
    if move.id=="KARATE_CHOP" then patch={type="FIGHTING"}
    elseif move.id=="SAND_ATTACK" then patch={type="GROUND"}
    elseif move.id=="GUST" then patch={type="FLYING"}
    elseif move.id=="LICK" then patch={type="GHOST", power=40, category="special"}
    elseif move.id=="LOW_KICK" then patch={power=60}
    elseif move.id=="SUBMISSION" then patch={accuracy=90} end
    if not patch then return move end
    local copy={}
    for key,value in pairs(move) do copy[key]=value end
    for key,value in pairs(patch) do copy[key]=value end
    return copy
  end

  mod.hooks:wrap("battle.accuracy", function(next, ctx)
    if get("never_miss") and ctx and ctx.user and ctx.user.isPlayer then return true end
    if ctx and get("type_fixes") and ctx.move and ctx.move.id=="SUBMISSION" then
      local copy={}
      for key,value in pairs(ctx) do copy[key]=value end
      copy.move=typeFixedMove(ctx.move)
      return next(copy)
    end
    return next(ctx)
  end)

  mod.hooks:wrap("battle.damage", function(next, ctx)
    if not get("type_fixes") or not ctx or not ctx.move then return next(ctx) end
    local copy={}
    for key,value in pairs(ctx) do copy[key]=value end
    copy.move=typeFixedMove(ctx.move)

    -- Gen 1's chart accidentally makes Psychic immune to Ghost. Replace only
    -- that defending type for the duration of this calculation with Ghost,
    -- whose vanilla Ghost matchup is the intended 2x. This preserves STAB,
    -- critical hits, random damage, dual-type floors and effectiveness text.
    local target=copy.target
    local types=target and target.curTypes
    local correctedTypes
    if copy.move.type=="GHOST" and type(types)=="table" then
      for i,typeId in ipairs(types) do
        if typeId=="PSYCHIC_TYPE" then
          correctedTypes=correctedTypes or {}
          if #correctedTypes==0 then
            for j,value in ipairs(types) do correctedTypes[j]=value end
          end
          correctedTypes[i]="GHOST"
        end
      end
    end
    if not correctedTypes then return next(copy) end

    target.curTypes=correctedTypes
    local ok,damage,info=pcall(next,copy)
    target.curTypes=types
    if not ok then error(damage) end
    return damage,info
  end)

  mod.hooks:wrap("battle.crit", function(next, ctx)
    if get("always_crit") and ctx and ctx.attacker and ctx.attacker.isPlayer then return true end
    return next(ctx)
  end)

  mod.hooks:wrap("catch.rate", function(next, ball, mon, def, opts)
    if get("always_catch") then return true, 3 end
    return next(ball,mon,def,opts)
  end)

  mod.events:on("battle.move_used", function(ev)
    if not get("infinite_pp") then return end
    if not ev.user or not ev.user.isPlayer or ev.isCalled then return end
    local mon=ev.user.mon
    if not mon or not mon.moves then return end
    for _,move in ipairs(mon.moves) do
      if move.id==ev.move.id then
        local moveDef=ev.battle and ev.battle.data and ev.battle.data.moves[move.id]
        if moveDef then
          local ppUps=tonumber(move.ppUps) or 0
          move.pp=moveDef.pp + ppUps*math.floor(moveDef.pp/5)
        end
        break
      end
    end
  end)

  mod.events:on("pokemon.caught",function(ev)
    if not get("max_dv") or not ev or type(ev.mon)~="table" then return end
    local mon,game=ev.mon,ev.game
    local data=game and game.data
    local def=data and data.pokemon and data.pokemon[mon.species]
    if not def then return end
    local oldHp=tonumber(mon.hp)
    local oldMax=mon.stats and tonumber(mon.stats.hp)
    mon.dvs={hp=15,attack=15,defense=15,speed=15,special=15}
    local Stats=require("src.pokemon.Stats")
    mon.stats=Stats.calc(def,mon.level or 1,mon.dvs,mon.statExp)
    local newMax=mon.stats and tonumber(mon.stats.hp)
    if oldHp and oldMax and oldMax>0 and newMax then
      if oldHp<=0 then mon.hp=0
      else mon.hp=math.max(1,math.min(newMax,math.floor(oldHp*newMax/oldMax+0.5))) end
    end
  end)

  -- SMART may provide an exact per-mon award.  The optional cheat multiplier
  -- is applied once to that amount or to the engine's normal calculated gain.
  -- Experience.apply still owns stats, levels, move learning and battle text.
  mod.hooks:wrap("exp.gain", function(next, ctx)
    local v = ctx and ctx.mon and forcedExp[ctx.mon]
    local gained=v ~= nil and v or next(ctx)
    local setting=get("exp_multiplier")
    local multiplier=tonumber(tostring(setting):match("^(%d+%.?%d*)X$")) or 1
    return math.max(0,math.floor((tonumber(gained) or 0)*multiplier))
  end)

  local function eligibleNonParticipants(battle, participants)
    local out={}
    for _,mon in ipairs((battle and battle.game and battle.game.save and battle.game.save.party) or {}) do
      if not participants[mon] and (mon.hp or 0)>0 and (mon.level or 0)<100 then
        out[#out+1]=mon
      end
    end
    return out
  end

  local function smartAlloc(data, recipients, pool)
    local alloc={}
    pool=math.max(0,math.floor(pool or 0))
    if pool==0 or #recipients==0 then return alloc,0 end

    -- Snapshot the lowest level before any award is applied. A recipient that
    -- levels up during this award stays in the chosen group; already-higher
    -- Pokemon do not join midway just because the levels became equal.
    local minLevel=1000
    for _,mon in ipairs(recipients) do
      minLevel=math.min(minLevel,tonumber(mon.level) or 1)
      alloc[mon]=0
    end
    local group={}
    for _,mon in ipairs(recipients) do
      if (tonumber(mon.level) or 1)==minLevel then group[#group+1]=mon end
    end
    local each=math.floor(pool/#group)
    local rem=pool-each*#group
    for _,mon in ipairs(group) do
      alloc[mon]=each
    end
    return alloc,rem
  end

  local function equalAlloc(recipients,pool)
    local alloc={}
    pool=math.max(0,math.floor(pool or 0))
    if pool==0 or #recipients==0 then return alloc,0 end
    local each=math.floor(pool/#recipients)
    local rem=pool-each*#recipients
    for _,mon in ipairs(recipients) do alloc[mon]=each end
    return alloc,rem
  end

  -- Gen1Recomp 0.1.86 identifies traded Pokemon from the original trainer ID.
  -- Keep the legacy flag as a fallback for saves created before OT data existed.
  local function isTradedMon(battle,mon)
    if not mon then return false end
    local playerId=battle and battle.game and battle.game.save
      and battle.game.save.player and battle.game.save.player.id
    if mon.otId~=nil and playerId~=nil then return mon.otId~=playerId end
    return mon.traded==true and mon.otId==nil
  end

  local function sharedExpSummary(battle, awards, insertAfter)
    if not awards or #awards==0 or not battle or not battle.sayNext then return end
    -- Experience.apply queues level-up text immediately through sayNext. When
    -- the awards are only known after applying every share, temporarily restore
    -- the insertion cursor captured before those awards so this summary is
    -- displayed first, then advance it past every row already queued.
    local queuedThrough=battle.nextInsert
    if insertAfter~=nil then battle.nextInsert=insertAfter end
    local same=true
    local each=math.max(0,math.floor(awards[1].gained or 0))
    for i=2,#awards do
      if math.max(0,math.floor(awards[i].gained or 0))~=each then same=false break end
    end
    if #awards==1 then
      battle:sayNext(("1 POKéMON gained\n%d EXP!"):format(each))
    elseif same then
      -- The amount shown is per Pokemon, not the sum of the shared group.
      battle:sayNext(("%d POKéMON gained\n%d EXP!"):format(#awards,each))
    else
      for _,award in ipairs(awards) do
        local mon=award.mon
        local def=mon and battle.data and battle.data.pokemon
          and battle.data.pokemon[mon.species]
        local name=(mon and mon.nickname) or (def and def.name) or "POKéMON"
        battle:sayNext(("%s gained\n%d EXP!"):format(
          name,math.max(0,math.floor(award.gained or 0))))
      end
    end
    if insertAfter~=nil then
      local inserted=(battle.nextInsert or insertAfter)-insertAfter
      battle.nextInsert=(queuedThrough or insertAfter)+inserted
    end
  end

  local function topUpFullStatExp(mon,enemyDef,split)
    if not (mon and enemyDef and enemyDef.baseStats) then return end
    mon.statExp=mon.statExp or {}
    local divisor=math.max(1,math.floor(tonumber(split) or 1))
    for _,key in ipairs({"hp","attack","defense","speed","special"}) do
      local full=math.max(0,math.floor(tonumber(enemyDef.baseStats[key]) or 0))
      local native=math.floor(full/divisor)
      mon.statExp[key]=math.min(65535,(tonumber(mon.statExp[key]) or 0)+full-native)
    end
  end

  mod.hooks:wrap("battle.exp_award", function(next, ctx)
    local mode=get("exp_share")
    if mode=="OFF" or not ctx or not ctx.battle then return next(ctx) end
    local battle=ctx.battle
    local participantSet={}
    for _,mon in ipairs(ctx.alive or {}) do participantSet[mon]=true end

    -- The engine tracks every surviving mon that fought the defeated enemy in
    -- ctx.alive/ctx.participants.  Only party members outside that set receive
    -- the shared half.  If nobody else is eligible, retain the native full
    -- participant award instead of discarding half of the experience.
    local Experience=require("src.battle.Experience")
    local enemy=battle.enemy and battle.enemy.mon
    local enemyDef=battle.enemy and battle.enemy.def
    local isTrainer=battle.kind=="trainer"
    local others=eligibleNonParticipants(battle,participantSet)
    if #others==0 then
      local split=math.max(1,tonumber(ctx.participants) or #ctx.alive)
      for _,mon in ipairs(ctx.alive or {}) do
        if (mon.level or 0)<100 then
          topUpFullStatExp(mon,enemyDef,split)
          ctx.applyShare(mon,split,true)
        end
      end
      return
    end

    local sharedAllocation=nil
    local participantRemainder=0
    if enemy and enemyDef then
      local pool=Experience.gainFor(
        enemyDef,enemy.level,isTrainer,2,false,battle.data.constants)
      if mode=="SMART" then
        sharedAllocation,participantRemainder=smartAlloc(battle.data,others,pool)
      else
        sharedAllocation,participantRemainder=equalAlloc(others,pool)
      end
    end

    -- Participants divide one half equally. Each participant completes the
    -- native EXP -> level/stats -> move-learning flow before the next one.
    local participantSplit=2*math.max(1,tonumber(ctx.participants) or #ctx.alive)
    local remainderRecipient=nil
    if participantRemainder>0 then
      local active=battle.player and battle.player.mon
      if active and participantSet[active] and (active.level or 0)<100 then
        remainderRecipient=active
      else
        for _,mon in ipairs(ctx.alive or {}) do
          if (mon.level or 0)<100 then remainderRecipient=mon break end
        end
      end
    end
    for _,mon in ipairs(ctx.alive or {}) do
      if (mon.level or 0)<100 then
        if mon==remainderRecipient and enemy and enemyDef then
          local base=Experience.gainFor(enemyDef,enemy.level,isTrainer,
            participantSplit,isTradedMon(battle,mon),battle.data.constants)
          forcedExp[mon]=base+participantRemainder
        end
        topUpFullStatExp(mon,enemyDef,participantSplit)
        ctx.applyShare(mon,participantSplit,true)
        forcedExp[mon]=nil
      end
    end
    -- Shared summary belongs after every participant's complete native flow,
    -- but before any level-up rows generated by the shared recipients.
    local summaryInsert=battle.nextInsert or 0

    if mode=="ACTIVE" then
      local split=2*#others
      local awards={}
      for _,mon in ipairs(others) do
        local amount=(sharedAllocation and sharedAllocation[mon]) or 0
        if amount>0 then
          local before=tonumber(mon.exp) or 0
          forcedExp[mon]=amount
          topUpFullStatExp(mon,enemyDef,split)
          ctx.applyShare(mon,split,nil)
          forcedExp[mon]=nil
          local gained=math.max(0,(tonumber(mon.exp) or before)-before)
          if gained>0 then awards[#awards+1]={mon=mon,gained=gained} end
        end
      end
      sharedExpSummary(battle,awards,summaryInsert)
      return
    end

    -- SMART: same 50% pool, directed at the lowest levels until equalized.
    if not enemy or not enemyDef then return end
    local alloc=sharedAllocation or {}
    local statSplit=2*math.max(1,#others)
    local awards={}
    for _,mon in ipairs(others) do
      local amount=alloc[mon] or 0
      if amount>0 then
        local before=tonumber(mon.exp) or 0
        forcedExp[mon]=amount
        topUpFullStatExp(mon,enemyDef,statSplit)
        ctx.applyShare(mon,statSplit,nil)
        forcedExp[mon]=nil
        local gained=math.max(0,(tonumber(mon.exp) or before)-before)
        if gained>0 then awards[#awards+1]={mon=mon,gained=gained} end
      end
    end
    sharedExpSummary(battle,awards,summaryInsert)
  end)

  -- ---------------- field/QoL hooks ----------------
  -- Gen1Recomp 0.1.86 sandboxes mod code and intentionally removes the debug
  -- library. Use the overworld's public state instead of inspecting the Lua
  -- call stack. Native scripted movement is queued through scriptMoves and
  -- bypasses Player:tryMove; these guards also cover transitions and any
  -- cutscene phase that happens to request a player step directly.
  local function stepCameFromDirectPlayerInput(ctx)
    if not ctx or not ctx.player or ctx.player.inputLocked then return false end
    local Game=require("src.core.Game")
    local ow=Game and Game.overworld
    if not ow or ow.player~=ctx.player or ow.transitioning then return false end
    local runner=ow.runner
    if runner and runner.isRunning and runner:isRunning() then return false end
    if #(ow.scriptMoves or {})>0 or ow.engaging or ow.emote
        or ow.teleportOut or ow.flyAnim or ow.flyArrive then return false end
    return true
  end

  mod.hooks:wrap("movement.speed", function(next, frames, ctx)
    local base=next(frames,ctx)
    local mode=get("fast_run")
    if mode=="OFF" or not ctx or ctx.onBike then return base end
    if ctx.surfing and mode~="ON+SURF" then return base end

    -- This gate is shared by both Hold-B Fast Run and Auto Run. It is the
    -- key cutscene fix: if a script started the step, B/Auto Run are ignored.
    if not stepCameFromDirectPlayerInput(ctx) then return base end

    local bHeld = false
    if ctx.input and ctx.input.isDown then
      local ok, held = pcall(function() return ctx.input:isDown("b") end)
      bHeld = ok and held and true or false
    end
    local running = bHeld or (get("auto_run") and true or false)
    if not running then return base end

    return math.max(1,math.floor((tonumber(base) or tonumber(frames) or 16)/2))
  end)

  -- Player:tryMove stores the chosen duration in stepFramesCur. Scripted
  -- player movement bypasses tryMove and OverworldController starts it
  -- directly, so without this reset it inherits the duration of the last
  -- manual step (including an 8-frame Fast Run step). Restore the engine's
  -- normal duration exactly when a scripted player step begins.
  local OverworldController=require("src.world.OverworldController")
  local quickHMMove=nil
  local oldPartyKnows=OverworldController.partyKnows
  OverworldController.partyKnows=function(self,moveId)
    if quickHMMove==moveId then
      local Game=require("src.core.Game")
      return Game.save and Game.save.party and Game.save.party[1]
    end
    return oldPartyKnows(self,moveId)
  end

  local QUICK_HMS={
    {move="CUT",badge="CASCADEBADGE"},
    {move="FLY",badge="THUNDERBADGE"},
    {move="SURF",badge="SOULBADGE"},
    {move="STRENGTH",badge="RAINBOWBADGE"},
    {move="FLASH",badge="BOULDERBADGE"},
  }

  local function quickHMAvailable(game,row)
    if get("quick_hm")=="IGNORE" then return true end
    local inv=game.save and game.save.inventory or {}
    if inv[row.badge]==nil then return false end
    for id,amount in pairs(inv) do
      local def=game.data and game.data.items and game.data.items[id]
      if amount and def and def.machine and def.machine.kind=="HM"
         and def.machine.move==row.move then return true end
    end
    return false
  end

  local function quickHMMessage(game,text)
    game.stack:push(require("src.render.TextBox").new(game,text))
  end

  local function runQuickHM(game,move)
    local ow=game.overworld
    if not (ow and ow.player and game.save.party and game.save.party[1]) then return end
    if move=="CUT" then
      quickHMMove="CUT"
      local reason=ow:useCutFieldMove()
      if reason=="ok" then
        local x,y=ow.player:facingCell()
        ow:tryCut(x,y)
      else quickHMMessage(game,"Nothing to CUT!") end
      quickHMMove=nil
    elseif move=="SURF" then
      quickHMMove="SURF"
      local reason=ow:useSurfFieldMove()
      if reason=="ok" then
        local x,y=ow.player:facingCell()
        ow:trySurf(x,y)
      elseif reason=="dismount" then
        ow.player.surfing=false
        require("src.core.Music").setSurfing(game.data,false)
        ow:stepForwardOrCrossEdge(ow.player.facing)
      else quickHMMessage(game,"No SURFing here!") end
      quickHMMove=nil
    elseif move=="STRENGTH" then
      ow.strengthActive=true
      quickHMMessage(game,"STRENGTH made it\npossible to move\nboulders!")
    elseif move=="FLASH" then
      if not ow.dark then quickHMMessage(game,"No need to use\nFLASH here."); return end
      game.save.flashLit=true
      ow:setDark(false)
    elseif move=="FLY" then
      local Map=require("src.world.Map")
      local FieldDefaults=require("src.world.FieldDefaults")
      if not Map.isOutside(ow.map.def,FieldDefaults.field(game.data,"outsideTilesets")) then
        quickHMMessage(game,"Can't use FLY\nhere.")
        return
      end
      require("src.ui.Screens").push(game,"TownMap",{fly=true,onFly=function(mapId)
        ow:flyTo(mapId)
      end})
    end
  end

  -- Use an unambiguous field action directly; otherwise retain the menu.
  quickHMContextAction=function(game)
    local ow=game.overworld
    local player=ow and ow.player
    if not (player and game.save and game.save.party and game.save.party[1]) then
      return false
    end

    local available={}
    for _,hm in ipairs(QUICK_HMS) do
      available[hm.move]=quickHMAvailable(game,hm)
    end

    if available.CUT then
      quickHMMove="CUT"
      local reason=ow:useCutFieldMove()
      quickHMMove=nil
      if reason=="ok" then
        runQuickHM(game,"CUT")
        return true
      end
    end

    if available.SURF then
      quickHMMove="SURF"
      local reason=ow:useSurfFieldMove()
      quickHMMove=nil
      if reason=="ok" or reason=="dismount" then
        runQuickHM(game,"SURF")
        return true
      end
    end

    if available.STRENGTH and ow.pushableAtCell then
      local x,y=player:facingCell()
      if ow:pushableAtCell(x,y) then
        if not ow.strengthActive then runQuickHM(game,"STRENGTH") end
        return true
      end
    end

    return false
  end

  mod.content.screens:register(QUICK_HM_SCREEN,{
    new=function(game)
      local rows={}
      for _,hm in ipairs(QUICK_HMS) do
        if quickHMAvailable(game,hm) then rows[#rows+1]={label=hm.move,value=hm.move} end
      end
      if #rows==0 then rows[1]={label="NO HM YET",value=false} end
      local menu=mod.ui.ListMenu.new(game,"QUICK HM",rows,{
        rows=math.min(7,#rows),wrap=true,
        onChoose=function(item,menu)
          if not (item and item.value) then return end
          if menu and menu.close then menu:close() end
          runQuickHM(game,item.value)
        end,
      })
      -- Match Gold's compact right-side Quick HM picker. Twelve tiles provide
      -- a ten-tile interior: enough for NO HM YET, STRENGTH and WATERFALL
      -- without touching the frame.
      menu.isOpaque=false
      menu.draw=function(self)
        local Font=require("src.render.Font")
        local Theme=require("src.ui.Theme")
        local Strings=require("src.core.Strings")
        love.graphics.setColor(1,1,1,1)
        Font.drawBox(8,0,12,17)
        love.graphics.setColor(0,0,0,1)
        Font.draw(Strings(self.title),80,8)
        for row=1,self.rows do
          local index=self.scroll+row
          local item=self.items[index]
          if not item then break end
          local y=16+(row-1)*16
          Font.draw(item.label,80,y)
          if index==self.index then Font.drawCode(Theme.cursor,72,y) end
        end
      end
      return menu
    end,
  })

  local oldUpdateScriptMoves=OverworldController.updateScriptMoves
  OverworldController.updateScriptMoves=function(self)
    local player=self and self.player
    local wasMoving=player and player.moving
    local result=oldUpdateScriptMoves(self)

    if player and not wasMoving and player.moving then
      local scriptedPlayerStep=false
      for _,move in ipairs(self.scriptMoves or {}) do
        if move.entity==player then
          scriptedPlayerStep=true
          break
        end
      end

      if scriptedPlayerStep then
        local normal=(player.onBike and player.bikeStepFrames)
                     or player.stepFrames or 16
        player.stepFramesCur=math.max(1,math.floor(tonumber(normal) or 16))
      end
    end

    return result
  end

  -- Itemfinder radar: every unfound hidden item inside the original
  -- Itemfinder rectangle gets a high-contrast square that contracts toward
  -- the centre of its tile once per second. ON works without the key item;
  -- HAVE ITEM requires ITEMFINDER to be present in the bag.
  local oldDrawWorld=OverworldController.drawWorld
  local radarFrame=0
  local function ownsItemfinder(save)
    local value=save and save.inventory and save.inventory.ITEMFINDER
    if type(value)=="number" then return value>0 end
    return value~=nil and value~=false
  end

  local function drawRadarSquare(x,y,size)
    -- A dark one-pixel surround keeps the marker visible on pale tiles;
    -- the white core keeps it visible on dark tiles.
    love.graphics.setColor(0,0,0,0.9)
    love.graphics.rectangle("line",x-0.5,y-0.5,size+1,size+1)
    love.graphics.setColor(1,1,1,1)
    love.graphics.rectangle("line",x+0.5,y+0.5,size-1,size-1)
  end

  OverworldController.drawWorld=function(self)
    local result=oldDrawWorld(self)
    local mode=get("itemfinder")
    if mode=="OFF" then return result end

    local Game=require("src.core.Game")
    if mode=="HAVE ITEM" and not ownsItemfinder(Game.save) then return result end
    if not (self and self.map and self.player and self.camera) then return result end

    local field=Game.data and Game.data.field
    local list=field and field.hiddenItems and field.hiddenItems[self.map.id]
    if not list then return result end

    radarFrame=(radarFrame+1)%60
    local inset=math.floor((radarFrame/60)*7)
    local size=16-inset*2
    local cam=self.camera
    local taken=(Game.save and Game.save.hiddenTaken) or {}
    local px,py=self.player.cellX,self.player.cellY
    local function near(c,v,hiAdd)
      return v>math.max(c-5,0) and v<=c+hiAdd
    end

    local oldWidth=love.graphics.getLineWidth and love.graphics.getLineWidth() or 1
    love.graphics.setLineWidth(1)
    for _,hidden in ipairs(list) do
      local key=self.map.id.."_"..hidden.x.."_"..hidden.y
      if not taken[key]
         and near(py,hidden.y,4) and near(px,hidden.x,5) then
        local x=math.floor(hidden.x*16-cam.x)+inset
        local y=math.floor(hidden.y*16-cam.y)+inset
        drawRadarSquare(x,y,size)
      end
    end
    love.graphics.setLineWidth(oldWidth)
    love.graphics.setColor(1,1,1,1)
    return result
  end

  -- ---------------- engine-internal QoL patches ----------------
  -- These are intentionally narrow and gated by the in-game settings.
  local TextBox=require("src.render.TextBox")
  local Timing=require("src.core.Timing")
  local oldTextNew=TextBox.new
  TextBox.new=function(game,text,onDone,opts)
    local mapId=game and game.overworld and game.overworld.map
      and game.overworld.map.id
    local isCoinOffer=mapId=="GAME_CORNER" and type(text)=="string"
      and text:find("50",1,true) and text:find("1000",1,true)
      and opts and type(opts.choice)=="function"
    if isCoinOffer then
      local wrapped={}
      for key,value in pairs(opts) do wrapped[key]=value end
      local oldChoice=opts.choice
      wrapped.choice=function(yes)
        local before=game.save.coins or 0
        local result=oldChoice(yes)
        local after=game.save.coins or 0
        local delivered=math.max(0,after-before)
        local multiplier=tonumber(tostring(get("game_corner_multiplier")):match("^(%d+)X$")) or 1
        if yes and delivered>0 and multiplier>1 then
          game.save.coins=math.min(9999,after+delivered*(multiplier-1))
        end
        return result
      end
      opts=wrapped
    end
    return oldTextNew(game,text,onDone,opts)
  end
  local oldTextUpdate=TextBox.update
  TextBox.update=function(self,dt)
    if get("instant_text") and not self.done and not self.waiting and (self.holdFrames or 0)<=0 then
      while not self.done and not self.waiting do
        local line=self.shown[#self.shown]
        while self.charIndex < #self.codes do
          self.charIndex=self.charIndex+1
          line[#line+1]=self.codes[self.charIndex]
        end
        local page=self.pages[self.pageIndex]
        if self.lineIndex < #page then
          local nextIdx=self.lineIndex+1
          local conts=self.pages.contBefore and self.pages.contBefore[self.pageIndex]
          if conts and conts[nextIdx] then
            self.waiting=true; self.preWait=Timing.TEXT_PRE_ADVANCE; self.contAdvance=true
          else
            self.lineIndex=nextIdx; self:beginLine()
          end
        elseif self.pageIndex < #self.pages then
          self.waiting=true; self.preWait=Timing.TEXT_PRE_ADVANCE; self.contAdvance=false
        else self.done=true end
      end
      return
    end
    return oldTextUpdate(self,dt)
  end

  local MoveLearnMenu=require("src.ui.MoveLearnMenu")
  local oldMoveLearnUpdate=MoveLearnMenu.update
  MoveLearnMenu.update=function(self,dt)
    if get("forget_hm") and self.selecting and self.game and self.game.input
       and self.game.input:wasPressed("a") and self.index<=#self.mon.moves then
      local old=self.mon.moves[self.index]
      if old and HM_MOVES[old.id] then
        local mdef=self.game.data.moves[self.newMoveId]
        self.mon.moves[self.index]={id=self.newMoveId,pp=mdef.pp}
        self.forgot=self.game.data.moves[old.id].name
        self:finish(true)
        return
      end
    end
    return oldMoveLearnUpdate(self,dt)
  end

  local ItemEffects=require("src.inventory.ItemEffects")
  local oldItemUse=ItemEffects.use
  ItemEffects.use=function(data,save,itemId,target,battle,moveIndex,ow)
    -- Yellow partner-Pikachu exception: let Thunder Stone follow normal evolve flow.
    if get("pikachu_evo") and not battle and itemId=="THUNDER_STONE"
       and target and target.species=="PIKACHU" then
      return "consumed",nil,{evolveTo="RAICHU"}
    end
    local result,payload,extra=oldItemUse(data,save,itemId,target,battle,moveIndex,ow)
    if get("unlimited_tm") and result=="learn" then
      local def=data and data.items and data.items[itemId]
      if def and def.machine and def.machine.kind=="TM" then result="learnkept" end
    end
    return result,payload,extra
  end

  -- Expanded Gen 2-style Bag. The engine already routes capacity checks
  -- through Bag.capacity, so replacing that single value covers pickups,
  -- shops and gifts without changing the per-item quantity cap.
  local Bag=require("src.inventory.Bag")
  Bag.capacity=function() return 999 end

  local BAG_POCKETS={
    { key="ITEMS", label="ITEMS" },
    { key="KEY", label="KEY" },
    { key="BALLS", label="BALL" },
    { key="TMHM", label="TM/HM" },
  }
  local bagPocket=1
  local activeBagList=nil

  local function bagPocketFor(game,id)
    local def=game.data and game.data.items and game.data.items[id]
    if def and def.machine then return "TMHM" end
    if ItemEffects.isBall and ItemEffects.isBall(id) then return "BALLS" end
    if id=="EXP_ALL" or (def and def.keyItem) or id:find("BADGE",1,true) then return "KEY" end
    return "ITEMS"
  end

  local function orderedMap(groups)
    local out,n={},0
    for group,ids in ipairs(groups) do
      for index,id in ipairs(ids) do
        n=n+1
        out[id]={group=group,index=index,rank=n}
      end
    end
    return out
  end

  local ITEM_TYPE_ORDER=orderedMap({
    {"POTION","SUPER_POTION","HYPER_POTION","MAX_POTION","FULL_RESTORE",
     "FRESH_WATER","SODA_POP","LEMONADE"},
    {"REVIVE","MAX_REVIVE"},
    {"ANTIDOTE","BURN_HEAL","ICE_HEAL","AWAKENING","PARLYZ_HEAL","FULL_HEAL"},
    {"ETHER","MAX_ETHER","ELIXER","MAX_ELIXER","PP_UP"},
    {"HP_UP","PROTEIN","IRON","CARBOS","CALCIUM","RARE_CANDY"},
    {"MOON_STONE","FIRE_STONE","THUNDER_STONE","WATER_STONE","LEAF_STONE"},
    {"X_ATTACK","X_DEFEND","X_SPEED","X_SPECIAL","X_ACCURACY","GUARD_SPEC","DIRE_HIT","POKE_DOLL"},
    {"REPEL","SUPER_REPEL","MAX_REPEL","ESCAPE_ROPE"},
    {"NUGGET"},
  })
  local KEY_TYPE_ORDER=orderedMap({
    {"BICYCLE","TOWN_MAP","ITEMFINDER","OLD_ROD","GOOD_ROD","SUPER_ROD"},
    {"EXP_ALL","POKE_FLUTE","SILPH_SCOPE","COIN_CASE"},
    {"OAKS_PARCEL","S_S_TICKET","BIKE_VOUCHER","CARD_KEY","LIFT_KEY","SECRET_KEY","GOLD_TEETH"},
    {"OLD_AMBER","HELIX_FOSSIL","DOME_FOSSIL"},
    {"POKEDEX","SURFBOARD"},
  })
  local BALL_TYPE_ORDER={POKE_BALL=1,GREAT_BALL=2,ULTRA_BALL=3,MASTER_BALL=4,SAFARI_BALL=5}
  local HM_MOVE_ORDER={CUT=1,FLY=2,SURF=3,STRENGTH=4,FLASH=5}
  local TM_MOVE_ORDER={
    MEGA_PUNCH=1,RAZOR_WIND=2,SWORDS_DANCE=3,WHIRLWIND=4,MEGA_KICK=5,
    TOXIC=6,HORN_DRILL=7,BODY_SLAM=8,TAKE_DOWN=9,DOUBLE_EDGE=10,
    BUBBLEBEAM=11,WATER_GUN=12,ICE_BEAM=13,BLIZZARD=14,HYPER_BEAM=15,
    PAY_DAY=16,SUBMISSION=17,COUNTER=18,SEISMIC_TOSS=19,RAGE=20,
    MEGA_DRAIN=21,SOLARBEAM=22,DRAGON_RAGE=23,THUNDERBOLT=24,THUNDER=25,
    EARTHQUAKE=26,FISSURE=27,DIG=28,PSYCHIC_M=29,TELEPORT=30,
    MIMIC=31,DOUBLE_TEAM=32,REFLECT=33,BIDE=34,METRONOME=35,
    SELFDESTRUCT=36,EGG_BOMB=37,FIRE_BLAST=38,SWIFT=39,SKULL_BASH=40,
    SOFTBOILED=41,DREAM_EATER=42,SKY_ATTACK=43,REST=44,THUNDER_WAVE=45,
    PSYWAVE=46,EXPLOSION=47,ROCK_SLIDE=48,TRI_ATTACK=49,SUBSTITUTE=50,
  }
  local TMHM_MOVE_ABBREVIATIONS={
    THUNDERBOLT="THNDRBOLT",
  }

  local function typeSortRank(game,id,pocket)
    if pocket=="ITEMS" then
      local row=ITEM_TYPE_ORDER[id]
      return row and row.rank or 9000
    elseif pocket=="KEY" then
      local row=KEY_TYPE_ORDER[id]
      return row and row.rank or 9000
    elseif pocket=="BALLS" then
      return BALL_TYPE_ORDER[id] or 9000
    elseif pocket=="TMHM" then
      local def=game.data and game.data.items and game.data.items[id]
      local machine=def and def.machine
      if machine and machine.kind=="HM" then return HM_MOVE_ORDER[machine.move] or 99 end
      if machine and machine.kind=="TM" then return 100+(TM_MOVE_ORDER[machine.move] or 999) end
      return 9000
    end
    return 9000
  end

  -- ListMenu starts labels at x=16 and right-aligns quantities against x=152.
  -- Fit TM/HM labels into the pixels between those columns. Longer/custom
  -- names lose only as many trailing letters as needed, without an ellipsis.
  -- For multi-word moves, shorten the longest word first so the recognizable
  -- final word remains visible (for example SEISMIC TOSS -> SEISM TOSS).
  local function fitBagLabel(label,right)
    local Font=require("src.render.Font")
    local budget=136-Font.width(right or "")
    if Font.width(label)<=budget then return label end
    local machine,move=label:match("^(%S+)%s+(.+)$")
    if machine and move then
      local words={}
      for word in move:gmatch("%S+") do words[#words+1]=word end
      local function joined() return machine.." "..table.concat(words," ") end
      while #words>0 and Font.width(joined())>budget do
        local longest,longestWidth=nil,-1
        for i,word in ipairs(words) do
          local spans=Font.split(word)
          local width=Font.width(word)
          if #spans>1 and width>longestWidth then longest,longestWidth=i,width end
        end
        if not longest then break end
        local spans=Font.split(words[longest])
        words[longest]=words[longest]:sub(1,spans[#spans-1].to)
      end
      label=joined()
      if Font.width(label)<=budget then return label end
    end
    local spans=Font.split(label)
    local fit=Font.spansFitting(spans,math.max(0,budget))
    if fit<=0 then return "" end
    return label:sub(1,spans[fit].to):gsub("%s+$","")
  end

  local function buildPocketItems(game,pocket,sortMode)
    local rows={}
    for _,id in ipairs(Bag.order(game.save)) do
      if bagPocketFor(game,id)==pocket then
        local def=game.data.items[id]
        local right="x"..tostring(game.save.inventory[id] or 0)
        local label=(def and def.name) or id
        if pocket=="TMHM" and def and def.machine then
          local moveDef=game.data and game.data.moves and game.data.moves[def.machine.move]
          local moveName=(moveDef and moveDef.name) or tostring(def.machine.move or "")
          moveName=TMHM_MOVE_ABBREVIATIONS[moveName] or moveName
          label=fitBagLabel(label.." "..moveName,right)
        end
        rows[#rows+1]={
          value=id,
          label=label,
          right=right,
          acquisition=#rows+1,
        }
      end
    end
    if sortMode~="OFF" then
      table.sort(rows,function(a,b)
        if sortMode=="QUANTITY" then
          local aq,bq=game.save.inventory[a.value] or 0,game.save.inventory[b.value] or 0
          if aq~=bq then return aq>bq end
        elseif sortMode=="TYPE" then
          local ar,br=typeSortRank(game,a.value,pocket),typeSortRank(game,b.value,pocket)
          if ar~=br then return ar<br end
        end
        if a.label~=b.label then return a.label<b.label end
        return tostring(a.value)<tostring(b.value)
      end)
    end
    return rows
  end

  mod.content.screens:register(BAG_SORT_SCREEN,{
    new=function(game)
      local items={
        {label="OFF",value="OFF"},
        {label="NAME",value="NAME"},
        {label="QUANTITY",value="QUANTITY"},
        {label="TYPE",value="TYPE"},
      }
      local menu=mod.ui.ListMenu.new(game,"AUTO SORT",items,{
        onChoose=function(item,menu)
          if not item then return end
          set(game,"bag_sort",item.value)
          if menu and menu.close then menu:close() end
          if activeBagList and activeBagList.refreshPocket then activeBagList:refreshPocket() end
        end,
      })
      local active=get("bag_sort")
      for i,item in ipairs(items) do
        if item.value==active then
          menu.index=i
          -- ListMenu draws swapIndex as the hollow cursor when it is not the
          -- navigation row; hollowIndex keeps it hollow while both coincide.
          menu.swapIndex=i
          menu.hollowIndex=i
          break
        end
      end
      return menu
    end,
  })

  local BagMenu=require("src.ui.BagMenu")
  local oldBagNew=BagMenu.new
  BagMenu.new=function(game,opts)
    local list=oldBagNew(game,opts)
    local oldUpdate=list.update
    local oldDraw=list.draw
    local whiteFontShader=nil
    local whiteFontShaderTried=false
    local pocketItemsRef=nil
    local lastPocketValue=nil
    local lastPocketIndex=1

    local function drawWhiteText(Font,value,x,y)
      if not whiteFontShaderTried then
        whiteFontShaderTried=true
        local ok,shader=pcall(love.graphics.newShader,[[
          vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen) {
            vec4 pixel=Texel(texture,uv);
            return vec4(1.0,1.0,1.0,pixel.a*color.a);
          }
        ]])
        if ok then whiteFontShader=shader end
      end
      if whiteFontShader then
        local previous=love.graphics.getShader and love.graphics.getShader() or nil
        love.graphics.setShader(whiteFontShader)
        Font.draw(value,x,y)
        love.graphics.setShader(previous)
      else
        -- Headless/legacy fallback remains readable even without shaders.
        love.graphics.setColor(1,1,1,1)
        love.graphics.rectangle("fill",x-1,y-2,Font.width(value)+2,12)
        love.graphics.setColor(0,0,0,1)
        Font.draw(value,x,y)
      end
    end

    function list:refreshPocket(keepValue,keepIndex)
      local selected=keepValue
      local previousIndex=keepIndex or self.index or 1
      if not selected then
        local current=self.items and self.items[self.index or 1]
        selected=current and current.value
      end
      self.items=buildPocketItems(game,BAG_POCKETS[bagPocket].key,get("bag_sort"))
      self.index=1
      local found=false
      if selected then
        for i,row in ipairs(self.items) do
          if row.value==selected then self.index=i; found=true; break end
        end
      end
      -- A consumed TM disappears from the rebuilt pocket. In that case stay
      -- on the nearest row instead of jumping back to the first item.
      if not found then
        self.index=math.max(1,math.min(previousIndex,math.max(1,#self.items)))
      end
      self.scroll=math.max(0,self.index-(self.rows or 7))
      self.swapIndex=nil
      self.title=BAG_POCKETS[bagPocket].label
      pocketItemsRef=self.items
    end

    list.onSelectKey=function(item,l)
      if not item then return end
      if get("bag_sort")~="OFF" then return end
      if not l.swapValue then
        l.swapValue=item.value
        l.swapIndex=l.index
        return
      end
      local other=item.value
      local order=Bag.order(game.save)
      local ai,bi
      for i,id in ipairs(order) do
        if id==l.swapValue then ai=i end
        if id==other then bi=i end
      end
      if ai and bi then
        order[ai],order[bi]=order[bi],order[ai]
        require("src.core.Sound").play(game.data,"Swap")
      end
      l.swapValue,l.swapIndex=nil,nil
      l:refreshPocket(other)
    end

    list.update=function(self,dt)
      -- Native TM/HM completion rebuilds the Gen 1 flat item list from its
      -- private buildItems closure. Restore our pocketed rows as soon as the
      -- Bag owns the screen again, preserving the current selection.
      if pocketItemsRef and self.items~=pocketItemsRef then
        self:refreshPocket(lastPocketValue,lastPocketIndex)
      end
      local current=self.items and self.items[self.index or 1]
      lastPocketValue=current and current.value
      lastPocketIndex=self.index or 1
      local input=game.input
      if input:wasPressed("start") then
        activeBagList=self
        mod.ui.push(game,BAG_SORT_SCREEN)
        return
      elseif input:wasPressed("left") then
        bagPocket=((bagPocket-2)%#BAG_POCKETS)+1
        self:refreshPocket()
        require("src.core.Sound").play(game.data,"Press_AB")
        return
      elseif input:wasPressed("right") then
        bagPocket=(bagPocket%#BAG_POCKETS)+1
        self:refreshPocket()
        require("src.core.Sound").play(game.data,"Press_AB")
        return
      end
      oldUpdate(self,dt)
    end

    list.draw=function(self)
      oldDraw(self)
      local Font=require("src.render.Font")
      love.graphics.setColor(1,1,1,1)
      love.graphics.rectangle("fill",0,0,160,16)
      local x=2
      for i,pocket in ipairs(BAG_POCKETS) do
        local w=Font.width(pocket.label)+2
        if i==bagPocket then
          love.graphics.setColor(0,0,0,1)
          love.graphics.rectangle("fill",x,1,w,12)
          drawWhiteText(Font,pocket.label,x+1,3)
        else
          love.graphics.setColor(0,0,0,1)
          Font.draw(pocket.label,x+1,3)
        end
        x=x+w
      end
      love.graphics.setColor(1,1,1,1)
    end

    list:refreshPocket()
    return list
  end

  -- This hook is also used by the Wide layout in compatible Gen1Recomp
  -- builds. Keep the native Type/PP panel and add Power/Accuracy below it.
  local BattleState=require("src.battle.BattleState")
  local oldDrawBattleText=BattleState.drawTextArea
  BattleState.drawTextArea=function(self)
    local selected=self.phase=="moveSelect" and self.player
      and self.player.curMoves and self.player.curMoves[self.moveIndex]
    local selectedDef=selected and self.data.moves[selected.id]
    local originalType,changedType
    if get("type_fixes") and selectedDef then
      if selected.id=="KARATE_CHOP" then originalType=selectedDef.type; selectedDef.type="FIGHTING"; changedType=true
      elseif selected.id=="SAND_ATTACK" then originalType=selectedDef.type; selectedDef.type="GROUND"; changedType=true
      elseif selected.id=="GUST" then originalType=selectedDef.type; selectedDef.type="FLYING"; changedType=true end
    end
    local ok,result=pcall(oldDrawBattleText,self)
    if changedType then selectedDef.type=originalType end
    if not ok then error(result) end
    if get("move_info") and self.phase=="moveSelect" and self.player
       and self.player.disabledSlot~=self.moveIndex then
      local def=selected and self.data.moves[selected.id]
      if def then
        local Font=require("src.render.Font")
        local power=tonumber(def.power)
        local accuracy=tonumber(def.accuracy)
        if get("type_fixes") then
          if selected.id=="LICK" then power=40
          elseif selected.id=="LOW_KICK" then power=60
          elseif selected.id=="SUBMISSION" then accuracy=90 end
        end
        if accuracy and accuracy<=1 then accuracy=math.floor(accuracy*100+0.5)
        elseif accuracy then accuracy=math.floor(accuracy+0.5) end
        local pwr=(power and power>0) and tostring(math.floor(power+0.5)) or "--"
        local acc=accuracy and tostring(accuracy) or "--"
        love.graphics.setColor(0,0,0,1)
        Font.draw("POW",8,104)
        Font.draw(pwr,8,112)
        Font.draw("ACC",8,120)
        Font.draw(acc,8,128)
        love.graphics.setColor(1,1,1,1)
      end
    end
    return result
  end

  -- Current Gen1Recomp handles nurses directly in OverworldController rather
  -- than through src.script.Commands. Intercept that native entry point so
  -- Fast Center can heal immediately without the dialogue/choice/animation.
  local oldNurseHeal=OverworldController.nurseHeal
  OverworldController.nurseHeal=function(self,onDone,npc)
    if not get("fast_center") then return oldNurseHeal(self,onDone,npc) end

    local Game=require("src.core.Game")
    local Pokemon=require("src.pokemon.Pokemon")
    for _,mon in ipairs((Game.save and Game.save.party) or {}) do
      Pokemon.heal(mon)
    end

    Game.save.usedPokecenter=true
    Game.save.lastHeal={
      map=self.map.id,
      x=self.player.cellX,
      y=self.player.cellY,
      outdoor=self.lastOutdoor and {
        id=self.lastOutdoor.id,
        x=self.lastOutdoor.x,
        y=self.lastOutdoor.y,
      } or nil,
    }

    if npc then npc:facePlayer(self.player) end
    require("src.core.Music").playOnce(Game.data,"Music_PkmnHealed")
    if onDone then onDone() end
  end

  -- Multiply only slot-machine winnings. Bets, odds and the 9999-coin cap
  -- remain owned by the native Game Corner implementation.
  local SlotMachine=require("src.ui.SlotMachine")
  local oldResolveSlotWin=SlotMachine.resolveWin
  SlotMachine.resolveWin=function(self,win)
    local value=get("game_corner_multiplier")
    local multiplier=tonumber(tostring(value):match("^(%d+)X$")) or 1
    if multiplier>1 and win and tonumber(win.payout) then
      local adjusted={}
      for key,entry in pairs(win) do adjusted[key]=entry end
      adjusted.payout=math.floor(win.payout*multiplier)
      return oldResolveSlotWin(self,adjusted)
    end
    return oldResolveSlotWin(self,win)
  end

  -- The native machine pays one coin every 4/8 frames. With a multiplied
  -- jackpot that can take minutes, so pay one multiplier-sized block per
  -- animation tick and shorten the tick to one frame. A 10X prize therefore
  -- takes roughly as many ticks as its original, unmultiplied payout.
  local oldStartSlotPayout=SlotMachine.startPayout
  SlotMachine.startPayout=function(self)
    local result=oldStartSlotPayout(self)
    local multiplier=tonumber(tostring(get("game_corner_multiplier")):match("^(%d+)X$")) or 1
    if multiplier>1 then self.dripFrames=1 end
    return result
  end
  local oldSlotUpdate=SlotMachine.update
  SlotMachine.update=function(self,dt)
    local wasPayout=self.stage=="payout"
    local before=wasPayout and (self.payoutRemaining or 0) or 0
    local result=oldSlotUpdate(self,dt)
    local paid=before-(self.payoutRemaining or 0)
    if wasPayout and paid==1 and self.stage=="payout" then
      local multiplier=tonumber(tostring(get("game_corner_multiplier")):match("^(%d+)X$")) or 1
      local extra=math.min(math.max(0,multiplier-1),self.payoutRemaining or 0)
      if extra>0 then
        local save=self.game and self.game.save
        if save then save.coins=math.min(9999,(save.coins or 0)+extra) end
        self.payoutRemaining=self.payoutRemaining-extra
        self.payoutDisplay=self.payoutRemaining
      end
    end
    return result
  end

end
