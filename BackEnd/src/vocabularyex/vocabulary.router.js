import vocabularyController from './vocabulary.controller.js';

const router = express.Router();

router.post('/', vocabularyController.createVocabulary);
router.get('/level/:level', vocabularyController.getVocabularyByLevel);
router.get('/id/:id', vocabularyController.getVocabularyById);

export default router;