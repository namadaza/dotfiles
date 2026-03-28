#!/usr/bin/env bun
/**
 * Linear GraphQL API helper for the linear-spec skill.
 *
 * Usage:
 *   bun linear.ts search <title>
 *   bun linear.ts get-by-identifier <identifier>
 *   bun linear.ts get <issue-id>
 *   bun linear.ts update <issue-id> <description>
 *   bun linear.ts comment <issue-id> <body>
 *   bun linear.ts list-todo
 *   bun linear.ts transition <issue-id> <state-type>
 *   bun linear.ts list-states <issue-id>
 *
 * Requires LINEAR_API_KEY in the environment.
 */

const API_URL = "https://api.linear.app/graphql";

const apiKey = process.env.LINEAR_API_KEY;
if (!apiKey) {
  console.error("LINEAR_API_KEY is not set in the environment.");
  process.exit(1);
}

async function linearRequest(
  query: string,
  variables: Record<string, unknown>,
) {
  const res = await fetch(API_URL, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: apiKey!,
    },
    body: JSON.stringify({ query, variables }),
  });

  if (!res.ok) {
    const text = await res.text();
    console.error(`Linear API error (${res.status}): ${text}`);
    process.exit(1);
  }

  const json = (await res.json()) as {
    data?: Record<string, unknown>;
    errors?: Array<{ message: string }>;
  };

  if (json.errors) {
    console.error("GraphQL errors:", JSON.stringify(json.errors, null, 2));
    process.exit(1);
  }

  return json.data;
}

// --- Queries ---

const SEARCH_QUERY = `
query($term: String!) {
  searchIssues(query: $term, filter: { labels: { name: { eq: "night-shift" } } }, first: 5) {
    nodes {
      id
      identifier
      title
      url
      state { name }
      description
    }
  }
}`;

const GET_QUERY = `
query($id: String!) {
  issue(id: $id) {
    id
    identifier
    title
    description
    url
    state { id name type }
    team { id }
    labels { nodes { name } }
    parent { identifier, title, description }
    children { nodes { identifier, title, description, state { name } } }
  }
}`;

const GET_BY_IDENTIFIER_QUERY = `
query($number: Float!, $teamKey: String!) {
  issues(filter: { number: { eq: $number }, team: { key: { eq: $teamKey } } }, first: 1) {
    nodes {
      id
      identifier
      title
      description
      url
      state { id name type }
      team { id }
      labels { nodes { name } }
      parent { identifier, title, description }
      children { nodes { identifier, title, description, state { name } } }
    }
  }
}`;

// --- Mutations ---

const UPDATE_MUTATION = `
mutation($id: String!, $description: String!) {
  issueUpdate(id: $id, input: { description: $description }) {
    success
    issue { id, identifier }
  }
}`;

const COMMENT_MUTATION = `
mutation($issueId: String!, $body: String!) {
  commentCreate(input: { issueId: $issueId, body: $body }) {
    comment { id }
  }
}`;

const LIST_TODO_QUERY = `
query {
  issues(
    filter: {
      labels: { name: { eq: "night-shift" } }
      state: { type: { in: ["unstarted", "backlog"] } }
    }
    first: 20
    orderBy: createdAt
  ) {
    nodes {
      id
      identifier
      title
      url
      priority
      state { id name type }
      team { id }
      description
    }
  }
}`;

const WORKFLOW_STATES_QUERY = `
query($teamId: String!) {
  workflowStates(filter: { team: { id: { eq: $teamId } } }) {
    nodes { id name type }
  }
}`;

const TRANSITION_MUTATION = `
mutation($id: String!, $stateId: String!) {
  issueUpdate(id: $id, input: { stateId: $stateId }) {
    success
    issue { id identifier state { name } }
  }
}`;

// --- Formatters ---

interface Issue {
  id: string;
  identifier: string;
  title: string;
  url: string;
  description?: string;
  priority?: number;
  state?: { id: string; name: string; type: string };
  team?: { id: string };
  labels?: { nodes: Array<{ name: string }> };
  parent?: { identifier: string; title: string; description?: string };
  children?: {
    nodes: Array<{
      identifier: string;
      title: string;
      description?: string;
      state?: { name: string };
    }>;
  };
}

