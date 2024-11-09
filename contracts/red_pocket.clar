;; title: red_pocket
;; version: 0.0.1
;; summary:
;; description:

;; token definitions
;;

;; constants
;;
(define-constant contract-owner tx-sender)

(define-constant BASIS_POINTS_DIVISOR u10000)

(define-constant ERR-CLAIM-TOO-EARLY (err u100))
(define-constant ERR-CLAIM-TOO-LATE (err u101))
(define-constant ERR-DUP-ADDR (err u102))
(define-constant ERR-EMPTY-ADDR (err u103))
(define-constant ERR-INSUFFICIENT-AMOUNT (err u104))
(define-constant ERR-INVALID-ACCESS (err u105))
(define-constant ERR-INVALID-BLOCK-DURATION (err u106))
(define-constant ERR-INVALID-CANCEL (err u107))
(define-constant ERR-INVALID-CLAIMED (err u108))
(define-constant ERR-INVALID-PARAMS (err u109))
(define-constant ERR-INVALID-TOKEN (err u110))
(define-constant ERR-INVALID-MODE (err u111))
(define-constant ERR-INVALID-REVEAL-BLOCK-AFTER (err u112))
(define-constant ERR-INVALID-RED-POCKET-CANCELLED (err u113))
(define-constant ERR-OWNER-ONLY (err u114))
(define-constant ERR-500 (err u500))



;; data vars
;;

;; Smart contract's configurations
(define-data-var min-reveal-block-after uint u1)       
(define-data-var max-reveal-block-after uint u1000)       
(define-data-var min-block-duration uint u1)           
(define-data-var max-block-duration uint u3000)           
(define-data-var max-mode-no uint u3)                  
(define-data-var cancel-disabled bool false)                  

;; Track current index
(define-data-var distributionIndex uint u0)

;; data maps
;;

(define-map distributions uint {
    mode: uint,
    state: uint,
    creator: principal,
    ;; token: principal,
    ;; isValid: (define-map isValid principal{ isValid: bool }),
    ;; claimers: list 100 principal,
    totalAmount: uint,
    amountRemaining: uint,
    seatRemaining: uint,
    revealBlock: uint,
    claimDuration: uint,
})

(define-map amountRemainings uint uint)

(define-map modes uint uint)

(define-map distribution-claimers
    {did: uint, claimer: principal}
    bool
)

;; public functions
;;
(define-public (createRedPocket (amount uint) (mode uint) (addresses (list 3 principal)) (revealBlock uint) (claimDuration uint))
  (begin
    ;; Perform all necessary checks
    (asserts! (> amount u0) (err ERR-INSUFFICIENT-AMOUNT))
    ;; (asserts! (> mode u0) (err ERR-INVALID-MODE))
    (asserts! (< mode (var-get max-mode-no)) (err ERR-INVALID-MODE))
    (asserts! (and (>= revealBlock (var-get min-reveal-block-after)) 
                 (<= revealBlock (var-get max-reveal-block-after))) 
             (err ERR-INVALID-REVEAL-BLOCK-AFTER))
    (asserts! (and (>= claimDuration (var-get min-block-duration)) 
                 (<= claimDuration (var-get max-block-duration))) 
             (err ERR-INVALID-BLOCK-DURATION))

    (asserts! (map-set distributions
        (var-get distributionIndex)
        {
          mode: mode,
          state: u0,
          creator: tx-sender,
          ;; token: token,
          totalAmount: amount,
          amountRemaining: amount,
          seatRemaining: u3,
          revealBlock: revealBlock,
          claimDuration: claimDuration
        }
      )
      (err ERR-500)
    )
    (if (>= (len addresses) u3) 
      (begin 
        (set-claimer (var-get distributionIndex) (unwrap! (element-at? addresses u0) (err ERR-500)))
      (set-claimer (var-get distributionIndex) (unwrap! (element-at? addresses u1) (err ERR-500)))
      (set-claimer (var-get distributionIndex) (unwrap! (element-at? addresses u2) (err ERR-500)))
      (asserts! (map-set amountRemainings  (var-get distributionIndex) amount) (err ERR-500))
      (asserts! (map-set modes  (var-get distributionIndex) mode) (err ERR-500))
      (asserts! (var-set distributionIndex (+ (var-get distributionIndex) u1)) (err ERR-500))
      ;; Perform the transfer if all checks pass
      (unwrap-panic (stx-transfer? amount tx-sender (as-contract tx-sender)))
      (ok "Created")
      )
      (err ERR-500)
    )
    
  )
)

(define-public (claimRedPocket (index uint)) 
  (let
    (
      (is-valid (unwrap! (get-isValid index) (err ERR-INVALID-CLAIMED)))
      (dist (unwrap! (get-tokenRemaining index) (err ERR-500)))
      (remainingAmount (unwrap! (get-amountRemaining index) (err ERR-500)))
      (seatRemaining (get seatRemaining dist))
      (mode (unwrap! (get-mode index) (err ERR-500)))
      (even-amount (get-even-amount remainingAmount seatRemaining))
    )
    (asserts! is-valid (err ERR-INVALID-CLAIMED))
    (if (is-eq seatRemaining u1) 
      ;; if only 1 seat remaining
      (begin 
        (update-remainingAmount index u0)
        (try! (transferToClaimer remainingAmount))
        (ok true)
      )
      ;; mode u0: even mode
      (if (is-eq mode u0) 
        (begin 
          (update-remainingAmount index (- remainingAmount even-amount))
          (try! (transferToClaimer even-amount))
          (ok true)
        )
          ;; TODO
        (err ERR-INVALID-MODE)
      )
      ;; (ok true)
    )
  )
)



;; read only functions
;;

(define-read-only (get-isValid (index uint))
    (map-get? distribution-claimers {did: index, claimer: tx-sender})
)

(define-read-only (get-tokenRemaining (index uint))
    (map-get? distributions index)
)

(define-read-only (get-amountRemaining (index uint))
    (map-get? amountRemainings index)
)

(define-read-only (get-mode (index uint))
    (map-get? modes index)
)


(define-read-only (get-even-amount (amountRemaining uint) (seatRemaing uint))
  (/ amountRemaining seatRemaing)
)

;; (define-read-only (func-name) body)

;; private functions
;;

(define-private (reduce-remainngAmount (current-remaining uint) (reduction uint)) 
  (- current-remaining reduction)
)

(define-private (update-remainingAmount (index uint) (new-remaining uint)) 
    (map-set amountRemainings index new-remaining) 
    ;; (ok true)
)

;; (define-private (get-random-seed (block-num uint)) 
;;   (get-block-info? id-header-hash block-num)
;; )

(define-private (set-claimer (index uint) (addr principal)) 
  (map-set distribution-claimers {did: index, claimer: addr} true)
)

;; (define-private (generate-random-amount (remaingAmount uint) (block-num uint)) 
;;   (let 
;;     (
;;       (seed (get-random-seed block-num))
;;     ) 
;;     ;; (buff-to-uint-be 
;;       (unwrap! 
;;         (slice? 
;;           (unwrap! (to-consensus-buff? tx-sender) (err ERR-500)) 
;;           u0 u16
;;         )
;;         (err ERR-500)
;;       )
;;     ;; )
;;   )
;; )

(define-public (transferToClaimer (amount uint))
  (begin 
    (asserts! (> amount u0) (err ERR-INSUFFICIENT-AMOUNT))
    (let ((transfer-result (stx-transfer? amount (as-contract tx-sender) tx-sender)))
      (match transfer-result
        ok (ok true)
        err (err transfer-result)
      )
    )
  )
)
