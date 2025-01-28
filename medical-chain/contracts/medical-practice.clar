;; Personalized Medicine Contract

;; Error codes
(define-constant ERR-ACCESS-DENIED (err u1))
(define-constant ERR-PATIENT-EXISTS (err u2))
(define-constant ERR-NO-PATIENT-FOUND (err u3))
(define-constant ERR-INVALID-RX-DATA (err u4))
(define-constant ERR-PROVIDER-EXISTS (err u5))
(define-constant ERR-NO-PROVIDER-FOUND (err u6))
(define-constant ERR-RX-LIST-FULL (err u7))
(define-constant ERR-BAD-INPUT-FORMAT (err u8))
(define-constant ERR-ALREADY-AUTHORIZED (err u9))
(define-constant ERR-AUTH-LIST-FULL (err u10))

;; Data structures
(define-map medical-records 
    { patient-id: principal }
    {
        health-history: (string-ascii 256),
        dna-profile: (string-ascii 256),
        medication-list: (list 10 uint),
        authorized-doctors: (list 5 principal)
    }
)

(define-map doctor-registry
    { doctor-id: principal }
    {
        specialty-field: (string-ascii 64),
        license-id: (string-ascii 32),
        is-active: bool
    }
)

(define-map prescriptions
    { rx-id: uint }
    {
        patient-id: principal,
        doctor-id: principal,
        drug-name: (string-ascii 64),
        dosage: (string-ascii 32),
        start-date: uint,
        end-date: uint,
        is-valid: bool
    }
)

;; Global variables
(define-data-var rx-counter uint u0)
(define-data-var rx-id-list (list 100 uint) (list))

;; Helper functions for input validation
(define-private (is-valid-long-text (text (string-ascii 256)))
    (and 
        (is-eq (len text) (len (concat text "")))
        (>= (len text) u1)
        (<= (len text) u256)
    )
)

(define-private (is-valid-medium-text (text (string-ascii 64)))
    (and 
        (is-eq (len text) (len (concat text "")))
        (>= (len text) u1)
        (<= (len text) u64)
    )
)

(define-private (is-valid-short-text (text (string-ascii 32)))
    (and 
        (is-eq (len text) (len (concat text "")))
        (>= (len text) u1)
        (<= (len text) u32)
    )
)

;; Authorization verification
(define-private (is-doctor-authorized (patient-id principal) (doctor-id principal))
    (let ((record (get-medical-record patient-id)))
        (match record
            data (is-some (index-of (get authorized-doctors data) doctor-id))
            false
        )
    )
)

;; Patient management functions
(define-public (add-patient (health-history (string-ascii 256)) (dna-profile (string-ascii 256)))
    (let ((patient-id tx-sender))
        (asserts! (is-valid-long-text health-history) ERR-BAD-INPUT-FORMAT)
        (asserts! (is-valid-long-text dna-profile) ERR-BAD-INPUT-FORMAT)
        (asserts! (is-none (get-medical-record patient-id)) ERR-PATIENT-EXISTS)
        (ok (map-set medical-records
            { patient-id: patient-id }
            {
                health-history: health-history,
                dna-profile: dna-profile,
                medication-list: (list),
                authorized-doctors: (list)
            }
        ))
    )
)

(define-read-only (get-medical-record (patient-id principal))
    (map-get? medical-records { patient-id: patient-id })
)

(define-public (authorize-doctor (doctor-id principal))
    (let (
        (patient-id tx-sender)
        (record (get-medical-record patient-id))
        )
        (asserts! (is-some record) ERR-NO-PATIENT-FOUND)
        (let ((current-data (unwrap-panic record)))
            (asserts! (< (len (get authorized-doctors current-data)) u5) ERR-AUTH-LIST-FULL)
            (asserts! (is-none (index-of (get authorized-doctors current-data) doctor-id)) ERR-ALREADY-AUTHORIZED)
            (ok (map-set medical-records
                { patient-id: patient-id }
                (merge current-data
                    { authorized-doctors: 
                        (unwrap! (as-max-len? 
                            (append (get authorized-doctors current-data) doctor-id)
                            u5
                        ) ERR-AUTH-LIST-FULL)
                    }
                )
            ))
        )
    )
)