function formatIssueRow(issue: Issue) {
  return `${issue.id} | ${issue.identifier} | ${issue.title} | ${issue.url}`;
}

function formatIssueFull(issue: Issue) {
  const lines: string[] = [];
  lines.push(`# ${issue.identifier}: ${issue.title}`);
  lines.push("");
  lines.push(`**ID:** ${issue.id}`);
  lines.push(`**URL:** ${issue.url}`);
  if (issue.state) lines.push(`**State:** ${issue.state.name}`);
  if (issue.labels?.nodes.length) {
    lines.push(
      `**Labels:** ${issue.labels.nodes.map((l) => l.name).join(", ")}`,
    );
  }
  lines.push("");

  if (issue.description) {
    lines.push("## Description");
    lines.push("");
    lines.push(issue.description);
    lines.push("");
  }

  if (issue.parent) {
    lines.push("## Parent Issue");
    lines.push("");
    lines.push(`**${issue.parent.identifier}:** ${issue.parent.title}`);
    if (issue.parent.description) {
      lines.push("");
      lines.push(issue.parent.description);
    }
    lines.push("");
  }

  if (issue.children?.nodes.length) {
    lines.push("## Sub-Issues");
    lines.push("");
    for (const child of issue.children.nodes) {
      const state = child.state ? ` [${child.state.name}]` : "";
      lines.push(`- **${child.identifier}:** ${child.title}${state}`);
      if (child.description) {
        lines.push(`  ${child.description.split("\n")[0]}`);
      }
    }
    lines.push("");
  }

  return lines.join("\n");
}

// --- Commands ---

const [command, ...args] = process.argv.slice(2);

if (!command) {
  console.error("Usage: bun linear.ts <command> [args]");
  console.error(
    "Commands: search, get-by-identifier, get, update, comment, list-todo, transition, list-states",
  );
  process.exit(1);
}

