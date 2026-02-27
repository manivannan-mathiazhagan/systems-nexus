import argparse
import requests
import sys
import os
from urllib.parse import quote

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
    output_path = output_path.strip()
    if not output_path.lower().endswith(".json"):
        raise ValueError("Output path must be a .json file")
    output_dir = os.path.dirname(output_path) or "."
    if not os.path.exists(output_dir):
        raise ValueError(f"Output directory does not exist: {output_dir}")
    if not os.access(output_dir, os.W_OK):
        raise PermissionError(f"No write permission to output directory: {output_dir}")


def main():
    parser = argparse.ArgumentParser(description="Download Excel file from SharePoint and save as JSON.")
    parser.add_argument("-s", "--site-name", required=True, help="SharePoint site name (exact match)")
    parser.add_argument("-f", "--file-path", required=True, help="SharePoint file path (must start with 'Biostats/' or 'BSP/')")
    parser.add_argument("-o", "--output", required=True, help="Output file path (.json)")
    parser.add_argument("-k", "--api-key", required=False, help="API key for BSP Back End server.")
    args = parser.parse_args()

    # Validate inputs
    try:
        validate_site_name(args.site_name)
        file_path = args.file_path.strip().replace("\\", "/")
        validate_file_path(file_path)
        validate_output_path(args.output)
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

    # Encode query parameters
    encoded_site_name = quote(args.site_name.strip())
    encoded_file_path = quote(file_path)

    url = f"{BASE_URL}/sharepoint/spreadsheet/json"
    params = {
        "site_name": encoded_site_name,
        "file_path": encoded_file_path,
    }
    headers = {
        "Authorization": f"Bearer {args.api_key or API_KEY}",
        "Accept": "application/json"
    }

    print("🔄 Downloading SharePoint Excel as JSON...")
    try:
        response = requests.get(url, params=params, headers=headers)
        response.raise_for_status()

        with open(args.output, "w", encoding="utf-8") as f:
            f.write(response.text)

        print(f"✅ JSON saved to: {args.output}")

    except requests.HTTPError as e:
        print("❌ Error:", e)
        print("🔎 Status Code:", response.status_code)
        print("🔎 Response:", response.text)
        sys.exit(1)
    except Exception as e:
        print("❌ Unexpected Error:", e)
        sys.exit(1)


if __name__ == "__main__":
    main()
