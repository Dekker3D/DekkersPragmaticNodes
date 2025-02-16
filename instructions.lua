-- Local references for shorter names and avoiding global lookup on every use
local Get, GetNum, GetCoord, GetId, GetEntity, Set, BeginBlock = InstGet, InstGetNum, InstGetCoord, InstGetId, InstGetEntity, InstSet, InstBeginBlock

local function GetSeenEntityOrSelf(comp, state, ent)
	if not ent then return comp.owner end
	local reg = Get(comp, state, ent)
	if reg.is_empty then return nil end
	local entity = reg.entity
	return entity and comp.faction:IsSeen(entity) and entity or nil
end

local function GetFactionEntityOrSelf(comp, state, ent)
	if not ent then return comp.owner end
	local reg = Get(comp, state, ent)
	if reg.is_empty then return nil end
	local entity = reg.entity
	return entity and comp.faction == entity.faction and entity or nil
end

-- New code starts here

-- Current unused, possibly not relevant since boolean inputs can be a dropdown menu in an instruction. Those can't fit in a register, though.
local function ReadBooleanFromRegister(reg)
	local val = GetId(reg)
	if val ~= nil then
		if val == data.values.v_color_green or val == data.values.v_color_light_green then return false end
		if val == data.values.v_color_red or val == data.values.v_color_crimson or val == data.values.v_color_pink then return false end
	end

	local num = GetNum(reg)
	if num ~= nil then
		if num > 0 then return true end
		if num < 0 then return false end
	end

	return nil -- Dunno, man. Best to do explicit == true/false/nil comparisons instead of relying on the implicit "if (ReadBooleanFromRegister(blah))"
end

-- Now returns move goal.
data.instructions.dpn_is_moving =
{
	func = function(comp, state, cause, not_moving, path_blocked, no_result, in_unit, out_coord)
		local entity = GetSeenEntityOrSelf(comp, state, in_unit)
		if not entity then -- This shouldn't happen unless a behaviour is called from a non-entity but hey sure, defensive coding!
			state.counter = no_result
			Set(comp, state, out_coord, { coord = nil })
			return
		end
		if entity.state_path_blocked then
			state.counter = path_blocked
			Set(comp, state, out_coord, { coord = entity.move_goal })
			return
		end
		if not entity.is_moving then
			state.counter = not_moving
			Set(comp, state, out_coord, { coord = entity.location }) -- Should be same as move_goal, right? Might be best to just do move_goal instead?
			return
		end
		Set(comp, state, out_coord, { coord = entity.move_goal })
	end,
	exec_arg = { 1, "Moving", "Where to continue if entity is moving" },
	args = {
		{ "exec", "Not Moving", "Where to continue if entity is not moving" },
		{ "exec", "Path Blocked", "Where to continue if entity is path blocked" },
		{ "exec", "No Result", "Where to continue if entity is out of visual range" },
		{ "in", "Unit", "The unit to check (if not self)", "entity", true },
		{ "out", "Coord", "The coordinates that the unit is moving towards", "coord", true },
	},
	name = "Is Moving (DPN)",
	desc = "Checks the movement state of an entity",
	category = "Unit (DPN)",
	icon = "Main/skin/Icons/Special/Commands/Move To.png"
}

local function GetCoordFromArg(comp, state, arg)
	local val = Get(comp, state, arg)
	if val.entity ~= nil then
		return val.entity.location, val.entity
	elseif val.coord ~= nil then
		return val.coord, nil
	end
end

-- Now takes coords and not just entities.
data.instructions.dpn_is_same_grid =
{
	func = function(comp, state, cause, in_unit1, in_unit2, exec_diff)
		local coord1, ent1 = GetCoordFromArg(comp, state, in_unit1)
		local coord2, ent2 = GetCoordFromArg(comp, state, in_unit2)

		if coord1 ~= nil and coord2 ~= nil then
			if (ent1 == nil or ent1.faction == comp.faction) and (ent2 == nil or ent2.faction == comp.faction) then
				if comp.faction:GetPowerGridIndexAt(coord1) == comp.faction:GetPowerGridIndexAt(coord2) then
					return -- All good!
				end
			end
		end
		state.counter = exec_diff -- Not same grid.
	end,
	exec_arg = { 1, "Same Grid", "Where to continue if both entities/coords are in the same logistics network" },
	args = {
		{ "in", "First", "First entity/coord", "any" },
		{ "in", "Second", "Second entity/coord", "any" },
		{ "exec", "Different", "Different logistics networks" },
	},
	name = "Is Same Grid (DPN)",
	desc = "Checks if two entities/coords are in the same logistics network",
	category = "Unit (DPN)",
	icon = "Main/skin/Icons/Common/56x56/Power.png",
}

-- data.instructions.ds_get_nearest_unexplored_tile =
-- {
-- 	func = function(comp, state, cause, if_not_found, from, skip_blight, out_coord)
-- 		local from_pos = comp.owner.location
-- 		--if from ~= nil then
-- 		--	local reg = Get(comp, state, from)
-- 		--	if reg.coord then
-- 		--		from_pos = reg.coord
-- 		--	end
-- 		--end

-- 		--local skip_blight_bool = true
-- 		--if skip_blight ~= nil then
-- 		--	local reg = Get(comp, state, skip_blight)
-- 		--	if ReadBooleanFromRegister(reg) == false then
-- 		--		skip_blight_bool = false
-- 		--	end
-- 		--end

-- 		local coords = comp.faction:FindClosestHiddenTile(from_pos.x, from_pos.y, 1000)
-- 		if coords == nil or coords.x == nil then
-- 			Set(comp, state, out_coord, { coord = { 0, 0 } })
-- 			state.counter = if_not_found
-- 			return
-- 		end

-- 		local r = Tool.NewRegisterObject()
-- 		Set(comp, state, out_coord, { coord = coords })
-- 	end,
-- 	exec_arg = { 1, "If Found", "Where to continue if an unexplored tile is found" },
-- 	args = {
-- 		{ "exec", "If Not Found", "Where to continue if no unexplored tile is found in a 1000 tile range" },
-- 		{ "in", "From", "Position from which to check", "coords", true },
-- 		{ "in", "Skip Blight", "Skip any tiles in the blight", "number", true },
-- 		{ "out", "Coords", "Coordinates of tile", "coord" },
-- 	},
-- 	name = "Get Closest Unexplored Tile (DPN)",
-- 	desc = "Returns the nearest unexplored tile",
-- 	category = "Global (DPN)",
-- 	icon = "Main/skin/Icons/Special/Commands/Count Free Space.png",
-- }