--DO NOT EDIT OR REUPLOAD THIS FILE

include("shared.lua")

function ENT:CheckEngineState()
	local Active = self:GetRPM() > 0
	
	if Active then
		local RPM = self:GetRPM()
		local LimitRPM = self:GetLimitRPM()
		
		local tPer = RPM / LimitRPM
		
		local CurDist = (LocalPlayer():GetViewEntity():GetPos() - self:GetPos()):Length()
		self.PitchOffset = self.PitchOffset and self.PitchOffset + (math.Clamp((CurDist - self.OldDist) / FrameTime() / 125,-40,20 *  tPer) - self.PitchOffset) * FrameTime() * 5 or 0
		self.OldDist = CurDist
		
		local Pitch = (RPM - self:GetIdleRPM()) / (LimitRPM - self:GetIdleRPM())

		self:CalcEngineSound( RPM, Pitch, -self.PitchOffset )
	end

	if self.oldEnActive ~= Active then
		self.oldEnActive = Active
		self:EngineActiveChanged( Active )
	end
end

ENT.Hud = true
ENT.HudThirdPerson = false
ENT.HudGradient = Material("gui/center_gradient")
ENT.HudColor = Color(255,255,255)

function ENT:PaintHeliFlightInfo( X, Y, ply, Pos2D )
	local Roll = self:GetAngles().r

	surface.SetDrawColor(0,0,0,40)
	surface.SetMaterial( self.HudGradient )
	surface.DrawTexturedRect( Pos2D.x - 270, Pos2D.y - 10, 140, 20 )
	surface.DrawTexturedRect( Pos2D.x + 130, Pos2D.y - 10, 140, 20 )

	local X = math.cos( math.rad( Roll ) )
	local Y = math.sin( math.rad( Roll ) )

	surface.SetDrawColor( self.HudColor.r, self.HudColor.g, self.HudColor.b, 255 )
	surface.DrawLine( Pos2D.x + X * 50, Pos2D.y + Y * 50, Pos2D.x + X * 125, Pos2D.y + Y * 125 ) 
	surface.DrawLine( Pos2D.x - X * 50, Pos2D.y - Y * 50, Pos2D.x - X * 125, Pos2D.y - Y * 125 ) 

	surface.DrawLine( Pos2D.x + 125, Pos2D.y, Pos2D.x + 130, Pos2D.y + 5 ) 
	surface.DrawLine( Pos2D.x + 125, Pos2D.y, Pos2D.x + 130, Pos2D.y - 5 ) 
	surface.DrawLine( Pos2D.x - 125, Pos2D.y, Pos2D.x - 130, Pos2D.y + 5 ) 
	surface.DrawLine( Pos2D.x - 125, Pos2D.y, Pos2D.x - 130, Pos2D.y - 5 ) 
	
	surface.SetDrawColor( 0, 0, 0, 80 )
	surface.DrawLine( Pos2D.x + X * 50 + 1, Pos2D.y + Y * 50 + 1, Pos2D.x + X * 125 + 1, Pos2D.y + Y * 125 + 1 ) 
	surface.DrawLine( Pos2D.x - X * 50 + 1, Pos2D.y - Y * 50 + 1, Pos2D.x - X * 125 + 1, Pos2D.y - Y * 125 + 1 ) 
	
	surface.DrawLine( Pos2D.x + 126, Pos2D.y + 1, Pos2D.x + 131, Pos2D.y + 6 ) 
	surface.DrawLine( Pos2D.x + 126, Pos2D.y + 1, Pos2D.x + 131, Pos2D.y - 4 ) 
	surface.DrawLine( Pos2D.x - 126, Pos2D.y + 1, Pos2D.x - 129, Pos2D.y + 6 ) 
	surface.DrawLine( Pos2D.x - 126, Pos2D.y + 1, Pos2D.x - 129, Pos2D.y - 4 )

	local X = math.cos( math.rad( Roll + 45 ) )
	local Y = math.sin( math.rad( Roll + 45 ) )
	surface.DrawLine( Pos2D.x + X * 30 - 1, Pos2D.y + Y * 30 + 1, Pos2D.x + X * 60 - 1, Pos2D.y + Y * 60 + 1 ) 
	local X = math.cos( math.rad( Roll + 135 ) )
	local Y = math.sin( math.rad( Roll + 135 ) )
	surface.DrawLine( Pos2D.x + X * 30 + 1, Pos2D.y + Y * 30 + 1, Pos2D.x + X * 60 + 1, Pos2D.y + Y * 60 + 1 ) 

	surface.SetDrawColor( self.HudColor.r, self.HudColor.g, self.HudColor.b, 255 )
	local X = math.cos( math.rad( Roll + 45 ) )
	local Y = math.sin( math.rad( Roll + 45 ) )
	surface.DrawLine( Pos2D.x + X * 30, Pos2D.y + Y * 30, Pos2D.x + X * 60, Pos2D.y + Y * 60 ) 
	local X = math.cos( math.rad( Roll + 135 ) )
	local Y = math.sin( math.rad( Roll + 135 ) )
	surface.DrawLine( Pos2D.x + X * 30, Pos2D.y + Y * 30, Pos2D.x + X * 60, Pos2D.y + Y * 60 )

	local Pitch = -self:GetAngles().p

	surface.DrawLine( Pos2D.x - 220, Pos2D.y, Pos2D.x - 180, Pos2D.y )
	surface.DrawLine( Pos2D.x + 220, Pos2D.y, Pos2D.x + 180, Pos2D.y )
	surface.SetDrawColor( 0, 0, 0, 80 )
	surface.DrawLine( Pos2D.x - 220, Pos2D.y + 1, Pos2D.x - 180, Pos2D.y + 1 )
	surface.DrawLine( Pos2D.x + 220, Pos2D.y + 1, Pos2D.x + 180, Pos2D.y + 1 )

	draw.DrawText( math.Round( Pitch, 2 ), "LVS_FONT_PANEL", Pos2D.x - 175, Pos2D.y - 7, Color( self.HudColor.r, self.HudColor.g, self.HudColor.b, 255 ), TEXT_ALIGN_LEFT )
	draw.DrawText( math.Round( Pitch, 2 ), "LVS_FONT_PANEL", Pos2D.x + 175, Pos2D.y - 7, Color( self.HudColor.r, self.HudColor.g, self.HudColor.b, 255 ), TEXT_ALIGN_RIGHT )

	for i = -180, 180 do
		local Y = -i * 10 + Pitch * 10

		local absN = math.abs( i ) 

		local IsTen = absN == math.Round( absN / 10, 0 ) * 10

		local SizeX = IsTen and 20 or 10

		local Alpha = 255 - (math.min( math.abs( Y ) / 200,1) ^ 2) * 255

		if Alpha <= 0 then continue end

		surface.SetDrawColor( self.HudColor.r, self.HudColor.g, self.HudColor.b, Alpha * 0.75 )
		surface.DrawLine(Pos2D.x - 200 - SizeX, Pos2D.y + Y, Pos2D.x - 200, Pos2D.y + Y ) 
		surface.DrawLine(Pos2D.x + 200 + SizeX, Pos2D.y + Y, Pos2D.x + 200, Pos2D.y + Y ) 
		surface.SetDrawColor( 0, 0, 0, Alpha * 0.25 )
		surface.DrawLine(Pos2D.x - 200 - SizeX, Pos2D.y + Y + 1, Pos2D.x - 200, Pos2D.y + Y + 1 ) 
		surface.DrawLine(Pos2D.x + 200 + SizeX, Pos2D.y + Y + 1, Pos2D.x + 200, Pos2D.y + Y + 1) 

		if not IsTen then continue end

		draw.DrawText( i, "LVS_FONT_HUD", Pos2D.x - 225, Pos2D.y + Y - 10, Color( self.HudColor.r, self.HudColor.g, self.HudColor.b, Alpha * 0.5 ), TEXT_ALIGN_RIGHT )
		draw.DrawText( i, "LVS_FONT_HUD", Pos2D.x + 225, Pos2D.y + Y - 10, Color( self.HudColor.r, self.HudColor.g, self.HudColor.b, Alpha * 0.5 ), TEXT_ALIGN_LEFT )
	end
end

function ENT:LVSHudPaintHelicopter( X, Y, ply, HitPilot )
	local pod = self:GetDriverSeat()

	if not IsValid( pod ) or ply:GetVehicle() ~= pod then return end

	if self.Hud then
		if not pod:GetThirdPersonMode() then
			self:PaintHeliFlightInfo( X, Y, ply, HitPilot )
		end
	end

	if self.HudThirdPerson then
		if pod:GetThirdPersonMode() then
			self:PaintHeliFlightInfo( X, Y, ply, HitPilot )
		end
	end
end

