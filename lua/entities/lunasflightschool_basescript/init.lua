AddCSLuaFile( "shared.lua" )
AddCSLuaFile( "cl_init.lua" )
AddCSLuaFile( "cl_camera.lua" )
AddCSLuaFile( "cl_hud.lua" )
AddCSLuaFile( "sh_camera_eyetrace.lua" )
include("shared.lua")
include("sh_camera_eyetrace.lua")

function ENT:Initialize()
	self:SetModel( self.MDL )

	self:PhysicsInit( SOLID_VPHYSICS )
	self:SetMoveType( MOVETYPE_VPHYSICS )
	self:SetSolid( SOLID_VPHYSICS )
	self:SetUseType( SIMPLE_USE )
	self:SetRenderMode( RENDERMODE_NORMAL )

	-- this is so vj npcs can still see us
	self:AddEFlags( EFL_DONTBLOCKLOS )

	-- this if for our npc relationship system to work
	self:AddFlags( FL_OBJECT )

	local PObj = self:GetPhysicsObject()

	if not IsValid( PObj ) then 
		self:Remove()
		
		print("LVS: missing model. Plane terminated.")
		
		return
	end

	PObj:SetMaterial( "default_silent" )
	PObj:EnableMotion( false )
	PObj:SetMass( self.Mass ) 
	PObj:SetDragCoefficient( self.Drag ) 
	self.LFSInertiaDefault = PObj:GetInertia()
	PObj:SetInertia( self.Inertia ) 

	self:InitPod()
	self:InitWheels()

	local SpawnSuccess, ErrorMsg = pcall( function() self:RunOnSpawn() end )

	if not SpawnSuccess then
		ErrorNoHalt( "\n[ERROR] "..ErrorMsg.."\n\n" )
	end

	self:AutoAI()

	timer.Simple(0, function()
		if not IsValid( self ) or not IsValid( PObj ) then print("LVS: ERROR couldn't initialize vehicle.") return end

		self:PostInitialize( PObj )
	end)

	if not istable( self.GibModels ) then return end

	for _, modelName in ipairs( self.GibModels ) do
		util.PrecacheModel( modelName )
	end
end

function ENT:RunOnSpawn()
end

function ENT:CanSound()
	self.NextSound = self.NextSound or 0
	return self.NextSound < CurTime()
end

function ENT:DelayNextSound( fDelay )
	if not isnumber( fDelay ) then return end
	
	self.NextSound = CurTime() + fDelay
end

function ENT:SetNextPrimary( delay )
	self.NextPrimary = CurTime() + delay
end

function ENT:SetNextSecondary( delay )
	self.NextSecondary = CurTime() + delay
end

function ENT:CanPrimaryAttack()
	self.NextPrimary = self.NextPrimary or 0
	return self.NextPrimary < CurTime()
end

function ENT:CanSecondaryAttack()
	self.NextSecondary = self.NextSecondary or 0
	return self.NextSecondary < CurTime()
end

function ENT:TakePrimaryAmmo( amount )
	amount = amount or 1
	
	self:SetAmmoPrimary( math.max(self:GetAmmoPrimary() - amount,0) )
end

function ENT:TakeSecondaryAmmo( amount )
	amount = amount or 1
	
	self:SetAmmoSecondary( math.max(self:GetAmmoSecondary() - amount,0) )
end

function ENT:PrimaryAttack()
	if not self:CanPrimaryAttack() then return end

	self:SetNextPrimary( 0.1 )
	
	self:TakePrimaryAmmo()
end

function ENT:SecondaryAttack()
	if not self:CanSecondaryAttack() then return end
	
	self:SetNextSecondary( 0.15 )
	
	self:TakeSecondaryAmmo()
end

function ENT:OnReloadWeapon()
	self:EmitSound("lfs/weapons_reload.wav")
end

function ENT:OnUnloadWeapon()
	self:EmitSound("weapons/357/357_reload4.wav")
end

function ENT:ReloadWeapon()
	self:SetAmmoPrimary( self:GetMaxAmmoPrimary() )
	self:SetAmmoSecondary( self:GetMaxAmmoSecondary() )

	self:OnReloadWeapon()
end

function ENT:UnloadWeapon()
	if self:GetMaxAmmoPrimary() > 0 then
		self:SetAmmoPrimary( 0 )
	end

	if self:GetMaxAmmoSecondary() > 0 then
		self:SetAmmoSecondary( 0 )
	end

	self:OnUnloadWeapon()
end

function ENT:HandleWeapons(Fire1, Fire2)
	local Driver = self:GetDriver()
	
	if IsValid( Driver ) then
		if self:GetAmmoPrimary() > 0 then
			Fire1 = Driver:KeyDown( IN_ATTACK )
		end
		
		if self:GetAmmoSecondary() > 0 then
			Fire2 = Driver:KeyDown( IN_ATTACK2 )
		end
	end
	
	if Fire1 then
		self:PrimaryAttack()
	end
	
	if Fire2 then
		self:SecondaryAttack()
	end
end

function ENT:OnTick()
end

function ENT:CalcFlightOverride( Pitch, Yaw, Roll, Stability )
	return Pitch,Yaw,Roll,Stability,Stability,Stability
end

