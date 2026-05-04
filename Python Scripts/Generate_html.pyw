# ============================================================
# Script : generate_bsp_html.py
# Purpose: Generate a single HTML page for BSP Study Setup Flow
# Output : BSP_Folder_Structure_Flow.html
# Note   : HTML is generated in the same folder as this .py file
# ============================================================

from pathlib import Path

SCRIPT_DIR = Path(__file__).resolve().parent
OUTPUT_HTML = SCRIPT_DIR / "BSP_Folder_Structure_Flow.html"

html_text = r"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>BSP Study Setup Flow and Folder Structure</title>

<style>
* {
    box-sizing: border-box;
}

body {
    font-family: "Segoe UI", Arial, Helvetica, sans-serif;
    margin: 0;
    background: #f4f6f8;
    color: #222;
}

header {
    background: #1f3b57;
    color: white;
    padding: 24px 36px;
}

header h1 {
    margin: 0;
    font-size: 28px;
}

header p {
    margin: 8px 0 0 0;
    color: #dbe8f5;
}

section {
    background: white;
    margin: 24px 36px;
    padding: 24px;
    border-radius: 12px;
    box-shadow: 0 2px 8px rgba(0,0,0,0.08);
}

h2 {
    margin-top: 0;
    color: #1f3b57;
    border-bottom: 2px solid #e5edf5;
    padding-bottom: 8px;
}

h3 {
    color: #243b53;
    margin-top: 22px;
}

a {
    color: inherit;
    text-decoration: none;
}

/* ===========================
   High-Level Flow Diagram
   =========================== */
.flow-wrap {
    display: flex;
    flex-direction: column;
    align-items: center;
    gap: 18px;
    padding: 10px;
}

.study-box {
    background: #1f3b57;
    color: white;
    padding: 18px 44px;
    border-radius: 14px;
    font-size: 22px;
    font-weight: 700;
    text-align: center;
    min-width: 260px;
    box-shadow: 0 3px 8px rgba(0,0,0,0.18);
}

.connector {
    width: 2px;
    height: 30px;
    background: #8798ad;
}

.flow-grid {
    display: grid;
    grid-template-columns: repeat(4, minmax(190px, 1fr));
    gap: 18px;
    width: 100%;
}

.flow-card {
    border: 2px solid #d9e2ec;
    border-radius: 14px;
    background: #fbfdff;
    padding: 18px;
    text-align: center;
    min-height: 148px;
    transition: transform 0.15s ease, box-shadow 0.15s ease, border-color 0.15s ease;
}

.flow-card:hover {
    transform: translateY(-3px);
    box-shadow: 0 4px 12px rgba(0,0,0,0.12);
    border-color: #1f3b57;
}

.flow-card .title {
    font-size: 18px;
    font-weight: 700;
    color: #1f3b57;
    margin-bottom: 10px;
}

.flow-card .desc {
    font-size: 14px;
    color: #444;
    line-height: 1.45;
}

/* ===========================
   Explorer-style Folder Tree
   =========================== */
.folder-panel {
    background: #fbfdff;
    border: 1px solid #d9e2ec;
    border-radius: 10px;
    padding: 16px;
    overflow-x: auto;
}

.tree {
    font-size: 14px;
    line-height: 1.6;
    min-width: 520px;
}

.tree details {
    margin-left: 20px;
}

.tree details.root {
    margin-left: 0;
}

.tree summary {
    cursor: pointer;
    list-style: none;
    padding: 3px 6px;
    border-radius: 6px;
    white-space: nowrap;
}

.tree summary::-webkit-details-marker {
    display: none;
}

.tree summary::before {
    content: "📁 ";
}

.tree details[open] > summary::before {
    content: "📂 ";
}

.tree .folder-line {
    margin-left: 20px;
    padding: 3px 6px;
    white-space: nowrap;
}

.tree .folder-line::before {
    content: "📁 ";
}

.tree .file-line {
    margin-left: 20px;
    padding: 3px 6px;
    white-space: nowrap;
}

.tree .file-line::before {
    content: "📄 ";
}

