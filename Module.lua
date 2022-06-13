---@author West#9009
---@description Persistence module for dynamic missions.
---@created 11JUN22

---@type BASE
PERSIST = {
    ClassName = 'PERSIST',
    Schedule = 60,
    Path = [[Persist\States\]],
    IgnoredGroups = {}
}

--function GROUP:SetSave(IsSave)
--    if not type(IsSave) == 'boolean' then return nil end
--
--    self.Save = IsSave
--
--    return self
--end
--
--function GROUP:IsSave()
--    if self.save == nil then return true end
--
--    return self.Save
--end

function PERSIST:New()
    local self = BASE:Inherit(self, BASE:New())

    self.Skill = 'Average'
    self.CanDrive = true

    return self
end

function PERSIST:SetSchedule(Seconds)
    if not type(Seconds) == 'number' then return end

    self.Schedule = Seconds

    return self
end

function PERSIST:SetSkill(Skill)
    self.Skill = Skill

    return self
end

function PERSIST:SetCanDrive(CanDrive)
    if not type(CanDrive) == 'boolean' then return end

    self.CanDrive = CanDrive

    return self
end

function PERSIST:SetPath(Path)
    self.Path = Path

    return self
end

function PERSIST:_LoadState()
    _MSF:Load(self.Path .. 'GROUPS', 'Optional')

    if not GROUPS then GROUPS = {} end

    return self
end

function PERSIST:_SaveState()
    if GROUPS then
        ROUTINES.file.EDSerializeToFile(_MSF.OptionalDirectory .. self.Path, 'GROUPS', GROUPS)
    end

    return self
end

function PERSIST:_UpdateState()
    GROUPS = {}

    self:GetSet():

    ForEach(function(Group)
        --if not Group:IsSave() then return end

        local Name = Group:GetName()
        local Units = Group:GetUnits()

        GROUPS[Name] = {}

        if Units then
            for _, Unit in pairs(Units) do
                local UnitState = {
                    Name = Unit:GetName(),
                    Vec3 = Unit:GetVec3(),
                    Type = Unit:GetType(),
                    Heading = math.rad(Unit:GetHeading()),
                    Country = Unit:GetCountry()
                }

                table.insert(GROUPS[Name], UnitState)
            end
        end
    end)

    self:_SaveState()
end

function PERSIST:GetSet()
    return SET:CreateFrom('Groups'):FilterCategory(Group.Category.GROUND)
end

function PERSIST:_RemoveGroups()
    local GroupSet = self:GetSet()

    GroupSet:

    ForEach(function(Group)
        --if not Group:IsSave() then return end

        Group:Destroy()
    end)

    return self
end

function PERSIST:_SpawnGroups()
    if not GROUPS then return end

    for GroupName, Units in pairs(GROUPS) do
        local Country = Units[1].Country
        local Spawn = SPAWN:NewEmptyGroundGroup(GroupName, Country)

        for _, Unit in ipairs(Units) do
            Spawn:
            AddUnit(Unit.Type, Unit.Name, self.Skill, Unit.Heading, self.CanDrive, { x = Unit.Vec3.x, y = Unit.Vec3.z })
        end

        Spawn:_SpawnGroup()
    end

    return self
end

function PERSIST:Start()
    self:_LoadState()

    if ROUTINES.util.size(GROUPS) ~= 0 then
        self:_RemoveGroups()
        self:_SpawnGroups()
    end

    self.ScheduleId = self:ScheduleRepeat(self.Schedule, self._UpdateState, self)
end

function PERSIST:Stop()
    if not self.ScheduleId then return end

    self:ScheduleStop(self.ScheduleId)

    return self
end

PERSIST = PERSIST:New()
