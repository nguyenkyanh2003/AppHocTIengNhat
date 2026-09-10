export const meta = {
  name: 'srs-streak-spec-reconcile',
  description: 'Đối chiếu spec streak/SRS đã sửa với code Task 1-4 đã build, lập danh sách sai lệch',
  phases: [
    { title: 'Đọc spec' },
    { title: 'Đối chiếu code' },
    { title: 'Kiểm phản biện' },
    { title: 'Tổng hợp' },
  ],
}

const ROOT = 'E:/GR2/AppHocTiengNhat'
const SPEC_STREAK = `${ROOT}/docs/superpowers/specs/2026-09-09-streak-integrity-design.md`
const SPEC_SRS = `${ROOT}/docs/superpowers/specs/2026-09-09-srs-revival-design.md`
const SPEC_PROG = `${ROOT}/docs/superpowers/specs/2026-09-09-learning-loop-program-design.md`
const PLAN = `${ROOT}/docs/superpowers/plans/2026-09-09-srs-revival-and-streak-foundation.md`

const COMMON = `
BỐI CẢNH: dự án app học tiếng Nhật. Backend Node/Express 5 + Mongoose 8, ESM, test bằng \`node --test\`.

Một loạt task (Task 1-4) ĐÃ ĐƯỢC TRIỂN KHAI dựa trên một implementation plan viết TRƯỚC khi spec được sửa lại.
Sau đó người dùng đã VIẾT LẠI spec đáng kể. Nhiệm vụ của bạn là tìm ra chính xác chỗ nào code hiện tại lệch spec hiện tại.

SPEC LÀ NGUỒN RÀNG BUỘC. Plan (${PLAN}) chỉ là lập luận cũ, đã lỗi thời — khi plan và spec mâu thuẫn, SPEC THẮNG.

Code đã build ở Task 1-4 (đọc để đối chiếu):
- ${ROOT}/BackEnd/src/modules/streaks/streak-rules.js
- ${ROOT}/BackEnd/src/modules/streaks/streak.repository.js
- ${ROOT}/BackEnd/src/modules/streaks/streak.service.js
- ${ROOT}/BackEnd/src/modules/streaks/streak.controller.js  (CHƯA sửa - còn bản cũ)
- ${ROOT}/BackEnd/src/modules/streaks/streak.routes.js      (CHƯA sửa - còn bản cũ)
- ${ROOT}/BackEnd/src/shared/db/unit-of-work.js
- ${ROOT}/BackEnd/model/XpEvent.js
- ${ROOT}/BackEnd/model/StreakDay.js
- ${ROOT}/BackEnd/model/UserStreak.js
- ${ROOT}/BackEnd/tests/streak-rules.test.js, streak.repository.test.js, streak.service.test.js, unit-of-work.test.js

QUY TẮC:
- CHỈ ĐỌC. Tuyệt đối không sửa file nào.
- Trích dẫn số dòng cụ thể cho cả spec lẫn code. Khẳng định không có dẫn chứng dòng là vô giá trị.
- Đừng suy đoán. Nếu spec không nói rõ, ghi là "spec không quy định" chứ đừng bịa ra yêu cầu.
- Phân biệt: (a) code TRÁI spec, (b) code THIẾU so với spec, (c) spec không quy định nên code tự do.
`

const GAP_SCHEMA = {
  type: 'object',
  properties: {
    area: { type: 'string' },
    gaps: {
      type: 'array',
      items: {
        type: 'object',
        properties: {
          id: { type: 'string', description: 'mã ngắn, ví dụ MODEL-1' },
          specSays: { type: 'string', description: 'spec yêu cầu gì, kèm file:dòng' },
          codeDoes: { type: 'string', description: 'code hiện làm gì, kèm file:dòng; "chưa có" nếu thiếu' },
          kind: { type: 'string', enum: ['trai-spec', 'thieu', 'spec-khong-quy-dinh'] },
          severity: { type: 'string', enum: ['blocking', 'important', 'minor'] },
          affectedFiles: { type: 'array', items: { type: 'string' } },
          fix: { type: 'string', description: 'cần làm gì để khớp spec' },
        },
        required: ['id', 'specSays', 'codeDoes', 'kind', 'severity', 'affectedFiles', 'fix'],
      },
    },
    notes: { type: 'string', description: 'điều đáng lưu ý ngoài danh sách gap' },
  },
  required: ['area', 'gaps', 'notes'],
}

