# ****************************************************************************************************
# Script Name    : Veristat_TextSearch_CompareChecker.py
#
# Purpose        : GUI Tool to search text across SAS, LOG, and TXT files in a folder (including subfolders),
#                  and review results from PROC COMPARE (PDF, LST, TXT) with Pass/Fail status.
#
# Author         : Manivannan Mathialagan
#
# Created On     : 15-Jul-2025
#
# Key Features:
#   - Search for any string across .sas, .txt, and .log files in folder + subfolders.
#   - Display relative folder + filename for each hit with line preview.
#   - Alternate background colors by file for easier readability.
#   - View PROC COMPARE results by scanning .lst/.txt/.pdf files and classifying them as Passed or Failed.
#   - Display total file counts, matches found, and status counts.
#   - Open results directly in VS Code at the matched line.
# ****************************************************************************************************

import sys, os, re, fitz, subprocess
from PyQt5.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QPushButton, QFileDialog, QLabel,
    QLineEdit, QListWidget, QComboBox, QStackedWidget, QHBoxLayout, QListWidgetItem
)
from PyQt5.QtGui import QFont, QColor
from PyQt5.QtCore import Qt

def launch_vscode(filepath, line_number=None):
    vscode_path = r"C:\Program Files\Microsoft VS Code\Code.exe"
    try:
        if line_number:
            subprocess.Popen([vscode_path, "-g", f"{filepath}:{line_number}"])
        else:
            subprocess.Popen([vscode_path, filepath])
    except Exception as e:
        print(f"Error launching VS Code: {e}")

