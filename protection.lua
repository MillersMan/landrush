landrush.offense = {}

function landrush.grief_alert(pos, name)

	local chunk = landrush.get_chunk(pos)

	minetest.chat_send_player(
		landrush.claims[chunk].owner,
		"You are being griefed by " ..
		name ..
		" at " ..
		minetest.pos_to_string(pos)
	)

	for _,shared_player_name in pairs(landrush.claims[chunk].shared) do
		minetest.chat_send_player(
			shared_player_name,
			name ..
			" is griefing your shared claim at " ..
			minetest.pos_to_string(pos)
		)
	end

	minetest.chat_send_player(
		name,
		"You are griefing " ..
		landrush.claims[chunk].owner
	)
end

function landrush.can_interact_in_radius(pos, name, r)
	local corners = { {x=pos.x+r, y=pos.y+r, z=pos.z+r},
	                  {x=pos.x+r, y=pos.y+r, z=pos.z-r},
	                  {x=pos.x+r, y=pos.y-r, z=pos.z+r},
	                  {x=pos.x+r, y=pos.y-r, z=pos.z-r},
	                  {x=pos.x-r, y=pos.y+r, z=pos.z+r},
	                  {x=pos.x-r, y=pos.y+r, z=pos.z-r},
	                  {x=pos.x-r, y=pos.y-r, z=pos.z+r},
	                  {x=pos.x-r, y=pos.y-r, z=pos.z-r} }
	for _, corner in ipairs(corners) do
		if not landrush.can_interact(corner,"") then
			return false
		end
	end
	return true
end

function landrush.can_interact(pos, name)

	--if ( pos.y < -200 or name == '' or name == nil ) then
	if ( pos.y < -200 ) or
	   ( minetest.check_player_privs(name, {landrush=true}) ) or
	   ( minetest.check_player_privs(name, {protection_bypass=true}) ) then
		return true
	end

	local chunk = landrush.get_chunk(pos)

	if ( landrush.claims[chunk] == nil ) then
		if ( landrush.config:get_bool("requireClaim") == false ) then
			return true
		end
		return false
	else -- landrush.claims[chunk] ~= nil
		if landrush.claims[chunk].owner == name or
		   landrush.claims[chunk].shared[name] or
		   landrush.claims[chunk].shared['*all'] then
			return true
		else
			if landrush.config:get_bool("onlineProtection") == false then
				landrush.grief_alert(chunk, name)
				return true
			end
			return false
		end
	end
end

function landrush.restore_privs(name, privs, grant_privs)

	for _,priv in ipairs(grant_privs) do
    privs[priv] = true
  end

	core.set_player_privs(name, privs)

	core.chat_send_player(name,
		"Your privileges have been restored."
	)

	core.chat_send_all(
		name ..	"'s privileges have been restored."
	)

	core.log("action",
		name ..	"'s privileges have been restored."
	)

end

function landrush.suspend_privs(name, revoke_privs, minutes)

	local privs = core.get_player_privs(name)
	if not privs then return end

	for _,priv in ipairs(revoke_privs) do
    privs[priv] = nil
  end

	core.set_player_privs(name, privs)

	core.after( minutes*60, landrush.restore_privs, name, privs, revoke_privs )

	minetest.chat_send_player(name,
		"Your privileges have been reduced for " ..
		tostring(minutes) .. " minutes for trying to grief."
	)

	minetest.chat_send_all(
		name ..	"'s privileges have been reduced for trying to grief."
	)

	minetest.log("action",
		name ..	"'s privileges have been reduced for trying to grief."
	)

end

