AddCSLuaFile()

ENT.Type = "anim"
ENT.PrintName = "Shipment"
ENT.Category = "Lilia"
ENT.Spawnable = false

if (SERVER) then
	function ENT:Initialize()
		self:SetModel("models/Items/item_item_crate.mdl")
		self:SetSolid(SOLID_VPHYSICS)
		self:PhysicsInit(SOLID_VPHYSICS)
		self:SetUseType(SIMPLE_USE)
		self:PrecacheGibs()

		local physObj = self:GetPhysicsObject()

		if (IsValid(physObj)) then
			physObj:EnableMotion(true)
			physObj:Wake()
		end

		self:setNetVar("delTime", CurTime() + 120)

		timer.Simple(120, function()
			if (IsValid(self)) then
				self:Remove()
			end
		end)
	end

	function ENT:Use(activator)
		if (activator:getChar() and activator:getChar():getID() == self:getNetVar("owner", 0) and hook.Run("PlayerCanOpenShipment", activator, self) ~= false) then
			activator.liaShipment = self
			netstream.Start(activator, "openShp", self, self.items)
		end
	end

	function ENT:setItems(items)
		self.items = items
	end

	function ENT:getItemCount()
		local count = 0

		for k, v in pairs(self.items) do
			count = count + math.max(v, 0)
		end

		return count
	end

	function ENT:OnRemove()
		self:EmitSound("physics/cardboard/cardboard_box_break"..math.random(1, 3)..".wav")

		local position = self:LocalToWorld(self:OBBCenter())

		local effect = EffectData()
			effect:SetStart(position)
			effect:SetOrigin(position)
			effect:SetScale(3)
		util.Effect("GlassImpact", effect)
	end
else
	ENT.DrawEntityInfo = true

	local toScreen = FindMetaTable("Vector").ToScreen
	local colorAlpha = ColorAlpha
	local drawText = lia.util.drawText

	local size = 150
	local tempMat = Material("particle/warp1_warp", "alphatest")
	function ENT:Draw()
		local pos, ang = self:GetPos(), self:GetAngles()

		self:DrawModel()

		pos = pos + self:GetUp()*25
		pos = pos + self:GetForward()*1
		pos = pos + self:GetRight()*3

		local delTime = math.max(math.ceil(self:getNetVar("delTime", 0) - CurTime()), 0)

		local func = function() 
			surface.SetMaterial(tempMat)
			surface.SetDrawColor(0, 0, 0, 200)
			surface.DrawTexturedRect(-size/2, -size/2 - 10, size, size)

			lia.util.drawText("k", 0, 0, color_white, 1, 4, "liaIconsBig")
			lia.util.drawText(delTime, 0, -10, color_white, 1, 5, "liaBigFont")
		end

		cam.Start3D2D(pos, ang, .15)
			func()
		cam.End3D2D()

		ang:RotateAroundAxis(ang:Right(), 180)
		pos = pos - self:GetUp()*26

		cam.Start3D2D(pos, ang, .15)
			func()
		cam.End3D2D()
	end

	function ENT:onDrawEntityInfo(alpha)
		local position = toScreen(self.LocalToWorld(self, self.OBBCenter(self)))
		local x, y = position.x, position.y
		local owner = lia.char.loaded[self.getNetVar(self, "owner", 0)]

		drawText(L"shipment", x, y, colorAlpha(lia.config.get("color"), alpha), 1, 1, nil, alpha * 0.65)

		if (owner) then
			drawText(L("shipmentDesc", owner.getName(owner)), x, y + 16, colorAlpha(color_white, alpha), 1, 1, "liaSmallFont", alpha * 0.65)
		end
	end
end