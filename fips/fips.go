// Package fips provides FIPS compliance checks.
// Stub implementation for non-FIPS builds.
package fips

// IsFipsEnabled returns true when running in FIPS-compliant mode.
// This stub always returns false.
func IsFipsEnabled() bool {
	return false
}
