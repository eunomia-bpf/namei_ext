// SPDX-License-Identifier: Apache-2.0

package main

import (
	"bufio"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"sort"
	"strings"
	"syscall"

	volumeutil "k8s.io/kubernetes/pkg/volume/util"
)

type fileObservation struct {
	Path  string `json:"path"`
	Errno int    `json:"errno"`
	Bytes string `json:"bytes"`
	Mode  uint32 `json:"mode"`
	UID   uint32 `json:"uid"`
	GID   uint32 `json:"gid"`
	Dev   uint64 `json:"dev"`
	Ino   uint64 `json:"ino"`
	Size  int64  `json:"size"`
}

type stateObservation struct {
	Event         string            `json:"event"`
	Mechanism     string            `json:"mechanism"`
	State         string            `json:"state"`
	DataTarget    string            `json:"data_target"`
	RootEntries   []string          `json:"root_entries"`
	ConfigEntries []string          `json:"config_entries"`
	TLSEntries    []string          `json:"tls_entries"`
	Files         []fileObservation `json:"files"`
	ConsumerExit  int               `json:"consumer_exit"`
	ConsumerOut   string            `json:"consumer_stdout"`
	Pass          bool              `json:"pass"`
}

type descriptorObservation struct {
	Event      string `json:"event"`
	Mechanism  string `json:"mechanism"`
	Stage      string `json:"stage"`
	Bytes      string `json:"bytes"`
	InitialDev uint64 `json:"initial_dev"`
	InitialIno uint64 `json:"initial_ino"`
	CurrentDev uint64 `json:"current_dev"`
	CurrentIno uint64 `json:"current_ino"`
	Pass       bool   `json:"pass"`
}

type directoryDescriptorObservation struct {
	Event          string `json:"event"`
	Mechanism      string `json:"mechanism"`
	State          string `json:"state"`
	Bytes          string `json:"bytes"`
	Mode           uint32 `json:"mode"`
	RootInitialDev uint64 `json:"root_initial_dev"`
	RootInitialIno uint64 `json:"root_initial_ino"`
	RootCurrentDev uint64 `json:"root_current_dev"`
	RootCurrentIno uint64 `json:"root_current_ino"`
	FileDev        uint64 `json:"file_dev"`
	FileIno        uint64 `json:"file_ino"`
	Pass           bool   `json:"pass"`
}

type noOpObservation struct {
	Event      string `json:"event"`
	Mechanism  string `json:"mechanism"`
	DataBefore string `json:"data_before"`
	DataAfter  string `json:"data_after"`
	DevBefore  uint64 `json:"dev_before"`
	InoBefore  uint64 `json:"ino_before"`
	DevAfter   uint64 `json:"dev_after"`
	InoAfter   uint64 `json:"ino_after"`
	Pass       bool   `json:"pass"`
}

type summaryObservation struct {
	Event     string `json:"event"`
	Mechanism string `json:"mechanism"`
	States    int    `json:"states"`
	Pass      bool   `json:"pass"`
	Error     string `json:"error,omitempty"`
}

type expectedFile struct {
	bytes string
	mode  os.FileMode
}

var v0 = map[string]volumeutil.FileProjection{
	"config/app.conf": {Data: []byte("version=0\n"), Mode: 0644},
	"tls/cert.pem":    {Data: []byte("certificate-v0\n"), Mode: 0400},
	"retired.conf":    {Data: []byte("retired\n"), Mode: 0644},
}

var v1 = map[string]volumeutil.FileProjection{
	"config/app.conf": {Data: []byte("version=1\n"), Mode: 0600},
	"tls/cert.pem":    {Data: []byte("certificate-v1\n"), Mode: 0400},
	"added.conf":      {Data: []byte("added\n"), Mode: 0644},
}

