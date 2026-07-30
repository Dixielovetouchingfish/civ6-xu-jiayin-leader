-- ===========================================================================
-- Xu Jiayin v1.2.1: Stability Hotfix.
-- This incremental patch is loaded after XJY_v11.sql.
-- ===========================================================================

-- The v1.1 Site Security modifier used COLLECTION_PLAYER_COMBAT. That
-- collection does not evaluate the unit-domain/opponent requirements in the
-- same unit-combat context as the official anti-Barbarian modifier. Remove the
-- complete old +5 chain before installing the official unit-combat structure.
DELETE FROM ModifierStrings
WHERE ModifierId = 'MODIFIER_XJY_EARLY_SITE_SECURITY';

DELETE FROM TraitModifiers
WHERE ModifierId = 'MODIFIER_XJY_EARLY_SITE_SECURITY';

DELETE FROM ModifierArguments
WHERE ModifierId = 'MODIFIER_XJY_EARLY_SITE_SECURITY';

DELETE FROM Modifiers
WHERE ModifierId = 'MODIFIER_XJY_EARLY_SITE_SECURITY';

DELETE FROM RequirementSetRequirements
WHERE RequirementSetId = 'REQUIREMENTSET_XJY_LAND_UNIT_VS_BARBARIAN';

DELETE FROM RequirementSets
WHERE RequirementSetId = 'REQUIREMENTSET_XJY_LAND_UNIT_VS_BARBARIAN';

-- Remove the failed first v1.2 implementation as an explicit migration guard.
-- It attached a unit-owner modifier directly to a player-owned leader trait.
DELETE FROM ModifierStrings
WHERE ModifierId = 'MODIFIER_XJY_V12_CONSTRUCTION_SITE_SECURITY';

DELETE FROM TraitModifiers
WHERE ModifierId = 'MODIFIER_XJY_V12_CONSTRUCTION_SITE_SECURITY';

DELETE FROM ModifierArguments
WHERE ModifierId = 'MODIFIER_XJY_V12_CONSTRUCTION_SITE_SECURITY';

DELETE FROM Modifiers
WHERE ModifierId = 'MODIFIER_XJY_V12_CONSTRUCTION_SITE_SECURITY';

DELETE FROM RequirementSetRequirements
WHERE RequirementSetId = 'REQUIREMENTSET_XJY_V12_LAND_COMBAT_VS_BARBARIAN';

DELETE FROM RequirementSets
WHERE RequirementSetId = 'REQUIREMENTSET_XJY_V12_LAND_COMBAT_VS_BARBARIAN';

-- Remove the obsolete personal-era gate. It caused the early combat effect to
-- end when Xu Jiayin personally unlocked a Medieval technology, even while the
-- world remained in the Classical Era.
DELETE FROM RequirementSetRequirements
WHERE RequirementSetId = 'REQUIREMENTSET_XJY_V12_PLAYER_BEFORE_MEDIEVAL';

DELETE FROM RequirementArguments
WHERE RequirementId = 'REQUIREMENT_XJY_V12_PLAYER_BEFORE_MEDIEVAL';

DELETE FROM Requirements
WHERE RequirementId = 'REQUIREMENT_XJY_V12_PLAYER_BEFORE_MEDIEVAL';

DELETE FROM RequirementSets
WHERE RequirementSetId = 'REQUIREMENTSET_XJY_V12_PLAYER_BEFORE_MEDIEVAL';

-- The official REQUIREMENT_GAME_ERA_IS structure is already assembled by
-- XJY_Gameplay.sql as REQUIREMENTSET_XJY_ERA_ANCIENT_CLASSICAL (TEST_ANY:
-- ERA_ANCIENT or ERA_CLASSICAL). All v1.2 early static effects reuse that
-- world-era gate, keeping the phase internally consistent without Lua polling.
INSERT INTO RequirementSets
(
    RequirementSetId,
    RequirementSetType
)
VALUES
(
    'REQUIREMENTSET_XJY_V12_LAND_UNITS',
    'REQUIREMENTSET_TEST_ALL'
);

