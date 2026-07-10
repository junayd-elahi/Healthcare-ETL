WITH SOURCE AS (
	SELECT * FROM {{ source('synthea', 'PATIENTS') }}

),

RENAMED AS (
	SELECT
	CAST ("Id" AS TEXT) AS patient_id,
	CAST("BIRTHDATE" AS DATE) AS birth_date,
	CAST("DEATHDATE" AS DATE) AS death_date,
	CAST ("SSN" AS TEXT) AS ssn,
	CAST ("DRIVERS" AS TEXT) AS drivers,
	CAST ("PASSPORT" AS TEXT) AS passport,
	CAST ("PREFIX" AS TEXT) AS prefix,
	CAST ("FIRST" AS TEXT) AS first_name,
	CAST ("MIDDLE" AS TEXT) AS middle_name,
	CAST ("LAST" AS TEXT) AS last_name,
	CAST ("SUFFIX" AS TEXT) AS suffix,
	CAST ("MAIDEN" AS TEXT) AS maiden_name,
	CAST ("MARITAL" AS TEXT) AS marital_status,
	CAST ("RACE" AS TEXT) AS race,
	CAST ("ETHNICITY" AS TEXT) AS ethnicity,
	CAST ("GENDER" AS TEXT) AS gender,
	CAST ("BIRTHPLACE" AS TEXT) AS birth_place,
	CAST ("ADDRESS" AS TEXT) AS address,
	CAST ("CITY" AS TEXT) AS city,
	CAST ("STATE" as TEXT) AS state,
	CAST ("COUNTY" AS TEXT) AS county,
	CAST ("FIPS" AS TEXT) AS fips_code,
	CAST ("ZIP" AS TEXT) AS zip,
	CAST ("LAT" AS FLOAT) AS latitude,
	CAST ("LON" AS FLOAT) AS longitude,
	CAST ("HEALTHCARE_EXPENSES" AS FLOAT) AS healthcare_expense,
	CAST ("HEALTHCARE_COVERAGE" AS FLOAT) AS healthcare_coverage,
	CAST ("INCOME" as INT) AS income
	FROM SOURCE)

SELECT * FROM RENAMED
