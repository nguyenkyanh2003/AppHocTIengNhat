import express from 'express';
import * as controller from './news.controller.js';

const router = express.Router();

router.get("/", controller.getRoot);
router.get("/:id", controller.getById);
router.get("/:id/related", controller.getByIdRelated);

export default router;
