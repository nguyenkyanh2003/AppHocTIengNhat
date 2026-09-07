import User from '../../../model/User.js';


// Lấy cài đặt của người dùng
export const getRoot = async (req, res) => {
  try {
    const userId = req.user._id;
    const user = await User.findById(userId).select('settings').lean();

    if (!user) {
      return res.status(404).json({ message: 'Người dùng không tìm thấy' });
    }

    res.json({
      notificationsEnabled: user.settings?.notificationsEnabled ?? true,
      soundEnabled: user.settings?.soundEnabled ?? true,
      vibrateEnabled: user.settings?.vibrateEnabled ?? true,
      language: user.settings?.language ?? 'vi',
      theme: user.settings?.theme ?? 'light',
    });
  } catch (error) {
    console.error('Lỗi khi lấy cài đặt:', error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

// Cập nhật cài đặt của người dùng
export const postRoot = async (req, res) => {
  try {
    const userId = req.user._id;
    const {
      notificationsEnabled,
      soundEnabled,
      vibrateEnabled,
      language,
      theme,
    } = req.body;

    const updatedUser = await User.findByIdAndUpdate(
      userId,
      {
        $set: {
          'settings.notificationsEnabled': notificationsEnabled ?? true,
          'settings.soundEnabled': soundEnabled ?? true,
          'settings.vibrateEnabled': vibrateEnabled ?? true,
          'settings.language': language ?? 'vi',
          'settings.theme': theme ?? 'light',
        },
      },
      { new: true }
    ).select('settings');

    res.json({
      message: 'Cài đặt đã được cập nhật',
      settings: {
        notificationsEnabled: updatedUser.settings?.notificationsEnabled,
        soundEnabled: updatedUser.settings?.soundEnabled,
        vibrateEnabled: updatedUser.settings?.vibrateEnabled,
        language: updatedUser.settings?.language,
        theme: updatedUser.settings?.theme,
      },
    });
  } catch (error) {
    console.error('Lỗi khi cập nhật cài đặt:', error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

// Cập nhật một cài đặt cụ thể
export const patchBySetting = async (req, res) => {
  try {
    const userId = req.user._id;
    const { setting } = req.params;
    const { value } = req.body;

    const allowedSettings = [
      'notificationsEnabled',
      'soundEnabled',
      'vibrateEnabled',
      'language',
      'theme',
    ];

    if (!allowedSettings.includes(setting)) {
      return res.status(400).json({ message: 'Cài đặt không hợp lệ' });
    }

    const updateObj = {};
    updateObj[`settings.${setting}`] = value;

    const updatedUser = await User.findByIdAndUpdate(userId, updateObj, {
      new: true,
    }).select('settings');

    res.json({
      message: 'Cài đặt đã được cập nhật',
      [setting]: updatedUser.settings?.[setting],
    });
  } catch (error) {
    console.error('Lỗi khi cập nhật cài đặt:', error);
    res.status(500).json({ message: 'Lỗi máy chủ', error: error.message });
  }
};

