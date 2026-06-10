#!/usr/bin/env python3
"""Convert Caltrain CSV schedules to compact JSON for the iOS app.

Times are stored as minutes since midnight (e.g. 5:52 = 352).
Times past midnight use values > 1440 (e.g. 24:05 = 1445).
Missing stops are null.

Usage:
    python3 tools/convert_schedule.py
    python3 tools/convert_schedule.py <data_dir> <output_file>
"""

import csv
import json
import re
import sys
from datetime import date
from pathlib import Path

def load_special_dates(data_dir):
    """Parse special dates from holiday_service.js in data_dir."""
    today = date.today().isoformat()
    js_file = data_dir / "holiday_service.js"
    special = {}
    with open(js_file) as f:
        for line in f:
            line = line.strip()
            if line.startswith("//") or line.startswith("/*"):
                continue
            m = re.match(r"'(\d{4}-\d{2}-\d{2})':\s*(\d+),?\s*(?://.*)?$", line)
            if m and m.group(1) >= today:
                special[m.group(1)] = int(m.group(2))
    return special

def time_to_minutes(t):
    if not t or not t.strip():
        return None
    parts = t.strip().split(":")
    return int(parts[0]) * 60 + int(parts[1])


def read_csv(path):
    with open(path, newline="") as f:
        rows = list(csv.reader(f))
    train_ids = [int(x) for x in rows[0][1:] if x.strip()]
    stations = []
    trains = {tid: [] for tid in train_ids}
    for row in rows[1:]:
        if not row or not row[0].strip():
            continue
        station = row[0].strip()
        stations.append(station)
        times = row[1:]
        for i, tid in enumerate(train_ids):
            val = times[i] if i < len(times) else ""
            trains[tid].append(time_to_minutes(val))
    return stations, trains


def main():
    data_dir = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("../next-caltrain-pwa/data")
    out_file = Path(sys.argv[2]) if len(sys.argv) > 2 else Path("assets/schedule.json")

    special_dates = load_special_dates(data_dir)
    print(f"Loaded {len(special_dates)} special dates from holiday_service.js")

    north_stations, weekday_north = read_csv(data_dir / "weekday_north.csv")
    south_stations, weekday_south = read_csv(data_dir / "weekday_south.csv")
    _, weekend_north = read_csv(data_dir / "weekend_north.csv")
    _, weekend_south = read_csv(data_dir / "weekend_south.csv")
    _, modified_north = read_csv(data_dir / "modified_north.csv")
    _, modified_south = read_csv(data_dir / "modified_south.csv")

    schedule = {
        "specialDates": special_dates,
        "northStops": north_stations,
        "southStops": south_stations,
        "northWeekday":  {str(k): v for k, v in weekday_north.items()},
        "northWeekend":  {str(k): v for k, v in weekend_north.items()},
        "northModified": {str(k): v for k, v in modified_north.items()},
        "southWeekday":  {str(k): v for k, v in weekday_south.items()},
        "southWeekend":  {str(k): v for k, v in weekend_south.items()},
        "southModified": {str(k): v for k, v in modified_south.items()},
    }

    out_file.parent.mkdir(parents=True, exist_ok=True)
    with open(out_file, "w") as f:
        json.dump(schedule, f, separators=(",", ":"))

    size = out_file.stat().st_size
    print(f"Written to {out_file} ({size:,} bytes)")


if __name__ == "__main__":
    main()
