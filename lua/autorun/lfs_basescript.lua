
simfphys = istable( simfphys ) and simfphys or {}
simfphys.LFS = {}

simfphys.LFS.VERSION = 310
simfphys.LFS.VERSION_TYPE = ".GIT"

hook.Add( "LVS:Initialize", "[LFS] - Initialize", function()
	simfphys.LFS.FreezeTeams = GetConVar( "lvs_freeze_teams" )
	simfphys.LFS.TeamPassenger = GetConVar( "lvs_teampassenger" )
	simfphys.LFS.PlayerDefaultTeam = GetConVar( "lvs_default_teams" )

	simfphys.LFS.IgnoreNPCs = LVS.IgnoreNPCs
	simfphys.LFS.IgnorePlayers = LVS.IgnorePlayers
end )

local meta = FindMetaTable( "Player" )

local KEYS = {
	["FREELOOK"] = IN_WALK,
	["ENGINE"] = IN_RELOAD,
	["VSPEC"] = IN_JUMP,
	["+THROTTLE"] = IN_FORWARD,
	["-THROTTLE"] = IN_BACK,
	["+PITCH"] = IN_SPEED,
	["-ROLL"] = IN_MOVELEFT,
	["+ROLL"] = IN_MOVERIGHT,
	["+THROTTLE_HELI"] = IN_FORWARD,
	["-THROTTLE_HELI"]= IN_BACK,
	["-ROLL_HELI"]= IN_MOVELEFT,
	["+ROLL_HELI"] = IN_MOVERIGHT,
	["HOVERMODE"] = IN_SPEED,
}

function meta:lfsGetPlane()
	return self:lvsGetVehicle()
end

function meta:lfsGetAITeam()
	return self:lvsGetAITeam()
end

function meta:lfsGetInput( name )
	if not KEYS[ name ] then return false end

	return self:KeyDown( KEYS[ name ] )
end

hook.Add( "PreRegisterSENT", "!!!lfs_to_lvs", function( ent, class )
	if not ent.Spawnable or not ent.Category then return end

	if not string.StartsWith( class, "lunasflightschool_" ) then return end

	local Variants = {
		[1] = "[LFS] - ",
		[2] = "[LFS] -",
		[3] = "[LFS]- ",
		[4] = "[LFS]-",
		[5] = "[LFS] ",
	}

	local NewSubCategory = ""

	for _, start in pairs( Variants ) do
		if ent.Category:StartWith( start ) then
			local NewName = string.Replace(ent.Category, start, "")

			if NewName ~= "" and NewName ~= "[LFS]" then
				NewSubCategory = NewName
			end

			break
		end
	end

	ent.VehicleCategory = "Flight School"

	if NewSubCategory ~= "" then
		ent.VehicleSubCategory = NewSubCategory
	end
end )

if SERVER then
	util.AddNetworkString( "lfs_failstartnotify" )
	util.AddNetworkString( "lfs_hitmarker" )
	util.AddNetworkString( "lfs_killmarker" )

	return
end

list.Set( "ContentCategoryIcons", "[LVS] - Flight School", "icon16/lfs.png" )
list.Set( "ContentCategoryIcons", "[LFS]", "icon16/lfs.png" )

net.Receive( "lfs_hitmarker", function( len )
	if not LVS.ShowHitMarker then return end

	local ply = LocalPlayer()

	local vehicle = ply:lvsGetVehicle()

	if not IsValid( vehicle ) then return end

	vehicle:HitMarker()
end )

net.Receive( "lfs_killmarker", function( len )
	if not LVS.ShowHitMarker then return end

	local ply = LocalPlayer()

	local vehicle = ply:lvsGetVehicle()

	if not IsValid( vehicle ) then return end

	vehicle:KillMarker()
end )

LFS_TIME_NOTIFY = 0
net.Receive( "lfs_failstartnotify", function( len )
	surface.PlaySound( "common/wpn_hudon.ogg" )

	LFS_TIME_NOTIFY = CurTime() + 2
end )

local THE_FONT = {
	font = "Verdana",
	extended = false,
	size = 14,
	weight = 600,
	blursize = 0,
	scanlines = 0,
	antialias = true,
	underline = false,
	italic = false,
	strikeout = false,
	symbol = false,
	rotary = false,
	shadow = true,
	additive = false,
	outline = false,
}

