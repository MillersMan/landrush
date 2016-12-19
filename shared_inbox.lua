-- 99.99 % code from homedcor modpack inbox
-- original code licensed under gpl version 3
-- original code by VanessaE
-- modified for use on fozland server by mootpoint license gpl version 3 for
-- all textures :  CC-by-SA 3.0 or higher
-- original textures by VanessaE
local fozland = {}
screwdriver = screwdriver or {}

minetest.register_craft({
	output ="fozland:shared_mailbox",
	recipe = {
		{"", "inbox:empty", ""},
		{"", "inbox:empty", ""},
		{"", "", ""}
	}
})

local mb_cbox = {
	type = "fixed",
	fixed = { -5/16, -8/16, -8/16, 5/16, 2/16, 8/16 }
}

minetest.register_node("fozland:shared_mailbox", {
	paramtype = "light",
	drawtype = "mesh",
	mesh = "inbox_mailbox.obj",
	description = "Shared Mailbox",
	tiles = {
		"shared_inbox_red_metal.png",
		"shared_inbox_blue_metal.png",
		"shared_inbox_grey_metal.png",
	},
	inventory_image = "shared_mailbox_inv.png",
	selection_box = mb_cbox,
	collision_box = mb_cbox,
	paramtype2 = "facedir",
	groups = {choppy=2,oddly_breakable_by_hand=2},
	sounds = default.node_sound_wood_defaults(),
	on_rotate = screwdriver.rotate_simple,
	after_place_node = function(pos, placer, itemstack)
		local meta = minetest.get_meta(pos)
		local owner = placer:get_player_name()
		meta:set_string("owner", owner)
		meta:set_string("infotext", "Shared Mailbox")
		local inv = meta:get_inventory()
		inv:set_size("main", 8*4)
		inv:set_size("drop", 1)
	end,
	on_rightclick = function(pos, node, clicker, itemstack)
		local meta = minetest.get_meta(pos)
		local player = clicker:get_player_name()
		local owner  = meta:get_string("owner")
		local meta = minetest.get_meta(pos)
		if owner == player or not minetest.is_protected(pos, player)  then
			minetest.show_formspec(
				clicker:get_player_name(),
				"default:chest_locked",
				fozland.get_inbox_formspec(pos))
		else
			minetest.show_formspec(
				clicker:get_player_name(),
				"default:chest_locked",
				fozland.get_inbox_insert_formspec(pos))
		end
		return itemstack
	end,
	can_dig = function(pos,player)
		local meta = minetest.get_meta(pos);
		local name = player and player:get_player_name()
		local owner = meta:get_string("owner")
		local inv = meta:get_inventory()
		return name == owner and inv:is_empty("main")
	end,
	on_metadata_inventory_put = function(pos, listname, index, stack, player)
		local meta = minetest.get_meta(pos)
		local inv = meta:get_inventory()
		if listname == "drop" and inv:room_for_item("main", stack) then
			inv:remove_item("drop", stack)
			inv:add_item("main", stack)
		end
	end,
	allow_metadata_inventory_put = function(pos, listname, index, stack, player)
		if listname == "main" then
			return 0
		end
		if listname == "drop" then
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			if inv:room_for_item("main", stack) then
				return -1
			else
				return 0
			end
		end
	end,
})

function fozland.get_inbox_formspec(pos)
	local spos = pos.x .. "," .. pos.y .. "," ..pos.z
	local formspec =
		"size[8,9]"..
		"list[nodemeta:".. spos .. ";main;0,0;8,4;]"..
		"list[current_player;main;0,5;8,4;]" ..
		"listring[]"
	return formspec
end

function fozland.get_inbox_insert_formspec(pos)
	local spos = pos.x .. "," .. pos.y .. "," ..pos.z
	local formspec =
		"size[8,9]"..
		"list[nodemeta:".. spos .. ";drop;3.5,2;1,1;]"..
		"list[current_player;main;0,5;8,4;]"..
		"listring[]"
	return formspec
end


