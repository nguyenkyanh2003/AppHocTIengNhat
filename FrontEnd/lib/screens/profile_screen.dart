import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import '../providers/auth_provider.dart';
import '../services/provider_reset_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _selectedImageBytes;
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông tin cá nhân'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditProfileDialog(user),
            tooltip: 'Chỉnh sửa thông tin',
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                // TODO: Reload user data
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Avatar Section
                    _buildAvatarSection(user),
                    const SizedBox(height: 24),

                    // Info Cards
                    _buildInfoCard(
                      title: 'Thông tin cơ bản',
                      children: [
                        _buildInfoRow(Icons.person, 'Họ tên', user.fullName ?? 'Chưa cập nhật'),
                        _buildInfoRow(Icons.alternate_email, 'Tên đăng nhập', user.username),
                        _buildInfoRow(Icons.email, 'Email', user.email),
                        _buildInfoRow(Icons.phone, 'Số điện thoại', user.phone ?? 'Chưa cập nhật'),
                        _buildInfoRow(Icons.cake, 'Ngày sinh', user.dateOfBirth != null 
                            ? '${user.dateOfBirth!.day}/${user.dateOfBirth!.month}/${user.dateOfBirth!.year}' 
                            : 'Chưa cập nhật'),
                        _buildInfoRow(Icons.wc, 'Giới tính', user.gender ?? 'Chưa cập nhật'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildInfoCard(
                      title: 'Học tập',
                      children: [
                        _buildInfoRow(Icons.school, 'Trình độ', user.currentLevel ?? 'N5'),
                        _buildInfoRow(Icons.stars, 'Điểm tích lũy', '${user.points ?? 0} XP'),
                        _buildInfoRow(Icons.timer, 'Tổng thời gian học', '${user.totalStudyTime ?? 0} phút'),
                        _buildInfoRow(Icons.local_fire_department, 'Streak hiện tại', '${user.currentStreak ?? 0} ngày'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    _buildInfoCard(
                      title: 'Tài khoản',
                      children: [
                        _buildInfoRow(Icons.verified_user, 'Trạng thái', user.status ?? 'active'),
                        _buildInfoRow(Icons.calendar_today, 'Ngày tạo', 
                            '${user.createdAt.day}/${user.createdAt.month}/${user.createdAt.year}'),
                        _buildInfoRow(Icons.login, 'Đăng nhập gần nhất', 
                            user.lastLogin != null 
                                ? '${user.lastLogin!.day}/${user.lastLogin!.month}/${user.lastLogin!.year}'
                                : 'Chưa có dữ liệu'),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Logout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _handleLogout(context),
                        icon: const Icon(Icons.logout),
                        label: const Text('Đăng xuất'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildAvatarSection(user) {
    return Center(
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 70,
              backgroundImage: _selectedImageBytes != null
                  ? MemoryImage(_selectedImageBytes!)
                  : (user.avatar != null
                      ? NetworkImage(user.avatar!)
                      : null) as ImageProvider?,
              backgroundColor: Colors.blue[100],
              child: (_selectedImageBytes == null && user.avatar == null)
                  ? Text(
                      user.username.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    )
                  : null,
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: GestureDetector(
              onTap: _isUploading ? null : _pickAndUploadAvatar,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.camera_alt, color: Colors.white, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.blue[700]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _isUploading = true;
        });

        // Upload to server
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final success = await authProvider.uploadAvatar(bytes, image.name);
        
        if (mounted) {
          setState(() => _isUploading = false);
          
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã cập nhật ảnh đại diện thành công!'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${authProvider.error ?? "Không thể cập nhật ảnh"}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi chọn ảnh: $e')),
        );
        setState(() => _isUploading = false);
      }
    }
  }

  void _showEditProfileDialog(user) {
    final fullNameController = TextEditingController(text: user?.fullName ?? '');
    final phoneController = TextEditingController(text: user?.phone ?? '');
    String selectedGender = user?.gender ?? 'Nam';
    String selectedLevel = user?.currentLevel ?? 'N5';
    DateTime? selectedDate = user?.dateOfBirth;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Icon(Icons.edit, color: Colors.blue[700]),
              const SizedBox(width: 8),
              const Text('Chỉnh sửa thông tin'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Họ tên',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate ?? DateTime.now(),
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => selectedDate = picked);
                    }
                  },
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Ngày sinh',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.cake),
                    ),
                    child: Text(
                      selectedDate != null
                          ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                          : 'Chọn ngày sinh',
                      style: TextStyle(
                        color: selectedDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedGender,
                  decoration: InputDecoration(
                    labelText: 'Giới tính',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.wc),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Nam', child: Text('Nam')),
                    DropdownMenuItem(value: 'Nữ', child: Text('Nữ')),
                    DropdownMenuItem(value: 'Khác', child: Text('Khác')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedGender = value);
                    }
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedLevel,
                  decoration: InputDecoration(
                    labelText: 'Trình độ',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.school),
                  ),
                  items: ['N5', 'N4', 'N3', 'N2', 'N1']
                      .map((level) => DropdownMenuItem(
                            value: level,
                            child: Text('JLPT $level'),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedLevel = value);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                
                final success = await authProvider.updateProfile(
                  fullName: fullNameController.text.trim().isEmpty ? null : fullNameController.text.trim(),
                  phoneNumber: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                  gender: selectedGender,
                  currentLevel: int.tryParse(selectedLevel.substring(1)), // Keep as int for provider
                  dateOfBirth: selectedDate,
                );
                
                if (mounted) {
                  Navigator.pop(context);
                  
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Đã cập nhật thông tin thành công!'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Lỗi: ${authProvider.error ?? "Không thể cập nhật"}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
              ),
              child: const Text('Lưu'),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      // Reset tất cả providers trước khi logout
      ProviderResetService.resetAllProviders(context);
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      
      if (mounted) {
        // Clear navigation stack và về login
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }
    }
  }
}
