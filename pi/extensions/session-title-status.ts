/**
 * Provide an LLM-callable tool for naming Pi sessions.
 *
 * Pi's built-in footer already renders the current session name next to the
 * repository and branch, so this extension deliberately adds no duplicate
 * footer status entry.
 */

import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Type } from "typebox";
export default function (pi: ExtensionAPI) {
	pi.registerTool({
		name: "set_session_title",
		label: "Set Session Title",
		description:
			"Set a concise display title for the current Pi session. Use once at the start of an unnamed session.",
		parameters: Type.Object({
			title: Type.String({
				description: "A concise, descriptive 2–5 word session title",
				minLength: 3,
				maxLength: 60,
			}),
		}),
		async execute(_toolCallId, { title }) {
			const existingTitle = pi.getSessionName();
			if (existingTitle) {
				return {
					content: [{ type: "text", text: `Session title is already set to: ${existingTitle}` }],
					details: { title: existingTitle, changed: false },
				};
			}

			const normalizedTitle = title.trim();
			pi.setSessionName(normalizedTitle);
			return {
				content: [{ type: "text", text: `Session title set to: ${normalizedTitle}` }],
				details: { title: normalizedTitle, changed: true },
			};
		},
	});

}
