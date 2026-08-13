-- myQualityOfLife - Pokemon Gold / Gen 2 implementation.
-- This file intentionally imports only shared modules and explicit gen2
-- modules. The stable Gen 1 implementation lives independently in gen1.lua.
return function(mod)
  local MAIN = "MQOL2Main"
  local BATTLE = "MQOL2Battle"
  local POKEMON = "MQOL2Pokemon"
  local MISC = "MQOL2Misc"
  local CHEATS = "MQOL2Cheats"
  local QUICK_HM = "MQOL2QuickHM"
  local HOTKEY = "MQOL2Hotkey"
  local KEY_CAPTURE = "MQOL2KeyCapture"
  local PAD_CAPTURE = "MQOL2PadCapture"
  local ENCOUNTER_HOTKEY = "MQOL2EncounterHotkey"
  local ENCOUNTER_KEY_CAPTURE = "MQOL2EncounterKeyCapture"
  local ENCOUNTER_PAD_CAPTURE = "MQOL2EncounterPadCapture"
  local WILD_POKEMON = "MQOL2WildPokemon"
  local BAG_SORT_SCREEN = "MQOL2BagSort"
  local MOVE_SCREEN = "MQOL2MoveEditor"
  local PICK_SCREEN = "MQOL2MovePick"
  local moveTarget, moveSlot
  local activeGame
  local syncForgetHM = function() end

  local DEFAULTS = {
    fast_run = "OFF", auto_run = false, instant_text = false,
    itemfinder = "OFF", fast_center = false, fast_save = false,
    bag_sort = "OFF", exp_share = "OFF", move_info = false,
    forget_hm = false, unlimited_tm = false, quick_hm = "OFF",
    quick_hm_hotkey = "shift", quick_hm_gamepad = "OFF",
    never_miss = false, always_crit = false, infinite_pp = false,
    always_catch = false, exp_multiplier = "OFF", move_editor = "OFF",
    force_encounter = false, encounter_hotkey = "f6", encounter_gamepad = "OFF",
    wild_select = "OFF", wild_pokemon = "RATTATA",
  }
  local MISC_KEYS = { "fast_run", "auto_run", "instant_text", "itemfinder",
    "fast_center", "fast_save", "bag_sort" }
  local BATTLE_KEYS = { "exp_share", "move_info" }
  local POKEMON_KEYS = { "forget_hm", "unlimited_tm", "quick_hm",
    "quick_hm_hotkey", "quick_hm_gamepad" }
  local CHEAT_KEYS = { "never_miss", "always_crit", "infinite_pp",
    "always_catch", "exp_multiplier", "move_editor", "force_encounter",
    "encounter_hotkey", "encounter_gamepad", "wild_select", "wild_pokemon" }

  local function get(key)
    local value=mod.save:get(key, DEFAULTS[key])
    if key=="wild_select" and type(value)=="boolean" then return value and "ON" or "OFF" end
    return value
  end
  local function persist(game)
    if game and game.writeSave then pcall(function() game:writeSave() end) end
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
    resetKeys(game, MISC_KEYS); resetKeys(game, BATTLE_KEYS)
    resetKeys(game, POKEMON_KEYS); resetKeys(game, CHEAT_KEYS)
  end
  local function boolText(value) return value and "ON" or "OFF" end
  local function toggle(game, key) set(game, key, not get(key)) end
  local function cycle(game, key, values)
    local index = 1
    for i, value in ipairs(values) do if value == get(key) then index = i end end
    set(game, key, values[index % #values + 1])
  end
  local function confirm(game, text, fn)
    local TextBox = require("src.render.TextBox")
    game.stack:push(TextBox.new(game, text, nil, {
      defaultNo = true, choice = function(yes) if yes then fn() end end,
    }))
  end
  local menuCursor = {}
  local function refresh(menu, game, screen)
    if menu and menu.items then
      local item = menu.items[menu.index or 1]
      menuCursor[screen] = { value=item and item.value, index=menu.index or 1 }
    end
    if menu and menu.close then menu:close() else game.stack:pop() end
    mod.ui.push(game, screen)
  end
  local function restoreCursor(screen, menu)
    local saved = menuCursor[screen]
    if not saved or not menu or not menu.items then return menu end
    local index
    for i, item in ipairs(menu.items) do
      if saved.value ~= nil and item.value == saved.value then index = i; break end
    end
    index = index or math.max(1, math.min(saved.index or 1, #menu.items))
    menu.index = index
    local rows = tonumber(menu.rows) or 7
    menu.scroll = index > rows and index - rows or 0
    return menu
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

  local function hotkeyText(key)
    key = tostring(key or "shift")
    local names = { shift="SHIFT", lctrl="LEFT CTRL", rctrl="RIGHT CTRL",
      lalt="LEFT ALT", ralt="RIGHT ALT", pageup="PAGE UP", pagedown="PAGE DOWN" }
    return names[key] or key:upper()
  end
  local function gamepadText(button)
    button = tostring(button or "OFF")
    local names = { leftshoulder="L1", rightshoulder="R1",
      lefttrigger="L2", righttrigger="R2", leftstick="L3", rightstick="R3" }
    names["axis:triggerleft"] = "L2"
    names["axis:triggerright"] = "R2"
    return names[button] or button:upper()
  end

  mod.content.screens:register(MAIN, { new=function(game)
    local menu
    menu = mod.ui.ListMenu.new(game, "MOD OPTIONS", {
      {label="BATTLE OPTIONS", value="battle"},
      {label="POKEMON", value="pokemon"},
      {label="MISC", value="misc"},
      {label="CHEATS", value="cheats"},
      {label="RESET DEFAULT ALL", value="reset"},
    }, { onChoose=function(item)
      if not item then return end
      if item.value == "battle" then mod.ui.push(game, BATTLE)
      elseif item.value == "pokemon" then mod.ui.push(game, POKEMON)
      elseif item.value == "misc" then mod.ui.push(game, MISC)
      elseif item.value == "cheats" then mod.ui.push(game, CHEATS)
      else confirm(game, "Reset ALL options\nto defaults?", function()
        resetAll(game); refresh(menu, game, MAIN)
      end) end
    end })
    return restoreCursor(MAIN, menu)
  end })

  mod.content.screens:register(MISC, { new=function(game)
    local items = { {label="FAST RUN", right=get("fast_run"), value="fast_run"} }
    if get("fast_run") ~= "OFF" then
      items[#items+1] = {label="AUTO RUN", right=boolText(get("auto_run")), value="auto_run"}
    end
    items[#items+1] = {label="INSTANT TEXT", right=boolText(get("instant_text")), value="instant_text"}
    items[#items+1] = {label="ITEMFINDER", right=get("itemfinder"), value="itemfinder"}
    items[#items+1] = {label="FAST CENTER", right=boolText(get("fast_center")), value="fast_center"}
    items[#items+1] = {label="FAST SAVE", right=boolText(get("fast_save")), value="fast_save"}
    items[#items+1] = {label="RESET DEFAULTS", value="reset"}
    local menu
    menu = mod.ui.ListMenu.new(game, "MISC - GOLD BETA", items, { onChoose=function(item)
      if item.value == "fast_run" then cycle(game, "fast_run", {"OFF","ON","ON+SURF"})
      elseif item.value == "auto_run" then toggle(game, "auto_run")
      elseif item.value == "instant_text" then toggle(game, "instant_text")
      elseif item.value == "itemfinder" then cycle(game, "itemfinder", {"OFF","ON","HAVE ITEM"})
      elseif item.value == "reset" then return confirm(game, "Reset MISC options\nto defaults?", function()
        resetKeys(game, MISC_KEYS); refresh(menu, game, MISC)
      end)
      else toggle(game, item.value) end
      refresh(menu, game, MISC)
    end })
    return restoreCursor(MISC, menu)
  end })

  mod.content.screens:register(BATTLE, { new=function(game)
    local menu
    menu = mod.ui.ListMenu.new(game, "BATTLE - GOLD BETA", {
      {label="EXP SHARE", right=(get("exp_share") == "ACTIVE" and "GEN1" or get("exp_share")), value="exp_share"},
      {label="MOVE INFO", right=boolText(get("move_info")), value="move_info"},
      {label="RESET DEFAULTS", value="reset"},
    }, { onChoose=function(item)
      if item.value == "exp_share" then cycle(game, "exp_share", {"OFF","ACTIVE","SMART"})
      elseif item.value == "reset" then return confirm(game, "Reset BATTLE options\nto defaults?", function()
        resetKeys(game, BATTLE_KEYS); refresh(menu, game, BATTLE)
      end)
      else toggle(game, item.value) end
      refresh(menu, game, BATTLE)
    end })
    return restoreCursor(BATTLE, menu)
  end })

  mod.content.screens:register(POKEMON, { new=function(game)
    local items = {
      {label="FORGET HM", right=boolText(get("forget_hm")), value="forget_hm"},
      {label="REUSABLE TMS", right=boolText(get("unlimited_tm")), value="unlimited_tm"},
      {label="QUICK HM", right=get("quick_hm"), value="quick_hm"},
    }
    if get("quick_hm") ~= "OFF" then
      items[#items+1] = {label="HM HOTKEY", right=hotkeyText(get("quick_hm_hotkey")), value="hotkey"}
    end
    items[#items+1] = {label="RESET DEFAULTS", value="reset"}
    local menu
    menu = mod.ui.ListMenu.new(game, "POKEMON - GOLD BETA", items, { onChoose=function(item)
      if item.value == "quick_hm" then cycle(game, "quick_hm", {"OFF","ON","IGNORE"})
      elseif item.value == "hotkey" then mod.ui.push(game, HOTKEY); return
      elseif item.value == "reset" then return confirm(game, "Reset POKEMON options\nto defaults?", function()
        resetKeys(game, POKEMON_KEYS); syncForgetHM(); refresh(menu, game, POKEMON)
      end)
      elseif item.value == "forget_hm" then
        toggle(game, item.value); syncForgetHM()
      else toggle(game, item.value) end
      refresh(menu, game, POKEMON)
    end })
    return restoreCursor(POKEMON, menu)
  end })

  mod.content.screens:register(CHEATS, { new=function(game)
    local menu
    local items = {
      {label="NEVER MISS", right=boolText(get("never_miss")), value="never_miss"},
      {label="ALWAYS CRIT", right=boolText(get("always_crit")), value="always_crit"},
      {label="INFINITE PP", right=boolText(get("infinite_pp")), value="infinite_pp"},
      {label="ALWAYS CATCH", right=boolText(get("always_catch")), value="always_catch"},
      {label="EXP MULTIPLIER", right=get("exp_multiplier"), value="exp_multiplier"},
      {label="MOVE EDITOR", right=get("move_editor"), value="move_editor"},
      {label="FORCE ENCOUNTER", right=boolText(get("force_encounter")), value="force_encounter"},
    }
    if get("force_encounter") then items[#items+1]={label="ENCOUNTER HOTKEY",right=hotkeyText(get("encounter_hotkey")),value="encounter_hotkey"} end
    items[#items+1]={label="WILD SELECT",right=tostring(get("wild_select")),value="wild_select"}
    if get("wild_select")~="OFF" then
      local species=mod.content.pokemon:get(get("wild_pokemon"))
      items[#items+1]={label="WILD POKEMON",right=(species and species.name) or tostring(get("wild_pokemon")),value="wild_pokemon"}
    end
    items[#items+1]={label="RESET DEFAULTS",value="reset"}
    menu = mod.ui.ListMenu.new(game, "CHEATS - GOLD BETA", items, { onChoose=function(item)
      if item.value == "exp_multiplier" then cycle(game, item.value, {"OFF","2X","3X","4X"})
      elseif item.value == "move_editor" then cycle(game, item.value, {"OFF","BASE","TODOS"})
      elseif item.value == "encounter_hotkey" then mod.ui.push(game, ENCOUNTER_HOTKEY); return
      elseif item.value == "wild_pokemon" then mod.ui.push(game, WILD_POKEMON); return
      elseif item.value == "wild_select" then cycle(game,item.value,{"OFF","ON","FIRST"})
      elseif item.value == "reset" then return confirm(game, "Reset CHEATS options\nto defaults?", function()
        resetKeys(game, CHEAT_KEYS); refresh(menu, game, CHEATS)
      end)
      else toggle(game, item.value) end
      refresh(menu, game, CHEATS)
    end })
    return restoreCursor(CHEATS, menu)
  end })

  mod.content.screens:register(HOTKEY, { new=function(game)
    local menu
    local items = {
      {label="KEYBOARD", right=hotkeyText(get("quick_hm_hotkey")), value="key"},
      {label="CONTROLLER", right=gamepadText(get("quick_hm_gamepad")), value="pad"},
    }
    if get("quick_hm_gamepad") ~= "OFF" then
      items[#items+1] = {label="DISABLE CONTROLLER", value="disable"}
    end
    menu = mod.ui.ListMenu.new(game, "QUICK HM HOTKEY", items, { onChoose=function(item)
      if item.value == "key" then mod.ui.push(game, KEY_CAPTURE)
      elseif item.value == "pad" then mod.ui.push(game, PAD_CAPTURE)
      else set(game, "quick_hm_gamepad", "OFF"); refresh(menu, game, HOTKEY) end
    end })
    return menu
  end })

  local blockedKeys = { up=true, down=true, left=true, right=true, w=true, a=true,
    s=true, d=true, z=true, x=true, ["return"]=true, space=true, escape=true }
  mod.content.screens:register(KEY_CAPTURE, { new=function(game)
    local menu = mod.ui.ListMenu.new(game, "KEYBOARD HOTKEY", {{label="PRESS A KEY"},{label="ESC TO CANCEL"}}, {rows=2})
    menu.mqol2KeyCapture = true
    menu.onKeyPressed = function(self, key)
      if key == "escape" or key == "backspace" then game.stack:pop(); return end
      if key == "lshift" or key == "rshift" then key = "shift" end
      if blockedKeys[key] then self.items[1].label = "KEY NOT AVAILABLE"; return end
      set(game, "quick_hm_hotkey", key)
      game.stack:pop() -- capture
      game.stack:pop() -- stale hotkey page
      mod.ui.push(game, HOTKEY)
    end
    return menu
  end })
  mod.content.screens:register(PAD_CAPTURE, { new=function(game)
    local menu = mod.ui.ListMenu.new(game, "CONTROLLER HOTKEY", {{label="PRESS A BUTTON"},{label="B TO CANCEL"}}, {rows=2})
    menu.mqol2Capture = true
    menu.onGamepadPressed = function(self, button)
      if button == "b" then game.stack:pop(); return end
      set(game, "quick_hm_gamepad", button)
      game.stack:pop() -- capture
      game.stack:pop() -- stale hotkey page
      mod.ui.push(game, HOTKEY)
    end
    menu.onGamepadAxis = function(self, axis, value)
      if (axis ~= "triggerleft" and axis ~= "triggerright") or value < 0.65 then return end
      set(game, "quick_hm_gamepad", "axis:" .. axis)
      game.stack:pop() -- capture
      game.stack:pop() -- stale hotkey page
      mod.ui.push(game, HOTKEY)
    end
    return menu
  end })

  mod.content.screens:register(WILD_POKEMON, { new=function(game)
    local rows={}
    for id,def in mod.content.pokemon:each() do
      local dex=tonumber(def and def.dex)
      if dex and dex>=1 and dex<=251 then
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
      refresh(parent,game,CHEATS)
    end})
    return pageAligned(menu)
  end})

  mod.content.screens:register(ENCOUNTER_HOTKEY, { new=function(game)
    local items={{label="KEYBOARD",right=hotkeyText(get("encounter_hotkey")),value="key"},
      {label="CONTROLLER",right=gamepadText(get("encounter_gamepad")),value="pad"}}
    if get("encounter_gamepad")~="OFF" then items[#items+1]={label="DISABLE CONTROLLER",value="disable"} end
    local menu
    menu=mod.ui.ListMenu.new(game,"ENCOUNTER HOTKEY",items,{onChoose=function(item)
      if item.value=="key" then mod.ui.push(game,ENCOUNTER_KEY_CAPTURE)
      elseif item.value=="pad" then mod.ui.push(game,ENCOUNTER_PAD_CAPTURE)
      else set(game,"encounter_gamepad","OFF"); refresh(menu,game,ENCOUNTER_HOTKEY) end
    end})
    return menu
  end})

  mod.content.screens:register(ENCOUNTER_KEY_CAPTURE, { new=function(game)
    local menu=mod.ui.ListMenu.new(game,"KEYBOARD HOTKEY",{{label="PRESS A KEY"},{label="ESC TO CANCEL"}},{rows=2})
    menu.mqol2EncounterKeyCapture=true
    menu.onKeyPressed=function(self,key)
      if key=="escape" or key=="backspace" then game.stack:pop(); return end
      if key=="lshift" or key=="rshift" then key="shift" end
      if blockedKeys[key] then self.items[1].label="KEY NOT AVAILABLE"; return end
      set(game,"encounter_hotkey",key); game.stack:pop(); game.stack:pop(); mod.ui.push(game,ENCOUNTER_HOTKEY)
    end
    return menu
  end})

  mod.content.screens:register(ENCOUNTER_PAD_CAPTURE, { new=function(game)
    local menu=mod.ui.ListMenu.new(game,"CONTROLLER HOTKEY",{{label="PRESS A BUTTON"},{label="B TO CANCEL"}},{rows=2})
    menu.mqol2EncounterCapture=true
    menu.onGamepadPressed=function(self,button)
      if button=="b" then game.stack:pop(); return end
      set(game,"encounter_gamepad",button); game.stack:pop(); game.stack:pop(); mod.ui.push(game,ENCOUNTER_HOTKEY)
    end
    menu.onGamepadAxis=function(self,axis,value)
      if (axis~="triggerleft" and axis~="triggerright") or value<0.65 then return end
      set(game,"encounter_gamepad","axis:"..axis); game.stack:pop(); game.stack:pop(); mod.ui.push(game,ENCOUNTER_HOTKEY)
    end
    return menu
  end})

  mod.content.screens:register(BAG_SORT_SCREEN, { new=function(game)
    local current = get("bag_sort")
    local rows = {}
    for _, mode in ipairs({"OFF", "NAME", "QUANTITY", "TYPE"}) do
      rows[#rows+1] = {
        label=(mode == current and "▷ " or "  ") .. mode,
        value=mode,
      }
    end
    local menu
    menu = mod.ui.ListMenu.new(game, "AUTO SORT", rows, { onChoose=function(item)
      if not item then return end
      set(game, "bag_sort", item.value)
      local states = game.stack and game.stack.states
      local pack = states and states[#states - 1]
      if menu and menu.close then menu:close() else game.stack:pop() end
      if pack and pack.rebuild then pack:rebuild() end
    end })
    return menu
  end })

  local function moveName(game, id)
    local def = id and game.data and game.data.moves and game.data.moves[id]
    return (def and def.name) or (id and tostring(id):gsub("_", " ")) or "EMPTY"
  end
  local function baseMoveSet(game, mon)
    local set = {}
    local species = mon and game.data and game.data.pokemon and game.data.pokemon[mon.species]
    -- Gold stores every natural move in levelMoves (including level 1), and
    -- breeding moves separately in eggMoves. Keep the Gen 1 field probes as
    -- harmless compatibility fallbacks for custom hybrid registries.
    for _, row in ipairs((species and species.levelMoves) or {}) do
      local id = type(row) == "table" and row.move or row
      if id then set[id] = true end
    end
    for _, id in ipairs((species and species.eggMoves) or {}) do set[id] = true end
    for _, id in ipairs((species and species.level1Moves) or {}) do set[id] = true end
    for _, row in ipairs((species and species.learnset) or {}) do
      local id = type(row) == "table" and row.move or row
      if id then set[id] = true end
    end
    for _, id in ipairs((species and species.tmhm) or {}) do set[id] = true end
    return set
  end
  mod.content.screens:register(MOVE_SCREEN, { new=function(game)
    local mon = moveTarget
    if not mon then return mod.ui.ListMenu.new(game, "MOVE EDITOR", {{label="NO POKEMON"}}) end
    local items = {}
    for slot = 1, 4 do
      local move = (mon.moves or {})[slot]
      items[#items+1] = {label=("SLOT %d  %s"):format(slot, moveName(game, move and move.id)), value=slot}
    end
    return mod.ui.ListMenu.new(game, (mon.nickname or mon.species or "POKEMON") .. " MOVES", items, {
      onChoose=function(item) if item then moveSlot = item.value; mod.ui.push(game, PICK_SCREEN) end end,
    })
  end })
  mod.content.screens:register(PICK_SCREEN, { new=function(game)
    local allowed = get("move_editor") == "BASE" and baseMoveSet(game, moveTarget) or nil
    local rows = {}
    for id, def in mod.content.moves:each() do
      if not allowed or allowed[id] then rows[#rows+1] = {id=id, name=(def and def.name) or tostring(id)} end
    end
    table.sort(rows, function(a,b) return a.name == b.name and tostring(a.id) < tostring(b.id) or a.name < b.name end)
    local items = {}; for _, row in ipairs(rows) do items[#items+1] = {label=row.name, value=row.id} end
    local menu
    menu = mod.ui.ListMenu.new(game, "REPLACE MOVE", items, {rows=5, pageJump=true, keyRepeat=true,
      onChoose=function(item, menu)
        if not (item and moveTarget and moveSlot) then return end
        local def = game.data and game.data.moves and game.data.moves[item.value]
        moveTarget.moves = moveTarget.moves or {}
        moveTarget.moves[moveSlot] = {id=item.value, pp=(def and def.pp) or 0,
          maxPp=(def and def.pp) or 0, ppUps=0}
        if menu and menu.close then menu:close() else game.stack:pop() end
        game.stack:pop(); mod.ui.push(game, MOVE_SCREEN)
      end,
    })
    return pageAligned(menu)
  end })
  mod.hooks:wrap("ui.party.submenu", function(next, game, items, mon, ctx)
    local out = next(game, items, mon, ctx)
    if type(out) ~= "table" then out = items end
    if get("move_editor") == "OFF" or (ctx and ctx.battle) then return out end
    out[#out+1] = { id="MQOL_MOVE_EDITOR", label="MOVE EDITOR",
      onSelect=function(selectedMon, selectedGame)
        moveTarget, moveSlot = selectedMon, nil
        if selectedGame.stack then selectedGame.stack:pop() end
        mod.ui.push(selectedGame, MOVE_SCREEN)
      end }
    return out
  end)

  -- Native options owns the entry point, keeping the START menu uncluttered.
  mod.hooks:wrap("ui.options.rows", function(next, game, rows)
    local out = next(game, rows)
    if type(out) == "table" then out[#out+1] = {
      id="my_quality_of_life", label="myQualityOfLife",
      activate=function(g) mod.ui.push(g, MAIN) end,
    } end
    return out
  end)

  -- Gold calls this hook only for direct player steps. Scripted movement and
  -- cutscenes use their own path, so Fast Run cannot leak into them.
  mod.hooks:wrap("movement.speed", function(next, frames, ctx)
    local base = next(frames, ctx)
    local mode = get("fast_run")
    if mode == "OFF" or not ctx or ctx.onBike or ctx.downhill then return base end
    if ctx.surfing and mode ~= "ON+SURF" then return base end
    local held = false
    if ctx.input and ctx.input.isDown then
      local ok, value = pcall(function() return ctx.input:isDown("b") end)
      held = ok and value or false
    end
    if not held and not get("auto_run") then return base end
    return math.max(1, math.floor((tonumber(base) or tonumber(frames) or 16) / 2))
  end)

  mod.hooks:wrap("battle.accuracy", function(next, ctx)
    if get("never_miss") and ctx and ctx.battle and ctx.user == ctx.battle.player then return true end
    return next(ctx)
  end)
  mod.hooks:wrap("battle.crit", function(next, ctx)
    if get("always_crit") and ctx and ctx.battle and ctx.attacker == ctx.battle.player then return true end
    return next(ctx)
  end)
  mod.hooks:wrap("catch.rate", function(next, ball, mon, def, opts)
    if get("always_catch") then return true, 3 end
    return next(ball, mon, def, opts)
  end)
  mod.hooks:wrap("exp.gain", function(next, ctx)
    local amount = next(ctx)
    local multiplier = tonumber(tostring(get("exp_multiplier")):match("^(%d+)X$")) or 1
    return math.max(0, math.floor((tonumber(amount) or 0) * multiplier))
  end)

  -- Gen1 mode: half for battlers and half for nonparticipants. Smart pays the
  -- shared half only to the lowest-level eligible group, snapshotted first.
  mod.hooks:wrap("battle.exp_award", function(next, ctx)
    local mode = get("exp_share")
    if mode == "OFF" or not ctx or not ctx.battle then return next(ctx) end
    local battle, participantSet = ctx.battle, {}
    for _, mon in ipairs(ctx.alive or {}) do participantSet[mon] = true end
    local others = {}
    for _, mon in ipairs((battle.save and battle.save.party) or battle.party or {}) do
      if not participantSet[mon] and (mon.hp or 0) > 0 and not mon.isEgg and (mon.level or 0) < 100 then
        others[#others+1] = mon
      end
    end
    if #others == 0 then return next(ctx) end
    if mode == "SMART" then
      local lowest = 101
      for _, mon in ipairs(others) do lowest = math.min(lowest, mon.level or 1) end
      local filtered = {}
      for _, mon in ipairs(others) do if (mon.level or 1) == lowest then filtered[#filtered+1] = mon end end
      others = filtered
    end
    local nativeHalf = ctx.halved and 1 or 2
    local participantDivisor = nativeHalf * math.max(1, #(ctx.alive or {}))
    for _, mon in ipairs(ctx.alive or {}) do ctx.applyShare(mon, participantDivisor) end
    local sharedDivisor = nativeHalf * #others
    for _, mon in ipairs(others) do ctx.applyShare(mon, sharedDivisor) end
  end)

  -- The Gold model calculates the complete EXP pass up front. When a full
  -- moveset pauses on choose-forget, resolveForget therefore appends its
  -- "forgot" / "learned" lines behind EXP events already queued for later
  -- recipients. Mark those two lines and put them back at the head when the
  -- choice closes, so one Pokemon's level-up flow finishes before the next.
  local GoldBattle = require("src.battle.gen2.Battle")
  local oldResolveForget = GoldBattle.resolveForget
  GoldBattle.resolveForget = function(self, index, slot, entry, moveName)
    local first = #(self.events or {}) + 1
    local result = oldResolveForget(self, index, slot, entry, moveName)
    for i = first, #(self.events or {}) do
      self.events[i].mqolLearnResolution = true
    end
    return result
  end
  local GoldBattleState = require("src.ui.gen2.BattleState")
  local oldPushAll = GoldBattleState.pushAll
  GoldBattleState.pushAll = function(self, events)
    local immediate, normal = {}, {}
    for _, event in ipairs(events or {}) do
      if event.mqolLearnResolution then
        event.mqolLearnResolution = nil
        immediate[#immediate + 1] = event
      else
        normal[#normal + 1] = event
      end
    end
    oldPushAll(self, normal)
    for i = #immediate, 1, -1 do
      table.insert(self.queue, 1, immediate[i])
    end
  end

  mod.events:on("battle.move_used", function(ev)
    if not get("infinite_pp") or not ev or ev.side ~= "player" then return end
    local user = ev.user
    for _, move in ipairs((user and user.moves) or {}) do
      if move.id == ev.moveId then move.pp = move.maxPp or move.pp; break end
    end
  end)

  -- Selected-move details replace the four PP columns at the right. This keeps
  -- every move visible and gives Power, Accuracy, Type and current/max PP one
  -- stable row each.
  mod.hooks:wrap("battle.overlay", function(next, state)
    next(state)
    if not get("move_info") or not state or state.phase ~= "moves" then return end
    local moves = state.playerMoves and state:playerMoves() or nil
    local move = moves and moves[state.moveIndex or 1]
    local def = move and state.game and state.game.data and state.game.data.moves[move.id]
    if not def then return end
    local Chrome = require("src.ui.gen2.Chrome")
    local power = tonumber(def.power) or 0
    local accuracy = tonumber(def.accuracy)
    local powerText = power > 0 and ("%3d"):format(power) or "---"
    local accText = accuracy and ("%3d"):format(math.floor(accuracy + 0.5)) or "---"
    local typeText = tostring(def.type or "---"):gsub("_TYPE$", ""):gsub("_", " ")
    if #typeText > 8 then typeText = typeText:sub(1, 8) end
    local ppText = ("PP %d/%d"):format(tonumber(move.pp) or 0,
      tonumber(move.maxPp) or tonumber(move.pp) or 0)
    local G = love.graphics
    G.setColor(1, 1, 1, 1)
    G.rectangle("fill", 12 * 8, 13 * 8, 8 * 8, 4 * 8)
    Chrome.print(("POW %s"):format(powerText), 12, 13)
    Chrome.print(("ACC %s"):format(accText), 12, 14)
    Chrome.print(("%-8s"):format(typeText), 12, 15)
    Chrome.print(ppText, 12, 16)
  end)

  local quickOverride
  mod.hooks:wrap("fieldmove.eligibility", function(next, moveId, ctx)
    if quickOverride == moveId and ctx and ctx.party then return ctx.party[1] end
    return next(moveId, ctx)
  end)
  local HMS = { "CUT", "FLY", "SURF", "STRENGTH", "FLASH", "WHIRLPOOL", "WATERFALL" }
  local FieldMoves = require("src.world.gen2.FieldMoves")
  local function monKnows(mon, moveId)
    for _, move in ipairs((mon and mon.moves) or {}) do
      if (type(move) == "table" and move.id or move) == moveId then return true end
    end
    return false
  end
  local function ownsHM(game, moveId)
    for itemId, amount in pairs((game.save and game.save.inventory) or {}) do
      local def = game.data and game.data.items and game.data.items[itemId]
      if (tonumber(amount) or 0) > 0 and def and def.teaches == moveId
          and tostring(itemId):sub(1, 3) == "HM_" then return true end
    end
    return false
  end
  local function quickHMAvailable(game, moveId)
    if get("quick_hm") == "IGNORE" then return true end
    return ownsHM(game, moveId)
      and FieldMoves.hasBadge(game.save, FieldMoves.BADGE[moveId])
  end
  local function useHM(game, moveId)
    local world = game.world
    local party = game.save and game.save.party or {}
    local mon
    for _, candidate in ipairs(party) do if monKnows(candidate, moveId) then mon = candidate; break end end
    local mode = get("quick_hm")
    if not mon and mode == "ON" then
      if quickHMAvailable(game, moveId) then mon = party[1] end
    elseif mode == "IGNORE" then mon = mon or party[1] end
    if mon and not monKnows(mon, moveId) then quickOverride = moveId end
    if not (world and mon) then quickOverride = nil; return false end
    local oldHasBadge
    if mode == "IGNORE" then
      oldHasBadge = FieldMoves.hasBadge
      FieldMoves.hasBadge = function() return true end
    end
    local ok, result = pcall(function() return world:useFieldMove(moveId, mon) end)
    if oldHasBadge then FieldMoves.hasBadge = oldHasBadge end
    quickOverride = nil
    return ok and result and result.ok or false
  end
  local function closeQuickHM(game)
    while game.stack and game.stack:top() do game.stack:pop() end
  end
  local function newQuickHMMenu(game)
    local rows = {}
    for _, id in ipairs(HMS) do
      if quickHMAvailable(game, id) then rows[#rows+1] = {label=id, value=id} end
    end
    if #rows == 0 then rows[1] = {label="NO HM YET", value=false, disabled=true} end
    local Chrome = require("src.ui.gen2.Chrome")
    local state = { isOpaque=false }
    state.list = Chrome.List.new({
      items=rows, x=10, y=2, spacing=2, rows=math.min(7, #rows), wrap=true,
      onChoose=function(value)
        if value and useHM(game, value) then closeQuickHM(game) end
      end,
      onCancel=function() game.stack:pop() end,
    })
    state.update = function(self) self.list:update(game.input) end
    state.draw = function(self)
      -- Twelve tiles wide, anchored to the right edge. The extra interior
      -- column keeps WATERFALL/STRENGTH and NO HM YET clear of the border.
      Chrome.box(8, 0, 12, 17)
      Chrome.print("QUICK HM", 10, 1)
      self.list:draw()
    end
    return state
  end
  mod.content.screens:register(QUICK_HM, { new=newQuickHMMenu })

  local function withQuickPermissions(game, moveId, fn)
    if not quickHMAvailable(game, moveId) then return false end
    quickOverride = moveId
    local oldHasBadge
    if get("quick_hm") == "IGNORE" then
      oldHasBadge = FieldMoves.hasBadge
      FieldMoves.hasBadge = function() return true end
    end
    local ok, result = pcall(fn)
    if oldHasBadge then FieldMoves.hasBadge = oldHasBadge end
    quickOverride = nil
    return ok and result or false
  end

  local function contextualQuickHM(game)
    local world = game.world
    if not (world and world.player and world.map) then return false end
    local ctx = world:fieldContext()
    local Permissions = require("src.world.gen2.Permissions")
    local checks = {
      { "CUT", FieldMoves.tryCutOW, function()
        return Permissions.isCutTree(ctx.facingColl)
      end },
      { "WHIRLPOOL", FieldMoves.tryWhirlpoolOW, function()
        return Permissions.isWhirlpool(ctx.facingColl)
      end },
      { "WATERFALL", FieldMoves.tryWaterfallOW, function()
        return FieldMoves.canWaterfall(ctx)
      end },
    }
    for _, row in ipairs(checks) do
      -- Try*OW assumes the native tile-event dispatcher already matched the
      -- collision. Calling it on every tile makes CUT return took=true even
      -- on open ground, swallowing SURF and the fallback menu.
      if row[3]() then
        local result = withQuickPermissions(game, row[1], function()
          return row[2](ctx)
        end)
        if result and result.ok and result.took then
          result.ask = nil
          result.blockIndex = ctx.facingBlockIndex
          result.facingX, result.facingY = ctx.facingX, ctx.facingY
          return world:runOverworldFieldMove(result) and true or false
        end
      end
    end
    -- Surf through Gold's native menu entry point. Besides keeping all of the
    -- cart checks in one place, this also supplies every field the runtime's
    -- queued move path expects before we execute it immediately.
    if quickHMAvailable(game, "SURF")
        and not FieldMoves.isSurfing(ctx.playerState)
        and Permissions.isWater(ctx.facingColl)
        and not FieldMoves.directionBlocked(ctx.playerColl, ctx.facing) then
      local mon = game.save and game.save.party and game.save.party[1]
      if mon then
        local result = withQuickPermissions(game, "SURF", function()
          return world:useFieldMove("SURF", mon)
        end)
        if result and result.ok then
          world.queuedFieldMove = nil
          return world:runFieldMove(result) and true or false
        end
      end
    end
    local npc = world:npcAt(ctx.facingX, ctx.facingY)
    if world.isStrengthBoulder and world.isStrengthBoulder(npc) then
      local result = withQuickPermissions(game, "STRENGTH", function()
        return FieldMoves.tryStrengthOW(ctx)
      end)
      if result and result.ok and result.took then
        result.ask = nil
        return world:runOverworldFieldMove(result) and true or false
      end
    end
    return false
  end

  local function openQuickHM(game)
    if get("quick_hm") == "OFF" or not game.world then return false end
    if game.stack and game.stack:top() then return false end
    local world = game.world
    if world.battleActive or world:busy()
        or (world.player and world.player.moving) then return false end
    -- Context detection must never swallow the hotkey. If a map-specific
    -- collision check fails, the player must still receive the HM picker.
    local ok, used = pcall(contextualQuickHM, game)
    if ok and used then return true end
    -- Push the compact state directly. This avoids routing a host hotkey
    -- through the screen registry while the world owns the input frame.
    game.stack:push(newQuickHMMenu(game))
    return true
  end

  local function forceWildEncounter(game)
    activeGame=game
    if not get("force_encounter") or not game.world then return false end
    if game.stack and game.stack:top() then return false end
    local world=game.world
    if world.battleActive or world:busy() or (world.player and world.player.moving) then return false end
    if tostring(get("wild_select") or "OFF")~="FIRST" then
      local Encounter=require("src.battle.gen2.Encounter")
      local oldTriggers=Encounter.triggers
      local oldCooldown=world.wildCooldownStep
      local oldRepel=world.repelSuppresses
      Encounter.triggers=function() return true end
      world.wildCooldownStep=function() return false end
      world.repelSuppresses=function() return false end
      local ok,result=pcall(function() return world:tryWildEncounter() end)
      Encounter.triggers=oldTriggers
      world.wildCooldownStep=oldCooldown
      world.repelSuppresses=oldRepel
      return ok and result==true
    end
    local species=tostring(get("wild_pokemon") or "RATTATA")
    if not mod.content.pokemon:get(species) then species="RATTATA" end
    local lead=game.save and game.save.party and game.save.party[1]
    local level=math.max(2,math.min(100,tonumber(lead and lead.level) or 5))
    local Mon=require("src.battle.gen2.Mon")
    local wild=Mon.new(game.data,species,level)
    if not wild then return false end
    game.save.pokedex=game.save.pokedex or {seen={},caught={}}
    game.save.pokedex.seen[species]=true
    return world:startBattle({wild=wild}) and true or false
  end

  mod.hooks:wrap("encounter.species",function(next,enc,ctx)
    local out=next(enc,ctx)
    local mode=tostring(get("wild_select") or "OFF")
    if mode=="OFF" or not out or (ctx and ctx.kind and ctx.kind~="wild") then return out end
    local species=tostring(get("wild_pokemon") or "RATTATA")
    if not mod.content.pokemon:get(species) then return out end
    local copy={}
    for key,value in pairs(out) do copy[key]=value end
    copy.species=species
    if mode=="FIRST" then
      local lead=activeGame and activeGame.save and activeGame.save.party and activeGame.save.party[1]
      copy.level=math.max(2,math.min(100,tonumber(lead and lead.level) or tonumber(copy.level) or 5))
    end
    return copy
  end)

  local Game2 = require("src.core.Game2")
  local StartMenu = require("src.ui.gen2.StartMenu")
  local oldStartMenuChoose = StartMenu.choose
  StartMenu.choose = function(self, id, index)
    if id == "save" and get("fast_save") then
      -- Bypass Sfx_ReadText2: Fast Save should acknowledge only the completed
      -- write, not the menu press that requested it.
      if self.onChoose then self.onChoose(id) end
      return
    end
    return oldStartMenuChoose(self, id, index)
  end
  local oldOpenStartMenuItem = Game2.openStartMenuItem
  Game2.openStartMenuItem = function(self, id)
    if id == "save" and get("fast_save") then
      local saved = self:writeSave()
      if saved ~= false then
        require("src.core.Sound").play(self.data, "Sfx_Save")
      end
      if self.stack and self.stack:top() then self.stack:pop() end
      return
    end
    return oldOpenStartMenuItem(self, id)
  end
  local oldKeypressed = Game2.keypressed
  Game2.keypressed = function(self, key)
    local top = self.stack and self.stack:top()
    if top and top.mqol2EncounterKeyCapture and top.onKeyPressed then top:onKeyPressed(key); return end
    if top and top.mqol2KeyCapture and top.onKeyPressed then
      top:onKeyPressed(key)
      return
    end
    local encounterKey=tostring(get("encounter_hotkey") or "f6")
    local encounterMatch=(encounterKey=="shift" and (key=="lshift" or key=="rshift")) or key==encounterKey
    if encounterMatch and forceWildEncounter(self) then return end
    local configured = tostring(get("quick_hm_hotkey") or "shift")
    local match = (configured == "shift" and (key == "lshift" or key == "rshift")) or key == configured
    if match then
      if openQuickHM(self) then return end
    end
    return oldKeypressed(self, key)
  end
  local oldGamepadpressed = Game2.gamepadpressed
  Game2.gamepadpressed = function(self, joystick, button)
    local top = self.stack and self.stack:top()
    if top and top.mqol2EncounterCapture and top.onGamepadPressed then top:onGamepadPressed(button); return end
    if top and top.mqol2Capture and top.onGamepadPressed then top:onGamepadPressed(button); return end
    if tostring(get("encounter_gamepad"))==button and forceWildEncounter(self) then return end
    if tostring(get("quick_hm_gamepad")) == button and openQuickHM(self) then return end
    return oldGamepadpressed(self, joystick, button)
  end
  local oldGamepadaxis = Game2.gamepadaxis
  Game2.gamepadaxis = function(self, joystick, axis, value)
    local top = self.stack and self.stack:top()
    if top and top.mqol2EncounterCapture and top.onGamepadAxis then top:onGamepadAxis(axis,value); return end
    if top and top.mqol2Capture and top.onGamepadAxis then
      top:onGamepadAxis(axis, value)
      return
    end
    self.mqolTriggerLatch = self.mqolTriggerLatch or {}
    if axis == "triggerleft" or axis == "triggerright" then
      local configured = tostring(get("quick_hm_gamepad") or "OFF")
      local encounterConfigured=tostring(get("encounter_gamepad") or "OFF")
      local key = "axis:" .. axis
      local down = value >= 0.65
      if value <= 0.35 then self.mqolTriggerLatch[axis] = false end
      self.mqolEncounterTriggerLatch=self.mqolEncounterTriggerLatch or {}
      if value<=0.35 then self.mqolEncounterTriggerLatch[axis]=false end
      if encounterConfigured==key and down and not self.mqolEncounterTriggerLatch[axis] then
        self.mqolEncounterTriggerLatch[axis]=true
        if forceWildEncounter(self) then return end
      end
      if configured == key and down and not self.mqolTriggerLatch[axis] then
        self.mqolTriggerLatch[axis] = true
        if openQuickHM(self) then return end
      end
    end
    return oldGamepadaxis(self, joystick, axis, value)
  end

  -- Some controller/keyboard backends do not deliver every configured key as
  -- a Game2 event. Poll from the engine's official once-per-frame lifecycle
  -- hook; unlike replacing Game2.update, this seam remains active after the
  -- mod loader finishes composing the Gold runtime.
  mod.hooks:wrap("core.update", function(next, game, dt)
    activeGame=game
    local encounterKey=tostring(get("encounter_hotkey") or "f6")
    local encounterKeyDown=false
    if get("force_encounter") and love and love.keyboard and love.keyboard.isDown then
      if encounterKey=="shift" then encounterKeyDown=love.keyboard.isDown("lshift","rshift")
      elseif encounterKey~="OFF" then encounterKeyDown=love.keyboard.isDown(encounterKey) end
    end
    local encounterPadDown=false
    local encounterPad=tostring(get("encounter_gamepad") or "OFF")
    if get("force_encounter") and encounterPad~="OFF" and love and love.joystick and love.joystick.getJoysticks then
      for _,joystick in ipairs(love.joystick.getJoysticks()) do
        if encounterPad:sub(1,5)=="axis:" then
          local axis=encounterPad:sub(6)
          encounterPadDown=joystick.getGamepadAxis and joystick:getGamepadAxis(axis)>=0.65
        else encounterPadDown=joystick.isGamepadDown and joystick:isGamepadDown(encounterPad) end
        if encounterPadDown then break end
      end
    end
    local encounterDown=encounterKeyDown or encounterPadDown
    if encounterDown and not game.mqolEncounterLatch then forceWildEncounter(game) end
    game.mqolEncounterLatch=encounterDown

    local configuredKey = tostring(get("quick_hm_hotkey") or "shift")
    local keyDown = false
    if love and love.keyboard and love.keyboard.isDown then
      if configuredKey == "shift" then
        keyDown = love.keyboard.isDown("lshift", "rshift")
      elseif configuredKey ~= "OFF" then
        keyDown = love.keyboard.isDown(configuredKey)
      end
    end
    local padDown = false
    local configuredPad = tostring(get("quick_hm_gamepad") or "OFF")
    if configuredPad ~= "OFF" and love and love.joystick and love.joystick.getJoysticks then
      for _, joystick in ipairs(love.joystick.getJoysticks()) do
        if configuredPad:sub(1, 5) == "axis:" then
          local axis = configuredPad:sub(6)
          padDown = joystick.getGamepadAxis and joystick:getGamepadAxis(axis) >= 0.65
        else
          padDown = joystick.isGamepadDown and joystick:isGamepadDown(configuredPad)
        end
        if padDown then break end
      end
    end
    local down = keyDown or padDown
    if down and not game.mqolQuickHMLatch then openQuickHM(game) end
    game.mqolQuickHMLatch = down
    return next(game, dt)
  end)

  -- Both Gold learning flows keep their HM guard as a private upvalue. Locate
  -- that exact table once in each module and switch only its five/seven keys;
  -- no Gen 1 closure is loaded or touched.
  local hmGuardTables, hmIds = {}, {
    "CUT", "FLY", "SURF", "STRENGTH", "FLASH", "WHIRLPOOL", "WATERFALL"
  }
  local function collectHmGuards(module)
    local seen = {}
    for _, fn in pairs(module or {}) do
      if type(fn) == "function" then
        local index = 1
        while debug and debug.getupvalue do
          local name, value = debug.getupvalue(fn, index)
          if not name then break end
          if name == "HM_MOVES" and type(value) == "table" and not seen[value] then
            seen[value] = true; hmGuardTables[#hmGuardTables+1] = value
          end
          index = index + 1
        end
      end
    end
  end
  collectHmGuards(Game2)
  collectHmGuards(require("src.ui.gen2.BattleState"))
  syncForgetHM = function()
    local allow = get("forget_hm")
    for _, guard in ipairs(hmGuardTables) do
      for _, id in ipairs(hmIds) do guard[id] = allow and nil or true end
    end
  end
  syncForgetHM()

  -- Shared textbox renderer, but a Gold-specific patch instance. It fills the
  -- current text section immediately while preserving page/scroll waits.
  local TextBox = require("src.render.TextBox")
  local Timing = require("src.core.Timing")
  local oldTextUpdate = TextBox.update
  TextBox.update = function(self, dt)
    if get("instant_text") and not self.done and not self.waiting
        and (self.holdFrames or 0) <= 0 then
      while not self.done and not self.waiting do
        local line = self.shown[#self.shown]
        while self.charIndex < #self.codes do
          self.charIndex = self.charIndex + 1
          line[#line+1] = self.codes[self.charIndex]
        end
        local page = self.pages[self.pageIndex]
        if self.lineIndex < #page then
          local nextIndex = self.lineIndex + 1
          local conts = self.pages.contBefore and self.pages.contBefore[self.pageIndex]
          if conts and conts[nextIndex] then
            self.waiting = true; self.preWait = Timing.TEXT_PRE_ADVANCE; self.contAdvance = true
          else
            self.lineIndex = nextIndex; self:beginLine()
          end
        elseif self.pageIndex < #self.pages then
          self.waiting = true; self.preWait = Timing.TEXT_PRE_ADVANCE; self.contAdvance = false
        else self.done = true end
      end
      return
    end
    return oldTextUpdate(self, dt)
  end

  -- Gold has four native pockets. Expand the number of distinct slots while
  -- preserving Gold's native 99-unit maximum for each individual item.
  -- apply the selected automatic ordering to the native Pack rows.
  local Bag = require("src.inventory.Bag")
  Bag.capacity = function(data, pocket) return 999 end
  local PackMenu = require("src.ui.gen2.PackMenu")
  local function makeTypeRanks(groups)
    local ranks, rank = {}, 0
    for group, ids in ipairs(groups) do
      for order, id in ipairs(ids) do
        rank = rank + 1
        ranks[id] = { group=group, order=order, rank=rank }
      end
    end
    return ranks
  end
  local ITEM_TYPE_RANK = makeTypeRanks({
    -- HP recovery
    {"POTION","SUPER_POTION","HYPER_POTION","MAX_POTION",
     "FULL_RESTORE","FRESH_WATER","SODA_POP","LEMONADE","MOOMOO_MILK",
     "ENERGYPOWDER","ENERGY_ROOT"},
    -- Revive
    {"REVIVE","MAX_REVIVE","REVIVAL_HERB"},
    -- Status recovery
    {"ANTIDOTE","BURN_HEAL","ICE_HEAL","AWAKENING","PARLYZ_HEAL",
     "FULL_HEAL","HEAL_POWDER"},
    -- PP recovery
    {"ETHER","MAX_ETHER","ELIXER","MAX_ELIXER","PP_UP"},
    -- Berries stay together instead of being split across HP/status/PP groups.
    {"BERRY","GOLD_BERRY","PRZCUREBERRY","PSNCUREBERRY","BITTER_BERRY",
     "BURNT_BERRY","ICE_BERRY","MINT_BERRY","MIRACLEBERRY","MYSTERYBERRY"},
    -- Permanent growth
    {"HP_UP","PROTEIN","IRON","CARBOS","CALCIUM","RARE_CANDY"},
    -- Evolution
    {"SUN_STONE","MOON_STONE","FIRE_STONE","THUNDERSTONE","THUNDER_STONE",
     "WATER_STONE","LEAF_STONE"},
    -- In-battle items
    {"X_ATTACK","X_DEFEND","X_SPEED","X_SPECIAL","X_ACCURACY",
     "GUARD_SPEC","DIRE_HIT","POKE_DOLL","FLUFFY_TAIL"},
    -- Exploration
    {"REPEL","SUPER_REPEL","MAX_REPEL","ESCAPE_ROPE"},
    -- Apricorn crafting
    {"RED_APRICORN","BLU_APRICORN","YLW_APRICORN","GRN_APRICORN",
     "WHT_APRICORN","BLK_APRICORN","PNK_APRICORN"},
    -- Sellable treasures
    {"NUGGET","PEARL","BIG_PEARL","STARDUST","STAR_PIECE","BRICK_PIECE"},
  })
  local BALL_TYPE_RANK = makeTypeRanks({
    {"POKE_BALL","GREAT_BALL","ULTRA_BALL","MASTER_BALL"},
    {"FAST_BALL","LEVEL_BALL","LURE_BALL","HEAVY_BALL","LOVE_BALL",
     "FRIEND_BALL","MOON_BALL"},
    {"PARK_BALL","SPORT_BALL"},
  })
  local KEY_TYPE_RANK = makeTypeRanks({
    {"BICYCLE","OLD_ROD","GOOD_ROD","SUPER_ROD","ITEMFINDER"},
    {"COIN_CASE","RADIO_CARD","MAP_CARD","PHONE_CARD","EXPN_CARD",
     "POKEGEAR"},
    {"SQUIRTBOTTLE","SECRETPOTION","CARD_KEY","BASEMENT_KEY",
     "S_S_TICKET","MACHINE_PART","LOST_ITEM","PASS"},
    {"MYSTERY_EGG","RED_SCALE","CLEAR_BELL","SILVER_WING","RAINBOW_WING"},
  })
  local function typeRank(self, row)
    local pocket = self:pocket().id
    if pocket == "ITEM" then
      local entry = ITEM_TYPE_RANK[row.id]
      return entry and entry.rank or 9000
    elseif pocket == "BALL" then
      local entry = BALL_TYPE_RANK[row.id]
      return entry and entry.rank or 9000
    elseif pocket == "KEY_ITEM" then
      local entry = KEY_TYPE_RANK[row.id]
      return entry and entry.rank or 9000
    elseif pocket == "TM_HM" then
      local id = tostring(row.id)
      local hm = tonumber(id:match("^HM_?(%d+)$"))
      local tm = tonumber(id:match("^TM_?(%d+)$"))
      if hm then return hm end
      if tm then return 100 + tm end
      return 9000
    end
    return 9000
  end
  local oldPackRebuild = PackMenu.rebuild
  PackMenu.rebuild = function(self)
    oldPackRebuild(self)
    local mode = get("bag_sort")
    if mode == "OFF" then return end
    table.sort(self.rows, function(a, b)
      if mode == "NAME" and a.name ~= b.name then return a.name < b.name end
      if mode == "QUANTITY" and a.count ~= b.count then return a.count > b.count end
      if mode == "TYPE" then
        local ar, br = typeRank(self, a), typeRank(self, b)
        if ar ~= br then return ar < br end
      end
      return a.id < b.id
    end)
  end
  local oldPackUpdate = PackMenu.update
  PackMenu.update = function(self, dt)
    local input = self.game and self.game.input
    if input and not self.qtyState and not self.message and not self.confirm
        and not self.submenu and input:wasPressed("start") then
      mod.ui.push(self.game, BAG_SORT_SCREEN)
      return
    end
    return oldPackUpdate(self, dt)
  end

  -- TMs are retained after a successful teach. HMs are already reusable in
  -- Gold and all refusal paths still consume nothing.
  local oldConsumeItem = Game2.consumeItem
  Game2.consumeItem = function(self, itemId)
    local def = self.data and self.data.items and self.data.items[itemId]
    if get("unlimited_tm") and def and def.teaches
        and tostring(itemId):sub(1, 3) ~= "HM_" then return end
    return oldConsumeItem(self, itemId)
  end

  -- Fast Center owns the nurse interaction itself. Other heal-machine users
  -- (Elm and Hall of Fame) keep their native scripts and animations.
  local World = require("src.world.gen2.World")
  local oldInteractBody = World.interactBody
  World.interactBody = function(self)
    if get("fast_center") and not self:busy() and self.player and self.map then
      local Map = require("src.world.gen2.Map")
      local Permissions = require("src.world.gen2.Permissions")
      local p = self.player
      local delta = Map.DELTA[p.facing]
      local fx, fy = p.cellX + delta[1], p.cellY + delta[2]
      local ox, oy = fx, fy
      if Permissions.isCounter(self.map:cellCollision(fx, fy)) then
        ox, oy = p.cellX + delta[1] * 2, p.cellY + delta[2] * 2
      end
      local npc = self:npcAt(ox, oy)
      if npc and npc.def and npc.def.sprite == "SPRITE_NURSE" then
        self:healParty()
        require("src.core.Music").playOnce(self.game.data, "Music_HealPokemon")
        return true
      end
    end
    return oldInteractBody(self)
  end

  -- Gold hidden items are background events, not Gen 1 field rows. Draw the
  -- same shrinking radar marker only for an unfound item in ITEMFINDER range.
  local HiddenItems = require("src.world.gen2.HiddenItems")
  local oldWorldDraw = World.draw
  World.draw = function(self)
    local result = oldWorldDraw(self)
    local mode = get("itemfinder")
    if mode == "OFF" or not self.map or not self.player then return result end
    if mode == "HAVE ITEM" then
      local def = self.game and self.game.data and self.game.data.items
        and self.game.data.items.ITEMFINDER
      if not (def and self:hasItem(def.index)) then return result end
    end
    local row = HiddenItems.nearby(self.map.def, self.player.cellX,
      self.player.cellY, self.events)
    if not row then return result end
    local scale = self:zoomScale()
    local x = (row.x * 16 - self.camera.x) * scale
    local y = (row.y * 16 - self.camera.y) * scale
    local pulse = (love.timer.getTime() * 2) % 1
    local size = math.max(5, math.floor((16 - pulse * 10) * scale))
    local cx, cy = x + 8 * scale, y + 8 * scale
    local G = love.graphics
    local oldWidth = G.getLineWidth()
    G.setLineWidth(math.max(1, scale))
    G.setColor(0, 0, 0, 1); G.rectangle("line", cx-size/2-1, cy-size/2-1, size+2, size+2)
    G.setColor(1, 1, 1, 1); G.rectangle("line", cx-size/2, cy-size/2, size, size)
    G.setLineWidth(oldWidth); G.setColor(1, 1, 1, 1)
    return result
  end

  -- Gold already has corrected Gen 2 typing, so Type Fixes is deliberately
  -- absent rather than applying Gen 1 balance patches to Gold's type chart.
  mod.log:info("myQualityOfLife Gold implementation loaded (v1.3 beta)")
end