function ENT:CalcFlight()
	local MaxTurnSpeed = self:GetMaxTurnSpeed()
	local MaxPitch = MaxTurnSpeed.p
	local MaxYaw = MaxTurnSpeed.y
	local MaxRoll = MaxTurnSpeed.r
	
	local IsInVtolMode = self:IsVtolModeActive()
	
	local PhysObj = self:GetPhysicsObject()
	if not IsValid( PhysObj ) then return end
	
	local Pod = self:GetDriverSeat()
	if not IsValid( Pod ) then return end
	
	local Driver = Pod:GetDriver()
	
	local A = false
	local D = false
	
	local LocalAngPitch = 0
	local LocalAngYaw = 0
	local LocalAngRoll = 0
	
	local AngDiff = 0
	
	if IsValid( Driver ) then 
		local EyeAngles = Pod:WorldToLocalAngles( Driver:EyeAngles() )

		if Driver:lfsGetInput( "FREELOOK" ) then
			if isangle( self.StoredEyeAngles ) then
				EyeAngles = self.StoredEyeAngles
			end
		else
			self.StoredEyeAngles = EyeAngles
		end

		local LocalAngles = self:WorldToLocalAngles( EyeAngles )

		local Pitch_Up = Driver:lfsGetInput( "+PITCH" )
		local Pitch_Dn = Driver:lfsGetInput( "-PITCH" )
		local Yaw_R = Driver:lfsGetInput( "+YAW" )
		local Yaw_L = Driver:lfsGetInput( "-YAW" )
		local Roll_R = Driver:lfsGetInput( "+ROLL" )
		local Roll_L = Driver:lfsGetInput( "-ROLL" ) 

		if not IsInVtolMode then
			if Pitch_Up or Pitch_Dn then
				EyeAngles = self:GetAngles()
				
				self.StoredEyeAngles = Angle(EyeAngles.p,EyeAngles.y,0)
				
				local X = (Pitch_Up and -90 or 0) + (Pitch_Dn and 90 or 0)

				LocalAngles = Angle(X,0,0)
			end
		end

		if Yaw_R or Yaw_L then
			EyeAngles = self:GetAngles()
			
			self.StoredEyeAngles = Angle(EyeAngles.p,EyeAngles.y,0)
			
			LocalAngles.y = (Yaw_R and -90 or 0) + (Yaw_L and 90 or 0)
		end

		if Yaw_R or Yaw_L then
			A = not Roll_R
			D = not Roll_L
		else
			A = Roll_L
			D = Roll_R
		end

		LocalAngPitch = LocalAngles.p
		LocalAngYaw = LocalAngles.y
		LocalAngRoll = LocalAngles.r + math.cos(CurTime()) * 2

		local EyeAngForward = EyeAngles:Forward()
		local Forward = self:GetForward()

		AngDiff = math.deg( math.acos( math.Clamp( Forward:Dot(EyeAngForward) ,-1,1) ) )
	else
		local EyeAngles = self:GetAngles()
		
		if self:GetAI() then
			EyeAngles = self:RunAI()
		else
			if self:IsSpaceShip() and isangle( self.StoredEyeAngles ) then
				EyeAngles = self.StoredEyeAngles
			end
		end
		
		local LocalAngles = self:WorldToLocalAngles( EyeAngles )
		
		LocalAngPitch = LocalAngles.p
		LocalAngYaw = LocalAngles.y
		LocalAngRoll = LocalAngles.r
		
		local EyeAngForward = EyeAngles:Forward()
		local Forward = self:GetForward()
		
		AngDiff = math.deg( math.acos( math.Clamp( Forward:Dot(EyeAngForward) ,-1,1) ) )
	end
	
	local WingFinFadeOut = math.max( (90 - AngDiff ) / 90, 0 )
	local RudderFadeOut = math.max( (60 - AngDiff ) / 60, 0 )

	self:SteerWheel( LocalAngYaw )
	
	local Stability = self:GetStability()

	local RollRate =  math.min(self:GetVelocity():Length() / math.min(self:GetMaxVelocity() * 0.5,3000),1)

	RudderFadeOut = math.max(RudderFadeOut,1 - RollRate)

	local RollLeft = A and MaxRoll or 0
	local RollRight = D and MaxRoll or 0

	if (RollLeft + RollRight) == 0 then
		self.m_smRoll = 0
	else
		self.m_smRoll = self.m_smRoll and self.m_smRoll + ((RollRight - RollLeft) - self.m_smRoll) * FrameTime() * 5 or 0

		if (self.m_smRoll > 0 and RollLeft > 0) or (self.m_smRoll < 0 and RollRight > 0) then
			self.m_smRoll = 0
		end
	end

	local ManualRoll = self.m_smRoll

	local AutoRoll = (-LocalAngYaw * 22 * RollRate + LocalAngRoll * 3.5 * RudderFadeOut) * WingFinFadeOut
	local VtolRoll = math.Clamp(((D and 10 or 0) - (A and 10 or 0) - self:GetAngles().r) * 5, -MaxRoll, MaxRoll)

	local P = math.Clamp(-LocalAngPitch * 25,-MaxPitch,MaxPitch)
	local Y = math.Clamp(-LocalAngYaw * 160 * RudderFadeOut,-MaxYaw,MaxYaw)
	local R = math.Clamp( (not A and not D) and AutoRoll or (IsInVtolMode and VtolRoll or ManualRoll),-MaxRoll ,MaxRoll )
	
	local Pitch,Yaw,Roll,StabW,StabE,StabR = self:CalcFlightOverride( P, Y, R, Stability )
	
	local Mass = PhysObj:GetMass()
	
	self:ApplyAngForce( Angle(0,0,-self:GetAngVel().r + Roll * StabW) *  Mass * 500 * StabW )
	
	PhysObj:ApplyForceOffset( -self:GetWingUp() * self:GetWingVelocity() *  Mass * StabW, self:GetWingPos() )
	
	PhysObj:ApplyForceOffset( -self:GetElevatorUp() * (self:GetElevatorVelocity() + Pitch * StabE) * Mass * StabE, self:GetElevatorPos() )
	
	PhysObj:ApplyForceOffset( -self:GetRudderUp() * (math.Clamp(self:GetRudderVelocity(),-MaxYaw,MaxYaw) + Yaw * StabR) *  Mass * StabR, self:GetRudderPos() )

	if self:IsSpaceShip() then
		if self:GetEngineActive() then
			if IsInVtolMode then
				PhysObj:ApplyForceCenter( self:GetRight() * (self:WorldToLocal( self:GetPos() + self:GetVelocity() ).y + ManualRoll) * Mass * 0.2 )
			else
				PhysObj:ApplyForceCenter( self:GetRight() * self:WorldToLocal( self:GetPos() + self:GetVelocity() ).y * Mass * 0.01 )
			end
		end
	else
		PhysObj:ApplyForceCenter( self:GetRight() * self:WorldToLocal( self:GetPos() + self:GetVelocity() ).y * Mass * 0.01 * Stability )
	end

	self:SetRotPitch( (Pitch / MaxPitch) * 30 )
	self:SetRotYaw( (Yaw / MaxYaw) * 30 )
	self:SetRotRoll( (Roll / MaxRoll) * 30 )
