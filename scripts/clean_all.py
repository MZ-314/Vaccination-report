import pandas as pd
import numpy as np
import re
import pycountry
from pathlib import Path

RAW = Path("data/raw")
CLEAN = Path("data/clean")
CLEAN.mkdir(parents=True, exist_ok=True)

def clean_colnames(df):
    """Standardize column names"""
    df = df.rename(columns=lambda c: re.sub(r'\s+', '_', str(c).strip().lower()))
    return df

def parse_percent(x):
    """Convert messy percentage strings into floats"""
    if pd.isna(x): return np.nan
    s = str(x).strip()
    if s in ['-', '—', 'na', 'n/a', 'not available', 'not reported', '']:
        return np.nan
    if '%' in s:
        try: return float(s.replace('%','').strip())
        except: return np.nan
    if s.startswith("<"):
        try: return float(s[1:]) / 2   # e.g. "<1" → 0.5
        except: return np.nan
    try: return float(s)
    except: return np.nan

def iso3_from_name(name):
    """Map country name → ISO3"""
    if pd.isna(name): return None
    try:
        return pycountry.countries.lookup(name).alpha_3
    except:
        return None

# --- Cleaning functions for each dataset ---

def clean_coverage():
    df = pd.read_excel(RAW/"coverage-data.xlsx")
    df = clean_colnames(df)

    # Fix column names if needed
    if "dodge" in df.columns:
        df = df.rename(columns={"dodge": "doses_administered"})
    if "doses" in df.columns:
        df = df.rename(columns={"doses": "doses_administered"})
    if "code" in df.columns:
        df = df.rename(columns={"code": "iso3"})
    if "name" in df.columns:
        df = df.rename(columns={"name": "country"})

    # Add ISO3 if missing
    if "iso3" not in df.columns and "country" in df.columns:
        df["iso3"] = df["country"].apply(iso3_from_name)

    # Parse numeric fields
    if "coverage" in df.columns:
        df["coverage_percent"] = df["coverage"].apply(parse_percent)
    if "year" in df.columns:
        df["year"] = pd.to_numeric(df["year"], errors="coerce").astype("Int64")

    df.to_csv(CLEAN/"coverage_clean.csv", index=False)
    print("✔ coverage cleaned:", df.shape)
    return df

def clean_incidence():
    df = pd.read_excel(RAW/"incidence-rate-data.xlsx")
    df = clean_colnames(df)
    if "code" in df.columns:
        df = df.rename(columns={"code": "iso3"})
    if "name" in df.columns:
        df = df.rename(columns={"name": "country"})
    df["incidence_rate"] = pd.to_numeric(df.get("incidence_rate"), errors="coerce")
    df["year"] = pd.to_numeric(df["year"], errors="coerce").astype("Int64")
    df.to_csv(CLEAN/"incidence_clean.csv", index=False)
    print("✔ incidence cleaned:", df.shape)
    return df

def clean_reported_cases():
    df = pd.read_excel(RAW/"reported-cases-data.xlsx")
    df = clean_colnames(df)
    if "code" in df.columns:
        df = df.rename(columns={"code": "iso3"})
    if "name" in df.columns:
        df = df.rename(columns={"name": "country"})
    df["cases"] = pd.to_numeric(df.get("cases"), errors="coerce").astype("Int64")
    df["year"] = pd.to_numeric(df["year"], errors="coerce").astype("Int64")
    df.to_csv(CLEAN/"reported_cases_clean.csv", index=False)
    print("✔ reported cases cleaned:", df.shape)
    return df

def clean_intro():
    df = pd.read_excel(RAW/"vaccine-introduction-data.xlsx")
    df = clean_colnames(df)
    if "iso_3_code" in df.columns:
        df = df.rename(columns={"iso_3_code": "iso3"})
    if "country_name" in df.columns:
        df = df.rename(columns={"country_name": "country"})
    df["year"] = pd.to_numeric(df["year"], errors="coerce").astype("Int64")
    df["introduced"] = df["intro"].astype(str).str.lower().map(
        {"yes": True, "y": True, "1": True, "true": True}
    ).fillna(False)
    df.to_csv(CLEAN/"vaccine_introduction_clean.csv", index=False)
    print("✔ vaccine introduction cleaned:", df.shape)
    return df

def clean_schedule():
    df = pd.read_excel(RAW/"vaccine-schedule-data.xlsx")
    df = clean_colnames(df)
    if "iso_3_code" in df.columns:
        df = df.rename(columns={"iso_3_code": "iso3"})
    if "country_name" in df.columns:
        df = df.rename(columns={"country_name": "country"})
    df["year"] = pd.to_numeric(df["year"], errors="coerce").astype("Int64")
    df.to_csv(CLEAN/"vaccine_schedule_clean.csv", index=False)
    print("✔ vaccine schedule cleaned:", df.shape)
    return df

if __name__ == "__main__":
    clean_coverage()
    clean_incidence()
    clean_reported_cases()
    clean_intro()
    clean_schedule()
    print("🎉 All datasets cleaned and saved in data/clean/")
