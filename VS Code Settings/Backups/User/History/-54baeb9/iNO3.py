# ****************************************************************************************************
# Script Name    : Veristat_TLF_Packager.py
#
# Purpose        : GUI Tool to scan RTF, DOCX, and PDF files in a folder,
#                  extract TLF titles (from RTF: header/first lines, DOCX: header/body, PDF: page 1),
#                  display for user review, filter, reorder (move up/down), and export details to Excel.
#                  Users can convert RTF/DOCX files to PDF (via Microsoft Word),
#                  and generate a single bookmarked PDF with advanced, clickable Table of Contents.
#
# Author         : Manivannan Mathialagan
#
# Created On     : 22-May-2025
#
# Key Parameters (GUI-based):
#   - Folder Selection         : User selects the folder containing RTF, DOCX, and PDF files.
#   - Output PDF Name          : User specifies the name for the merged PDF.
#
# Key Features:
#   - Extracts and displays TLF titles from headers/bodies of RTF, DOCX, and first page of PDF.
#   - Allows user to filter, select, and reorder outputs for packaging.
#   - Bookmark/Include columns are interactive; Bookmark is editable.
#   - Exports details and custom order to Excel for documentation or further review.
#   - Converts RTF/DOCX to PDF using Microsoft Word (requires pywin32).
#   - Generates a merged PDF with bookmarks and advanced, wrapped, clickable Table of Contents (TOC).
#
# Example Usage:
#   - Run the script: python TLF_Packager.py
#   - Use the GUI to select folder, review/reorder files, and generate outputs.
#
# Notes:
#   - Requires Python 3, openpyxl, PyMuPDF (fitz), PyQt5, pywin32, python-docx
#   - Requires Microsoft Word installed for RTF/DOCX to PDF conversion (via pywin32)
#   - For any issues or suggestions, contact manivannan.mathialagan@veristat.com
#
# Modification History:
#
# Version 2.0 - Manivannan Mathialagan (05-Aug-2025)
#
# - Added checkbox to enable/disable TOC page generation
# - Added Terminate button to stop ongoing PDF or conversion processes
# ****************************************************************************************************

import sys
import os
import re
import time
import datetime
import subprocess
import site
import openpyxl
import fitz
import docx
from openpyxl import Workbook
from PyQt5 import QtWidgets, QtCore, QtGui

# Auto-install required packages (user mode only)
def ensure_user_site():
    user_site = site.getusersitepackages()
    if user_site not in sys.path:
        sys.path.insert(0, user_site)

def install_if_missing(package_name, import_name=None):
    try:
        __import__(import_name or package_name)
    except ImportError:
        print(f"[Installing] {package_name} (user mode)...")
        subprocess.check_call([sys.executable, "-m", "pip", "install", "--user", package_name])
        print(f"[Done] {package_name} installed.")

ensure_user_site()
install_if_missing("openpyxl")
install_if_missing("PyMuPDF", "fitz")
install_if_missing("PyQt5")
install_if_missing("pywin32")
install_if_missing("python-docx", "docx")