const AREAS = [
  {
    key: 'model',
    prompt: `${COMMON}
MẢNG CỦA BẠN: **Model và index**.

Đọc ${SPEC_STREAK} phần §3.2 (bảng model) và mọi chỗ nói về ActivityEvent / StreakDay / UserStreak / index / TTL.
Đối chiếu với ${ROOT}/BackEnd/model/XpEvent.js, StreakDay.js, UserStreak.js.

Câu hỏi phải trả lời dứt khoát:
1. Spec gọi model nhật ký là gì? Code tạo model tên gì? Spec có nói gì về việc KHÔNG tạo model trùng dữ liệu không?
2. So từng trường một: ActivityEvent trong spec có những trường nào, XpEvent trong code có những trường nào — thiếu/thừa gì?
3. StreakDay: spec liệt kê trường nào, code có trường nào, enum status có đủ giá trị spec đòi không?
4. UserStreak: spec đòi tóm tắt gồm những trường nào, code có gì, thiếu gì? Spec nói gì về việc UserStreak KHÔNG được chứa cái gì?
5. Index nào spec bắt buộc? Code khai báo index nào? Khớp không? Spec nói gì về TTL?`,
  },
  {
    key: 'contract',
    prompt: `${COMMON}
MẢNG CỦA BẠN: **Chữ ký và hợp đồng của recordActivity, chống trùng, thứ tự transaction**.

Đọc ${SPEC_STREAK} phần §3.1 và §3.3 (định danh, chống trùng) và mọi chỗ nói về transaction/CAS/revision.
Đối chiếu với ${ROOT}/BackEnd/src/modules/streaks/streak.service.js và streak.repository.js.

Câu hỏi phải trả lời dứt khoát:
1. Spec viết chữ ký recordActivity ra sao (bao nhiêu tham số, tên từng tham số)? Code cài chữ ký nào? Khác chỗ nào?
2. \`occurrenceKey\` và \`context\` trong spec dùng để làm gì? Code có khái niệm tương đương không?
3. Spec quy định chống trùng bằng cơ chế nào, khoá lưu ở đâu? Code chống trùng bằng gì, lưu ở đâu? Spec có câu nào bác bỏ trực tiếp cách code đang làm không — trích nguyên văn.
4. Spec đòi thứ tự ghi trong transaction ra sao? Code làm đúng thứ tự đó không?
5. Spec nói gì về \`revision\` và cạnh tranh khởi tạo tóm tắt? Code có dùng không?`,
  },
  {
    key: 'xp-policy',
    prompt: `${COMMON}
MẢNG CỦA BẠN: **Chính sách XP, nguồn hoạt động, cutover**.

Đọc ${SPEC_STREAK} §2 (bảng quyết định sản phẩm) và mọi bảng XP, cùng phần nói về writer/cutover.
Đối chiếu với bảng \`XP_BY_ACTIVITY\` trong ${ROOT}/BackEnd/src/modules/streaks/streak.service.js.

Đọc thêm code nguồn ghi hiện tại để biết chính sách XP thật sự đang chạy:
- ${ROOT}/BackEnd/src/modules/lesson-progress/lesson-progress.service.js
- ${ROOT}/BackEnd/src/modules/exercise/exercise.controller.js
- ${ROOT}/BackEnd/src/modules/progress/progress.controller.js
- ${ROOT}/BackEnd/src/modules/jlpt/jlpt.controller.js
- ${ROOT}/BackEnd/src/modules/users/user.repository.js

Câu hỏi phải trả lời dứt khoát:
1. Spec chốt mỗi loại hoạt động được bao nhiêu XP? Liệt kê thành bảng.
2. Bảng XP_BY_ACTIVITY trong code ghi bao nhiêu? So từng dòng với spec — dòng nào sai số?
3. Spec nói lesson-progress hiện dùng XP bao nhiêu? Đối chiếu với code thật của lesson-progress.service.js — con số nào đúng?
4. Hoạt động nào spec nói KHÔNG được nối chuỗi và KHÔNG XP? Code có tôn trọng không?
5. Spec đòi những writer nào phải chuyển cùng một đợt cutover? Cái nào đã chuyển, cái nào chưa?`,
  },
  {
    key: 'read-compat',
    prompt: `${COMMON}
MẢNG CỦA BẠN: **Đường đọc và tương thích API cũ**.

Đọc ${SPEC_STREAK} phần nói về GET /streak/my-streak, /streak/xp-history, leaderboard, và mọi ràng buộc tương thích.
Đối chiếu với ${ROOT}/BackEnd/src/modules/streaks/streak.controller.js và streak.routes.js (hai file này CHƯA được sửa, vẫn là bản cũ).

Đọc thêm phía client đang tiêu thụ:
- ${ROOT}/FrontEnd/lib/features/settings/screens/export_screen.dart
- ${ROOT}/FrontEnd/lib/features/streaks/services/streak_service.dart
- ${ROOT}/FrontEnd/lib/features/streaks/providers/streak_provider.dart

Câu hỏi phải trả lời dứt khoát:
1. Spec đòi /streak/xp-history trả hình dạng gì? Có ràng buộc nào về phân trang / giới hạn mặc định không — trích nguyên văn.
2. Client Flutter đang mong đợi hình dạng gì? Nếu đổi sang phân trang thì có làm hỏng chức năng xuất dữ liệu không?
3. Spec nói gì về việc GET /my-streak hiện có thể TẠO hoặc RESET dữ liệu khi đọc? Đó có phải lỗi phải sửa không?
4. Spec nói gì về leaderboard tuần/tháng khi đổi nguồn lịch sử? Code hiện tính thế nào?
5. Route nào spec đòi bỏ, route nào phải giữ?`,
  },
  {
    key: 'migration',
    prompt: `${COMMON}
MẢNG CỦA BẠN: **Migration và dữ liệu legacy**.

Đọc ${SPEC_STREAK} phần migration/cutover (khoảng dòng 200-240) và mọi chỗ nói tracking_started_day, legacy_day_count, baseline, chuỗi cũ.

Đối chiếu với thực tế: hiện có script ${ROOT}/BackEnd/scripts/audit-srs-progress.js (audit SRS, đã chạy) nhưng CHƯA có audit hay migration nào cho UserStreak.

Câu hỏi phải trả lời dứt khoát:
1. Spec đòi audit những gì trên UserStreak trước cutover? Liệt kê đầy đủ từng mục.
2. Spec quy định xử lý chuỗi cũ ra sao — có chấm lại không, bảo toàn cái gì?
3. tracking_started_day / legacy_day_count / total_active_days dùng để làm gì, tính từ đâu?
4. Spec nói gì về việc chuyển reward_keys cũ thành event? Trích nguyên văn.
5. Có bước migration nào BẮT BUỘC phải làm trước khi bật code mới không? Liệt kê theo thứ tự.`,
  },
  {
    key: 'srs-dependency',
    prompt: `${COMMON}
MẢNG CỦA BẠN: **SRS spec phụ thuộc gì vào nền streak Phần A**.

Đọc ${SPEC_SRS} toàn bộ, tập trung phần nói về ghi hoạt động ngày, XP, transaction, recordActivity, unit of work.
Đọc thêm ${SPEC_PROG} để biết ranh giới mốc.

Đối chiếu với những gì Task 1-4 đã build (streak-rules, unit-of-work, streak.repository, streak.service).

Câu hỏi phải trả lời dứt khoát:
1. Spec SRS gọi recordActivity với chữ ký nào, truyền gì? Khớp với code Task 4 không?
2. Spec SRS đòi khoá chống trùng cho lượt ôn được ghép từ cái gì? Trích nguyên văn. Code Task 4 làm gì cho srs.review?
3. Mỗi lượt ôn được bao nhiêu XP theo spec SRS? Có mâu thuẫn với spec streak không?
4. Spec SRS đòi unit of work có tính chất gì? unit-of-work.js đã build có đủ không?
5. Có điều gì trong spec SRS khiến nền Phần A hiện tại KHÔNG dùng được không? Đây là câu quan trọng nhất.`,
  },
]

