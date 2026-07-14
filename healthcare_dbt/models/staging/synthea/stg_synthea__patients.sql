WITH SOURCE AS (
	SELECT * FROM {{ source('synthea', 'PATIENTS') }}

),

RENAMED AS (
	SELECT
	"Id" AS patient_id,
	CAST("BIRTHDATE" AS DATE) AS birth_date,
	CAST("DEATHDATE" AS DATE) AS death_date,
	ssn,
	drivers,
	passport,
	prefix,
	"FIRST" AS first_name,
	"MIDDLE" AS middle_name,
	"LAST" AS last_name,
	suffix,
	"MAIDEN" AS maiden_name,
	"MARITAL" AS marital_status,
	race,
	ethnicity,
	gender,
	"BIRTHPLACE" AS birth_place,
	address,
	city,
	state,
	county,
	"FIPS" AS fips_code,
	zip,
	CAST ("LAT" AS FLOAT) AS latitude,
	CAST ("LON" AS FLOAT) AS longitude,
	CAST ("HEALTHCARE_EXPENSES" AS DECIMAL(12, 2)) AS healthcare_expense,
	CAST ("HEALTHCARE_COVERAGE" AS DECIMAL(12, 2)) AS healthcare_coverage,
	CAST ("INCOME" as INT) AS income
	FROM SOURCE)

SELECT * FROM RENAMED