func fileStat(path string) (fileObservation, error) {
	observation := fileObservation{Path: path}
	info, err := os.Stat(path)
	if err != nil {
		if errors.Is(err, os.ErrNotExist) {
			observation.Errno = int(syscall.ENOENT)
			return observation, nil
		}
		return observation, err
	}
	data, err := os.ReadFile(path)
	if err != nil {
		return observation, err
	}
	stat, ok := info.Sys().(*syscall.Stat_t)
	if !ok {
		return observation, fmt.Errorf("stat payload unavailable for %s", path)
	}
	observation.Bytes = string(data)
	observation.Mode = uint32(info.Mode().Perm())
	observation.UID = stat.Uid
	observation.GID = stat.Gid
	observation.Dev = uint64(stat.Dev)
	observation.Ino = stat.Ino
	observation.Size = info.Size()
	return observation, nil
}

func listPayload(path string, filterPrivate bool) ([]string, error) {
	entries, err := os.ReadDir(path)
	if err != nil {
		return nil, err
	}
	names := make([]string, 0, len(entries))
	for _, entry := range entries {
		if filterPrivate && strings.HasPrefix(entry.Name(), "..") {
			continue
		}
		names = append(names, entry.Name())
	}
	sort.Strings(names)
	return names, nil
}

func equalNames(actual []string, expected ...string) bool {
	copyExpected := append([]string(nil), expected...)
	sort.Strings(copyExpected)
	if len(actual) != len(copyExpected) {
		return false
	}
	for index := range actual {
		if actual[index] != copyExpected[index] {
			return false
		}
	}
	return true
}

func expectedPayload(payload map[string]volumeutil.FileProjection) map[string]expectedFile {
	expected := make(map[string]expectedFile, len(payload))
	for path, projection := range payload {
		expected[path] = expectedFile{
			bytes: string(projection.Data),
			mode:  os.FileMode(projection.Mode),
		}
	}
	return expected
}

func runConsumer(root string) (int, string, error) {
	command := exec.Command(
		"/bin/sh", "-c", `exec cat "$1/config/app.conf"`, "sh", root,
	)
	output, err := command.CombinedOutput()
	if err == nil {
		return 0, string(output), nil
	}
	var exitError *exec.ExitError
	if errors.As(err, &exitError) {
		return exitError.ExitCode(), string(output), nil
	}
	return -1, string(output), err
}

func captureState(root, state, inventoryPath string,
	payload map[string]volumeutil.FileProjection) (stateObservation, error) {
	observation := stateObservation{
		Event:     "kubernetes-atomicwriter-state",
		Mechanism: "kubernetes-atomicwriter",
		State:     state,
	}
	var err error
	observation.DataTarget, err = os.Readlink(filepath.Join(root, "..data"))
	if err != nil {
		return observation, err
	}
	observation.RootEntries, err = listPayload(root, true)
	if err != nil {
		return observation, err
	}
	observation.ConfigEntries, err = listPayload(filepath.Join(root, "config"), false)
	if err != nil {
		return observation, err
	}
	observation.TLSEntries, err = listPayload(filepath.Join(root, "tls"), false)
	if err != nil {
		return observation, err
	}
	for _, path := range []string{
		"config/app.conf", "tls/cert.pem", "retired.conf", "added.conf",
	} {
		file, fileErr := fileStat(filepath.Join(root, path))
		if fileErr != nil {
			return observation, fileErr
		}
		file.Path = path
		observation.Files = append(observation.Files, file)
	}
	observation.ConsumerExit, observation.ConsumerOut, err = runConsumer(root)
	if err != nil {
		return observation, err
	}
	if err := writeInventory(root, inventoryPath); err != nil {
		return observation, err
	}

	expected := expectedPayload(payload)
	pass := observation.ConsumerExit == 0 &&
		observation.ConsumerOut == expected["config/app.conf"].bytes &&
		equalNames(observation.ConfigEntries, "app.conf") &&
		equalNames(observation.TLSEntries, "cert.pem")
	if _, present := expected["retired.conf"]; present {
		pass = pass && equalNames(observation.RootEntries,
			"config", "retired.conf", "tls")
	} else {
		pass = pass && equalNames(observation.RootEntries,
			"added.conf", "config", "tls")
	}
	for _, file := range observation.Files {
		want, present := expected[file.Path]
		if !present {
			pass = pass && file.Errno == int(syscall.ENOENT)
			continue
		}
		pass = pass && file.Errno == 0 && file.Bytes == want.bytes &&
			file.Mode == uint32(want.mode.Perm())
	}
	observation.Pass = pass
	if !pass {
		return observation, fmt.Errorf("payload oracle failed for state %s", state)
	}
	return observation, nil
}

