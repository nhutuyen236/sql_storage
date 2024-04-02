-- I. KHOÁ CHÍNH, KHOÁ NGOẠI, RÀNG BUỘC
-- Tạo quan hệ và khai báo tất cả các ràng buộc khóa chính, khóa ngoại. Thêm vào 3 thuộc tính GHICHU, DIEMTB, XEPLOAI cho quan hệ HOCVIEN. 
CREATE TABLE HOCVIEN (
    MAHV CHAR(5) PRIMARY KEY, 
    HO VARCHAR(40), 
    TEN VARCHAR(10), 
    NGSINH SMALLDATETIME, 
    GIOITINH VARCHAR(3) CHECK (GIOITINH IN ('NAM', 'NU')), 
    NOISINH VARCHAR(40), 
    MALOP CHAR(3),
    GHICHU VARCHAR(50), 
    DIEMTB NUMERIC(4,2),
    XEPLOAI VARCHAR(50),
    FOREIGN KEY (MALOP) REFERENCES LOP(MALOP),
    CONSTRAINT CHK_AGE CHECK (DATEDIFF(YEAR, NGSINH, GETDATE()) >= 18) -- Constraint to ensure the student is at least 18 years old
);

CREATE TABLE LOP (
    MALOP CHAR(3) PRIMARY KEY, 
    TENLOP VARCHAR(40), 
    TRGLOP CHAR(5), 
    SISO TINYINT, 
    MAGVCN CHAR(4),
    FOREIGN KEY (MAGVCN) REFERENCES GIAOVIEN(MAGV)
);
CREATE TABLE KHOA (
    MAKHOA VARCHAR(4) PRIMARY KEY, 
    TENKHOA VARCHAR(40), 
    NGTLAP SMALLDATETIME, 
    TRGKHOA CHAR(4),
    FOREIGN KEY (TRGKHOA) REFERENCES GIAOVIEN(MAGV)
);
CREATE TABLE MONHOC (
    MAMH VARCHAR(10) PRIMARY KEY, 
    TENMH VARCHAR(40), 
    TCLT TINYINT, 
    TCTH TINYINT, 
    MAKHOA VARCHAR(4),
    FOREIGN KEY (MAKHOA) REFERENCES KHOA(MAKHOA)
);

CREATE TABLE DIEUKIEN (
    MAMH VARCHAR(10), 
    MAMH_TRUOC VARCHAR(10) 
);

CREATE TABLE GIAOVIEN (
    MAGV CHAR(4) PRIMARY KEY, 
    HOTEN VARCHAR(40), 
    HOCVI VARCHAR(10) CHECK (HOCVI IN ('CN', 'KS', 'Ths', 'TS', 'PTS')), -- Constraint to ensure HOCVI contains only specific values
    HOCHAM VARCHAR(10),
    GIOITINH VARCHAR(3), 
    NGSINH SMALLDATETIME, 
    NGVL SMALLDATETIME,
    HESO NUMERIC(4,2), 
    MUCLUONG MONEY, 
    MAKHOA VARCHAR(4),
    FOREIGN KEY (MAKHOA) REFERENCES KHOA(MAKHOA)
);


CREATE TABLE GIANGDAY (
    MALOP CHAR(3), 
    MAMH VARCHAR(10), 
    MAGV CHAR(4), 
    HOCKY TINYINT, 
    NAM SMALLINT, 
    TUNGAY SMALLDATETIME, 
    DENNGAY SMALLDATETIME,
    CONSTRAINT CHK_DATE_RANGE CHECK (TUNGAY < DENNGAY), -- Constraint to ensure TUNGAY is before DENNGAY
    FOREIGN KEY (MALOP) REFERENCES LOP(MALOP),
    FOREIGN KEY (MAMH) REFERENCES MONHOC(MAMH),
    FOREIGN KEY (MAGV) REFERENCES GIAOVIEN(MAGV)
);

CREATE TABLE KETQUATHI (
    MAHV CHAR(5), 
    MAMH VARCHAR(10), 
    LANTHI TINYINT, 
    NGTHI SMALLDATETIME, 
    DIEM NUMERIC(4,2), 
    KQUA VARCHAR(10) AS (CASE WHEN DIEM >= 5 THEN 'Dat' ELSE 'Khong dat' END),
    CONSTRAINT CHK_DIEM_RANGE CHECK (DIEM >= 0 AND DIEM <= 10) 
);

