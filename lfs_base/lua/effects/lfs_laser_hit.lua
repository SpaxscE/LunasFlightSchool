--DO NOT EDIT OR REUPLOAD THIS FILE

local Materials = {
	"particle/smokesprites_0001",
	"particle/smokesprites_0002",
	"particle/smokesprites_0003",
	"particle/smokesprites_0004",
	"particle/smokesprites_0005",
	"particle/smokesprites_0006",
	"particle/smokesprites_0007",
	"particle/smokesprites_0008",
	"particle/smokesprites_0009",
	"particle/smokesprites_0010",
	"particle/smokesprites_0011",
	"particle/smokesprites_0012",
	"particle/smokesprites_0013",
	"particle/smokesprites_0014",
	"particle/smokesprites_0015",
	"particle/smokesprites_0016"
}

local DecalMat = Material( util.DecalMaterial( "FadingScorch" ) )
function EFFECT:Init( data )
	self.Pos = data:GetOrigin()
	self.Col = data:GetStart() or Vector(255,100,0)
	
	self.mat = Material( "sprites/light_glow02_add" )
	
	self.LifeTime = math.Rand(2,3)
	self.DieTime = CurTime() + self.LifeTime
	self.DieTimeGlow = CurTime() + 0.2

	local Col = self.Col
	local Pos = self.Pos
	local Dir = data:GetNormal()
	
	local emitter = ParticleEmitter( Pos, false )

	local trace = util.TraceLine( {
		start = Pos - Dir * 5,
		endpos = Pos + Dir * 5,
	} )

	if trace.Hit and not trace.HitNonWorld then
		--sound.Play( Sound( "weapons/laserimpact/laserhit"..math.random(1,10)..".wav" ), trace.HitPos, SNDLVL_95dB)

		self.RenderGlow = {
			Pos = trace.HitPos,
			Normal = trace.HitNormal,
			Angle = trace.HitNormal:Angle() + Angle(90,0,0),
			RandomAng = math.random(0,360),
		}

		util.DecalEx( DecalMat, trace.Entity, trace.HitPos + trace.HitNormal, trace.HitNormal, Color(255,255,255,255), math.Rand(0.4,0.8), math.Rand(0.4,0.8) )

		for i = 0,3 do
			local particle = emitter:Add( "effects/fleck_tile"..math.random(1,2), Pos - Dir * 1)
			local vel = -Dir * 150 + VectorRand() * 100
			if particle then
				particle:SetVelocity( vel )
				particle:SetDieTime( math.Rand(2,4) )
				particle:SetAirResistance( 10 ) 
				particle:SetStartAlpha( 255 )
				particle:SetStartSize( 1 )
				particle:SetEndSize( 1 )
				particle:SetRoll( math.Rand(-1,1) * 200 )
				particle:SetColor( 50,50,50 )
				particle:SetGravity( Vector( 0, 0, -600 ) )
				particle:SetCollide( true )
				particle:SetBounce( 0.3 )
			end
		end

		--self.snd = CreateSound(self, "weapons/flaregun/burn.wav")
		--self.snd:PlayEx(0.3,120)
		--self.snd:ChangeVolume( 0, self.LifeTime )
		--self.snd:ChangePitch( 60, self.LifeTime )
	end

	for i = 0, 10 do
		local particle = emitter:Add( "sprites/light_glow02_add", Pos )
		
		local vel = VectorRand() * 200 - Dir  * 80
		
		if particle then
			particle:SetVelocity( vel )
			particle:SetAngles( vel:Angle() + Angle(0,90,0) )
			particle:SetDieTime( math.Rand(0.2,0.4) )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( math.Rand(12,24) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand(-100,100) )
			particle:SetRollDelta( math.Rand(-100,100) )
			particle:SetColor( Col.x,Col.y,Col.z )
			particle:SetGravity( Vector(0,0,-600) )

			particle:SetAirResistance( 0 )
			
			particle:SetCollide( true )
			particle:SetBounce( 0.5 )
		end
	end

	for i = 0, 6 do
		local particle = emitter:Add( "sprites/rico1", Pos )
		
		local vel = VectorRand() * 80 + Dir * math.Rand(80,120)
		
		if particle then
			particle:SetVelocity( vel )
			particle:SetAngles( vel:Angle() + Angle(0,90,0) )
			particle:SetDieTime( math.Rand(1,2) )
			particle:SetStartAlpha( math.Rand( 200, 255 ) )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( 1 )
			particle:SetEndSize( 0.25 )
			particle:SetRoll( math.Rand(-100,100) )
			particle:SetRollDelta( math.Rand(-100,100) )
			particle:SetCollide( true )
			particle:SetBounce( 0.5 )
			particle:SetAirResistance( 0 )
			particle:SetColor( 255, 150, 0 )
			particle:SetGravity( Vector(0,0,-600) )
		end
	end

	self.Emitter = emitter
end

function EFFECT:Think()
	if self.DieTime < CurTime() then 
		if self.Emitter then
			self.Emitter:Finish()
		end

		if self.snd then
			self.snd:Stop()
		end

		return false
	end

	return true
end

local Mat = Material("particle/particle_glow_05_addnofog")
function EFFECT:Render()
	local Scale = (self.DieTimeGlow - CurTime()) / 0.2
	if Scale > 0 then
		render.SetMaterial( self.mat )
		render.DrawSprite( self.Pos, 100 * Scale, 100 * Scale, Color( self.Col.x, self.Col.y, self.Col.z, 255) )
		render.DrawSprite( self.Pos, 25 * Scale, 25 * Scale, Color( 255, 255, 255, 255) )
	end

	if self.RenderGlow then
		local Timed = 1 - (self.DieTime - CurTime()) / self.LifeTime
		local Scale = math.max(math.min(2 - Timed * 2,1),0)

		cam.Start3D2D( self.RenderGlow.Pos + self.RenderGlow.Normal * 0.5, self.RenderGlow.Angle, 0.1 )
			--draw.NoTexture()
			surface.SetMaterial( Mat )
			surface.SetDrawColor( 255, 93 + 50 * Scale, 50 * Scale, 200 * Scale )
			surface.DrawTexturedRectRotated( 0, 0, 300 , 300 , self.RenderGlow.RandomAng )
		cam.End3D2D()

		if self.Emitter then
			if (self.NextFX or 0) < CurTime() then
				self.NextFX = CurTime() + 0.05
	
				local particle = self.Emitter:Add( table.Random( Materials ) , self.RenderGlow.Pos )

				if particle then
					particle:SetVelocity( self.RenderGlow.Normal * math.Rand(20,25) + VectorRand() * 20 )
					particle:SetDieTime( math.Rand(0.5,0.6) )
					particle:SetAirResistance( 500 ) 
					particle:SetStartAlpha( math.Rand(100,150) * Scale )
					particle:SetEndAlpha( 0 )
					particle:SetStartSize( 0 )
					particle:SetEndSize( math.Rand(5,10) )
					particle:SetRoll( math.Rand( -1, 1 ) )
					particle:SetColor( 50,50,50 )
					particle:SetGravity( Vector( 0, 0, 300 ) )
					particle:SetCollide( false )
				end
			end
		end
	end
end
