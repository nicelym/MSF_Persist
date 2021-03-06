---@author West#9009
---@description Persistence module for dynamic missions.
---@created 11JUN22

---@type BASE
PERSIST = {
    ClassName = 'PERSIST',
    Schedule = 60,
    Path = [[Persist\States\]],
    IgnoredGroups = {},
    Skill = 'Average',
    CanDrive = true
}

--- Ignore a group from state tracking.
---@return self
function PERSIST:IgnoreGroup(Group)
    if not Group.GetClassName then return end
    if not Group:GetClassName() == 'GROUP' then return end

    self.IgnoredGroups[Group:GetName()] = true

    return self
end

--- Track a group that was previously ignored.
---@return self
function PERSIST:TrackGroup(Group)
    if not Group.GetClassName then return end
    if not Group:GetClassName() == 'GROUP' then return end

    self.IgnoredGroups[Group:GetName()] = nil

    return self
end

--- Instantiate a new PERSIST object.
---@return self
function PERSIST:New()
    local self = BASE:Inherit(self, BASE:New())

    return self
end

--- Set the rate in seconds that the state is saved.
---@return self
function PERSIST:SetSchedule(Seconds)
    if not type(Seconds) == 'number' then return end

    self.Schedule = Seconds

    return self
end

--- Set skill of units.
---@return self
function PERSIST:SetSkill(Skill)
    self.Skill = Skill

    return self
end

--- Set if players can drive units or not.
---@return self
function PERSIST:SetCanDrive(CanDrive)
    if not type(CanDrive) == 'boolean' then return end

    self.CanDrive = CanDrive

    return self
end

--- Set the path for state saving.
---@return self
function PERSIST:SetPath(Path)
    self.Path = Path

    return self
end

--- Load the state from file.
---@return self
function PERSIST:_LoadState()
    _MSF:Load(self.Path .. 'GROUPS', 'Optional')

    return self
end

--- Save the state to file.
---@return self
function PERSIST:_SaveState()
    if GROUPS then
        ROUTINES.file.EDSerializeToFile(_MSF.OptionalDirectory .. self.Path, 'GROUPS', GROUPS)
    end

    return self
end

--- Update the state from group set and save.
---@return
function PERSIST:_UpdateState()
    GROUPS = {}

    self:GetSet():

    ForEach(function(Group)
        local Name = Group:GetName()

        if self.IgnoredGroups[Name] then return end

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

    return self
end

--- Get a ground unit Set.
---@return SET
function PERSIST:GetSet()
    return SET:CreateFrom('Groups'):FilterCategory(Group.Category.GROUND)
end

--- Remove all groups from mission.
---@return self
function PERSIST:_RemoveGroups()
    local GroupSet = self:GetSet()

    GroupSet:

    ForEach(function(Group)
        if self.IgnoredGroups[Group:GetName()] then return end

        Group:Destroy()
    end)

    return self
end

--- Generate the new groups from GROUPS and spawn.
---@return self
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

--- Start the Persist module
---@return self
function PERSIST:Start()
    self:_LoadState()

    if GROUPS then
        self:_RemoveGroups()
        self:_SpawnGroups()
    end

    self.ScheduleId = self:ScheduleRepeat(self.Schedule, self._UpdateState, self)

    return self
end

--- Stop the Persist module.
---@return self
function PERSIST:Stop()
    if not self.ScheduleId then return end

    self:ScheduleStop(self.ScheduleId)

    return self
end

PERSIST = PERSIST:New()
