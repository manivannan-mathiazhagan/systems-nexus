# ****************************************************************************************************
# Script Name    : Veristat_TLF_Packager.py
#
# Purpose        : GUI Tool to scan RTF, DOCX, and PDF files in a folder,
#                  extract TLF titles (from RTF: header/first lines, DOCX: header/body, PDF: page 1),
#                  display for user review, filter, reorder (move up/down), and export details to Excel.
#                  Users can convert RTF/DOCX to PDF using Microsoft Word (via pywin32),
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

import os
import sys
import datetime
from PyQt5 import QtWidgets, QtGui, QtCore
import traceback

# Signal class for safe communication between threads and UI
class Communicate(QtCore.QObject):
    log_signal = QtCore.pyqtSignal(str)
    message_signal = QtCore.pyqtSignal(str, str)

# Main function
def main():
    app = QtWidgets.QApplication(sys.argv)
    window = TLFApp()
    window.show()
    sys.exit(app.exec_())

class TLFApp(QtWidgets.QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Veristat TLF Packager")
        self.setGeometry(100, 100, 1100, 700)
        self.setStyleSheet("font-family: Courier New; font-size: 10pt;")

        self.comm = Communicate()
        self.comm.log_signal.connect(self.handle_log_signal)
        self.comm.message_signal.connect(self.show_messagebox)

        self.terminate_requested = False
        self.active_thread = None

        layout = QtWidgets.QVBoxLayout(self)

        # === Folder selection ===
        folder_layout = QtWidgets.QHBoxLayout()
        self.folder_label = QtWidgets.QLabel("Select Folder:")
        self.folder_path = QtWidgets.QLineEdit()
        self.folder_button = QtWidgets.QPushButton("Browse")
        self.folder_button.clicked.connect(self.select_folder)
        folder_layout.addWidget(self.folder_label)
        folder_layout.addWidget(self.folder_path)
        folder_layout.addWidget(self.folder_button)

        # === Output PDF Name ===
        output_layout = QtWidgets.QHBoxLayout()
        self.outpdf_label = QtWidgets.QLabel("Output PDF:")
        self.outpdf_var = QtWidgets.QLineEdit("Combined_TLFs.pdf")
        self.toc_checkbox = QtWidgets.QCheckBox("Include TOC Pages")
        self.toc_checkbox.setChecked(True)
        output_layout.addWidget(self.outpdf_label)
        output_layout.addWidget(self.outpdf_var)
        output_layout.addWidget(self.toc_checkbox)

        # === Table setup ===
        self.table = QtWidgets.QTableWidget()
        self.table.setColumnCount(3)
        self.table.setHorizontalHeaderLabels(["Filename", "Include", "Bookmark"])
        self.table.horizontalHeader().setStretchLastSection(True)

        # === Buttons ===
        button_layout = QtWidgets.QHBoxLayout()
        self.load_button = QtWidgets.QPushButton("Load Files")
        self.convert_button = QtWidgets.QPushButton("Convert RTF/DOCX ➜ PDF")
        self.generate_button = QtWidgets.QPushButton("Generate PDF")
        self.terminate_button = QtWidgets.QPushButton("Terminate")
        self.load_button.clicked.connect(self.load_files)
        self.convert_button.clicked.connect(self.convert_checked_files)
        self.generate_button.clicked.connect(self.generate_pdf)
        self.terminate_button.clicked.connect(self.terminate_process)
        button_layout.addWidget(self.load_button)
        button_layout.addWidget(self.convert_button)
        button_layout.addWidget(self.generate_button)
        button_layout.addWidget(self.terminate_button)

        # === Log box ===
        self.log_box = QtWidgets.QTextEdit()
        self.log_box.setReadOnly(True)
        self.log_box.setMinimumHeight(180)
        self.log_box.setStyleSheet("background-color: #f9f9f9; border: 1px solid #aaa;")

        layout.addLayout(folder_layout)
        layout.addLayout(output_layout)
        layout.addWidget(self.table)
        layout.addLayout(button_layout)
        layout.addWidget(QtWidgets.QLabel("Log Output:"))
        layout.addWidget(self.log_box)

    def show_messagebox(self, title, message):
        QtWidgets.QMessageBox.information(self, title, message)

    def thread_safe_log(self, text, level="normal"):
        color_map = {
            "success": "green",
            "warning": "orange",
            "error": "red",
            "terminated": "crimson",
            "normal": "black"
        }
        color = color_map.get(level, "black")
        formatted = f'<span style="color:{color}">{text}</span>'
        self.comm.log_signal.emit(formatted)

    def handle_log_signal(self, text):
        timestamp = datetime.datetime.now().strftime("%H:%M:%S")
        self.log_box.append(f"[{timestamp}] {text}")

    def terminate_process(self):
        if self.active_thread and self.active_thread.is_alive():
            self.terminate_requested = True
            self.thread_safe_log("🛑 Termination requested. Waiting for task to halt...", level="terminated")
        else:
            self.thread_safe_log("⚠️ No active process to terminate.", level="warning")

    def select_folder(self):
        folder = QtWidgets.QFileDialog.getExistingDirectory(self, "Select Folder")
        if folder:
            self.folder_path.setText(folder)

    def load_files(self):
        folder = self.folder_path.text().strip()
        if not folder or not os.path.isdir(folder):
            self.thread_safe_log("❌ Invalid folder selected.", level="error")
            return

        allowed_exts = [".rtf", ".docx", ".pdf"]
        files = [
            os.path.join(folder, f)
            for f in os.listdir(folder)
            if os.path.splitext(f)[1].lower() in allowed_exts
        ]

        if not files:
            self.thread_safe_log("⚠️ No RTF/DOCX/PDF files found in the folder.", level="warning")
            return

        self.table_data = []
        self.table.setRowCount(len(files))

        for i, file in enumerate(files):
            filename = os.path.basename(file)
            include_chk = QtWidgets.QCheckBox()
            include_chk.setChecked(True)

            bookmark_edit = QtWidgets.QLineEdit(os.path.splitext(filename)[0])
            bookmark_edit.setStyleSheet("background-color: #fefefe;")

            self.table.setItem(i, 0, QtWidgets.QTableWidgetItem(filename))
            self.table.setCellWidget(i, 1, include_chk)
            self.table.setCellWidget(i, 2, bookmark_edit)

            self.table_data.append([file, include_chk, bookmark_edit])

        self.thread_safe_log(f"✅ Loaded {len(files)} files from: {folder}", level="success")
    def convert_checked_files(self):
        import pythoncom
        from win32com.client import Dispatch

        def worker():
            try:
                pythoncom.CoInitialize()
                word = Dispatch("Word.Application")
                word.Visible = False
                count = 0

                for file, chkbox, _ in self.table_data:
                    if self.terminate_requested:
                        self.thread_safe_log("❌ Conversion terminated by user.", level="terminated")
                        return

                    if chkbox.isChecked() and file.lower().endswith((".rtf", ".docx")):
                        pdf_path = os.path.splitext(file)[0] + ".pdf"
                        doc = word.Documents.Open(file)
                        doc.SaveAs(pdf_path, FileFormat=17)
                        doc.Close(False)
                        self.thread_safe_log(f"✅ Converted: {os.path.basename(file)} ➜ {os.path.basename(pdf_path)}", level="success")
                        count += 1

                word.Quit()
                self.thread_safe_log(f"✔️ Conversion completed for {count} files.")
            except Exception as e:
                self.thread_safe_log(f"❌ Conversion error: {str(e)}", level="error")

        self.terminate_requested = False
        self.active_thread = threading.Thread(target=worker)
        self.active_thread.start()

    def generate_pdf(self):
        import fitz  # PyMuPDF
        from PyPDF2 import PdfMerger

        def worker():
            try:
                merger = PdfMerger()
                toc_enabled = self.toc_checkbox.isChecked()
                bookmarks = []
                folder = self.folder_path.text().strip()
                outpdf_name = self.outpdf_var.text().strip()
                outpdf_path = os.path.join(folder, outpdf_name)
                added = 0

                for file, chkbox, bookmark_widget in self.table_data:
                    if self.terminate_requested:
                        self.thread_safe_log("❌ PDF merge terminated by user.", level="terminated")
                        return

                    if chkbox.isChecked():
                        pdf_path = file
                        if not pdf_path.lower().endswith(".pdf"):
                            pdf_path = os.path.splitext(pdf_path)[0] + ".pdf"
                        if not os.path.exists(pdf_path):
                            self.thread_safe_log(f"⚠️ Missing PDF: {os.path.basename(pdf_path)}", level="warning")
                            continue

                        bookmark_text = bookmark_widget.text().strip()
                        merger.append(pdf_path)
                        bookmarks.append((bookmark_text, added))
                        added += 1

                with open(outpdf_path, "wb") as f_out:
                    merger.write(f_out)
                    merger.close()

                self.thread_safe_log(f"📄 Final merged PDF created: {outpdf_path}", level="success")

                if toc_enabled:
                    self.insert_toc_pages(outpdf_path, bookmarks)
            except Exception as e:
                self.thread_safe_log(f"❌ PDF generation error: {str(e)}", level="error")

        self.terminate_requested = False
        self.active_thread = threading.Thread(target=worker)
        self.active_thread.start()

    def insert_toc_pages(self, pdf_path, bookmarks):
        try:
            doc = fitz.open(pdf_path)
            toc_lines = ["Table of Contents", ""]

            for title, page in bookmarks:
                toc_lines.append(f"{title} ...... {page + 1}")

            toc_text = "\n".join(toc_lines)
            toc_page = fitz.open()
            page = toc_page.new_page()
            page.insert_text((50, 50), toc_text, fontsize=12)
            doc.insert_pdf(toc_page, start_at=0)
            doc.save(pdf_path, incremental=True)
            doc.close()
            self.thread_safe_log("📑 TOC page inserted successfully.", level="success")
        except Exception as e:
            self.thread_safe_log(f"❌ TOC insertion failed: {str(e)}", level="error")

if __name__ == "__main__":
    main()