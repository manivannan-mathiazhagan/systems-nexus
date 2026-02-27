import sys
import os
import re
import fitz
import subprocess
from collections import defaultdict
from PyQt5.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QLabel, QLineEdit, QPushButton,
    QFileDialog, QCheckBox, QListWidget, QMessageBox, QHBoxLayout,
    QStackedLayout, QListWidgetItem, QFrame
)
from PyQt5.QtCore import Qt
from PyQt5.QtGui import QFont, QColor

NOTEPADPP_PATH = r"C:\Program Files\Notepad++\notepad++.exe"

class MainWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Text & PDF Compare Tool")
        self.setGeometry(100, 100, 900, 650)
        self.layout = QVBoxLayout(self)
        self.stack = QStackedLayout()
        self.main_page = self.create_main_page()
        self.text_search_page = TextSearchPage(self.stack)
        self.pdf_check_page = PDFCheckPage(self.stack)

        self.stack.addWidget(self.main_page)
        self.stack.addWidget(self.text_search_page)
        self.stack.addWidget(self.pdf_check_page)

        self.layout.addLayout(self.stack)

    def create_main_page(self):
        main = QWidget()
        layout = QVBoxLayout()

        title = QLabel("Choose an Option")
        title.setFont(QFont("Arial", 16, QFont.Bold))
        title.setAlignment(Qt.AlignCenter)
        layout.addWidget(title)

        btn1 = QPushButton("🔍 Search Text in SAS/TXT/LOG Files")
        btn1.setStyleSheet("background-color: #0078d7; color: white; font-weight: bold; padding: 10px;")
        btn1.clicked.connect(lambda: self.stack.setCurrentWidget(self.text_search_page))
        layout.addWidget(btn1)

        btn2 = QPushButton("📄 Check PDF PROC COMPARE Status")
        btn2.setStyleSheet("background-color: #28a745; color: white; font-weight: bold; padding: 10px;")
        btn2.clicked.connect(lambda: self.stack.setCurrentWidget(self.pdf_check_page))
        layout.addWidget(btn2)

        layout.addStretch()
        main.setLayout(layout)
        return main

class TextSearchPage(QWidget):
    def __init__(self, stack):
        super().__init__()
        self.stack = stack
        self.folder_path = ""
        self.setLayout(QVBoxLayout())

        header = QLabel("🔍 Text Search in Files")
        header.setFont(QFont("Arial", 14, QFont.Bold))
        self.layout().addWidget(header)

        self.folder_label = QLabel("Selected Folder: None")
        self.layout().addWidget(self.folder_label)

        btn_layout = QHBoxLayout()
        self.btn_browse = QPushButton("Select Folder")
        self.btn_browse.clicked.connect(self.select_folder)
        btn_layout.addWidget(self.btn_browse)

        self.back_btn = QPushButton("Back to Main")
        self.back_btn.clicked.connect(lambda: self.stack.setCurrentIndex(0))
        btn_layout.addWidget(self.back_btn)

        self.layout().addLayout(btn_layout)

        self.search_input = QLineEdit()
        self.search_input.setPlaceholderText("Enter search text (case-insensitive)")
        self.layout().addWidget(self.search_input)

        ft_layout = QHBoxLayout()
        self.chk_sas = QCheckBox(".sas")
        self.chk_log = QCheckBox(".log")
        self.chk_txt = QCheckBox(".txt")
        ft_layout.addWidget(self.chk_sas)
        ft_layout.addWidget(self.chk_log)
        ft_layout.addWidget(self.chk_txt)
        self.layout().addLayout(ft_layout)

        self.btn_search = QPushButton("Search")
        self.btn_search.clicked.connect(self.search_files)
        self.layout().addWidget(self.btn_search)

        self.summary_label = QLabel("")
        self.layout().addWidget(self.summary_label)

        line = QFrame()
        line.setFrameShape(QFrame.HLine)
        self.layout().addWidget(line)

        self.results_list = QListWidget()
        self.results_list.itemClicked.connect(self.open_in_editor)
        self.layout().addWidget(self.results_list)

    def select_folder(self):
        folder = QFileDialog.getExistingDirectory(self, "Select Folder")
        if folder:
            self.folder_path = folder
            self.folder_label.setText(f"Selected Folder: {folder}")

    def get_extensions(self):
        exts = []
        if self.chk_sas.isChecked():
            exts.append(".sas")
        if self.chk_log.isChecked():
            exts.append(".log")
        if self.chk_txt.isChecked():
            exts.append(".txt")
        return exts

    def search_files(self):
        self.results_list.clear()
        self.summary_label.clear()
        if not self.folder_path or not self.search_input.text().strip():
            QMessageBox.warning(self, "Warning", "Select folder and enter search text.")
            return

        exts = self.get_extensions()
        if not exts:
            QMessageBox.warning(self, "Warning", "Select at least one file type.")
            return

        pattern = re.compile(re.escape(self.search_input.text().strip()), re.IGNORECASE)
        stats = defaultdict(lambda: {'total': 0, 'matched': 0})

        for root, _, files in os.walk(self.folder_path):
            for file in files:
                ext = os.path.splitext(file)[1].lower()
                if ext in exts:
                    stats[ext]['total'] += 1
                    filepath = os.path.join(root, file)
                    try:
                        with open(filepath, "r", errors="ignore") as f:
                            matched = False
                            for i, line in enumerate(f, 1):
                                if pattern.search(line):
                                    display = f"{file} | Line {i}: {line.strip()}"
                                    item = QListWidgetItem(display)
                                    item.setData(Qt.UserRole, (filepath, i))
                                    self.results_list.addItem(item)
                                    matched = True
                            if matched:
                                stats[ext]['matched'] += 1
                    except Exception as e:
                        print(f"Read error: {filepath} - {e}")

        summary = "\n".join([f"{ext.upper()}: {d['matched']} / {d['total']} matched"
                             for ext, d in stats.items()])
        self.summary_label.setText(summary)

    def open_in_editor(self, item):
        filepath, line = item.data(Qt.UserRole)
        if os.path.exists(filepath):
            subprocess.Popen([NOTEPADPP_PATH, f"-n{line}", filepath])

