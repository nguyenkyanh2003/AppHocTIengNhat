import vocabularyex from '../../models/vocabularyex.js';
import {apiError} from '../../shared/http/api-error.js';

//1. Thêm từ vựng mới
export const createVocabulary = async (req, res) => {
    try {
        const { word, hiragana, meaning, level, usage_context, audio_url } = req.body;

        // Kiểm tra xem từ vựng đã tồn tại chưa
        const existingVocabulary = await vocabularyex.findOne({ word, hiragana });
        if (existingVocabulary) {
            return res.status(400).json({ message: 'Từ vựng đã tồn tại.' });
        }
        // Tạo từ vựng mới
        const newVocabulary = new vocabularyex({
            word,
            hiragana,
            meaning,
            level,
            usage_context,
            audio_url,
        });

        await newVocabulary.save();

        return res.status(201).json(newVocabulary);
    } catch (error) {
        console.error(error);
        return apiError(res, 500, 'Lỗi máy chủ. Vui lòng thử lại sau.');
    }
};
export const getVocabularyByLevel = async (req, res) => {
    try{
        const {level} = req.params;
        const vocabulary = await vocabularyex.find({level});
        if(!vocabulary){
            return res.status(404).json({message: 'Không tìm thấy từ vựng.'});
        }
        return res.status(200).json(vocabulary);
    } catch (error) {
        console.error(error);
        return apiError(res, 500, 'Lỗi máy chủ. Vui lòng thử lại sau.');
    }
};
export const getVocabularyById = async (req, res) => {
    try{
        const {id} = req.params;
        const vocabulary = await vocabularyex.findById(id);
        if(!vocabulary){
            return res.status(404).json({message: 'Không tìm thấy từ vựng.'});
        }
        return res.status(200).json(vocabulary);
    } catch (error) {
        console.error(error);
        return apiError(res, 500, 'Lỗi máy chủ. Vui lòng thử lại sau.');
    }
};

