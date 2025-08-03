;; Bycatch Reduction Monitoring Contract
;; Measures and minimizes unintended capture of non-target species

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u400))
(define-constant ERR-INVALID-DATA (err u401))
(define-constant ERR-RECORD-NOT-FOUND (err u402))
(define-constant ERR-INVALID-PERCENTAGE (err u403))

;; Data Variables
(define-data-var next-bycatch-id uint u1)
(define-data-var bycatch-reduction-target uint u10) ;; 10% target reduction

;; Data Maps
(define-map bycatch-records
  { bycatch-id: uint }
  {
    vessel-id: uint,
    fisherman: principal,
    target-species: (string-ascii 30),
    bycatch-species: (string-ascii 30),
    target-quantity: uint,
    bycatch-quantity: uint,
    fishing-method: (string-ascii 30),
    gear-type: (string-ascii 30),
    location-lat: int,
    location-lon: int,
    timestamp: uint,
    released-alive: bool
  }
)

(define-map fishing-method-stats
  { method: (string-ascii 30), species: (string-ascii 30) }
  {
    total-catches: uint,
    total-bycatch: uint,
    bycatch-rate: uint,
    last-updated: uint
  }
)

(define-map vessel-bycatch-performance
  { vessel-id: uint, period: uint }
  {
    total-target-catch: uint,
    total-bycatch: uint,
    bycatch-percentage: uint,
    improvement-score: uint,
    incentive-earned: uint
  }
)

(define-map protected-species
  { species: (string-ascii 30) }
  {
    protection-level: uint,
    penalty-per-unit: uint,
    release-required: bool
  }
)

;; Private Functions
(define-private (calculate-bycatch-rate (target-catch uint) (bycatch-catch uint))
  (if (> target-catch u0)
    (/ (* bycatch-catch u100) target-catch)
    u0
  )
)

(define-private (is-protected-species (species (string-ascii 30)))
  (is-some (map-get? protected-species { species: species }))
)

;; Public Functions
(define-public (add-protected-species (species (string-ascii 30)) (protection-level uint) (penalty-per-unit uint) (release-required bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= protection-level u5) ERR-INVALID-DATA)
    (map-set protected-species
      { species: species }
      {
        protection-level: protection-level,
        penalty-per-unit: penalty-per-unit,
        release-required: release-required
      }
    )
    (ok true)
  )
)

(define-public (record-bycatch (vessel-id uint) (target-species (string-ascii 30)) (bycatch-species (string-ascii 30)) (target-quantity uint) (bycatch-quantity uint) (fishing-method (string-ascii 30)) (gear-type (string-ascii 30)) (location-lat int) (location-lon int) (released-alive bool))
  (let ((bycatch-id (var-get next-bycatch-id)))
    (asserts! (> target-quantity u0) ERR-INVALID-DATA)
    (asserts! (> bycatch-quantity u0) ERR-INVALID-DATA)

    ;; Record bycatch incident
    (map-set bycatch-records
      { bycatch-id: bycatch-id }
      {
        vessel-id: vessel-id,
        fisherman: tx-sender,
        target-species: target-species,
        bycatch-species: bycatch-species,
        target-quantity: target-quantity,
        bycatch-quantity: bycatch-quantity,
        fishing-method: fishing-method,
        gear-type: gear-type,
        location-lat: location-lat,
        location-lon: location-lon,
        timestamp: block-height,
        released-alive: released-alive
      }
    )

    ;; Update fishing method statistics
    (let ((current-stats (default-to
      { total-catches: u0, total-bycatch: u0, bycatch-rate: u0, last-updated: u0 }
      (map-get? fishing-method-stats { method: fishing-method, species: bycatch-species })
    )))
      (let ((new-total-catches (+ (get total-catches current-stats) target-quantity))
            (new-total-bycatch (+ (get total-bycatch current-stats) bycatch-quantity)))
        (map-set fishing-method-stats
          { method: fishing-method, species: bycatch-species }
          {
            total-catches: new-total-catches,
            total-bycatch: new-total-bycatch,
            bycatch-rate: (calculate-bycatch-rate new-total-catches new-total-bycatch),
            last-updated: block-height
          }
        )
      )
    )

    (var-set next-bycatch-id (+ bycatch-id u1))
    (ok bycatch-id)
  )
)

(define-public (update-vessel-performance (vessel-id uint) (period uint))
  (let
    (
      (current-performance (default-to
        { total-target-catch: u0, total-bycatch: u0, bycatch-percentage: u0, improvement-score: u0, incentive-earned: u0 }
        (map-get? vessel-bycatch-performance { vessel-id: vessel-id, period: period })
      ))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    ;; This would typically aggregate data from bycatch-records for the vessel and period
    ;; For simplicity, we'll allow manual updates by the contract owner
    (ok true)
  )
)

(define-public (calculate-incentive (vessel-id uint) (period uint) (target-catch uint) (bycatch-catch uint))
  (let
    (
      (bycatch-percentage (calculate-bycatch-rate target-catch bycatch-catch))
      (target-percentage (var-get bycatch-reduction-target))
      (improvement-score (if (< bycatch-percentage target-percentage)
        (- target-percentage bycatch-percentage)
        u0))
      (incentive-amount (* improvement-score u100)) ;; 100 tokens per percentage point improvement
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (map-set vessel-bycatch-performance
      { vessel-id: vessel-id, period: period }
      {
        total-target-catch: target-catch,
        total-bycatch: bycatch-catch,
        bycatch-percentage: bycatch-percentage,
        improvement-score: improvement-score,
        incentive-earned: incentive-amount
      }
    )
    (ok incentive-amount)
  )
)

;; Read-only Functions
(define-read-only (get-bycatch-record (bycatch-id uint))
  (map-get? bycatch-records { bycatch-id: bycatch-id })
)

(define-read-only (get-fishing-method-stats (method (string-ascii 30)) (species (string-ascii 30)))
  (map-get? fishing-method-stats { method: method, species: species })
)

(define-read-only (get-vessel-performance (vessel-id uint) (period uint))
  (map-get? vessel-bycatch-performance { vessel-id: vessel-id, period: period })
)

(define-read-only (get-protected-species-info (species (string-ascii 30)))
  (map-get? protected-species { species: species })
)

(define-read-only (calculate-bycatch-percentage (target-catch uint) (bycatch-catch uint))
  (calculate-bycatch-rate target-catch bycatch-catch)
)
