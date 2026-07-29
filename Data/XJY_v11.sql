-- ===========================================================================
-- Xu Jiayin v1.1: High-Turnover Development balance update.
-- Loaded after the existing gameplay, unique-unit and unique-building data.
-- ===========================================================================

-- Remove the old universal Ancient/Classical specialty-district bonus.
-- The first-district modifiers below now provide the complete +100% by
-- themselves, so later districts receive no early production bonus.
DELETE FROM TraitModifiers
WHERE ModifierId LIKE 'MODIFIER_XJY_EARLY_DISTRICT_%';

DELETE FROM ModifierArguments
WHERE ModifierId LIKE 'MODIFIER_XJY_EARLY_DISTRICT_%';

DELETE FROM Modifiers
WHERE ModifierId LIKE 'MODIFIER_XJY_EARLY_DISTRICT_%';

UPDATE ModifierArguments
SET Value = 100
WHERE ModifierId LIKE 'MODIFIER_XJY_EARLY_FIRST_DISTRICT_%'
  AND Name = 'Amount';

UPDATE ModifierArguments
SET Value = 30
WHERE ModifierId LIKE 'MODIFIER_XJY_EARLY_BUILDING_%'
  AND Name = 'Amount';

-- Great Merchant points now belong only to the middle phase.
DELETE FROM TraitModifiers
WHERE ModifierId = 'MODIFIER_XJY_EARLY_MERCHANT_POINTS';

DELETE FROM ModifierArguments
WHERE ModifierId = 'MODIFIER_XJY_EARLY_MERCHANT_POINTS';

DELETE FROM Modifiers
WHERE ModifierId = 'MODIFIER_XJY_EARLY_MERCHANT_POINTS';

UPDATE ModifierArguments
SET Value = 50
WHERE ModifierId = 'MODIFIER_XJY_MID_MERCHANT_POINTS'
  AND Name = 'Amount';

UPDATE ModifierArguments
SET Value = -4
WHERE ModifierId = 'MODIFIER_XJY_MID_CITY_DEBT'
  AND Name = 'Amount';

UPDATE ModifierArguments
SET Value = -6
WHERE ModifierId = 'MODIFIER_XJY_LATE_CITY_DEBT'
  AND Name = 'Amount';

-- Remove the obsolete late-game Capital subsidy.
DELETE FROM TraitModifiers
WHERE ModifierId = 'MODIFIER_XJY_LATE_CAPITAL_GOLD';

DELETE FROM ModifierArguments
WHERE ModifierId = 'MODIFIER_XJY_LATE_CAPITAL_GOLD';

DELETE FROM Modifiers
WHERE ModifierId = 'MODIFIER_XJY_LATE_CAPITAL_GOLD';

-- Middle and late liabilities.
INSERT INTO Modifiers
(
    ModifierId,
    ModifierType,
    OwnerRequirementSetId,
    SubjectRequirementSetId
)
VALUES
    (
        'MODIFIER_XJY_MID_CITY_AMENITY',
        'MODIFIER_PLAYER_CITIES_ADJUST_POLICY_AMENITY',
        'REQUIREMENTSET_XJY_ERA_MEDIEVAL_RENAISSANCE',
        'REQUIREMENTSET_XJY_CITY_HAS_5_SPECIALTY_DISTRICTS'
    ),
    (
        'MODIFIER_XJY_LATE_EMPIRE_GOLD_PERCENT',
        'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER',
        'REQUIREMENTSET_XJY_ERA_INDUSTRIAL_OR_LATER',
        NULL
    ),
    (
        'MODIFIER_XJY_LATE_CITY_EXTRA_DEBT',
        'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_CHANGE',
        'REQUIREMENTSET_XJY_ERA_INDUSTRIAL_OR_LATER',
        'REQUIREMENTSET_XJY_CITY_HAS_5_SPECIALTY_DISTRICTS'
    ),
    (
        'MODIFIER_XJY_LATE_CITY_PRODUCTION',
        'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER',
        'REQUIREMENTSET_XJY_ERA_INDUSTRIAL_OR_LATER',
        'REQUIREMENTSET_XJY_CITY_HAS_5_SPECIALTY_DISTRICTS'
    ),
    (
        'MODIFIER_XJY_LATE_CITY_SCIENCE',
        'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER',
        'REQUIREMENTSET_XJY_ERA_INDUSTRIAL_OR_LATER',
        'REQUIREMENTSET_XJY_CITY_HAS_5_SPECIALTY_DISTRICTS'
    );

