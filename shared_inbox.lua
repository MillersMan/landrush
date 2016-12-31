-- Adapted from homedcor modpack inbox licensed under gpl version 3 by VanessaE.
-- Modified by mootpoint and Foz license gpl version 3
-- textures:  CC-by-SA 3.0 or higher

if minetest.get_modpath('inbox') then

	screwdriver = screwdriver or {}

	local function take_fs(pos)
		local spos = pos.x .. ',' .. pos.y .. ',' ..pos.z
		local formspec =
			'size[8,9]'..
			default.gui_bg ..
			default.gui_bg_img ..
			default.gui_slots ..
			'list[nodemeta:' .. spos .. ';main;0,0.3;8,4;]' ..
			'list[current_player;main;0,4.85;8,1;]' ..
			'list[current_player;main;0,6.08;8,3;8]' ..
			'listring[nodemeta:' .. spos .. ';main]' ..
			'listring[current_player;main]' ..
			default.get_hotbar_bg(0,4.85)
		return formspec
	end

	local function give_fs(pos)
		local spos = pos.x .. ',' .. pos.y .. ',' ..pos.z
		local formspec =
			'size[8,9]'..
			default.gui_bg ..
			default.gui_bg_img ..
			default.gui_slots ..
			'list[nodemeta:'.. spos .. ';drop;3.5,2;1,1;]'..
			'list[current_player;main;0,4.85;8,1;]' ..
			'list[current_player;main;0,6.08;8,3;8]' ..
			'listring[nodemeta:' .. spos .. ';drop]' ..
			'listring[current_player;main]' ..
			default.get_hotbar_bg(0,4.85)
		return formspec
	end

	local mb_cbox = {
		type = 'fixed',
		fixed = { -5/16, -8/16, -8/16, 5/16, 2/16, 8/16 }
	}

	minetest.register_node(':landrush:shared_mailbox', {
		paramtype = 'light',
		drawtype = 'mesh',
		mesh = 'inbox_mailbox.obj',
		description = 'Shared Mailbox',
		tiles = {
			'landrush_shared_inbox_flag.png',
			'landrush_shared_inbox_box.png',
			'inbox_grey_metal.png',
		},
		inventory_image = 'landrush_shared_mailbox_inv.png',
		selection_box = mb_cbox,
		collision_box = mb_cbox,
		paramtype2 = 'facedir',
		groups = {choppy=2,oddly_breakable_by_hand=2},
		sounds = default.node_sound_wood_defaults(),
		on_rotate = screwdriver.rotate_simple,
		after_place_node = function(pos, placer, itemstack)
			local meta = minetest.get_meta(pos)
			meta:set_string('infotext', 'Shared Mailbox')
			local inv = meta:get_inventory()
			inv:set_size('main', 8*4)
			inv:set_size('drop', 1)
		end,
		on_rightclick = function(pos, node, clicker, itemstack)
			local name = clicker:get_player_name()
			if clicker:get_player_control().aux1 or
			   minetest.is_protected(pos, name) then
				minetest.show_formspec(name, 'landrush:shared_inbox',	give_fs(pos))
			else
				minetest.show_formspec(name, 'landrush:shared_inbox',	take_fs(pos))
			end
			return itemstack
		end,
		can_dig = function(pos,player)
			local meta = minetest.get_meta(pos);
			local inv = meta:get_inventory()
			return inv:is_empty('main')
		end,
		allow_metadata_inventory_put = function(pos, listname, index, stack, player)
			if listname == 'drop' then
				local meta = minetest.get_meta(pos)
				local inv = meta:get_inventory()
				if inv:room_for_item('main', stack) then
					return -1
				end
			end
			return 0
		end,
		allow_metadata_inventory_take = function(pos, listname, index, stack, player)
			if minetest.is_protected(pos, player:get_player_name()) then
				return 0
			end
			return stack:get_count()
		end,
		on_metadata_inventory_put = function(pos, listname, index, stack, player)
			local meta = minetest.get_meta(pos)
			local inv = meta:get_inventory()
			inv:remove_item('drop', stack)
			inv:add_item('main', stack)

			local name = player:get_player_name()
			local stuff = stack:get_count()..' '..stack:get_name()
			local action = ' puts '..stuff..' in shared inbox at '
			local location = minetest.pos_to_string(pos)
			minetest.log('action',name..action..location)
		end,
		on_metadata_inventory_take = function(pos, listname, index, stack, player)
			local name = player:get_player_name()
			local stuff = stack:get_count()..' '..stack:get_name()
			local action = ' takes '..stuff..' from shared inbox at '
			local location = minetest.pos_to_string(pos)
			minetest.log('action',name..action..location)
		end,
	})

	minetest.register_craft({
		output ='landrush:shared_mailbox',
		recipe = {
			{'', 'inbox:empty', ''},
			{'', 'inbox:empty', ''},
			{'', '', ''}
		}
	})

end
