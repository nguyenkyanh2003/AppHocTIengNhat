import { z } from 'zod';

const objectId = z
  .string()
  .regex(/^[0-9a-fA-F]{24}$/, 'Định danh không hợp lệ.');

export const idParams = z.object({ id: objectId });
