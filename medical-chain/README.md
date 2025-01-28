# Medical Records Smart Contract

A secure and decentralized smart contract system for managing medical records, prescriptions, and healthcare provider authorizations on the Stacks blockchain.

## Overview

This smart contract implements a comprehensive medical records management system that enables:
- Secure storage of patient medical records and DNA profiles
- Doctor registration and verification
- Prescription management
- Patient-doctor authorization controls

## Features

### Patient Management
- Patient registration with medical history and DNA profile
- Secure storage of medical records
- Management of authorized healthcare providers
- View and track prescriptions

### Doctor Management
- Doctor registration with specialty and license verification
- Active status tracking
- Prescription writing capabilities
- Access control to patient records

### Prescription System
- Secure prescription creation
- Validity period management
- Prescription cancellation
- Active prescription tracking

## Data Structures

### Medical Records
```clarity
{
    health-history: string-ascii-256,
    dna-profile: string-ascii-256,
    medication-list: list[10],
    authorized-doctors: list[5]
}
```

### Doctor Registry
```clarity
{
    specialty-field: string-ascii-64,
    license-id: string-ascii-32,
    is-active: bool
}
```

### Prescriptions
```clarity
{
    patient-id: principal,
    doctor-id: principal,
    drug-name: string-ascii-64,
    dosage: string-ascii-32,
    start-date: uint,
    end-date: uint,
    is-valid: bool
}
```

## Public Functions

### Patient Functions
- `add-patient`: Register a new patient with medical history and DNA profile
- `authorize-doctor`: Add a doctor to patient's authorized providers list
- `get-medical-record`: Retrieve patient's medical record

### Doctor Functions
- `add-doctor`: Register a new healthcare provider
- `get-doctor-info`: Retrieve doctor's information
- `check-doctor-status`: Check if a doctor is currently active

### Prescription Functions
- `write-prescription`: Create a new prescription for a patient
- `cancel-prescription`: Deactivate an existing prescription
- `get-rx-details`: Get details of a specific prescription
- `get-active-prescriptions`: List all active prescriptions for a patient

## Error Codes

| Code | Description |
|------|-------------|
| ERR-ACCESS-DENIED (u1) | Unauthorized access attempt |
| ERR-PATIENT-EXISTS (u2) | Patient record already exists |
| ERR-NO-PATIENT-FOUND (u3) | Patient record not found |
| ERR-INVALID-RX-DATA (u4) | Invalid prescription data |
| ERR-PROVIDER-EXISTS (u5) | Provider already registered |
| ERR-NO-PROVIDER-FOUND (u6) | Provider not found |
| ERR-RX-LIST-FULL (u7) | Prescription list capacity reached |
| ERR-BAD-INPUT-FORMAT (u8) | Invalid input format |
| ERR-ALREADY-AUTHORIZED (u9) | Provider already authorized |
| ERR-AUTH-LIST-FULL (u10) | Authorization list capacity reached |

## Security Features

1. Access Control
   - Only authorized doctors can access patient records
   - Patients control their doctor authorization list
   - Maximum of 5 authorized doctors per patient

2. Data Validation
   - Input string length validation
   - Date range validation for prescriptions
   - Active status verification for doctors

3. Capacity Limits
   - Maximum 10 active prescriptions per patient
   - Maximum 5 authorized doctors per patient
   - Maximum 100 prescriptions in global registry

## Usage Examples

### Registering a Patient
```clarity
(contract-call? .medical-records add-patient 
    "Patient history details..." 
    "DNA profile data..."
)
```

### Authorizing a Doctor
```clarity
(contract-call? .medical-records authorize-doctor 
    'DOCTOR_PRINCIPAL
)
```

### Writing a Prescription
```clarity
(contract-call? .medical-records write-prescription
    'PATIENT_PRINCIPAL
    "Medication Name"
    "1 tablet daily"
    u1643673600  ;; start date
    u1646092800  ;; end date
)
```

## Limitations

1. Storage Constraints
   - Fixed-length string fields
   - Limited number of prescriptions
   - Maximum number of authorized doctors

2. Data Privacy
   - All data is stored on-chain
   - Sensitive data should be properly encrypted before storage

3. System Constraints
   - No automatic prescription expiration
   - No built-in payment system
   - No support for multiple signatures

## Best Practices

1. Regular status updates for healthcare providers
2. Periodic review of authorized doctor list
3. Careful management of prescription validity periods
4. Proper encryption of sensitive medical data before storage
5. Regular verification of doctor credentials