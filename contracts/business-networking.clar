;; Business Networking Facilitation Contract
;; Connects entrepreneurs with mentors, partners, and customers

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-PROFILE-NOT-FOUND (err u501))
(define-constant ERR-EVENT-NOT-FOUND (err u502))
(define-constant ERR-INVALID-INPUT (err u503))
(define-constant ERR-CONNECTION-EXISTS (err u504))
(define-constant ERR-SELF-CONNECTION (err u505))

;; Data Variables
(define-data-var next-profile-id uint u1)
(define-data-var next-event-id uint u1)
(define-data-var next-connection-id uint u1)
(define-data-var next-opportunity-id uint u1)
(define-data-var networking-fee uint u500000) ;; 0.5 STX in microSTX

;; Data Maps
(define-map user-profiles
  { profile-id: uint }
  {
    owner: principal,
    name: (string-ascii 100),
    title: (string-ascii 100),
    company: (string-ascii 100),
    industry: (string-ascii 50),
    location: (string-ascii 100),
    bio: (string-ascii 1000),
    skills: (string-ascii 500),
    interests: (string-ascii 500),
    profile-type: (string-ascii 30),
    experience-level: (string-ascii 30),
    availability: (string-ascii 30),
    contact-info: (string-ascii 200),
    created-at: uint,
    last-active: uint,
    verified: bool
  }
)

(define-map profile-owners
  { owner: principal }
  { profile-id: uint }
)

(define-map networking-events
  { event-id: uint }
  {
    organizer: principal,
    title: (string-ascii 200),
    description: (string-ascii 1000),
    event-type: (string-ascii 50),
    industry-focus: (string-ascii 50),
    location: (string-ascii 200),
    start-time: uint,
    end-time: uint,
    max-attendees: uint,
    current-attendees: uint,
    registration-fee: uint,
    status: (string-ascii 20),
    created-at: uint
  }
)

(define-map event-attendees
  { event-id: uint, profile-id: uint }
  {
    registered-at: uint,
    attendance-status: (string-ascii 20),
    feedback-score: (optional uint),
    networking-goals: (string-ascii 500)
  }
)

(define-map connections
  { connection-id: uint }
  {
    profile-1: uint,
    profile-2: uint,
    connection-type: (string-ascii 30),
    status: (string-ascii 20),
    initiated-by: uint,
    created-at: uint,
    last-interaction: uint,
    interaction-count: uint,
    notes: (string-ascii 1000)
  }
)

(define-map partnership-opportunities
  { opportunity-id: uint }
  {
    creator: uint,
    title: (string-ascii 200),
    description: (string-ascii 1000),
    opportunity-type: (string-ascii 50),
    industry: (string-ascii 50),
    requirements: (string-ascii 1000),
    benefits: (string-ascii 1000),
    duration: (string-ascii 50),
    status: (string-ascii 20),
    applications-count: uint,
    created-at: uint,
    deadline: (optional uint)
  }
)

(define-map mentorship-relationships
  { mentor-id: uint, mentee-id: uint }
  {
    start-date: uint,
    end-date: (optional uint),
    meeting-frequency: (string-ascii 50),
    focus-areas: (string-ascii 500),
    status: (string-ascii 20),
    progress-notes: (string-ascii 2000),
    satisfaction-rating: (optional uint)
  }
)

;; Public Functions

;; Create user profile
(define-public (create-user-profile (name (string-ascii 100)) (title (string-ascii 100)) (company (string-ascii 100)) (industry (string-ascii 50)) (location (string-ascii 100)) (bio (string-ascii 1000)) (skills (string-ascii 500)) (interests (string-ascii 500)) (profile-type (string-ascii 30)) (experience-level (string-ascii 30)))
  (let
    (
      (profile-id (var-get next-profile-id))
    )
    (asserts! (> (len name) u0) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? profile-owners { owner: tx-sender })) ERR-INVALID-INPUT)

    (map-set user-profiles
      { profile-id: profile-id }
      {
        owner: tx-sender,
        name: name,
        title: title,
        company: company,
        industry: industry,
        location: location,
        bio: bio,
        skills: skills,
        interests: interests,
        profile-type: profile-type,
        experience-level: experience-level,
        availability: "available",
        contact-info: "",
        created-at: block-height,
        last-active: block-height,
        verified: false
      }
    )

    (map-set profile-owners
      { owner: tx-sender }
      { profile-id: profile-id }
    )

    (var-set next-profile-id (+ profile-id u1))
    (ok profile-id)
  )
)

;; Update profile information
(define-public (update-profile (profile-id uint) (title (string-ascii 100)) (company (string-ascii 100)) (bio (string-ascii 1000)) (skills (string-ascii 500)) (interests (string-ascii 500)) (availability (string-ascii 30)) (contact-info (string-ascii 200)))
  (let
    (
      (profile (unwrap! (map-get? user-profiles { profile-id: profile-id }) ERR-PROFILE-NOT-FOUND))
    )
    (asserts! (is-eq (get owner profile) tx-sender) ERR-NOT-AUTHORIZED)

    (map-set user-profiles
      { profile-id: profile-id }
      (merge profile {
        title: title,
        company: company,
        bio: bio,
        skills: skills,
        interests: interests,
        availability: availability,
        contact-info: contact-info,
        last-active: block-height
      })
    )
    (ok true)
  )
)

