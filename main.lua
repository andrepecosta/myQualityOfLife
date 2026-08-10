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
    fast_center = false,
    fast_save = false,
    never_miss = false,
    always_crit = false,
    infinite_pp = false,
    always_catch = false,
    exp_multiplier = "OFF",    -- OFF / 2X / 3X / 4X
    exp_share = "OFF",         -- OFF / ACTIVE (shown as GEN1) / SMART
    move_info = false,
    move_editor = "OFF",       -- TODOS / BASE / OFF
    forget_hm = false,
    unlimited_tm = false,
    quick_hm = "OFF",          -- OFF / ON / IGNORE
    quick_hm_hotkey = "shift",
    bag_sort = "OFF",          -- OFF / NAME / QUANTITY / TYPE
    pikachu_evo = false,
  }

  local MISC_KEYS = { "fast_run", "auto_run", "instant_text", "itemfinder", "fast_center", "fast_save", "bag_sort" }
  local BATTLE_KEYS = { "exp_share", "move_info" }
  local POKEMON_KEYS = { "forget_hm", "unlimited_tm", "quick_hm", "quick_hm_hotkey", "pikachu_evo" }
  local CHEAT_KEYS = { "never_miss", "always_crit", "infinite_pp", "always_catch", "exp_multiplier", "move_editor" }

  local function get(key)
    return mod.save:get(key, DEFAULTS[key])
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

  local function cycle(game, key, values)
    local cur = get(key)
    local idx = 1
    for i, v in ipairs(values) do if v == cur then idx = i break end end
    idx = idx % #values + 1
    set(game, key, values[idx])
  end

  local function hotkeyText(key)
    key=tostring(key or "shift")
    local names={
      shift="SHIFT", lctrl="LEFT CTRL", rctrl="RIGHT CTRL",
      lalt="LEFT ALT", ralt="RIGHT ALT", capslock="CAPS LOCK",
      pageup="PAGE UP", pagedown="PAGE DOWN",
    }
    return names[key] or key:upper()
  end

  local BLOCKED_HOTKEYS={
    up=true,down=true,left=true,right=true,w=true,a=true,s=true,d=true,
    z=true,x=true,["return"]=true,space=true,backspace=true,escape=true,tab=true,
    ["1"]=true,["2"]=true,["3"]=true,["4"]=true,["5"]=true,
    f1=true,f2=true,f5=true,f10=true,
  }

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
    local typ = typeName(game, def.type or def.moveType or def.typeId or def.type_id)
    -- Some data tables expose display strings such as "PSYCHIC TYPE".
    -- The footer already represents the Type field, so keep only the type name.
    typ = tostring(typ):gsub("[%s_%-]*TYPE$", "")
    if typ == "" then typ = "--" end
    local pp = tostring(def.pp or def.basePP or "--")
    local pwr = tonumber(def.power)
    local acc = tonumber(def.accuracy)
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

  local function baseMoves(game, mon)
    local set = {}
    local data = game and game.data
    if not data or not data.pokemon or not mon then return set end
    addLearnset(set, data.pokemon[mon.species])
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
      if type(tbl) == "table" then addLearnset(set, tbl[mon.species]) end
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
      local menu=mod.ui.ListMenu.new(game,"QUICK HM HOTKEY",{
        {label="PRESS A KEY"},
        {label="ESC TO CANCEL"},
      },{ rows=2 })
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
        refresh(parent,game,POKEMON_SCREEN)
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
        {label="MOVE EDITOR", right=tostring(get("move_editor")), value="move_editor"},
        {label="RESET DEFAULTS", value="reset"},
      }
      local menu = mod.ui.ListMenu.new(game,"CHEATS",items,{
        onChoose=function(item,menu)
          if item.value == "move_editor" then
            cycle(game,"move_editor",{"TODOS","BASE","OFF"})
          elseif item.value == "exp_multiplier" then
            cycle(game,"exp_multiplier",{"OFF","2X","3X","4X"})
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
    if get("quick_hm")~="OFF" then
      out=mod.ui.insertBefore(out,"SAVE",{
        label="QUICK HM",
        onSelect=function() mod.ui.push(game,QUICK_HM_SCREEN) end,
      })
    end
    return mod.ui.insertBefore(out, "SAVE", {
      label="MOD OPTIONS",
      onSelect=function() mod.ui.push(game,MAIN_SCREEN) end,
    })
  end)

  -- Configurable keyboard shortcut. It claims the key only during free
  -- overworld control; everywhere else the engine receives its normal input.
  local Game=require("src.core.Game")
  local oldGameKeyPressed=Game.keypressed
  Game.keypressed=function(self,key)
    local configured=tostring(get("quick_hm_hotkey") or "shift")
    local matches=(configured=="shift" and (key=="lshift" or key=="rshift"))
                  or key==configured
    if get("quick_hm")~="OFF" and matches then
      local ow=self.overworld
      local top=self.stack and self.stack:top()
      local busy=not ow or top~=ow or ow.transitioning
        or (ow.runner and ow.runner.isRunning and ow.runner:isRunning())
        or (ow.scriptMoves and #ow.scriptMoves>0)
        or ow.engaging or ow.emote
      if not busy then
        mod.ui.push(self,QUICK_HM_SCREEN)
        return
      end
    end
    return oldGameKeyPressed(self,key)
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
  mod.hooks:wrap("battle.accuracy", function(next, ctx)
    if get("never_miss") and ctx and ctx.user and ctx.user.isPlayer then return true end
    return next(ctx)
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

  -- SMART may provide an exact per-mon award.  The optional cheat multiplier
  -- is applied once to that amount or to the engine's normal calculated gain.
  -- Experience.apply still owns stats, levels, move learning and battle text.
  mod.hooks:wrap("exp.gain", function(next, ctx)
    local v = ctx and ctx.mon and forcedExp[ctx.mon]
    local gained=v ~= nil and v or next(ctx)
    local setting=get("exp_multiplier")
    local multiplier=tonumber(tostring(setting):match("^(%d+)X$")) or 1
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
    if pool==0 or #recipients==0 then return alloc end

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
    for i,mon in ipairs(group) do
      alloc[mon]=each+(i<=rem and 1 or 0)
    end
    return alloc
  end

  local function sharedExpSummary(battle, recipients, total, insertAfter)
    recipients=math.max(0,math.floor(recipients or 0))
    total=math.max(0,math.floor(total or 0))
    if recipients==0 or total==0 or not battle or not battle.sayNext then return end
    -- Experience.apply queues level-up text immediately through sayNext. When
    -- the total is only known after applying every share, temporarily restore
    -- the insertion cursor captured before those awards so this summary is
    -- displayed first, then advance it past every row already queued.
    local queuedThrough=battle.nextInsert
    if insertAfter~=nil then battle.nextInsert=insertAfter end
    if recipients==1 then
      battle:sayNext(("1 POKéMON gained\n%d EXP!"):format(total))
    else
      battle:sayNext(("%d POKéMON shared\n%d EXP!"):format(recipients,total))
    end
    if insertAfter~=nil then battle.nextInsert=(queuedThrough or insertAfter)+1 end
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
    local others=eligibleNonParticipants(battle,participantSet)
    if #others==0 then return next(ctx) end

    -- Participants divide one half equally.  For example, two participants
    -- each receive 25%, regardless of which one landed the final blow. Keep
    -- every participant's native gained-EXP row together at the front, while
    -- leaving their level-up rows behind it. This gives the shared summary a
    -- stable insertion point between gained EXP and resulting level changes.
    local participantSplit=2*math.max(1,tonumber(ctx.participants) or #ctx.alive)
    local participantQueueStart=battle.nextInsert or 0
    local participantAnnouncements=0
    for _,mon in ipairs(ctx.alive or {}) do
      if (mon.level or 0)<100 then
        local before=battle.nextInsert or participantQueueStart
        ctx.applyShare(mon,participantSplit,true)
        local after=battle.nextInsert or before
        if after>before and battle.queue then
          local announcement=table.remove(battle.queue,before+1)
          battle.nextInsert=after-1
          participantAnnouncements=participantAnnouncements+1
          table.insert(battle.queue,
            participantQueueStart+participantAnnouncements,announcement)
          battle.nextInsert=battle.nextInsert+1
        end
      end
    end
    local summaryInsert=participantQueueStart+participantAnnouncements

    if mode=="ACTIVE" then
      local split=2*#others
      local recipients,total=0,0
      for _,mon in ipairs(others) do
        local before=tonumber(mon.exp) or 0
        ctx.applyShare(mon,split,nil)
        local gained=math.max(0,(tonumber(mon.exp) or before)-before)
        if gained>0 then recipients=recipients+1; total=total+gained end
      end
      sharedExpSummary(battle,recipients,total,summaryInsert)
      return
    end

    -- SMART: same 50% pool, directed at the lowest levels until equalized.
    local Experience=require("src.battle.Experience")
    local enemy=battle.enemy and battle.enemy.mon
    local enemyDef=battle.enemy and battle.enemy.def
    if not enemy or not enemyDef then return end
    local isTrainer=battle.kind=="trainer"
    local pool=Experience.gainFor(enemyDef,enemy.level,isTrainer,2,false,battle.data.constants)
    local alloc=smartAlloc(battle.data,others,pool)
    local statSplit=2*math.max(1,#others)
    local recipients,total=0,0
    for _,mon in ipairs(others) do
      local amount=alloc[mon] or 0
      if amount>0 then
        local before=tonumber(mon.exp) or 0
        forcedExp[mon]=amount
        ctx.applyShare(mon,statSplit,nil)
        forcedExp[mon]=nil
        local gained=math.max(0,(tonumber(mon.exp) or before)-before)
        if gained>0 then recipients=recipients+1; total=total+gained end
      end
    end
    sharedExpSummary(battle,recipients,total,summaryInsert)
  end)

  -- ---------------- field/QoL hooks ----------------
  -- Fast Run / Auto Run only apply to a step that was started directly by
  -- the player's overworld input handler. Holding B during a scripted move
  -- must not accelerate that move, and Auto Run must behave the same way.
  --
  -- Important: simply checking whether a direction or B is held is not
  -- enough. During a cutscene the player can keep those buttons held while
  -- a script calls Player:tryMove(). We therefore locate Player:tryMove in
  -- the synchronous Lua stack and classify the *direct caller* that started
  -- the step. Script/update-driven callers stay at vanilla speed.
  local function stepCameFromDirectPlayerInput(ctx)
    if not ctx or not ctx.player or ctx.player.inputLocked then return false end
    if not (debug and debug.getinfo) then return false end

    local tryMoveLevel = nil
    for level = 3, 24 do
      local info = debug.getinfo(level, "nS")
      if not info then break end
      local src = tostring(info.short_src or info.source or ""):lower()
      local name = tostring(info.name or ""):lower()
      if name == "trymove" or src:find("src/world/player.lua", 1, true) then
        tryMoveLevel = level
        break
      end
    end
    if not tryMoveLevel then return false end

    -- The first frame above Player:tryMove is the code that actually
    -- requested this step. Only the normal direction-input handlers count
    -- as manual control. Everything else (script command, cutscene update,
    -- forced movement, transition logic, etc.) is deliberately rejected.
    for level = tryMoveLevel + 1, tryMoveLevel + 4 do
      local info = debug.getinfo(level, "nS")
      if not info then break end
      local src = tostring(info.short_src or info.source or ""):lower()
      local name = tostring(info.name or ""):lower()

      if src:find("src/script", 1, true) or src:find("commands.lua", 1, true)
         or name:find("script", 1, true) then
        return false
      end

      if name == "handleinput" or name == "handledirectionbuttonpress"
         or name == "handledirection" then
        return true
      end

      -- Skip tiny wrapper/anonymous frames, but do not accept a generic
      -- overworld/update caller: scripted movement can pass through those.
      if name ~= "" and name ~= "call" and name ~= "wrap" then
        return false
      end
    end

    return false
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

  mod.content.screens:register(QUICK_HM_SCREEN,{
    new=function(game)
      local rows={}
      for _,hm in ipairs(QUICK_HMS) do
        if quickHMAvailable(game,hm) then rows[#rows+1]={label=hm.move,value=hm.move} end
      end
      return mod.ui.ListMenu.new(game,"QUICK HM",rows,{
        onChoose=function(item,menu)
          if not item then return end
          if menu and menu.close then menu:close() end
          runQuickHM(game,item.value)
        end,
      })
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

    function list:refreshPocket(keepValue)
      local selected=keepValue
      if not selected then
        local current=self.items and self.items[self.index or 1]
        selected=current and current.value
      end
      self.items=buildPocketItems(game,BAG_POCKETS[bagPocket].key,get("bag_sort"))
      self.index=1
      if selected then
        for i,row in ipairs(self.items) do
          if row.value==selected then self.index=i break end
        end
      end
      self.scroll=math.max(0,self.index-(self.rows or 7))
      self.swapIndex=nil
      self.title=BAG_POCKETS[bagPocket].label
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
    local result=oldDrawBattleText(self)
    if get("move_info") and self.phase=="moveSelect" and self.player
       and self.player.disabledSlot~=self.moveIndex then
      local selected=self.player.curMoves and self.player.curMoves[self.moveIndex]
      local def=selected and self.data.moves[selected.id]
      if def then
        local Font=require("src.render.Font")
        local power=tonumber(def.power)
        local accuracy=tonumber(def.accuracy)
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
end
