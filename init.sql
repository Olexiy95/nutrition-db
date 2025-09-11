-- Core user table
CREATE TABLE
    IF NOT EXISTS user (
        id TEXT PRIMARY KEY NOT NULL,
        first_name TEXT,
        last_name TEXT,
        date_of_birth TEXT,
        email TEXT UNIQUE,
        password TEXT NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        height_cm REAL
    );

-- Weight log table
CREATE TABLE
    IF NOT EXISTS user_weight_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        weight REAL NOT NULL,
        log_date TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES user (id)
    );

-- Waist circumference log table
CREATE TABLE
    IF NOT EXISTS user_waist_circumference_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        waist_cm REAL NOT NULL,
        log_date TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES user (id)
    );

-- Bodyfat percentage log table
CREATE TABLE
    IF NOT EXISTS user_bodyfat_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        bodyfat_percentage REAL NOT NULL,
        log_date TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id) REFERENCES user (id)
    );

-- ========================= FOOD (atoms + meals) =========================
CREATE TABLE
    IF NOT EXISTS food (
        id TEXT PRIMARY KEY NOT NULL, -- UUID/string
        name TEXT NOT NULL COLLATE NOCASE,
        brand TEXT COLLATE NOCASE,
        description TEXT,
        -- 'atomic' = loggable standalone item; 'meal' = composition of items
        type TEXT NOT NULL CHECK (type IN ('atomic', 'meal')),
        default_portion_id INTEGER REFERENCES food_portion (id),
        -- Canonical basis for per-100 values and all quantities of this food
        per_100_basis TEXT NOT NULL CHECK (per_100_basis IN ('g', 'ml')),
        -- Per-100 nutrition (only for atomic rows; meals compute from components)
        kcal_per_100 REAL CHECK (
            kcal_per_100 IS NULL
            OR kcal_per_100 >= 0
        ),
        kj_per_100 REAL GENERATED ALWAYS AS (kcal_per_100 * 4.184) STORED,
        protein_g_per_100 REAL CHECK (
            protein_g_per_100 IS NULL
            OR protein_g_per_100 >= 0
        ),
        carbs_g_per_100 REAL CHECK (
            carbs_g_per_100 IS NULL
            OR carbs_g_per_100 >= 0
        ),
        fat_g_per_100 REAL CHECK (
            fat_g_per_100 IS NULL
            OR fat_g_per_100 >= 0
        ),
        fiber_g_per_100 REAL CHECK (
            fiber_g_per_100 IS NULL
            OR fiber_g_per_100 >= 0
        ),
        sugar_g_per_100 REAL CHECK (
            sugar_g_per_100 IS NULL
            OR sugar_g_per_100 >= 0
        ),
        sodium_mg_per_100 REAL CHECK (
            sodium_mg_per_100 IS NULL
            OR sodium_mg_per_100 >= 0
        ),
        -- Optional barcode for packaged items (kept since it's a central catalog)
        barcode TEXT UNIQUE,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        -- Meals must not carry direct per-100 nutrition
        CHECK (
            type = 'atomic'
            OR (
                kcal_per_100 IS NULL
                AND protein_g_per_100 IS NULL
                AND carbs_g_per_100 IS NULL
                AND fat_g_per_100 IS NULL
                AND fiber_g_per_100 IS NULL
                AND sugar_g_per_100 IS NULL
                AND sodium_mg_per_100 IS NULL
            )
        )
    );

CREATE TRIGGER IF NOT EXISTS trg_food_updated_at AFTER
UPDATE ON food FOR EACH ROW BEGIN
UPDATE food
SET
    updated_at = CURRENT_TIMESTAMP
WHERE
    id = OLD.id;

END;

CREATE INDEX IF NOT EXISTS idx_food_type ON food (type);

CREATE INDEX IF NOT EXISTS idx_food_name_nocase ON food (name);

-- =========================
-- PORTIONS (named servings)
-- amount uses the food's basis (g OR ml)
-- =========================
CREATE TABLE
    IF NOT EXISTS food_portion (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        food_id TEXT NOT NULL,
        name TEXT NOT NULL, -- 'slice', 'cup', 'can', 'medium'
        amount REAL NOT NULL CHECK (amount > 0), -- in food.per_100_basis units
        note TEXT,
        FOREIGN KEY (food_id) REFERENCES food (id) ON DELETE CASCADE
    );

CREATE INDEX IF NOT EXISTS idx_portion_food ON food_portion (food_id);

-- Optional guardrail (ensures parent food exists; basis is implicit)
CREATE TRIGGER IF NOT EXISTS trg_portion_food_exists BEFORE INSERT ON food_portion FOR EACH ROW BEGIN
SELECT
    CASE
        WHEN (
            SELECT
                1
            FROM
                food
            WHERE
                id = NEW.food_id
        ) IS NULL THEN RAISE (ABORT, 'food_id not found')
    END;

END;

-- =========================
-- MEAL COMPOSITION
-- parent is a meal; child is an atomic food
-- amount is in the CHILD food's basis (g OR ml)
-- =========================
CREATE TABLE
    IF NOT EXISTS food_component (
        parent_food_id TEXT NOT NULL, -- type='meal'
        child_food_id TEXT NOT NULL, -- type='atomic'
        amount REAL NOT NULL CHECK (amount > 0), -- in child.per_100_basis
        PRIMARY KEY (parent_food_id, child_food_id),
        FOREIGN KEY (parent_food_id) REFERENCES food (id) ON DELETE CASCADE,
        FOREIGN KEY (child_food_id) REFERENCES food (id)
    );

CREATE INDEX IF NOT EXISTS idx_component_parent ON food_component (parent_food_id);

CREATE INDEX IF NOT EXISTS idx_component_child ON food_component (child_food_id);

-- Enforce correct types for composition
CREATE TRIGGER IF NOT EXISTS trg_component_parent_is_meal BEFORE INSERT ON food_component FOR EACH ROW BEGIN
SELECT
    CASE
        WHEN (
            SELECT
                type
            FROM
                food
            WHERE
                id = NEW.parent_food_id
        ) <> 'meal' THEN RAISE (ABORT, 'parent_food_id must reference a meal')
    END;

END;

CREATE TRIGGER IF NOT EXISTS trg_component_child_is_atomic BEFORE INSERT ON food_component FOR EACH ROW BEGIN
SELECT
    CASE
        WHEN (
            SELECT
                type
            FROM
                food
            WHERE
                id = NEW.child_food_id
        ) <> 'atomic' THEN RAISE (
            ABORT,
            'child_food_id must reference an atomic food'
        )
    END;

END;

CREATE VIEW
    IF NOT EXISTS food_display AS
WITH
    meal_totals AS (
        SELECT
            fc.parent_food_id AS food_id,
            SUM(c.kcal_per_100 * fc.amount / 100.0) AS total_kcal,
            SUM(c.protein_g_per_100 * fc.amount / 100.0) AS total_protein_g,
            SUM(c.carbs_g_per_100 * fc.amount / 100.0) AS total_carbs_g,
            SUM(c.fat_g_per_100 * fc.amount / 100.0) AS total_fat_g,
            SUM(c.fiber_g_per_100 * fc.amount / 100.0) AS total_fiber_g,
            SUM(c.sugar_g_per_100 * fc.amount / 100.0) AS total_sugar_g,
            SUM(c.sodium_mg_per_100 * fc.amount / 100.0) AS total_sodium_mg
        FROM
            food_component fc
            JOIN food c ON c.id = fc.child_food_id
        GROUP BY
            fc.parent_food_id
    )
SELECT
    f.id,
    f.name,
    f.brand,
    f.type,
    f.per_100_basis AS basis,
    COALESCE(fp.amount, 100.0) AS display_amount,
    CASE
        WHEN fp.id IS NULL THEN 'per-100'
        ELSE fp.name
    END AS display_portion,
    -- totals for that amount
    (
        f.kcal_per_100 * COALESCE(fp.amount, 100.0) / 100.0
    ) AS total_kcal,
    (
        f.protein_g_per_100 * COALESCE(fp.amount, 100.0) / 100.0
    ) AS total_protein_g,
    (
        f.carbs_g_per_100 * COALESCE(fp.amount, 100.0) / 100.0
    ) AS total_carbs_g,
    (
        f.fat_g_per_100 * COALESCE(fp.amount, 100.0) / 100.0
    ) AS total_fat_g,
    (
        f.fiber_g_per_100 * COALESCE(fp.amount, 100.0) / 100.0
    ) AS total_fiber_g,
    (
        f.sugar_g_per_100 * COALESCE(fp.amount, 100.0) / 100.0
    ) AS total_sugar_g,
    (
        f.sodium_mg_per_100 * COALESCE(fp.amount, 100.0) / 100.0
    ) AS total_sodium_mg
FROM
    food f
    LEFT JOIN food_portion fp ON fp.id = f.default_portion_id
WHERE
    f.type = 'atomic'
UNION ALL
SELECT
    f.id,
    f.name,
    f.brand,
    f.type,
    NULL AS basis,
    NULL AS display_amount,
    'meal total' AS display_portion,
    mt.total_kcal,
    mt.total_protein_g,
    mt.total_carbs_g,
    mt.total_fat_g,
    mt.total_fiber_g,
    mt.total_sugar_g,
    mt.total_sodium_mg
FROM
    food f
    JOIN meal_totals mt ON mt.food_id = f.id
WHERE
    f.type = 'meal';