end

function ENT:Think()

	self:HandleActive()
	self:HandleStart()

	-- lvs
	self:PhysicsThink()
	self:DamageThink()

	self:HandleLandingGear()
	self:HandleWeapons()
	self:CalcFlight()
	self:HandleEngine()

	-- lvs
	self:ShieldThink()
	self:WeaponsThink()

	self:OnTick()

	self:NextThink( CurTime() )
	
	return true
end

function ENT:SteerWheel( SteerAngle )
	if IsValid( self.wheel_C_master ) then
		if isvector( self.WheelPos_L ) and isvector( self.WheelPos_R ) and isvector( self.WheelPos_C ) then
			local SteerMaster = self.wheel_C_master
			local smPObj = SteerMaster:GetPhysicsObject()
			
			if IsValid( smPObj ) then
				if smPObj:IsMotionEnabled() then
					smPObj:EnableMotion( false )
				end
			end
			
			local Mirror = ((self.WheelPos_L.x + self.WheelPos_R.x) * 0.5 > self.WheelPos_C.x) and -1 or 1
			
			self.wheel_C_master:SetAngles( self:LocalToWorldAngles( Angle(0,math.Clamp(SteerAngle * Mirror,-45,45),0) ) )
		end
	end
end

function ENT:HitGround()
	if not isvector( self.obbvc ) or not isnumber( self.obbvm ) then
		self.obbvc = self:OBBCenter() 
		self.obbvm = self:OBBMins().z
	end
	
	local tr = util.TraceLine( {
		start = self:LocalToWorld( self.obbvc ),
		endpos = self:LocalToWorld( self.obbvc + Vector(0,0,self.obbvm - 100) ),
		filter = function( ent ) 
			if ( ent == self ) then 
				return false
			end
		end
	} )
	
	return tr.Hit 
end

function ENT:OnKeyThrottle( bPressed )
end

function ENT:HandleEngine()
	local IdleRPM = self:GetIdleRPM()
	local MaxRPM = self:GetMaxRPM()
	local LimitRPM = self:GetLimitRPM()
	local MaxVelocity = self:GetMaxVelocity()
	
	local EngActive = self:GetEngineActive()

	local KeyThrottle = false
	local KeyBrake = false

	self.TargetRPM = self.TargetRPM or 0
	
	if EngActive then
		local Pod = self:GetDriverSeat()
		
		if not IsValid( Pod ) then return end
		
		local Driver = Pod:GetDriver()
		
		local RPMAdd = 0
		
		if IsValid( Driver ) then 
			KeyThrottle = Driver:lfsGetInput( "+THROTTLE" )
			KeyBrake = Driver:lfsGetInput( "-THROTTLE" )
			
			RPMAdd = ((KeyThrottle and self:GetThrottleIncrement() or 0) - (KeyBrake and self:GetThrottleIncrement() or 0)) * FrameTime()
		end
		
		if KeyThrottle ~= self.oldKeyThrottle then
			self.oldKeyThrottle = KeyThrottle
			
			self:OnKeyThrottle( KeyThrottle )
		end
		
		self.TargetRPM = math.Clamp( self.TargetRPM + RPMAdd,IdleRPM,((self:GetAI() or KeyThrottle) and self:GetWepEnabled()) and LimitRPM or MaxRPM)
	else
		self.TargetRPM = self.TargetRPM - math.Clamp(self.TargetRPM,-250,250)
	end

	if isnumber( self.VtolAllowInputBelowThrottle ) and not self:GetAI() then
		local MaxRPMVtolMin = self:GetMaxRPM() * ((self.VtolAllowInputBelowThrottle - 1) / 100)

		if self:GetRPM() < MaxRPMVtolMin and not KeyThrottle then
			self.TargetRPM = math.min( self.TargetRPM, MaxRPMVtolMin )
		end

		--[[ -- while it makes perfect sense to clamp it in both directions, it just doesnt feel right
		local MaxRPMVtolMax = self:GetMaxRPM() * (self.VtolAllowInputBelowThrottle / 100)
		if self:GetRPM() > MaxRPMVtolMax and not KeyBrake then
			self.TargetRPM = math.max( self.TargetRPM, MaxRPMVtolMax )
		end
		]]--
	end

	self:SetRPM( self:GetRPM() + (self.TargetRPM - self:GetRPM()) * FrameTime() )
	
	local PhysObj = self:GetPhysicsObject()
	
	if not IsValid( PhysObj ) then return end
	
	local fThrust = MaxVelocity * (self:GetRPM() / LimitRPM) - self:GetForwardVelocity()
	
	if not self:IsSpaceShip() and not self:GetAI() then fThrust = math.max( fThrust ,0 ) end
	
	local Force = fThrust / MaxVelocity * self:GetMaxThrust() * LimitRPM * FrameTime()
	
	if self:IsDestroyed() or not EngActive then
		self:StopEngine()
		
		return
	end
	
	if self.VerticalTakeoff then
		if self:IsSpaceShip() then
			local Driver = self:GetDriver()

			if IsValid( Driver ) then 
				local IsVtolActive = self:IsVtolModeActive()

				if self.oldVtolMode ~= IsVtolActive then
					self.oldVtolMode = IsVtolActive
					self:OnVtolMode( IsVtolActive )
				end

				if IsVtolActive then
					if isnumber( self.VtolAllowInputBelowThrottle ) then
						local KeyThrottle = Driver:lfsGetInput( "+PITCH" )
						local KeyBrake = Driver:lfsGetInput( "-THROTTLE" ) and self:GetThrottlePercent() <= 10
			
						local Up = KeyThrottle and self:GetThrustVtol() or 0
						local Down = KeyBrake and -self:GetThrustVtol() or 0
						
						local VtolForce = (Up + Down) * PhysObj:GetMass() * 0.015
						
						self.smfForce = isnumber( self.smfForce ) and (self.smfForce + (VtolForce - self.smfForce) * FrameTime() * 2) or VtolForce
						self:ApplyThrustVtol( PhysObj, self:GetUp(), self.smfForce )
					else
						self.TargetRPM = (self:GetVelocity():Length() / MaxVelocity) * LimitRPM
						
						local Up = Driver:lfsGetInput( "+THROTTLE" ) and self:GetThrustVtol() or 0
						local Down = Driver:lfsGetInput( "-THROTTLE" ) and -self:GetThrustVtol() or 0
						
						local VtolForce = (Up + Down) * PhysObj:GetMass() * 0.015
						
						self.smfForce = isnumber( self.smfForce ) and (self.smfForce + (VtolForce - self.smfForce) * FrameTime() * 2) or VtolForce
						self:ApplyThrustVtol( PhysObj, self:GetUp(), self.smfForce )
						
						return
					end
				end
			end
		end
	end
	
	self:ApplyThrust( PhysObj, self:GetForward(), Force )