INSERT INTO ModifierArguments
(
    ModifierId,
    Name,
    Value
)
VALUES
    ('MODIFIER_XJY_MID_CITY_AMENITY', 'Amount', -1),
    ('MODIFIER_XJY_LATE_EMPIRE_GOLD_PERCENT', 'YieldType', 'YIELD_GOLD'),
    ('MODIFIER_XJY_LATE_EMPIRE_GOLD_PERCENT', 'Amount', -30),
    ('MODIFIER_XJY_LATE_CITY_EXTRA_DEBT', 'YieldType', 'YIELD_GOLD'),
    ('MODIFIER_XJY_LATE_CITY_EXTRA_DEBT', 'Amount', -4),
    ('MODIFIER_XJY_LATE_CITY_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
    ('MODIFIER_XJY_LATE_CITY_PRODUCTION', 'Amount', -15),
    ('MODIFIER_XJY_LATE_CITY_SCIENCE', 'YieldType', 'YIELD_SCIENCE'),
    ('MODIFIER_XJY_LATE_CITY_SCIENCE', 'Amount', -10);

INSERT INTO TraitModifiers
(
    TraitType,
    ModifierId
)
VALUES
    ('TRAIT_LEADER_XJY_PLACEHOLDER', 'MODIFIER_XJY_MID_CITY_AMENITY'),
    ('TRAIT_LEADER_XJY_PLACEHOLDER', 'MODIFIER_XJY_LATE_EMPIRE_GOLD_PERCENT'),
    ('TRAIT_LEADER_XJY_PLACEHOLDER', 'MODIFIER_XJY_LATE_CITY_EXTRA_DEBT'),
    ('TRAIT_LEADER_XJY_PLACEHOLDER', 'MODIFIER_XJY_LATE_CITY_PRODUCTION'),
    ('TRAIT_LEADER_XJY_PLACEHOLDER', 'MODIFIER_XJY_LATE_CITY_SCIENCE');

-- The old Land Reserve was trait-wide and could not remember the founding era.
-- v1.1 attaches these two modifiers only to cities whose persistent Lua
-- qualification is granted at CityBuilt time.
DELETE FROM TraitModifiers
WHERE ModifierId = 'MODIFIER_XJY_EARLY_LAND_RESERVE';

DELETE FROM ModifierArguments
WHERE ModifierId = 'MODIFIER_XJY_EARLY_LAND_RESERVE';

DELETE FROM Modifiers
WHERE ModifierId = 'MODIFIER_XJY_EARLY_LAND_RESERVE';

INSERT INTO RequirementSetRequirements
(
    RequirementSetId,
    RequirementId
)
VALUES
(
    'REQUIREMENTSET_XJY_LAND_RESERVE_CITY',
    'REQUIREMENT_XJY_CITY_HAS_0_SPECIALTY_DISTRICTS'
);

INSERT INTO RequirementSets
(
    RequirementSetId,
    RequirementSetType
)
VALUES
(
    'REQUIREMENTSET_XJY_PROJECT_BACKLOG_CITY',
    'REQUIREMENTSET_TEST_ALL'
);

INSERT INTO Requirements
(
    RequirementId,
    RequirementType
)
VALUES
(
    'REQUIREMENT_XJY_PROJECT_BACKLOG_POPULATION_4',
    'REQUIREMENT_CITY_HAS_X_POPULATION'
);

INSERT INTO RequirementArguments
(
    RequirementId,
    Name,
    Value
)
VALUES
(
    'REQUIREMENT_XJY_PROJECT_BACKLOG_POPULATION_4',
    'Amount',
    4
);

INSERT INTO RequirementSetRequirements
(
    RequirementSetId,
    RequirementId
)
VALUES
    ('REQUIREMENTSET_XJY_PROJECT_BACKLOG_CITY', 'REQUIRES_CITY_WAS_FOUNDED'),
    ('REQUIREMENTSET_XJY_PROJECT_BACKLOG_CITY', 'REQUIREMENT_XJY_LAND_RESERVE_NOT_CAPITAL'),
    ('REQUIREMENTSET_XJY_PROJECT_BACKLOG_CITY', 'REQUIREMENT_XJY_PROJECT_BACKLOG_POPULATION_4'),
    ('REQUIREMENTSET_XJY_PROJECT_BACKLOG_CITY', 'REQUIREMENT_XJY_CITY_HAS_0_SPECIALTY_DISTRICTS');

INSERT INTO Modifiers
(
    ModifierId,
    ModifierType,
    OwnerRequirementSetId,
    SubjectRequirementSetId
)
VALUES
    (
        'MODIFIER_XJY_EARLY_PROJECT_LAND_RESERVE_CITY',
        'MODIFIER_SINGLE_CITY_ADJUST_IDENTITY_PER_TURN',
        'REQUIREMENTSET_XJY_ERA_ANCIENT_CLASSICAL',
        'REQUIREMENTSET_XJY_LAND_RESERVE_CITY'
    ),
    (
        'MODIFIER_XJY_EARLY_PROJECT_BACKLOG_CITY',
        'MODIFIER_SINGLE_CITY_ADJUST_YIELD_CHANGE',
        'REQUIREMENTSET_XJY_ERA_ANCIENT_CLASSICAL',
        'REQUIREMENTSET_XJY_PROJECT_BACKLOG_CITY'
    );

INSERT INTO ModifierArguments
(
    ModifierId,
    Name,
    Value
)
VALUES
    ('MODIFIER_XJY_EARLY_PROJECT_LAND_RESERVE_CITY', 'Amount', 8),
    ('MODIFIER_XJY_EARLY_PROJECT_BACKLOG_CITY', 'YieldType', 'YIELD_GOLD'),
    ('MODIFIER_XJY_EARLY_PROJECT_BACKLOG_CITY', 'Amount', -2);

-- A city-scoped amenity modifier is composed from the official owner
-- collection and EFFECT_ADJUST_POLICY_AMENITY. Lua attaches +1 on delivery and
-- later attaches -1 to end the serialized temporary effect without relying on
-- an unverified detach API.
INSERT INTO Types
(
    Type,
    Kind
)
VALUES
(
    'MODIFIER_XJY_SINGLE_CITY_ADJUST_POLICY_AMENITY',
    'KIND_MODIFIER'
);

INSERT INTO DynamicModifiers
(
    ModifierType,
    CollectionType,
    EffectType
)
VALUES
(
    'MODIFIER_XJY_SINGLE_CITY_ADJUST_POLICY_AMENITY',
    'COLLECTION_OWNER',
    'EFFECT_ADJUST_POLICY_AMENITY'
);

INSERT INTO Modifiers
(
    ModifierId,
    ModifierType
)
VALUES
    (
        'MODIFIER_XJY_ON_TIME_DELIVERY_AMENITY',
        'MODIFIER_XJY_SINGLE_CITY_ADJUST_POLICY_AMENITY'
    ),
    (
        'MODIFIER_XJY_ON_TIME_DELIVERY_AMENITY_END',
        'MODIFIER_XJY_SINGLE_CITY_ADJUST_POLICY_AMENITY'
    );

INSERT INTO ModifierArguments
(
    ModifierId,
    Name,
    Value
)
VALUES
    ('MODIFIER_XJY_ON_TIME_DELIVERY_AMENITY', 'Amount', 1),
    ('MODIFIER_XJY_ON_TIME_DELIVERY_AMENITY_END', 'Amount', -1);

-- Guaranteed Delivery Program: only a late five-district city offsets the
-- corresponding -15% Production penalty.
INSERT INTO RequirementSets
(
    RequirementSetId,
    RequirementSetType
)
VALUES
    ('REQUIREMENTSET_XJY_CITY_HAS_BAOJIAOLOU', 'REQUIREMENTSET_TEST_ALL'),
    ('REQUIREMENTSET_XJY_CITY_HAS_BAOJIAOLOU_AND_5_DISTRICTS', 'REQUIREMENTSET_TEST_ALL');

INSERT INTO Requirements
(
    RequirementId,
    RequirementType
)
VALUES
(
    'REQUIREMENT_XJY_CITY_HAS_BAOJIAOLOU',
    'REQUIREMENT_CITY_HAS_BUILDING'
);

INSERT INTO RequirementArguments
(
    RequirementId,
    Name,
    Value
)
VALUES
(
    'REQUIREMENT_XJY_CITY_HAS_BAOJIAOLOU',
    'BuildingType',
    'BUILDING_XJY_BAOJIAOLOU'
);

INSERT INTO RequirementSetRequirements
(
    RequirementSetId,
    RequirementId
)
VALUES
    ('REQUIREMENTSET_XJY_CITY_HAS_BAOJIAOLOU', 'REQUIREMENT_XJY_CITY_HAS_BAOJIAOLOU'),
    ('REQUIREMENTSET_XJY_CITY_HAS_BAOJIAOLOU_AND_5_DISTRICTS', 'REQUIREMENT_XJY_CITY_HAS_BAOJIAOLOU'),
    ('REQUIREMENTSET_XJY_CITY_HAS_BAOJIAOLOU_AND_5_DISTRICTS', 'REQUIREMENT_XJY_CITY_HAS_5_SPECIALTY_DISTRICTS');

INSERT INTO Modifiers
(
    ModifierId,
    ModifierType,
    OwnerRequirementSetId,
    SubjectRequirementSetId
)
VALUES
(
    'MODIFIER_XJY_BAOJIAOLOU_LATE_PRODUCTION_RECOVERY',
    'MODIFIER_PLAYER_CITIES_ADJUST_CITY_YIELD_MODIFIER',
    'REQUIREMENTSET_XJY_ERA_INDUSTRIAL_OR_LATER',
    'REQUIREMENTSET_XJY_CITY_HAS_BAOJIAOLOU_AND_5_DISTRICTS'
);

INSERT INTO ModifierArguments
(
    ModifierId,
    Name,
    Value
)
VALUES
    ('MODIFIER_XJY_BAOJIAOLOU_LATE_PRODUCTION_RECOVERY', 'YieldType', 'YIELD_PRODUCTION'),
    ('MODIFIER_XJY_BAOJIAOLOU_LATE_PRODUCTION_RECOVERY', 'Amount', 15);

INSERT INTO TraitModifiers
(
    TraitType,
    ModifierId
)
VALUES
(
    'TRAIT_LEADER_XJY_PLACEHOLDER',
    'MODIFIER_XJY_BAOJIAOLOU_LATE_PRODUCTION_RECOVERY'
);

-- Official Holy Order uses this typed purchase-cost modifier with UnitType and
-- Amount. One row per land combat unit avoids discounting civilian units.
INSERT INTO Modifiers
(
    ModifierId,
    ModifierType,
    SubjectRequirementSetId
)
SELECT
    'MODIFIER_XJY_BAOJIAOLOU_LAND_PURCHASE_' || UnitType,
    'MODIFIER_PLAYER_CITIES_ADJUST_UNIT_PURCHASE_COST',
    'REQUIREMENTSET_XJY_CITY_HAS_BAOJIAOLOU'
FROM Units
WHERE Domain = 'DOMAIN_LAND'
  AND Combat > 0;

INSERT INTO ModifierArguments
(
    ModifierId,
    Name,
    Value
)
SELECT
    'MODIFIER_XJY_BAOJIAOLOU_LAND_PURCHASE_' || UnitType,
    'UnitType',
    UnitType
FROM Units
WHERE Domain = 'DOMAIN_LAND'
  AND Combat > 0;

INSERT INTO ModifierArguments
(
    ModifierId,
    Name,
    Value
)
SELECT
    'MODIFIER_XJY_BAOJIAOLOU_LAND_PURCHASE_' || UnitType,
    'Amount',
    20
FROM Units
WHERE Domain = 'DOMAIN_LAND'
  AND Combat > 0;

INSERT INTO TraitModifiers
(
    TraitType,
    ModifierId
)
SELECT
    'TRAIT_LEADER_XJY_PLACEHOLDER',
    'MODIFIER_XJY_BAOJIAOLOU_LAND_PURCHASE_' || UnitType
FROM Units
WHERE Domain = 'DOMAIN_LAND'
  AND Combat > 0;

-- Light AI preferences only; no hidden yields, combat bonuses or expansion/
-- war agenda changes are introduced.
INSERT INTO AiListTypes
(
    ListType
)
VALUES
    ('XJYFavoredDistricts'),
    ('XJYFavoredBuildings'),
    ('XJYFavoredUnitClasses');

INSERT INTO AiLists
(
    ListType,
    LeaderType,
    System
)
VALUES
    ('XJYFavoredDistricts', 'TRAIT_LEADER_XJY_PLACEHOLDER', 'Districts'),
    ('XJYFavoredBuildings', 'TRAIT_LEADER_XJY_PLACEHOLDER', 'Buildings'),
    ('XJYFavoredUnitClasses', 'TRAIT_LEADER_XJY_PLACEHOLDER', 'UnitPromotionClasses');

INSERT INTO AiFavoredItems
(
    ListType,
    Item,
    Favored,
    Value
)
VALUES
    ('XJYFavoredDistricts', 'DISTRICT_COMMERCIAL_HUB', 1, 0),
    ('XJYFavoredDistricts', 'DISTRICT_INDUSTRIAL_ZONE', 1, 0),
    ('XJYFavoredDistricts', 'DISTRICT_CAMPUS', 1, 0),
    ('XJYFavoredBuildings', 'BUILDING_XJY_BAOJIAOLOU', 1, 0),
    ('XJYFavoredBuildings', 'BUILDING_WALLS', 1, 0),
    ('XJYFavoredBuildings', 'BUILDING_CASTLE', 1, 0),
    ('XJYFavoredBuildings', 'BUILDING_STAR_FORT', 1, 0),
    ('XJYFavoredUnitClasses', 'PROMOTION_CLASS_RANGED', 1, 1);
