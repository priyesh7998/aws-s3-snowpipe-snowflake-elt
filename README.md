# 🚀 AWS S3 → Snowflake Snowpipe ELT Pipeline

An end-to-end **ELT data pipeline** that automatically ingests CSV files from **Amazon S3 into Snowflake** using **Snowflake Snowpipe**.

This project demonstrates how to build a cloud-based data ingestion pipeline for **Employees, Department, and Attendance** data using AWS S3, IAM, SQS notifications, Snowflake Storage Integration, External Stages, File Formats, and Snowpipe.

---

## 📌 Project Overview

The pipeline follows this architecture:

```text
                    AWS CLOUD
┌─────────────────────────────────────────────┐
│                                             │
│                 Amazon S3                   │
│                                             │
│  ┌────────────┐  ┌────────────┐  ┌────────┐ │
│  │ Employees  │  │ Department │  │Attend. │ │
│  │   CSVs     │  │   CSVs     │  │  CSVs  │ │
│  └─────┬──────┘  └─────┬──────┘  └───┬────┘ │
│        │                │              │     │
└────────┼────────────────┼──────────────┼─────┘
         │                │              │
         └────────────────┼──────────────┘
                          │
                    S3 Event Notification
                          │
                          ▼
                    AWS SQS Queue
                          │
                          ▼
              ┌──────────────────────┐
              │ Snowflake Snowpipe   │
              │    AUTO_INGEST       │
              └──────────┬───────────┘
                         │
                         ▼
                Snowflake External
                      Stages
                         │
                         ▼
                 Raw Snowflake Tables
                         │
                         ▼
              Employees / Department /
                   Attendance
```

---

# 🛠️ Technologies Used

* **Amazon S3** – Cloud object storage for CSV files
* **AWS IAM** – Permissions and trust relationship
* **AWS SQS** – Event notification queue used by Snowpipe
* **Snowflake** – Cloud data warehouse
* **Snowflake Storage Integration** – Secure S3 authentication
* **Snowflake External Stage** – Connects Snowflake to S3
* **Snowflake File Format** – Defines CSV structure
* **Snowpipe** – Continuous/automatic data ingestion
* **SQL** – Data loading and verification

---

# 📂 Repository Structure

```text
aws-s3-snowpipe-snowflake-elt/
│
├── README.md
│
├── script/
│   ├── employees.sql
│   ├── department.sql
│   └── attendance.sql
│
└── data/
    ├── employees/
    │   └── employees.csv
    │
    ├── department/
    │   └── department.csv
    │
    └── attendance/
        └── attendance.csv
```

> The `script` folder contains the Snowflake SQL scripts, while the `data` folder contains the source CSV files.

---

# 📦 S3 Bucket Structure

Create one S3 bucket for the project.

Example:

```text
hr-project-data/
│
├── employees/
│   └── employees.csv
│
├── department/
│   └── department.csv
│
└── attendance/
    └── attendance.csv
```

You can also upload multiple files into each folder:

```text
hr-project-data/
│
├── employees/
│   ├── employees_01.csv
│   ├── employees_02.csv
│   └── employees_03.csv
│
├── department/
│   ├── department_01.csv
│   └── department_02.csv
│
└── attendance/
    ├── attendance_01.csv
    └── attendance_02.csv
```

This structure allows each Snowflake stage and Snowpipe to monitor its corresponding folder.

---

# 1️⃣ Create an S3 Bucket

Create an S3 bucket from the AWS Console.

Example bucket:

```text
hr-project-data
```

Inside the bucket, create:

```text
employees/
department/
attendance/
```

Upload the corresponding CSV files into each folder.

---

# 2️⃣ Create AWS IAM Role

Snowflake needs permission to access the S3 bucket.

Go to:

```text
AWS Console
    ↓
IAM
    ↓
Roles
    ↓
Create Role
```

Create an IAM role for Snowflake.

Example:

```text
 hr-project-role
```

