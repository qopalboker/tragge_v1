package server

// Contest/join status and JSON keys used across user-bff handlers.
const (
	contestStatusRegistrationOpen = "registration_open"
	contestStatusScheduled        = "scheduled"
	contestStatusRunning          = "running"

	jsonKeyReason = "reason"

	envDevelopment = "development"
	envDev         = "dev"
	envLocal       = "local"
)