.tree .comment-line {
    margin-left: 20px;
    padding: 3px 6px;
    white-space: nowrap;
    color: #666;
    font-style: italic;
}

.tree .comment-line::before {
    content: "💬 ";
}

.tree .bsp > summary {
    background: #e8f1ff;
    color: #005eb8;
    font-weight: 700;
    border: 1px solid #b8d4ff;
}

.tree .muted {
    color: #666;
    font-size: 12px;
}

.tree .example {
    display: block;
    margin-left: 24px;
    color: #666;
    font-size: 12px;
    font-family: Consolas, "Courier New", monospace;
}

.note {
    background: #fff8e1;
    border-left: 5px solid #f0b429;
    padding: 12px 14px;
    margin: 12px 0;
}

.grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
    gap: 14px;
}

.info-card {
    border: 1px solid #d9e2ec;
    border-radius: 10px;
    padding: 14px;
    background: #fbfdff;
}

.info-card b {
    color: #1f3b57;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 12px;
}

th {
    background: #1f3b57;
    color: white;
    text-align: left;
    padding: 10px;
}

td {
    border: 1px solid #d9e2ec;
    padding: 9px;
    vertical-align: top;
}

.code-block {
    background: #0f172a;
    color: #e5e7eb;
    padding: 16px;
    border-radius: 10px;
    overflow-x: auto;
    font-family: Consolas, "Courier New", monospace;
    font-size: 13px;
    line-height: 1.5;
    white-space: pre;
}

.path-block {
    background: #f8fafc;
    border: 1px solid #d9e2ec;
    border-radius: 8px;
    padding: 10px 12px;
    font-family: Consolas, "Courier New", monospace;
    font-size: 13px;
    overflow-x: auto;
}

.small {
    color: #666;
    font-size: 13px;
}

.footer {
    text-align: center;
    color: #666;
    font-size: 12px;
    padding: 24px;
}

@media (max-width: 980px) {
    .flow-grid {
        grid-template-columns: repeat(2, minmax(190px, 1fr));
    }
}

@media (max-width: 560px) {
    .flow-grid {
        grid-template-columns: 1fr;
    }

    section {
        margin: 16px;
    }

    header {
        padding: 20px;
    }
}
</style>
</head>

<body>

<header>
    <h1>BSP Study Setup Flow and Folder Structure</h1>
    <p>Generic visual reference for harmonized BSP study setup</p>
</header>

<section id="flow">
    <h2>High-Level Study Setup Flow</h2>

    <div class="flow-wrap">
        <div class="study-box">Study</div>
        <div class="connector"></div>

        <div class="flow-grid">
            <a href="#projects-drive">
                <div class="flow-card">
                    <div class="title">1. Projects Drive</div>
                    <div class="desc">
                        Data such as SAS datasets and XPT datasets, and outputs such as RTF, PDF, DOCX, etc.
                    </div>
                </div>
            </a>

            <a href="#sharepoint">
                <div class="flow-card">
                    <div class="title">2. SharePoint Site / Teams Channel</div>
                    <div class="desc">
                        Specs, SAP, aCRF, deliverables, and supporting documents. Site should be set up as Public for programmatic access.
                    </div>
                </div>
            </a>

            <a href="#beanstalk">
                <div class="flow-card">
                    <div class="title">3. Beanstalk</div>
                    <div class="desc">
                        Git-based version control for study programs.
                    </div>
                </div>
            </a>

            <a href="#teamwork">
                <div class="flow-card">
                    <div class="title">4. Teamwork</div>
                    <div class="desc">
                        Program status, generated outputs, QC issues, deliverable completion, and user assignment tracking.
                    </div>
                </div>
            </a>
        </div>
    </div>
</section>

