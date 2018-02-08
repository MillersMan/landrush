local function vertical_level(y)
	-- 3 levels of vertical protection
	if ( y < -200 ) then
		y = -32000
	elseif ( y < -60 ) then
		y = -200
	elseif ( y < 140 ) then
		y = -30
	else
		y = 90
	end
	return y
end

function landrush.get_chunk(pos)
	local N = landrush.config:get("chunkSize")

	local x = math.floor(pos.x/N)
	local y = vertical_level(pos.y)
	local z = math.floor(pos.z/N)

	return x..","..y..","..z
end

function landrush.get_chunk_center(pos)
	local N = landrush.config:get("chunkSize")

	local x = math.floor(pos.x/N)*N + 7.5
	local z = math.floor(pos.z/N)*N + 7.5

	return {x=x,y=nil,z=z}
end

function landrush.get_owner(pos)
	if ( pos.x < tonumber(landrush.config:get("min_x")) ) or
	   ( pos.x > tonumber(landrush.config:get("max_x")) ) or
	   ( pos.z < tonumber(landrush.config:get("min_z")) ) or
	   ( pos.z > tonumber(landrush.config:get("max_z")) ) then
		return landrush.config:get("border_owner")
	end

	local chunk = landrush.get_chunk(pos)
	if landrush.claims[chunk] then
		return landrush.claims[chunk].owner
	end
end
 
function landrush.get_distance(pos1,pos2)
	if ( pos1 ~= nil and pos2 ~= nil ) then
		return math.floor(math.sqrt( (pos1.x - pos2.x)^2 + (pos1.z - pos2.z)^2 ))
	end
	return 0
end

function landrush.get_timeonline(name)
	-- a wrapper for whoison.getTimeOnline
	-- since whoison is an optional dependency
	if ( landrush.whoison == true ) then
		return (whoison.getTimeOnline(name) / 60)
	end
	return -1
end