### Step-by-Step
```text
┌──────────────────────────────────────────────────────────────┐
│                     AWS IAM ROLE SETUP                       │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  1. Select Trusted Entity                                    │
│                                                              │
│     Choose: AWS Account                                      │
│                                                              │
│  2. Options                                                  │
│                                                              │
│     Select: Require external ID                              │
│     (Best practice when a third party will assume this role) │
│                                                              │
│     External ID: 0000                                        │
│                                                              │
│  3. Add Permissions                                          │
│                                                              │
│     Choose: AmazonS3FullAccess                               │
│                                                              │
│  4. Name, Review, and Create                                 │
│                                                              │
│     Role Name: hr-project-role                               │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```
> **Note:** `0000` is only an example value for initial setup. For a real Snowflake Storage Integration, use the `STORAGE_AWS_EXTERNAL_ID` generated by Snowflake in the IAM Trust Policy.

For a learning project, the role may have permissions such as:


> For production environments, follow the principle of least privilege and restrict permissions to only the required bucket and prefixes.

---

# 3️⃣ Get the IAM Role ARN

After creating the IAM role:

```text
AWS Console
    ↓
IAM
    ↓
Roles
    ↓
 hr-project-role
```

Copy the **ARN**.

It will look similar to:

```text
arn:aws:iam::<AWS_ACCOUNT_ID>:role/SnowflakeS3Role
```

This ARN is required when creating the Snowflake Storage Integration.

---

# 4️⃣ Create Snowflake Storage Integration

Create a Storage Integration in Snowflake.

```sql
CREATE OR REPLACE STORAGE INTEGRATION HR_DATA_INTEGRATION
    TYPE = EXTERNAL_STAGE
    STORAGE_PROVIDER = S3
    ENABLED = TRUE
    STORAGE_AWS_ROLE_ARN = 'arn:aws:iam::<AWS_ACCOUNT_ID>:role/SnowflakeS3Role'
    STORAGE_ALLOWED_LOCATIONS = (
        's3://hr-project-data/'
    );
```

### Important

The `STORAGE_AWS_ROLE_ARN` is the IAM Role ARN obtained from AWS.

The `STORAGE_ALLOWED_LOCATIONS` contains the S3 bucket location.

Example:

```text
s3://hr-project-data/
```

---

# 5️⃣ Describe the Storage Integration

Run:

```sql
DESC INTEGRATION HR_DATA_INTEGRATION;
```

Snowflake will return important values such as:

```text
STORAGE_AWS_IAM_USER_ARN
STORAGE_AWS_EXTERNAL_ID
```

You need these values for the AWS IAM Trust Policy.

---

# 6️⃣ Update AWS IAM Trust Policy

Go back to:

```text
AWS Console
    ↓
IAM
    ↓
Roles
    ↓
 hr-project-role
    ↓
Trust relationships
    ↓
Edit trust policy
```

The trust relationship allows Snowflake to assume the AWS IAM role.

Example structure:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "<STORAGE_AWS_IAM_USER_ARN>"
      },
      "Action": "sts:AssumeRole",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "<STORAGE_AWS_EXTERNAL_ID>"
        }
      }
    }
  ]
}
```

Replace:

```text
<STORAGE_AWS_IAM_USER_ARN>
```

with the value returned by:

```sql
DESC INTEGRATION HR_DATA_INTEGRATION;
```

And replace:

```text
<STORAGE_AWS_EXTERNAL_ID>
```

with the Snowflake-generated external ID.

### Why are these values required?

The **IAM User ARN** identifies Snowflake as the trusted entity.

The **External ID** provides an additional security mechanism when Snowflake assumes the AWS role.

---

# 7️⃣ Verify the Storage Integration

Run:

```sql
DESC INTEGRATION HR_DATA_INTEGRATION;
```

Verify that:

```text
STORAGE_AWS_IAM_USER_ARN
STORAGE_AWS_EXTERNAL_ID
STORAGE_ALLOWED_LOCATIONS
```

are configured correctly.

---

# 8️⃣ Create Database and Schema

Example:

```sql
CREATE DATABASE IF NOT EXISTS HR_DATA;