THE_FONT.extended = false
THE_FONT.size = 20
THE_FONT.weight = 2000
surface.CreateFont( "LFS_FONT", THE_FONT )

THE_FONT.size = 16
surface.CreateFont( "LFS_FONT_SWITCHER", THE_FONT )

THE_FONT.font = "Arial"
THE_FONT.size = 14
THE_FONT.weight = 1
THE_FONT.shadow = false
surface.CreateFont( "LFS_FONT_PANEL", THE_FONT )

local function PrecacheArc(cx,cy,radius,thickness,startang,endang,roughness,bClockwise)
	local triarc = {}
	local deg2rad = math.pi / 180

	local startang,endang = startang or 0, endang or 0
	if bClockwise and (startang < endang) then
		local temp = startang
		startang = endang
		endang = temp
		temp = nil
	elseif (startang > endang) then 
		local temp = startang
		startang = endang
		endang = temp
		temp = nil
	end

	local roughness = math.max(roughness or 1, 1)
	local step = roughness
	if bClockwise then
		step = math.abs(roughness) * -1
	end

	local inner = {}
	local r = radius - thickness
	for deg=startang, endang, step do
		local rad = deg2rad * deg
		table.insert(inner, {
			x=cx+(math.cos(rad)*r),
			y=cy+(math.sin(rad)*r)
		})
	end

	local outer = {}
	for deg=startang, endang, step do
		local rad = deg2rad * deg
		table.insert(outer, {
			x=cx+(math.cos(rad)*radius),
			y=cy+(math.sin(rad)*radius)
		})
	end

	for tri=1,#inner*2 do
		local p1,p2,p3
		p1 = outer[math.floor(tri/2)+1]
		p3 = inner[math.floor((tri+1)/2)+1]
		if tri%2 == 0 then
			p2 = outer[math.floor((tri+1)/2)]
		else
			p2 = inner[math.floor((tri+1)/2)]
		end
	
		table.insert(triarc, {p1,p2,p3})
	end
	return triarc
end

function simfphys.LFS.DrawArc(cx,cy,radius,thickness,startang,endang,roughness,color,bClockwise)
	surface.SetDrawColor(color)
	draw.NoTexture()

	for k,v in ipairs( PrecacheArc(cx,cy,radius,thickness,startang,endang,roughness,bClockwise) ) do
		surface.DrawPoly(v)
	end
end

function simfphys.LFS.DrawCircle( X, Y, radius )
	local segmentdist = 360 / ( 2 * math.pi * radius / 2 )
	
	for a = 0, 360, segmentdist do
		surface.DrawLine( X + math.cos( math.rad( a ) ) * radius, Y - math.sin( math.rad( a ) ) * radius, X + math.cos( math.rad( a + segmentdist ) ) * radius, Y - math.sin( math.rad( a + segmentdist ) ) * radius )
	end
end

function simfphys.LFS.DrawDiamond( X, Y, radius, perc )
	if perc <= 0 then return end

	local segmentdist = 90

	draw.NoTexture()

	for a = 90, 360, segmentdist do
		local Xa = math.Round( math.sin( math.rad( -a ) ) * radius, 0 )
		local Ya = math.Round( math.cos( math.rad( -a ) ) * radius, 0 )

		local C = math.sqrt( radius ^ 2 + radius ^ 2 )

		if a == 90 then
			C = C * math.min(math.max(perc - 0.75,0) / 0.25,1)
		elseif a == 180 then
			C = C * math.min(math.max(perc - 0.5,0) / 0.25,1)
		elseif a == 270 then
			C = C * math.min(math.max(perc - 0.25,0) / 0.25,1)
		elseif a == 360 then
			C = C * math.min(math.max(perc,0) / 0.25,1)
		end

		if C > 0 then
			local AxisMoveX = math.Round( math.sin( math.rad( -a + 135) ) * (C + 3) * 0.5, 0 )
			local AxisMoveY =math.Round( math.cos( math.rad( -a + 135) ) * (C + 3) * 0.5, 0 )

			surface.DrawTexturedRectRotated(X - Xa - AxisMoveX, Y - Ya - AxisMoveY,3, math.ceil( C ), a - 45)
		end
	end
end

