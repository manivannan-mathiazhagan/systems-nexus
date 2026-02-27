import sys
import os
import re
import fitz
import subprocess
from collections import defaultdict
from PyQt5.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QLabel, QLineEdit, QPushButton,
    QFileDialog, QCheckBox, QListWidget, QMessageBox, QHBoxLayout, QComboBox,
    QStackedLayout, QListWidgetItem, QFrame
)
from PyQt5.QtCore import Qt
from PyQt5.QtGui import QFont

NOTEPADPP_PATH = r"C:\Program Files\Notepad++\notepad++.exe"

class MainWindow(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Case-Insensitive Text Search & PROC COMPARE Results Checker")
        self.setGeometry(100, 100, 950, 680)
        self.layout = QVBoxLayout(self)
        self.stack = QStackedLayout()
        self.main_page = self.create_main_page()
        self.text_search_page = TextSearchPage(self.stack)
        self.proc_compare_page = ProcComparePage(self.stack)

        self.stack.addWidget(self.main_page)
        self.stack.addWidget(self.text_search_page)
        self.stack.addWidget(self.proc_compare_page)

        self.layout.addLayout(self.stack)

    def create_main_page(self):
        main = QWidget()
        layout = QVBoxLayout()

        title = QLabel("Case-Insensitive Text Search & PROC COMPARE Results Checker")
        title.setFont(QFont("Arial", 16, QFont.Bold))
        title.setAlignment(Qt.AlignCenter)
        layout.addWidget(title)

        btn1 = QPushButton("🔍 Search Text in SAS/TXT/LOG Files")
        btn1.setStyleSheet("background-color: #0078d7; color: white; font-weight: bold; padding: 10px;")
        btn1.clicked.connect(lambda: self.stack.setCurrentWidget(self.text_search_page))
        layout.addWidget(btn1)

        btn2 = QPushButton("📊 Check PROC COMPARE Status (PDF, LST, LOG, TXT)")
        btn2.setStyleSheet("background-color: #28a745; color: white; font-weight: bold; padding: 10px;")
        btn2.clicked.connect(lambda: self.stack.setCurrentWidget(self.proc_compare_page))
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

        header = QLabel("🔍 Case-Insensitive Text Search")
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
        self.btn_search.setStyleSheet("background-color: #0078d7; color: white; font-weight: bold;")
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

class ProcComparePage(QWidget):
    def __init__(self, stack):
        super().__init__()
        self.stack = stack
        self.folder_path = ""
        self.results = []
        self.setLayout(QVBoxLayout())

        header = QLabel("📊 PROC COMPARE Results Checker")
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

        filter_layout = QHBoxLayout()
        self.btn_check = QPushButton("Refresh Status")
        self.btn_check.setStyleSheet("background-color: orange; font-weight: bold;")
        self.btn_check.clicked.connect(self.check_files)
        filter_layout.addWidget(self.btn_check)

        filter_layout.addWidget(QLabel("Show Results:"))
        self.filter_combo = QComboBox()
        self.filter_combo.addItems(["All", "Passed Only", "Failed Only"])
        self.filter_combo.currentIndexChanged.connect(self.apply_filter)
        filter_layout.addWidget(self.filter_combo)
        self.layout().addLayout(filter_layout)

        self.summary_label = QLabel("")
        self.layout().addWidget(self.summary_label)

        self.results_list = QListWidget()
        self.results_list.itemClicked.connect(self.open_file)
        self.layout().addWidget(self.results_list)

    def select_folder(self):
        folder = QFileDialog.getExistingDirectory(self, "Select Folder")
        if folder:
            self.folder_path = folder
            self.folder_label.setText(f"Selected Folder: {folder}")

    def check_files(self):
        self.results = []
        self.results_list.clear()
        self.summary_label.clear()

        if not self.folder_path:
            QMessageBox.warning(self, "Warning", "Please select a folder first.")
            return

        total, passed = 0, 0
        exts = [".pdf", ".log", ".txt", ".lst"]
        pattern1 = "no unequal values were found"
        pattern2 = "all matching variables are equal"

        for root, _, files in os.walk(self.folder_path):
            for file in files:
                ext = os.path.splitext(file)[1].lower()
                if ext not in exts:
                    continue
                filepath = os.path.join(root, file)
                total += 1
                try:
                    if ext == ".pdf":
                        doc = fitz.open(filepath)
                        text = "\n".join([p.get_text() for p in doc])
                    else:
                        with open(filepath, "r", errors="ignore") as f:
                            text = f.read()

                    if pattern1 in text.lower() or pattern2 in text.lower():
                        self.results.append((file, filepath, "PASSED"))
                        passed += 1
                    else:
                        self.results.append((file, filepath, "FAILED"))
                except Exception as e:
                    print(f"Read error: {filepath} - {e}")

        self.summary_label.setText(f"Files Passed: {passed} / {total}")
        self.apply_filter()

    def apply_filter(self):
        self.results_list.clear()
        selected = self.filter_combo.currentText()
        for file, path, status in self.results:
            if selected == "Passed Only" and status != "PASSED":
                continue
            if selected == "Failed Only" and status != "FAILED":
                continue
            tag = "✅" if status == "PASSED" else "❌"
            item = QListWidgetItem(f"{file} | {tag} {status}")
            item.setData(Qt.UserRole, path)
            self.results_list.addItem(item)

    def open_file(self, item):
        filepath = item.data(Qt.UserRole)
        if filepath.lower().endswith(".pdf"):
            os.startfile(filepath)
        else:
            subprocess.Popen([NOTEPADPP_PATH, filepath])

if __name__ == "__main__":
    app = QApplication(sys.argv)
    win = MainWindow()
    win.show()
    sys.exit(app.exec_())