;; Create networking event
(define-public (create-networking-event (title (string-ascii 200)) (description (string-ascii 1000)) (event-type (string-ascii 50)) (industry-focus (string-ascii 50)) (location (string-ascii 200)) (start-time uint) (end-time uint) (max-attendees uint) (registration-fee uint))
  (let
    (
      (event-id (var-get next-event-id))
    )
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)
    (asserts! (> end-time start-time) ERR-INVALID-INPUT)
    (asserts! (> start-time block-height) ERR-INVALID-INPUT)
    (asserts! (> max-attendees u0) ERR-INVALID-INPUT)

    (map-set networking-events
      { event-id: event-id }
      {
        organizer: tx-sender,
        title: title,
        description: description,
        event-type: event-type,
        industry-focus: industry-focus,
        location: location,
        start-time: start-time,
        end-time: end-time,
        max-attendees: max-attendees,
        current-attendees: u0,
        registration-fee: registration-fee,
        status: "open",
        created-at: block-height
      }
    )

    (var-set next-event-id (+ event-id u1))
    (ok event-id)
  )
)

;; Register for networking event
(define-public (register-for-event (event-id uint) (networking-goals (string-ascii 500)))
  (let
    (
      (event (unwrap! (map-get? networking-events { event-id: event-id }) ERR-EVENT-NOT-FOUND))
      (profile-data (unwrap! (map-get? profile-owners { owner: tx-sender }) ERR-PROFILE-NOT-FOUND))
      (profile-id (get profile-id profile-data))
    )
    (asserts! (is-eq (get status event) "open") ERR-INVALID-INPUT)
    (asserts! (< (get current-attendees event) (get max-attendees event)) ERR-INVALID-INPUT)
    (asserts! (is-none (map-get? event-attendees { event-id: event-id, profile-id: profile-id })) ERR-INVALID-INPUT)

    (map-set event-attendees
      { event-id: event-id, profile-id: profile-id }
      {
        registered-at: block-height,
        attendance-status: "registered",
        feedback-score: none,
        networking-goals: networking-goals
      }
    )

    (map-set networking-events
      { event-id: event-id }
      (merge event {
        current-attendees: (+ (get current-attendees event) u1)
      })
    )

    (ok true)
  )
)

;; Initiate connection
(define-public (initiate-connection (target-profile-id uint) (connection-type (string-ascii 30)) (notes (string-ascii 1000)))
  (let
    (
      (initiator-data (unwrap! (map-get? profile-owners { owner: tx-sender }) ERR-PROFILE-NOT-FOUND))
      (initiator-profile-id (get profile-id initiator-data))
      (target-profile (unwrap! (map-get? user-profiles { profile-id: target-profile-id }) ERR-PROFILE-NOT-FOUND))
      (connection-id (var-get next-connection-id))
    )
    (asserts! (not (is-eq initiator-profile-id target-profile-id)) ERR-SELF-CONNECTION)

    (map-set connections
      { connection-id: connection-id }
      {
        profile-1: initiator-profile-id,
        profile-2: target-profile-id,
        connection-type: connection-type,
        status: "pending",
        initiated-by: initiator-profile-id,
        created-at: block-height,
        last-interaction: block-height,
        interaction-count: u1,
        notes: notes
      }
    )

    (var-set next-connection-id (+ connection-id u1))
    (ok connection-id)
  )
)

;; Accept connection
(define-public (accept-connection (connection-id uint))
  (let
    (
      (connection (unwrap! (map-get? connections { connection-id: connection-id }) ERR-PROFILE-NOT-FOUND))
      (profile-data (unwrap! (map-get? profile-owners { owner: tx-sender }) ERR-PROFILE-NOT-FOUND))
      (profile-id (get profile-id profile-data))
    )
    (asserts! (is-eq (get status connection) "pending") ERR-INVALID-INPUT)
    (asserts! (is-eq (get profile-2 connection) profile-id) ERR-NOT-AUTHORIZED)

    (map-set connections
      { connection-id: connection-id }
      (merge connection {
        status: "accepted",
        last-interaction: block-height,
        interaction-count: (+ (get interaction-count connection) u1)
      })
    )
    (ok true)
  )
)

