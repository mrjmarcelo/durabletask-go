package helpers

import (
	"fmt"
	"os"

	"github.com/google/uuid"
)

func GetDefaultWorkerName() string {
	hostname, err := os.Hostname()
	if err != nil {
		hostname = "unknown"
	}

	pid := os.Getpid()
	u, _ := uuid.NewV7()
	uuidStr := u.String()
	return fmt.Sprintf("%v,%d,%v", hostname, pid, uuidStr)
}