func writeInventory(root, outputPath string) error {
	output, err := os.Create(outputPath)
	if err != nil {
		return err
	}
	writer := bufio.NewWriter(output)
	walkErr := filepath.Walk(root, func(path string, info os.FileInfo, walkErr error) error {
		if walkErr != nil {
			return walkErr
		}
		relative, err := filepath.Rel(root, path)
		if err != nil {
			return err
		}
		stat, ok := info.Sys().(*syscall.Stat_t)
		if !ok {
			return fmt.Errorf("stat payload unavailable for %s", path)
		}
		target := ""
		if info.Mode()&os.ModeSymlink != 0 {
			target, err = os.Readlink(path)
			if err != nil {
				return err
			}
		}
		_, err = fmt.Fprintf(writer,
			"%s\t%#o\t%d\t%d\t%d\t%d\t%d\t%d\t%s\n",
			relative, uint32(info.Mode()), stat.Uid, stat.Gid,
			stat.Dev, stat.Ino, info.Size(), stat.Mtim.Sec, target)
		return err
	})
	if walkErr == nil {
		walkErr = writer.Flush()
	}
	if closeErr := output.Close(); walkErr == nil {
		walkErr = closeErr
	}
	return walkErr
}

func descriptorState(file *os.File, initial os.FileInfo,
	stage string) (descriptorObservation, error) {
	observation := descriptorObservation{
		Event:     "kubernetes-atomicwriter-old-fd",
		Mechanism: "kubernetes-atomicwriter",
		Stage:     stage,
	}
	if _, err := file.Seek(0, io.SeekStart); err != nil {
		return observation, err
	}
	data, err := io.ReadAll(file)
	if err != nil {
		return observation, err
	}
	current, err := file.Stat()
	if err != nil {
		return observation, err
	}
	initialStat := initial.Sys().(*syscall.Stat_t)
	currentStat := current.Sys().(*syscall.Stat_t)
	observation.Bytes = string(data)
	observation.InitialDev = uint64(initialStat.Dev)
	observation.InitialIno = initialStat.Ino
	observation.CurrentDev = uint64(currentStat.Dev)
	observation.CurrentIno = currentStat.Ino
	observation.Pass = observation.Bytes == "version=0\n" &&
		observation.InitialDev == observation.CurrentDev &&
		observation.InitialIno == observation.CurrentIno
	if !observation.Pass {
		return observation, fmt.Errorf("old descriptor changed at %s", stage)
	}
	return observation, nil
}

