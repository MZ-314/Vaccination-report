import pandas as pd
import sqlite3
from pathlib import Path

CLEAN = Path("data/clean")
DB = Path("db/vaccination.db")
DB.parent.mkdir(exist_ok=True)

# Connect to SQLite
conn = sqlite3.connect(DB)
cur = conn.cursor()

# Run schema (drops old tables first)
with open("sql/create_tables.sql", "r") as f:
    conn.executescript(f.read())
print("✔ Database schema created")

# --- Load cleaned CSVs ---
coverage = pd.read_csv(CLEAN/"coverage_clean.csv")
incidence = pd.read_csv(CLEAN/"incidence_clean.csv")
cases = pd.read_csv(CLEAN/"reported_cases_clean.csv")
intro = pd.read_csv(CLEAN/"vaccine_introduction_clean.csv")
schedule = pd.read_csv(CLEAN/"vaccine_schedule_clean.csv")

# Drop unused "group" columns
for df in [coverage, incidence, cases]:
    if "group" in df.columns:
        df.drop(columns=["group"], inplace=True)

# --- Populate lookup tables ---
countries = coverage[["iso3","country"]].drop_duplicates()
if "who_region" not in countries.columns and "who_region" in intro.columns:
    countries = countries.merge(intro[["iso3","who_region"]].drop_duplicates(), on="iso3", how="left")
countries = countries.rename(columns={"country":"name"})
countries.to_sql("country", conn, if_exists="append", index=False)

vaccines = pd.concat([
    coverage[["antigen","antigen_description"]].rename(columns={"antigen":"code","antigen_description":"description"}),
    schedule[["vaccinecode","vaccine_description"]].rename(columns={"vaccinecode":"code","vaccine_description":"description"})
]).drop_duplicates()
vaccines.to_sql("vaccine", conn, if_exists="append", index=False)

diseases = pd.concat([
    incidence[["disease","disease_description"]].rename(columns={"disease":"code","disease_description":"description"}),
    cases[["disease","disease_description"]].rename(columns={"disease":"code","disease_description":"description"})
]).drop_duplicates()
diseases.to_sql("disease", conn, if_exists="append", index=False)

# --- Build lookup dicts ---
country_map = pd.read_sql("SELECT id, iso3 FROM country", conn).set_index("iso3")["id"].to_dict()
vaccine_map = pd.read_sql("SELECT id, code FROM vaccine", conn).set_index("code")["id"].to_dict()
disease_map = pd.read_sql("SELECT id, code FROM disease", conn).set_index("code")["id"].to_dict()

# --- Insert fact tables (normalized) ---

# Coverage
cov_fact = coverage.rename(columns={
    "antigen":"vaccine_code",
    "country":"country_name"
})
cov_fact["country_id"] = cov_fact["iso3"].map(country_map)
cov_fact["vaccine_id"] = cov_fact["vaccine_code"].map(vaccine_map)
cov_fact = cov_fact[[
    "country_id","vaccine_id","year","coverage_category","coverage_category_description",
    "target_number","doses_administered","coverage","coverage_percent"
]]
cov_fact.to_sql("coverage", conn, if_exists="append", index=False)

# Incidence
inc_fact = incidence.rename(columns={"disease":"disease_code"})
inc_fact["country_id"] = inc_fact["iso3"].map(country_map)
inc_fact["disease_id"] = inc_fact["disease_code"].map(disease_map)
inc_fact = inc_fact[["country_id","disease_id","year","denominator","incidence_rate"]]
inc_fact.to_sql("incidence", conn, if_exists="append", index=False)

# Cases
cases_fact = cases.rename(columns={"disease":"disease_code"})
cases_fact["country_id"] = cases_fact["iso3"].map(country_map)
cases_fact["disease_id"] = cases_fact["disease_code"].map(disease_map)
cases_fact = cases_fact[["country_id","disease_id","year","cases"]]
cases_fact.to_sql("reported_cases", conn, if_exists="append", index=False)

# Vaccine Introduction
intro_fact = intro.rename(columns={"countryname":"country"})
intro_fact["country_id"] = intro_fact["iso3"].map(country_map)
# ⚠ vaccine mapping may need refinement (for now leave null if not matchable)
intro_fact["vaccine_id"] = None
intro_fact = intro_fact[["country_id","vaccine_id","year","description","introduced"]]
intro_fact.to_sql("vaccine_introduction", conn, if_exists="append", index=False)



# Vaccine Schedule
sched_fact = schedule.rename(columns={"countryname":"country"})
sched_fact["country_id"] = sched_fact["iso3"].map(country_map)
sched_fact["vaccine_id"] = sched_fact["vaccinecode"].map(vaccine_map)
sched_fact = sched_fact[[
    "country_id","vaccine_id","year","schedulerounds","targetpop","targetpop_description",
    "geoarea","ageadministered","sourcecomment"
]]
sched_fact.to_sql("vaccine_schedule", conn, if_exists="append", index=False)

conn.commit()
conn.close()
print("🎉 All data loaded into vaccination.db (normalized)")
