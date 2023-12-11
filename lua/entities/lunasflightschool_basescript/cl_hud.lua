function ENT:LFSHudPaintInfoText( X, Y, speed, alt, AmmoPrimary, AmmoSecondary, Throttle )
	local Col = Throttle <= 100 and Color(255,255,255,255) or Color(255,0,0,255)

	draw.SimpleText( "THR", "LFS_FONT", 10, 10, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	draw.SimpleText( Throttle.."%" , "LFS_FONT", 120, 10, Col, TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

	draw.SimpleText( "IAS", "LFS_FONT", 10, 35, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	draw.SimpleText( speed.."km/h", "LFS_FONT", 120, 35, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

	draw.SimpleText( "ALT", "LFS_FONT", 10, 60, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	draw.SimpleText( alt.."m" , "LFS_FONT", 120, 60, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )

	if self:GetMaxAmmoPrimary() > -1 then
		draw.SimpleText( "PRI", "LFS_FONT", 10, 85, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		draw.SimpleText( AmmoPrimary, "LFS_FONT", 120, 85, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	end

	if self:GetMaxAmmoSecondary() > -1 then
		draw.SimpleText( "SEC", "LFS_FONT", 10, 110, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
		draw.SimpleText( AmmoSecondary, "LFS_FONT", 120, 110, Color(255,255,255,255), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	end
end

local AltitudeMinZ = 0
LVS:AddHudEditor( "lfshud",  ScrW(), ScrH(),  220, 75, 220, 75, "LFS Info Text",
	function( self, vehicle, X, Y, W, H, ScrX, ScrY, ply )
		if not vehicle.LFSHudPaintInfoText then return end

		local vel = vehicle:GetVelocity():Length()

		local Throttle = vehicle:GetThrottlePercent()

		local speed = math.Round(vel * 0.09144,0)

		local ZPos = math.Round( vehicle:GetPos().z,0)
		if (ZPos + AltitudeMinZ )< 0 then AltitudeMinZ = math.abs(ZPos) end
		local alt = math.Round( (vehicle:GetPos().z + AltitudeMinZ) * 0.0254,0)

		local AmmoPrimary = vehicle:GetAmmoPrimary()
		local AmmoSecondary = vehicle:GetAmmoSecondary()

		vehicle:LFSHudPaintInfoText( X, Y, speed, alt, AmmoPrimary, AmmoSecondary, Throttle )
	end
)

ENT.IconEngine = Material( "lvs/engine.png" )

function ENT:LVSHudPaintInfoText( X, Y, W, H, ScrX, ScrY, ply )
	local kmh = math.Round(self:GetVelocity():Length() * 0.09144,0)
	draw.DrawText( "km/h ", "LVS_FONT", X + 72, Y + 35, color_white, TEXT_ALIGN_RIGHT )
	draw.DrawText( kmh, "LVS_FONT_HUD_LARGE", X + 72, Y + 20, color_white, TEXT_ALIGN_LEFT )

	if ply ~= self:GetDriver() then return end

	local Throttle = self:GetThrottlePercent() / 100

	local Col = Throttle <= 1 and color_white or Color(0,0,0,255)
	local hX = X + W - H * 0.5
	local hY = Y + H * 0.25 + H * 0.25

	surface.SetMaterial( self.IconEngine )
	surface.SetDrawColor( 0, 0, 0, 200 )
	surface.DrawTexturedRectRotated( hX + 4, hY + 1, H * 0.5, H * 0.5, 0 )
	surface.SetDrawColor( color_white )
	surface.DrawTexturedRectRotated( hX + 2, hY - 1, H * 0.5, H * 0.5, 0 )

	if not self:GetEngineActive() then
		draw.SimpleText( "X" , "LVS_FONT",  hX, hY, Color(0,0,0,255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end

	self:LVSDrawCircle( hX, hY, H * 0.35, math.min( Throttle, 1 ) )

	if Throttle > 1 then
		draw.SimpleText( "+"..math.Round((Throttle - 1) * 100,0).."%" , "LVS_FONT",  hX, hY, Col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER )
	end
end

function ENT:LVSPreHudPaint( X, Y, ply )
	return true
end

function ENT:LVSHudPaint( X, Y, ply )
	if not self:LVSPreHudPaint( X, Y, ply ) then return end

	if ply ~= self:GetDriver() then
		self:LFSHudPaintPassenger( X, Y, ply )

		return
	end

	local HitPlane = self:GetEyeTrace( true ).HitPos:ToScreen()
	local HitPilot = self:GetEyeTrace().HitPos:ToScreen()

	local Sub = Vector(HitPilot.x,HitPilot.y,0) - Vector(HitPlane.x,HitPlane.y,0)
	local Len = Sub:Length()
	local Dir = Sub:GetNormalized()

	self:LFSHudPaintCrosshair( HitPlane, HitPilot )
	self:LFSHudPaintInfoLine( HitPlane, HitPilot, LFS_TIME_NOTIFY, Dir, Len, LocalPlayer():lvsKeyDown( "FREELOOK" ) )
	self:LFSPaintHitMarker( HitPilot )

	self:LVSHudPaintHelicopter( X, Y, ply, HitPilot )
end

function ENT:LVSHudPaintHelicopter( X, Y, ply, HitPilot )
end

function ENT:LFSHudPaintPassenger( X, Y, ply )
	self:LFSPaintHitMarker( {x = X * 0.5, y = Y * 0.5} )
end

function ENT:LFSHudPaintInfoLine( HitPlane, HitPilot, LFS_TIME_NOTIFY, Dir, Len, FREELOOK )
	if Len <= 20 then return end

	surface.SetDrawColor( 255, 255, 255, 100 )

	local FailStart = LFS_TIME_NOTIFY > CurTime()
	if FailStart then
		surface.SetDrawColor( 255, 0, 0, math.abs( math.cos( CurTime() * 10 ) ) * 255 )
	end

	if not FREELOOK or FailStart then
		surface.DrawLine( HitPlane.x + Dir.x * 5, HitPlane.y + Dir.y * 5, HitPilot.x - Dir.x * 20, HitPilot.y- Dir.y * 20 )

		-- shadow
		surface.SetDrawColor( 0, 0, 0, 50 )
		surface.DrawLine( HitPlane.x + Dir.x * 5 + 1, HitPlane.y + Dir.y * 5 + 1, HitPilot.x - Dir.x * 20+ 1, HitPilot.y- Dir.y * 20 + 1 )
	end
end

function ENT:LFSHudPaintCrosshair( HitPlane, HitPilot )
	self:PaintCrosshairCenter( HitPlane )
	self:PaintCrosshairOuter( HitPilot )
end

function ENT:LFSPaintHitMarker( scr )
	self:LVSPaintHitMarker( scr )
end