end

function ENT:OnVtolMode( On )
end

function ENT:IsVtolModeActive()
	if not self.VerticalTakeoff then return false end
	
	if isnumber( self.VtolAllowInputBelowThrottle ) then
		return self.VtolAllowInputBelowThrottle > self:GetThrottlePercent()
	else
		return not self.LandingGearUp
	end
end

function ENT:ApplyThrustVtol( PhysObj, vDirection, fForce )
	PhysObj:ApplyForceOffset( vDirection * fForce,  self:GetElevatorPos() )
	PhysObj:ApplyForceOffset( vDirection * fForce,  self:GetWingPos() )
end

function ENT:ApplyThrust( PhysObj, vDirection, fForce )
	PhysObj:ApplyForceOffset( vDirection * fForce, self:GetRotorPos() )
end

function ENT:GetThrottleIncrement()
	self.RPMThrottleIncrement = isnumber( self.RPMThrottleIncrement ) and self.RPMThrottleIncrement or (self:IsSpaceShip() and 2000 or 350)
	
	return self.RPMThrottleIncrement
end

DEFINE_BASECLASS( "lvs_base" )

function ENT:OnDriverChanged( Old, New, VehicleIsActive )
	if not IsValid( new ) then return end

	self:AlignView( New )
end

function ENT:HandleActive()
	local gPod = self:GetGunnerSeat()

	if IsValid( gPod ) then
		local Gunner = gPod:GetDriver()

		if Gunner ~= self:GetGunner() then
			self:SetGunner( Gunner )
			self:AlignView( Gunner )
		end
	end

	local Time = CurTime()

	self.NextSetInertia = self.NextSetInertia or 0

	if self.NextSetInertia < Time then
		local inea = Active or self:GetEngineActive() or (self:GetStability() > 0.1) or not self:HitGround()
		local TargetInertia = inea and self.Inertia or self.LFSInertiaDefault

		self.NextSetInertia = Time + 1 -- !!!hack!!! reset every second. There are so many factors that could possibly break this like touching the planes with the physgun which sometimes causes ent:GetInertia() to return a wrong value?!?!
		
		local PObj = self:GetPhysicsObject()
		if IsValid( PObj ) then
			if PObj:IsMotionEnabled() then -- only set when unfrozen
				PObj:SetMass( self.Mass ) -- !!!hack!!!
				PObj:SetInertia( TargetInertia ) -- !!!hack!!!
			end
		end
	end

	BaseClass.HandleActive( self )
end

function ENT:InertiaSetNow()
	self.NextSetInertia = 0
end

function ENT:HandleStart()
	local Driver = self:GetDriver()
	
	if IsValid( Driver ) then
		local KeyReload = Driver:lfsGetInput( "ENGINE" )
		
		if self.OldKeyReload ~= KeyReload then
			self.OldKeyReload = KeyReload
			if KeyReload then
				self:ToggleEngine()
			end
		end
	end
end

function ENT:HandleLandingGear()
	local Driver = self:GetDriver()
	
	if IsValid( Driver ) then
		local KeyJump = Driver:lfsGetInput( "VSPEC" )
		
		if self.OldKeyJump ~= KeyJump then
			self.OldKeyJump = KeyJump
			if KeyJump then
				self:ToggleLandingGear()
				self:PhysWake()
			end
		end
	end
	
	local TValAuto = (self:GetStability() > 0.3) and 0 or 1
	local TValManual = self.LandingGearUp and 0 or 1
	
	local TVal = self.WheelAutoRetract and TValAuto or TValManual
	local Speed = FrameTime()
	local Speed2 = Speed * math.abs( math.cos( math.rad( self:GetLGear() * 180 ) ) )
	
	self:SetLGear( self:GetLGear() + math.Clamp(TVal - self:GetLGear(),-Speed,Speed) )
	self:SetRGear( self:GetRGear() + math.Clamp(TVal - self:GetRGear(),-Speed2,Speed2) )
	
	if IsValid( self.wheel_R ) then
		local RWpObj = self.wheel_R:GetPhysicsObject()
		if IsValid( RWpObj ) then
			RWpObj:SetMass( 1 + (self.WheelMass - 1) * self:GetRGear() ^ 5 )
		end
	end
	
	if IsValid( self.wheel_L ) then
		local LWpObj = self.wheel_L:GetPhysicsObject()
		if IsValid( LWpObj ) then
			LWpObj:SetMass( 1 + (self.WheelMass - 1) * self:GetLGear() ^ 5 )
		end
	end
	
	if IsValid( self.wheel_C ) then
		local CWpObj = self.wheel_C:GetPhysicsObject()
		if IsValid( CWpObj ) then
			CWpObj:SetMass( 1 + (self.WheelMass - 1) * self:GetRGear() )
		end
	end