INSERT INTO RequirementSetRequirements
(
    RequirementSetId,
    RequirementId
)
VALUES
(
    'REQUIREMENTSET_XJY_V12_LAND_UNITS',
    'REQUIRES_UNIT_IS_LAND_DOMAIN'
);

-- City Cash Flow: each owned City Center receives its own +2 Gold.
INSERT INTO Modifiers
(
    ModifierId,
    ModifierType,
    OwnerRequirementSetId,
    SubjectRequirementSetId
)
VALUES
(
    'MODIFIER_XJY_V12_CITY_CENTER_GOLD',
    'MODIFIER_PLAYER_DISTRICTS_ADJUST_YIELD_CHANGE',
    'REQUIREMENTSET_XJY_ERA_ANCIENT_CLASSICAL',
    'REQUIREMENTSET_XJY_DISTRICT_IS_CITY_CENTER'
);

INSERT INTO ModifierArguments
(
    ModifierId,
    Name,
    Value
)
VALUES
    ('MODIFIER_XJY_V12_CITY_CENTER_GOLD', 'YieldType', 'YIELD_GOLD'),
    ('MODIFIER_XJY_V12_CITY_CENTER_GOLD', 'Amount', 2);

-- Construction Site Security copies the official Discipline policy structure:
-- MODIFIER_PLAYER_UNITS_ADJUST_BARBARIAN_COMBAT propagates from the player to
-- COLLECTION_PLAYER_UNITS and applies EFFECT_ADJUST_UNIT_BARBARIAN_COMBAT.
-- The SubjectRequirementSet narrows that official player-unit collection to
-- land units. The effect itself handles Barbarian attack and defense combat.
INSERT INTO Modifiers
(
    ModifierId,
    ModifierType,
    OwnerRequirementSetId,
    SubjectRequirementSetId
)
VALUES
(
    'MODIFIER_XJY_V12_CONSTRUCTION_SITE_SECURITY',
    'MODIFIER_PLAYER_UNITS_ADJUST_BARBARIAN_COMBAT',
    'REQUIREMENTSET_XJY_ERA_ANCIENT_CLASSICAL',
    'REQUIREMENTSET_XJY_V12_LAND_UNITS'
);

INSERT INTO ModifierArguments
(
    ModifierId,
    Name,
    Value
)
VALUES
(
    'MODIFIER_XJY_V12_CONSTRUCTION_SITE_SECURITY',
    'Amount',
    8
);

INSERT INTO ModifierStrings
(
    ModifierId,
    Context,
    Text
)
VALUES
(
    'MODIFIER_XJY_V12_CONSTRUCTION_SITE_SECURITY',
    'Preview',
    'LOC_XJY_V12_CONSTRUCTION_SITE_SECURITY_COMBAT_PREVIEW'
);