class VeristatChecker(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Veristat Text Search and PROC COMPARE Checker")
        self.setGeometry(200, 100, 1000, 650)
        self.setStyleSheet("background-color: #f8fbff;")

        font_title = QFont("Segoe UI", 14, QFont.Bold)
        font_label = QFont("Segoe UI", 10)

        layout = QVBoxLayout()
        self.setLayout(layout)

        self.header = QLabel("📘 Veristat Text Search and PROC COMPARE Checker")
        self.header.setFont(font_title)
        self.header.setStyleSheet("background-color: #b3d9ff; color: #003366; padding: 12px; border-radius: 10px;")
        self.header.setAlignment(Qt.AlignCenter)
        layout.addWidget(self.header)

        self.stack = QStackedWidget()
        layout.addWidget(self.stack)

        self.init_main_menu(font_label)
        self.init_text_search_ui(font_label)
        self.init_compare_checker_ui(font_label)

        self.stack.setCurrentIndex(0)

    def init_main_menu(self, font_label):
        menu = QWidget()
        vbox = QVBoxLayout()

        btn1 = QPushButton("🔍 Text Search in SAS, LOG, TXT Files")
        btn2 = QPushButton("📑 Check PROC COMPARE Status (PDF/LST/TXT)")

        for btn in [btn1, btn2]:
            btn.setFont(font_label)
            btn.setMinimumHeight(40)
            btn.setStyleSheet("background-color: #e6f2ff; color: #002244; font-weight: bold;")

        btn1.clicked.connect(lambda: self.stack.setCurrentIndex(1))
        btn2.clicked.connect(lambda: self.stack.setCurrentIndex(2))

        vbox.addStretch(1)
        vbox.addWidget(btn1)
        vbox.addWidget(btn2)
        vbox.addStretch(1)
        menu.setLayout(vbox)
        self.stack.addWidget(menu)

    def init_text_search_ui(self, font_label):
        page = QWidget()
        layout = QVBoxLayout()

        self.search_folder = QLineEdit()
        browse_btn = QPushButton("Browse Folder")
        browse_btn.clicked.connect(self.browse_text_folder)

        path_row = QHBoxLayout()
        path_row.addWidget(self.search_folder)
        path_row.addWidget(browse_btn)

        self.search_input = QLineEdit()
        self.search_input.setPlaceholderText("Enter text to search (case-insensitive)")

        self.filetype_combo = QComboBox()
        self.filetype_combo.addItems([".sas", ".log", ".txt", "All"])

        self.search_btn = QPushButton("Search")
        self.search_btn.setStyleSheet("background-color: #c0f2c0; font-weight: bold;")
        self.search_btn.clicked.connect(self.run_text_search)

        self.search_results = QListWidget()
        self.search_results.itemClicked.connect(self.open_file_line)

        self.search_status = QLabel("")
        back_btn = QPushButton("⬅ Back")
        back_btn.clicked.connect(lambda: self.stack.setCurrentIndex(0))

        layout.addLayout(path_row)
        layout.addWidget(self.search_input)
        layout.addWidget(self.filetype_combo)
        layout.addWidget(self.search_btn)
        layout.addWidget(self.search_results)
        layout.addWidget(self.search_status)
        layout.addWidget(back_btn)

        for w in [self.search_input, self.search_folder, self.search_status]:
            w.setFont(font_label)
        page.setLayout(layout)
        self.stack.addWidget(page)

    def init_compare_checker_ui(self, font_label):
        page = QWidget()
        layout = QVBoxLayout()

        self.compare_folder = QLineEdit()
        browse_btn = QPushButton("Browse Folder")
        browse_btn.clicked.connect(self.browse_compare_folder)

        path_row = QHBoxLayout()
        path_row.addWidget(self.compare_folder)
        path_row.addWidget(browse_btn)

        self.compare_filetype = QComboBox()
        self.compare_filetype.addItems([".pdf", ".lst", ".txt", "All"])

        self.status_filter = QComboBox()
        self.status_filter.addItems(["All", "Passed", "Failed"])

        refresh_btn = QPushButton("Refresh Status")
        refresh_btn.setStyleSheet("background-color: #ffd9cc; font-weight: bold;")
        refresh_btn.clicked.connect(self.run_compare_check)

        filter_row = QHBoxLayout()
        filter_row.addWidget(QLabel("File Type:"))
        filter_row.addWidget(self.compare_filetype)
        filter_row.addWidget(QLabel("Show:"))
        filter_row.addWidget(self.status_filter)
        filter_row.addWidget(refresh_btn)

        self.compare_results = QListWidget()
        self.compare_results.itemClicked.connect(self.open_file_line)

        self.compare_status = QLabel("")
        back_btn = QPushButton("⬅ Back")
        back_btn.clicked.connect(lambda: self.stack.setCurrentIndex(0))

        layout.addLayout(path_row)
        layout.addLayout(filter_row)
        layout.addWidget(self.compare_results)
        layout.addWidget(self.compare_status)
        layout.addWidget(back_btn)

        for w in [self.compare_folder, self.compare_status]:
            w.setFont(font_label)
        page.setLayout(layout)
        self.stack.addWidget(page)

    def browse_text_folder(self):
        folder = QFileDialog.getExistingDirectory(self, "Select Folder")
        if folder:
            self.search_folder.setText(folder)

    def browse_compare_folder(self):
        folder = QFileDialog.getExistingDirectory(self, "Select Folder")
        if folder:
            self.compare_folder.setText(folder)

    def run_text_search(self):
        folder = self.search_folder.text().strip()
        search_term = self.search_input.text().strip().lower()
        ext = self.filetype_combo.currentText()
        self.search_results.clear()
        count = 0
        total = 0
        file_index = 0  # for alternating colors

        if not os.path.isdir(folder):
            self.search_status.setText("⚠️ Invalid folder")
            return

        valid_exts = [".sas", ".txt", ".log"]

        for root, _, files in os.walk(folder):
            for file in files:
                if ext == "All":
                    if not any(file.lower().endswith(x) for x in valid_exts):
                        continue
                else:
                    if not file.lower().endswith(ext):
                        continue

                total += 1
                path = os.path.join(root, file)
                color = QColor("#f0f8ff") if file_index % 2 == 0 else QColor("#e6ffe6")
                file_index += 1

                try:
                    with open(path, 'r', errors='ignore') as f:
                        for i, line in enumerate(f, 1):
                            if search_term in line.lower():
                                count += 1
                                relpath = os.path.relpath(path, folder)
                                item = QListWidgetItem(f"{relpath} [Line {i}]: {line.strip()}")
                                item.setData(Qt.UserRole, (path, i))
                                item.setBackground(color)
                                self.search_results.addItem(item)
                except:
                    continue
        self.search_status.setText(f"✅ Found {count} matches in {total} file(s)")

    def run_compare_check(self):
        folder = self.compare_folder.text().strip()
        ext = self.compare_filetype.currentText()
        filter_status = self.status_filter.currentText()
        self.compare_results.clear()
        passed = failed = total = 0

        if not os.path.isdir(folder):
            self.compare_status.setText("⚠️ Invalid folder")
            return

        for root, _, files in os.walk(folder):
            for file in files:
                if ext != "All" and not file.lower().endswith(ext):
                    continue
                path = os.path.join(root, file)
                try:
                    if file.endswith(".pdf"):
                        doc = fitz.open(path)
                        content = "\n".join(p.get_text() for p in doc)
                        doc.close()
                    else:
                        with open(path, 'r', errors='ignore') as f:
                            content = f.read()
                except:
                    continue

                match = re.search(r"Number of Observations with Some Compared Variables Unequal:\s+(\d+)", content, re.IGNORECASE)
                if match:
                    unequal = int(match.group(1))
                    status = "Passed" if unequal == 0 else "Failed"
                    if filter_status == "All" or filter_status == status:
                        item = QListWidgetItem(f"{file}: {status}")
                        item.setData(Qt.UserRole, (path, None))
                        color = QColor("#c6f6c6") if status == "Passed" else QColor("#f6c6c6")
                        item.setBackground(color)
                        self.compare_results.addItem(item)
                    if status == "Passed": passed += 1
                    else: failed += 1
                    total += 1
        self.compare_status.setText(f"🧾 Scanned {total} files → ✅ {passed} Passed | ❌ {failed} Failed")

    def open_file_line(self, item):
        path, lineno = item.data(Qt.UserRole)
        if os.path.exists(path):
            launch_vscode(path, lineno)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = VeristatChecker()
    window.show()
    sys.exit(app.exec_())