;; Create partnership opportunity
(define-public (create-partnership-opportunity (title (string-ascii 200)) (description (string-ascii 1000)) (opportunity-type (string-ascii 50)) (industry (string-ascii 50)) (requirements (string-ascii 1000)) (benefits (string-ascii 1000)) (duration (string-ascii 50)) (deadline (optional uint)))
  (let
    (
      (profile-data (unwrap! (map-get? profile-owners { owner: tx-sender }) ERR-PROFILE-NOT-FOUND))
      (profile-id (get profile-id profile-data))
      (opportunity-id (var-get next-opportunity-id))
    )
    (asserts! (> (len title) u0) ERR-INVALID-INPUT)

    (map-set partnership-opportunities
      { opportunity-id: opportunity-id }
      {
        creator: profile-id,
        title: title,
        description: description,
        opportunity-type: opportunity-type,
        industry: industry,
        requirements: requirements,
        benefits: benefits,
        duration: duration,
        status: "open",
        applications-count: u0,
        created-at: block-height,
        deadline: deadline
      }
    )

    (var-set next-opportunity-id (+ opportunity-id u1))
    (ok opportunity-id)
  )
)

;; Start mentorship relationship
(define-public (start-mentorship (mentee-profile-id uint) (meeting-frequency (string-ascii 50)) (focus-areas (string-ascii 500)))
  (let
    (
      (mentor-data (unwrap! (map-get? profile-owners { owner: tx-sender }) ERR-PROFILE-NOT-FOUND))
      (mentor-profile-id (get profile-id mentor-data))
      (mentee-profile (unwrap! (map-get? user-profiles { profile-id: mentee-profile-id }) ERR-PROFILE-NOT-FOUND))
    )
    (asserts! (not (is-eq mentor-profile-id mentee-profile-id)) ERR-SELF-CONNECTION)

    (map-set mentorship-relationships
      { mentor-id: mentor-profile-id, mentee-id: mentee-profile-id }
      {
        start-date: block-height,
        end-date: none,
        meeting-frequency: meeting-frequency,
        focus-areas: focus-areas,
        status: "active",
        progress-notes: "",
        satisfaction-rating: none
      }
    )
    (ok true)
  )
)

;; Update mentorship progress
(define-public (update-mentorship-progress (mentee-profile-id uint) (progress-notes (string-ascii 2000)))
  (let
    (
      (mentor-data (unwrap! (map-get? profile-owners { owner: tx-sender }) ERR-PROFILE-NOT-FOUND))
      (mentor-profile-id (get profile-id mentor-data))
      (mentorship (unwrap! (map-get? mentorship-relationships { mentor-id: mentor-profile-id, mentee-id: mentee-profile-id }) ERR-PROFILE-NOT-FOUND))
    )
    (asserts! (is-eq (get status mentorship) "active") ERR-INVALID-INPUT)

    (map-set mentorship-relationships
      { mentor-id: mentor-profile-id, mentee-id: mentee-profile-id }
      (merge mentorship { progress-notes: progress-notes })
    )
    (ok true)
  )
)

;; Read-only Functions

;; Get user profile
(define-read-only (get-user-profile (profile-id uint))
  (map-get? user-profiles { profile-id: profile-id })
)

;; Get profile by owner
(define-read-only (get-profile-by-owner (owner principal))
  (match (map-get? profile-owners { owner: owner })
    profile-data (map-get? user-profiles { profile-id: (get profile-id profile-data) })
    none
  )
)

;; Get networking event
(define-read-only (get-networking-event (event-id uint))
  (map-get? networking-events { event-id: event-id })
)

;; Get event attendance
(define-read-only (get-event-attendance (event-id uint) (profile-id uint))
  (map-get? event-attendees { event-id: event-id, profile-id: profile-id })
)

;; Get connection
(define-read-only (get-connection (connection-id uint))
  (map-get? connections { connection-id: connection-id })
)

;; Get partnership opportunity
(define-read-only (get-partnership-opportunity (opportunity-id uint))
  (map-get? partnership-opportunities { opportunity-id: opportunity-id })
)

;; Get mentorship relationship
(define-read-only (get-mentorship-relationship (mentor-id uint) (mentee-id uint))
  (map-get? mentorship-relationships { mentor-id: mentor-id, mentee-id: mentee-id })
)

;; Get networking fee
(define-read-only (get-networking-fee)
  (var-get networking-fee)
)

;; Administrative Functions

;; Verify user profile (owner only)
(define-public (verify-user-profile (profile-id uint))
  (let
    (
      (profile (unwrap! (map-get? user-profiles { profile-id: profile-id }) ERR-PROFILE-NOT-FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (map-set user-profiles
      { profile-id: profile-id }
      (merge profile { verified: true })
    )
    (ok true)
  )
)

;; Update networking fee (owner only)
(define-public (update-networking-fee (new-fee uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set networking-fee new-fee)
    (ok true)
  )
)

;; Cancel event (owner only)
(define-public (cancel-event (event-id uint))
  (let
    (
      (event (unwrap! (map-get? networking-events { event-id: event-id }) ERR-EVENT-NOT-FOUND))
    )
    (asserts! (or (is-eq tx-sender CONTRACT-OWNER) (is-eq tx-sender (get organizer event))) ERR-NOT-AUTHORIZED)

    (map-set networking-events
      { event-id: event-id }
      (merge event { status: "cancelled" })
    )
    (ok true)
  )
)
