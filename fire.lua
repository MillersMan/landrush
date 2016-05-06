local def = minetest.registered_nodes["fire:basic_flame"]
if def then
	-- Do not allow flames in or around protected areas
	local default_on_construct = def.on_construct
	def.on_construct = function(pos)
		if landrush.can_interact_in_radius(pos, "", 1) then
			return default_on_construct(pos)
		end
		minetest.remove_node(pos)
	end

	-- Extinguish flames in and around protected areas
	-- this is needed because voxelmanip can set a node without
	-- triggering the on_construct callback
	minetest.register_abm({
		nodenames = {"fire:basic_flame"},
		interval = 3,
		chance = 1,
		catchup = true,
		action = function(pos)
			if not landrush.can_interact_in_radius(pos, "", 1) then
				minetest.remove_node(pos)
				minetest.sound_play("fire_extinguish_flame",
					{pos = pos, max_hear_distance = 16, gain = 0.25})
			end
		end
	})
end
