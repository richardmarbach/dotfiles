export type SnippetPlacement = "prepend" | "append";
export type SnippetScope = "global" | "project";

export interface Snippet {
	id: string;
	name: string;
	description: string;
	placement: SnippetPlacement;
	order: number;
	body: string;
	scope: SnippetScope;
	path: string;
}

export interface SnippetDirectory {
	path: string;
	scope: SnippetScope;
}