<section id="projects-drive">
    <h2>1. Projects Drive</h2>

    <p class="note">
        Only the Biostat/Biostats area is standardized to <b>BSP</b>. Cross-functional folders outside BSP are not changed.
    </p>

    <h3>Study-Level Folder Structure</h3>

    <div class="folder-panel">
        <div class="tree">
            <details class="root" open>
                <summary>
                    Study Root
                    <span class="muted"> — examples:</span>
                    <span class="example">P:\Projects\&lt;Sponsor name&gt;\&lt;Study&gt;</span>
                    <span class="example">P:\Projects\Client\&lt;Sponsor name&gt;\&lt;Study&gt;</span>
                    <span class="example">P:\Projects2\Client\BLA\&lt;Sponsor name&gt;\&lt;Study&gt;</span>
                </summary>

                <details class="bsp" open>
                    <summary>BSP</summary>

                    <details open>
                        <summary>_Restricted</summary>
                        <div class="folder-line">Non-CRF Data</div>
                        <div class="folder-line">Output</div>
                        <div class="folder-line">SASDATA</div>
                    </details>

                    <details open>
                        <summary>Non-CRF Data</summary>
                        <div class="folder-line">AE terms</div>
                        <div class="folder-line">Lab data</div>
                        <div class="folder-line">PK data</div>
                        <div class="folder-line">DM reports</div>
                        <div class="folder-line">Protocol deviations</div>
                        <div class="folder-line">Randomization datasets</div>
                    </details>

                    <details open>
                        <summary>Output</summary>

                        <details open>
                            <summary>Development TLFs</summary>
                            <div class="folder-line">tables_shells</div>
                            <div class="folder-line">listings_shells</div>
                            <div class="folder-line">figures_shells</div>
                            <div class="folder-line">tables_vYYYYMMDD</div>
                            <div class="folder-line">listings_vYYYYMMDD</div>
                            <div class="folder-line">figures_vYYYYMMDD</div>
                        </details>

                        <details open>
                            <summary>Delivery TLFs</summary>
                            <div class="comment-line">Deliverable-specific TLF folders can be named based on study need.</div>

                            <details open>
                                <summary>CSR TLFs</summary>
                                <div class="folder-line">tables_vYYYYMMDD_dYYYYMMDD</div>
                                <div class="folder-line">listings_vYYYYMMDD_dYYYYMMDD</div>
                                <div class="folder-line">figures_vYYYYMMDD_dYYYYMMDD</div>
                            </details>

                            <details>
                                <summary>aCSR TLFs</summary>
                                <div class="folder-line">tables_vYYYYMMDD_dYYYYMMDD</div>
                                <div class="folder-line">listings_vYYYYMMDD_dYYYYMMDD</div>
                                <div class="folder-line">figures_vYYYYMMDD_dYYYYMMDD</div>
                            </details>

                            <details>
                                <summary>DSMB TLFs</summary>
                                <div class="folder-line">tables_vYYYYMMDD_dYYYYMMDD</div>
                                <div class="folder-line">listings_vYYYYMMDD_dYYYYMMDD</div>
                                <div class="folder-line">figures_vYYYYMMDD_dYYYYMMDD</div>
                            </details>

                            <details>
                                <summary>DMC TLFs</summary>
                                <div class="folder-line">tables_vYYYYMMDD_dYYYYMMDD</div>
                                <div class="folder-line">listings_vYYYYMMDD_dYYYYMMDD</div>
                                <div class="folder-line">figures_vYYYYMMDD_dYYYYMMDD</div>
                            </details>
                        </details>
                    </details>

                    <details open>
                        <summary>SASDATA</summary>
                        <details open>
                            <summary>raw_vYYYYMMDD</summary>
                            <div class="folder-line">Logs</div>

                            <details open>
                                <summary>sdtm_vYYYYMMDD</summary>
                                <details>
                                    <summary>Compare</summary>
                                    <div class="folder-line">Logs</div>
                                </details>
                                <div class="folder-line">Logs</div>
                                <div class="folder-line">Specs</div>
                                <div class="folder-line">XPT</div>

                                <details open>
                                    <summary>adam_vYYYYMMDD</summary>
                                    <details>
                                        <summary>Compare</summary>
                                        <div class="folder-line">Logs</div>
                                    </details>
                                    <div class="folder-line">Logs</div>
                                    <div class="folder-line">Specs</div>
                                    <div class="folder-line">XPT</div>
                                </details>
                            </details>
                        </details>
                    </details>

                    <div class="folder-line">Sample Size</div>
                    <div class="folder-line">Documents</div>
                </details>

                <div class="folder-line">Data Mgmt</div>
                <div class="folder-line">Data Transfer Folder</div>
                <div class="folder-line">Meetings</div>
                <div class="folder-line">Notes to File</div>
                <div class="folder-line">Proj Mgmt IUO</div>
                <div class="folder-line">Protocol</div>
                <div class="folder-line">Timelines</div>
                <div class="folder-line">Training</div>
            </details>
        </div>
    </div>

    <p class="small">
        _Restricted mirrors the blinded structure and is used only when restricted or unblinded access is required.
    </p>
