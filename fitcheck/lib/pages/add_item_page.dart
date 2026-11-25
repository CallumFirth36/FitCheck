import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fitcheck/core/app_colours.dart';
import 'package:fitcheck/core/clothing_colours.dart';
import 'package:fitcheck/models/clothing_item.dart';
import 'package:fitcheck/services/wardrobe_service.dart';
import 'package:fitcheck/widgets/auth_text_field.dart';
import 'package:fitcheck/widgets/gradient_background.dart';

// The form for adding one clothing item to the wardrobe.
class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // The choices the user makes
  ClothingCategory _category = ClothingCategory.top;
  String? _colour;            // null until a swatch is tapped
  bool _colourError = false;  // true shows "Please pick a colour"
  int _warmth = 3;            // 1 to 5
  bool _waterproof = false;
  bool _saving = false;       // true while the save is in progress

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Same side spacing that AuthTextField has built in, so everything lines up
  static const _side = EdgeInsets.symmetric(horizontal: 40);

  // A bold heading above each section of the form
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.textOnDark,
        ),
      ),
    );
  }

  // Outline chosen colour
  Widget _colourSwatch(ClothingColour c) {
    final selected = _colour == c.name;
    final tickColor =
        ThemeData.estimateBrightnessForColor(c.color) == Brightness.light
            ? Colors.black87
            : Colors.white;

    return Tooltip(
      message: c.name,
      child: GestureDetector(
        onTap: () => setState(() {
          _colour = c.name;
          _colourError = false;
        }),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: c.color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? AppColors.accent : Colors.white54,
              width: selected ? 3 : 1,
            ),
          ),
          child: selected ? Icon(Icons.check, size: 22, color: tickColor) : null,
        ),
      ),
    );
  }

  // Builds the clothing item and sames it with wardrobe service
  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    final colourOk = _colour != null;
    if (!colourOk) setState(() => _colourError = true);
    if (!formOk || !colourOk) return; // show the errors and stop

    // Grabbed now, because using context after an await can be unsafe
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final item = ClothingItem(
      name: _nameController.text.trim(),
      category: _category,
      colour: _colour!,
      warmth: _warmth,
      waterproof: _waterproof,
      createdAt: DateTime.now(),
    );

    setState(() => _saving = true);
    try {

      await wardrobeService.addItem(item).timeout(const Duration(seconds: 8));

      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text('Added "${item.name}"')));
      navigator.pop(); // back to the wardrobe page
    } on TimeoutException {

      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(
        content: Text("You seem to be offline. It will save when you reconnect."),
      ));
      navigator.pop();
    } catch (e) {
      print(e);
      messenger.showSnackBar(const SnackBar(
        content: Text("Couldn't save that item. Please try again."),
      ));
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Add Item',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textOnDark,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.textOnDark),
      ),
      body: GradientBackground(
        child: SafeArea(
          // scrollable so the keyboard never causes an overflow error
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: kToolbarHeight, bottom: 30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---- Name ----
                  _label('Name'),
                  AuthTextField(
                    controller: _nameController,
                    hint: 'e.g. Navy rain jacket',
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter a name';
                      }
                      return null;
                    },
                  ),

                  // ---- Category: one chip per category, tap to choose ----
                  _label('Category'),
                  Padding(
                    padding: _side,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ClothingCategory.values.map((c) {
                        return ChoiceChip(
                          label: Text(c.label),
                          selected: _category == c,
                          selectedColor: AppColors.accent,
                          onSelected: (_) => setState(() => _category = c),
                        );
                      }).toList(),
                    ),
                  ),

                  //  Colour: one circle per colour in your colour list 
                  _label('Colour'),
                  Padding(
                    padding: _side,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children:
                          ClothingColours.all.map(_colourSwatch).toList(),
                    ),
                  ),
                  if (_colourError)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(40, 8, 40, 0),
                      child: Text(
                        'Please pick a colour',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),

                  //  Warmth: slider from 1 to 5 
                  _label('Warmth: $_warmth / ${ClothingItem.maxWarmth}'),
                  Padding(
                    padding: _side,
                    child: Slider(
                      value: _warmth.toDouble(),
                      min: ClothingItem.minWarmth.toDouble(),
                      max: ClothingItem.maxWarmth.toDouble(),
                      divisions: ClothingItem.maxWarmth - ClothingItem.minWarmth,
                      label: '$_warmth',
                      activeColor: AppColors.accent,
                      onChanged: (v) => setState(() => _warmth = v.round()),
                    ),
                  ),
                  const Padding(
                    padding: _side,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Light', style: TextStyle(color: Colors.white70)),
                        Text('Very warm',
                            style: TextStyle(color: Colors.white70)),
                      ],
                    ),
                  ),

                  //  Waterproof switch 
                  const SizedBox(height: 8),
                  Padding(
                    padding: _side,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Waterproof',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textOnDark,
                        ),
                      ),
                      value: _waterproof,
                      activeTrackColor: AppColors.accent,
                      onChanged: (v) => setState(() => _waterproof = v),
                    ),
                  ),

                  //  Save button (greyed out with a spinner while saving) 
                  const SizedBox(height: 24),
                  Center(
                    child: SizedBox(
                      width: 250,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        child: _saving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text(
                                'Save Item',
                                style: TextStyle(fontSize: 18),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}