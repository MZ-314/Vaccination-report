from pathlib import Path
import pandas as pd

# Always use relative paths (portable!)
RAW = Path("data/raw")

files = {
    "coverage": RAW / "coverage-data.xlsx",
    "incidence": RAW / "incidence-rate-data.xlsx",
    "cases": RAW / "reported-cases-data.xlsx",
    "intro": RAW / "vaccine-introduction-data.xlsx",
    "schedule": RAW / "vaccine-schedule-data.xlsx"
}

for name, path in files.items():
    print(f"\n=== {name.upper()} ===")
    try:
        df = pd.read_excel(path)
        print("Shape:", df.shape)
        print("Columns:", df.columns.tolist())
        print(df.head(3).to_markdown())  # first 3 rows as a nice table
    except Exception as e:
        print(f"Error reading {path}: {e}")
