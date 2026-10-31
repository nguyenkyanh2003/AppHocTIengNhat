import mongoose from "mongoose";

const vocabularySchema = new mongoose.Schema({
    word: {
        type: String,
        required: true,
        trim: true,
    },
    hiragana: {
        type: String,
        required: true,
        trim: true,
    },
    meaning: {
        type: String,
        required: true,
        trim: true,
    },
    level: {
        type: String,
        required: true,
        enum: ['N5', 'N4', 'N3', 'N2', 'N1'],
    },
    usage_context: {
        type: String,
        trim: true,
        default: null,
    },
    audio_url: {
        type: String,
        default: null,
    },
}, { timestamps: true, collection: 'vocabulary_exercises' });

vocabularySchema.index({ word: 1, hiragana: 1 }, { unique: true });

export default mongoose.model('VocabularyEx', vocabularySchema);