end

function ENT:ToggleEngine()
	if self:GetEngineActive() then
		self:StopEngine()
	else
		self:StartEngine()
	end
end

function ENT:IsEngineStartAllowed()
	if hook.Run( "LVS.IsEngineStartAllowed", self ) == false then return false end

	local Driver = self:GetDriver()
	local Pod = self:GetDriverSeat()
	
	if self:GetAI() or not IsValid( Driver ) or not IsValid( Pod ) then return true end

	local EyeAngles = Pod:WorldToLocalAngles( Driver:EyeAngles() )
	local AimDirToForwardDir = math.deg( math.acos( math.Clamp( self:GetForward():Dot( EyeAngles:Forward() ) ,-1,1) ) )
	
	local CanStart = AimDirToForwardDir < 10
	
	if not CanStart then
		net.Start( "lfs_failstartnotify" )
		net.Send( Driver )
	end
	
	return CanStart
end

function ENT:StartEngine()
	if self:GetEngineActive() or self:IsDestroyed() or self:InWater() or not self:IsEngineStartAllowed() or self:GetRotorDestroyed() then return end
	
	self:SetEngineActive( true )
	self:OnEngineStarted()
	
	self:InertiaSetNow()
end

function ENT:StopEngine()
	if not self:GetEngineActive() then return end
	
	self:SetEngineActive( false )
	self:OnEngineStopped()
end

function ENT:ToggleLandingGear()
	self.LandingGearUp = not self.LandingGearUp
	
	self:OnLandingGearToggled( self.LandingGearUp )
end

function ENT:RaiseLandingGear()
	if not self.LandingGearUp then
		self.LandingGearUp = true
		
		self:OnLandingGearToggled( self.LandingGearUp )
	end
end

function ENT:DeployLandingGear()
	if self.LandingGearUp then
		self.LandingGearUp = false
		
		self:OnLandingGearToggled( self.LandingGearUp )
	end
end

function ENT:OnRemove()
end

function ENT:OnEngineStarted()
end

function ENT:OnEngineStopped()
end

function ENT:OnLandingGearToggled( bOn )
end

function ENT:GetWingVelocity()
	local PhysObj = self:GetPhysicsObject()

	if not IsValid( PhysObj ) then return vector_origin end

	local CurPos = self:GetWingPos()

	local Vel = PhysObj:GetVelocityAtPoint( CurPos )

	local VelForward = Vel:GetNormalized()

	local Up = self:GetWingUp()

	local Az = math.asin( math.Clamp( Up:Dot(VelForward) ,-1,1) )

	local Fz = math.sin( Az ) * Vel:Length()

	return Fz
end

function ENT:GetElevatorVelocity()
	local PhysObj = self:GetPhysicsObject()

	if not IsValid( PhysObj ) then return vector_origin end

	local CurPos = self:GetElevatorPos()

	local Vel = PhysObj:GetVelocityAtPoint( CurPos )
	local VelForward = Vel:GetNormalized()
	local Up = self:GetElevatorUp()

	local Az = math.asin( math.Clamp( Up:Dot(VelForward) ,-1,1) )
	local Fz = math.sin( Az ) * Vel:Length()

	return Fz
end

function ENT:GetRudderVelocity()
	local PhysObj = self:GetPhysicsObject()

	if not IsValid( PhysObj ) then return vector_origin end

	local CurPos = self:GetRudderPos()

	local Vel = PhysObj:GetVelocityAtPoint( CurPos )
	local VelForward = Vel:GetNormalized()
	local Up = self:GetRudderUp()

	local Az = math.asin( math.Clamp( Up:Dot(VelForward) ,-1,1) )
	local Fz = math.sin( Az ) * Vel:Length()

	return Fz
end

function ENT:InWater()
	local InWater = self:WaterLevel() > 2
	
	if InWater then
		self.nfwater = self.nfwater or 0
		
		if self.nfwater < CurTime() then
			self.nfwater = CurTime() + 0.02
			local PhysObj = self:GetPhysicsObject()
			if IsValid( PhysObj ) then
				PhysObj:ApplyForceCenter( -self:GetVelocity() * PhysObj:GetMass() * 0.1 )
			end
			self:ApplyAngForce( -self:GetAngVel() * PhysObj:GetMass() * 25 )
			
			if self:GetAI() then
				self:Destroy()
			end
			
			if self:GetEngineActive() then
				self:StopEngine()
			end
		end
	end
	
	return InWater
end

function ENT:GetStability()
	local Stability = math.abs( math.Clamp( self:GetForwardVelocity() / self:GetMaxPerfVelocity(),-self:GetMaxStability(),self:GetMaxStability() ) )

	if self:IsSpaceShip() then
		local TargetStability = self:IsDestroyed() and 0.1 or (self:GetEngineActive() and self.Stability or 0)

		self.smStablty = self.smStablty and self.smStablty + (TargetStability - self.smStablty) * FrameTime() or 0

		if TargetStability <= 0 then
			self.smStablty = 0
		end

		Stability = self.smStablty
	end

	return self:InWater() and 0 or Stability
end

function ENT:GetForwardVelocity()
	local Velocity = self:GetVelocity()
	local VelForward = Velocity:GetNormalized()

	local Forward = self:GetForward()
	
	local Ax = math.acos( math.Clamp( Forward:Dot(VelForward) ,-1,1) )

	local Fx = math.cos( Ax ) * Velocity:Length()
	
	return Fx
