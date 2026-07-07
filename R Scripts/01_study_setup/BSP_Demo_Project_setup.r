# =============================================================================
# File    : BSP_Demo_Project_setup.R
# Purpose : Study-specific setup for BSP Demo Project
# =============================================================================

# -----------------------------------------------------------------------------
# 1. Load global setup
# -----------------------------------------------------------------------------

source(
  "P:/BSP_LocalDev/Manivannan.Mathialag/zzzz_My_SAS_Files/My GitHub/systems-nexus/R Scripts/00_global_setup/global_setup.R"
)


# -----------------------------------------------------------------------------
# 2. Load required packages
# -----------------------------------------------------------------------------

setup_packages(c(
  "haven",
  "dplyr",
  "readxl",
  "openxlsx",
  "stringr",
  "purrr",
  "tidyr"
))


# -----------------------------------------------------------------------------
# 3. Study-level paths
# -----------------------------------------------------------------------------

STUDY_ROOT <- "P:/Projects/Veristat/BSP Demo Project/BSP"

RAW_VER  <- "raw_v20250618"
SDTM_VER <- "sdtm_v20250630"
ADAM_VER <- "adam_v20250630"

RAW_PATH  <- file.path(STUDY_ROOT, "SASDATA", RAW_VER)
SDTM_PATH <- file.path(RAW_PATH, SDTM_VER)
ADAM_PATH <- file.path(SDTM_PATH, ADAM_VER)


setup_libraries(
  raw    = RAW_PATH,
  sdtm   = SDTM_PATH,
  adam   = ADAM_PATH,

  output = file.path(STUDY_ROOT, "04_Log_outputs"),
  logs   = file.path(STUDY_ROOT, "04_Log_outputs"),

  extra = list(
    VALIDATION = file.path(STUDY_ROOT, "04_Log_outputs", "validation"),
    COMPARE    = file.path(STUDY_ROOT, "04_Log_outputs", "compare"),
    REPORTS    = file.path(STUDY_ROOT, "04_Log_outputs", "reports"),
    SPECS      = file.path(STUDY_ROOT, "TLF_SPECS")
  ),

  create_missing = TRUE

)


# -----------------------------------------------------------------------------
# 5. WORK folder
# -----------------------------------------------------------------------------

setup_work(
  work_base = file.path(STUDY_ROOT, "04_Log_outputs", "work")
)


# -----------------------------------------------------------------------------
# 6. Load reusable functions
# -----------------------------------------------------------------------------

load_all_functions(
  "P:/BSP_LocalDev/Manivannan.Mathialag/zzzz_My_SAS_Files/My GitHub/systems-nexus/R Scripts/03_functions"
)


# -----------------------------------------------------------------------------
# 7. Study setup completion message
# -----------------------------------------------------------------------------

message("Study setup completed successfully.")
message("Study       : ", STUDY)
message("Sponsor     : ", SPONSOR)
message("RAW version : ", RAW_VER)
message("SDTM version: ", SDTM_VER)
message("ADAM version: ", ADAM_VER)