CREATE SCHEMA IF NOT EXISTS HR_DATA.RAW;

USE DATABASE HR_DATA;
USE SCHEMA RAW;
```

---

# 9️⃣ Create File Format

Since the source files are CSV files, create a CSV file format.

```sql
CREATE OR REPLACE FILE FORMAT CSV_FORMAT
    TYPE = CSV
    SKIP_HEADER = 1
    FIELD_DELIMITER = ','
    RECORD_DELIMITER = '\n'
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
```

This tells Snowflake how to interpret the CSV files.

---

# 🔟 Create Snowflake Tables

Create separate tables for:

* Employees
* Department
* Attendance

Example:

```sql
CREATE OR REPLACE TABLE EMPLOYEES (
    employee_id STRING,
    first_name STRING,
    last_name STRING,
    email STRING,
    phone STRING,
    department_id STRING,
    job_title STRING,
    hire_date DATE,
    salary NUMBER(12,2),
    manager_id STRING,
    gender STRING,
    date_of_birth DATE,
    status STRING
);
```

Create your `DEPARTMENT` and `ATTENDANCE` tables according to their CSV structures.

> Make sure the number and order of columns in the table match the source CSV structure when using positional loading such as `$1, $2, $3...`.

---

# 1️⃣1️⃣ Create External Stages

Create a separate stage for each S3 folder.

## Employees Stage

```sql
CREATE OR REPLACE STAGE EMPLOYEES_STG
    URL = 's3://hr-project-data/employees/'
    STORAGE_INTEGRATION = HR_DATA_INTEGRATION
    FILE_FORMAT = CSV_FORMAT;
```

## Department Stage

```sql
CREATE OR REPLACE STAGE DEPARTMENT_STG
    URL = 's3://hr-project-data/department/'
    STORAGE_INTEGRATION = HR_DATA_INTEGRATION
    FILE_FORMAT = CSV_FORMAT;
```

## Attendance Stage

```sql
CREATE OR REPLACE STAGE ATTENDANCE_STG
    URL = 's3://hr-project-data/attendance/'
    STORAGE_INTEGRATION = HR_DATA_INTEGRATION
    FILE_FORMAT = CSV_FORMAT;
```

### Important: Stage URL

When creating a stage, don't use only:

```text
s3://hr-project-data/
```

for every stage if you want each stage to point to a specific folder.

Instead use the folder path:

```text
s3://hr-project-data/employees/
s3://hr-project-data/department/
s3://hr-project-data/attendance/
```

This keeps each stage focused on its own data.

---

# 1️⃣2️⃣ Test the Stages

Check the Employees stage:

```sql
LIST @EMPLOYEES_STG;
```

Department:

```sql
LIST @DEPARTMENT_STG;
```

Attendance:

```sql
LIST @ATTENDANCE_STG;
```

If the integration and permissions are correct, Snowflake should be able to see the files stored in S3.

---

# 1️⃣3️⃣ Create Snowpipes

Now create a separate Snowpipe for each table.

## Employees Snowpipe

```sql
CREATE OR REPLACE PIPE EMPLOYEES_PIPE
    AUTO_INGEST = TRUE
AS
COPY INTO EMPLOYEES
FROM @EMPLOYEES_STG
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT);
```

## Department Snowpipe

```sql
CREATE OR REPLACE PIPE DEPARTMENT_PIPE
    AUTO_INGEST = TRUE
AS
COPY INTO DEPARTMENT
FROM @DEPARTMENT_STG
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT);
```

## Attendance Snowpipe

```sql
CREATE OR REPLACE PIPE ATTENDANCE_PIPE
    AUTO_INGEST = TRUE
