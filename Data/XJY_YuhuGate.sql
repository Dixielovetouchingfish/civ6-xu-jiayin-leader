-- Stage 1F: Evergrande Yuhu Gate.
-- Technical form: leader-unique City Center building, one instance per player.

INSERT INTO Types
(
    Type,
    Kind
)
VALUES
(
    'BUILDING_XJY_YUHU_GATE',
    'KIND_BUILDING'
);

INSERT INTO Buildings
(
    BuildingType,
    Name,
    Description,
    PrereqCivic,
    Cost,
    MaxPlayerInstances,
    PrereqDistrict,
    RequiresPlacement,
    Housing,
    Entertainment,
    MustPurchase,
    Maintenance,
    IsWonder,
    TraitType,
    InternalOnly,
    AdvisorType
)
VALUES
(
    'BUILDING_XJY_YUHU_GATE',
    'LOC_BUILDING_XJY_YUHU_GATE_NAME',
    'LOC_BUILDING_XJY_YUHU_GATE_DESCRIPTION',
    'CIVIC_URBANIZATION',
    800,
    1,
    'DISTRICT_CITY_CENTER',
    0,
    4,
    2,
    0,
    0,
    0,
    'TRAIT_LEADER_XJY_UNIQUE_CONTENT',
    0,
    'ADVISOR_GENERIC'
);

INSERT INTO Building_YieldChanges
(
    BuildingType,
    YieldType,
    YieldChange
)
VALUES
(
    'BUILDING_XJY_YUHU_GATE',
    'YIELD_GOLD',
    8
);

-- The existing Xu Jiayin trait owns both production modifiers. The global
-- modifier is active only while this player owns the Gate. The local modifier
-- additionally tests each city for the Gate, giving 25 + 25 = 50 percent.
INSERT INTO RequirementSets
(
    RequirementSetId,
    RequirementSetType
)
VALUES
    ('REQUIREMENTSET_XJY_PLAYER_HAS_YUHU_GATE', 'REQUIREMENTSET_TEST_ALL'),
    ('REQUIREMENTSET_XJY_CITY_HAS_YUHU_GATE', 'REQUIREMENTSET_TEST_ALL');

INSERT INTO Requirements
(
    RequirementId,
    RequirementType
)
VALUES
    ('REQUIREMENT_XJY_PLAYER_HAS_YUHU_GATE', 'REQUIREMENT_PLAYER_HAS_BUILDING'),
    ('REQUIREMENT_XJY_CITY_HAS_YUHU_GATE', 'REQUIREMENT_CITY_HAS_BUILDING');

INSERT INTO RequirementArguments
(
    RequirementId,
    Name,
    Value
)
VALUES
    ('REQUIREMENT_XJY_PLAYER_HAS_YUHU_GATE', 'BuildingType', 'BUILDING_XJY_YUHU_GATE'),
    ('REQUIREMENT_XJY_CITY_HAS_YUHU_GATE', 'BuildingType', 'BUILDING_XJY_YUHU_GATE');

INSERT INTO RequirementSetRequirements
(
    RequirementSetId,
    RequirementId
)
VALUES
    ('REQUIREMENTSET_XJY_PLAYER_HAS_YUHU_GATE', 'REQUIREMENT_XJY_PLAYER_HAS_YUHU_GATE'),
    ('REQUIREMENTSET_XJY_CITY_HAS_YUHU_GATE', 'REQUIREMENT_XJY_CITY_HAS_YUHU_GATE');

INSERT INTO Modifiers
(
    ModifierId,
    ModifierType,
    OwnerRequirementSetId,
    SubjectRequirementSetId
)
VALUES
    (
        'MODIFIER_XJY_YUHU_ALL_CITIES_BAOJIAOLOU',
        'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_PRODUCTION',
        'REQUIREMENTSET_XJY_PLAYER_HAS_YUHU_GATE',
        NULL
    ),
    (
        'MODIFIER_XJY_YUHU_LOCAL_BAOJIAOLOU_EXTRA',
        'MODIFIER_PLAYER_CITIES_ADJUST_BUILDING_PRODUCTION',
        'REQUIREMENTSET_XJY_PLAYER_HAS_YUHU_GATE',
        'REQUIREMENTSET_XJY_CITY_HAS_YUHU_GATE'
    );

INSERT INTO ModifierArguments
(
    ModifierId,
    Name,
    Value
)
VALUES
    ('MODIFIER_XJY_YUHU_ALL_CITIES_BAOJIAOLOU', 'BuildingType', 'BUILDING_XJY_BAOJIAOLOU'),
    ('MODIFIER_XJY_YUHU_ALL_CITIES_BAOJIAOLOU', 'Amount', 25),
    ('MODIFIER_XJY_YUHU_LOCAL_BAOJIAOLOU_EXTRA', 'BuildingType', 'BUILDING_XJY_BAOJIAOLOU'),
    ('MODIFIER_XJY_YUHU_LOCAL_BAOJIAOLOU_EXTRA', 'Amount', 25);

INSERT INTO TraitModifiers
(
    TraitType,
    ModifierId
)
VALUES
    ('TRAIT_LEADER_XJY_PLACEHOLDER', 'MODIFIER_XJY_YUHU_ALL_CITIES_BAOJIAOLOU'),
    ('TRAIT_LEADER_XJY_PLACEHOLDER', 'MODIFIER_XJY_YUHU_LOCAL_BAOJIAOLOU_EXTRA');
