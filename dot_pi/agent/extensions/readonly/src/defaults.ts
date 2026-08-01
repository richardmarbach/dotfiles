/**
 * Built-in default whitelist for read-only mode.
 *
 * Replaced wholesale by `readOnly.whitelist` in settings.json when present.
 */

export const DEFAULT_WHITELIST: readonly string[] = [
	"read",
	"grep",
	"glob",
	"web_search",
	"code_search",
	"fetch_content",
	"get_search_content",
	"coms_list",
	"coms_get",
	"coms_send",
	"coms_end",
];