AS
COPY INTO ATTENDANCE
FROM @ATTENDANCE_STG
FILE_FORMAT = (FORMAT_NAME = CSV_FORMAT);
```

The important setting is:

```sql
AUTO_INGEST = TRUE
```

This enables Snowpipe's automatic ingestion mechanism.

---

# 1️⃣4️⃣ Get Snowpipe Notification Channel

After creating the pipe, run:

```sql
DESC PIPE EMPLOYEES_PIPE;
```

Look for:

```text
notificationChannel
```

or the notification channel value associated with the pipe.

You will get an AWS SQS-style value similar to:

```text
arn:aws:sqs:ap-south-1:<AWS_ACCOUNT_ID>:sf-snowpipe-xxxxxxxx
```

Copy this value.

Do the same for:

```sql
DESC PIPE DEPARTMENT_PIPE;

DESC PIPE ATTENDANCE_PIPE;
```

Each pipe can have its own notification channel.

---

# 1️⃣5️⃣ Configure S3 Event Notification

Now go back to AWS:

```text
AWS Console
    ↓
S3
    ↓
hr-project-data
    ↓
Properties(scroll down & look for)
    ↓
Event notifications
```

Create/configure an event notification.
```text
Event name
   ↓
prefix(same a folder name)
   ↓
```

For the Employees folder, configure the appropriate prefix:

```text
employees/
```

Choose the event type for new objects, such as:
```text
checkbox( All object create events) 
```

Configure the destination as (scroll down):

```text
SQS Queue
   ↓
Enter SQS queue ARN

```

Paste the Snowpipe notification channel/SQS destination obtained from:

```sql
DESC PIPE EMPLOYEES_PIPE;
```

---

# 1️⃣6️⃣ Configure Notifications for Other Folders

Repeat the same configuration for:

### Employees
### Department
### Attendance
The purpose is:

```text
S3 employees/
        ↓
Employees SQS Notification
        ↓
EMPLOYEES_PIPE
        ↓
EMPLOYEES TABLE
```

and:

```text
S3 department/
        ↓
Department SQS Notification
        ↓
DEPARTMENT_PIPE
        ↓
DEPARTMENT TABLE
```

and:

```text
S3 attendance/
        ↓
Attendance SQS Notification
        ↓
ATTENDANCE_PIPE
        ↓
ATTENDANCE TABLE
```

---

# 1️⃣7️⃣ Check Snowpipe Status

Check Employees:

```sql
SELECT SYSTEM$PIPE_STATUS('EMPLOYEES_PIPE');
```

Department:

```sql
SELECT SYSTEM$PIPE_STATUS('DEPARTMENT_PIPE');
```

Attendance:

```sql
SELECT SYSTEM$PIPE_STATUS('ATTENDANCE_PIPE');
```

A healthy pipe should generally show:

```text
executionState: RUNNING
```

Other useful fields include:

```text
pendingFileCount
lastIngestedFilePath
lastIngestedTimestamp
notificationChannelName
lastReceivedMessageTimestamp
lastForwardedMessageTimestamp
```

---

# 1️⃣8️⃣ Test Automatic Ingestion

Upload a **new CSV file** into the appropriate S3 folder.

For example:

```text
hr-project-data/
└── employees/
    ├── employees.csv
    └── employees_02.csv
