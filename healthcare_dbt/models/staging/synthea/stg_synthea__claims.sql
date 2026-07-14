

with source as (

    select * from {{ source('synthea', 'CLAIMS') }}

),

renamed as (

    select
        "Id" AS claim_id,
        patientid AS patient_id,
        providerid AS provider_id,
        primarypatientinsuranceid AS primary_patient_insurance_id,
        secondarypatientinsuranceid AS secondary_patient_insurance_id,
        departmentid AS department_id,
        patientdepartmentid AS patient_department_id,
        diagnosis1,
        diagnosis2,
        diagnosis3,
        diagnosis4,
        diagnosis5,
        diagnosis6,
        diagnosis7,
        diagnosis8,
        referringproviderid AS referring_provider_id,
        appointmentid AS appointment_id,
        CAST ("CURRENTILLNESSDATE" AS TIMESTAMP_TZ) AS current_illness_timestamp,
        CAST ("SERVICEDATE" AS TIMESTAMP_TZ) AS service_timestamp,
        supervisingproviderid AS supervising_provider_id,
        status1,
        status2,
        statusp,
        CAST (outstanding1 AS DECIMAL(12, 2)) AS outstanding1,
        CAST (outstanding2 AS DECIMAL(12, 2))AS outstanding2,
        CAST (outstandingp AS DECIMAL(12, 2)) AS outstandingp,
        CAST ("LASTBILLEDDATE1" AS TIMESTAMP_TZ) AS last_billed_timestamp1,
        CAST ("LASTBILLEDDATE2" AS TIMESTAMP_TZ) AS last_billed_timestamp2,
        CAST ("LASTBILLEDDATEP" AS TIMESTAMP_TZ) AS last_billed_timestampp,
        healthcareclaimtypeid1 AS healthcare_claimtype_id1,
        healthcareclaimtypeid2 AS healthcare_claimtype_id2

    from source

)

select * from renamed

