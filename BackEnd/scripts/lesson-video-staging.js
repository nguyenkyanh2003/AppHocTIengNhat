/**
 * Đọc thư mục video gốc của một chủ đề và lên kế hoạch đưa vào app.
 *
 * Video gốc được đặt tên theo đúng tên cảnh trên trang nguồn:
 *   `10－1．Em muốn mở tài khoản..mp4`   → cảnh 1 của bài 10
 *   `10. Ôn tập.mp4`                     → video ôn tập của bài 10
 * Dấu gạch và dấu chấm nhận cả bản ASCII lẫn bản toàn độ rộng (－ ．).
 *
 * Hàm thuần, không đọc đĩa — `stage-lesson-videos.js` lo phần file. Mọi bất
 * thường làm **cả thư mục** bị từ chối: đưa nửa số cảnh vào app, hoặc đoán
 * file nào mới là cảnh đúng, đều tệ hơn là báo rõ để tải lại.
 */

export const VIDEO_SOURCE = '文部科学省「つながるひろがる にほんごでのくらし」';

const SCENE = /^(\d+)\s*[-－]\s*(\d+)\s*[.．]\s*(.+?)\s*\.mp4$/i;
const SUMMARY = /^(\d+)\s*(?:[.．]\s*|\s+)(.+?)\s*\.mp4$/i;

/** Tên hiển thị của video ôn tập — tên file ôn tập mỗi bài một kiểu ("Ôn tập", "On tap", "Tổng hợp…"). */
export const REVIEW_TITLE = 'Ôn tập';

const capitalize = (text) => text.charAt(0).toLocaleUpperCase('vi') + text.slice(1);

/**
 * Tên cảnh lấy từ tên file: bỏ dấu chấm cuối câu mà tên file buộc phải có
 * trước `.mp4` (`…tài khoản..mp4`), giữ nguyên dấu `…`. Tên file Windows không
 * chứa được `?`, nên câu hỏi phải thêm dấu tay trong file mô tả.
 */
const sceneTitle = (text) => text.trim().replace(/(?<![.…])\.$/, '');

/**
 * @returns {{ lesson: number, scene: number | null, title: string } | null}
 *   `scene` là `null` với video ôn tập; `null` cả kết quả khi tên không theo mẫu.
 */
export const parseRawVideoName = (fileName) => {
  const scene = SCENE.exec(fileName);
  if (scene) return { lesson: Number(scene[1]), scene: Number(scene[2]), title: sceneTitle(scene[3]) };

  const summary = SUMMARY.exec(fileName);
  if (summary) return { lesson: Number(summary[1]), scene: null, title: capitalize(summary[2].trim()) };

  return null;
};

/**
 * @param lesson Số bài của thư mục (lấy từ tên thư mục, ví dụ `10. sử dụng ngân hàng`).
 * @param files  `[{ name, hash }]` — `hash` là dấu vân tay nội dung của file.
 * @returns {{ videos: { file, target, title, kind }[], errors: string[] }}
 *   `videos` theo thứ tự cảnh 1, 2, 3… rồi tới video ôn tập.
 */
export const planLessonFolder = ({ lesson, files }) => {
  const errors = [];
  const scenes = new Map();
  let summary = null;

  for (const file of files) {
    const parsed = parseRawVideoName(file.name);
    if (!parsed) {
      errors.push(`"${file.name}": tên không theo mẫu "${lesson}－1．Tên cảnh.mp4" hoặc "${lesson}. Ôn tập.mp4".`);
      continue;
    }
    if (parsed.lesson !== lesson) {
      errors.push(`"${file.name}": tên file ghi bài ${parsed.lesson} nhưng nằm trong thư mục bài ${lesson}.`);
      continue;
    }

    if (parsed.scene === null) {
      if (summary) errors.push(`Có hai video ôn tập: "${summary.file}" và "${file.name}".`);
      summary = { file: file.name, title: REVIEW_TITLE, kind: 'review', target: 'summary.mp4' };
    } else if (scenes.has(parsed.scene)) {
      errors.push(`Hai file cùng là cảnh ${parsed.scene}: "${scenes.get(parsed.scene).file}" và "${file.name}".`);
    } else {
      scenes.set(parsed.scene, {
        file: file.name,
        title: parsed.title,
        kind: 'scene',
        target: `scene-${parsed.scene}.mp4`,
      });
    }
  }

  // Cùng dấu vân tay là cùng một video dù tên khác nhau: người học bấm "Cảnh
  // 2" mà xem lại đúng cảnh 1.
  const byHash = new Map();
  for (const file of files) byHash.set(file.hash, [...(byHash.get(file.hash) ?? []), file.name]);
  for (const names of byHash.values()) {
    if (names.length > 1) {
      errors.push(`${names.length} file giống hệt nhau từng byte, thực chất chỉ là một video: ${names.map((n) => `"${n}"`).join(', ')}.`);
    }
  }

  if (errors.length > 0) return { videos: [], errors };

  const ordered = [...scenes.keys()].sort((a, b) => a - b).map((scene) => scenes.get(scene));
  return { videos: summary ? [...ordered, summary] : ordered, errors };
};

/**
 * Khung file lời thoại của bài: đủ tiêu đề từng cảnh, chờ gõ câu thoại vào.
 *
 * Sinh sẵn để không ai phải tự gõ `## scene-1.mp4` — gõ sai tên cảnh là lời
 * thoại không vào đâu cả. Tiêu đề cảnh đứng ngay dưới dạng ghi chú để biết
 * đang gõ cho cảnh nào.
 */
export const transcriptSkeleton = ({ lesson, title, videos }) => {
  const lines = [
    `# Lời thoại ${title ?? `bài ${lesson}`}`,
    '# Mỗi dòng một câu: mốc | người nói JA / VI | câu tiếng Nhật | roma-ji | nghĩa tiếng Việt',
    `# Gõ xong chạy: node scripts/apply-transcript.js --lesson ${lesson}`,
    '# Mẫu đầy đủ: data/lesson-videos/n5-01-greeting.txt',
  ];
  for (const video of videos) {
    lines.push('', `## ${video.target}`, `# ${video.title}`);
  }
  return `${lines.join('\n')}\n`;
};

/**
 * File mô tả mới của bài sau khi đưa video vào `uploads/lesson-videos/<dir>/`.
 *
 * Video đã có (cùng `url`) giữ nguyên tên cảnh, mô tả và lời thoại người soạn
 * đã nhập — chỉ `kind` được đặt lại vì nó suy ra từ tên file (cảnh hay ôn
 * tập), không phải thứ người soạn sửa tay. Video mới có lời thoại rỗng chờ bổ
 * sung. Video cũ không còn trong thư mục gốc bị bỏ khỏi file mô tả.
 */
export const mergeManifest = ({ manifest, dir, videos }) => {
  const existing = new Map((manifest.videos ?? []).map((video) => [video.url, video]));
  return {
    ...manifest,
    videos: videos.map(({ target, title, kind }) => {
      const url = `/uploads/lesson-videos/${dir}/${target}`;
      const current = existing.get(url);
      return current
        ? { ...current, kind }
        : { title, url, kind, source: VIDEO_SOURCE, transcript: [] };
    }),
  };
};
