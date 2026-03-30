import pandas as pd
import json
import sys


def excel_to_questions_json(excel_file_path, output_json_path='questions.json'):
    """
    Đọc file Excel và chuyển đổi thành file JSON với format câu hỏi quiz
    
    Args:
        excel_file_path: Đường dẫn đến file Excel
        output_json_path: Đường dẫn file JSON output (mặc định: questions.json)
    """
    all_questions = []
    
    try:
        # Đọc tất cả các sheet trong file Excel
        excel_file = pd.ExcelFile(excel_file_path)
        
        print(f"Đang đọc file Excel: {excel_file_path}")
        print(f"Tìm thấy {len(excel_file.sheet_names)} sheet(s): {excel_file.sheet_names}")
        
        # Duyệt qua từng sheet
        for sheet_name in excel_file.sheet_names:
            print(f"\nĐang xử lý sheet: {sheet_name}")
            
            # Đọc sheet, bỏ qua 2 dòng đầu (header_row=2 nghĩa là dòng 3 là dòng đầu tiên có dữ liệu)
            df = pd.read_excel(excel_file_path, sheet_name=sheet_name, header=None)
            
            # Đọc từ dòng 3 (index 2), cột B (index 1) và cột C (index 2)
            question_count = 0
            for index in range(2, len(df)):  # Bắt đầu từ dòng 3 (index 2)
                question = df.iloc[index, 1]  # Cột B (index 1)
                answer = df.iloc[index, 2]     # Cột C (index 2)
                
                # Bỏ qua dòng trống
                if pd.isna(question) or pd.isna(answer):
                    continue
                
                # Chuyển đổi answer thành string và chuẩn hóa
                answer_str = str(answer).strip()
                
                # Xác định correctAnswer dựa trên đáp án
                if answer_str.lower() == "an toàn" or answer_str.lower() == "an toan":
                    correct_answer = "A"
                elif answer_str.lower() == "không an toàn" or answer_str.lower() == "khong an toan":
                    correct_answer = "B"
                else:
                    print(f"  ⚠ Cảnh báo: Đáp án không hợp lệ ở dòng {index + 1}: '{answer_str}'")
                    # Mặc định là An toàn
                    correct_answer = "A"
                
                # Tạo object câu hỏi
                question_obj = {
                    "question": str(question).strip(),
                    "optionA": "An toàn",
                    "optionB": "Không an toàn",
                    "correctAnswer": correct_answer
                }
                
                all_questions.append(question_obj)
                question_count += 1
            
            print(f"  ✓ Đã xử lý {question_count} câu hỏi từ sheet '{sheet_name}'")
        
        # Ghi ra file JSON
        with open(output_json_path, 'w', encoding='utf-8') as json_file:
            json.dump(all_questions, json_file, ensure_ascii=False, indent=2)
        
        print(f"\n✓ Hoàn thành! Đã tạo file '{output_json_path}' với {len(all_questions)} câu hỏi.")
        return True
        
    except FileNotFoundError:
        print(f"✗ Lỗi: Không tìm thấy file '{excel_file_path}'")
        return False
    except Exception as e:
        print(f"✗ Lỗi: {str(e)}")
        import traceback
        traceback.print_exc()
        return False


if __name__ == "__main__":
    # Kiểm tra arguments
    if len(sys.argv) < 2:
        print("Cách sử dụng:")
        print("  python excel_to_questions.py <đường_dẫn_file_excel> [đường_dẫn_file_json_output]")
        print("\nVí dụ:")
        print("  python excel_to_questions.py questions.xlsx")
        print("  python excel_to_questions.py questions.xlsx output.json")
        sys.exit(1)
    
    excel_path = sys.argv[1]
    json_path = sys.argv[2] if len(sys.argv) > 2 else "questions.json"
    
    success = excel_to_questions_json(excel_path, json_path)
    sys.exit(0 if success else 1)
