#!/usr/bin/env -S mise x bun@latest -- bun

// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Voice Note
// @raycast.mode fullOutput
// @raycast.packageName Voice Notes
// @raycast.icon 🎤
// @raycast.description Record a voice note, transcribe it, and save it with AI-generated title and tags

import { $ } from "bun";
import os from "node:os";
import path from "node:path";
import fs from "node:fs";

// Configuration
const ZK_NOTEBOOK_PATH =
  Bun.env.ZK_NOTEBOOK_PATH || path.join(os.homedir(), "notes");
const NOTES_DIR = ZK_NOTEBOOK_PATH;
const AUDIO_DIR = path.join(NOTES_DIR, "audio");
const RECORDING_FORMAT = "wav";
const SAMPLE_RATE = 16000;
const MODEL_PATH = "~/.local/share/whisper-cpp/ggml-large-v3-turbo.bin";

const LOG_LEVELS = {
  error: "❌",
  success: "✅",
  info: "ℹ️",
  progress: "🔄",
};

function show(
  level: "error" | "success" | "info" | "progress",
  message: string,
) {
  console.log(`${LOG_LEVELS[level]} ${message}`);
}

// Ensure directories exist
function ensureDirectories() {
  if (!fs.existsSync(NOTES_DIR)) {
    fs.mkdirSync(NOTES_DIR, { recursive: true });
    show("info", `Created notes directory: ${NOTES_DIR}`);
  }
  if (!fs.existsSync(AUDIO_DIR)) {
    fs.mkdirSync(AUDIO_DIR, { recursive: true });
    show("info", `Created audio directory: ${AUDIO_DIR}`);
  }
}

function generateFilename(extension = RECORDING_FORMAT) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  return `voice-note-${timestamp}.${extension}`;
}

type Dependency = {
  cmd: string;
  name: string;
  install: string;
};

async function checkDependencies() {
  const dependencies = [
    { cmd: "sox", name: "SoX (Sound eXchange)", install: "brew install sox" },
    {
      cmd: "whisper-cli",
      name: "Whisper Transcription",
      install: "brew install whisper-cpp",
    },
    {
      cmd: "zk",
      name: "Zettelkasten -- zk",
      install: "brew install zk",
    },
    {
      cmd: "ollama",
      name: "Ollama AI",
      install: "brew install ollama --cask",
    },
  ];

  const missing: Dependency[] = [];
  for (const dep of dependencies) {
    try {
      await $`which ${dep.cmd}`.quiet();
    } catch (error) {
      missing.push(dep);
    }
  }

  if (missing.length > 0) {
    show("error", "Missing dependencies:");
    missing.forEach((dep) => {
      console.log(`   • ${dep.name}: ${dep.install}`);
    });
    console.log("\nPlease install the missing dependencies and try again.");
    process.exit(1);
  }
}

async function recordAudio(filename: string, maxDuration = 300) {
  const audioPath = path.join(AUDIO_DIR, filename);

  console.log("🎤 Recording started...");
  console.log("💡 Speak clearly. Auto-stops after 10 minutes or on silence.");
  console.log("⏹️  Press Return in the popup or click Stop to end recording.");

  const controller = new AbortController();
  const { signal } = controller;

  const recCmd = [
    "rec",
    "--bits",
    "16",
    audioPath,
    "rate",
    SAMPLE_RATE.toString(),
    "silence",
    "1",
    "0.1",
    "0.1%",
    "1",
    "30.0", // Stop after continuous silence
    "0.1%",
  ];

  const recording = Bun.spawn(recCmd, {
    timeout: maxDuration * 1000,
    signal,
    killSignal: "SIGINT",
  });

  const osaScript = `
        set msg to "Recording… Press Return to stop.\\n\\nThe note will also stop on silence or after ${maxDuration}s."
        display dialog msg buttons {"Stop"} default button 1 with icon note giving up after ${maxDuration + 5}
      `;
  const dialog = Bun.spawn(["osascript", "-e", osaScript], {
    signal,
  });

  await Promise.any([recording.exited, dialog.exited]);
  console.log("\n⏹️  Recording stopped (dialog).");
  controller.abort();

  const file = Bun.file(audioPath);
  if (!file.exists()) {
    throw new Error("Recording file was not created");
  }

  // At least 1KB
  if (file.size < 1000) {
    show("error", "Recording file is too small. Please try again.");
    throw new Error("Recording file is too small.");
  }
  show("success", `Recording completed: ${audioPath}`);
  return audioPath;
}

async function transcribeAudio(audioPath: string) {
  show("progress", "Transcribing audio with Whisper...");

  const baseName = path.basename(audioPath, path.extname(audioPath));
  const outputFile = path.join(AUDIO_DIR, `${baseName}`);

  await $`whisper-cli "${audioPath}" --model ${MODEL_PATH} --output-txt --output-file "${outputFile}"`.quiet();

  const transcriptPath = `${outputFile}.txt`;

  const file = Bun.file(transcriptPath);

  if (!file.exists()) {
    throw new Error("Transcript file not found");
  }

  if (file.size > 0) {
    show("success", "Transcription completed");
    return file;
  }

  await Bun.file(transcriptPath).delete();
  throw new Error("No speech detected in recording");
}

