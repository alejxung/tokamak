#include <cstring>
#include <iostream>
#include <sched.h>	  // unshare
#include <seccomp.h>  // libseccomp
#include <sys/stat.h> // umask
#include <sys/wait.h> // waitpid
#include <unistd.h>	  // fork, execvp, chroot
#include <vector>

// CONSTANTS
const char *VACUUM_PATH = "./vacuum_root";

void enter_vacuum() {
	// The Air Gap (Network Isolation)
	// Create a new empty network namespace.
	// The process will see NO network interfaces.
	if (unshare(CLONE_NEWNET) != 0) {
		perror("[ERROR] Failed to isolate network (unshare)");
		exit(1);
	}

	// Seal the Vacuum (chroot)
	// We lock the process inside the vacuum_root folder.
	if (chroot(VACUUM_PATH) != 0) {
		perror("[ERROR] Failed to seal Vacuum (chroot)");
		exit(1);
	}

	// Re-orient (chdir)
	// Move to the new root "/"
	if (chdir("/") != 0) {
		perror("[ERROR] Failed to stabilize inside Vacuum (chdir)");
		exit(1);
	}
}

void engage_shield() {
	// Initialize the filter: ALLOW all syscalls by default.
	// We strictly blacklist dangerous calls to maintain stability.
	scmp_filter_ctx ctx = seccomp_init(SCMP_ACT_ALLOW);
	if (ctx == NULL) {
		perror("[ERROR] Failed to init seccomp");
		exit(1);
	}

	// Prevent socket creation to block network access.
	// Returns EPERM (Permission Denied) so applications handle it gracefully.
	if (seccomp_rule_add(ctx, SCMP_ACT_ERRNO(EPERM), SCMP_SYS(socket), 0) < 0) {
		perror("[ERROR] Failed to add socket rule");
		exit(1);
	}

	// Note: clone/fork rules are intentionally omitted here to support
	// QEMU emulation on Apple Silicon (which uses clone for threading).
	// In a native Linux environment, these should be blocked to prevent fork
	// bombs.

	// Load the filter into the kernel.
	std::cout << "[Plasma] Engaging Seccomp Deflector Shields..." << std::endl;
	if (seccomp_load(ctx) < 0) {
		perror("[ERROR] Failed to load seccomp filter");
		exit(1);
	}

	seccomp_release(ctx);
}

int main(int argc, char *argv[]) {
	if (argc < 2) {
		std::cerr << "Usage: ./reactor <plasma_command> [args...]" << std::endl;
		std::cerr << "Example: sudo ./reactor /bin/ls -la" << std::endl;
		return 1;
	}

	std::cout << "[Reactor] Initializing containment field..." << std::endl;

	// Magnetic Separation (Fork)
	// We split the Reactor (Parent) from the Plasma (Child).
	pid_t pid = fork();

	if (pid == -1) {
		perror("[Reactor] Field collapse (Fork failed)");
		return 1;
	}

	if (pid == 0) {
		// ================= PLASMA (Inside the Vacuum) =================

		enter_vacuum();
		engage_shield();

		std::cout << "[Plasma] Injected into Vacuum. PID: " << getpid()
				  << std::endl;

		// Prepare arguments for execution
		std::vector<char *> args;
		for (int i = 1; i < argc; ++i) {
			args.push_back(argv[i]);
		}
		args.push_back(nullptr);

		// Ignition (Exec)
		// Run the command inside the vacuum.
		execvp(args[0], args.data());

		// If we get here, ignition failed.
		perror("[Plasma] Ignition failed (execvp)");
		exit(1);
	} else {
		// ================= REACTOR (Control Room) =================
		std::cout << "[Reactor] Plasma active. Monitoring PID: " << pid
				  << std::endl;

		int status;
		waitpid(pid, &status, 0);

		if (WIFEXITED(status)) {
			std::cout
				<< "[Reactor] Containment stable. Plasma dissipated with code: "
				<< WEXITSTATUS(status) << std::endl;
		} else if (WIFSIGNALED(status)) {
			std::cout << "[Reactor] ALERT: Plasma BREACH caused by signal: "
					  << WTERMSIG(status) << std::endl;
		}
	}

	return 0;
}