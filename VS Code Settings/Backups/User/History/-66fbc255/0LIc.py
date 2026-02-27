import sys
import os
import re
import subprocess
from PyQt5.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QPushButton, QFileDialog,
    QLabel, QLineEdit, QTextEdit, QListWidget, QComboBox, QStackedWidget,
    QHBoxLayout, QListWidgetItem
)
from PyQt5.QtCore import Qt
from PyQt5.QtGui import QFont
import fitz  # PyMuPDF

def launch_notepadpp(filepath, line_number=None):
    npp_path = r"C:\Program Files\Notepad++\notepad++.exe"  # ✅ Adjust if Notepad++ is in a different path
    try:
        if line_number:
            subprocess.Popen([npp_path, f"-n{line_number}", filepath])
        else:
            subprocess.Popen([npp_path, filepath])
    except Exception as e:
        print(f"Error launching Notepad++: {e}")

class TextSearchTool(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Text Search and PROC COMPARE Results Checker")
        self.setGeometry(100, 100, 800, 600)
        self.setStyleSheet("background-color: #f4faff; font-family: Arial;")
        self.layout = QVBoxLayout()
        self.setLayout(self.layout)

        self.header = QLabel("📘 Text Search and PROC COMPARE Results Checker")
        self.header.setFont(QFont("Arial", 14, QFont.Bold))
        self.header.setAlignment(Qt.AlignCenter)
        self.layout.addWidget(self.header)

        self.stack = QStackedWidget()
        self.layout.addWidget(self.stack)

        self.init_main_page()
        self.init_search_page()
        self.init_compare_page()

        self.stack.setCurrentIndex(0)

    def init_main_page(self):
        page = QWidget()
        layout = QVBoxLayout()

        btn1 = QPushButton("🔍 Option 1: Text Search")
        btn2 = QPushButton("📑 Option 2: Check PROC COMPARE Results")
        btn1.setStyleSheet("background-color: #dbefff; padding: 10px; font-size: 14px;")
        btn2.setStyleSheet("background-color: #ffefdb; padding: 10px; font-size: 14px;")
        btn1.clicked.connect(lambda: self.stack.setCurrentIndex(1))
        btn2.clicked.connect(lambda: self.stack.setCurrentIndex(2))
        layout.addWidget(btn1)
        layout.addWidget(btn2)
        page.setLayout(layout)
        self.stack.addWidget(page)

    def init_search_page(self):
        page = QWidget()
        layout = QVBoxLayout()

        self.folder_label = QLabel("📁 Folder:")
        self.folder_path = QLineEdit()
        browse_btn = QPushButton("Browse")
        browse_btn.clicked.connect(self.browse_folder)

        folder_layout = QHBoxLayout()
        folder_layout.addWidget(self.folder_path)
        folder_layout.addWidget(browse_btn)

        self.search_label = QLabel("🔎 Search Text:")
        self.search_text = QLineEdit()

        self.filetype_label = QLabel("📂 File Types to Search:")
        self.filetype_combo = QComboBox()
        self.filetype_combo.addItems([".sas", ".txt", ".log", "All"])
        self.filetype_combo.setCurrentText("All")

        self.search_btn = QPushButton("Search")
        self.search_btn.setStyleSheet("background-color: #d0f0c0; font-weight: bold;")
        self.search_btn.clicked.connect(self.search_files)

        self.result_list = QListWidget()
        self.result_list.itemClicked.connect(self.open_selected_file)

        self.status_label = QLabel("")
        self.back_btn = QPushButton("⬅ Back to Main Menu")
        self.back_btn.clicked.connect(lambda: self.stack.setCurrentIndex(0))

        layout.addWidget(self.folder_label)
        layout.addLayout(folder_layout)
        layout.addWidget(self.search_label)
        layout.addWidget(self.search_text)
        layout.addWidget(self.filetype_label)
        layout.addWidget(self.filetype_combo)
        layout.addWidget(self.search_btn)
        layout.addWidget(self.result_list)
        layout.addWidget(self.status_label)
        layout.addWidget(self.back_btn)

        page.setLayout(layout)
        self.stack.addWidget(page)

    def init_compare_page(self):
        page = QWidget()
        layout = QVBoxLayout()

        self.compare_folder_path = QLineEdit()
        browse_btn = QPushButton("Browse")
        browse_btn.clicked.connect(self.browse_compare_folder)

        folder_layout = QHBoxLayout()
        folder_layout.addWidget(self.compare_folder_path)
        folder_layout.addWidget(browse_btn)

        self.filetype_filter_combo = QComboBox()
        self.filetype_filter_combo.addItems([".pdf", ".lst", ".txt", "All"])
        self.filetype_filter_combo.setCurrentText("All")

        self.status_filter_combo = QComboBox()
        self.status_filter_combo.addItems(["All", "Passed", "Failed"])

        refresh_btn = QPushButton("Refresh Status")
        refresh_btn.setStyleSheet("background-color: #fcdada; font-weight: bold;")
        refresh_btn.clicked.connect(self.check_compare_results)

        filter_layout = QHBoxLayout()
        filter_layout.addWidget(QLabel("File Type:"))
        filter_layout.addWidget(self.filetype_filter_combo)
        filter_layout.addWidget(QLabel("Status Filter:"))
        filter_layout.addWidget(self.status_filter_combo)
        filter_layout.addWidget(refresh_btn)

        self.compare_results_list = QListWidget()
        self.compare_results_list.itemClicked.connect(self.open_selected_file)

        self.compare_status_label = QLabel("")
        self.back_btn2 = QPushButton("⬅ Back to Main Menu")
        self.back_btn2.clicked.connect(lambda: self.stack.setCurrentIndex(0))

        layout.addLayout(folder_layout)
        layout.addLayout(filter_layout)
        layout.addWidget(self.compare_results_list)
        layout.addWidget(self.compare_status_label)
        layout.addWidget(self.back_btn2)

        page.setLayout(layout)
        self.stack.addWidget(page)

    def browse_folder(self):
        path = QFileDialog.getExistingDirectory(self, "Select Folder")
        if path:
            self.folder_path.setText(path)

    def browse_compare_folder(self):
        path = QFileDialog.getExistingDirectory(self, "Select Folder")
        if path:
            self.compare_folder_path.setText(path)

    def search_files(self):
        folder = self.folder_path.text().strip()
        keyword = self.search_text.text().strip().lower()
        ext_filter = self.filetype_combo.currentText()
        self.result_list.clear()

        if not folder or not os.path.isdir(folder):
            self.status_label.setText("⚠️ Please select a valid folder.")
            return

        match_count = 0
        total_files = 0
        for root, _, files in os.walk(folder):
            for file in files:
                if ext_filter != "All" and not file.lower().endswith(ext_filter):
                    continue
                if not any(file.lower().endswith(ext) for ext in [".sas", ".txt", ".log"]):
                    continue
                total_files += 1
                filepath = os.path.join(root, file)
                try:
                    with open(filepath, 'r', errors='ignore') as f:
                        for i, line in enumerate(f, start=1):
                            if keyword in line.lower():
                                match_count += 1
                                item = QListWidgetItem(f"{file} [Line {i}]: {line.strip()}")
                                item.setData(Qt.UserRole, (filepath, i))
                                self.result_list.addItem(item)
                except:
                    continue

        self.status_label.setText(f"✅ {match_count} matches found in {total_files} files.")

    def check_compare_results(self):
        folder = self.compare_folder_path.text().strip()
        type_filter = self.filetype_filter_combo.currentText()
        status_filter = self.status_filter_combo.currentText()
        self.compare_results_list.clear()

        if not folder or not os.path.isdir(folder):
            self.compare_status_label.setText("⚠️ Please select a valid folder.")
            return

        total = passed = failed = 0

        for root, _, files in os.walk(folder):
            for file in files:
                ext = os.path.splitext(file)[-1].lower()
                if type_filter != "All" and ext != type_filter:
                    continue
                total += 1
                filepath = os.path.join(root, file)
                content = ""
                try:
                    if ext == ".pdf":
                        doc = fitz.open(filepath)
                        content = "\n".join(page.get_text() for page in doc)
                    else:
                        with open(filepath, 'r', errors='ignore') as f:
                            content = f.read()
                except:
                    continue

                # ✅ Enhanced logic to detect comparison status
                result = None
                unequal_match = re.search(
                    r"Number of Observations with Some Compared Variables Unequal:\s+(\d+)",
                    content, re.IGNORECASE
                )
                if unequal_match:
                    unequal_count = int(unequal_match.group(1))
                    result = "Passed" if unequal_count == 0 else "Failed"
                    if result == "Passed":
                        passed += 1
                    else:
                        failed += 1
                else:
                    continue

                if status_filter == "All" or result == status_filter:
                    item = QListWidgetItem(f"{file}: {result}")
                    item.setData(Qt.UserRole, (filepath, None))
                    self.compare_results_list.addItem(item)

        self.compare_status_label.setText(
            f"🗂 Scanned: {total} files | ✅ Passed: {passed} | ❌ Failed: {failed}"
        )

    def open_selected_file(self, item):
        filepath, line_number = item.data(Qt.UserRole)
        if os.path.exists(filepath):
            launch_notepadpp(filepath, line_number)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = TextSearchTool()
    window.show()
    sys.exit(app.exec_())
