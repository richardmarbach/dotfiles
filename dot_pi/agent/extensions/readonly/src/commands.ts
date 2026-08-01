/**
 * Argument parsing for the single `/readonly` command.
 *
 * Subcommands: (bare) on off allow <tool> deny <tool> list status reset.
 */

export type Subcommand =
	| { kind: "enable" }
	| { kind: "disable" }
	| { kind: "allow"; tool: string }
	| { kind: "deny"; tool: string }
	| { kind: "list" }
	| { kind: "status" }
	| { kind: "reset" }
	| { kind: "missing-target"; sub: "allow" | "deny" }
	| { kind: "unknown"; raw: string };

export function parseSubcommand(args: string): Subcommand {
	const tokens = args.trim().split(/\s+/).filter((t) => t.length > 0);
	if (tokens.length === 0) return { kind: "enable" };

	const head = tokens[0].toLowerCase();
	const rest = tokens.slice(1).join(" ").trim();

	switch (head) {
		case "on":
			return { kind: "enable" };
		case "off":
			return { kind: "disable" };
		case "allow":
			if (!rest) return { kind: "missing-target", sub: "allow" };
			return { kind: "allow", tool: rest };
		case "deny":
			if (!rest) return { kind: "missing-target", sub: "deny" };
			return { kind: "deny", tool: rest };
		case "list":
			return { kind: "list" };
		case "status":
			return { kind: "status" };
		case "reset":
			return { kind: "reset" };
		default:
			return { kind: "unknown", raw: tokens.join(" ") };
	}
}

export const SUBCOMMAND_NAMES = ["on", "off", "allow", "deny", "list", "status", "reset"] as const;
