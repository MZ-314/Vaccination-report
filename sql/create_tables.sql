-- Drop old tables if they exist
DROP TABLE IF EXISTS coverage;
DROP TABLE IF EXISTS incidence;
DROP TABLE IF EXISTS reported_cases;
DROP TABLE IF EXISTS vaccine_introduction;
DROP TABLE IF EXISTS vaccine_schedule;
DROP TABLE IF EXISTS vaccine;
DROP TABLE IF EXISTS disease;
DROP TABLE IF EXISTS country;

-- Lookup tables
CREATE TABLE country (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    iso3 CHAR(3) UNIQUE,
    name TEXT,
    who_region TEXT
);

CREATE TABLE vaccine (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT,
    description TEXT
);

CREATE TABLE disease (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT,
    description TEXT
);

-- Fact tables
CREATE TABLE coverage (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    country_id INTEGER,
    vaccine_id INTEGER,
    year INTEGER,
    coverage_category TEXT,
    coverage_category_description TEXT,  -- ✅ add this column
    target_number INTEGER,
    doses_administered INTEGER,
    coverage REAL,
    coverage_percent REAL,
    FOREIGN KEY (country_id) REFERENCES country(id),
    FOREIGN KEY (vaccine_id) REFERENCES vaccine(id)
);


CREATE TABLE incidence (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    country_id INTEGER,
    disease_id INTEGER,
    year INTEGER,
    denominator TEXT,
    incidence_rate REAL,
    FOREIGN KEY (country_id) REFERENCES country(id),
    FOREIGN KEY (disease_id) REFERENCES disease(id)
);

CREATE TABLE reported_cases (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    country_id INTEGER,
    disease_id INTEGER,
    year INTEGER,
    cases INTEGER,
    FOREIGN KEY (country_id) REFERENCES country(id),
    FOREIGN KEY (disease_id) REFERENCES disease(id)
);

CREATE TABLE vaccine_introduction (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    country_id INTEGER,
    vaccine_id INTEGER,
    year INTEGER,
    introduced BOOLEAN,
    description TEXT,
    FOREIGN KEY (country_id) REFERENCES country(id),
    FOREIGN KEY (vaccine_id) REFERENCES vaccine(id)
);

CREATE TABLE vaccine_schedule (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    country_id INTEGER,
    vaccine_id INTEGER,
    year INTEGER,
    schedulerounds INTEGER,          -- ✅ match CSV column
    targetpop TEXT,
    targetpop_description TEXT,
    geoarea TEXT,
    ageadministered TEXT,
    sourcecomment TEXT,
    FOREIGN KEY (country_id) REFERENCES country(id),
    FOREIGN KEY (vaccine_id) REFERENCES vaccine(id)
);