</section>

<section id="sharepoint">
    <h2>2. SharePoint Site / Teams Channel</h2>

    <p>
        SharePoint Site / Teams Channel is used to store study documents such as specifications, aCRF, SAP,
        deliverables, and supporting materials. The site should be set up as <b>Public</b> for programmatic access.
    </p>

    <h3>SharePoint / Teams BSP Folder Structure</h3>

    <div class="folder-panel">
        <div class="tree">
            <details class="root" open>
                <summary>SharePoint Site / Teams Channel BSP Area</summary>

                <div class="folder-line">aCRF</div>

                <details open>
                    <summary>ADaM_Specs</summary>
                    <div class="folder-line">CSR</div>
                    <div class="folder-line">DSMB</div>
                    <div class="folder-line">DMC</div>
                    <div class="folder-line">Other task-specific folders, as needed</div>
                </details>

                <details open>
                    <summary>Analysis Plan</summary>
                    <div class="folder-line">CSR</div>
                    <div class="folder-line">DSMB</div>
                    <div class="folder-line">DMC</div>
                    <div class="folder-line">Other task-specific folders, as needed</div>
                </details>

                <details open>
                    <summary>Deliverables</summary>
                    <div class="folder-line">Version-controlled delivery packages</div>
                </details>

                <div class="folder-line">Other Documents</div>
                <div class="folder-line">Random</div>

                <details open>
                    <summary>SDTM_Specs</summary>
                    <div class="folder-line">CSR</div>
                    <div class="folder-line">DSMB</div>
                    <div class="folder-line">DMC</div>
                    <div class="folder-line">Other task-specific folders, as needed</div>
                </details>

                <details open>
                    <summary>TLF_Specs</summary>
                    <div class="folder-line">CSR</div>
                    <div class="folder-line">DSMB</div>
                    <div class="folder-line">DMC</div>
                    <div class="folder-line">Other task-specific folders, as needed</div>
                </details>
            </details>
        </div>
    </div>

    <p class="note">
        <b>CSR</b> is the default folder created first under specification folders. If the study requires other task-related specifications
        such as DSMB or DMC, create separate folders within the relevant specification folder.
    </p>

    <table>
        <tr><th>Folder</th><th>Purpose</th></tr>
        <tr><td>aCRF</td><td>aCRFs used for SDTM mapping and define.xml preparation.</td></tr>
        <tr><td>ADaM_Specs</td><td>ADaM specifications, variable definitions, derivation rules, and metadata.</td></tr>
        <tr><td>Analysis Plan</td><td>SAP and related updates or amendments.</td></tr>
        <tr><td>Deliverables</td><td>Final study deliverables, submitted packages, reviewer guides, define.xml, and archived outputs.</td></tr>
        <tr><td>Other Documents</td><td>Hard coding specifications and supporting study documents.</td></tr>
        <tr><td>Random</td><td>Randomization specifications, blinding/unblinding plans, code lists, seed files, and approvals.</td></tr>
        <tr><td>SDTM_Specs</td><td>SDTM specifications, domain structures, metadata, controlled terminology, and mapping rules.</td></tr>
        <tr><td>TLF_Specs</td><td>TLF specifications.</td></tr>
    </table>
</section>

