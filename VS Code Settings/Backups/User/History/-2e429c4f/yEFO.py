import argparse
import requests
import sys
import os
import pandas as pd
import json

BASE_URL = "https://bsp-back-end-v1.calmpond-6c1a3e6f.eastus2.azurecontainerapps.io"
API_KEY = "7ebq71mikBQgFXuPL2mPP7jJFH9DRXqK"

def validate_site_name(site_name: str) -> None:
    if not site_name:
        raise ValueError("Site name is required.")

def validate_file_path(file_path: str) -> None:
    file_path = file_path.strip().replace("\\", "/")
    if not file_path.startswith("Biostats/") and not file_path.startswith("BSP/"):
        raise ValueError("File path must start with 'Biostats/' or 'BSP/'")
    if not os.path.splitext(file_path)[1]:
        raise ValueError("File path must include a file name with extension (e.g., .xlsx)")

def validate_output_path(output_path: str) -> None:
    if not output_path.lower().endswith(".json"):
        raise ValueError("Output path must be a .json file.")
    out_dir = os.path.dirname(output_path) or "."
    if not os.path.exists(out_dir):
        raise FileNotFoundError(f"Output directory does not exist: {out_dir}")
    if not os.access(out_dir, os.W_OK):
        raise PermissionError(f"No write permission to: {out_dir}")

def fetch_excel(site_name, file_path, api_key):
    url = f"{BASE_URL}/sharepoint/spreadsheet"
    headers = {"Authorization": f"Bearer {api_key or API_KEY}"}
    params = {"site_name": site_name, "file_path": file_path}
    response = requests.get(url, headers=headers, params=params, stream=True)
    response.raise_for_status()
    return response.content

def convert_excel_to_json(excel_bytes, output_path):
    df_dict = pd.read_excel(pd.io.common.BytesIO(excel_bytes), sheet_name=None, dtype=str)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(df_dict, f, ensure_ascii=False, indent=2)

def main():
    parser = argparse.ArgumentParser(description="Download Excel from SharePoint and convert to JSON")
    parser.add_argument("-s", "--site-name", required=True)
    parser.add_argument("-f", "--file-path", required=True)
    parser.add_argument("-o", "--output", required=True)
    parser.add_argument("-k", "--api-key", required=False)
    args = parser.parse_args()

    try:
        validate_site_name(args.site_name)
        validate_file_path(args.file_path)
        validate_output_path(args.output)
        excel_bytes = fetch_excel(args.site_name.strip(), args.file_path.strip().replace("\\", "/"), args.api_key or API_KEY)
        convert_excel_to_json(excel_bytes, args.output.strip())
        print(f"✅ Saved as JSON: {args.output}")
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
