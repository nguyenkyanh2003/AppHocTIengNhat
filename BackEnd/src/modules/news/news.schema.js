import { z } from 'zod';

import { paginationQuery } from '../../shared/http/pagination.js';
import { jlptLevel, objectId, optionalQuery } from '../../shared/http/schemas.js';

export const listQuery = paginationQuery.extend({
  level: optionalQuery(jlptLevel),
  search: optionalQuery(z.string().trim().min(1).max(100)),
});

export const idParams = z.object({ id: objectId });

export const relatedQuery = z.object({
  limit: z.coerce.number().int().min(1).max(20).default(5),
});
