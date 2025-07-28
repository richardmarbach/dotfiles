#!/usr/bin/env -S mise x node@latest -- node

// Required parameters:
// @raycast.schemaVersion 1
// @raycast.title Voice Note
// @raycast.mode fullOutput
// @raycast.packageName Voice Notes
// @raycast.icon 🎤
// @raycast.description Record a voice note, transcribe it, and save it with AI-generated title and tags

const { execSync, spawn } = require("child_process");
const fs = require("fs");
const path = require("path");
const os = require("os");

// Configuration
const ZK_NOTEBOOK_PATH =
  process.env.ZK_NOTEBOOK_PATH || path.join(os.homedir(), "notes");
const NOTES_DIR = ZK_NOTEBOOK_PATH;
const AUDIO_DIR = path.join(NOTES_DIR, "audio");
const RECORDING_FORMAT = "wav";
const SAMPLE_RATE = 16000;
const MODEL_PATH = "~/.local/share/whisper-cpp/ggml-large-v3-turbo.bin";

// Raycast-specific output functions
function showError(message) {
  console.log(`❌ ${message}`);
  process.exit(1);
}

function showSuccess(message) {
  console.log(`✅ ${message}`);
}

function showInfo(message) {
  console.log(`ℹ️  ${message}`);
}

function showProgress(message) {
  console.log(`🔄 ${message}`);
}

// Ensure directories exist
function ensureDirectories() {
  if (!fs.existsSync(NOTES_DIR)) {
    fs.mkdirSync(NOTES_DIR, { recursive: true });
    showInfo(`Created notes directory: ${NOTES_DIR}`);
  }
  if (!fs.existsSync(AUDIO_DIR)) {
    fs.mkdirSync(AUDIO_DIR, { recursive: true });
    showInfo(`Created audio directory: ${AUDIO_DIR}`);
  }
}

// Generate timestamp-based filename
function generateFilename(extension = RECORDING_FORMAT) {
  const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
  return `voice-note-${timestamp}.${extension}`;
}

// Check if required tools are available
function checkDependencies() {
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
  ];

  const missing = [];
  for (const dep of dependencies) {
    try {
      execSync(`which ${dep.cmd}`, { stdio: "ignore" });
    } catch (error) {
      missing.push(dep);
    }
  }

  if (missing.length > 0) {
    console.log("❌ Missing dependencies:");
    missing.forEach((dep) => {
      console.log(`   • ${dep.name}: ${dep.install}`);
    });
    console.log("\nPlease install the missing dependencies and try again.");
    process.exit(1);
  }
}

