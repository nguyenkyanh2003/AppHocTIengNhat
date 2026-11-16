import express from 'express';

import { authenticateUser } from '../../middleware/auth.middleware.js';
import { uploadGroupAvatar } from '../../middleware/upload.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createGroupController } from './group.controller.js';
import * as schema from './group.schema.js';
import { groupService } from './group.service.js';

/** Nhận dependency qua tham số để test dựng router với service, auth và upload giả. */
export const createGroupRoutes = ({
  service = groupService,
  authenticate = authenticateUser,
  uploadAvatar = uploadGroupAvatar,
} = {}) => {
  const controller = createGroupController(service);
  const group = validate({ params: schema.groupParams });
  const member = validate({ params: schema.memberParams });
  const router = express.Router();

  router.post('/', authenticate, validate({ body: schema.createBody }), asyncHandler(controller.create));
  router.get('/', authenticate, validate({ query: schema.listQuery }), asyncHandler(controller.list));
  router.get('/me', authenticate, asyncHandler(controller.listMine));
  router.get('/:groupID', authenticate, group, asyncHandler(controller.detail));
  router.put('/:groupID', authenticate, group, validate({ body: schema.updateBody }), asyncHandler(controller.update));
  router.delete('/:groupID', authenticate, group, asyncHandler(controller.remove));
  router.post('/join/:groupID', authenticate, group, asyncHandler(controller.join));
  router.post('/leave/:groupID', authenticate, group, asyncHandler(controller.leave));
  router.delete('/kick/:groupID/:userID', authenticate, member, asyncHandler(controller.kick));
  router.put('/promote/:groupID/:userID', authenticate, member, asyncHandler(controller.promote));
  router.put('/demote/:groupID/:userID', authenticate, member, asyncHandler(controller.demote));
  router.get('/:groupID/stats', authenticate, group, asyncHandler(controller.stats));
  router.put('/:groupID/avatar', authenticate, group, uploadAvatar, asyncHandler(controller.setAvatar));

  return router;
};

export default createGroupRoutes();
