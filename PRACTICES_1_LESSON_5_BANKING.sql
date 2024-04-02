-- I. KHOÁ CHÍNH, KHOÁ NGOẠI, RÀNG BUỘC

CREATE TABLE CUSTOMER_INFO (
    APP_CUSTOMER_ID INT,
    APP_CUSTOMER_NUMBER VARCHAR(50),
    CUSTOMER_ID SERIAL PRIMARY KEY,
    GENDER VARCHAR(20) CHECK (GENDER IN ('MALE', 'FEMALE', 'THIRD GENDER', 'ORTHER')),
    MARITAL_STATUS VARCHAR(20) CHECK (MARITAL_STATUS IN ('SINGLE', 'MARRIED', 'NOT AVAILABLE')),
    BIRTHDAY DATE,
    BIRTHDAY_CUSTOM VARCHAR(50),
    MOBILE_NUMBER VARCHAR(15),
    RESIDENTIAL_DISTRICT VARCHAR(100),
    RESIDENTIAL_CITY VARCHAR(100),
    RESIDENTIAL_ADDRESS VARCHAR(255)
);

CREATE TABLE ACCOUNT_INFO (
    ACCOUNT_ID SERIAL PRIMARY KEY,
    ACCOUNT_TYPE VARCHAR(50),
    CUSTOMER_ID INT,
    PRODUCT_TYPE VARCHAR(50),
    INTEREST_RATE DECIMAL(10, 2),
    CREDIT_LIMIT DECIMAL(12, 2),
    OPEN_DATE DATE,
    CLOSE_DATE DATE,
    STATUS VARCHAR(20),
    FOREIGN KEY (CUSTOMER_ID) REFERENCES CUSTOMER_INFO(CUSTOMER_ID)
);


-- II - MAPPING 2 TẬP DỮ LIỆU 

-- 1 - CUSTOMER_INFO
-- Đếm số khách hàng thuộc từng tỉnh ( RESIDENTIAL_CITY) , từng quận huyện (RESIDENTIAL_DISTRICT)
SELECT 
    RESIDENTIAL_CITY,
    RESIDENTIAL_DISTRICT,
    COUNT(CUSTOMER_ID) AS NUMER_OF_CUSTOMERS
FROM CUSTOMER_INFO
GROUP BY 1,2;

