import PyPDF2
import sys

def extract_text_from_pdf(pdf_path, output_path):
    with open(pdf_path, 'rb') as file:
        reader = PyPDF2.PdfReader(file)
        with open(output_path, 'w', encoding='utf-8') as out_file:
            for page in reader.pages:
                out_file.write(page.extract_text() + '\n')

if __name__ == "__main__":
    extract_text_from_pdf("SRS_MARK_App_IEEE_v2.pdf", "srs_text.txt")
