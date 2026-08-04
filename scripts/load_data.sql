-- HR database setup with S3 storage integration and staging
-- Co-authored with CoCo
CREATE OR REPLACE WAREHOUSE HR_WH
AUTO_SUSPEND = 500
AUTO_RESUME = TRUE

USE WAREHOUSE HR_WH;

CREATE IF NOT EXISTS DATABASE HR_DB;
USE DATABASE HR_DB;


CREATE SCHEMA HR_DB.RAW;
CREATE SCHEMA HR_DB.ANALYTICS;

USE SCHEMA RAW;


SHOW ROLES;
SHOW WAREHOUSES;
SHOW SCHEMAS;
SHOW GRANTS ON WAREHOUSE HR_WH


/* ========== CHANGE TIMEXONE TO +5:50 GMT KOLAKATA========================*/
SHOW PARAMETERS LIKE 'TIMEZONE' IN ACCOUNT;    

ALTER ACCOUNT SET TIMEZONE = 'Asia/Kolkata';
SELECT CURRENT_TIMESTAMP();


/*======================================================================================================================
                                            -------------- HR PROJECT_01 -----------------
========================================================================================================================*/

/* ============= EMPLOYEES TABLE CREATION - RAW LAYER ================ */


CREATE OR REPLACE TABLE EMPLOYEES (
    EMPLOYEE_ID     VARCHAR(20) PRIMARY KEY,
    FIRST_NAME      VARCHAR(40),
    LAST_NAME       VARCHAR(40),
    EMAIL           VARCHAR(100),
    PHONE           VARCHAR(30),
    DEPARTMENT_ID   VARCHAR(20),
    JOB_TITLE       VARCHAR(70),
    HIRE_DATE       VARCHAR(30),
    SALARY          DECIMAL(12,2),
    MANAGER_ID      VARCHAR(20),
    GENDER          VARCHAR(30),
    DOB             VARCHAR(30),
    STATUS          VARCHAR(20),
    WORK_LOACTION   VARCHAR(50)
    
)

/* ============= DEPARTMENT TABLE CREATION - RAW LAYER ================ */

CREATE OR REPLACE TABLE DEPARTMENTS (
    DEPARTMENT_ID       VARCHAR(20),
    DEPARTMENT_NAME     VARCHAR(100),
    DIVISION            VARCHAR(50),
    DEPARTMENT_HEAD     VARCHAR(50),
    DEPARTMENT_EMAIL    VARCHAR(100),
    LOCATION            VARCHAR(70)
    
)


/* ============= ATTENDANCES TABLE CREATION ================ */


CREATE OR REPLACE TABLE ATTENDANCES (
    ATTENDANCE_ID       VARCHAR(20),
    EMPLOYEE_ID         VARCHAR(20),
    ATTENDANCE_DATE     VARCHAR(50),
    ATTENDANCE_STATUS   VARCHAR(30),
    CHECK_IN_TIME       TIME,
    CHECK_OUT_TIME      TIME,
    WORK_HOUR           FLOAT,
    LEAVE_TYPE          VARCHAR(30),
    REMARK              VARCHAR(30)
    
)

/*=======================================================
       ------ STORAGE INTEGRATION CREATION -------
=========================================================*/
CREATE OR REPLACE STORAGE INTEGRATION HR_DATA_LOAD
    TYPE = EXTERNAL_STAGE
    ENABLED = TRUE
    STORAGE_PROVIDER = 's3'
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::7672618000000:role/hr-project-role' -- Your aws role arn
    STORAGE_ALLOWED_LOCATIONS = ('s3://hr-project-data/')   -- Your bucket url

 DESC INTEGRATION HR_DATA_LOAD;


/*=======================================================
       ------ FILE FORMAT CREATION -------
=========================================================*/
 

CREATE OR REPLACE FILE FORMAT CSV_FORMAT
    TYPE = 'CSV',
    FIELD_DELIMITER = ',',
    RECORD_DELIMITER = '\n',
    SKIP_HEADER = 1,
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'    


/*=======================================================
       ------ STAGE FOR EMPLOYEES TABLE -------
=========================================================*/

 CREATE OR REPLACE STAGE EMPLOYEES_STG
    URL = 's3://hr-project-data/employees/'
    STORAGE_INTEGRATION = HR_DATA_LOAD
    FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)

LIST @EMPLOYEES_STG  -- To check loaded file on external stage from s3 bucket


/*=======================================================
       ------ STAGE FOR DEPARTMENTS TABLE -------
=========================================================*/

CREATE OR REPLACE STAGE DEPARTMENTS_STG
    URL = 's3://hr-project-data/departments/'
    STORAGE_INTEGRATION = HR_DATA_LOAD
    FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)

LIST @DEPARTMENTS_STG    -- To check loaded file on external stage from s3 bucket

/*=======================================================
       ------ STAGE FOR ATTENDANCES TABLE -------
=========================================================*/

CREATE OR REPLACE STAGE ATTENDANCE_STG
    URL = 's3://hr-project-data/attendance/'
    STORAGE_INTEGRATION = HR_DATA_LOAD
    FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)

    LIST @ATTENDANCE_STG    -- To check loaded file on external stage from s3 bucket


/*=======================================================
       ------ PIPE FOR EMPLOYEES TABLE -------
=========================================================*/
CREATE OR REPLACE PIPE EMPLOYEES_PIPE
AUTO_INGEST = TRUE
AS
COPY INTO EMPLOYEES
FROM @EMPLOYEES_STG
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)

DESC PIPE EMPLOYEES_PIPE   -- to get notification channel

SELECT SYSTEM$PIPE_STATUS('EMPLOYEES_PIPE')

ALTER PIPE EMPLOYEES_PIPE REFRESH; -- IF FILE IS ALREADY LOADED ON S3 BEFORE PIPE CREATION

SELECT * FROM EMPLOYEES;


/* ================ TO CHECK WHERE IS ERROR ============================ */
SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'EMPLOYEES',
        START_TIME => DATEADD('hour', -24, CURRENT_TIMESTAMP())
    )
)
ORDER BY LAST_LOAD_TIME DESC;



/*=======================================================
       ------ PIPE FOR DEPARTMENTS TABLE -------
=========================================================*/
CREATE OR REPLACE PIPE DEPARTMENTS_PIPE
AUTO_INGEST = TRUE
AS
COPY INTO DEPARTMENTS
FROM @DEPARTMENTS_STG
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)

DESC PIPE DEPARTMENTS_PIPE; -- to get notification channel

LIST @DEPARTMENTS_STG;

SELECT SYSTEM$PIPE_STATUS('DEPARTMENTS_PIPE')

SELECT * FROM DEPARTMENTS;


/*=======================================================
       ------ PIPE FOR ATTENDANCES TABLE -------
=========================================================*/
CREATE OR REPLACE PIPE ATTENDANCE_PIPE
AUTO_INGEST = TRUE
AS
COPY INTO ATTENDANCES
FROM @ATTENDANCE_STG
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT)

--DESC PIPE ATTENDANCE_PIPE;  -- to get notification channel
  HR_DB.ANALYTICS.EMPLOYEES

LIST @ATTENDANCE_STG;

SELECT SYSTEM$PIPE_STATUS('ATTENDANCE_PIPE')

SELECT * FROM ATTENDANCES;

