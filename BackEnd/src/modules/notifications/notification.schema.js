import { z } from 'zod';

import { NOTIFICATION_TYPES, SENDABLE_NOTIFICATION_TYPES } from '../../../model/Notification.js';
import { paginationQuery } from '../../shared/http/pagination.js';
import { objectId } from '../../shared/http/schemas.js';

export const TITLE_MAX = 120;
export const MESSAGE_MAX = 2000;

export const listQuery = paginationQuery.extend({
  status: z.enum(['all', 'read', 'unread']).default('all'),
  // Bỏ trống là mọi loại. App dùng `ACHIEVEMENT` để tìm huy hiệu vừa nhận mà chưa báo.
  type: z.enum(NOTIFICATION_TYPES).optional(),
});

export const idParams = z.object({ id: objectId });

const content = {
  title: z.string().trim().min(1, 'Vui lòng nhập tiêu đề.').max(TITLE_MAX),
  message: z.string().trim().min(1, 'Vui lòng nhập nội dung.').max(MESSAGE_MAX),
  type: z.enum(SENDABLE_NOTIFICATION_TYPES).default('SYSTEM'),
};

/** `strict`: tên trường cũ (`NguoiHocID`, `TieuDe`...) là 400, không bị lờ đi rồi lưu thiếu. */
export const sendBody = z.strictObject({ recipient_id: objectId, ...content });

export const broadcastBody = z.strictObject(content);
