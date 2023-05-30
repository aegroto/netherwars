if minetest.get_modpath("tnt") then
  local good=false
  for k,v in pairs(minetest.registered_abms) do
    if v.label=="TNT ignition" then
      good=true
      break
    end
  end
  if not good then return end
end
local modname=minetest.get_current_modname()

local tex_unproto_inc="default_tool_diamondsword.png^protector_logo.png"
local tex_unproto=tex_unproto_inc.."^[invert:rgb"
local tex_unproto_off=tex_unproto.."^[multiply:#808080"

local unp_n=modname..":unprotect_off"
local unp_na=modname..":unprotect_on"

local repls={
  [unp_n]=unp_na,
  [unp_na]=unp_n
}

do
  local on_place=function(stack)
    local iname=stack:get_name()
    assert(repls[iname])
    if stack:get_wear()<65535 then
      stack:set_name(repls[iname])
    end
    return stack
  end
  local def={
    description = "The Unprotector",
    inventory_image = tex_unproto_off,
    groups={not_repaired_by_anvil=1},
    wear_represents="absolutely fucking nothing",
    on_place=on_place,
    on_secondary_use=on_place
  }
  local od=table.copy(def)
  local ad=table.copy(def)
  ad.groups={not_in_creative_inventory=1}
  ad.inventory_image=tex_unproto
  minetest.register_tool(unp_n,od)
  minetest.register_tool(unp_na,ad)
end

do
  local u=unp_n
  local c="default:diamondblock"
  local m="default:mese"
  local recipe={
    {m,c,m},
    {c,u,c},
    {m,c,m},
  }
  minetest.register_craft({
    output=u,
    recipe=recipe
  })
  minetest.register_on_craft(function(stack,pl,rec,inv)
    for y=1,3 do
      for x=1,3 do
        local n=(y-1)*3+x
        if rec[n]:get_name()~=recipe[y][x] then
          return
        end
      end
    end
    stack:set_wear(0)
    return stack
  end)
end

local stt=0;
local fns={}
local function push(...)
  table.insert(fns,{...})
end
local function newstage(items,p,n)
  local raw=modname..":icu"..stt
  local sss=stt
  stt=stt+1
  push(function()minetest.register_craftitem(raw,{
    description = ("Incomplete Unprotector (%.1f%%)"):format((sss+1)/(stt+1)*100),
    inventory_image = tex_unproto_inc,
    groups={not_in_creative_inventory=1},
  })end)
  if not n then
    local sss=stt
    n=modname..":icu"..stt
    stt=stt+1
    push(function()minetest.register_craftitem(n,{
      description = ("Incomplete Unprotector (%.1f%%)"):format((sss+1)/(stt+1)*100),
      inventory_image = tex_unproto_inc,
      groups={not_in_creative_inventory=1},
    })end)
  end
  local a,b=unpack(items)
  a=a or b
  b=b or a
  push(function()minetest.register_craft({
    output=raw,
    recipe={
      {a,p,a},
      {b,b,b},
      {a,p,a},
    }
  })
  minetest.register_craft({
    type = "cooking",
    output = n,
    recipe = raw,
  })end)
  return n
end

local function st(item)
  local t={i=item}
  function t:f(items,n)
    self.i=newstage(items,self.i,n)
    return self
  end
  return t
end

local wear=0;

minetest.register_globalstep(function(dt)
  wear=wear+65535/30*dt
  local ww=math.floor(wear)
  wear=wear-ww
  for _,pl in ipairs(minetest.get_connected_players()) do
    local name = pl:get_player_name()
    local privs = minetest.get_player_privs(name)
    local inv = pl:get_inventory()
    privs.protection_bypass=nil
    for k,v in pairs(inv:get_list("main")) do
      if v:get_name()==unp_na then
        if v:get_wear()<65535 then
          v:set_wear(math.min(65535,v:get_wear()+ww))
          privs.protection_bypass=true
        else
          v:set_name(unp_n)
        end
        inv:set_stack("main",k,v)
      end
    end
    minetest.set_player_privs(name,privs)
  end
end)

st("default:sword_diamond")
:f{"","protector:protect"}
:f({"tnt:tnt"})
:f({"default:copperblock"})
:f({"default:obsidian"})
:f({"default:diamondblock","default:steelblock"})
:f({"","default:mese"})
:f({"dye:red","basic_materials:energy_crystal_simple"},unp_n)

for k,v in ipairs(fns) do
  v[1](unpack(v,2))
end
