#!/usr/bin/env node
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const pluginRoot = path.resolve(path.dirname(__filename), "..");
const repoRoot = path.resolve(pluginRoot, "..", "..");

const errors = [];

function readText(relativePath) {
  const absolutePath = path.join(pluginRoot, relativePath);
  try {
    return fs.readFileSync(absolutePath, "utf8");
  } catch (error) {
    errors.push(`missing or unreadable ${relativePath}: ${error.message}`);
    return "";
  }
}

function readJson(relativePath) {
  const text = readText(relativePath);
  if (!text) return null;
  try {
    return JSON.parse(text);
  } catch (error) {
    errors.push(`${relativePath} is not valid JSON: ${error.message}`);
    return null;
  }
}

function requireString(value, label) {
  if (typeof value !== "string" || value.trim() === "") {
    errors.push(`${label} must be a non-empty string`);
  }
}

function assert(condition, message) {
  if (!condition) errors.push(message);
}

const manifest = readJson(".codex-plugin/plugin.json");
if (manifest) {
  assert(manifest.name === "mijia-control-codex", "plugin name must be mijia-control-codex");
  assert(/^\d+\.\d+\.\d+/.test(manifest.version), "plugin version must look like semver");
  requireString(manifest.description, "description");
  requireString(manifest.author?.name, "author.name");
  assert(manifest.skills === "./skills/", "skills must point to ./skills/");
  assert(manifest.mcpServers === "./.mcp.json", "mcpServers must point to ./.mcp.json");
  requireString(manifest.interface?.displayName, "interface.displayName");
  requireString(manifest.interface?.shortDescription, "interface.shortDescription");
  requireString(manifest.interface?.longDescription, "interface.longDescription");
  requireString(manifest.interface?.developerName, "interface.developerName");
  requireString(manifest.interface?.category, "interface.category");
  assert(Array.isArray(manifest.interface?.capabilities), "interface.capabilities must be an array");
  assert(Array.isArray(manifest.interface?.defaultPrompt), "interface.defaultPrompt must be an array");
}

const mcp = readJson(".mcp.json");
if (mcp) {
  const server = mcp.mcpServers?.["mijia-control"];
  assert(server && typeof server === "object", ".mcp.json must declare mcpServers.mijia-control");
  assert(server?.type === "stdio", "mijia-control MCP server must use stdio");
  assert(server?.command === "python", "mijia-control MCP server command must be python");
  assert(Array.isArray(server?.args), "mijia-control MCP server args must be an array");
  assert(server?.args?.join(" ") === "-m mcp_server", "mijia-control MCP server must run -m mcp_server");
  assert(server?.env?.MCP_TRANSPORT === "stdio", "MCP_TRANSPORT must be stdio");
  assert(Array.isArray(server?.env_vars), "mijia-control MCP server must declare env_vars");
  assert(server?.env_vars?.includes("MIJIA_API_URL"), "MIJIA_API_URL must be forwarded with env_vars");
  assert(server?.env_vars?.includes("MIJIA_TOKEN"), "MIJIA_TOKEN must be forwarded with env_vars");
}

const skill = readText("skills/mijia-control/SKILL.md");
if (skill) {
  assert(/^---\r?\n/.test(skill), "Skill must start with YAML frontmatter");
  assert(skill.includes("name: mijia-control"), "Skill frontmatter must name mijia-control");
  assert(skill.includes("description:"), "Skill frontmatter must include description");
  assert(skill.includes("must use `mijia-control` as the only device-facing interface"), "Skill must include only-through-mijia-control rule");
  assert(skill.includes("Do not call Xiaomi Cloud"), "Skill must block bypasses");
}

const envTemplate = readText("config/mijia-control.env.example");
if (envTemplate) {
  assert(envTemplate.includes("MIJIA_API_URL=http://127.0.0.1:5000/api"), "env template must include MIJIA_API_URL");
  assert(envTemplate.includes("MIJIA_TOKEN=replace-with-local-jwt-access-token"), "env template must use a token placeholder");
}

const marketplacePath = path.join(repoRoot, ".agents", "plugins", "marketplace.json");
if (fs.existsSync(marketplacePath)) {
  try {
    const marketplace = JSON.parse(fs.readFileSync(marketplacePath, "utf8"));
    const entry = marketplace.plugins?.find((plugin) => plugin.name === "mijia-control-codex");
    assert(Boolean(entry), "marketplace must include mijia-control-codex");
    assert(entry?.source?.path === "./plugins/mijia-control-codex", "marketplace path must point to ./plugins/mijia-control-codex");
    assert(entry?.policy?.installation === "AVAILABLE", "marketplace installation policy must be AVAILABLE");
    assert(entry?.policy?.authentication === "ON_INSTALL", "marketplace auth policy must be ON_INSTALL");
  } catch (error) {
    errors.push(`marketplace JSON is invalid: ${error.message}`);
  }
}

const forbiddenPatterns = [
  { pattern: /eyJ[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{20,}\.[A-Za-z0-9_-]{10,}/, label: "JWT token" },
  { pattern: /password\s*=\s*(?!your-|replace-|<)/i, label: "possible password assignment" },
  { pattern: /refresh_token\s*[:=]\s*["'][A-Za-z0-9._-]{12,}["']/i, label: "refresh token" },
  { pattern: /bindkey\s*[:=]\s*["']?[A-Fa-f0-9]{16,}/, label: "BLE bindkey" },
  { pattern: /\bblt\.\d+\.[A-Za-z0-9_-]{5,}\b/, label: "real-looking BLE DID" },
  { pattern: /\b[A-Fa-f0-9]{2}(:[A-Fa-f0-9]{2}){5}\b/, label: "MAC address" }
];

function scanDirectory(directory) {
  for (const entry of fs.readdirSync(directory, { withFileTypes: true })) {
    if (entry.name === ".git" || entry.name === "node_modules") continue;
    const absolutePath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      scanDirectory(absolutePath);
      continue;
    }
    const relativePath = path.relative(pluginRoot, absolutePath).replaceAll(path.sep, "/");
    const text = fs.readFileSync(absolutePath, "utf8");
    for (const { pattern, label } of forbiddenPatterns) {
      if (pattern.test(text)) {
        errors.push(`${relativePath} contains ${label}`);
      }
    }
  }
}

scanDirectory(pluginRoot);

if (errors.length > 0) {
  console.error("verify-plugin: failed");
  for (const error of errors) {
    console.error(`- ${error}`);
  }
  process.exit(1);
}

console.log("verify-plugin: ok");
