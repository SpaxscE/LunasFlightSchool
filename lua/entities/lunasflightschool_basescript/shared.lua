--DO NOT EDIT OR REUPLOAD THIS FILE

ENT.Base = "lvs_base"

ENT.PrintName = "basescript"
ENT.Author = "Luna"
ENT.Information = "Luna's Flight School Plane Basescript"
ENT.Category = "[LFS]"

ENT.Spawnable		= false
ENT.AdminSpawnable  = false

ENT.AutomaticFrameAdvance = true
ENT.RenderGroup = RENDERGROUP_BOTH 

ENT.MDL = "error.mdl"

ENT.LFS = true

ENT.AITEAM = 0

ENT.Mass = 2000
ENT.Inertia = Vector(250000,250000,250000)
ENT.Drag = 0

ENT.SeatPos = Vector(32,0,67.5)
ENT.SeatAng = Angle(0,-90,0)

ENT.IdleRPM = 300
ENT.MaxRPM = 1200
ENT.LimitRPM = 2000

ENT.RotorPos = Vector(80,0,0)
ENT.WingPos = Vector(40,0,0)
ENT.ElevatorPos = Vector(-40,0,0)
ENT.RudderPos = Vector(-40,0,15)

ENT.MaxVelocity = 2500

ENT.MaxThrust = 500

ENT.MaxTurnPitch = 300
ENT.MaxTurnYaw = 300
ENT.MaxTurnRoll = 300

ENT.MaxPerfVelocity = 2600

ENT.MaxHealth = 1000
ENT.MaxShield = 0

ENT.MaxPrimaryAmmo = -1
ENT.MaxSecondaryAmmo = -1

ENT.MaintenanceTime = 8
ENT.MaintenanceRepairAmount = 250

function ENT:SetupDataTables()
	self:CreateBaseDT()

	self:AddDT( "Entity", "Gunner" )
	self:AddDT( "Entity", "GunnerSeat" )
	
	self:AddDT( "Bool", "IsGroundTouching" )
	self:AddDT( "Bool", "RotorDestroyed" )

	self:AddDT( "Float", "LGear" )
	self:AddDT( "Float", "RGear" )
	self:AddDT( "Float", "RPM" )
	self:AddDT( "Float", "RotPitch" )
	self:AddDT( "Float", "RotYaw" )
	self:AddDT( "Float", "RotRoll" )
	self:AddDT( "Float", "MaintenanceProgress" )

	self:AddDT( "Int", "AmmoPrimary", { KeyName = "primaryammo", Edit = { type = "Int", order = 3,min = 0, max = self.MaxPrimaryAmmo, category = "Weapons"} } )
	self:AddDT( "Int", "AmmoSecondary", { KeyName = "secondaryammo", Edit = { type = "Int", order = 4,min = 0, max = self.MaxSecondaryAmmo, category = "Weapons"} } )

	self:AddDataTables()

	if SERVER then
		self:ReloadWeapon()

		-- failsave for vehicles that overwrite ENT:Initialize() such as the ATTE
		timer.Simple( 1, function()
			if not IsValid( self ) then return end

			self:SetlvsReady( true )
		end )
	end
end

function ENT:GetlfsLockedStatus()
	return self:GetlvsLockedStatus()
end

function ENT:SetlfsLockedStatus( lock )
	return self:SetlvsLockedStatus( lock )
end

function ENT:CalcMainActivity( ply )
end

function ENT:StartCommand( ply, cmd )
end

function ENT:AddDataTables()
end

function ENT:GetMaxAmmoPrimary()
	return self.MaxPrimaryAmmo
end

function ENT:GetMaxAmmoSecondary()
	return self.MaxSecondaryAmmo
end

function ENT:GetIdleRPM()
	return self.IdleRPM
end

function ENT:GetMaxRPM()
	return self.MaxRPM
end

function ENT:GetLimitRPM()
	return self.LimitRPM
end

function ENT:GetMaxVelocity()
	return self.MaxVelocity
end

function ENT:GetMaxTurnSpeed()
	return  {p = self.MaxTurnPitch, y = self.MaxTurnYaw, r = self.MaxTurnRoll }
end

function ENT:GetMaxPerfVelocity()
	return self.MaxPerfVelocity
end

function ENT:GetMaxThrust()
	return self.MaxThrust
end

function ENT:GetThrustVtol()
	self.MaxThrustVtol = isnumber( self.MaxThrustVtol ) and self.MaxThrustVtol or self:GetMaxThrust() * 0.15
	
	return self.MaxThrustVtol
end

function ENT:GetRotorPos()
	return self:LocalToWorld( self.RotorPos )
end

function ENT:GetWingPos()
	return self:LocalToWorld( self.WingPos )
end

function ENT:GetWingUp()
	return self:GetUp()
end

function ENT:GetElevatorUp()
	return self:GetUp()
end

function ENT:GetRudderUp()
	return self:GetRight()
end

function ENT:GetElevatorPos()
	return self:LocalToWorld( self.ElevatorPos )
end

function ENT:GetRudderPos()
	return self:LocalToWorld( self.RudderPos )
end

function ENT:GetMaxStability()
	self.MaxStability = self.MaxStability or 1
	
	return self.MaxStability
end

function ENT:GetThrottlePercent()
	local IdleRPM = self:GetIdleRPM()
	local MaxRPM = self:GetMaxRPM()
	
	return math.max( math.Round(((self:GetRPM() - IdleRPM) / (MaxRPM - IdleRPM)) * 100,0) ,0)
end

function ENT:IsGunship()
	return false
end

function ENT:IsSpaceShip()
	return isnumber( self.Stability )
end

function ENT:IsHelicopter()
	return false
end

function ENT:GetVehicleType()
	return "Plane"
end

sound.Add( {
	name = "LFS_PLANE_EXPLOSION",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 125,
	pitch = {75, 120},
	sound = {"^lfs/plane_explosion1.wav","^lfs/plane_explosion2.wav","^lfs/plane_explosion3.wav"}
} )

sound.Add( {
	name = "LFS_PLANE_KNOCKOUT",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 140,
	pitch = 100,
	sound = {"lfs/plane_preexp1.ogg","lfs/plane_preexp2.ogg","lfs/plane_preexp3.ogg"}
} )

sound.Add( {
	name = "LFS_PROPELLER",
	channel = CHAN_VOICE,
	volume = 1.0,
	level = 80,
	sound = "^lfs/cessna/propeller.wav"
} )

sound.Add( {
	name = "LFS_PROPELLER_STRAIN",
	channel = CHAN_VOICE2,
	volume = 1.0,
	level = 80,
	sound = "^lfs/cessna/propeller_strain.wav"
} )