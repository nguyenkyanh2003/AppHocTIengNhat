import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/study_group_provider.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedLevel = 'ALL';
  bool _isPrivate = false;
  int _maxMembers = 50;
  bool _isCreating = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tạo nhóm mới'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Tên nhóm *',
                hintText: 'Nhập tên nhóm học',
                prefixIcon: Icon(Icons.group),
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập tên nhóm';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Mô tả',
                hintText: 'Mô tả về nhóm học',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedLevel,
              decoration: const InputDecoration(
                labelText: 'Cấp độ',
                prefixIcon: Icon(Icons.school),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'ALL', child: Text('Tất cả cấp độ')),
                DropdownMenuItem(value: 'N5', child: Text('JLPT N5')),
                DropdownMenuItem(value: 'N4', child: Text('JLPT N4')),
                DropdownMenuItem(value: 'N3', child: Text('JLPT N3')),
                DropdownMenuItem(value: 'N2', child: Text('JLPT N2')),
                DropdownMenuItem(value: 'N1', child: Text('JLPT N1')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedLevel = value);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: _maxMembers.toString(),
              decoration: const InputDecoration(
                labelText: 'Số thành viên tối đa',
                prefixIcon: Icon(Icons.people),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số thành viên';
                }
                final number = int.tryParse(value);
                if (number == null || number < 2 || number > 500) {
                  return 'Số thành viên phải từ 2-500';
                }
                return null;
              },
              onChanged: (value) {
                final number = int.tryParse(value);
                if (number != null) {
                  _maxMembers = number;
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Nhóm riêng tư'),
              subtitle: const Text('Yêu cầu phê duyệt để tham gia'),
              value: _isPrivate,
              onChanged: (value) {
                setState(() => _isPrivate = value);
              },
              secondary: const Icon(Icons.lock),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isCreating ? null : _createGroup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Tạo nhóm', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  void _createGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    final provider = Provider.of<StudyGroupProvider>(context, listen: false);
    final group = await provider.createGroup(
      name: _nameController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      level: _selectedLevel,
      isPrivate: _isPrivate,
      maxMembers: _maxMembers,
    );

    setState(() => _isCreating = false);

    if (group != null && mounted) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tạo nhóm thành công!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error ?? 'Lỗi khi tạo nhóm')),
      );
    }
  }
}