# Main App Class
class TLFApp(QtWidgets.QWidget):
    log_signal = QtCore.pyqtSignal(str)
    message_signal = QtCore.pyqtSignal(str, str)

    def __init__(self):
        super().__init__()
        self.setWindowTitle("Veristat TLF Packager")
        self.setGeometry(100, 100, 1280, 720)
        self.setStyleSheet("background-color: #f4f4f4; border-radius: 14px;")

        # Thread/termination control
        self.active_thread = None
        self.terminate_requested = False

        self.table_data = []
        self.out_folder = ""
        self.filtered_indices = []
        self.sorted_once = False
        self.current_sort_column = None
        self.sort_order = QtCore.Qt.AscendingOrder

        self.init_ui()
        self.log_signal.connect(self.handle_log_signal)
        self.message_signal.connect(self.show_messagebox)

    def init_ui(self):
        layout = QtWidgets.QVBoxLayout(self)
        layout.setContentsMargins(16, 12, 16, 12)

        header = QtWidgets.QLabel("Veristat TLF Packager")
        header.setFont(QtGui.QFont("Times New Roman", 21, QtGui.QFont.Bold))
        header.setAlignment(QtCore.Qt.AlignCenter)
        header.setStyleSheet("color: black; background: #b3e3e7; padding: 14px 0 10px 0; border-radius: 18px;")
        layout.addWidget(header)

        query = QtWidgets.QLabel(
            "• For any queries, issues faced, or if you have ideas for improvement,\n  please contact Manivannan (manivannan.mathialagan@veristat.com)"
        )
        query.setFont(QtGui.QFont("Times New Roman", 12))
        query.setStyleSheet("background: #f4f4f4; color: #222;")
        query.setAlignment(QtCore.Qt.AlignRight)
        layout.addWidget(query)

        self.toc_checkbox = QtWidgets.QCheckBox("Include Table of Contents (TOC) Pages in Final PDF")
        self.toc_checkbox.setChecked(True)
        self.toc_checkbox.setFont(QtGui.QFont("Times New Roman", 11))
        self.toc_checkbox.setStyleSheet("margin-left: 6px; color: #222;")
        layout.addWidget(self.toc_checkbox)

        self.outpdf_var = QtWidgets.QLineEdit(f"TLFs_Merged_{datetime.datetime.now().strftime('%Y%m%d_T%H%M')}.pdf")
        self.outpdf_var.setStyleSheet("""
            QLineEdit { border-radius: 8px; padding: 4px 6px; border: 1px solid #b8c2d0; background: #fff; }
        """)
        outpdf_lbl = QtWidgets.QLabel("Output PDF Name:")
        outpdf_lbl.setFont(QtGui.QFont("Times New Roman", 12))
        output_pdf_row = QtWidgets.QHBoxLayout()
        output_pdf_row.addWidget(outpdf_lbl)
        output_pdf_row.addWidget(self.outpdf_var)
        layout.addLayout(output_pdf_row)

        btn_layout = QtWidgets.QHBoxLayout()
        btn_style_base = """
            QPushButton {
                font-family: 'Times New Roman';
                font-weight: bold;
                font-size: 11pt;
                border-radius: 10px;
                padding: 6px 16px;
            }
            QPushButton:disabled {
                background-color: #e1e1e1; color: #aaa;
            }
        """

        self.browse_btn = QtWidgets.QPushButton("Browse Folder")
        self.browse_btn.setStyleSheet(btn_style_base + "QPushButton { background-color: #b3c6e7; color: #222; }")
        btn_layout.addWidget(self.browse_btn)

        self.convert_btn = QtWidgets.QPushButton("Convert to PDF")
        self.convert_btn.setStyleSheet(btn_style_base + "QPushButton { background-color: #ff9933; color: #222; }")
        btn_layout.addWidget(self.convert_btn)

        self.pack_btn = QtWidgets.QPushButton("Pack && TOC")
        self.pack_btn.setStyleSheet(btn_style_base + "QPushButton { background-color: #89c990; color: #222; font-size: 13pt; }")
        btn_layout.addWidget(self.pack_btn)

        self.export_btn = QtWidgets.QPushButton("Export to Excel")
        self.export_btn.setStyleSheet(btn_style_base + "QPushButton { background-color: #71c95e; color: #fff; }")
        btn_layout.addWidget(self.export_btn)

        self.exit_btn = QtWidgets.QPushButton("Terminate")
        self.exit_btn.setStyleSheet(btn_style_base + "QPushButton { background-color: #ff6666; color: white; }")
        btn_layout.addWidget(self.exit_btn)

        layout.addLayout(btn_layout)

        log_lbl = QtWidgets.QLabel("Log:")
        log_lbl.setFont(QtGui.QFont("Times New Roman", 12))
        layout.addWidget(log_lbl)

        self.log_box = QtWidgets.QTextEdit()
        self.log_box.setReadOnly(True)
        self.log_box.setMaximumHeight(130)
        self.log_box.setFont(QtGui.QFont("Times New Roman", 10))
        self.log_box.setStyleSheet("background: #f7f7f7; color: #1a2a4f; border-radius: 8px;")
        layout.addWidget(self.log_box)

        self.browse_btn.clicked.connect(self.browse_folder)
        self.convert_btn.clicked.connect(self.convert_checked_files)
        self.pack_btn.clicked.connect(self.generate_pdf)
        self.export_btn.clicked.connect(self.export_excel)
        self.exit_btn.clicked.connect(self.terminate_process)
        
    # === Handle emitted log signal ===
    def handle_log_signal(self, payload):
        if "|" in payload:
            level, msg = payload.split("|", 1)
        else:
            level, msg = "normal", payload
        self.log(msg, level)

    # === Display messagebox from thread ===
    def show_messagebox(self, type_, msg):
        if type_ == "info":
            QtWidgets.QMessageBox.information(self, "Info", msg)
        elif type_ == "warning":
            QtWidgets.QMessageBox.warning(self, "Warning", msg)
        elif type_ == "error":
            QtWidgets.QMessageBox.critical(self, "Error", msg)

    # === Log to QTextEdit with color formatting ===
    def log(self, msg, level="normal"):
        colors = {
            "normal": "#1a2a4f",      # dark blue
            "success": "#2e7d32",     # green
            "warning": "#d17f00",     # orange
            "error": "#c62828",       # red
            "terminated": "#990000"   # dark red
        }
        timestamp = datetime.datetime.now().strftime("%H:%M:%S")
        color = colors.get(level, "#1a2a4f")
        formatted = f'<span style="color:{color};">[{timestamp}] {msg}</span><br>'
        self.log_box.insertHtml(formatted)
        self.log_box.verticalScrollBar().setValue(self.log_box.verticalScrollBar().maximum())
        QtWidgets.QApplication.processEvents()

    # === Safe thread log emitter ===
    def thread_safe_log(self, msg, level="normal"):
        self.log_signal.emit(f"{level}|{msg}")

    # === Thread-safe messagebox trigger ===
    def thread_safe_message(self, type_, msg):
        self.message_signal.emit(type_, msg)

    # === Terminate active process/thread ===
    def terminate_process(self):
        if self.active_thread and self.active_thread.is_alive():
            self.terminate_requested = True
            self.thread_safe_log("⚠️ Termination requested. Attempting to stop the running process...", level="warning")
            self.thread_safe_message("info", "Termination in progress. Please wait a moment...")
        else:
            self.thread_safe_log("ℹ️ No active process to terminate.", level="normal")
            self.thread_safe_message("info", "No running process found to terminate.")
        def convert_checked_files(self):
        from threading import Thread
        def run_conversion():
            import win32com.client as win32
            word = win32.gencache.EnsureDispatch("Word.Application")
            word.Visible = False
            self.thread_safe_log("🔁 Converting selected RTF/DOCX files to PDF...", level="normal")
            try:
                for idx, row in enumerate(self.table_data):
                    if self.terminate_requested:
                        self.thread_safe_log("⛔ Conversion terminated by user.", level="terminated")
                        break
                    file_path = row[0]
                    ext = os.path.splitext(file_path)[1].lower()
                    if ext not in [".rtf", ".docx"]:
                        continue
                    pdf_path = os.path.splitext(file_path)[0] + ".pdf"
                    if os.path.exists(pdf_path):
                        self.thread_safe_log(f"⚠️ PDF already exists for: {os.path.basename(file_path)}", level="warning")
                        continue
                    doc = word.Documents.Open(file_path)
                    doc.SaveAs(pdf_path, FileFormat=17)
                    doc.Close()
                    self.thread_safe_log(f"✅ Converted: {os.path.basename(file_path)}", level="success")
            except Exception as e:
                self.thread_safe_log(f"❌ Conversion error: {str(e)}", level="error")
            finally:
                word.Quit()
                self.terminate_requested = False
                self.active_thread = None

        self.terminate_requested = False
        self.active_thread = Thread(target=run_conversion)
        self.active_thread.start()

    def generate_pdf(self):
        from threading import Thread
        def run_packaging():
            try:
                self.thread_safe_log("📦 Generating combined PDF with bookmarks...", level="normal")
                folder = QtWidgets.QFileDialog.getExistingDirectory(self, "Select PDF Folder")
                if not folder:
                    self.thread_safe_log("⚠️ PDF generation cancelled by user.", level="warning")
                    return

                import fitz
                final_pdf = fitz.open()
                toc_pages = []
                toc_checkbox = self.toc_checkbox.isChecked()
                file_list = sorted([
                    os.path.join(folder, f) for f in os.listdir(folder)
                    if f.lower().endswith(".pdf")
                ])

                if not file_list:
                    self.thread_safe_log("❌ No PDF files found for merging.", level="error")
                    return

                toc = []
                for i, pdf_file in enumerate(file_list, 1):
                    if self.terminate_requested:
                        self.thread_safe_log("⛔ PDF generation terminated by user.", level="terminated")
                        return

                    doc = fitz.open(pdf_file)
                    final_pdf.insert_pdf(doc)
                    toc.append([1, os.path.splitext(os.path.basename(pdf_file))[0], len(final_pdf) - doc.page_count + 1])
                    doc.close()
                    self.thread_safe_log(f"📎 Added: {os.path.basename(pdf_file)}", level="normal")

                if toc_checkbox:
                    toc_pdf = fitz.open()
                    for entry in toc:
                        toc_text = f"{entry[2]:>3} - {entry[1]}"
                        page = toc_pdf.new_page()
                        page.insert_text((72, 100 + 20 * toc.index(entry)), toc_text, fontsize=12)
                    final_pdf.insert_pdf(toc_pdf, start_at=0)
                    self.thread_safe_log("🧷 TOC pages inserted at beginning of PDF.", level="success")

                outpdf_name = self.outpdf_var.text().strip()
                if not outpdf_name.endswith(".pdf"):
                    outpdf_name += ".pdf"
                output_path = os.path.join(folder, outpdf_name)
                final_pdf.set_toc(toc)
                final_pdf.save(output_path)
                self.thread_safe_log(f"✅ Final PDF saved: {output_path}", level="success")

            except Exception as e:
                self.thread_safe_log(f"❌ PDF packaging error: {str(e)}", level="error")
            finally:
                self.terminate_requested = False
                self.active_thread = None

        self.terminate_requested = False
        self.active_thread = Thread(target=run_packaging)
        self.active_thread.start()