end

function ENT:InitWheels()
	if isnumber( self.WheelMass ) and isnumber( self.WheelRadius ) then
		if isvector( self.WheelPos_L ) then
			local wheel_L = ents.Create( "prop_physics" )
		
			if IsValid( wheel_L ) then
				wheel_L:SetPos( self:LocalToWorld( self.WheelPos_L ) )
				wheel_L:SetAngles( self:LocalToWorldAngles( Angle(0,90,0) ) )
				
				wheel_L:SetModel( "models/props_vehicles/tire001c_car.mdl" )
				wheel_L:Spawn()
				wheel_L:Activate()
				
				wheel_L:SetNoDraw( true )
				wheel_L:DrawShadow( false )
				wheel_L.DoNotDuplicate = true
				wheel_L:AddEFlags( EFL_NO_PHYSCANNON_INTERACTION )
				
				local radius = self.WheelRadius
				
				wheel_L:PhysicsInitSphere( radius, "jeeptire" )
				wheel_L:SetCollisionBounds( Vector(-radius,-radius,-radius), Vector(radius,radius,radius) )
				
				local LWpObj = wheel_L:GetPhysicsObject()
				if not IsValid( LWpObj ) then
					self:Remove()
					
					print("LFS: Failed to initialize landing gear phys model. Plane terminated.")
					return
				end
			
				LWpObj:EnableMotion(false)
				LWpObj:SetMass( self.WheelMass )
				
				self.wheel_L = wheel_L
				self:DeleteOnRemove( wheel_L )
				self:dOwner( wheel_L )
				
				self:dOwner( constraint.Axis( wheel_L, self, 0, 0, LWpObj:GetMassCenter(), wheel_L:GetPos(), 0, 0, 50, 0, Vector(1,0,0) , false ) )
				self:dOwner( constraint.NoCollide( wheel_L, self, 0, 0 ) )
				
				LWpObj:EnableMotion( true )
				LWpObj:EnableDrag( false ) 
				
			else
				self:Remove()
			
				print("LFS: Failed to initialize landing gear. Plane terminated.")
			end
		end
		
		if isvector( self.WheelPos_R ) then
			local wheel_R = ents.Create( "prop_physics" )
			
			if IsValid( wheel_R ) then
				wheel_R:SetPos( self:LocalToWorld(  self.WheelPos_R ) )
				wheel_R:SetAngles( self:LocalToWorldAngles( Angle(0,90,0) ) )
				
				wheel_R:SetModel( "models/props_vehicles/tire001c_car.mdl" )
				wheel_R:Spawn()
				wheel_R:Activate()
				
				wheel_R:SetNoDraw( true )
				wheel_R:DrawShadow( false )
				wheel_R.DoNotDuplicate = true
				wheel_R:AddEFlags( EFL_NO_PHYSCANNON_INTERACTION )
				
				local radius = self.WheelRadius
				
				wheel_R:PhysicsInitSphere( radius, "jeeptire" )
				wheel_R:SetCollisionBounds( Vector(-radius,-radius,-radius), Vector(radius,radius,radius) )
				
				local RWpObj = wheel_R:GetPhysicsObject()
				if not IsValid( RWpObj ) then
					self:Remove()
					
					print("LFS: Failed to initialize landing gear phys model. Plane terminated.")
					return
				end
			
				RWpObj:EnableMotion(false)
				RWpObj:SetMass( self.WheelMass )
				
				self.wheel_R = wheel_R
				self:DeleteOnRemove( wheel_R )
				self:dOwner( wheel_R )
				
				self:dOwner( constraint.Axis( wheel_R, self, 0, 0, RWpObj:GetMassCenter(), wheel_R:GetPos(), 0, 0, 50, 0, Vector(1,0,0) , false ) )
				self:dOwner( constraint.NoCollide( wheel_R, self, 0, 0 ) )
				
				RWpObj:EnableMotion( true )
				RWpObj:EnableDrag( false ) 
			else
				self:Remove()
			
				print("LFS: Failed to initialize landing gear. Plane terminated.")
			end
		end
		
		if isvector( self.WheelPos_C ) then
			local SteerMaster = ents.Create( "prop_physics" )
			
			if IsValid( SteerMaster ) then
				SteerMaster:SetModel( "models/hunter/plates/plate025x025.mdl" )
				SteerMaster:SetPos( self:GetPos() )
				SteerMaster:SetAngles( Angle(0,90,0) )
				SteerMaster:Spawn()
				SteerMaster:Activate()
				
				local smPObj = SteerMaster:GetPhysicsObject()
				if IsValid( smPObj ) then
					smPObj:EnableMotion( false )
				end
				
				SteerMaster:SetOwner( self )
				SteerMaster:DrawShadow( false )
				SteerMaster:SetNotSolid( true )
				SteerMaster:SetNoDraw( true )
				SteerMaster.DoNotDuplicate = true
				self:DeleteOnRemove( SteerMaster )
				self:dOwner( SteerMaster )
				
				self.wheel_C_master = SteerMaster
				
				local wheel_C = ents.Create( "prop_physics" )
				
				if IsValid( wheel_C ) then
					wheel_C:SetPos( self:LocalToWorld( self.WheelPos_C ) )
					wheel_C:SetAngles( Angle(0,0,0) )
					
					wheel_C:SetModel( "models/props_vehicles/tire001c_car.mdl" )
					wheel_C:Spawn()
					wheel_C:Activate()
					
					wheel_C:SetNoDraw( true )
					wheel_C:DrawShadow( false )
					wheel_C.DoNotDuplicate = true
					wheel_C:AddEFlags( EFL_NO_PHYSCANNON_INTERACTION )
					
					local radius = self.WheelRadius
					
					wheel_C:PhysicsInitSphere( radius, "jeeptire" )
					wheel_C:SetCollisionBounds( Vector(-radius,-radius,-radius), Vector(radius,radius,radius) )
					
					local CWpObj = wheel_C:GetPhysicsObject()
					if not IsValid( CWpObj ) then
						self:Remove()
						
						print("LFS: Failed to initialize landing gear phys model. Plane terminated.")
						return
					end
				
					CWpObj:EnableMotion(false)
					CWpObj:SetMass( self.WheelMass )
					
					self.wheel_C = wheel_C
					self:DeleteOnRemove( wheel_C )
					self:dOwner( wheel_C )
					
					self:dOwner( constraint.AdvBallsocket(wheel_C, SteerMaster,0,0,Vector(0,0,0),Vector(0,0,0),0,0, -180, -0.01, -0.01, 180, 0.01, 0.01, 0, 0, 0, 1, 0) )
					self:dOwner( constraint.AdvBallsocket(wheel_C,self,0,0,Vector(0,0,0),Vector(0,0,0),0,0, -180, -180, -180, 180, 180, 180, 0, 0, 0, 0, 0) )
					self:dOwner( constraint.NoCollide( wheel_C, self, 0, 0 ) )
					
					CWpObj:EnableMotion( true )
					CWpObj:EnableDrag( false ) 
				end
			end
		end
	end