-- Construction Mobilization: the official all-military production modifier
-- accepts PromotionClass. Seven explicit land-combat promotion classes prevent
-- civilians, religious units, naval units and aircraft from qualifying.
INSERT INTO Modifiers
(
    ModifierId,
    ModifierType,
    OwnerRequirementSetId
)
VALUES
    (
        'MODIFIER_XJY_V12_MOBILIZATION_RECON',
        'MODIFIER_PLAYER_CITIES_ADJUST_MILITARY_UNITS_PRODUCTION',
        'REQUIREMENTSET_XJY_ERA_ANCIENT_CLASSICAL'
    ),
    (
        'MODIFIER_XJY_V12_MOBILIZATION_MELEE',
        'MODIFIER_PLAYER_CITIES_ADJUST_MILITARY_UNITS_PRODUCTION',
        'REQUIREMENTSET_XJY_ERA_ANCIENT_CLASSICAL'
    ),
    (
        'MODIFIER_XJY_V12_MOBILIZATION_RANGED',
        'MODIFIER_PLAYER_CITIES_ADJUST_MILITARY_UNITS_PRODUCTION',
        'REQUIREMENTSET_XJY_ERA_ANCIENT_CLASSICAL'
    ),
    (
        'MODIFIER_XJY_V12_MOBILIZATION_ANTI_CAVALRY',
        'MODIFIER_PLAYER_CITIES_ADJUST_MILITARY_UNITS_PRODUCTION',
        'REQUIREMENTSET_XJY_ERA_ANCIENT_CLASSICAL'
    ),
    (
        'MODIFIER_XJY_V12_MOBILIZATION_LIGHT_CAVALRY',
        'MODIFIER_PLAYER_CITIES_ADJUST_MILITARY_UNITS_PRODUCTION',
        'REQUIREMENTSET_XJY_ERA_ANCIENT_CLASSICAL'
    ),
    (
        'MODIFIER_XJY_V12_MOBILIZATION_HEAVY_CAVALRY',
        'MODIFIER_PLAYER_CITIES_ADJUST_MILITARY_UNITS_PRODUCTION',
        'REQUIREMENTSET_XJY_ERA_ANCIENT_CLASSICAL'
    ),
    (
        'MODIFIER_XJY_V12_MOBILIZATION_SIEGE',
        'MODIFIER_PLAYER_CITIES_ADJUST_MILITARY_UNITS_PRODUCTION',
        'REQUIREMENTSET_XJY_ERA_ANCIENT_CLASSICAL'
    );

INSERT INTO ModifierArguments
(
    ModifierId,
    Name,
    Value
)
VALUES
    ('MODIFIER_XJY_V12_MOBILIZATION_RECON', 'PromotionClass', 'PROMOTION_CLASS_RECON'),
    ('MODIFIER_XJY_V12_MOBILIZATION_RECON', 'Amount', 25),
    ('MODIFIER_XJY_V12_MOBILIZATION_MELEE', 'PromotionClass', 'PROMOTION_CLASS_MELEE'),
    ('MODIFIER_XJY_V12_MOBILIZATION_MELEE', 'Amount', 25),
    ('MODIFIER_XJY_V12_MOBILIZATION_RANGED', 'PromotionClass', 'PROMOTION_CLASS_RANGED'),
    ('MODIFIER_XJY_V12_MOBILIZATION_RANGED', 'Amount', 25),
    ('MODIFIER_XJY_V12_MOBILIZATION_ANTI_CAVALRY', 'PromotionClass', 'PROMOTION_CLASS_ANTI_CAVALRY'),
    ('MODIFIER_XJY_V12_MOBILIZATION_ANTI_CAVALRY', 'Amount', 25),
    ('MODIFIER_XJY_V12_MOBILIZATION_LIGHT_CAVALRY', 'PromotionClass', 'PROMOTION_CLASS_LIGHT_CAVALRY'),
    ('MODIFIER_XJY_V12_MOBILIZATION_LIGHT_CAVALRY', 'Amount', 25),
    ('MODIFIER_XJY_V12_MOBILIZATION_HEAVY_CAVALRY', 'PromotionClass', 'PROMOTION_CLASS_HEAVY_CAVALRY'),
    ('MODIFIER_XJY_V12_MOBILIZATION_HEAVY_CAVALRY', 'Amount', 25),
    ('MODIFIER_XJY_V12_MOBILIZATION_SIEGE', 'PromotionClass', 'PROMOTION_CLASS_SIEGE'),
    ('MODIFIER_XJY_V12_MOBILIZATION_SIEGE', 'Amount', 25);

