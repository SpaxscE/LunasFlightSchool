include("shared.lua")
include("cl_camera.lua")
include("cl_hud.lua")
include("sh_camera_eyetrace.lua")

function ENT:Think()
	self:AnimCabin()
	self:AnimLandingGear()
	self:AnimRotor()
	self:AnimFins()
	
	self:CheckEngineState()
	
	self:ExhaustFX()
	self:DamageFX()

	if not self:IsInitialized() then return end
 
	if self:HandleActive() then
		self:OnFrameActive()
	end

	self:HandleTrail()
	self:OnFrame()
end

function ENT:DamageFX()
	local HP = self:GetHP()
	if HP <= 0 or HP > self:GetMaxHP() * 0.5 then return end
	
	self.nextDFX = self.nextDFX or 0
	
	if self.nextDFX < CurTime() then
		self.nextDFX = CurTime() + 0.05
		
		local effectdata = EffectData()
			effectdata:SetOrigin( self:GetRotorPos() - self:GetForward() * 50 )
		util.Effect( "lfs_blacksmoke", effectdata )
	end
end

function ENT:ExhaustFX()
end

function ENT:CalcEngineSound( RPM, Pitch, Doppler )
end

function ENT:EngineActiveChanged( bActive )
end

function ENT:OnRemove()
	self:StopEmitter()
	self:StopWindSounds()
	self:StopFlyBy()
	self:StopDeathSound()

	self:OnRemoved()

	self:SoundStop()
end

function ENT:SoundStop()
end

function ENT:HandlePropellerSND( Pitch, RPM, LoadStart, AddStart, RPMAdd, RPMSub )
	AddStart = AddStart or 0.8
	RPMAdd = RPMAdd or 0.25
	RPMSub = RPMSub or 0.4
	LoadStart =  LoadStart or 0.6

	local MaxRPM = self:GetLimitRPM()
	local PropFade = (RPM / MaxRPM) ^ 5
	local Vel = self:GetVelocity():Length()
	local MaxVel = self:GetMaxVelocity()

	local Add = math.min( math.max(Vel - MaxVel * AddStart,0) / 300, 1 )
	local Load = math.max( math.min(Vel, (MaxVel-Vel) / (MaxVel - MaxVel * LoadStart),1), 0) ^ 2

	if self.PROPELLER_A then
		self.PROPELLER_A:ChangeVolume( Load * PropFade )
	end

	if self.PROPELLER_B then
		self.PROPELLER_B:ChangeVolume( Add  * PropFade )
	end

	return Pitch
end

function ENT:RemovePropellerSND()
	if self.PROPELLER_A then
		self.PROPELLER_A:Stop()
	end
	if self.PROPELLER_B then
		self.PROPELLER_B:Stop()
	end
end

function ENT:AddPropellerSND( Pitch )
	Pitch = Pitch or 100

	self.PROPELLER_A = CreateSound( self, "LFS_PROPELLER" )
	self.PROPELLER_A:PlayEx(0,Pitch)

	self.PROPELLER_B = CreateSound( self, "LFS_PROPELLER_STRAIN" )
	self.PROPELLER_B:PlayEx(0,Pitch)
end

function ENT:CheckEngineState()
	local Active = self:GetEngineActive()
	
	if Active then
		local RPM = self:GetRPM()
		local LimitRPM = self:GetLimitRPM()

		local ply = LocalPlayer()
		local Time = CurTime()

		if (self.NextSound_flyby or 0) < Time then
			self.NextSound_flyby = Time + 0.1

			local Vel = self:GetVelocity()

			local ToPlayer = (ply:GetPos() - self:GetPos()):GetNormalized()
			local VelDir = Vel:GetNormalized()

			local Approaching = math.deg( math.acos( math.Clamp( ToPlayer:Dot( VelDir ) ,-1,1) ) ) < 80

			if Approaching ~= self.OldApproaching then
				self.OldApproaching = Approaching

				if not Approaching then
					if Vel:Length() > self:GetMaxVelocity() * 0.6 and self:GetThrottlePercent() > 50 then
						if ply:lvsGetVehicle() ~= self then
							local Dist = (ply:GetPos() - self:GetPos()):Length()

							if Dist < 3000 then
								self:PlayFlybySND()
							end
						end
					end
				end
			end
		end

		local tPer = RPM / LimitRPM

		local CurDist = (ply:GetViewEntity():GetPos() - self:GetPos()):Length()
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

function ENT:PlayFlybySND()
end

function ENT:AnimFins()
end

function ENT:AnimRotor()
end

function ENT:AnimCabin()
end

function ENT:AnimLandingGear()
end
