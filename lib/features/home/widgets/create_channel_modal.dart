import 'package:zedu/core/core.dart';

class CreateChannelModal extends StatefulWidget {
  const CreateChannelModal({super.key});

  @override
  State<CreateChannelModal> createState() => _CreateChannelModalState();
}

class _CreateChannelModalState extends State<CreateChannelModal> {
  final _nameController = TextEditingController();

  String selectedCategory = 'General';
  String selectedType = 'Public';

  String? error;

  void _createChannel() {
    final name = _nameController.text.trim();

    if (name.isEmpty) {
      setState(() => error = 'Channel name is required');
      return;
    }

    Navigator.pop(context, {
      'name': name,
      'category': selectedCategory,
      'type': selectedType,
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(20),
        color: colors.background,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            /// Title
            Row(
              children: [
                Text(
                  'Create Channel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colors.textPrimary,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// Channel Name
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Channel name',
                errorText: error,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (_) {
                if (error != null) setState(() => error = null);
              },
            ),

            const SizedBox(height: 16),

            /// Category Dropdown
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              items: [
                'General',
                'Class',
                'Team',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => selectedCategory = val!),
              decoration: const InputDecoration(labelText: 'Category'),
            ),

            const SizedBox(height: 16),

            /// Type Dropdown
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              items: [
                'Public',
                'Private',
              ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) => setState(() => selectedType = val!),
              decoration: const InputDecoration(labelText: 'Channel Type'),
            ),

            const SizedBox(height: 24),

            /// Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _createChannel,
                child: const Text('Create Channel'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
