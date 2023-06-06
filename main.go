package main

import (
	"bufio"
	"fmt"
	"log"
	"os"
	"os/exec"
	"runtime"
)

func main() {
	// Determine the operating system
	osName := runtime.GOOS

	// Define the installation process based on the operating system
	switch osName {
	case "darwin":
		installOnMacOS("your-software-name")
	case "linux":
		installOnLinux([]string{
			"wget",
			"curl",
			"git",
			"unzip",
			"zip",
			"vim",
		})
	case "windows":
		// Install Chocolatey if not already installed
		if !isChocolateyInstalled() {
			installChocolatey()
		}
		// refer to windows/choco.ps1 for the list of software to install
		installOnWindows()
	default:
		log.Fatal("Unsupported operating system:", osName)
	}
}

func installOnMacOS(softwareName string) {
	// Install software on macOS using Homebrew
	installCommand := exec.Command("brew", "install", softwareName)
	runCommand(installCommand)
}

func installOnLinux(commands []string) {

	// Update the package list
	updateCommand := exec.Command("apt", "update", "-y")
	runCommand(updateCommand)

	// upgrade the packages
	upgradeCommand := exec.Command("apt", "upgrade", "-y")
	runCommand(upgradeCommand)

	// Install software on Linux using APT package manager
	installCommand := exec.Command("apt", "install", "-y")
	installCommand.Args = append(installCommand.Args, commands...)
	runCommand(installCommand)
}

func installOnWindows() {

	// install software on Windows using powershell
	scriptPath := "windows/choco.ps1"
	installCommand := exec.Command("powershell", "-Command", scriptPath)
	runCommand(installCommand)
}

func installChocolatey() {
	// Install Chocolatey on Windows with Administrator privileges
	powershellCmd := exec.Command("powershell", "-Command", "Start-Process powershell -Verb RunAs -ArgumentList '-Command \"Set-ExecutionPolicy Bypass -Scope Process -Force; iex ((New-Object System.Net.WebClient).DownloadString(''https://chocolatey.org/install.ps1''))\"'")
	runCommand(powershellCmd)
}

func isChocolateyInstalled() bool {
	// Check if Chocolatey is installed on Windows
	_, err := exec.LookPath("choco")
	return err == nil
}

func runCommand(command *exec.Cmd) {
	// Set the correct output device according to the operating system
	if runtime.GOOS == "windows" {
		command.Stdout = os.Stdout
		command.Stderr = os.Stderr
	}
	// Run the command
	err := command.Run()
	if err != nil {
		log.Fatal(err)
	}

	// Create a pipe to capture the command's stdout
	stdoutPipe, err := command.StdoutPipe()
	if err != nil {
		log.Fatal(err)
	}

	// Start the command
	if err := command.Start(); err != nil {
		log.Fatal(err)
	}

	// Stream and capture the stdout
	scanner := bufio.NewScanner(stdoutPipe)
	for scanner.Scan() {
		fmt.Println(scanner.Text())
	}

	// Check for any error during streaming
	if err := scanner.Err(); err != nil {
		log.Fatal(err)
	}

	// Wait for the command to finish
	if err := command.Wait(); err != nil {
		log.Fatal(err)
	}
}
