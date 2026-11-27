package config

import (
	"encoding/base64"
	"fmt"
	"net"
	"net/url"
	"os"
	"strconv"
	"strings"
)

type Config struct {
	ListenAddr     string
	DatabaseURL    string
	StorageBackend string
	StoragePath    string
	EncryptionKey  []byte
	LogLevel       string
}

func Load() (Config, error) {
	return LoadFrom(os.Getenv)
}

func LoadFrom(getenv func(string) string) (Config, error) {
	cfg := Config{
		ListenAddr:     value(getenv, "OT_LISTEN_ADDR", "127.0.0.1:8080"),
		DatabaseURL:    strings.TrimSpace(getenv("OT_DATABASE_URL")),
		StorageBackend: strings.ToLower(value(getenv, "OT_STORAGE_BACKEND", "local")),
		StoragePath:    strings.TrimSpace(getenv("OT_STORAGE_LOCAL_PATH")),
		LogLevel:       strings.ToLower(value(getenv, "OT_LOG_LEVEL", "info")),
	}

	keyText := strings.TrimSpace(getenv("OT_ENCRYPTION_KEY"))
	if keyText != "" {
		key, err := base64.StdEncoding.DecodeString(keyText)
		if err != nil {
			return Config{}, fmt.Errorf("OT_ENCRYPTION_KEY must be valid base64")
		}
		cfg.EncryptionKey = key
	}

	if err := cfg.Validate(); err != nil {
		return Config{}, err
	}
	return cfg, nil
}

func (c Config) Validate() error {
	if _, _, err := net.SplitHostPort(c.ListenAddr); err != nil {
		return fmt.Errorf("OT_LISTEN_ADDR must be host:port: %w", err)
	}
	if c.StorageBackend != "local" && c.StorageBackend != "nas" {
		return fmt.Errorf("unsupported OT_STORAGE_BACKEND %q (supported: local, nas)", c.StorageBackend)
	}
	if !strings.HasPrefix(c.StoragePath, "/") {
		return fmt.Errorf("OT_STORAGE_LOCAL_PATH must be an absolute path")
	}
	if c.DatabaseURL == "" {
		return fmt.Errorf("OT_DATABASE_URL is required")
	}
	u, err := url.Parse(c.DatabaseURL)
	if err != nil || (u.Scheme != "postgres" && u.Scheme != "postgresql") || u.Hostname() == "" {
		return fmt.Errorf("OT_DATABASE_URL must be a valid postgres:// or postgresql:// URL")
	}
	if c.EncryptionKey != nil && len(c.EncryptionKey) != 32 {
		return fmt.Errorf("OT_ENCRYPTION_KEY must decode to exactly 32 bytes")
	}
	switch c.LogLevel {
	case "debug", "info", "warn", "error":
	default:
		return fmt.Errorf("OT_LOG_LEVEL must be debug, info, warn or error")
	}
	return nil
}

// DatabaseAddress returns the TCP endpoint used by the readiness probe.
// It deliberately does not claim that PostgreSQL authentication or schema
// migrations have been checked.
func DatabaseAddress(databaseURL string) (string, error) {
	u, err := url.Parse(databaseURL)
	if err != nil {
		return "", err
	}
	host := u.Hostname()
	if host == "" {
		return "", fmt.Errorf("database hostname is missing")
	}
	port := u.Port()
	if port == "" {
		port = "5432"
	}
	if _, err := strconv.Atoi(port); err != nil {
		return "", fmt.Errorf("database port is invalid")
	}
	return net.JoinHostPort(host, port), nil
}

func value(getenv func(string) string, key, fallback string) string {
	if v := strings.TrimSpace(getenv(key)); v != "" {
		return v
	}
	return fallback
}
