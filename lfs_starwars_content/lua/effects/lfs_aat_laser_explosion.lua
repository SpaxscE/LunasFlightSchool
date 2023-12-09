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

function EFFECT:Init( data )
	local Pos = data:GetOrigin()
	self.Pos = Pos

	self.LifeTime = 0.4
	self.DieTime = CurTime() + self.LifeTime
	self.DieTimeGlow = CurTime() + 0.2

	self.matA = Material( "particle/warp1_warp" )
	self.mat = Material( "sprites/light_glow02_add" )

	sound.Play( "lfsAAT_EXPLOSION", Pos )
	self:Explosion( Pos )
end

function EFFECT:Explosion( pos )
	local emitter = ParticleEmitter( pos, false )
	
	if not emitter then return end

	for i = 0,12 do
		local particle = emitter:Add( table.Random( Materials ), pos + VectorRand() * 5 )
		
		if particle then
			particle:SetVelocity( VectorRand() * 1000 )
			particle:SetDieTime( math.Rand(1,2) )
			particle:SetAirResistance( math.Rand(700,1200) ) 
			particle:SetStartAlpha( 150 )
			particle:SetStartSize( math.Rand(25,30) )
			particle:SetEndSize( math.Rand(80,100) )
			particle:SetRoll( math.Rand(-1,1) )
			particle:SetColor( 50,50,50 )
			particle:SetGravity( Vector( 0, 0, 60 ) )
			particle:SetCollide( false )
		end
	end

	for i = 0, 15 do
		local particle = emitter:Add( "sprites/light_glow02_add", pos )
		
		local vel = VectorRand() * 450
		
		if particle then
			particle:SetVelocity( vel )
			particle:SetAngles( vel:Angle() + Angle(0,90,0) )
			particle:SetDieTime( math.Rand(1,1.6) )
			particle:SetStartAlpha( 255 )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( math.Rand(12,15) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand(-100,100) )
			particle:SetRollDelta( math.Rand(-100,100) )
			particle:SetColor( 255,0,0 )
			particle:SetGravity( Vector(0,0,-600) )

			particle:SetAirResistance( 0 )
			
			particle:SetCollide( true )
			particle:SetBounce( 0.5 )
		end
	end

	for i = 0, 5 do
		local particle = emitter:Add( "sprites/rico1", pos )
		
		local vel = VectorRand() * 1000
		
		if particle then
			particle:SetVelocity( vel )
			particle:SetAngles( vel:Angle() + Angle(0,90,0) )
			particle:SetDieTime( math.Rand(0.5,0.8) )
			particle:SetStartAlpha( math.Rand( 200, 255 ) )
			particle:SetEndAlpha( 0 )
			particle:SetStartSize( math.Rand(10,20) )
			particle:SetEndSize( 0 )
			particle:SetRoll( math.Rand(-100,100) )
			particle:SetRollDelta( math.Rand(-100,100) )
			particle:SetColor( 255, 0, 0 )
			particle:SetGravity( -vel:GetNormalized() * math.random(1250,1750) )
			particle:SetCollide( true )
			particle:SetBounce( 0.5 )

			particle:SetAirResistance( 200 )
		end
	end

	for i = 0, 20 do
		local particle = emitter:Add( "sprites/flamelet"..math.random(1,5), pos )
		
		if particle then
			particle:SetVelocity( VectorRand(-1,1) * 500 )
			particle:SetDieTime( 0.14 )
			particle:SetStartAlpha( 255 )
			particle:SetStartSize( 10 )
			particle:SetEndSize( math.Rand(30,60) )
			particle:SetEndAlpha( 100 )
			particle:SetRoll( math.Rand( -1, 1 ) )
			particle:SetColor( 200,150,150 )
			particle:SetCollide( false )
		end
	end

	emitter:Finish()
end

function EFFECT:Think()
	if self.DieTime < CurTime() then return false end

	return true
end

function EFFECT:Render()
	local Scale = math.max((self.DieTime - self.LifeTime + 0.3 - CurTime()) / 0.3,0)
	render.SetMaterial( self.matA )
	render.DrawSprite( self.Pos, 300 * Scale, 300 * Scale, Color( 255, 255, 255, 255) )

	render.SetMaterial( self.mat )
	render.DrawSprite( self.Pos, 1000 * Scale, 1000 * Scale, Color( 255, 100, 50, 255) )

	local Scale = (self.DieTimeGlow - CurTime()) / 0.2
	if Scale > 0 then
		render.SetMaterial( self.mat )
		render.DrawSprite( self.Pos, 100 * Scale, 100 * Scale, Color( 250, 0, 0, 255) )
		render.DrawSprite( self.Pos, 25 * Scale, 25 * Scale, Color( 255, 255, 255, 255) )
	end

	local Scale = (self.DieTime - self.LifeTime + 0.25 - CurTime()) / 0.25
	local InvScale = 1 - Scale
	if Scale > 0 then
		render.SetColorMaterial()
		render.DrawSphere( self.Pos, -180 * InvScale, 30,30, Color( 255, 0, 0, 255 * (Scale ^ 2) ) )
		render.DrawSphere( self.Pos, -190 * InvScale, 30,30, Color( 255, 0, 0, 150 * (Scale ^ 2) ) )
		render.DrawSphere( self.Pos, -200 * InvScale, 30,30, Color( 255, 0, 0, 50 * (Scale ^ 2) ) )
		render.DrawSphere( self.Pos, 210 * InvScale, 30,30, Color( 255, 0, 0, 50 * (Scale ^ 2) ) )
	end
end