```

Snowpipe should automatically detect the new file and load it into:

```text
EMPLOYEES
```

Verify:

```sql
SELECT *
FROM EMPLOYEES;
```

And:

```sql
SELECT COUNT(*)
FROM EMPLOYEES;
```

---

# 1️⃣9️⃣ Check COPY HISTORY

To check the files loaded into Employees:

```sql
SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'EMPLOYEES',
        START_TIME => DATEADD('day', -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY LAST_LOAD_TIME DESC;
```

For Department:

```sql
SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'DEPARTMENT',
        START_TIME => DATEADD('day', -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY LAST_LOAD_TIME DESC;
```

For Attendance:

```sql
SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'ATTENDANCE',
        START_TIME => DATEADD('day', -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY LAST_LOAD_TIME DESC;
```

This helps verify which files were successfully loaded and when.

---

# 🔍 2️⃣0️⃣ Verify Data in Tables

Employees:

```sql
SELECT *
FROM EMPLOYEES;
```

Department:

```sql
SELECT *
FROM DEPARTMENT;
```

Attendance:

```sql
SELECT *
FROM ATTENDANCE;
```

You can also verify row counts:

```sql
SELECT COUNT(*) FROM EMPLOYEES;

SELECT COUNT(*) FROM DEPARTMENT;

SELECT COUNT(*) FROM ATTENDANCE;
```

---

# 🔄 Complete ELT Workflow

The complete workflow is:

```text
                ┌──────────────────┐
                │   CSV Source     │
                └────────┬─────────┘
                         │
                         ▼
                ┌──────────────────┐
                │     AWS S3       │
                │                  │
                │ employees/       │
                │ department/      │
                │ attendance/      │
                └────────┬─────────┘
                         │
                         │ Object Created Event
                         ▼
                ┌──────────────────┐
                │    AWS SQS       │
                └────────┬─────────┘
                         │
                         ▼
                ┌──────────────────┐
                │ Snowflake        │
                │ Snowpipe         │
                │ AUTO_INGEST=TRUE │
                └────────┬─────────┘
                         │
                         ▼
                ┌──────────────────┐
                │ External Stage   │
                └────────┬─────────┘
                         │
                         ▼
                ┌──────────────────┐
                │ Snowflake RAW    │
                │ Tables           │
                ├──────────────────┤
                │ EMPLOYEES        │
                │ DEPARTMENT       │
                │ ATTENDANCE       │
                └──────────────────┘
```

---

# 🧠 Why This Is ELT

This project follows the **ELT (Extract, Load, Transform)** approach.

### Extract

Data originates from CSV files stored in Amazon S3.

```text
CSV → AWS S3
```

### Load

Snowpipe automatically loads the files into Snowflake.

```text
S3 → Snowpipe → Snowflake
```

### Transform

Transformations can then be performed inside Snowflake using SQL, Views, Streams, Tasks, dbt, or other transformation tools.

```text
Raw Data
   ↓
Transformation
   ↓
Analytics Data
```

Therefore:

> **AWS S3 + Snowpipe + Snowflake = Cloud ELT Pipeline**

---

# ⚠️ Troubleshooting

## 1. File appears in Stage but not in Table

Check:

```sql
LIST @EMPLOYEES_STG;
```

Then:

```sql
SELECT SYSTEM$PIPE_STATUS('EMPLOYEES_PIPE');
```

Check:

```text
executionState
pendingFileCount
lastIngestedFilePath
lastReceivedMessageTimestamp
lastForwardedMessageTimestamp
```

Also verify the S3 event notification and SQS destination.

---

## 2. Manually Refresh Snowpipe

If a file is already present in the stage and needs to be queued for Snowpipe processing:

```sql
ALTER PIPE EMPLOYEES_PIPE REFRESH;
```

Then check:

```sql
SELECT COUNT(*)
FROM EMPLOYEES;
```

And:

```sql
SELECT *
FROM TABLE(
    INFORMATION_SCHEMA.COPY_HISTORY(
        TABLE_NAME => 'EMPLOYEES',
        START_TIME => DATEADD('day', -1, CURRENT_TIMESTAMP())
    )
)
ORDER BY LAST_LOAD_TIME DESC;
```

> `ALTER PIPE ... REFRESH` is useful for troubleshooting and for processing files already present in a stage. A correctly configured `AUTO_INGEST` pipeline should normally process newly arriving files automatically.

---

## 3. Check the Pipe Definition

```sql
SELECT GET_DDL(
    'PIPE',
    'EMPLOYEES_PIPE'
);
```

Verify:

```text
AUTO_INGEST = TRUE
```

and:

```text
FROM @EMPLOYEES_STG
```

---

## 4. Check the Stage

```sql
DESC STAGE EMPLOYEES_STG;
```

Verify that the URL points to the correct S3 folder:

```text
s3://hr-project-data/employees/
```

---

## 5. Check the Storage Integration

```sql
DESC INTEGRATION HR_DATA_INTEGRATION;
```

Verify:

```text
STORAGE_AWS_IAM_USER_ARN
STORAGE_AWS_EXTERNAL_ID
STORAGE_ALLOWED_LOCATIONS
```

Also make sure the AWS IAM Trust Policy contains the correct values.

---

# 🔐 Security Notes

**Never commit AWS credentials or sensitive Snowflake credentials to GitHub.**

Do not upload:

```text
AWS Access Key
AWS Secret Access Key
AWS Account credentials
Private keys
Passwords
Snowflake passwords
Connection strings containing secrets
```

The following values should also be treated carefully:

```text
AWS Account ID
IAM Role ARN
SQS Queue ARN
Snowflake Account Identifier
```

For a public repository, use placeholders:

```text
<AWS_ACCOUNT_ID>
<SNOWFLAKE_ACCOUNT>
<S3_BUCKET_NAME>
<IAM_ROLE_NAME>
```

---

# 📋 Project Checklist

Use this checklist when setting up the project from scratch:

* [ ] Create AWS S3 bucket
* [ ] Create `employees/` folder
* [ ] Create `department/` folder
* [ ] Create `attendance/` folder
* [ ] Upload CSV files
* [ ] Create AWS IAM Role
* [ ] Add S3 permissions
* [ ] Copy IAM Role ARN
* [ ] Create Snowflake Storage Integration
* [ ] Run `DESC INTEGRATION`
* [ ] Copy Snowflake IAM User ARN
* [ ] Copy Snowflake External ID
* [ ] Update IAM Trust Policy
* [ ] Create Snowflake database
* [ ] Create RAW schema
* [ ] Create CSV File Format
* [ ] Create Employees table
* [ ] Create Department table
* [ ] Create Attendance table
* [ ] Create Employees stage
* [ ] Create Department stage
* [ ] Create Attendance stage
* [ ] Test stages using `LIST`
* [ ] Create Employees Snowpipe
* [ ] Create Department Snowpipe
* [ ] Create Attendance Snowpipe
* [ ] Run `DESC PIPE`
* [ ] Copy notification channel
* [ ] Configure S3 Event Notifications
* [ ] Configure SQS destination
* [ ] Upload a new CSV file
* [ ] Verify Snowpipe status
* [ ] Verify table row count
* [ ] Verify `COPY_HISTORY`

---

# 🎯 Key Learning Outcomes

Through this project, you can learn and demonstrate:

* AWS S3 data organization
* AWS IAM Roles
* IAM Trust Policies
* Snowflake Storage Integrations
* External Stages
* Snowflake File Formats
* Snowpipe
* Continuous Data Loading
* AWS S3 Event Notifications
* AWS SQS integration
* Automatic data ingestion
* Snowflake `COPY_HISTORY`
* Snowpipe monitoring
* Cloud-based ELT architecture

---

# 🚀 Future Improvements

This project can be extended by adding:

* **Snowflake Streams** for CDC
* **Snowflake Tasks** for scheduled transformations
* **dbt** for transformation and data testing
* **Apache Airflow** for orchestration
* **Snowflake Dynamic Tables**
* Data quality checks
* Error handling and rejected-record tables
* Analytics schema
* Fact and dimension tables
* Power BI dashboard
* Automated deployment using CI/CD

---

# 👨‍💻 Project

**Project:** AWS S3 → Snowflake Snowpipe ELT Pipeline

**Data Domains:**

* Employees
* Department
* Attendance

**Architecture:**

```text
AWS S3
   ↓
S3 Event Notification
   ↓
AWS SQS
   ↓
Snowflake Snowpipe
   ↓
Snowflake External Stage
   ↓
RAW Tables
   ↓
Analytics / Transformation Layer
```

---

## ⭐ If You Found This Project Useful

If this project helps you understand AWS S3, Snowflake Snowpipe, and ELT pipelines, consider giving the repository a ⭐.

Feel free to fork the project and experiment with your own S3 → Snowflake data pipeline.
