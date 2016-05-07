local liquid_itemnames = {}
for key, value in pairs(bucket.liquids) do
	if key == value.source then
		table.insert(liquid_itemnames, value.itemname)
	end
end

for _, liquid_itemname in ipairs(liquid_itemnames) do
	local idef = minetest.registered_items[liquid_itemname]
	if idef then
		-- Override on_place for liquids
		local default_on_place = idef.on_place
		idef.on_place = function(itemstack, user, pointed_thing)
			-- find the position we are trying to place the liquid
			local node = minetest.get_node_or_nil(pointed_thing.under)
			local ndef
			if node then
				ndef = minetest.registered_nodes[node.name]
			end
			local pos = nil
			if ndef and ndef.buildable_to then
				pos = pointed_thing.under
			else
				pos = pointed_thing.above
			end

			local name = ''
			if user then
				name = user:get_player_name()
			end

			-- don't allow placement above 140
			-- don't allow placement to unclaimed areas above -200
			if pos then
				if pos.y < -200 then
					return default_on_place(itemstack, user, pointed_thing)
				elseif pos.y > 140 then
					minetest.chat_send_player(name, 'You can not place liquids above 140.')
				else
					if landrush.claims[landrush.get_chunk(pos)] == nil then
						minetest.chat_send_player(name, 'You can not place liquids in unclaimed areas.')
					else
						return default_on_place(itemstack, user, pointed_thing)
					end
				end
			end
		end
	end
end
