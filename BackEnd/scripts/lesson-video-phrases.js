import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { parseManifestName } from './lesson-video-manifests.js';

const DATA_DIR = fileURLToPath(new URL('../data/lesson-videos/', import.meta.url));


export const loadVideoKeyPhrases = (dir = DATA_DIR) => {
  const byLesson = new Map();
  const names = fs.readdirSync(dir).filter((name) => parseManifestName(name)).sort();

  for (const name of names) {
    const manifest = JSON.parse(fs.readFileSync(path.join(dir, name), 'utf8'));
    const seen = new Set();
    const phrases = [];
    for (const video of manifest.videos ?? []) {
      for (const line of video.transcript ?? []) {
        if (!line.key_phrase || seen.has(line.text_ja)) continue;
        seen.add(line.text_ja);
        phrases.push({
          speaker: line.speaker_ja ? (line.speaker_vi ?? line.speaker_ja) : null,
          text_ja: line.text_ja,
          reading: line.romaji ?? null,
          text_vi: line.text_vi,
        });
      }
    }
    if (phrases.length > 0) byLesson.set(manifest.lesson.title, phrases);
  }
  return byLesson;
};