INSERT INTO TraitModifiers
(
    TraitType,
    ModifierId
)
VALUES
    ('TRAIT_LEADER_XJY_PLACEHOLDER', 'MODIFIER_XJY_V12_CITY_CENTER_GOLD'),
    ('TRAIT_LEADER_XJY_PLACEHOLDER', 'MODIFIER_XJY_V12_CONSTRUCTION_SITE_SECURITY'),
    ('TRAIT_LEADER_XJY_PLACEHOLDER', 'MODIFIER_XJY_V12_MOBILIZATION_RECON'),
    ('TRAIT_LEADER_XJY_PLACEHOLDER', 'MODIFIER_XJY_V12_MOBILIZATION_MELEE'),
    ('TRAIT_LEADER_XJY_PLACEHOLDER', 'MODIFIER_XJY_V12_MOBILIZATION_RANGED'),
    ('TRAIT_LEADER_XJY_PLACEHOLDER', 'MODIFIER_XJY_V12_MOBILIZATION_ANTI_CAVALRY'),
    ('TRAIT_LEADER_XJY_PLACEHOLDER', 'MODIFIER_XJY_V12_MOBILIZATION_LIGHT_CAVALRY'),
    ('TRAIT_LEADER_XJY_PLACEHOLDER', 'MODIFIER_XJY_V12_MOBILIZATION_HEAVY_CAVALRY'),
    ('TRAIT_LEADER_XJY_PLACEHOLDER', 'MODIFIER_XJY_V12_MOBILIZATION_SIEGE');

-- Asset Takeover uses city-scoped modifiers attached by the v1.2 gameplay
-- controller. Matching negative modifiers end each serialized temporary effect
-- without relying on an unverified detach API.
INSERT INTO Modifiers
(
    ModifierId,
    ModifierType
)
VALUES
    (
        'MODIFIER_XJY_V12_ASSET_TAKEOVER_LOYALTY',
        'MODIFIER_SINGLE_CITY_ADJUST_IDENTITY_PER_TURN'
    ),
    (
        'MODIFIER_XJY_V12_ASSET_TAKEOVER_LOYALTY_END',
        'MODIFIER_SINGLE_CITY_ADJUST_IDENTITY_PER_TURN'
    ),
    (
        'MODIFIER_XJY_V12_ASSET_TAKEOVER_AMENITY',
        'MODIFIER_XJY_SINGLE_CITY_ADJUST_POLICY_AMENITY'
    ),
    (
        'MODIFIER_XJY_V12_ASSET_TAKEOVER_AMENITY_END',
        'MODIFIER_XJY_SINGLE_CITY_ADJUST_POLICY_AMENITY'
    ),
    (
        'MODIFIER_XJY_V12_ASSET_TAKEOVER_PRODUCTION',
        'MODIFIER_SINGLE_CITY_ADJUST_YIELD_CHANGE'
    ),
    (
        'MODIFIER_XJY_V12_ASSET_TAKEOVER_PRODUCTION_END',
        'MODIFIER_SINGLE_CITY_ADJUST_YIELD_CHANGE'
    ),
    (
        'MODIFIER_XJY_V12_SALES_NETWORK_TRADE_CAPACITY',
        'MODIFIER_PLAYER_ADJUST_TRADE_ROUTE_CAPACITY'
    );

INSERT INTO ModifierArguments
(
    ModifierId,
    Name,
    Value
)
VALUES
    ('MODIFIER_XJY_V12_ASSET_TAKEOVER_LOYALTY', 'Amount', 5),
    ('MODIFIER_XJY_V12_ASSET_TAKEOVER_LOYALTY_END', 'Amount', -5),
    ('MODIFIER_XJY_V12_ASSET_TAKEOVER_AMENITY', 'Amount', 1),
    ('MODIFIER_XJY_V12_ASSET_TAKEOVER_AMENITY_END', 'Amount', -1),
    ('MODIFIER_XJY_V12_ASSET_TAKEOVER_PRODUCTION', 'YieldType', 'YIELD_PRODUCTION'),
    ('MODIFIER_XJY_V12_ASSET_TAKEOVER_PRODUCTION', 'Amount', 4),
    ('MODIFIER_XJY_V12_ASSET_TAKEOVER_PRODUCTION_END', 'YieldType', 'YIELD_PRODUCTION'),
    ('MODIFIER_XJY_V12_ASSET_TAKEOVER_PRODUCTION_END', 'Amount', -4),
    ('MODIFIER_XJY_V12_SALES_NETWORK_TRADE_CAPACITY', 'Amount', 1);
