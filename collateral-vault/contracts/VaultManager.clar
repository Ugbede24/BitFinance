;; VaultManager.clar
;; Manages BTC collateral vaults for the BitFinance protocol

;; Constants for vault management
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INSUFFICIENT_COLLATERAL (err u101))
(define-constant ERR_VAULT_NOT_FOUND (err u102))
(define-constant ERR_BELOW_MIN_COLLATERAL (err u103))
(define-constant ERR_VAULT_ALREADY_EXISTS (err u104))

;; Minimum collateral ratio (150%)
(define-constant MIN_COLLATERAL_RATIO u150)

;; Liquidation threshold (130%)
(define-constant LIQUIDATION_THRESHOLD u130)

;; Data maps for vault management
(define-map vaults
  { owner: principal }
  { 
    collateral-amount: uint,
    debt-amount: uint,
    last-update-block: uint
  }
)

;; Protocol admin for privileged operations
(define-data-var protocol-admin principal tx-sender)

;; Total collateral in the protocol
(define-data-var total-collateral uint u0)

;; Total debt in the protocol
(define-data-var total-debt uint u0)

;; Check if caller is admin
(define-private (is-admin)
  (is-eq tx-sender (var-get protocol-admin))
)

;; Update admin (admin only)
(define-public (set-admin (new-admin principal))
  (begin
    (asserts! (is-admin) ERR_UNAUTHORIZED)
    (ok (var-set protocol-admin new-admin))
  )
)

;; Create a new vault
(define-public (create-vault)
  (let
    (
      (existing-vault (map-get? vaults { owner: tx-sender }))
    )
    (asserts! (is-none existing-vault) ERR_VAULT_ALREADY_EXISTS)
    (map-set vaults
      { owner: tx-sender }
      {
        collateral-amount: u0,
        debt-amount: u0,
        last-update-block: block-height
      }
    )
    (ok true)
  )
)

;; Add collateral to vault
(define-public (add-collateral (amount uint))
  (let
    (
      (vault (unwrap! (map-get? vaults { owner: tx-sender }) ERR_VAULT_NOT_FOUND))
      (new-collateral-amount (+ (get collateral-amount vault) amount))
    )
    ;; Transfer collateral - this would be a token transfer in production
    ;; Here, we're just updating the value for simplicity
    
    ;; Update vault with new collateral amount
    (map-set vaults
      { owner: tx-sender }
      (merge vault { 
        collateral-amount: new-collateral-amount,
        last-update-block: block-height
      })
    )
    
    ;; Update total collateral
    (var-set total-collateral (+ (var-get total-collateral) amount))
    
    (ok new-collateral-amount)
  )
)

;; Remove collateral from vault
(define-public (remove-collateral (amount uint))
  (let
    (
      (vault (unwrap! (map-get? vaults { owner: tx-sender }) ERR_VAULT_NOT_FOUND))
      (current-collateral (get collateral-amount vault))
      (current-debt (get debt-amount vault))
      (new-collateral-amount (- current-collateral amount))
    )
    ;; Check if there's enough collateral
    (asserts! (<= amount current-collateral) ERR_INSUFFICIENT_COLLATERAL)
    
    ;; Check if the collateral ratio remains safe
    (asserts! 
      (or
        (is-eq current-debt u0)
        (>= (calculate-collateral-ratio new-collateral-amount current-debt) MIN_COLLATERAL_RATIO)
      ) 
      ERR_BELOW_MIN_COLLATERAL
    )
    
    ;; Update vault with new collateral amount
    (map-set vaults
      { owner: tx-sender }
      (merge vault { 
        collateral-amount: new-collateral-amount,
        last-update-block: block-height
      })
    )
    
    ;; Update total collateral
    (var-set total-collateral (- (var-get total-collateral) amount))
    
    ;; Transfer collateral back to user - would be a token transfer in production
    (ok new-collateral-amount)
  )
)

;; Calculate collateral ratio (collateral / debt * 100)
(define-private (calculate-collateral-ratio (collateral-amount uint) (debt-amount uint))
  (if (is-eq debt-amount u0)
    ;; If no debt, return max uint (infinite ratio)
    (/ (unwrap-panic (pow-precision u2 u32 u0)) u1)
    ;; Otherwise calculate actual ratio
    (/ (* collateral-amount u100) debt-amount)
  )
)

;; Get vault details
(define-read-only (get-vault (owner principal))
  (map-get? vaults { owner: owner })
)

;; Get current collateral ratio for a vault
(define-read-only (get-collateral-ratio (owner principal))
  (let
    (
      (vault (unwrap! (map-get? vaults { owner: owner }) ERR_VAULT_NOT_FOUND))
      (collateral (get collateral-amount vault))
      (debt (get debt-amount vault))
    )
    (ok (calculate-collateral-ratio collateral debt))
  )
)

;; Check if vault can be liquidated
(define-read-only (can-liquidate (owner principal))
  (let
    (
      (vault (unwrap! (map-get? vaults { owner: owner }) ERR_VAULT_NOT_FOUND))
      (collateral (get collateral-amount vault))
      (debt (get debt-amount vault))
    )
    (if (and
          (> debt u0)
          (< (calculate-collateral-ratio collateral debt) LIQUIDATION_THRESHOLD)
        )
      (ok true)
      (ok false)
    )
  )
)

;; This function would be called by the loan contract
(define-public (update-debt (owner principal) (new-debt uint))
  (let
    (
      (vault (unwrap! (map-get? vaults { owner: owner }) ERR_VAULT_NOT_FOUND))
      (current-collateral (get collateral-amount vault))
      (current-debt (get debt-amount vault))
    )
    ;; Check if the collateral ratio remains safe with new debt
    (asserts! 
      (or
        (is-eq new-debt u0)
        (>= (calculate-collateral-ratio current-collateral new-debt) MIN_COLLATERAL_RATIO)
      ) 
      ERR_BELOW_MIN_COLLATERAL
    )
    
    ;; Update total debt tracking
    (var-set total-debt (+ (- (var-get total-debt) current-debt) new-debt))
    
    ;; Update vault with new debt amount
    (map-set vaults
      { owner: owner }
      (merge vault { 
        debt-amount: new-debt,
        last-update-block: block-height
      })
    )
    
    (ok new-debt)
  )
)

;; Get protocol stats
(define-read-only (get-protocol-stats)
  {
    total-collateral: (var-get total-collateral),
    total-debt: (var-get total-debt)
  }
)