<section id="beanstalk">
    <h2>3. Beanstalk</h2>

    <p>
        Beanstalk is used for Git-based version control of study programs. The repository is configured by IT,
        and each programmer clones the repository into their local development area.
    </p>

    <h3>Programs Repository Structure</h3>

    <div class="folder-panel">
        <div class="tree">
            <details class="root" open>
                <summary>Study Program Repository</summary>

                <details open>
                    <summary>Programs</summary>

                    <div class="file-line">init.sas</div>
                    <div class="comment-line">init.sas should be updated with SharePoint site name and specification file name during configuration.</div>

                    <div class="file-line">study_formats.sas</div>
                    <div class="comment-line">study_formats.sas can centralize formats from SDTM/ADaM specs using dev_formats and qc_formats sheets.</div>

                    <div class="folder-line">ADaM</div>
                    <div class="folder-line">Derived</div>

                    <details open>
                        <summary>Figures</summary>
                        <div class="folder-line">Shells</div>
                    </details>

                    <details open>
                        <summary>Listings</summary>
                        <div class="folder-line">Shells</div>
                    </details>

                    <div class="folder-line">Macros</div>
                    <div class="folder-line">Randomization</div>
                    <div class="folder-line">SDTM</div>

                    <details open>
                        <summary>Tables</summary>
                        <div class="folder-line">Shells</div>
                    </details>

                    <details open>
                        <summary>Validation</summary>
                        <div class="folder-line">ADaM</div>
                        <div class="folder-line">Derived</div>
                        <div class="folder-line">Figures</div>
                        <div class="folder-line">Listings</div>
                        <div class="folder-line">SDTM</div>
                        <div class="folder-line">Tables</div>
                    </details>

                    <div class="folder-line">Vendor Data</div>
                </details>
            </details>
        </div>
    </div>

    <h3>setenv.sas Example and Flow</h3>

    <p>
        The <b>setenv.sas</b> macro sets program, data, output, GLIB, and library paths based on the study parameters.
    </p>

    <h4>Example 1 — Standard Projects2 setup</h4>
    <div class="code-block">%setenv(
    sponsor    = BMS,
    study      = ADEPT-01,
    devrootw   = P:\Projects2,
    glibver    = harm_bsp_v_1_0,
    dbver2     = raw_v20260407\sdtm_v20260407\adam_v20260407,
    deliver    = Development TLFs,
    pgmtype    = tables_shells
);</div>

    <h4>Example 2 — Projects2 setup with additional middle folder</h4>
    <div class="code-block">%setenv(
    sponsor    = BMS,
    study      = ADEPT-01,
    devrootw   = P:\Projects2\Veristat,
    glibver    = harm_bsp_v_1_0,
    dbver2     = raw_v20260407\sdtm_v20260407\adam_v20260407,
    deliver    = Development TLFs,
    pgmtype    = tables_shells
);</div>

    <h4>What the macro sets up</h4>

    <table>
        <tr><th>Parameter / Macro Variable</th><th>Purpose / Setup</th></tr>
        <tr>
            <td><b>sponsor</b></td>
            <td>Used as the sponsor/client folder name while deriving program, data, and output paths.</td>
        </tr>
        <tr>
            <td><b>study</b></td>
            <td>Used as the study/project folder name while deriving program, data, and output paths.</td>
        </tr>
        <tr>
            <td><b>devrootw</b></td>
            <td>Base Projects Drive root. For harmonized structure, this points to the shared project root such as P:\Projects2 or a root containing additional middle folders.</td>
        </tr>
        <tr>
            <td><b>glibver</b></td>
            <td>Controls which GLIB version is used. Example: P:\BSP_LocalDev\_GLIB\harm_bsp_v_1_0\macros.</td>
        </tr>
        <tr>
            <td><b>dbver2</b></td>
            <td>Defines raw, SDTM, and ADaM data version path. The macro parses this and assigns RAW, SDTM, ADAM, and related spec libraries where folders exist.</td>
        </tr>
        <tr>
            <td><b>deliver</b></td>
            <td>Defines the output deliverable area. Example: Development TLFs, CSR TLFs, DSMB TLFs, DMC TLFs, etc.</td>
        </tr>
        <tr>
            <td><b>pgmtype</b></td>
            <td>Defines the program/output type. Examples: tables, listings, figures, tables_shells. Shells route to shell folders and set output destination as WORD.</td>
        </tr>
        <tr>
            <td><b>PROOT</b></td>
            <td>Program root. Typically resolves under P:\BSP_LocalDev\&lt;username&gt;\&lt;sponsor&gt;\&lt;study&gt;\Programs, with fallback logic using current program path if init.sas is not found.</td>
        </tr>
        <tr>
            <td><b>DROOT</b></td>
            <td>Data root. For harmonized structure, points to &lt;devrootw&gt;\&lt;sponsor&gt;\&lt;study&gt;\BSP\sasdata.</td>
        </tr>
        <tr>
            <td><b>OROOT</b></td>
            <td>Output root. For harmonized structure, points to &lt;devrootw&gt;\&lt;sponsor&gt;\&lt;study&gt;\BSP\Output\&lt;deliver&gt;.</td>
        </tr>
        <tr>
            <td><b>OUTLOC</b></td>
            <td>Output subfolder derived from pgmtype, database version, and delivery date. Example: tables_shells or tables_v20260407_d20260430.</td>
        </tr>
        <tr>
            <td><b>SASAUTOS</b></td>
            <td>Includes study macros and selected GLIB macro folders for macro resolution.</td>
        </tr>
        <tr>
            <td><b>init.sas</b></td>
            <td>Loaded after environment setup. If not found under PROOT, the macro attempts to resolve it from the current executing program path.</td>
        </tr>
    </table>

    <h4>Example resolved paths</h4>

    <div class="path-block">
