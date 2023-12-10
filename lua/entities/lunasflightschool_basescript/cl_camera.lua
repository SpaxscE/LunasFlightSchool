
function ENT:LVSCalcView( ply, pos, angles, fov, pod )
	return self:CalcViewMouseAim( ply, pos, angles, fov, pod )
end

function ENT:LFSCalcViewFirstPerson( view, ply )
	return view
end

function ENT:LFSCalcViewThirdPerson( view, ply )
	return view
end

local smTran = 0
function ENT:CalcViewMouseAim( ply, pos, angles, fov, pod )
	local cvarFocus = math.Clamp( LVS.cvarCamFocus:GetFloat() , -1, 1 )

	smTran = smTran + ((ply:lfsGetInput( "FREELOOK" ) and 0 or 1) - smTran) * FrameTime() * 10

	self.ZoomFov = fov

	local view = {}
	view.origin = pos
	view.fov = fov
	view.drawviewer = true
	view.angles = (self:GetForward() * (1 + cvarFocus) * smTran * 0.8 + ply:EyeAngles():Forward() * math.max(1 - cvarFocus, 1 - smTran)):Angle()

	if cvarFocus >= 1 then
		view.angles = LerpAngle( smTran, ply:EyeAngles(), self:GetAngles() )
	else
		view.angles.r = 0
	end

	if self:GetDriverSeat() ~= pod then
		view.angles = ply:EyeAngles()
	end
	
	if not pod:GetThirdPersonMode() then
		
		view.drawviewer = false
		
		return self:LFSCalcViewFirstPerson( view, ply )
	end
	
	local radius = 550
	radius = radius + radius * pod:GetCameraDistance()
	
	local TargetOrigin = view.origin - view.angles:Forward() * radius  + view.angles:Up() * radius * 0.2
	local WallOffset = 4

	local tr = util.TraceHull( {
		start = view.origin,
		endpos = TargetOrigin,
		filter = function( e )
			local c = e:GetClass()
			local collide = not c:StartWith( "prop_physics" ) and not c:StartWith( "prop_dynamic" ) and not c:StartWith( "prop_ragdoll" ) and not e:IsVehicle() and not c:StartWith( "gmod_" ) and not c:StartWith( "lvs_" ) and not c:StartWith( "player" ) and not e.LVS

			return collide
		end,
		mins = Vector( -WallOffset, -WallOffset, -WallOffset ),
		maxs = Vector( WallOffset, WallOffset, WallOffset ),
	} )
	
	view.origin = tr.HitPos
	
	if tr.Hit and not tr.StartSolid then
		view.origin = view.origin + tr.HitNormal * WallOffset
	end

	return self:LFSCalcViewThirdPerson( view, ply )
end