func directoryDescriptorState(root *os.File, initial os.FileInfo, state string,
	payload map[string]volumeutil.FileProjection) (directoryDescriptorObservation, error) {
	observation := directoryDescriptorObservation{
		Event:     "kubernetes-atomicwriter-dirfd",
		Mechanism: "kubernetes-atomicwriter",
		State:     state,
	}
	fd, err := syscall.Openat(
		int(root.Fd()), "config/app.conf", syscall.O_RDONLY|syscall.O_CLOEXEC, 0,
	)
	if err != nil {
		return observation, err
	}
	file := os.NewFile(uintptr(fd), "config/app.conf")
	if file == nil {
		_ = syscall.Close(fd)
		return observation, fmt.Errorf("failed to wrap openat descriptor")
	}
	data, readErr := io.ReadAll(file)
	fileInfo, statErr := file.Stat()
	closeErr := file.Close()
	if readErr != nil {
		return observation, readErr
	}
	if statErr != nil {
		return observation, statErr
	}
	if closeErr != nil {
		return observation, closeErr
	}
	currentRoot, err := root.Stat()
	if err != nil {
		return observation, err
	}
	initialRootStat := initial.Sys().(*syscall.Stat_t)
	currentRootStat := currentRoot.Sys().(*syscall.Stat_t)
	fileStat := fileInfo.Sys().(*syscall.Stat_t)
	expected := payload["config/app.conf"]

	observation.Bytes = string(data)
	observation.Mode = uint32(fileInfo.Mode().Perm())
	observation.RootInitialDev = uint64(initialRootStat.Dev)
	observation.RootInitialIno = initialRootStat.Ino
	observation.RootCurrentDev = uint64(currentRootStat.Dev)
	observation.RootCurrentIno = currentRootStat.Ino
	observation.FileDev = uint64(fileStat.Dev)
	observation.FileIno = fileStat.Ino
	observation.Pass = observation.Bytes == string(expected.Data) &&
		observation.Mode == uint32(os.FileMode(expected.Mode).Perm()) &&
		observation.RootInitialDev == observation.RootCurrentDev &&
		observation.RootInitialIno == observation.RootCurrentIno
	if !observation.Pass {
		return observation, fmt.Errorf("directory descriptor oracle failed at %s", state)
	}
	return observation, nil
}

func encode(output *json.Encoder, value any) error {
	return output.Encode(value)
}

