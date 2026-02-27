"""
This script converts a local Excel (XLSX) file into a JSON file.
Each worksheet becomes a top-level JSON key (sheet name), with values as row dictionaries.

Usage:
    python xlsx_to_json.py -f "Path/To/Input.xlsx" -o "Path/To/Output.json"

Arguments:
    -f, --file      (required)  Path to the local XLSX file
    -o, --output    (required)  Path to save the output JSON file
"""

import argparse
import pandas as pd
import os
import json
import sys


def validate_file_path(file_path: str) -> None:
    if not os.path.exists(file_path):
        raise FileNotFoundError(f"Input file does not exist: {file_path}")
    if not file_path.lower().endswith(".xlsx"):
        raise ValueError("Input file must be an .xlsx Excel file")


def validate_output_path(output_path: str) -> None:
    out_dir = os.path.dirname(output_path) or "."
    if not os.path.exists(out_dir):
        raise FileNotFoundError(f"Output directory does not exist: {out_dir}")
    if not output_path.lower().endswith(".json"):
        raise ValueError("Output path must end with .json")
    if not os.access(out_dir, os.W_OK):
        raise PermissionError(f"No write permission to output directory: {out_dir}")


def convert_xlsx_to_json(input_file: str, output_file: str) -> None:
    print(f"Reading local Excel file: {input_file}")

    # Read all sheets, preserving literal "NA", "N/A", etc.
    excel_data = pd.read_excel(
        input_file,
        sheet_name=None,
        keep_default_na=False  # Keeps "NA" as string, not NaN
    )

    # Convert each sheet's DataFrame to a list of row dictionaries
    excel_dict = {
        sheet_name: df.to_dict(orient="records")
        for sheet_name, df in excel_data.items()
    }

    # Write flat JSON to output file
    with open(output_file, "w") as f:
        json.dump(excel_dict, f, indent=2, allow_nan=False)

    print(f"✅ JSON saved to: {output_file}")


def main():
    parser = argparse.ArgumentParser(description="Convert local XLSX file to JSON.")
    parser.add_argument("-f", "--file", required=True, help="Path to input XLSX file")
    parser.add_argument("-o", "--output", required=True, help="Path to output JSON file")
    args = parser.parse_args()

    try:
        validate_file_path(args.file)
        validate_output_path(args.output)
        convert_xlsx_to_json(args.file, args.output)
    except Exception as e:
        print(f"❌ ERROR: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