switch (command) {
  case "search": {
    const term = args.join(" ");
    if (!term) {
      console.error("Usage: bun linear.ts search <title>");
      process.exit(1);
    }
    const data = (await linearRequest(SEARCH_QUERY, { term })) as {
      searchIssues: { nodes: Issue[] };
    };
    const issues = data.searchIssues.nodes;
    if (issues.length === 0) {
      console.log("No matching issues found.");
    } else {
      for (const issue of issues) {
        console.log(formatIssueRow(issue));
      }
    }
    break;
  }

  case "get-by-identifier": {
    const identifier = args[0];
    if (!identifier) {
      console.error("Usage: bun linear.ts get-by-identifier <identifier>");
      process.exit(1);
    }
    const match = identifier.match(/^([A-Z]+)-(\d+)$/);
    if (!match) {
      console.error(
        `Invalid identifier format: ${identifier} (expected e.g. ENG-123)`,
      );
      process.exit(1);
    }
    const [, teamKey, numberStr] = match;
    const data = (await linearRequest(GET_BY_IDENTIFIER_QUERY, {
      teamKey,
      number: parseInt(numberStr, 10),
    })) as {
      issues: { nodes: Issue[] };
    };
    const issues = data.issues.nodes;
    if (issues.length === 0) {
      console.error(`No issue found with identifier: ${identifier}`);
      process.exit(1);
    }
    console.log(formatIssueFull(issues[0]));
    break;
  }

  case "get": {
    const id = args[0];
    if (!id) {
      console.error("Usage: bun linear.ts get <issue-id>");
      process.exit(1);
    }
    const data = (await linearRequest(GET_QUERY, { id })) as { issue: Issue };
    if (!data.issue) {
      console.error(`No issue found with id: ${id}`);
      process.exit(1);
    }
    console.log(formatIssueFull(data.issue));
    break;
  }

  case "update": {
    const id = args[0];
    const description = args.slice(1).join(" ");
    if (!id || !description) {
      console.error("Usage: bun linear.ts update <issue-id> <description>");
      process.exit(1);
    }
    const data = (await linearRequest(UPDATE_MUTATION, {
      id,
      description,
    })) as {
      issueUpdate: {
        success: boolean;
        issue: { id: string; identifier: string };
      };
    };
    if (data.issueUpdate.success) {
      console.log(`Updated ${data.issueUpdate.issue.identifier}`);
    } else {
      console.error("Update failed.");
      process.exit(1);
    }
    break;
  }

  case "comment": {
    const issueId = args[0];
    const body = args.slice(1).join(" ");
    if (!issueId || !body) {
      console.error("Usage: bun linear.ts comment <issue-id> <body>");
      process.exit(1);
    }
    const data = (await linearRequest(COMMENT_MUTATION, { issueId, body })) as {
      commentCreate: { comment: { id: string } };
    };
    console.log(`Comment created: ${data.commentCreate.comment.id}`);
    break;
  }

  case "list-todo": {
    const data = (await linearRequest(LIST_TODO_QUERY, {})) as {
      issues: { nodes: Issue[] };
    };
    const issues = data.issues.nodes;
    if (issues.length === 0) {
      console.log("No night-shift todo issues found.");
    } else {
      for (const issue of issues) {
        const state = issue.state ? issue.state.name : "unknown";
        console.log(
          `${issue.id} | ${issue.identifier} | ${issue.title} | ${issue.url} | ${state}`,
        );
      }
    }
    break;
  }

  case "transition": {
    const issueId = args[0];
    const stateType = args[1];
    if (!issueId || !stateType) {
      console.error("Usage: bun linear.ts transition <issue-id> <state-type>");
      console.error("state-type: started, canceled");
      process.exit(1);
    }
    // Fetch issue to get team ID
    const issueData = (await linearRequest(GET_QUERY, { id: issueId })) as {
      issue: Issue;
    };
    if (!issueData.issue) {
      console.error(`No issue found with id: ${issueId}`);
      process.exit(1);
    }
    const teamId = issueData.issue.team?.id;
    if (!teamId) {
      console.error("Issue has no team assigned.");
      process.exit(1);
    }
    // Fetch workflow states for the team
    const statesData = (await linearRequest(WORKFLOW_STATES_QUERY, {
      teamId,
    })) as {
      workflowStates: {
        nodes: Array<{ id: string; name: string; type: string }>;
      };
    };
    const targetState = statesData.workflowStates.nodes.find(
      (s) => s.type === stateType,
    );
    if (!targetState) {
      console.error(
        `No workflow state with type "${stateType}" found for this team.`,
      );
      console.error(
        "Available states:",
        statesData.workflowStates.nodes
          .map((s) => `${s.name} (${s.type})`)
          .join(", "),
      );
      process.exit(1);
    }
    // Transition the issue
    const transitionData = (await linearRequest(TRANSITION_MUTATION, {
      id: issueId,
      stateId: targetState.id,
    })) as {
      issueUpdate: {
        success: boolean;
        issue: { id: string; identifier: string; state: { name: string } };
      };
    };
    if (transitionData.issueUpdate.success) {
      console.log(
        `Transitioned ${transitionData.issueUpdate.issue.identifier} to ${transitionData.issueUpdate.issue.state.name}`,
      );
    } else {
      console.error("Transition failed.");
      process.exit(1);
    }
    break;
  }

  case "list-states": {
    const issueId = args[0];
    if (!issueId) {
      console.error("Usage: bun linear.ts list-states <issue-id>");
      process.exit(1);
    }
    const issueData = (await linearRequest(GET_QUERY, { id: issueId })) as {
      issue: Issue;
    };
    if (!issueData.issue) {
      console.error(`No issue found with id: ${issueId}`);
      process.exit(1);
    }
    const teamId = issueData.issue.team?.id;
    if (!teamId) {
      console.error("Issue has no team assigned.");
      process.exit(1);
    }
    const statesData = (await linearRequest(WORKFLOW_STATES_QUERY, {
      teamId,
    })) as {
      workflowStates: {
        nodes: Array<{ id: string; name: string; type: string }>;
      };
    };
    for (const state of statesData.workflowStates.nodes) {
      console.log(`${state.id} | ${state.name} | ${state.type}`);
    }
    break;
  }

  default:
    console.error(`Unknown command: ${command}`);
    console.error(
      "Commands: search, get-by-identifier, get, update, comment, list-todo, transition, list-states",
    );
    process.exit(1);
}