PROOT  = P:\BSP_LocalDev\&lt;username&gt;\BMS\ADEPT-01\Programs<br>
DROOT  = P:\Projects2\BMS\ADEPT-01\BSP\sasdata<br>
OROOT  = P:\Projects2\BMS\ADEPT-01\BSP\Output\Development TLFs<br>
OUTLOC = tables_shells<br>
OUTPATH = P:\Projects2\BMS\ADEPT-01\BSP\Output\Development TLFs\tables_shells
    </div>

    <h4>setenv.sas Flow</h4>

    <div class="folder-panel">
        <div class="tree">
            <details class="root" open>
                <summary>Program Call</summary>
                <details open>
                    <summary>setenv.sas</summary>
                    <div class="folder-line">Clears existing environment when clrenv=1</div>
                    <div class="folder-line">Resolves PROOT, DROOT, OROOT, GLIBROOT</div>
                    <div class="folder-line">Assigns SASAUTOS using study macros and GLIB macros</div>
                    <div class="folder-line">Assigns RAW, SDTM, ADAM libraries from dbver2</div>
                    <div class="folder-line">Assigns output location from deliver and pgmtype</div>
                    <div class="folder-line">Loads study init.sas</div>
                </details>
            </details>
        </div>
    </div>
</section>

<section id="teamwork">
    <h2>4. Teamwork</h2>

    <p>
        Teamwork is used for tracking programming and deliverable activities through completion with assigned ownership.
    </p>

    <div class="grid">
        <div class="info-card"><b>Program Status</b><br>Track status of SDTM, ADaM, TLF, validation, and related programs.</div>
        <div class="info-card"><b>Outputs Generated</b><br>Track generated outputs and related review readiness.</div>
        <div class="info-card"><b>QC Issues</b><br>Track QC findings, actions, owners, and closure.</div>
        <div class="info-card"><b>Deliverable Status</b><br>Track deliverable completion, finalization, and assigned ownership.</div>
    </div>
</section>

<section>
    <h2>Notes</h2>
    <ul>
        <li>This page is a visual guide only; controlled folder structure guidance should follow the approved GDL.</li>
        <li><b>BSP</b> is the standardized Biostatistics and Statistical Programming folder.</li>
        <li>Cross-functional folders outside BSP remain unchanged.</li>
    </ul>
</section>

<div class="footer">
Generated HTML reference page for BSP study setup
</div>

</body>
</html>
"""

OUTPUT_HTML.write_text(html_text, encoding="utf-8")

print("=" * 70)
print("HTML generated successfully.")
print(f"Output file: {OUTPUT_HTML}")
print("=" * 70)
