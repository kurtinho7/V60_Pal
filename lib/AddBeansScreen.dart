import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:v60pal/ApiClient.dart';
import 'package:v60pal/Theme.dart';
import 'package:v60pal/models/Beans.dart';
import 'package:v60pal/models/BeansList.dart';
import 'package:v60pal/services/BeansService.dart';

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
      final serverId = (res is Map && res['_id'] is String)
          ? res['_id'] as String
          : '';
      final bean = Beans(
        id: serverId,
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
    final textStyleHeader = TextStyle(color: TEXT_COLOR, fontSize: 20);
    Widget todayText = Text(
      "${todayDate.year}-${todayDate.month.toString().padLeft(2, '0')}-${todayDate.day.toString().padLeft(2, '0')}",
      style: TextStyle(color: TEXT_COLOR),
    );
    if (_roastDate != null) {
      todayText = Text(
        "${_roastDate!.year}-${_roastDate!.month.toString().padLeft(2, '0')}-${_roastDate!.day.toString().padLeft(2, '0')}",
        style: TextStyle(color: TEXT_COLOR),
      );
    }

    Widget card({required Widget child}) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.white10,
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(4.0),
          boxShadow: const [
            BoxShadow(
              blurRadius: 4,
              offset: Offset(0, 2),
              color: Colors.black12,
            ),
          ],
        ),
        child: child,
      );
    }

    InputDecoration _dec(String hint) => InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      border: InputBorder.none,
    );

    return Scaffold(
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
              Text(
                "New Beans",
                style: TextStyle(color: TEXT_COLOR, fontSize: 35),
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
                      style: TextStyle(color: TEXT_COLOR),
                      decoration: _dec('Name (e.g., Ethiopia Koke)'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _originCtrl,
                      style: TextStyle(color: TEXT_COLOR),
                      decoration: _dec('Origin (e.g., Ethiopia, Guatemala)'),
                    ),
                    const SizedBox(height: 12),
                    // Roast level (dropdown) + date picker in a row
                    Row(
                      children: [
                        Expanded(
                          child: InputDecorator(
                            decoration: _dec('Roast Level'),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedRoast,
                                hint: const Text('Select Roast Level'),
                                items: _roastLevels
                                    .map(
                                      (r) => DropdownMenuItem(
                                        value: r,
                                        child: Text(
                                          r,
                                          style: TextStyle(color: TEXT_COLOR),
                                        ),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedRoast = v),
                                dropdownColor: Colors.black,
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
                              decoration: _dec('Roast Date'),
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
                          style: TextStyle(color: TEXT_COLOR, fontSize: 18),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _weightCtrl,
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: TextStyle(color: TEXT_COLOR),
                            decoration: _dec('Weight (g)'),
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
                      style: TextStyle(color: TEXT_COLOR),
                      maxLines: null,
                      decoration: _dec('Tasting notes, brew tips, etc.'),
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