-- Tính tỷ lệ khách hàng kết hôn và độc thân theo giới tính ( xem tỷ lệ khách hàng kết hôn bao nhiêu % , khách hàng độc thân bao nhiêu % )
SELECT
    GENDER,
    (SUM(CASE WHEN GENDER = 'MARRIED' THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS MARRIED_PERCENTAGE,
    (SUM(CASE WHEN GENDER = 'SINGLE' THEN 1 ELSE 0 END) / COUNT(*)) * 100 AS SINGLE_PERCENTAGE
FROM CUSTOMER_INFO
GROUP BY 1;

-- Độ tuổi trung bình của khách hàng là bao nhiêu 
SELECT AVG(EXTRACT(YEAR FROM AGE(NOW(), BIRTHDAY))) AS average_age
FROM CUSTOMER_INFO;

-- 2 - ACCOUNT_INFO
-- Tính lãi suất bình quân của các tài khoản còn hạn mức tín dụng dưới 10tr , 10-20tr , > 20tr (CREDIT_LIMIT <> 0 )
SELECT 
    CASE WHEN CREDIT_LIMIT < 10000000 THEN 'Below 10TR'
         WHEN CREDIT_LIMIT BETWEEN 10000000 AND 20000000 THEN '10TR to 20TR'
         WHEN CREDIT_LIMIT > 20000000 THEN 'Above 20TR' END AS Credit_Limit_Category,
    AVG(INTEREST_RATE) AS Average_Interest_Rate
FROM ACCOUNT_INFO
WHERE CREDIT_LIMIT <> 0
GROUP BY 
    CASE WHEN CREDIT_LIMIT < 10000000 THEN 'Below 10TR'
         WHEN CREDIT_LIMIT BETWEEN 10000000 AND 20000000 THEN '10TR to 20TR'
         WHEN CREDIT_LIMIT > 20000000 THEN 'Above 20TR' END;


-- Lọc ra danh sách quý nào mở tài khoản nhiều nhất trong danh sách 

SELECT QUARTER, COUNT(*) AS NUMBER_OF_ACCOUNTS
FROM (
    SELECT 
        *,
        CASE 
            WHEN EXTRACT(MONTH FROM OPEN_DATE) BETWEEN 1 AND 3 THEN 'Q1'
            WHEN EXTRACT(MONTH FROM OPEN_DATE) BETWEEN 4 AND 6 THEN 'Q2'
            WHEN EXTRACT(MONTH FROM OPEN_DATE) BETWEEN 7 AND 9 THEN 'Q3'
            ELSE 'Q4'
        END AS QUARTER
    FROM ACCOUNT_INFO
) AS quarters
GROUP BY QUARTER
ORDER BY NUMBER_OF_ACCOUNTS DESC
LIMIT 1;
-- Lọc ra thời gian đóng tài khoản của các tài khoản đóng ( CLOSE_DATE is not null ) và tìm ra tài khoản nào đóng ngắn nhất , tài khoản nào đóng dài nhất.
-- Lọc ra thời gian đóng tài khoản của các tài khoản đóng ( CLOSE_DATE is not null ) 
SELECT
    ACCOUNT_ID,
    CLOSE_DATE
FROM ACCOUNT_INFO
WHERE CLOSE_DATE IS NOT NULL
-- Tìm ra tài khoản nào đóng ngắn nhất , tài khoản nào đóng dài nhất.
SELECT
    ACCOUNT_ID,
    MIN(DATEDIFF(CLOSE_DATE, OPEN_DATE)) AS MIN_DURATION
FROM ACCOUNT_INFO
WHERE CLOSE_DATE IS NOT NULL
GROUP BY ACCOUNT_ID
UNION ALL 
SELECT
    ACCOUNT_ID,
    MAX(DATEDIFF(CLOSE_DATE, OPEN_DATE)) AS MAX_DURATION
FROM ACCOUNT_INFO
WHERE CLOSE_DATE IS NOT NULL
GROUP BY ACCOUNT_ID;

-- 3 - SaoKeDuNo
-- Tính tổng dư nợ theo từng ngày trong tập danh sách , và tìm ra dư nợ (OUTSTANDING_PRINCIPAL ) cao nhất / nhỏ nhất trong tất cả các ngày.
-- Tính tổng dư nợ theo từng ngày
SELECT 
    PROCESS_DT, 
    SUM(OUTSTANDING_PRINCIPAL) AS TOTAL_OUTSTANDING_PRINCIPAL
FROM 
    SAO_KE_DU_NO
GROUP BY 
    PROCESS_DT;

-- Tìm dư nợ (OUTSTANDING_PRINCIPAL) cao nhất
SELECT 
    *
FROM 
    SAO_KE_DU_NO
WHERE 
    OUTSTANDING_PRINCIPAL = (
        SELECT 
            MAX(OUTSTANDING_PRINCIPAL)
        FROM 
            SAO_KE_DU_NO
    );

-- Tìm dư nợ (OUTSTANDING_PRINCIPAL) nhỏ nhất
SELECT 
    *
FROM 
    SAO_KE_DU_NO
WHERE 
    OUTSTANDING_PRINCIPAL = (
        SELECT 
            MIN(OUTSTANDING_PRINCIPAL)
        FROM 
            SAO_KE_DU_NO
    );

-- Lấy ra tỷ lệ nhóm nợ xấu cao nhất theo khu vực với cơ chế quy nhóm nợ theo ngân hàng nhà nước
SELECT 
    REGION_CDE,
    GROUP_CONCAT(
        CASE 
            WHEN DPD < 9 THEN 'Nhóm nợ 1'
            WHEN DPD >= 10 AND DPD <= 90 THEN 'Nhóm nợ 2'
            WHEN DPD >= 91 AND DPD <= 180 THEN 'Nhóm nợ 3'
            WHEN DPD >= 181 AND DPD <= 360 THEN 'Nhóm nợ 4'
            ELSE 'Nhóm nợ 5'
        END
        ORDER BY DPD
    ) AS GROUPS,
    COUNT(*) AS TOTAL_CUSTOMERS,
    SUM(OUTSTANDING_PRINCIPAL) AS TOTAL_OUTSTANDING_PRINCIPAL,
    SUM(
        CASE 
            WHEN DPD >= 91 THEN OUTSTANDING_PRINCIPAL
            ELSE 0
        END
    ) AS BAD_DEBT_OUTSTANDING_PRINCIPAL
FROM 
    SAO_KE_DU_NO
GROUP BY 
    REGION_CDE;

-- TEP SO_PHU_TAI_KHOAN
-- Lấy ra thời điểm giao dịch rút tiền cao nhất của tài khoản trong tập
SELECT 
    ACCOUNT_ID, 
    MAX(AMOUNT) AS MAX_WITHDRAWAL_AMOUNT, 
    TXN_DATE
FROM SO_PHU_TAI_KHOAN
WHERE TRANSACTION_DESC = 'Rút tiền'
GROUP BY ACCOUNT_ID, TXN_DATE;

-- Lấy tỷ lệ phí trung bình theo tài khoản so với tổng dư nợ mà tài khoản đó đã thực hiện trong danh sách
SELECT ACCOUNT_ID, AVG(FEE / AMOUNT) AS AVG_FEE_RATIO
FROM SO_PHU_TAI_KHOAN
GROUP BY ACCOUNT_ID;

-- Lấy ra tổng amount theo tuần trong tập danh sách
SELECT EXTRACT(WEEK FROM TXN_DATE) AS WEEK_NUMBER,
       SUM(AMOUNT) AS TOTAL_AMOUNT
FROM SO_PHU_TAI_KHOAN
WHERE EXTRACT(ISODOW FROM TXN_DATE) BETWEEN 1 AND 6
GROUP BY EXTRACT(WEEK FROM TXN_DATE);
