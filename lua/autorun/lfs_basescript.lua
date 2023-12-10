
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

	return
end

list.Set( "ContentCategoryIcons", "[LVS] - Flight School", "icon16/lfs.png" )
list.Set( "ContentCategoryIcons", "[LFS]", "icon16/lfs.png" )

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