phase('Đọc spec')
log(`Đối chiếu ${AREAS.length} mảng giữa spec đã sửa và code Task 1-4`)

const areaResults = await pipeline(
  AREAS,
  (a) => agent(a.prompt, { label: `doi-chieu:${a.key}`, phase: 'Đối chiếu code', schema: GAP_SCHEMA }),
  (res, a) => {
    if (!res || !res.gaps || res.gaps.length === 0) return res
    const serious = res.gaps.filter((g) => g.severity !== 'minor')
    if (serious.length === 0) return res

    const claims = serious
      .map(
        (g) =>
          `### ${g.id} [${g.severity}, ${g.kind}]\n- Spec được cho là nói: ${g.specSays}\n- Code được cho là làm: ${g.codeDoes}\n- File: ${(g.affectedFiles || []).join(', ')}`,
      )
      .join('\n\n')

    const LENSES = [
      {
        key: 'spec',
        brief: `LĂNG KÍNH CỦA BẠN: **spec có thật sự nói như vậy không**.

Với mỗi khẳng định, tự mở file spec được trích và đọc lại nguyên văn quanh dòng đó.

Bác bỏ (refuted=true) nếu bất kỳ điều nào đúng:
- Spec không nói điều đó, hoặc nói khác đi
- Câu được trích thuộc **Phần B / mốc 1B / phạm vi khác**, bị gán nhầm cho Phần A của mốc 1
- Spec cố ý để mở, không phải một yêu cầu bắt buộc
- Trích đúng chữ nhưng sai ngữ cảnh (ví dụ đang mô tả hiện trạng cần sửa, chứ không phải yêu cầu mới)

KHÔNG cần kiểm code ở lăng kính này. Nếu spec đúng như trích thì refuted=false, kể cả khi bạn ngờ code đã làm đúng.`,
      },
      {
        key: 'code',
        brief: `LĂNG KÍNH CỦA BẠN: **code có thật sự làm như mô tả không**.

Với mỗi khẳng định, tự mở file code được trích và đọc lại.

Bác bỏ (refuted=true) nếu bất kỳ điều nào đúng:
- Code thật ra ĐÃ làm đúng yêu cầu, agent trước đọc sót
- Mô tả "code làm gì" sai sự thật (sai dòng, sai file, sai hàm)
- Chỗ được nêu là **file chưa thuộc phạm vi đã triển khai** (ví dụ controller/routes streak vẫn là bản cũ chưa ai sửa) nên gọi là "sai lệch của code mới" là không đúng — đây là việc chưa làm, không phải làm sai

KHÔNG cần kiểm spec ở lăng kính này. Nếu code đúng như mô tả thì refuted=false.`,
      },
    ]

    return parallel(
      LENSES.map((lens) => () =>
        agent(
          `${COMMON}

Bạn PHẢN BIỆN một loạt khẳng định về sai lệch spec-vs-code trong mảng "${a.key}".
Một agent khác đưa ra chúng. Nhiệm vụ của bạn là cố BÁC BỎ, không phải xác nhận.

${lens.brief}

Trả verdict cho **từng** khẳng định dưới đây, đủ ${serious.length} mục, đúng mã đã cho.
Mặc định refuted=true nếu bạn không tự xác minh được bằng dẫn chứng dòng cụ thể.

CÁC KHẲNG ĐỊNH:

${claims}`,
          {
            label: `phan-bien:${a.key}:${lens.key}`,
            phase: 'Kiểm phản biện',
            schema: {
              type: 'object',
              properties: {
                verdicts: {
                  type: 'array',
                  items: {
                    type: 'object',
                    properties: {
                      id: { type: 'string' },
                      refuted: { type: 'boolean' },
                      reason: { type: 'string', description: 'dẫn chứng file:dòng' },
                      severityAdjusted: {
                        type: 'string',
                        enum: ['blocking', 'important', 'minor', 'khong-doi'],
                      },
                    },
                    required: ['id', 'refuted', 'reason', 'severityAdjusted'],
                  },
                },
              },
              required: ['verdicts'],
            },
          },
        ).then((r) => ({ lens: lens.key, verdicts: (r && r.verdicts) || [] })),
      ),
    ).then((lensResults) => ({ ...res, lensResults: lensResults.filter(Boolean) }))
  },
)