;; Healthcare provider functions
(define-public (add-doctor (specialty-field (string-ascii 64)) (license-id (string-ascii 32)))
    (let ((doctor-id tx-sender))
        (asserts! (is-valid-medium-text specialty-field) ERR-BAD-INPUT-FORMAT)
        (asserts! (is-valid-short-text license-id) ERR-BAD-INPUT-FORMAT)
        (asserts! (is-none (get-doctor-info doctor-id)) ERR-PROVIDER-EXISTS)
        (ok (map-set doctor-registry
            { doctor-id: doctor-id }
            {
                specialty-field: specialty-field,
                license-id: license-id,
                is-active: true
            }
        ))
    )
)

(define-read-only (get-doctor-info (doctor-id principal))
    (map-get? doctor-registry { doctor-id: doctor-id })
)

;; Prescription management functions
(define-private (get-new-rx-id)
    (let ((current-count (var-get rx-counter)))
        (var-set rx-counter (+ current-count u1))
        current-count
    )
)

(define-public (write-prescription 
    (patient-id principal)
    (drug-name (string-ascii 64))
    (dosage (string-ascii 32))
    (start-date uint)
    (end-date uint)
)
    (let (
        (doctor-id tx-sender)
        (rx-id (get-new-rx-id))
    )
        (asserts! (is-doctor-authorized patient-id doctor-id) ERR-ACCESS-DENIED)
        (asserts! (< start-date end-date) ERR-INVALID-RX-DATA)
        (asserts! (is-valid-medium-text drug-name) ERR-BAD-INPUT-FORMAT)
        (asserts! (is-valid-short-text dosage) ERR-BAD-INPUT-FORMAT)

        ;; Add prescription
        (map-set prescriptions
            { rx-id: rx-id }
            {
                patient-id: patient-id,
                doctor-id: doctor-id,
                drug-name: drug-name,
                dosage: dosage,
                start-date: start-date,
                end-date: end-date,
                is-valid: true
            }
        )

        ;; Update rx list
        (match (as-max-len? (append (var-get rx-id-list) rx-id) u100)
            success (ok (var-set rx-id-list success))
            ERR-RX-LIST-FULL
        )
    )
)

(define-read-only (get-rx-details (rx-id uint))
    (map-get? prescriptions { rx-id: rx-id })
)

(define-public (cancel-prescription (rx-id uint))
    (let (
        (user-id tx-sender)
        (rx-data (get-rx-details rx-id))
    )
        (asserts! (is-some rx-data) ERR-INVALID-RX-DATA)
        (let ((current-rx (unwrap-panic rx-data)))
            (asserts! (or
                (is-eq user-id (get doctor-id current-rx))
                (is-eq user-id (get patient-id current-rx))
            ) ERR-ACCESS-DENIED)
            (ok (map-set prescriptions
                { rx-id: rx-id }
                (merge current-rx { is-valid: false })
            ))
        )
    )
)

(define-read-only (get-active-prescriptions (patient-id principal))
    (ok (fold filter-valid-rx-fold (var-get rx-id-list) (list)))
)

(define-private (filter-valid-rx-fold 
    (rx-id uint) 
    (valid-rx-list (list 100 uint))
)
    (let ((patient-id tx-sender))
        (if (is-rx-valid patient-id rx-id)
            (unwrap! (as-max-len? (append valid-rx-list rx-id) u100) valid-rx-list)
            valid-rx-list
        )
    )
)

(define-private (is-rx-valid (patient-id principal) (rx-id uint))
    (check-rx-validity rx-id patient-id)
)

(define-private (check-rx-validity (rx-id uint) (patient-id principal))
    (match (get-rx-details rx-id)
        rx-data 
            (and 
                (is-eq (get patient-id rx-data) patient-id)
                (get is-valid rx-data)
            )
        false
    )
)

(define-read-only (check-doctor-status (doctor-id principal))
    (match (get-doctor-info doctor-id)
        doctor-data (get is-active doctor-data)
        false
    )
)