-- II. MAPPING 2 TẬP DỮ LIỆU (tổng hợp cả các phần đã học của những bài học trước)
-- 1 - In ra danh sách (mã học viên, họ tên, ngày sinh, mã lớp) lớp trưởng của các lớp. 
In ra bảng điểm khi thi (mã học viên, họ tên , lần thi, điểm số) môn CTRR của lớp “K12”, sắp xếp theo tên, họ học viên. 
In ra danh sách những học viên (mã học viên, họ tên) và những môn học mà học viên đó thi lần thứ nhất đã đạt. 
In ra danh sách học viên (mã học viên, họ tên) của lớp “K11” thi môn CTRR không đạt (ở lần thi 1). 
* Danh sách học viên (mã học viên, họ tên) của lớp “K” thi môn CTRR không đạt (ở tất cả các lần thi). 
Tìm tên những môn học mà giáo viên có tên “Tran Tam Thanh” dạy trong học kỳ 1 năm 2006. 
Tìm những môn học (mã môn học, tên môn học) mà giáo viên chủ nhiệm lớp “K11” dạy trong học kỳ 1 năm 2006. 
Tìm họ tên lớp trưởng của các lớp mà giáo viên có tên “Nguyen To Lan” dạy môn “Co So Du Lieu”. 
In ra danh sách những môn học (mã môn học, tên môn học) phải học liền trước môn “Co So Du Lieu”. 
Môn “Cau Truc Roi Rac” là môn bắt buộc phải học liền trước những môn học (mã môn học, tên môn học) nào. 
Tìm họ tên giáo viên dạy môn CTRR cho cả hai lớp “K11” và “K12” trong cùng học kỳ 1 năm 2006. 
Tìm những học viên (mã học viên, họ tên) thi không đạt môn CSDL ở lần thi thứ 1 nhưng chưa thi lại môn này. 
Tìm giáo viên (mã giáo viên, họ tên) không được phân công giảng dạy bất kỳ môn học nào. 
Tìm giáo viên (mã giáo viên, họ tên) không được phân công giảng dạy bất kỳ môn học nào thuộc khoa giáo viên đó phụ trách. 
Tìm họ tên các học viên thuộc lớp “K11” thi một môn bất kỳ quá 3 lần vẫn “Khong dat” hoặc thi lần thứ 2 môn CTRR được 5 điểm. 
Tìm họ tên giáo viên dạy môn CTRR cho ít nhất hai lớp trong cùng một học kỳ của một năm học. 
Danh sách học viên và điểm thi môn CSDL (chỉ lấy điểm của lần thi sau cùng). 
Danh sách học viên và điểm thi môn “Co So Du Lieu” (chỉ lấy điểm cao nhất của các lần thi). 
Khoa nào (mã khoa, tên khoa) được thành lập sớm nhất. 
Có bao nhiêu giáo viên có học hàm là “GS” hoặc “PGS”. 
Thống kê có bao nhiêu giáo viên có học vị là “CN”, “KS”, “Ths”, “TS”, “PTS” trong mỗi khoa. 
Mỗi môn học thống kê số lượng học viên theo kết quả (đạt và không đạt). 
Tìm giáo viên (mã giáo viên, họ tên) là giáo viên chủ nhiệm của một lớp, đồng thời dạy cho lớp đó ít nhất một môn học. 
Tìm họ tên lớp trưởng của lớp có sỉ số cao nhất. 
* Tìm họ tên những LOPTRG thi không đạt quá 3 môn (mỗi môn đều thi không đạt ở tất cả các lần thi). 
Tìm học viên (mã học viên, họ tên) có số môn đạt điểm 9,10 nhiều nhất. 
Trong từng lớp, tìm học viên (mã học viên, họ tên) có số môn đạt điểm 9,10 nhiều nhất. 
Trong từng học kỳ của từng năm, mỗi giáo viên phân công dạy bao nhiêu môn học, bao nhiêu lớp. 
Trong từng học kỳ của từng năm, tìm giáo viên (mã giáo viên, họ tên) giảng dạy nhiều nhất. 
Tìm môn học (mã môn học, tên môn học) có nhiều học viên thi không đạt (ở lần thi thứ 1) nhất. 
Tìm học viên (mã học viên, họ tên) thi môn nào cũng đạt (chỉ xét lần thi thứ 1). 
* Tìm học viên (mã học viên, họ tên) thi môn nào cũng đạt (chỉ xét lần thi sau cùng). 
* Tìm học viên (mã học viên, họ tên) đã thi tất cả các môn đều đạt (chỉ xét lần thi thứ 1). 
* Tìm học viên (mã học viên, họ tên) đã thi tất cả các môn đều đạt (chỉ xét lần thi sau cùng). 
** Tìm học viên (mã học viên, họ tên) có điểm thi cao nhất trong từng môn (lấy điểm ở lần thi sau cùng). 
