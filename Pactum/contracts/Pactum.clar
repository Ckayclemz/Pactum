;; Project: Pactum Smart Contract
;; Description:
;; Pactum is a guild governance and venture coordination protocol.
;; It enables guild craftsmen to initiate ventures, deliberate in 
;; council, endorse or object proposals, and allocate treasury 
;; resources. Reputation (guild standing) determines influence, 
;; ensuring collective decision-making aligns with merit. 
;; Pactum provides a structured process for:
;;   - Initiating guild ventures with charters and treasury needs
;;   - Council deliberation with endorsements and objections
;;   - Commencement of approved ventures and fund transfers
;;   - Contribution and distribution of guild standing
;;   - Coordinated multi-venture execution

;; Metadata constants
(define-constant PROJECT_NAME "Pactum")
(define-constant PROJECT_DESCRIPTION "A guild governance and venture coordination protocol driven by reputation and council deliberation.")

;; Define error constants
(define-constant ERR_NOT_GUILD_CRAFTSMAN (err u100)) 
(define-constant ERR_CRAFTSMAN_ALREADY_DELIBERATED (err u101)) 
(define-constant ERR_COUNCIL_SESSION_ENDED (err u102)) 
(define-constant ERR_INVALID_TREASURY_AMOUNT (err u103)) 
(define-constant ERR_INSUFFICIENT_GUILD_STANDING (err u104)) 
(define-constant ERR_VENTURE_PROPOSAL_MISSING (err u105)) 
(define-constant ERR_VENTURE_ALREADY_COMMENCED (err u106)) 
(define-constant ERR_DEFECTIVE_VENTURE_RECORD (err u107)) 
(define-constant ERR_INVALID_GUILD_MEMBER (err u108)) 
(define-constant ERR_GUILD_COORDINATION_FAILURE (err u109)) 

;; Define data variables
(define-data-var total-guild-reputation uint u1000000) ;; Total guild standing points
(define-data-var guild-venture-count uint u0) ;; Counter for guild venture IDs

;; Define data maps
(define-map craftsman-reputation principal uint) ;; Guild standing per craftsman
(define-map guild-ventures 
  uint 
  {
    venture-master: principal,
    expedition-name: (string-ascii 50),
    venture-charter: (string-utf8 500),
    treasury-requirement: uint,
    venture-beneficiary: principal,
    guild-endorsements: uint,
    craftsman-objections: uint,
    council-deadline: uint,
    commenced: bool
  }
)
(define-map deliberation-records {venture-id: uint, craftsman: principal} bool)

;; Read-only functions

(define-read-only (inspect-craftsman-standing (guild-member principal))
  (default-to u0 (map-get? craftsman-reputation guild-member))
)

(define-read-only (examine-guild-venture (venture-id uint))
  (map-get? guild-ventures venture-id)
)

(define-read-only (craftsman-has-deliberated (venture-id uint) (guild-member principal))
  (default-to false (map-get? deliberation-records {venture-id: venture-id, craftsman: guild-member}))
)