// Record audio using SoX with a timeout
function recordAudio(filename, maxDuration = 300) {
  return new Promise((resolve, reject) => {
    const audioPath = path.join(AUDIO_DIR, filename);

    console.log("🎤 Recording started...");
    console.log("💡 Speak clearly. Auto-stops after 10 minutes or on silence.");
    console.log(
      "⏹️  Press Return in the popup or click Stop to end recording.",
    );

    // Use SoX with silence detection to auto-stop
    const recArgs = [
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

    const recording = spawn("rec", recArgs);
    let stopped = false;

    // Auto-timeout after maxDuration
    const timeout = setTimeout(() => {
      console.log("\n⏰ Maximum recording time reached");
      recording.kill("SIGTERM");
    }, maxDuration * 1000);

    // SoX handles SIGINT (Ctrl-C) cleanly.
    process.on("SIGINT", () => {
      console.log("\n⏹️  Recording stopped manually");
      clearTimeout(timeout);
      recording.kill("SIGTERM");
    });

    // --- GUI modal for non-TTY environments (Raycast) ---
    // We show a blocking dialog in a child process. Pressing Return activates the default button.
    // The dialog will also auto-dismiss after maxDuration+5 seconds for safety.
    let dialog;
    try {
      const giveUp = Math.max(5, maxDuration + 5);
      const osaScript = `
        set msg to "Recording… Press Return to stop.\\n\\nThe note will also stop on silence or after ${maxDuration}s."
        display dialog msg buttons {"Stop"} default button 1 with icon note giving up after ${giveUp}
      `;
      dialog = spawn("osascript", ["-e", osaScript], {
        stdio: ["ignore", "ignore", "ignore"],
      });
      dialog.on("close", (_) => {
        // Exit status 0 => button clicked / Return pressed.
        // Non-zero (1) may indicate "gave up after" timeout or dialog dismissed.
        if (stopped) return;
        stopped = true;
        console.log("\n⏹️  Recording stopped (dialog).");
        clearTimeout(timeout);
        recording.kill("SIGINT");
      });
    } catch {
      // If osascript is unavailable (rare on macOS), we just rely on timeout/silence.
      showInfo("osascript not available; using silence/timeout to stop.");
    }

    recording.on("close", (_) => {
      clearTimeout(timeout);
      try {
        dialog && dialog.kill("SIGTERM");
      } catch {}
      setTimeout(() => {
        if (fs.existsSync(audioPath)) {
          const stats = fs.statSync(audioPath);
          // At least 1KB
          if (stats.size > 1000) {
            showSuccess(`Recording completed: ${audioPath}`);
            resolve(audioPath);
          } else {
            showError("Recording file is too small. Please try again.");
            reject(new Error("Recording too small"));
          }
        } else {
          showError("Recording file was not created");
          reject(new Error("No recording file"));
        }
      }, 500);
    });

    recording.on("error", (error) => {
      clearTimeout(timeout);
      try {
        dialog && dialog.kill("SIGTERM");
      } catch {}
      showError(`Recording error: ${error.message}`);
      reject(error);
    });

    // Show recording progress
    let dots = 0;
    const progressInterval = setInterval(() => {
      dots = (dots + 1) % 4;
      process.stdout.write(
        `\r🎤 Recording${"•".repeat(dots)}${" ".repeat(3 - dots)}`,
      );
    }, 500);

    recording.on("close", () => {
      clearInterval(progressInterval);
      process.stdout.write("\r");
    });
  });
}

// Transcribe audio using Whisper
async function transcribeAudio(audioPath) {
  showProgress("Transcribing audio with Whisper...");

  try {
    const baseName = path.basename(audioPath, path.extname(audioPath));
    const outputFile = path.join(AUDIO_DIR, `${baseName}`);
    execSync(
      `whisper-cli "${audioPath}" --model ${MODEL_PATH} --output-txt --output-file "${outputFile}"`,
      {
        encoding: "utf8",
        maxBuffer: 1024 * 1024 * 10,
        stdio: ["inherit", "pipe", "pipe"],
      },
    );

    const transcriptPath = `${outputFile}.txt`;

    if (fs.existsSync(transcriptPath)) {
      const transcript = fs.readFileSync(transcriptPath, "utf8").trim();
      if (transcript && transcript.length > 0) {
        showSuccess("Transcription completed");
        return transcript;
      } else {
        showError("No speech detected in recording");
        throw new Error("Empty transcript");
      }
    } else {
      showError("Transcript file not found");
      throw new Error("Transcript file not found");
    }
  } catch (error) {
    showError(`Transcription failed: ${error.message}`);
    throw error;
  }
}

// Generate title and tags using local LLM with Zettelkasten context
async function generateTitleAndTags(transcript) {
  try {
    // Check if Ollama is available
    try {
      execSync("which ollama", { stdio: "ignore" });
    } catch (error) {
      showInfo("Ollama not found, using simple analysis");
      return generateTitleAndTagsSimple(transcript);
    }

    showProgress("Generating title and tags with AI...");

    // Get existing notes context for better linking
    let existingNotes = "";
    try {
      const zkList = execSync(
        "zk list --sort created- --created-after 'last two weeks' --limit 20",
        {
          encoding: "utf8",
          cwd: NOTES_DIR,
          stdio: "pipe",
        },
      );
      existingNotes = zkList.trim();
    } catch (error) {
      // Continue without context if zk list fails
    }

    const prompt = `You are analyzing a voice note transcript for a Zettelkasten knowledge management system.

Transcript: "${transcript}"

${existingNotes ? `Recent notes in the system for context:\n${existingNotes}\n` : ""}

Provide:
1. A concise, descriptive title (max 60 characters) that would work well as a Zettelkasten note
2. Relevant tags (3-6 tags) that connect this note to broader concepts
3. Clean up the transcript for clarity and readability. Do not include the summarized title or tags in the body.
4. Suggest potential connections to other notes if you see conceptual overlap

Respond in this exact JSON format:
{
  "title": "Your generated title here",
  "body": "Your cleaned up transcript here",
  "tags": ["tag1", "tag2", "tag3"],
  "connections": ["concept1", "concept2"] 
}

Common Zettelkasten tag categories: concept, method, question, insight, meeting, project, idea, reference, fleeting, permanent, literature`;

    const response = execSync(
      `ollama run llama3.2:3b '${prompt.replace(/'/g, "'\\''")}' --format json`,
      {
        encoding: "utf8",
        maxBuffer: 1024 * 1024,
        timeout: 40000,
        cwd: NOTES_DIR,
      },
    );

    try {
      const result = JSON.parse(response.trim());

      let title = result.title || "Voice Note";
      if (title.length > 60) {
        title = title.substring(0, 57) + "...";
      }

      let body = result.body || transcript;

      body = body.trim();
      if (body.startsWith("#")) {
        body = body.replace(/^.*\n/, "");
        body = body.trim();
      }

      let tags = Array.isArray(result.tags) ? result.tags : [];
      let connections = Array.isArray(result.connections)
        ? result.connections
        : [];

      // Add standard tags
      tags.push("voice-note", "fleeting");
      const dateTag = new Date().toISOString().split("T")[0];
      tags.push(dateTag);

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

      showSuccess("AI analysis completed");
      return { title, body, tags, connections };
    } catch (parseError) {
      showInfo("AI response parsing failed, using simple analysis");
      return generateTitleAndTagsSimple(transcript);
    }
  } catch (error) {
    showInfo("AI processing failed, using simple analysis");
    return generateTitleAndTagsSimple(transcript);
  }
}

// Fallback function for simple heuristics
function generateTitleAndTagsSimple(transcript) {
  const sentences = transcript
    .split(/[.!?]+/)
    .filter((s) => s.trim().length > 0);

  let title = "";
  if (sentences.length > 0) {
    title = sentences[0].trim();
    if (title.length > 50) {
      title = title.substring(0, 47) + "...";
    }
  } else {
    const words = transcript.toLowerCase().split(/\s+/);
    title = words.slice(0, 8).join(" ");
  }

  title = title.replace(/^[^a-zA-Z0-9]+/, "").replace(/[^a-zA-Z0-9]+$/, "");
  if (!title) title = "Voice Note";

  const tagKeywords = {
    meeting: ["meeting", "discuss", "agenda", "attendees"],
    idea: ["idea", "thought", "concept", "brainstorm"],
    todo: ["todo", "task", "need to", "remember to", "don't forget"],
    reminder: ["remind", "reminder", "remember", "note to self"],
    project: ["project", "work on", "deadline", "milestone"],
    personal: ["personal", "family", "friend", "weekend"],
    urgent: ["urgent", "important", "asap", "immediately"],
    research: ["research", "look into", "investigate", "study"],
    question: ["question", "wonder", "why", "how", "what if"],
    insight: ["realize", "understand", "insight", "conclusion"],
  };

  const tags = [];
  const transcriptLower = transcript.toLowerCase();

  for (const [tag, keywords] of Object.entries(tagKeywords)) {
    if (keywords.some((keyword) => transcriptLower.includes(keyword))) {
      tags.push(tag);
    }
  }

  // Add Zettelkasten standard tags
  tags.push("voice-note", "fleeting");
  const dateTag = new Date().toISOString().split("T")[0];
  tags.push(dateTag);

  return { title, body: transcript, tags: [...new Set(tags)], connections: [] };
}

// Save note using zk new command
function saveNote(title, transcript, tags, connections, audioFilename) {
  showProgress("Creating Zettelkasten note...");

  let connectionContent = "";
  if (connections && connections.length > 0) {
    connectionContent = `
---

${connections.length > 0 ? `${connections.join("\n")}` : ""}
`;
  }

  // Create the note content in Zettelkasten format
  const noteContent = `${tags.length > 0 ? `${tags.map((tag) => `#${tag}`).join("\n")}` : ""}

${transcript}

${connectionContent}
---

*Captured via voice recording on ${new Date().toLocaleString()}*  
*Audio file: ${audioFilename}*
`;

  try {
    // Use zk new to create the note with proper ID and metadata
    const zkCommand = `zk new --print-path --interactive --title "${title.replace(/"/g, '\\"')}"`;

    // Create temporary file for content
    const tempFile = path.join(os.tmpdir(), `zk-voice-${Date.now()}.md`);
    fs.writeFileSync(tempFile, noteContent, "utf8");

    // Create the note with zk
    const result = execSync(`${zkCommand} < "${tempFile}"`, {
      encoding: "utf8",
      cwd: NOTES_DIR,
    });

    // Clean up temp file
    fs.unlinkSync(tempFile);

    // Extract the created note path from zk output
    const notePath = result.replace(/^\s*output:\s*/i, "").trim();

    if (notePath && fs.existsSync(notePath)) {
      showSuccess(`Zettelkasten note created: ${path.basename(notePath)}`);
      return notePath;
    } else {
      throw new Error("Note creation failed - file not found");
    }
  } catch (error) {
    // Fallback: create note manually if zk command fails
    showInfo(`zk command failed: ${error.message}, creating note manually...`);

    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
    const noteFilename = `${timestamp}-voice-note.md`;
    const notePath = path.join(NOTES_DIR, noteFilename);

    // Add YAML frontmatter for manual creation
    const manualContent = `---
title: "${title}"
date: ${new Date().toISOString()}
tags: [${tags.map((tag) => `"${tag}"`).join(", ")}]
type: fleeting
source: voice-recording
---

${noteContent}`;

    fs.writeFileSync(notePath, manualContent, "utf8");
    showSuccess(`Manual note created: ${noteFilename}`);
    return notePath;
  }
}

// Main function
async function main() {
  try {
    console.log("🎵 Voice Note Recorder");
    console.log("======================\n");

    // Check dependencies
    checkDependencies();

    // Ensure directories exist
    ensureDirectories();

    // Generate filename for audio
    const audioFilename = generateFilename();

    // Record audio
    const audioPath = await recordAudio(audioFilename);

    // Transcribe audio
    const transcript = await transcribeAudio(audioPath);

    console.log("\n📝 Transcript Preview:");
    console.log("─".repeat(50));
    console.log(
      transcript.substring(0, 200) + (transcript.length > 200 ? "..." : ""),
    );
    console.log("─".repeat(50));

    // Generate title and tags
    const {
      title,
      tags,
      body,
      connections = [],
    } = await generateTitleAndTags(transcript);

    console.log(`\n📋 Title: ${title}`);
    console.log(`🏷️  Tags: ${tags.join(", ")}`);
    if (connections.length > 0) {
      console.log(`🔗 Connections: ${connections.join(", ")}`);
    }

    // Save note
    const notePath = saveNote(title, body, tags, connections, audioFilename);

    console.log(`\n💾 Zettelkasten note: ${path.basename(notePath)}`);
    console.log(`🎵 Audio saved to: ${path.relative(NOTES_DIR, audioPath)}`);

    // Show zk-specific info
    try {
      const zkInfo = execSync(
        `zk list --format "{{id}} - {{title}}" --limit 1 --sort created-`,
        {
          encoding: "utf8",
          cwd: NOTES_DIR,
        },
      );
      console.log(`🆔 Note ID: ${zkInfo.trim().split(" - ")[0]}`);
    } catch (error) {
      // Ignore if zk list fails
    }

    console.log("\n✨ Voice note processing completed successfully!");
    console.log("💡 Next steps:");
    console.log("   • Review the fleeting note and extract key insights");
    console.log("   • Create connections to existing notes with: zk link");
    console.log("   • Process into permanent notes when ready");

    // Show quick stats
    const wordCount = transcript.split(/\s+/).length;
    const duration = Math.round(
      fs.statSync(audioPath).size / (SAMPLE_RATE * 2),
    ); // Rough estimate
    console.log(`📊 Stats: ${wordCount} words, ~${duration}s recording`);
  } catch (error) {
    showError(`Processing failed: ${error.message}`);
    process.exit(1);
  }
}

// Run the main function
if (require.main === module) {
  main();
}
