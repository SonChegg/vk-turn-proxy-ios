package proxycore

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"strings"
	"sync"
)

// Service is a gomobile-friendly wrapper around the TURN proxy runtime.
type Service struct {
	mu     sync.Mutex
	cancel context.CancelFunc
	running bool
	logs   []string
}

func NewService() *Service {
	return &Service{
		logs: []string{"Ожидание запуска..."},
	}
}

// Start accepts a JSON-encoded string array with CLI-style arguments.
// Example:
// ["-peer","1.2.3.4:56000","-vk-link","https://vk.com/call/join/...","-listen","127.0.0.1:9000","-udp"]
func (s *Service) Start(argsJSON string) string {
	var args []string
	if err := json.Unmarshal([]byte(argsJSON), &args); err != nil {
		return fmt.Sprintf("failed to decode args JSON: %v", err)
	}

	s.mu.Lock()
	if s.running {
		s.mu.Unlock()
		return "proxy is already running"
	}

	ctx, cancel := context.WithCancel(context.Background())
	s.cancel = cancel
	s.running = true
	s.logs = nil
	s.mu.Unlock()

	s.appendLog("=== ЗАПУСК PROXY ===")

	go func() {
		if err := s.run(ctx, args); err != nil {
			s.appendLog(fmt.Sprintf("КРИТИЧЕСКАЯ ОШИБКА: %v", err))
		}

		s.mu.Lock()
		s.running = false
		s.cancel = nil
		s.mu.Unlock()

		s.appendLog("=== ПРОКСИ ОСТАНОВЛЕН ===")
	}()

	return ""
}

func (s *Service) run(ctx context.Context, args []string) error {
	writer := &serviceLogWriter{service: s}
	prevWriter := log.Writer()
	prevFlags := log.Flags()
	log.SetOutput(writer)
	log.SetFlags(0)
	defer func() {
		log.SetOutput(prevWriter)
		log.SetFlags(prevFlags)
	}()

	return runArgs(ctx, args)
}

func (s *Service) Stop() {
	s.mu.Lock()
	cancel := s.cancel
	s.mu.Unlock()

	if cancel != nil {
		s.appendLog("=== ОСТАНОВКА ИЗ ИНТЕРФЕЙСА ===")
		cancel()
	}
}

func (s *Service) IsRunning() bool {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.running
}

// DrainLogs returns accumulated logs and clears the buffer.
func (s *Service) DrainLogs() string {
	s.mu.Lock()
	defer s.mu.Unlock()

	if len(s.logs) == 0 {
		return ""
	}

	joined := strings.Join(s.logs, "\n")
	s.logs = nil
	return joined
}

func (s *Service) appendLog(msg string) {
	s.mu.Lock()
	defer s.mu.Unlock()

	for _, line := range strings.Split(msg, "\n") {
		clean := strings.TrimSpace(line)
		if clean == "" {
			continue
		}
		s.logs = append(s.logs, clean)
	}

	if len(s.logs) > 400 {
		s.logs = s.logs[len(s.logs)-400:]
	}
}

type serviceLogWriter struct {
	service *Service
}

func (w *serviceLogWriter) Write(p []byte) (int, error) {
	w.service.appendLog(strings.TrimRight(string(p), "\r\n"))
	return len(p), nil
}
