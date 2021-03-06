local stats_enabled = false
if minetest.get_modpath("stats") then
	stats_enabled = true
end

minetest.register_chatcommand("landowner", {
	params = "",
	description = "tells the owner of the current map chunk",
	privs = {interact=true},
	func = function(name, param)
		local player = minetest.env:get_player_by_name(name)
		local pos = player:getpos()
		local owner = landrush.get_owner(pos)
		if owner then
			minetest.chat_send_player(name, "This area is owned by "..owner)
		else
			minetest.chat_send_player(name, "This area is unowned.")
		end
	end,
})

minetest.register_chatcommand("userunclaim", {
	params = "player",
	privs = {landrush=true},
	description = "Unclaims all of a players areas",
	func = function(name, param)
		qdone = 0
		for k,v in pairs(landrush.claims) do
            if landrush.claims[k].owner == param then
                landrush.claims[k] = nil
                qdone = qdone + 1
            end
        end
        landrush.save_claims()
        minetest.chat_send_player(name,tostring(qdone).." claims unclaims for "..param)
	end
})

minetest.register_chatcommand("unclaim", {
	params = "",
	description = "unclaims the current map chunk",
	privs = {interact=true},
	func = function(name, param)
		local player = minetest.env:get_player_by_name(name)
		local pos = player:getpos()
		local owner = landrush.get_owner(pos)
		local inv = player:get_inventory()
		if owner then
			if owner == name or minetest.check_player_privs(name, {landrush=true}) then
				local chunk = landrush.get_chunk(pos)
				if inv:room_for_item("main", landrush.claims[chunk].claimtype) then
					player:get_inventory():add_item("main", {name=landrush.claims[chunk].claimtype})
					if stats_enabled then
						stats.decrease_stat(player, 'land_claims', 1)
						for name,_ in pairs(landrush.claims[chunk].shared) do
							stats.decrease_stat(name, 'land_shares', 1)
						end
					end
					landrush.claims[chunk] = nil
					landrush.save_claims()
					minetest.chat_send_player(name, "You renounced your claim on this area.")
					minetest.log("action", "landrush chunk (" .. chunk ..	") unclaimed by " .. owner)
				else
					minetest.chat_send_player(name, "Your inventory is full.")
				end
			else
				minetest.chat_send_player(name, "This area is owned by "..owner)
			end
		else
			minetest.chat_send_player(name, "This area is unowned.")
		end
	end,
})

minetest.register_chatcommand("sharearea", {
	params = "<name> or *all to retain ownership but allow anyone to build",
	description = "shares the current map chunk with <name>",
	privs = {interact=true},
	func = function(name, param)
		local player = minetest.env:get_player_by_name(name)
		local pos = player:getpos()
		local owner = landrush.get_owner(pos)
		if owner then
			if ( owner == name and name ~= param ) or minetest.check_player_privs(name, {landrush=true}) then
				if minetest.env:get_player_by_name(param) or param=="*all" then
					if stats_enabled and param ~= "*all"
					   and not landrush.claims[landrush.get_chunk(pos)].shared[param] then
						stats.increase_stat(param, 'land_shares', 1)
					end
					landrush.claims[landrush.get_chunk(pos)].shared[param] = param
					landrush.save_claims()
					minetest.chat_send_player(name, param.." may now edit this area.")
					minetest.chat_send_player(param, name.." has just shared an area with you.")
				else
					minetest.chat_send_player(name, param.." is not a valid player.")
				end
			else
				minetest.chat_send_player(name, "This area is owned by "..owner)
			end
		else
			minetest.chat_send_player(name, "This area is unowned.")
		end
	end,
})

