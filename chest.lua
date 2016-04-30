-- add a special chest that is shared among the land-possesors

local chest_formspec =
	"size[8,9]" ..
	default.gui_bg ..
	default.gui_bg_img ..
	default.gui_slots ..
	"list[current_name;main;0,0.3;8,4;]" ..
	"list[current_player;main;0,4.85;8,1;]" ..
	"list[current_player;main;0,6.08;8,3;8]" ..
	"listring[current_name;main]" ..
	"listring[current_player;main]" ..
	default.get_hotbar_bg(0,4.85)

local log_chest_access = function(pos,name,action)
	minetest.log(
		"action",
		name ..
		" " ..
		action ..
		" the shared chest at " ..
		minetest.pos_to_string(pos)
	)
end

local log_chest_access_attempt = function(pos,name,action)
		action = "tried to " .. action
		log_chest_access(pos,name,action)
end

minetest.register_node("landrush:shared_chest", {
		description = "Land Rush Shared Chest",
		tiles = {
			"landrush_shared_chest_top.png",
			"landrush_shared_chest_top.png",
			"landrush_shared_chest_side.png",
			"landrush_shared_chest_side.png",
			"landrush_shared_chest_side.png",
			"landrush_shared_chest_front.png"
		},
		groups = {
			snappy=2,
			choppy=2,
			oddly_breakable_by_hand=2,
			tubedevice=1,
			tubedevice_receiver=1
		},
		paramtype2 = "facedir",
		legacy_facedir_simple = true,
		sounds = default.node_sound_wood_defaults(),

		can_dig = function(pos,player)
			local meta = minetest.get_meta(pos);
			local inv = meta:get_inventory()
			return inv:is_empty("main")
		end,

		on_construct = function(pos)
			local meta = minetest.get_meta(pos)
			meta:set_string("formspec",chest_formspec)
			meta:set_string("infotext", "Shared Chest")
			local inv = meta:get_inventory()
			inv:set_size("main", 8*4)
		end,
		
		allow_metadata_inventory_move = function(
				pos, from_list, from_index,
				to_list, to_index, count, player
			)

			local name = player:get_player_name()
			if landrush.can_interact(pos,name) then
				return count
			else
				log_chest_access_attempt(pos,name,"move stuff in")
				return 0
			end
		end,

		allow_metadata_inventory_put = function(
				pos, listname, index, stack, player
			)

			local name = player:get_player_name()
			if landrush.can_interact(pos,name) then
				return stack:get_count()
			else
				log_chest_access_attempt(pos,name,"put stuff in")
				return 0
			end
		end,
		
	  allow_metadata_inventory_take = function(
				pos, listname, index, stack, player
			)

			local name = player:get_player_name()
			if landrush.can_interact(pos,name) then
				return stack:get_count()
			else
				log_chest_access_attempt(pos,name,"take stuff from")
				return 0
			end
		end,
		
		on_metadata_inventory_move = function(
				pos, from_list, from_index,
				to_list, to_index, count, player
			)

			local name = player:get_player_name()
			log_chest_access(pos,name,"moves stuff in")
		end,
		
	  on_metadata_inventory_put = function(
				pos, listname, index, stack, player
			)

			local name = player:get_player_name()
			log_chest_access(pos,name,"puts stuff in")
		end,
		
	  on_metadata_inventory_take = function(
				pos, listname, index, stack, player
			)

			local name = player:get_player_name()
			log_chest_access(pos,name,"takes stuff from")
		end,

		tube = {
			insert_object = function(pos, node, stack, direction)
				local meta = minetest.env:get_meta(pos)
				local inventory = meta:get_inventory()
				return inventory:add_item("main",stack)
			end,

			can_insert = function(pos, node, stack, direction)
				local meta=minetest.env:get_meta(pos)
				local inventory = meta:get_inventory()
				return inventory:room_for_item("main",stack)
			end,

			input_inventory="main",
			connect_sides = {left=1, right=1, back=1, top=1, bottom=1},
		}
})

minetest.register_craft({
		output = 'landrush:shared_chest',
		recipe = {
			{'group:wood','group:wood','group:wood'},
			{'group:wood','landrush:landclaim','group:wood'},
			{'group:wood','group:wood','group:wood'}
		}
})

minetest.register_craft({
		output = 'landrush:shared_chest',
		recipe = {
			{'landrush:landclaim'},
			{'default:chest'}
		}
})

minetest.register_craft({
		output = 'landrush:shared_chest',
		recipe = {
			{'landrush:landclaim'},
			{'default:chest_locked'}
		}
})
