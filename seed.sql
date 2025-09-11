-- ================================
-- Seed data for FOOD (atomic + meals)
-- ================================
INSERT INTO
    food (
        id,
        name,
        brand,
        description,
        type,
        per_100_basis,
        kcal_per_100,
        protein_g_per_100,
        carbs_g_per_100,
        fat_g_per_100,
        fiber_g_per_100,
        sugar_g_per_100,
        sodium_mg_per_100,
        barcode
    )
VALUES
    -- Atomic items
    (
        'tomato',
        'Tomato',
        NULL,
        'Fresh red tomato',
        'atomic',
        'g',
        18,
        0.9,
        3.9,
        0.2,
        1.2,
        2.6,
        5,
        NULL
    ),
    (
        'cucumber',
        'Cucumber',
        NULL,
        'Fresh cucumber',
        'atomic',
        'g',
        16,
        0.7,
        3.6,
        0.1,
        0.5,
        1.7,
        2,
        NULL
    ),
    (
        'double_cheeseburger',
        'Double Cheeseburger',
        'McDonald''s',
        'McDonald''s double cheeseburger',
        'atomic',
        'g',
        301,
        17,
        32,
        14,
        2.0,
        7.0,
        1150,
        '1234567890123'
    ),
    (
        'fries_small',
        'Fries (Small)',
        'McDonald''s',
        'Small fries',
        'atomic',
        'g',
        323,
        3.5,
        41,
        16,
        3.8,
        0.3,
        210,
        '2345678901234'
    ),
    (
        'coke_small',
        'Coke (Small)',
        'McDonald''s',
        'Small Coke (250ml)',
        'atomic',
        'ml',
        42,
        0,
        11,
        0,
        0,
        11,
        5,
        '3456789012345'
    ),
    -- Meals
    (
        'salad',
        'Simple Salad',
        NULL,
        'Tomato + cucumber salad',
        'meal',
        'g',
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL
    ),
    (
        'mcd_combo',
        'McDonald''s Double Cheeseburger Meal',
        'McDonald''s',
        'Burger + fries + Coke',
        'meal',
        'g',
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL,
        NULL
    );

-- ================================
-- Seed data for FOOD_PORTION (servings)
-- ================================
INSERT INTO
    food_portion (food_id, name, amount, note)
VALUES
    (
        'tomato',
        'medium tomato',
        123,
        'average medium whole tomato'
    ),
    (
        'cucumber',
        'medium cucumber',
        200,
        'average cucumber'
    ),
    (
        'fries_small',
        'carton',
        80,
        'McDonald''s small fries serving'
    ),
    (
        'coke_small',
        'cup',
        250,
        'McDonald''s small Coke cup'
    );

-- ================================
-- Seed data for FOOD_COMPONENT (meal compositions)
-- ================================
INSERT INTO
    food_component (parent_food_id, child_food_id, amount)
VALUES
    -- Salad = tomato + cucumber
    ('salad', 'tomato', 150),
    ('salad', 'cucumber', 100),
    -- McDonald's combo = cheeseburger + fries + coke
    ('mcd_combo', 'double_cheeseburger', 150),
    ('mcd_combo', 'fries_small', 100),
    ('mcd_combo', 'coke_small', 250);

-- ========================================
-- Example queries for testing
-- ========================================
-- 1) Show all foods
-- SELECT id, name, type, per_100_basis FROM food;
-- 2) Show composition of the salad
-- SELECT f.name, fc.amount, f.per_100_basis
-- FROM food_component fc
-- JOIN food f ON f.id = fc.child_food_id
-- WHERE fc.parent_food_id = 'salad';
-- 3) Compute total kcal + protein for the salad
-- SELECT SUM(f.kcal_per_100 * fc.amount / 100.0) AS total_kcal,
--        SUM(f.protein_g_per_100 * fc.amount / 100.0) AS total_protein
-- FROM food_component fc
-- JOIN food f ON f.id = fc.child_food_id
-- WHERE fc.parent_food_id = 'salad';
-- 4) Compute totals for the McDonald's combo meal
-- SELECT SUM(f.kcal_per_100 * fc.amount / 100.0) AS total_kcal,
--        SUM(f.carbs_g_per_100 * fc.amount / 100.0) AS total_carbs,
--        SUM(f.fat_g_per_100 * fc.amount / 100.0) AS total_fat,
--        SUM(f.protein_g_per_100 * fc.amount / 100.0) AS total_protein,
--        SUM(f.sodium_mg_per_100 * fc.amount / 100.0) AS total_sodium
-- FROM food_component fc
-- JOIN food f ON f.id = fc.child_food_id
-- WHERE fc.parent_food_id = 'mcd_combo';