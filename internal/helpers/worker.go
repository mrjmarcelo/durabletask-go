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
	uuidStr := uuid.NewString()
 	u, err := uuid.NewV7()
 	if err == nil {
 		uuidStr = u.String()
 	}
	return fmt.Sprintf("%v,%d,%v", hostname, pid, uuidStr)
}
