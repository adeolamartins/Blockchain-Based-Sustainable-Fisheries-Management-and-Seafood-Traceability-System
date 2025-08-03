;; Seafood Origin Verification Contract
;; Tracks seafood from harvest to consumer to prevent mislabeling and fraud

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u300))
(define-constant ERR-PRODUCT-NOT-FOUND (err u301))
(define-constant ERR-INVALID-STATUS (err u302))
(define-constant ERR-ALREADY-PROCESSED (err u303))

;; Data Variables
(define-data-var next-product-id uint u1)
(define-data-var next-batch-id uint u1)

;; Data Maps
(define-map seafood-products
  { product-id: uint }
  {
    catch-id: uint,
    species: (string-ascii 30),
    harvest-date: uint,
    harvest-location-lat: int,
    harvest-location-lon: int,
    fisherman: principal,
    current-owner: principal,
    status: (string-ascii 20),
    created-at: uint
  }
)

(define-map processing-records
  { product-id: uint, batch-id: uint }
  {
    processor: principal,
    processing-type: (string-ascii 30),
    processing-date: uint,
    facility-location: (string-ascii 50),
    quality-grade: (string-ascii 10),
    expiry-date: uint
  }
)

(define-map supply-chain-events
  { product-id: uint, event-id: uint }
  {
    event-type: (string-ascii 20),
    participant: principal,
    timestamp: uint,
    location: (string-ascii 50),
    temperature: (optional int),
    notes: (string-ascii 100)
  }
)

(define-map authorized-participants
  { participant: principal }
  {
    participant-type: (string-ascii 20),
    license-number: (string-ascii 30),
    authorized-date: uint,
    is-active: bool
  }
)

;; Private Functions
(define-private (is-authorized-participant (participant principal))
  (match (map-get? authorized-participants { participant: participant })
    auth (get is-active auth)
    false
  )
)

;; Public Functions
(define-public (authorize-participant (participant principal) (participant-type (string-ascii 20)) (license-number (string-ascii 30)))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set authorized-participants
      { participant: participant }
      {
        participant-type: participant-type,
        license-number: license-number,
        authorized-date: block-height,
        is-active: true
      }
    )
    (ok true)
  )
)

(define-public (create-seafood-product (catch-id uint) (species (string-ascii 30)) (harvest-date uint) (harvest-lat int) (harvest-lon int) (fisherman principal))
  (let ((product-id (var-get next-product-id)))
    (asserts! (is-authorized-participant tx-sender) ERR-NOT-AUTHORIZED)
    (map-set seafood-products
      { product-id: product-id }
      {
        catch-id: catch-id,
        species: species,
        harvest-date: harvest-date,
        harvest-location-lat: harvest-lat,
        harvest-location-lon: harvest-lon,
        fisherman: fisherman,
        current-owner: fisherman,
        status: "harvested",
        created-at: block-height
      }
    )
    (var-set next-product-id (+ product-id u1))
    (ok product-id)
  )
)

(define-public (transfer-ownership (product-id uint) (new-owner principal))
  (let ((product (unwrap! (map-get? seafood-products { product-id: product-id }) ERR-PRODUCT-NOT-FOUND)))
    (asserts! (is-eq tx-sender (get current-owner product)) ERR-NOT-AUTHORIZED)
    (asserts! (is-authorized-participant new-owner) ERR-NOT-AUTHORIZED)
    (map-set seafood-products
      { product-id: product-id }
      (merge product { current-owner: new-owner })
    )
    (ok true)
  )
)

(define-public (process-seafood (product-id uint) (processing-type (string-ascii 30)) (facility-location (string-ascii 50)) (quality-grade (string-ascii 10)) (expiry-date uint))
  (let
    (
      (product (unwrap! (map-get? seafood-products { product-id: product-id }) ERR-PRODUCT-NOT-FOUND))
      (batch-id (var-get next-batch-id))
    )
    (asserts! (is-eq tx-sender (get current-owner product)) ERR-NOT-AUTHORIZED)
    (asserts! (is-authorized-participant tx-sender) ERR-NOT-AUTHORIZED)
    (asserts! (not (is-eq (get status product) "processed")) ERR-ALREADY-PROCESSED)

    (map-set processing-records
      { product-id: product-id, batch-id: batch-id }
      {
        processor: tx-sender,
        processing-type: processing-type,
        processing-date: block-height,
        facility-location: facility-location,
        quality-grade: quality-grade,
        expiry-date: expiry-date
      }
    )

    (map-set seafood-products
      { product-id: product-id }
      (merge product { status: "processed" })
    )

    (var-set next-batch-id (+ batch-id u1))
    (ok batch-id)
  )
)

(define-public (add-supply-chain-event (product-id uint) (event-type (string-ascii 20)) (location (string-ascii 50)) (temperature (optional int)) (notes (string-ascii 100)))
  (let
    (
      (product (unwrap! (map-get? seafood-products { product-id: product-id }) ERR-PRODUCT-NOT-FOUND))
      (event-id block-height)
    )
    (asserts! (is-authorized-participant tx-sender) ERR-NOT-AUTHORIZED)
    (map-set supply-chain-events
      { product-id: product-id, event-id: event-id }
      {
        event-type: event-type,
        participant: tx-sender,
        timestamp: block-height,
        location: location,
        temperature: temperature,
        notes: notes
      }
    )
    (ok event-id)
  )
)

;; Read-only Functions
(define-read-only (get-product-info (product-id uint))
  (map-get? seafood-products { product-id: product-id })
)

(define-read-only (get-processing-record (product-id uint) (batch-id uint))
  (map-get? processing-records { product-id: product-id, batch-id: batch-id })
)

(define-read-only (get-supply-chain-event (product-id uint) (event-id uint))
  (map-get? supply-chain-events { product-id: product-id, event-id: event-id })
)

(define-read-only (verify-product-authenticity (product-id uint))
  (match (map-get? seafood-products { product-id: product-id })
    product (some {
      species: (get species product),
      harvest-date: (get harvest-date product),
      fisherman: (get fisherman product),
      current-status: (get status product)
    })
    none
  )
)
