package config

import (
	"strings"
	"testing"
)

func validEnv() map[string]string {
	return map[string]string{
		"OT_LISTEN_ADDR":        "127.0.0.1:8080",
		"OT_DATABASE_URL":       "postgres://opentransfer:secret@localhost:5432/opentransfer?sslmode=disable",
		"OT_STORAGE_BACKEND":    "local",
		"OT_STORAGE_LOCAL_PATH": "/var/lib/opentransfer/files",
		"OT_ENCRYPTION_KEY":     "MDEyMzQ1Njc4OWFiY2RlZjAxMjM0NTY3ODlhYmNkZWY=",
		"OT_LOG_LEVEL":          "info",
	}
}

func TestLoadFromAcceptsValidConfiguration(t *testing.T) {
	values := validEnv()
	cfg, err := LoadFrom(func(key string) string { return values[key] })
	if err != nil {
		t.Fatalf("LoadFrom() error = %v", err)
	}
	if cfg.StorageBackend != "local" || len(cfg.EncryptionKey) != 32 {
		t.Fatalf("unexpected config: backend=%q key-bytes=%d", cfg.StorageBackend, len(cfg.EncryptionKey))
	}
}

func TestLoadFromRejectsMissingDatabase(t *testing.T) {
	values := validEnv()
	values["OT_DATABASE_URL"] = ""
	_, err := LoadFrom(func(key string) string { return values[key] })
	if err == nil || !strings.Contains(err.Error(), "OT_DATABASE_URL") {
		t.Fatalf("expected database configuration error, got %v", err)
	}
}

func TestLoadFromRejectsInvalidEncryptionKey(t *testing.T) {
	values := validEnv()
	values["OT_ENCRYPTION_KEY"] = "bm90LTMyeA=="
	_, err := LoadFrom(func(key string) string { return values[key] })
	if err == nil || !strings.Contains(err.Error(), "32 bytes") {
		t.Fatalf("expected encryption key length error, got %v", err)
	}
}

func TestDatabaseAddressAddsDefaultPort(t *testing.T) {
	got, err := DatabaseAddress("postgres://user:pass@db/opentransfer")
	if err != nil {
		t.Fatal(err)
	}
	if got != "db:5432" {
		t.Fatalf("DatabaseAddress() = %q, want db:5432", got)
	}
}
