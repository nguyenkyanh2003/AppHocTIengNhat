import express from 'express';

import { authenticateUser } from '../../middleware/auth.middleware.js';
import { asyncHandler } from '../../shared/http/async-handler.js';
import { validate } from '../../shared/http/validate.js';
import { createFlashcardController } from './flashcard.controller.js';
import * as schema from './flashcard.schema.js';
import { flashcardService } from './flashcard.service.js';

/**
 * Nhận dependency qua tham số để test dựng router với service và auth giả.
 * Xác thực gắn theo từng route (không `router.use`) để path không tồn tại vẫn là 404.
 */
export const createFlashcardRoutes = ({ service = flashcardService, authenticate = authenticateUser } = {}) => {
  const controller = createFlashcardController(service);
  const deck = validate({ params: schema.deckParams });
  const card = validate({ params: schema.cardParams });
  const router = express.Router();

  router.get('/decks', authenticate, validate({ query: schema.listQuery }), asyncHandler(controller.listMine));
  router.get('/decks/:id', authenticate, deck, asyncHandler(controller.detail));
  router.post('/decks', authenticate, validate({ body: schema.createDeckBody }), asyncHandler(controller.createDeck));
  router.put('/decks/:id', authenticate, deck, validate({ body: schema.updateDeckBody }), asyncHandler(controller.updateDeck));
  router.delete('/decks/:id', authenticate, deck, asyncHandler(controller.removeDeck));
  router.post('/decks/:id/cards', authenticate, deck, validate({ body: schema.cardBody }), asyncHandler(controller.addCard));
  router.put(
    '/decks/:deckId/cards/:cardId',
    authenticate,
    card,
    validate({ body: schema.updateCardBody }),
    asyncHandler(controller.updateCard),
  );
  router.delete('/decks/:deckId/cards/:cardId', authenticate, card, asyncHandler(controller.removeCard));
  router.post('/decks/:id/study', authenticate, deck, asyncHandler(controller.recordStudy));

  return router;
};

export default createFlashcardRoutes();
