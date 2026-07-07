# =============================================================================
# Program : v_dm.R
# Purpose : Create QC SDTM DM dataset in R and compare with production SDTM.DM
# =============================================================================

source("P:/BSP_LocalDev/Manivannan.Mathialag/zzzz_My_SAS_Files/My GitHub/systems-nexus/R Scripts/01_study_setup/BSP_Demo_Project_setup.R")

# -----------------------------------------------------------------------------
# 1. Read production SDTM DM
# -----------------------------------------------------------------------------

prod_dm <- read_sas_data(SDTM, "dm")

# -----------------------------------------------------------------------------
# 2. Read RAW source datasets
#    UPDATE these dataset names based on actual raw folder
# -----------------------------------------------------------------------------

raw_dm <- read_sas_data(RAW, "dm")     # example only
# raw_ds <- read_sas_data(RAW, "ds")   # if needed
# raw_ex <- read_sas_data(RAW, "ex")   # if needed

# -----------------------------------------------------------------------------
# 3. Create QC DM
#    UPDATE variable mappings based on raw data
# -----------------------------------------------------------------------------

qc_dm <- raw_dm |>
  dplyr::transmute(
    STUDYID  = as.character(STUDYID),
    DOMAIN   = "DM",
    USUBJID  = as.character(USUBJID),
    SUBJID   = as.character(SUBJID),

    RFSTDTC  = as.character(RFSTDTC),
    RFENDTC  = as.character(RFENDTC),
    RFXSTDTC = as.character(RFXSTDTC),
    RFXENDTC = as.character(RFXENDTC),

    RFICDTC  = as.character(RFICDTC),
    RFPENDTC = as.character(RFPENDTC),

    DTHDTC   = as.character(DTHDTC),
    DTHFL    = as.character(DTHFL),

    SITEID   = as.character(SITEID),
    AGE      = as.numeric(AGE),
    AGEU     = as.character(AGEU),
    SEX      = as.character(SEX),
    RACE     = as.character(RACE),
    ETHNIC   = as.character(ETHNIC),
    ARMCD    = as.character(ARMCD),
    ARM      = as.character(ARM),
    ACTARMCD = as.character(ACTARMCD),
    ACTARM   = as.character(ACTARM),
    COUNTRY  = as.character(COUNTRY)
  )

# -----------------------------------------------------------------------------
# 4. Align QC DM variable order with production DM
# -----------------------------------------------------------------------------

prod_vars <- names(prod_dm)

qc_dm <- qc_dm |>
  dplyr::select(dplyr::any_of(prod_vars))

# Add missing production variables to QC as NA
missing_in_qc <- setdiff(prod_vars, names(qc_dm))

for (v in missing_in_qc) {
  qc_dm[[v]] <- NA
}

qc_dm <- qc_dm[, prod_vars]

# -----------------------------------------------------------------------------
# 5. Sort both datasets
# -----------------------------------------------------------------------------

prod_dm_s <- prod_dm |>
  dplyr::arrange(USUBJID)

qc_dm_s <- qc_dm |>
  dplyr::arrange(USUBJID)

# -----------------------------------------------------------------------------
# 6. Compare metadata
# -----------------------------------------------------------------------------

metadata_compare <- data.frame(
  VARIABLE = union(names(prod_dm_s), names(qc_dm_s)),
  IN_PROD = union(names(prod_dm_s), names(qc_dm_s)) %in% names(prod_dm_s),
  IN_QC   = union(names(prod_dm_s), names(qc_dm_s)) %in% names(qc_dm_s)
)

# -----------------------------------------------------------------------------
# 7. Compare records by USUBJID
# -----------------------------------------------------------------------------

prod_key <- prod_dm_s |> dplyr::select(USUBJID)
qc_key   <- qc_dm_s   |> dplyr::select(USUBJID)

records_only_in_prod <- dplyr::anti_join(prod_key, qc_key, by = "USUBJID")
records_only_in_qc   <- dplyr::anti_join(qc_key, prod_key, by = "USUBJID")

# -----------------------------------------------------------------------------
# 8. Cell-by-cell compare
# -----------------------------------------------------------------------------

common_vars <- intersect(names(prod_dm_s), names(qc_dm_s))
compare_vars <- setdiff(common_vars, "USUBJID")

prod_long <- prod_dm_s |>
  dplyr::select(dplyr::all_of(c("USUBJID", compare_vars))) |>
  tidyr::pivot_longer(
    cols = -USUBJID,
    names_to = "VARIABLE",
    values_to = "PROD_VALUE"
  ) |>
  dplyr::mutate(PROD_VALUE = as.character(PROD_VALUE))

qc_long <- qc_dm_s |>
  dplyr::select(dplyr::all_of(c("USUBJID", compare_vars))) |>
  tidyr::pivot_longer(
    cols = -USUBJID,
    names_to = "VARIABLE",
    values_to = "QC_VALUE"
  ) |>
  dplyr::mutate(QC_VALUE = as.character(QC_VALUE))

value_compare <- dplyr::full_join(
  prod_long,
  qc_long,
  by = c("USUBJID", "VARIABLE")
) |>
  dplyr::filter(
    dplyr::coalesce(PROD_VALUE, "") != dplyr::coalesce(QC_VALUE, "")
  )

# -----------------------------------------------------------------------------
# 9. Summary
# -----------------------------------------------------------------------------

summary_df <- data.frame(
  CHECK = c(
    "Production DM records",
    "QC DM records",
    "Records only in production",
    "Records only in QC",
    "Value differences",
    "Variables missing in QC",
    "Variables missing in production"
  ),
  COUNT = c(
    nrow(prod_dm_s),
    nrow(qc_dm_s),
    nrow(records_only_in_prod),
    nrow(records_only_in_qc),
    nrow(value_compare),
    sum(!metadata_compare$IN_QC),
    sum(!metadata_compare$IN_PROD)
  )
)

# -----------------------------------------------------------------------------
# 10. Write outputs
# -----------------------------------------------------------------------------

out_file <- file.path(COMPARE, "v_dm_compare_report.xlsx")
qc_out   <- file.path(VALIDATION, "qc_dm_created_by_r.xpt")

openxlsx::write.xlsx(
  list(
    Summary = summary_df,
    Metadata_Compare = metadata_compare,
    Records_Only_In_Prod = records_only_in_prod,
    Records_Only_In_QC = records_only_in_qc,
    Value_Differences = value_compare,
    QC_DM = qc_dm_s
  ),
  file = out_file,
  overwrite = TRUE
)

haven::write_xpt(qc_dm_s, qc_out)

message("DM QC creation and compare completed.")
message("Compare report: ", out_file)
message("QC DM XPT     : ", qc_out)