func run(observationsPath, root, inventoryDir string) error {
	file, err := os.OpenFile(observationsPath,
		os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	defer file.Close()
	output := json.NewEncoder(file)

	if err := os.Mkdir(root, 0755); err != nil {
		return err
	}
	if err := os.MkdirAll(inventoryDir, 0755); err != nil {
		return err
	}
	writer, err := volumeutil.NewAtomicWriter(root, "namei-ext-rq1")
	if err != nil {
		return err
	}

	if err := writer.Write(v0, nil); err != nil {
		return err
	}
	initial, err := captureState(root, "initial",
		filepath.Join(inventoryDir, "source-tree-initial.tsv"), v0)
	if err != nil {
		return err
	}
	if err := encode(output, initial); err != nil {
		return err
	}
	rootDir, err := os.Open(root)
	if err != nil {
		return err
	}
	defer rootDir.Close()
	rootInfo, err := rootDir.Stat()
	if err != nil {
		return err
	}
	initialDirFD, err := directoryDescriptorState(rootDir, rootInfo, "initial", v0)
	if err != nil {
		return err
	}
	if err := encode(output, initialDirFD); err != nil {
		return err
	}
	oldFile, err := os.Open(filepath.Join(root, "config/app.conf"))
	if err != nil {
		return err
	}
	defer oldFile.Close()
	oldInfo, err := oldFile.Stat()
	if err != nil {
		return err
	}

	if err := writer.Write(v1, nil); err != nil {
		return err
	}
	update, err := captureState(root, "update",
		filepath.Join(inventoryDir, "source-tree-update.tsv"), v1)
	if err != nil {
		return err
	}
	if err := encode(output, update); err != nil {
		return err
	}
	updateDirFD, err := directoryDescriptorState(rootDir, rootInfo, "update", v1)
	if err != nil {
		return err
	}
	if err := encode(output, updateDirFD); err != nil {
		return err
	}
	oldAfterUpdate, err := descriptorState(oldFile, oldInfo, "after-update")
	if err != nil {
		return err
	}
	if err := encode(output, oldAfterUpdate); err != nil {
		return err
	}

	beforeNoOp, err := os.Stat(filepath.Join(root, "config/app.conf"))
	if err != nil {
		return err
	}
	dataBefore, err := os.Readlink(filepath.Join(root, "..data"))
	if err != nil {
		return err
	}
	if err := writer.Write(v1, nil); err != nil {
		return err
	}
	noOp, err := captureState(root, "no-op",
		filepath.Join(inventoryDir, "source-tree-no-op.tsv"), v1)
	if err != nil {
		return err
	}
	if err := encode(output, noOp); err != nil {
		return err
	}
	noOpDirFD, err := directoryDescriptorState(rootDir, rootInfo, "no-op", v1)
	if err != nil {
		return err
	}
	if err := encode(output, noOpDirFD); err != nil {
		return err
	}
	afterNoOp, err := os.Stat(filepath.Join(root, "config/app.conf"))
	if err != nil {
		return err
	}
	beforeStat := beforeNoOp.Sys().(*syscall.Stat_t)
	afterStat := afterNoOp.Sys().(*syscall.Stat_t)
	noOpIdentity := noOpObservation{
		Event:      "kubernetes-atomicwriter-no-op",
		Mechanism:  "kubernetes-atomicwriter",
		DataBefore: dataBefore,
		DataAfter:  noOp.DataTarget,
		DevBefore:  uint64(beforeStat.Dev),
		InoBefore:  beforeStat.Ino,
		DevAfter:   uint64(afterStat.Dev),
		InoAfter:   afterStat.Ino,
	}
	noOpIdentity.Pass = noOpIdentity.DataBefore == noOpIdentity.DataAfter &&
		noOpIdentity.DevBefore == noOpIdentity.DevAfter &&
		noOpIdentity.InoBefore == noOpIdentity.InoAfter
	if !noOpIdentity.Pass {
		return fmt.Errorf("no-op publication changed payload identity")
	}
	if err := encode(output, noOpIdentity); err != nil {
		return err
	}

	if err := writer.Write(v0, nil); err != nil {
		return err
	}
	rollback, err := captureState(root, "rollback",
		filepath.Join(inventoryDir, "source-tree-rollback.tsv"), v0)
	if err != nil {
		return err
	}
	if err := encode(output, rollback); err != nil {
		return err
	}
	rollbackDirFD, err := directoryDescriptorState(rootDir, rootInfo, "rollback", v0)
	if err != nil {
		return err
	}
	if err := encode(output, rollbackDirFD); err != nil {
		return err
	}
	oldAfterRollback, err := descriptorState(oldFile, oldInfo, "after-rollback")
	if err != nil {
		return err
	}
	if err := encode(output, oldAfterRollback); err != nil {
		return err
	}
	rollbackInfo, err := os.Stat(filepath.Join(root, "config/app.conf"))
	if err != nil {
		return err
	}
	rollbackStat := rollbackInfo.Sys().(*syscall.Stat_t)
	if uint64(rollbackStat.Dev) == oldAfterRollback.InitialDev &&
		rollbackStat.Ino == oldAfterRollback.InitialIno {
		return fmt.Errorf("rollback reused the still-open original V0 inode")
	}

	return encode(output, summaryObservation{
		Event:     "kubernetes-atomicwriter-summary",
		Mechanism: "kubernetes-atomicwriter",
		States:    4,
		Pass:      true,
	})
}

func main() {
	if len(os.Args) != 4 {
		fmt.Fprintf(os.Stderr,
			"usage: %s OBSERVATIONS_JSONL ROOT INVENTORY_DIR\n",
			os.Args[0])
		os.Exit(2)
	}
	if err := run(os.Args[1], os.Args[2], os.Args[3]); err != nil {
		file, openErr := os.OpenFile(os.Args[1],
			os.O_CREATE|os.O_APPEND|os.O_WRONLY, 0644)
		if openErr == nil {
			_ = json.NewEncoder(file).Encode(summaryObservation{
				Event:     "kubernetes-atomicwriter-summary",
				Mechanism: "kubernetes-atomicwriter",
				Pass:      false,
				Error:     err.Error(),
			})
			_ = file.Close()
		}
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
