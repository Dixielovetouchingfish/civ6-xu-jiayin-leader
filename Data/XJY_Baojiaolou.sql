INSERT INTO Types
(
    Type,
    Kind
)
VALUES
(
    'BUILDING_XJY_BAOJIAOLOU',
    'KIND_BUILDING'
);

INSERT INTO Buildings
(
    BuildingType,
    Name,
    Description,
    PrereqCivic,
    Cost,
    PrereqDistrict,
    Housing,
    Entertainment,
    PurchaseYield,
    Maintenance,
    IsWonder,
    TraitType,
    InternalOnly,
    AdvisorType
)
VALUES
(
    'BUILDING_XJY_BAOJIAOLOU',
    'LOC_BUILDING_XJY_BAOJIAOLOU_NAME',
    'LOC_BUILDING_XJY_BAOJIAOLOU_DESCRIPTION',
    'CIVIC_URBANIZATION',
    300,
    'DISTRICT_CITY_CENTER',
    2,
    1,
    'YIELD_GOLD',
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
    'BUILDING_XJY_BAOJIAOLOU',
    'YIELD_GOLD',
    3
);
