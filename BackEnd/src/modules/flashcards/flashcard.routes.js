import express from 'express';
import { authenticateUser } from '../../middleware/auth.middleware.js';
import * as controller from './flashcard.controller.js';

const router = express.Router();

router.get("/decks", authenticateUser, controller.getDecks);
router.get("/decks/search", authenticateUser, controller.getDecksSearch);
router.get("/decks/:id", authenticateUser, controller.getDecksById);
router.post("/decks", authenticateUser, controller.postDecks);
router.put("/decks/:id", authenticateUser, controller.putDecksById);
router.delete("/decks/:id", authenticateUser, controller.deleteDecksById);
router.post("/decks/:id/cards", authenticateUser, controller.postDecksByIdCards);
router.put("/decks/:deckId/cards/:cardId", authenticateUser, controller.putDecksByDeckIdCardsByCardId);
router.delete("/decks/:deckId/cards/:cardId", authenticateUser, controller.deleteDecksByDeckIdCardsByCardId);
router.post("/decks/:id/study", authenticateUser, controller.postDecksByIdStudy);

export default router;