end

function ENT:InitPod()
	local Pod = self:AddDriverSeat( self.SeatPos,  self.SeatAng )

	if self.HideDriver then
		Pod.HidePlayer = true
	end

	return Pod
end

function ENT:dOwner( eEnt )
	self:TransferCPPI( eEnt )
end

function ENT:PrepExplode()
end

function ENT:ApplyAngForce( angForce )
	if self:IsDestroyed() then return end

	local phys = self:GetPhysicsObject()

	if not IsValid( phys ) then return end
	
	local up = self:GetUp()
	local left = self:GetRight() * -1
	local forward = self:GetForward()

	local pitch = up * (angForce.p * 0.5)
	phys:ApplyForceOffset( forward, pitch )
	phys:ApplyForceOffset( forward * -1, pitch * -1 )

	local yaw = forward * (angForce.y * 0.5)
	phys:ApplyForceOffset( left, yaw )
	phys:ApplyForceOffset( left * -1, yaw * -1 )

	local roll = left * (angForce.r * 0.5)
	phys:ApplyForceOffset( up, roll )
	phys:ApplyForceOffset( up * -1, roll * -1 )
end

function ENT:GetAngVel()
	local phys = self:GetPhysicsObject()
	if not IsValid( phys ) then return Angle(0,0,0) end
	
	local vec = phys:GetAngleVelocity()
	
	return Angle( vec.y, vec.z, vec.x )
end

function ENT:Destroy()
	self.Destroyed = true

	local PObj = self:GetPhysicsObject()
	if IsValid( PObj ) then
		PObj:SetDragCoefficient( -20 )
	end
end

function ENT:DisableWep( bEnabled )
	self.lfsWepDisabled = bEnabled
end

function ENT:GetWepEnabled()
	return not self.lfsWepDisabled
end

function ENT:CanSee( otherEnt )
	if not IsValid( otherEnt ) then return false end
	return util.TraceHull( { start = self:GetRotorPos(), filter = {self,self.wheel_L,self.wheel_R,self.wheel_C}, endpos = otherEnt:GetPos(), mins = Vector( -10, -10, -10 ),maxs = Vector( 10, 10, 10 ) } ).Entity == otherEnt
end

function ENT:AIGetNPCRelationship( npc_class )
	return LVS:GetNPCRelationship( npc_class )
end

function ENT:AIGetNPCTargets()
	return LVS:GetNPCs()
end

