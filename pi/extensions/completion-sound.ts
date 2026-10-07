import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

export default function (pi: ExtensionAPI) {
	// Wait until generation, tool calls, retries, and queued work have finished.
	pi.on("agent_settled", async (_event, ctx) => {
		if (!ctx.hasUI || process.platform !== "darwin") return;

		await pi.exec("/usr/bin/afplay", [
			"-v", "0.25",
			"/System/Library/Sounds/Blow.aiff",
		]);
	});
}