;; Helper function to validate guild member
(define-private (is-recognized-guild-member (member principal))
  (and
    (not (is-eq member 'SP000000000000000000002Q6VF78))
    (not (is-eq member (as-contract tx-sender)))
  )
)

;; Public functions

(define-public (initiate-guild-venture (expedition-name (string-ascii 50)) (venture-charter (string-utf8 500)) (treasury-requirement uint) (venture-beneficiary principal))
  (let
    (
      (venture-id (+ (var-get guild-venture-count) u1))
      (venture-master tx-sender)
    )
    (asserts! (>= (inspect-craftsman-standing venture-master) u1) ERR_NOT_GUILD_CRAFTSMAN)
    (asserts! (> treasury-requirement u0) ERR_INVALID_TREASURY_AMOUNT)
    (asserts! (<= treasury-requirement u1000000000) ERR_INVALID_TREASURY_AMOUNT)
    (asserts! (is-some (as-max-len? expedition-name u50)) ERR_DEFECTIVE_VENTURE_RECORD)
    (asserts! (is-some (as-max-len? venture-charter u500)) ERR_DEFECTIVE_VENTURE_RECORD)
    (asserts! (is-recognized-guild-member venture-beneficiary) ERR_INVALID_GUILD_MEMBER)
    (map-set guild-ventures venture-id
      {
        venture-master: venture-master,
        expedition-name: expedition-name,
        venture-charter: venture-charter,
        treasury-requirement: treasury-requirement,
        venture-beneficiary: venture-beneficiary,
        guild-endorsements: u0,
        craftsman-objections: u0,
        council-deadline: (+ stacks-block-height u1440),
        commenced: false
      }
    )
    (var-set guild-venture-count venture-id)
    (ok venture-id)
  )
)

(define-public (participate-in-council (venture-id uint) (endorse-venture bool))
  (let
    (
      (deliberating-craftsman tx-sender)
      (venture (unwrap! (examine-guild-venture venture-id) ERR_VENTURE_PROPOSAL_MISSING))
      (craftsman-standing (inspect-craftsman-standing deliberating-craftsman))
    )
    (asserts! (< stacks-block-height (get council-deadline venture)) ERR_COUNCIL_SESSION_ENDED)
    (asserts! (not (craftsman-has-deliberated venture-id deliberating-craftsman)) ERR_CRAFTSMAN_ALREADY_DELIBERATED)
    (asserts! (> craftsman-standing u0) ERR_NOT_GUILD_CRAFTSMAN)
    
    (map-set deliberation-records {venture-id: venture-id, craftsman: deliberating-craftsman} true)
    
    (if endorse-venture
      (map-set guild-ventures venture-id 
        (merge venture {guild-endorsements: (+ (get guild-endorsements venture) craftsman-standing)}))
      (map-set guild-ventures venture-id 
        (merge venture {craftsman-objections: (+ (get craftsman-objections venture) craftsman-standing)}))
    )
    (ok true)
  )
)

(define-public (commence-approved-venture (venture-id uint))
  (let
    (
      (venture (unwrap! (examine-guild-venture venture-id) ERR_VENTURE_PROPOSAL_MISSING))
    )
    (asserts! (>= stacks-block-height (get council-deadline venture)) ERR_COUNCIL_SESSION_ENDED)
    (asserts! (not (get commenced venture)) ERR_VENTURE_ALREADY_COMMENCED)
    (asserts! (> (get guild-endorsements venture) (get craftsman-objections venture)) ERR_NOT_GUILD_CRAFTSMAN)
    
    (map-set guild-ventures venture-id (merge venture {commenced: true}))
    
    (as-contract (stx-transfer? (get treasury-requirement venture) tx-sender (get venture-beneficiary venture)))
  )
)

(define-public (contribute-to-guild-coffers (amount uint))
  (let
    (
      (contributing-member tx-sender)
    )
    (asserts! (> amount u0) ERR_INVALID_TREASURY_AMOUNT)
    (asserts! (<= amount u1000000000) ERR_INVALID_TREASURY_AMOUNT)
    (try! (stx-transfer? amount contributing-member (as-contract tx-sender)))
    (ok true)
  )
)

(define-public (bestow-guild-standing (amount uint) (apprentice principal))
  (let
    (
      (existing-standing (inspect-craftsman-standing apprentice))
      (elevated-standing (+ existing-standing amount))
      (enhanced-total-reputation (+ (var-get total-guild-reputation) amount))
    )
    (asserts! (is-eq tx-sender (as-contract tx-sender)) ERR_NOT_GUILD_CRAFTSMAN)
    (asserts! (> amount u0) ERR_INVALID_TREASURY_AMOUNT)
    (asserts! (<= amount u1000000000) ERR_INVALID_TREASURY_AMOUNT)
    (asserts! (>= elevated-standing existing-standing) ERR_INVALID_TREASURY_AMOUNT)
    (asserts! (>= enhanced-total-reputation (var-get total-guild-reputation)) ERR_INVALID_TREASURY_AMOUNT)
    (asserts! (is-recognized-guild-member apprentice) ERR_INVALID_GUILD_MEMBER)
    
    (var-set total-guild-reputation enhanced-total-reputation)
    (map-set craftsman-reputation apprentice elevated-standing)
    (ok true)
  )
)

(define-public (transfer-guild-standing (amount uint) (fellow-craftsman principal))
  (let
    (
      (transferring-member tx-sender)
      (sender-standing (inspect-craftsman-standing transferring-member))
      (recipient-standing (inspect-craftsman-standing fellow-craftsman))
      (enhanced-recipient-standing (+ recipient-standing amount))
    )
    (asserts! (> amount u0) ERR_INVALID_TREASURY_AMOUNT)
    (asserts! (<= amount u1000000000) ERR_INVALID_TREASURY_AMOUNT)
    (asserts! (<= amount sender-standing) ERR_INSUFFICIENT_GUILD_STANDING)
    (asserts! (>= enhanced-recipient-standing recipient-standing) ERR_INVALID_TREASURY_AMOUNT)
    (asserts! (is-recognized-guild-member fellow-craftsman) ERR_INVALID_GUILD_MEMBER)
    
    (map-set craftsman-reputation transferring-member (- sender-standing amount))
    (map-set craftsman-reputation fellow-craftsman enhanced-recipient-standing)
    (ok true)
  )
)

(define-public (mass-commence-ventures (venture-ids (list 10 uint)))
  (let
    (
      (commencement-results (map commence-approved-venture venture-ids))
    )
    (asserts! (is-eq (len commencement-results) (len venture-ids)) ERR_GUILD_COORDINATION_FAILURE)
    (ok true)
  )
)

(define-public (guild-collective-deliberation (deliberation-list (list 10 {venture-id: uint, endorse-venture: bool})))
  (let
    (
      (deliberation-results (map process-council-deliberation deliberation-list))
    )
    (asserts! (is-eq (len deliberation-results) (len deliberation-list)) ERR_GUILD_COORDINATION_FAILURE)
    (ok true)
  )
)

(define-private (process-council-deliberation (deliberation-data {venture-id: uint, endorse-venture: bool}))
  (participate-in-council (get venture-id deliberation-data) (get endorse-venture deliberation-data))
) 
