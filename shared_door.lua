doors.register("landrush_shared_door", {
	description = "Shared Door",
	inventory_image = "shared_door_inv.png",
	groups = {snappy=1,bendy=2,cracky=1,melty=2,level=2,door=1},
	tiles = {{ name = "shared_door.png", backface_culling = true }},
	on_rightclick = function(pos, node, clicker)
		if ( landrush.can_interact(pos,clicker:get_player_name()) ) then
			local door = doors.get(pos)
			door:toggle()
		end
	end
})

minetest.register_craft({
	output = 'doors:landrush_shared_door',
	recipe = {
		{'default:steel_ingot','default:steel_ingot',''},
		{'default:steel_ingot','landrush:landclaim',''},
		{'default:steel_ingot','default:steel_ingot',''}
	}
})

