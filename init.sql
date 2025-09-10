CREATE TABLE
    IF NOT EXISTS user (
        id TEXT PRIMARY KEY NOT NULL,
        first_name TEXT,
        last_name TEXT,
        date_of_birth TEXT,
        email TEXT UNIQUE,
        password text NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        current_weight REAL,
        current_weight_date TEXT,
        height_cm REAL,
        current_bmi REAL,
        current_bmi_date TEXT
    );

CREATE TABLE
    foods (
        id INTEGER PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT, -- e.g. "fruit", "beverage"
        description TEXT
    );

CREATE TABLE
    nutrients_per_100g (
        id INTEGER PRIMARY KEY,
        food_id INTEGER NOT NULL,
        energy_kcal REAL,
        energy_kj REAL,
        protein_grams REAL,
        fat_grams REAL,
        carbohydrates_g REAL,
        fiber_grams REAL,
        sugar_grams REAL,
        sodium_mgrams REAL,
        FOREIGN KEY (food_id) REFERENCES foods (id)
    );

CREATE TABLE
    servings (
        id INTEGER PRIMARY KEY,
        food_id INTEGER NOT NULL,
        serving_name TEXT NOT NULL, -- e.g. "slice", "cup", "piece"
        amount REAL NOT NULL, -- how many units (e.g., 1.0, 0.5)
        grams_equivalent REAL NOT NULL, -- e.g., 1 slice = 30g
        description TEXT,
        FOREIGN KEY (food_id) REFERENCES foods (id)
    );

CREATE TABLE
    nutrients_per_serving (
        id INTEGER PRIMARY KEY,
        serving_id INTEGER NOT NULL,
        energy_kcal REAL,
        energy_kj REAL,
        protein_grams REAL,
        fat_grams REAL,
        carbohydrates_grams REAL,
        fiber_grams REAL,
        sugar_grams REAL,
        sodium_mgrams REAL,
        -- add more as needed
        FOREIGN KEY (serving_id) REFERENCES servings (id)
    );