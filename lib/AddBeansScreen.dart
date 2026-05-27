import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:v60pal/ApiClient.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/Beans.dart';
import 'package:v60pal/models/BeansList.dart';
import 'package:v60pal/services/BeansService.dart';
import 'package:v60pal/widgets/app_ui.dart';

class AddBeansScreen extends StatefulWidget {
  const AddBeansScreen({super.key});

  @override
  State<AddBeansScreen> createState() => _AddBeansScreenState();
}

class _AddBeansScreenState extends State<AddBeansScreen> {
  final _formKey = GlobalKey<FormState>();

  late final ApiClient api;
  late final BeansService beansSvc;

  // Controllers
  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _originCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();
  final TextEditingController _weightCtrl = TextEditingController();

  // Roast level options
  final List<String> _roastLevels = const [
    'light',
    'medium',
    'medium-light',
    'medium-dark',
    'dark',
  ];
  String? _selectedRoast;
  DateTime? _roastDate;

  final todayDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    api = ApiClient('http://10.0.2.2:3000');
    beansSvc = BeansService(api);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _originCtrl.dispose();
    _notesCtrl.dispose();
    _weightCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickRoastDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _roastDate,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      helpText: 'Select Roast Date',
      builder: (context, child) {
        // Optional theming hook
        return Theme(data: Theme.of(context), child: child!);
      },
    );
    if (picked != null) {
      setState(() => _roastDate = picked);
    }
  }

  String? _extractId(dynamic json) {
    if (json is Map<String, dynamic>) {
      final direct = json['_id'] ?? json['id'];
      if (direct is String && direct.isNotEmpty) return direct;
      if (direct is Map && direct[r'$oid'] is String) {
        return direct[r'$oid'] as String;
      }

      final inserted = json['insertedId'];
      if (inserted is String) return inserted;
      if (inserted is Map && inserted[r'$oid'] is String) {
        return inserted[r'$oid'] as String;
      }

      for (final key in ['bean', 'data', 'result']) {
        final nested = json[key];
        final id = _extractId(nested);
        if (id != null) return id;
      }
    }
    return null;
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Must Input a Name')));
      return;
    }

    if (_roastDate == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Must Select a Roast Date')));
      return;
    }
    final newOrigin = (_originCtrl.text.isEmpty) ? "" : _originCtrl.text;
    final newRoast = (_selectedRoast == null) ? "" : _selectedRoast!;
    final newWeight = (_weightCtrl.text.isEmpty)
        ? 0
        : int.parse(_weightCtrl.text);
    final ttxt = _notesCtrl.text.trim();
    final newNotes = ttxt.isEmpty ? '' : _notesCtrl.text;

    try {
      final res = await beansSvc.create(
        name: _nameCtrl.text.trim(),
        origin: newOrigin.trim(),
        roastLevel: newRoast,
        roastDate: _roastDate!,
        weight: newWeight,
        notes: newNotes.trim(),
      );
      final serverId = _extractId(res);
      debugPrint('$serverId is the server id');
      final bean = Beans(
        id: serverId!,
        name: _nameCtrl.text.trim(),
        origin: newOrigin,
        roastLevel: newRoast,
        roastDate: _roastDate!,
        weight: newWeight,
        notes: newNotes,
      );
      final beansList = context.read<BeansList>();
      await beansList.addEntry(bean);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Created Beans')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error $e')));
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final textStyleHeader = Theme.of(context).textTheme.titleMedium;
    Widget todayText = Text(
      "${todayDate.year}-${todayDate.month.toString().padLeft(2, '0')}-${todayDate.day.toString().padLeft(2, '0')}",
    );
    if (_roastDate != null) {
      todayText = Text(
        "${_roastDate!.year}-${_roastDate!.month.toString().padLeft(2, '0')}-${_roastDate!.day.toString().padLeft(2, '0')}",
      );
    }

    Widget card({required Widget child}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: AppSectionCard(child: child),
      );
    }

    InputDecoration dec(String hint) => appInputDecoration(hint);

    return Scaffold(
      backgroundColor: BACKGROUND_COLOR,
      appBar: AppBar(
        automaticallyImplyLeading: true,
        title: const Text('Add Beans'),
        actions: [
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.done),
            onPressed: _save,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppPageTitle(
                title: 'New Beans',
                subtitle: 'Save the roast details you want close at hand.',
              ),
              const SizedBox(height: 10),

              // Basic info
              card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Basics", style: textStyleHeader),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nameCtrl,
                      decoration: dec('Name (e.g., Ethiopia Koke)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _originCtrl,
                      decoration: dec('Origin (e.g., Ethiopia, Guatemala)'),
                    ),
                    const SizedBox(height: 12),
                    // Roast level (dropdown) + date picker in a row
                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: dec('Roast Level'),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRoast,
                                hint: const Text('Select Roast Level'),
                                items: _roastLevels
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(r),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedRoast = v),
                                isExpanded: true,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: InkWell(
                            onTap: _pickRoastDate,
                            child: InputDecorator(
                              decoration: dec('Roast Date'),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  todayText,
                                  const Icon(Icons.calendar_today, size: 18),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Weight
              card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Package", style: textStyleHeader),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Weight",
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _weightCtrl,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            decoration: dec('Weight (g)'),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Notes
              card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Notes", style: textStyleHeader),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _notesCtrl,
                      maxLines: null,
                      decoration: dec('Tasting notes, brew tips, etc.'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Validate minimal fields before saving
            ],
          ),
        ),
      ),
    );
  }
}
