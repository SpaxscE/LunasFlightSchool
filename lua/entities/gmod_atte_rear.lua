AddCSLuaFile()

ENT.Type            = "anim"

if SERVER then
	function ENT:Initialize()	
		self:SetModel( "models/blu/atte_rear.mdl" )
		self:PhysicsInit( SOLID_VPHYSICS )
		self:SetMoveType( MOVETYPE_VPHYSICS )
		self:SetSolid( SOLID_VPHYSICS )
		self:SetUseType( SIMPLE_USE )
		self:AddFlags( FL_OBJECT ) -- this allows npcs to see this entity
	end

	function ENT:Use( ply )
		if not IsValid( self.ATTEBaseEnt ) or not IsValid( ply ) then return end

		self.ATTEBaseEnt:Use( ply )
	end

	function ENT:Think()
		self:NextThink( CurTime() )
		return true
	end

	function ENT:OnTakeDamage( dmginfo )
		self:TakePhysicsDamage( dmginfo )
		
		if IsValid( self.ATTEBaseEnt ) then
			self.ATTEBaseEnt:TakeDamageInfo( dmginfo ) 
		end
	end
else 
	include("entities/lunasflightschool_atte/cl_ikfunctions.lua")

	function ENT:OnRemoveAdd() -- since ENT:OnRemove() is used by the IK script we need to do our stuff here
	end

	function ENT:Draw()
		self:DrawModel()
	end
	
	function ENT:Think()
	end
end