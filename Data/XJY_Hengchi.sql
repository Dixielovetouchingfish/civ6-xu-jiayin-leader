-- Stage 1E: Hengchi Vehicle
-- A leader-exclusive Modern Armor replacement for Xu Jiayin.

INSERT INTO Types
(
    Type,
    Kind
)
VALUES
    ('UNIT_XJY_HENGCHI', 'KIND_UNIT'),
    ('ABILITY_XJY_DOMESTIC_SUPPLY_CHAIN', 'KIND_ABILITY');

INSERT INTO Tags
(
    Tag,
    Vocabulary
)
VALUES
    ('CLASS_XJY_HENGCHI', 'ABILITY_CLASS');

INSERT INTO TypeTags
(
    Type,
    Tag
)
VALUES
    ('UNIT_XJY_HENGCHI', 'CLASS_HEAVY_CHARIOT'),
    ('UNIT_XJY_HENGCHI', 'CLASS_HEAVY_CAVALRY'),
    ('UNIT_XJY_HENGCHI', 'CLASS_XJY_HENGCHI'),
    ('ABILITY_XJY_DOMESTIC_SUPPLY_CHAIN', 'CLASS_XJY_HENGCHI');

INSERT INTO Units
(
    UnitType,
    Name,
    Description,
    BaseMoves,
    BaseSightRange,
    ZoneOfControl,
    Domain,
    Combat,
    RangedCombat,
    Range,
    Bombard,
    Cost,
    PopulationCost,
    FoundCity,
    BuildCharges,
    CanCapture,
    CanTargetAir,
    AntiAirCombat,
    CanEarnExperience,
    CanTrain,
    AdvisorType,
    Maintenance,
    PurchaseYield,
    PrereqTech,
    StrategicResource,
    PromotionClass,
    FormationClass,
    TraitType
)
VALUES
(
    'UNIT_XJY_HENGCHI',
    'LOC_UNIT_XJY_HENGCHI_NAME',
    'LOC_UNIT_XJY_HENGCHI_DESCRIPTION',
    5,
    2,
    1,
    'DOMAIN_LAND',
    90,
    0,
    0,
    0,
    580,
    NULL,
    0,
    0,
    1,
    0,
    0,
    1,
    1,
    'ADVISOR_CONQUEST',
    8,
    'YIELD_GOLD',
    'TECH_COMPOSITES',
    'RESOURCE_OIL',
    'PROMOTION_CLASS_HEAVY_CAVALRY',
    'FORMATION_CLASS_LAND_COMBAT',
    'TRAIT_LEADER_XJY_UNIQUE_CONTENT'
);

INSERT INTO Units_XP2
(
    UnitType,
    ResourceMaintenanceAmount,
    ResourceCost,
    ResourceMaintenanceType,
    CanEarnExperience,
    CanFormMilitaryFormation
)
VALUES
(
    'UNIT_XJY_HENGCHI',
    1,
    1,
    'RESOURCE_OIL',
    1,
    1
);

INSERT INTO UnitAiInfos
(
    UnitType,
    AiType
)
VALUES
    ('UNIT_XJY_HENGCHI', 'UNITAI_COMBAT'),
    ('UNIT_XJY_HENGCHI', 'UNITTYPE_MELEE'),
    ('UNIT_XJY_HENGCHI', 'UNITAI_EXPLORE'),
    ('UNIT_XJY_HENGCHI', 'UNITTYPE_CAVALRY'),
    ('UNIT_XJY_HENGCHI', 'UNITTYPE_LAND_COMBAT');

INSERT INTO UnitReplaces
(
    CivUniqueUnitType,
    ReplacesUnitType
)
VALUES
(
    'UNIT_XJY_HENGCHI',
    'UNIT_MODERN_ARMOR'
);

INSERT INTO UnitAbilities
(
    UnitAbilityType,
    Name,
    Description,
    Inactive,
    ShowFloatTextWhenEarned,
    Permanent
)
VALUES
(
    'ABILITY_XJY_DOMESTIC_SUPPLY_CHAIN',
    'LOC_ABILITY_XJY_DOMESTIC_SUPPLY_CHAIN_NAME',
    'LOC_ABILITY_XJY_DOMESTIC_SUPPLY_CHAIN_DESCRIPTION',
    0,
    0,
    0
);

INSERT INTO UnitAbilityModifiers
(
    UnitAbilityType,
    ModifierId
)
VALUES
(
    'ABILITY_XJY_DOMESTIC_SUPPLY_CHAIN',
    'MODIFIER_XJY_HENGCHI_OWN_TERRITORY_COMBAT'
);

INSERT INTO Requirements
(
    RequirementId,
    RequirementType
)
VALUES
(
    'REQUIREMENT_XJY_HENGCHI_IN_OWNER_TERRITORY',
    'REQUIREMENT_UNIT_IN_OWNER_TERRITORY'
);

INSERT INTO RequirementSets
(
    RequirementSetId,
    RequirementSetType
)
VALUES
(
    'REQUIREMENTSET_XJY_HENGCHI_IN_OWN_TERRITORY',
    'REQUIREMENTSET_TEST_ALL'
);

INSERT INTO RequirementSetRequirements
(
    RequirementSetId,
    RequirementId
)
VALUES
(
    'REQUIREMENTSET_XJY_HENGCHI_IN_OWN_TERRITORY',
    'REQUIREMENT_XJY_HENGCHI_IN_OWNER_TERRITORY'
);

INSERT INTO Modifiers
(
    ModifierId,
    ModifierType,
    SubjectRequirementSetId
)
VALUES
(
    'MODIFIER_XJY_HENGCHI_OWN_TERRITORY_COMBAT',
    'MODIFIER_UNIT_ADJUST_COMBAT_STRENGTH',
    'REQUIREMENTSET_XJY_HENGCHI_IN_OWN_TERRITORY'
);

INSERT INTO ModifierArguments
(
    ModifierId,
    Name,
    Value
)
VALUES
(
    'MODIFIER_XJY_HENGCHI_OWN_TERRITORY_COMBAT',
    'Amount',
    10
);

INSERT INTO ModifierStrings
(
    ModifierId,
    Context,
    Text
)
VALUES
(
    'MODIFIER_XJY_HENGCHI_OWN_TERRITORY_COMBAT',
    'Preview',
    'LOC_ABILITY_XJY_DOMESTIC_SUPPLY_CHAIN_COMBAT_PREVIEW'
);
