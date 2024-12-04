;; Tool Library Rental System Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-available (err u101))
(define-constant err-not-rented (err u102))
(define-constant err-unauthorized (err u103))

;; Data Variables
(define-map tools 
    { tool-id: uint }
    {
        name: (string-ascii 50),
        available: bool,
        current-renter: (optional principal),
        rental-fee: uint
    }
)

(define-map user-rentals
    { user: principal }
    { active-rentals: (list 10 uint) }
)

;; Public Functions
(define-public (add-tool (tool-id uint) (name (string-ascii 50)) (rental-fee uint))
    (if (is-eq tx-sender contract-owner)
        (begin
            (map-set tools 
                { tool-id: tool-id }
                {
                    name: name,
                    available: true,
                    current-renter: none,
                    rental-fee: rental-fee
                }
            )
            (ok true)
        )
        err-owner-only
    )
)

(define-public (rent-tool (tool-id uint))
    (let (
        (tool (unwrap! (map-get? tools { tool-id: tool-id }) (err u404)))
        (user-rental (default-to { active-rentals: (list) } 
            (map-get? user-rentals { user: tx-sender })))
    )
    (if (get available tool)
        (begin
            (map-set tools
                { tool-id: tool-id }
                (merge tool {
                    available: false,
                    current-renter: (some tx-sender)
                })
            )
            (map-set user-rentals
                { user: tx-sender }
                { active-rentals: (unwrap! (as-max-len? 
                    (append (get active-rentals user-rental) tool-id) u10)
                    (err u404)) }
            )
            (ok true)
        )
        err-not-available
    ))
)

(define-public (return-tool (tool-id uint))
    (let (
        (tool (unwrap! (map-get? tools { tool-id: tool-id }) (err u404)))
    )
    (if (is-eq (some tx-sender) (get current-renter tool))
        (begin
            (map-set tools
                { tool-id: tool-id }
                (merge tool {
                    available: true,
                    current-renter: none
                })
            )
            (ok true)
        )
        err-unauthorized
    ))
)

;; Read Only Functions
(define-read-only (get-tool-info (tool-id uint))
    (map-get? tools { tool-id: tool-id })
)

(define-read-only (get-user-rentals (user principal))
    (map-get? user-rentals { user: user })
)

(define-read-only (is-tool-available (tool-id uint))
    (match (map-get? tools { tool-id: tool-id })
        tool (ok (get available tool))
        (err u404)
    )
)