const areas = areaResults.filter(Boolean)

const confirmed = []
const refuted = []
for (const r of areas) {
  // Hai lăng kính kiểm hai điều kiện CẦN khác nhau (spec có nói / code có làm),
  // nên chỉ cần MỘT lăng kính bác bỏ là khẳng định sụp.
  const byId = new Map()
  for (const lr of r.lensResults || []) {
    for (const v of lr.verdicts || []) {
      const prev = byId.get(v.id) || []
      prev.push({ ...v, lens: lr.lens })
      byId.set(v.id, prev)
    }
  }

  for (const g of r.gaps || []) {
    const vs = byId.get(g.id) || []
    if (g.severity === 'minor') { confirmed.push({ ...g, area: r.area }); continue }
    if (vs.length === 0) { confirmed.push({ ...g, area: r.area, note: 'chua phan bien' }); continue }
    const killer = vs.find((v) => v.refuted)
    if (killer) {
      refuted.push({ ...g, area: r.area, whyRefuted: `[${killer.lens}] ${killer.reason}` })
      continue
    }
    const adj = vs
      .map((v) => v.severityAdjusted)
      .filter((s) => s && s !== 'khong-doi')
    const rank = { blocking: 0, important: 1, minor: 2 }
    const sev = adj.length
      ? adj.sort((x, y) => rank[y] - rank[x])[0]
      : g.severity
    confirmed.push({ ...g, area: r.area, severity: sev, verifiedBy: vs.map((v) => v.lens) })
  }
}