class PDFCheckPage(QWidget):
    def __init__(self, stack):
        super().__init__()
        self.stack = stack
        self.folder_path = ""
        self.setLayout(QVBoxLayout())

        header = QLabel("📄 PROC COMPARE PDF Status Check")
        header.setFont(QFont("Arial", 14, QFont.Bold))
        self.layout().addWidget(header)

        self.folder_label = QLabel("Selected Folder: None")
        self.layout().addWidget(self.folder_label)

        btn_layout = QHBoxLayout()
        self.btn_browse = QPushButton("Select Folder")
        self.btn_browse.clicked.connect(self.select_folder)
        btn_layout.addWidget(self.btn_browse)

        self.back_btn = QPushButton("Back to Main")
        self.back_btn.clicked.connect(lambda: self.stack.setCurrentIndex(0))
        btn_layout.addWidget(self.back_btn)

        self.layout().addLayout(btn_layout)

        self.btn_check = QPushButton("Refresh Status")
        self.btn_check.clicked.connect(self.check_pdfs)
        self.btn_check.setStyleSheet("background-color: orange; font-weight: bold;")
        self.layout().addWidget(self.btn_check)

        self.summary_label = QLabel("")
        self.layout().addWidget(self.summary_label)

        self.results_list = QListWidget()
        self.results_list.itemClicked.connect(self.open_pdf)
        self.layout().addWidget(self.results_list)

    def select_folder(self):
        folder = QFileDialog.getExistingDirectory(self, "Select Folder")
        if folder:
            self.folder_path = folder
            self.folder_label.setText(f"Selected Folder: {folder}")

    def check_pdfs(self):
        self.results_list.clear()
        self.summary_label.clear()
        if not self.folder_path:
            QMessageBox.warning(self, "Warning", "Please select a folder first.")
            return

        total = 0
        passed = 0

        for root, _, files in os.walk(self.folder_path):
            for file in files:
                if file.lower().endswith(".pdf"):
                    total += 1
                    filepath = os.path.join(root, file)
                    try:
                        doc = fitz.open(filepath)
                        text = ""
                        for page in doc:
                            text += page.get_text()
                        if "no unequal values were found" in text.lower() or \
                           "all matching variables are equal" in text.lower():
                            result = f"{file} | ✅ PASSED"
                            passed += 1
                        else:
                            result = f"{file} | ❌ FAILED"
                        item = QListWidgetItem(result)
                        item.setData(Qt.UserRole, filepath)
                        self.results_list.addItem(item)
                    except Exception as e:
                        print(f"Error reading PDF: {e}")

        self.summary_label.setText(f"PDFs Passed: {passed} / {total}")

    def open_pdf(self, item):
        filepath = item.data(Qt.UserRole)
        os.startfile(filepath)

if __name__ == "__main__":
    app = QApplication(sys.argv)
    win = MainWindow()
    win.show()
    sys.exit(app.exec_())