minetest.register_chatcommand("unsharearea", {
	params = "<name>",
	description = "unshares the current map chunk with <name>",
	privs = {interact=true},
	func = function(name, param)
		local player = minetest.env:get_player_by_name(name)
		local pos = player:getpos()
		local owner = landrush.get_owner(pos)
		if owner then
			if owner == name or minetest.check_player_privs(name, {landrush=true}) then
				if name ~= param then
					if stats_enabled and param ~= "*all"
					   and landrush.claims[landrush.get_chunk(pos)].shared[param] then
						stats.decrease_stat(param, 'land_shares', 1)
					end
					landrush.claims[landrush.get_chunk(pos)].shared[param] = nil
					landrush.save_claims()
					minetest.chat_send_player(name, param.." may no longer edit this area.")
					minetest.chat_send_player(param, name.." has just revoked your editing privileges in an area.")
				else
					minetest.chat_send_player(name, 'Use "/unclaim" to unclaim the area.')
				end
			else
				minetest.chat_send_player(name, "This area is owned by "..owner)
			end
		else
			minetest.chat_send_player(name, "This area is unowned.")
		end
	end,
})

minetest.register_chatcommand("mayedit", {
	params = "",
	description = "lists the people who may edit the current map chunk",
	privs = {interact=true},
	func = function(name, param)
		local player = minetest.env:get_player_by_name(name)
		local pos = player:getpos()
		local mayedit = landrush.get_owner(pos)
		if mayedit then
			local chunk = landrush.get_chunk(pos)
			for user, user in pairs(landrush.claims[chunk].shared) do
				mayedit = mayedit..", "..user
			end
			minetest.chat_send_player(name, mayedit)
		else
			minetest.chat_send_player(name, "This area is unowned.")
		end
	end,
})

minetest.register_chatcommand("showarea", {
	params = "",
	description = "highlights the boundaries of the current protected area",
	privs = {interact=true},
	func = function(name, param)
		local player = minetest.env:get_player_by_name(name)
		local pos = player:getpos()		
				local entpos = landrush.get_chunk_center(pos)
				entpos.y = (pos.y-1)
				minetest.env:add_entity(entpos, "landrush:showarea")	
	end,
})

minetest.register_chatcommand("shareall", {
    params = "<name>",
    description = "shares all your landclaims with <name>",
    privs = {interact=true},
    func = function(name, param)
        
        if minetest.env:get_player_by_name(param) then
            local qdone = 0
            for k,v in pairs(landrush.claims) do
                if landrush.claims[k].owner == name then
										if stats_enabled and param ~= "*all"
											and not landrush.claims[k].shared[param] then
											stats.increase_stat(param, 'land_shares', 1)
										end
                    landrush.claims[k].shared[param] = param
                    qdone = qdone + 1
                end
            end
        
            landrush.save_claims()
            
            if qdone > 0 then
                minetest.chat_send_player(name, param.." may now edit all of your areas.")
                minetest.chat_send_player(name, qdone.." total areas were shared.")
                minetest.chat_send_player(param, name.." has just shared all of their areas with you.")
            else
                minetest.chat_send_player(name, param.." was not given any permissions. You may not own any land.")
            end
        else
                minetest.chat_send_player(name, param.." is not a valid player. Player must be online to share.")
        end
    end,
})

minetest.register_chatcommand("unshareall", {
    params = "<name>",
    description = "unshares all your landclaims with <name>",
    privs = {interact=true},
    func = function(name, param)
        if name ~= param then
            local qdone = 0
            for k,v in pairs(landrush.claims) do
                if landrush.claims[k].owner == name then
										if stats_enabled and param ~= "*all"
											and landrush.claims[k].shared[param] then
											stats.decrease_stat(param, 'land_shares', 1)
										end
                    landrush.claims[k].shared[param] = nil
                    qdone = qdone + 1
                end
            end
        
            landrush.save_claims()
            
            if qdone > 0 then
                minetest.chat_send_player(name, param.." may no longer edit any of your areas.")
                minetest.chat_send_player(name, qdone.." total areas were unshared.")
                minetest.chat_send_player(param, name.." has just unshared all of their areas with you.")
            else
                minetest.chat_send_player(name, param.." had no permissions being revoked. You may not own any land.")
            end
        else
            minetest.chat_send_player(name, 'Use "/unclaim" to unclaim any of your areas.')
        end
    end,
})
