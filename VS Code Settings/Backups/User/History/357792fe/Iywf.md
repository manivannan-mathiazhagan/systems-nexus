# Veristat TLF Packager – User Guide

## 1. Introduction

The **Veristat TLF Packager** automates the process of extracting table titles and bookmarks from **RTF**, **DOCX**, and **PDF** files and consolidates them into a single, **bookmarked PDF** with a **clickable Table of Contents (TOC)**.

### Tool Variants

- **CLI Script**: `TLF_Packager.py` (can also be called via SAS macro)
- **GUI Tool**: `Veristat_TLF_Packager.exe` (interactive version)


## 2. Option 1: Python CLI & SAS Macro

### 2.1 Requirements

- Python 3.x installed  
- Microsoft Word installed  
- Required Python packages:
  - `openpyxl`
  - `pymupdf`
  - `python-docx`
  - `pywin32`


### 2.2 Parameters

| Position | Parameter               | Function                                                  | Default | Example                                |
|----------|--------------------------|------------------------------------------------------------|---------|----------------------------------------|
| 1        | `input_folder`           | Path containing RTF/DOCX/PDF files                         | —       | `"C:\TLFs"`                            |
| 2        | `output_pdf_name`        | Name of the final merged PDF                               | —       | `merged.pdf`                           |
| 3        | `delete_pdfs`            | Delete converted PDFs after merge (Y/N)                    | Y       | `Y`                                    |
| 4        | `wait_for_user_approval` | Pause after Excel export for user review (Y/N)             | Y       | `N`                                    |

> 📌 **Note**: Enclose folder paths in quotes if they contain spaces.


### 2.3 Running the Script via Command Prompt (CLI)

#### Step 1: Open Command Prompt

- Press `Windows + R`, type `cmd`, and press **Enter**  
  *or*  
- Click **Start**, search for **Command Prompt**, and open it.



#### ✅ Option A: Navigate to Script Folder

**Step 2A**: Switch to the correct drive:
P: 

**Step 3A**: Navigate to script folder:

cd "Biostatistics\PDF Tool"

**Step 4A**: Run the script:

python TLF_Packager.py "P:\Biostatistics\PDF Tool\Testing Veristat PDF\Chk 1" "Final_TLF_Output.pdf" Y Y



**Explanation of Parameters**

- `python`: Calls the Python interpreter.
- `TLF_Packager.py`: The script that performs the TLF packaging.
- `"P:\..."`: Full path to input folder containing `.RTF`, `.DOCX`, `.PDF` files.
- `"Final_TLF_Output.pdf"`: Name of the final merged PDF file.
- `Y` (3rd param): Delete intermediate PDFs (`Y` = Yes, `N` = No).
- `Y` (4th param): Pause after Excel is generated for user review (`Y` = Yes, `N` = No).

If `wait_for_user_approval = Y`, the script will generate: TLF_Bookmarks_Worksheet.xlsx

> You can use this Excel file to:
> - Reorder the outputs
> - Remove any unwanted files
> - Edit/customize bookmark titles  
> Then save the Excel and return to the prompt to continue.


**To skip the Excel review step**, use:

python TLF_Packager.py "P:\Biostatistics\PDF Tool\Testing Veristat PDF\Chk 1" "Final_TLF_Output.pdf" Y N


#### ✅ Option B: Use Full Script Path (No Need to Navigate)

You can skip directory navigation and run the script directly using full path:

python "P:\Biostatistics\PDF Tool\TLF_Packager.py" "P:\Biostatistics\PDF Tool\Testing Veristat PDF\Chk 1" "Final_TLF_Output.pdf" Y Y


### 2.4 Calling from SAS Macro: `%TLF_Packager`

This macro enables SAS users to invoke the `TLF_Packager.py` script from within SAS.

| Parameter       | Function                                                       | Default | Example                                                 | Python Param Position |
|----------------|-----------------------------------------------------------------|---------|---------------------------------------------------------|------------------------|
| `input_path`     | Folder path with `.RTF`, `.DOCX`, or `.PDF` files             | —       | `P:\Biostatistics\PDF Tool\KAR-012\TLF\Tables`           | 1                      |
| `delete_pdfs`    | Y/N – Delete intermediate PDFs after merging                  | Y       | `Y`                                                      | 3                      |
| `wait_approval`  | Y/N – Pause for Excel review before generating final PDF      | Y       | `Y`                                                      | 4                      |

**Output Filename**:  
Automatically generated using folder name + timestamp, e.g.: Tables_20250709_113045.pdf


**Dependencies**:

- Python installed
- Microsoft Word installed
- Script located at: P:\Biostatistics\PDF Tool\TLF_Packager.py


### CLI vs SAS Macro – Key Differences

| Feature               | CLI Version              | SAS Macro Version                                 |
|------------------------|--------------------------|----------------------------------------------------|
| Interface              | Command-line              | Integrated in SAS                                  |
| Automation             | Manual trigger            | Seamless within table programs                     |
| User Interaction       | Manual Excel review       | Optional pause via macro param                     |
| Ideal for              | Technical users           | Production pipelines                               |


## 3. Option 2: GUI Tool

### 3.1 Launching the GUI

Double-click on the executable: Veristat_TLF_Packager.exe


> 💡 No Python installation or config required when using the EXE.


### 3.2 Benefits of GUI Tool vs CLI/Macro

| Feature                  | Advantage                                                     |
|--------------------------|---------------------------------------------------------------|
| Interactive Preview      | Instantly view titles before merge                            |
| Reordering Buttons       | Use Move Up / Move Down to reorder outputs                    |
| Inline Editing           | Modify titles directly inside the tool                        |
| No Command Line          | Fully point-and-click interface                               |
| Real-Time Validation     | Detects unreadable or missing files instantly                 |
| Standalone EXE           | Delivered as `.exe`; no Python or external libraries needed   |

> ✅ Recommended for non-programmers or reviewers who prefer visual control.


## 4. Feature Comparison at a Glance

| Feature             | CLI / SAS Macro      | GUI Tool              |
|---------------------|----------------------|------------------------|
| Ideal Use           | Automation           | Visual Review          |
| Bookmark Editing    | Excel                | Inline Editing         |
| Interactivity       | Low                  | High                   |
| Ease of Use         | Requires setup       | Plug-and-Play          |
| Excel Pause         | Optional             | Built-in               |


## 5. Setup Instructions

### 5.1 Install Required Python Packages (for CLI users)

Open Command Prompt and run: python -m pip install openpyxl pymupdf python-docx pywin32


**What these do:**

- `openpyxl`: Excel file handling
- `pymupdf`: PDF reading/writing, bookmarks
- `python-docx`: DOCX content reading
- `pywin32`: MS Word automation for DOCX/RTF to PDF conversion

> ⚠️ If `'pip' is not recognized`, refer to Appendix A or contact IT for setup.


### 5.2 Notes

- Microsoft Word must be installed to convert `.RTF` or `.DOCX` to PDF.


## 6. File Locations

| Component         | Location                                                               |
|------------------|-------------------------------------------------------------------------|
| Python Script     | `P:\Biostatistics\PDF Tool\TLF_Packager.py`                             |
| SAS Macro         | `P:\Biostatistics\PDF Tool\TLF_Packager.sas`                            |
| GUI EXE Tool      | `P:\Biostatistics\PDF Tool\GUI Tool\Veristat_TLF_Packager.exe`          |











