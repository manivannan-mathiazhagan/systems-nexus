import sys
import os
import re
import fitz  # PyMuPDF
import subprocess
from PyQt5.QtWidgets import (
    QApplication, QWidget, QVBoxLayout, QLabel, QLineEdit, QPushButton,
    QFileDialog, QCheckBox, QListWidget, QMessageBox, QHBoxLayout, QListWidgetItem
)
from PyQt5.QtCore import Qt

# Editor configuration
NOTEPADPP_PATH = r"C:\Program Files\Notepad++\notepad++.exe"  # Update if installed elsewhere

class TextSearchApp(QWidget):
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Folder Text Search Tool")
        self.setGeometry(100, 100, 800, 600)
        self.layout = QVBoxLayout()

        self.folder_label = QLabel("Selected Folder: None")
        self.layout.addWidget(self.folder_label)

        self.btn_browse = QPushButton("Select Folder")
        self.btn_browse.clicked.connect(self.select_folder)
        self.layout.addWidget(self.btn_browse)

        self.search_input = QLineEdit()
        self.search_input.setPlaceholderText("Enter search text (case-insensitive)")
        self.layout.addWidget(self.search_input)

        filetype_layout = QHBoxLayout()
        self.chk_sas = QCheckBox(".sas")
        self.chk_log = QCheckBox(".log")
        self.chk_txt = QCheckBox(".txt")
        self.chk_pdf = QCheckBox(".pdf")
        filetype_layout.addWidget(self.chk_sas)
        filetype_layout.addWidget(self.chk_log)
        filetype_layout.addWidget(self.chk_txt)
        filetype_layout.addWidget(self.chk_pdf)
        self.layout.addLayout(filetype_layout)

        self.btn_search = QPushButton("Search")
        self.btn_search.clicked.connect(self.search_files)
        self.layout.addWidget(self.btn_search)

        self.results_list = QListWidget()
        self.results_list.itemClicked.connect(self.open_in_editor)
        self.layout.addWidget(self.results_list)

        self.setLayout(self.layout)
        self.folder_path = ""

    def select_folder(self):
        folder = QFileDialog.getExistingDirectory(self, "Select Folder")
        if folder:
            self.folder_path = folder
            self.folder_label.setText(f"Selected Folder: {folder}")

    def get_selected_extensions(self):
        extensions = []
        if self.chk_sas.isChecked():
            extensions.append(".sas")
        if self.chk_log.isChecked():
            extensions.append(".log")
        if self.chk_txt.isChecked():
            extensions.append(".txt")
        if self.chk_pdf.isChecked():
            extensions.append(".pdf")
        return extensions

    def search_files(self):
        self.results_list.clear()
        if not self.folder_path:
            QMessageBox.warning(self, "Warning", "Please select a folder first.")
            return

        search_term = self.search_input.text().strip()
        if not search_term:
            QMessageBox.warning(self, "Warning", "Please enter a search term.")
            return

        extensions = self.get_selected_extensions()
        if not extensions:
            QMessageBox.warning(self, "Warning", "Please select at least one file type.")
            return

        pattern = re.compile(re.escape(search_term), re.IGNORECASE)

        for root, _, files in os.walk(self.folder_path):
            for file in files:
                filepath = os.path.join(root, file)
                ext = os.path.splitext(file)[1].lower()

                if ext in extensions:
                    try:
                        if ext == ".pdf":
                            self.check_pdf(filepath)
                        else:
                            with open(filepath, "r", errors="ignore") as f:
                                for i, line in enumerate(f, 1):
                                    if pattern.search(line):
                                        display = f"{file} | Line {i}: {line.strip()}"
                                        item = QListWidgetItem(display)
                                        item.setData(Qt.UserRole, (filepath, i))
                                        self.results_list.addItem(item)
                    except Exception as e:
                        print(f"Error reading {filepath}: {e}")

    def check_pdf(self, filepath):
        try:
            doc = fitz.open(filepath)
            for page in doc:
                text = page.get_text()
                if "no unequal values were found" in text.lower() or \
                   "all matching variables are equal" in text.lower():
                    item = QListWidgetItem(f"{os.path.basename(filepath)} | ✅ PROC COMPARE PASSED")
                    item.setData(Qt.UserRole, (filepath, None))  # No line number
                    self.results_list.addItem(item)
                    break
        except Exception as e:
            print(f"PDF error in {filepath}: {e}")

    def open_in_editor(self, item):
        filepath, line = item.data(Qt.UserRole)
        if filepath.endswith(".pdf"):
            os.startfile(filepath)
        else:
            if not os.path.exists(NOTEPADPP_PATH):
                QMessageBox.warning(self, "Notepad++ Not Found", "Please check the Notepad++ path.")
                return
            try:
                if line:
                    subprocess.Popen([NOTEPADPP_PATH, "-n{}".format(line), filepath])
                else:
                    subprocess.Popen([NOTEPADPP_PATH, filepath])
            except Exception as e:
                QMessageBox.critical(self, "Error", f"Failed to open file:\n{e}")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    window = TextSearchApp()
    window.show()
    sys.exit(app.exec_())