log(`Xác nhận ${confirmed.length} sai lệch, bác bỏ ${refuted.length}`)

phase('Tổng hợp')
const synthesis = await agent(
  `${COMMON}

Bạn tổng hợp kết quả đối chiếu spec-vs-code thành một bản đánh giá dứt khoát cho người điều phối.

SAI LỆCH ĐÃ XÁC NHẬN (đã qua phản biện):
${JSON.stringify(confirmed, null, 1)}

SAI LỆCH ĐÃ BỊ BÁC BỎ (không tính, chỉ để bạn biết đã xét):
${JSON.stringify(refuted.map((r) => ({ id: r.id, why: r.whyRefuted })), null, 1)}

Ghi chú thêm từ từng mảng:
${JSON.stringify(areas.map((a) => ({ area: a.area, notes: a.notes })), null, 1)}

Hãy trả lời:
1. Task 1 và Task 2 (streak-rules.js, unit-of-work.js) có còn dùng được với spec mới không? Cần sửa gì, hay giữ nguyên?
2. Task 3 và Task 4 (model XpEvent/StreakDay/UserStreak, repository, service) — phần nào giữ được, phần nào phải làm lại? Nói cụ thể từng file.
3. Plan hiện tại (15 task) phải sửa lại thế nào? Đưa ra danh sách task ĐÃ ĐIỀU CHỈNH cho phần còn lại, theo thứ tự phụ thuộc. Với mỗi task ghi: tên, file đụng tới, phụ thuộc task nào, và một câu về vì sao ở vị trí đó.
4. Có việc nào BẮT BUỘC phải làm trước khi viết thêm code không (audit dữ liệu, quyết định còn treo)?
5. Có mâu thuẫn nào giữa ba spec với nhau không? Nếu có, chỉ rõ và đề xuất cách xử lý.

Viết bằng tiếng Việt, gọn, có dẫn chứng file:dòng. Đây là báo cáo để ra quyết định, không phải bài luận.`,
  { label: 'tong-hop', phase: 'Tổng hợp' },
)

return { confirmed, refuted, synthesis }
