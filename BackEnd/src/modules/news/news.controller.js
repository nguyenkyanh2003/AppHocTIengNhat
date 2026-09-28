import News from "../../../model/News.js";


// USER ROUTES

export const getRoot = async (req, res) => {
    try {
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 10;
        const { level, search } = req.query;

        const query = {};
        
        if (level) {
            query.level = level;
        }
        
        if (search) {
            query.$or = [
                { title: { $regex: search, $options: 'i' } },
                { description: { $regex: search, $options: 'i' } },
                { content_html: { $regex: search, $options: 'i' } }
            ];
        }

        const skip = (page - 1) * limit;

        const [newsList, total] = await Promise.all([
            News.find(query)
                .sort({ createdAt: -1 })
                .skip(skip)
                .limit(limit)
                .lean(),
            News.countDocuments(query)
        ]);

        res.json({
            totalItems: total,
            totalPages: Math.ceil(total / limit),
            currentPage: page,
            data: newsList
        });
    } catch (error) {
        console.error("Lỗi lấy danh sách tin tức:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Lấy chi tiết tin tức
export const getById = async (req, res) => {
    try {
        const { id } = req.params;
        
        const news = await News.findById(id).lean();

        if (!news) {
            return res.status(404).json({ message: "Không tìm thấy tin tức." });
        }

        // Tăng lượt xem
        await News.findByIdAndUpdate(id, { $inc: { views: 1 } });

        res.json({ data: news });
    } catch (error) {
        console.error("Lỗi lấy chi tiết tin tức:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};

// Lấy tin tức liên quan
export const getByIdRelated = async (req, res) => {
    try {
        const { id } = req.params;
        const limit = parseInt(req.query.limit, 10) || 5;
        
        const currentNews = await News.findById(id);
        if (!currentNews) {
            return res.status(404).json({ message: "Không tìm thấy tin tức." });
        }

        const relatedNews = await News.find({
            _id: { $ne: id },
            level: currentNews.level
        })
            .sort({ createdAt: -1 })
            .limit(limit)
            .lean();

        res.json({
            total: relatedNews.length,
            data: relatedNews
        });
    } catch (error) {
        console.error("Lỗi lấy tin tức liên quan:", error);
        res.status(500).json({ message: "Lỗi máy chủ.", error: error.message });
    }
};