function ENT:RunAI()
	local RangerLength = 15000

	local mySpeed = self:GetVelocity():Length()
	local myRadius = self:BoundingRadius() 
	local myPos = self:GetPos()
	local myDir = self:GetForward()

	local MinDist = 600 + mySpeed * 2

	local StartPos = self:LocalToWorld( self:OBBCenter() )

	local TraceFilter = self:GetCrosshairFilterEnts()

	local FrontLeft = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,20,0) ):Forward() * RangerLength } )
	local FrontRight = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(0,-20,0) ):Forward() * RangerLength } )

	local FrontLeft2 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(25,65,0) ):Forward() * RangerLength } )
	local FrontRight2 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(25,-65,0) ):Forward() * RangerLength } )

	local FrontLeft3 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(-25,65,0) ):Forward() * RangerLength } )
	local FrontRight3 = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(-25,-65,0) ):Forward() * RangerLength } )

	local FrontUp = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(-20,0,0) ):Forward() * RangerLength } )
	local FrontDown = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:LocalToWorldAngles( Angle(20,0,0) ):Forward() * RangerLength } )

	local Up = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos + self:GetUp() * RangerLength } )
	local Down = util.TraceLine( { start = StartPos, filter = TraceFilter, endpos = StartPos - self:GetUp() * RangerLength } )

	local Down2 = util.TraceLine( { start = self:LocalToWorld( Vector(0,0,100) ), filter = TraceFilter, endpos = StartPos + Vector(0,0,-RangerLength) } )

	local cAvoid = Vector(0,0,0)

	for _, v in pairs( LVS:GetVehicles() ) do
		if v == self then continue end

		local theirRadius = v:BoundingRadius() 
		local Sub = (myPos - v:GetPos())
		local Dir = Sub:GetNormalized()
		local Dist = Sub:Length()
		
		if Dist < (theirRadius + myRadius + 200) then
			if math.deg( math.acos( math.Clamp( myDir:Dot( -Dir ) ,-1,1) ) ) < 90 then
				cAvoid = cAvoid + Dir * (theirRadius + myRadius + 500)
			end
		end
	end

	local FLp = FrontLeft.HitPos + FrontLeft.HitNormal * MinDist + cAvoid * 8
	local FRp = FrontRight.HitPos + FrontRight.HitNormal * MinDist + cAvoid * 8

	local FL2p = FrontLeft2.HitPos + FrontLeft2.HitNormal * MinDist
	local FR2p = FrontRight2.HitPos + FrontRight2.HitNormal * MinDist

	local FL3p = FrontLeft3.HitPos + FrontLeft3.HitNormal * MinDist
	local FR3p = FrontRight3.HitPos + FrontRight3.HitNormal * MinDist

	local FUp = FrontUp.HitPos + FrontUp.HitNormal * MinDist
	local FDp = FrontDown.HitPos + FrontDown.HitNormal * MinDist

	local Up = Up.HitPos + Up.HitNormal * MinDist
	local Dp = Down.HitPos + Down.HitNormal * MinDist

	local TargetPos = (FLp+FRp+FL2p+FR2p+FL3p+FR3p+FUp+FDp+Up+Dp) / 10

	self._AIFireInput = false

	local alt = (self:GetPos() - Down2.HitPos):Length()

	if alt < MinDist then 
		self.TargetRPM = self:GetMaxRPM()
		
		if self:GetStability() < 0.4 then
			self.TargetRPM = self:GetLimitRPM()
			TargetPos.z = self:GetPos().z + 2000
		end
		
		if self.LandingGearUp and mySpeed < 100 and not self:IsPlayerHolding() then
			local pObj = self:GetPhysicsObject()
			if IsValid( pObj ) then
				if pObj:IsMotionEnabled() then
					self:Explode()
				end
			end
		end
	else
		if self:GetStability() < 0.3 then
			self.TargetRPM = self:GetLimitRPM()
			TargetPos.z = self:GetPos().z + 600
		else
			if alt > mySpeed then
				local Target = self:AIGetTarget()
				if IsValid( Target ) then
					if self:AITargetInFront( Target, 65 ) then
						TargetPos = Target:GetPos() + cAvoid * 8 + Target:GetVelocity() * math.abs(math.cos( CurTime() * 150 ) ) * 3

						local Throttle = (self:GetPos() - TargetPos):Length() / 8000 * self:GetMaxRPM()
						self.TargetRPM = math.Clamp( Throttle,self:GetIdleRPM(),self:GetMaxRPM())
	
						local startpos =  self:GetRotorPos()
						local tr = util.TraceHull( {
							start = startpos,
							endpos = (startpos + self:GetForward() * 50000),
							mins = Vector( -50, -50, -50 ),
							maxs = Vector( 50, 50, 50 ),
							filter = TraceFilter
						} )

						local CanShoot = (IsValid( tr.Entity ) and tr.Entity.LVS and tr.Entity.GetAITEAM) and (tr.Entity:GetAITEAM() ~= self:GetAITEAM() or tr.Entity:GetAITEAM() == 0) or true
					
						if CanShoot then
							self._AIFireInput = true

							if self:AITargetInFront( Target, 15 ) then
								self:HandleWeapons( true )
								
								if self:AITargetInFront( Target, 10 ) then
									self:HandleWeapons( true, true )
								end
							end
						end
					else
						if alt > 6000 and self:AITargetInFront( Target, 90 ) then
							TargetPos = Target:GetPos()
						else
							TargetPos = TargetPos
						end
						
						self.TargetRPM = self:GetMaxRPM()
					end
				else
					self.TargetRPM = self:GetMaxRPM()
				end
			else
				self.TargetRPM = self:GetMaxRPM()
				TargetPos.z = self:GetPos().z + 2000
			end
		end
		self:RaiseLandingGear()
	end

	if self:IsDestroyed() or not self:GetEngineActive() then
		self.TargetRPM = 0
	end

	self.smTargetPos = self.smTargetPos and self.smTargetPos + (TargetPos - self.smTargetPos) * FrameTime() or self:GetPos()

	self._lvsAITargetAng = (self.smTargetPos - self:GetPos()):GetNormalized():Angle()

	return self._lvsAITargetAng
end

function ENT:CreateAI()
end

function ENT:RemoveAI()
end

function ENT:OnCreateAI()
	self:CreateAI()

	self:StartEngine()
	self.COL_GROUP_OLD = self:GetCollisionGroup()
	self:SetCollisionGroup( COLLISION_GROUP_INTERACTIVE_DEBRIS )
end

function ENT:OnRemoveAI()
	self:RemoveAI()

	self:StopEngine()
	self:SetCollisionGroup( self.COL_GROUP_OLD or COLLISION_GROUP_NONE )
end

function ENT:OnSkyCollide( data, PhysObj )

	local NewVelocity = self:VectorSubtractNormal( data.HitNormal, data.OurOldVelocity ) - data.HitNormal * 250

	PhysObj:SetVelocityInstantaneous( NewVelocity )
	PhysObj:SetAngleVelocityInstantaneous( data.OurOldAngularVelocity )

	return true
end

function ENT:AITargetInfront( ent, range )
	return self:AITargetInFront( ent, range )
end

function ENT:CanRechargeShield()
	return self:CanShieldRecharge()
end

function ENT:SetNextShieldRecharge( nDelay )
	if not isnumber( nDelay ) then return end
	
	self:DelayNextShieldRecharge( nDelay )
end

DEFINE_BASECLASS( "lvs_base" )

function ENT:SetDestroyed( SuppressOnDestroy )
	BaseClass.SetDestroyed( self, SuppressOnDestroy )

	self:Destroy()
end

function ENT:WeaponRestoreAmmo()
	self:ReloadWeapon()

	BaseClass.WeaponRestoreAmmo( self )
end

-- keep this to prevent lua errors
function ENT:OnStartMaintenance()
end

function ENT:OnStopMaintenance()
end

function ENT:StartMaintenance()
	self:OnStartMaintenance()
end

function ENT:StopMaintenance()
	self:OnStopMaintenance()
end
