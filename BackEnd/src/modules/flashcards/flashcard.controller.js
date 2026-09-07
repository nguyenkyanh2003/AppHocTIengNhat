import FlashcardDeck from "../../../model/FlashcardDeck.js";


// ============ DECK ROUTES ============

// 1. Lấy danh sách bộ thẻ của user (hoặc public decks)
export const getDecks = async (req, res) => {
    try {
        const { page = 1, limit = 20, category, level, myDecks } = req.query;
        const userId = req.user._id;
        
        const query = {};
        
        // Nếu myDecks=true thì chỉ lấy bộ thẻ của user, không thì lấy public + của user
        if (myDecks === 'true') {
            query.user = userId;
        } else {
            query.$or = [
                { user: userId },
                { is_public: true }
            ];
        }
        
        if (category) query.category = category;
        if (level) query.level = level;
        
        const skip = (parseInt(page) - 1) * parseInt(limit);
        
        const [decks, total] = await Promise.all([
            FlashcardDeck.find(query)
                .populate('user', 'TenDangNhap AnhDaiDien HoTen')
                .sort({ updated_at: -1 })
                .skip(skip)
                .limit(parseInt(limit))
                .lean(),
            FlashcardDeck.countDocuments(query)
        ]);
        
        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / parseInt(limit)),
            currentPage: parseInt(page),
            data: decks
        });
    } catch (error) {
        console.error("Lỗi lấy danh sách bộ thẻ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// 2. Lấy chi tiết một bộ thẻ
export const getDecksById = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;
        
        const deck = await FlashcardDeck.findById(id)
            .populate('user', 'TenDangNhap AnhDaiDien HoTen')
            .lean();
        
        if (!deck) {
            return res.status(404).json({ message: "Không tìm thấy bộ thẻ." });
        }
        
        // Kiểm tra quyền truy cập (chỉ cho phép nếu là của user hoặc là public)
        if (deck.user._id.toString() !== userId.toString() && !deck.is_public) {
            return res.status(403).json({ message: "Bạn không có quyền truy cập bộ thẻ này." });
        }
        
        res.json(deck);
    } catch (error) {
        console.error("Lỗi lấy chi tiết bộ thẻ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// 3. Tạo bộ thẻ mới
export const postDecks = async (req, res) => {
    try {
        const userId = req.user._id;
        const { title, description, is_public, category, level, tags } = req.body;
        
        if (!title || title.trim() === "") {
            return res.status(400).json({ message: "Tiêu đề bộ thẻ không được để trống." });
        }
        
        const newDeck = new FlashcardDeck({
            title: title.trim(),
            description: description?.trim(),
            user: userId,
            is_public: is_public || false,
            category: category || 'custom',
            level,
            tags: tags || [],
            cards: []
        });
        
        await newDeck.save();
        
        const populatedDeck = await FlashcardDeck.findById(newDeck._id)
            .populate('user', 'TenDangNhap AnhDaiDien HoTen')
            .lean();
        
        res.status(201).json({
            message: "Tạo bộ thẻ thành công.",
            data: populatedDeck
        });
    } catch (error) {
        console.error("Lỗi tạo bộ thẻ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// 4. Cập nhật thông tin bộ thẻ
export const putDecksById = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;
        const { title, description, is_public, category, level, tags } = req.body;
        
        const deck = await FlashcardDeck.findById(id);
        
        if (!deck) {
            return res.status(404).json({ message: "Không tìm thấy bộ thẻ." });
        }
        
        if (deck.user.toString() !== userId.toString()) {
            return res.status(403).json({ message: "Bạn không có quyền chỉnh sửa bộ thẻ này." });
        }
        
        if (title !== undefined) deck.title = title.trim();
        if (description !== undefined) deck.description = description?.trim();
        if (is_public !== undefined) deck.is_public = is_public;
        if (category !== undefined) deck.category = category;
        if (level !== undefined) deck.level = level;
        if (tags !== undefined) deck.tags = tags;
        
        await deck.save();
        
        const updatedDeck = await FlashcardDeck.findById(id)
            .populate('user', 'TenDangNhap AnhDaiDien HoTen')
            .lean();
        
        res.json({
            message: "Cập nhật bộ thẻ thành công.",
            data: updatedDeck
        });
    } catch (error) {
        console.error("Lỗi cập nhật bộ thẻ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// 5. Xóa bộ thẻ
export const deleteDecksById = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;
        
        const deck = await FlashcardDeck.findById(id);
        
        if (!deck) {
            return res.status(404).json({ message: "Không tìm thấy bộ thẻ." });
        }
        
        if (deck.user.toString() !== userId.toString()) {
            return res.status(403).json({ message: "Bạn không có quyền xóa bộ thẻ này." });
        }
        
        await FlashcardDeck.findByIdAndDelete(id);
        
        res.json({ message: "Xóa bộ thẻ thành công." });
    } catch (error) {
        console.error("Lỗi xóa bộ thẻ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// ============ CARD ROUTES ============

// 6. Thêm thẻ mới vào bộ
export const postDecksByIdCards = async (req, res) => {
    try {
        const { id } = req.params;
        const userId = req.user._id;
        const { front, back, front_subtext, back_subtext, image_url, audio_url } = req.body;
        
        if (!front || !back) {
            return res.status(400).json({ message: "Mặt trước và mặt sau không được để trống." });
        }
        
        const deck = await FlashcardDeck.findById(id);
        
        if (!deck) {
            return res.status(404).json({ message: "Không tìm thấy bộ thẻ." });
        }
        
        if (deck.user.toString() !== userId.toString()) {
            return res.status(403).json({ message: "Bạn không có quyền chỉnh sửa bộ thẻ này." });
        }
        
        const newCard = {
            front: front.trim(),
            back: back.trim(),
            front_subtext: front_subtext?.trim(),
            back_subtext: back_subtext?.trim(),
            image_url,
            audio_url,
            order: deck.cards.length
        };
        
        deck.cards.push(newCard);
        await deck.save();
        
        const updatedDeck = await FlashcardDeck.findById(id)
            .populate('user', 'TenDangNhap AnhDaiDien HoTen')
            .lean();
        
        res.status(201).json({
            message: "Thêm thẻ thành công.",
            data: updatedDeck
        });
    } catch (error) {
        console.error("Lỗi thêm thẻ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// 7. Cập nhật thẻ trong bộ
export const putDecksByDeckIdCardsByCardId = async (req, res) => {
    try {
        const { deckId, cardId } = req.params;
        const userId = req.user._id;
        const { front, back, front_subtext, back_subtext, image_url, audio_url } = req.body;
        
        const deck = await FlashcardDeck.findById(deckId);
        
        if (!deck) {
            return res.status(404).json({ message: "Không tìm thấy bộ thẻ." });
        }
        
        if (deck.user.toString() !== userId.toString()) {
            return res.status(403).json({ message: "Bạn không có quyền chỉnh sửa bộ thẻ này." });
        }
        
        const card = deck.cards.id(cardId);
        
        if (!card) {
            return res.status(404).json({ message: "Không tìm thấy thẻ." });
        }
        
        if (front !== undefined) card.front = front.trim();
        if (back !== undefined) card.back = back.trim();
        if (front_subtext !== undefined) card.front_subtext = front_subtext?.trim();
        if (back_subtext !== undefined) card.back_subtext = back_subtext?.trim();
        if (image_url !== undefined) card.image_url = image_url;
        if (audio_url !== undefined) card.audio_url = audio_url;
        
        await deck.save();
        
        const updatedDeck = await FlashcardDeck.findById(deckId)
            .populate('user', 'TenDangNhap AnhDaiDien HoTen')
            .lean();
        
        res.json({
            message: "Cập nhật thẻ thành công.",
            data: updatedDeck
        });
    } catch (error) {
        console.error("Lỗi cập nhật thẻ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// 8. Xóa thẻ khỏi bộ
export const deleteDecksByDeckIdCardsByCardId = async (req, res) => {
    try {
        const { deckId, cardId } = req.params;
        const userId = req.user._id;
        
        const deck = await FlashcardDeck.findById(deckId);
        
        if (!deck) {
            return res.status(404).json({ message: "Không tìm thấy bộ thẻ." });
        }
        
        if (deck.user.toString() !== userId.toString()) {
            return res.status(403).json({ message: "Bạn không có quyền chỉnh sửa bộ thẻ này." });
        }
        
        deck.cards.pull(cardId);
        await deck.save();
        
        const updatedDeck = await FlashcardDeck.findById(deckId)
            .populate('user', 'TenDangNhap AnhDaiDien HoTen')
            .lean();
        
        res.json({
            message: "Xóa thẻ thành công.",
            data: updatedDeck
        });
    } catch (error) {
        console.error("Lỗi xóa thẻ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// 9. Tăng số lần học bộ thẻ
export const postDecksByIdStudy = async (req, res) => {
    try {
        const { id } = req.params;
        
        const deck = await FlashcardDeck.findByIdAndUpdate(
            id,
            { $inc: { study_count: 1 } },
            { new: true }
        ).lean();
        
        if (!deck) {
            return res.status(404).json({ message: "Không tìm thấy bộ thẻ." });
        }
        
        res.json({ message: "Đã ghi nhận lượt học." });
    } catch (error) {
        console.error("Lỗi ghi nhận lượt học:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// 10. Tìm kiếm bộ thẻ
export const getDecksSearch = async (req, res) => {
    try {
        const { keyword, page = 1, limit = 20 } = req.query;
        const userId = req.user._id;
        
        if (!keyword || keyword.trim() === "") {
            return res.status(400).json({ message: "Từ khóa tìm kiếm không được để trống." });
        }
        
        const query = {
            $or: [
                { user: userId },
                { is_public: true }
            ],
            $text: { $search: keyword }
        };
        
        const skip = (parseInt(page) - 1) * parseInt(limit);
        
        const [decks, total] = await Promise.all([
            FlashcardDeck.find(query)
                .populate('user', 'TenDangNhap AnhDaiDien HoTen')
                .sort({ score: { $meta: "textScore" } })
                .skip(skip)
                .limit(parseInt(limit))
                .lean(),
            FlashcardDeck.countDocuments(query)
        ]);
        
        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / parseInt(limit)),
            currentPage: parseInt(page),
            data: decks
        });
    } catch (error) {
        console.error("Lỗi tìm kiếm bộ thẻ:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