function landrush.moderate(pos,name)

	if ( landrush.offense[name] == nil ) then
		landrush.offense[name] = {count=0,lastpos=nil,lasttime=os.time(),bancount=0}
	end

	local timediff = (os.time() - landrush.offense[name].lasttime)/60
	local distance = landrush.get_distance(landrush.offense[name].lastpos,pos)

	-- reset offenses after a given time period
	if timediff > tonumber(landrush.config:get("offenseReset")) then
		landrush.offense[name].count=0
	end
	if timediff > tonumber(landrush.config:get("offenseReset"))*7 then
		landrush.offense[name].bancount=0
	end

	local offenseAmount = 0
	if timediff < 0.01 then
		-- reduce the offense amount for very rapid attempts that
		-- may be unnoticed by the player due to lag
		offenseAmount = 1
	else
		-- offense amount starts at 10 and is decreased based on
		-- the length of time between offenses and the distance
		-- from the last offense. This weighted system tries to
		-- tolerate players who aren't intentionally griefing
		local N = landrush.config:get("chunkSize")
		offenseAmount = math.max(0, 10 - timediff/6 - distance/N)
	end

	landrush.offense[name].count = landrush.offense[name].count + offenseAmount
	landrush.offense[name].lastpos = pos
	landrush.offense[name].lasttime = os.time()

	minetest.log("action",
		string.format(
			name ..
			" attempted to grief. Offense count raised to %.3f.",
			landrush.offense[name].count
		)
	)

	if ( landrush.offense[name].count > tonumber(landrush.config:get("banLevel")) ) then

		landrush.offense[name].bancount = landrush.offense[name].bancount + 1
		landrush.offense[name].count = 0
		landrush.offense[name].lastpos = nil

		local term = 3^landrush.offense[name].bancount -- minutes

		if ( landrush.offense[name].bancount < 4 ) then

			local privs = {"interact", "shout"}
			landrush.suspend_privs(name, privs, term)

		else
			minetest.ban_player(name)

			minetest.log("action",
				name ..	" has been banned for too many grief attempts."
			)

			minetest.chat_send_all(
				name ..	" has been banned for too many grief attempts."
			)
		end

		if minetest.get_modpath("chatplus") then
			if ( chatplus and landrush.config:get("adminUser") ~= nil) then
				table.insert(
					chatplus.names[landrush.config:get("adminUser")].messages,
					"mail from <LandRush>: " ..
					name .. " banned for " ..
					tostring(term) ..
					" minutes for attempted griefing"
				)
			end
		end

		return
	end

	if ( landrush.offense[name].count > tonumber(landrush.config:get("banWarning")) ) then

		minetest.chat_send_player(name,
			"Stop trying to dig in claimed areas or you will be banned!"
		)

		minetest.chat_send_player(name,
			"Use /showarea and /landowner to see the protected area and who owns it."
		)

		minetest.sound_play("landrush_ban_warning", {to_player=name,gain = 10.0})

	end

end

function landrush.protection_violation(pos, name)
	-- this function can be overwritten to apply whatever discipline the server admin wants
	-- this is the default discipline

	local player = minetest.get_player_by_name(name)
	if ( player == nil ) then
	  return
	end

	-- inform
	local owner = landrush.get_owner(pos)
	if ( owner == nil ) and
	   ( landrush.config:get_bool("requireClaim") == true ) then
		minetest.chat_send_player(name,
			"This area is unowned, but you must claim it to build or mine"
		)
		return true
	else
		minetest.chat_send_player(name,
			"Area owned by " ..
			tostring(owner) ..
			" stop trying to dig here!"
		)
	end

	-- discipline
	if ( tonumber(landrush.config:get("noDamageTime")) >
	              landrush.get_timeonline(name) ) then
		player:set_hp( player:get_hp() - landrush.config:get("offenseDamage") )
	end

	if ( landrush.config:get_bool("autoBan") == true ) and
	   ( tonumber(landrush.config:get("noBanTime")) >
	              landrush.get_timeonline(name) ) then
		landrush.moderate(pos,name)
	end

end

landrush.default_is_protected = minetest.is_protected

function minetest.is_protected (pos, name)
	if ( landrush.can_interact(pos, name) ) then
		return landrush.default_is_protected(pos,name)
	end
	return true
end

minetest.register_on_protection_violation( landrush.protection_violation )