async function getExistingTags() {
  try {
    const output =
      await $`zk tag list --delimiter=',' --footer='' --no-input --format=name`.text();
    return output.trim();
  } catch (error) {
    return "";
  }
}

async function runModel(prompt: string) {
  return await $`ollama run llama3.2:3b '${prompt.replace(/'/g, "'\\''")}' --format json`.json();
}

type Note = {
  title: string;
  body: string;
  tags: string[];
};

async function generateTitleAndTags(transcript: string): Promise<Note> {
  show("progress", "Generating title and tags with AI...");

  const prompt = `You are analyzing a voice note transcript for a Zettelkasten knowledge management system.

Transcript: "${transcript}"

Provide:
1. A concise, descriptive title (max 60 characters) that would work well as a Zettelkasten note
2. Relevant tags (3-6 tags) that connect this note to broader concepts
3. Clean up the transcript for clarity and readability. Use lists where appropriate, and remove any filler words or unnecessary phrases.

Respond in this exact JSON format:
{
  "title": "Your generated title here",
  "body": "Your cleaned up transcript here",
  "tags": ["tag1", "tag2", "tag3"],
}

Existing Zettelkasten tags: ${await getExistingTags()}`;

  type ExpectedResponse = {
    title?: string;
    body?: string | string[];
    tags?: string[];
  };
  const result: ExpectedResponse = await runModel(prompt);

  console.log("AI response:", result);

  let title = result.title || "Voice Note";
  if (title.length > 60) {
    title = title.substring(0, 57) + "...";
  }

  let body: string = "";
  if (Array.isArray(result.body)) {
    body = result.body.join("\n");
  }
  if (typeof result.body === "string") {
    body = result.body;
  }
  body = body.trim();

  if (body.length === 0) {
    body = transcript;
  }

  body = body.trim();
  if (body.startsWith("#")) {
    body = body.replace(/^.*\n/, "");
    body = body.trim();
  }

  let tags = Array.isArray(result.tags) ? result.tags : [];

  // Add standard tags
  tags.push("voice-note", "fleeting");

  // Clean tags
  tags = [
    ...new Set(
      tags
        .map((tag) =>
          tag
            .toLowerCase()
            .replace(/[^a-z0-9-]/g, "")
            .substring(0, 20),
        )
        .filter((tag) => tag.length > 0),
    ),
  ];

  // TODO: ask model to find connecting notes

  show("success", "AI analysis completed");
  return { title, body, tags };
}

async function saveNote(note: Note, filename: string) {
  show("progress", "Creating Zettelkasten note...");

  const content = new Response(`---
title: "${note.title}"
date: ${new Date().toISOString()}
tags: [${note.tags.map((tag) => `"${tag}"`).join(", ")}]
audioFile: ${filename}
---

${note.body}
`);

  const result =
    await $`zk new --print-path --interactive --template="generated.md" --title "${note.title.replace(/"/g, '\\"')}" < ${content}`
      .cwd(NOTES_DIR)
      .text();
  const notePath = result.replace(/^\s*output:\s*/i, "").trim();

  show("success", `Zettelkasten note created: ${path.basename(notePath)}`);
  return notePath;
}

async function main() {
  try {
    console.log("🎵 Voice Note Recorder");
    console.log("======================\n");

    checkDependencies();
    ensureDirectories();

    const audioFilename = generateFilename();
    const audioPath = await recordAudio(audioFilename);
    const transcriptFile = await transcribeAudio(audioPath);
    const transcript = await transcriptFile.text();

    console.log("\n📝 Transcript Preview:");
    console.log("─".repeat(50));
    console.log(
      transcript.substring(0, 200) + (transcript.length > 200 ? "..." : ""),
    );
    console.log("─".repeat(50));

    const note = await generateTitleAndTags(transcript);

    console.log(`\n📋 Title: ${note.title}`);
    console.log(`🏷️  Tags: ${note.tags.join(", ")}`);

    const notePath = await saveNote(note, audioFilename);

    console.log(`\n💾 Zettelkasten note: ${path.basename(notePath)}`);
    console.log(`🎵 Audio saved to: ${path.relative(NOTES_DIR, audioPath)}`);

    console.log("\n✨ Voice note processing completed successfully!");
    console.log("💡 Next steps:");
    console.log("   • Review the fleeting note and extract key insights");
    console.log("   • Create connections to existing notes with: zk link");
    console.log("   • Process into permanent notes when ready");

    const wordCount = transcript.split(/\s+/).length;
    console.log(`📊 Stats: ${wordCount} words`);
    await transcriptFile.delete();
  } catch (error) {
    show("error", `Processing failed: ${error.message}`);
    process.exit(1);
  }
}

if (import.meta.main) {
  main();
}
