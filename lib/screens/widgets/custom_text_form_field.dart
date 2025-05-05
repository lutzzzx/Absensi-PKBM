import 'package:flutter/material.dart';

class CustomTextFormField extends StatefulWidget {
  final Icon icon;
  final TextEditingController controller;
  final String labelText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool readOnly;
  final VoidCallback? onTap;
  final ValueChanged<String>? onChanged;
  final bool isEdit;
  final List<String>? dropdownItems;
  final String? initialDropdownValue;
  final bool obscureText;

  const CustomTextFormField({
    super.key,
    required this.icon,
    required this.controller,
    required this.labelText,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.readOnly = false,
    this.onTap,
    this.onChanged,
    this.isEdit = false,
    this.dropdownItems,
    this.initialDropdownValue,
    this.obscureText = false,
  });

  @override
  _CustomTextFormFieldState createState() => _CustomTextFormFieldState();
}

class _CustomTextFormFieldState extends State<CustomTextFormField> {
  late FocusNode _focusNode;
  Color _iconColor = Colors.grey;
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _iconColor = _focusNode.hasFocus ? Colors.blue : Colors.grey;
      });
    });

    _selectedValue = widget.initialDropdownValue;
    if (widget.initialDropdownValue != null) {
      widget.controller.text = widget.initialDropdownValue!;
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: widget.dropdownItems != null
          ? DropdownButtonFormField<String>(
        value: _selectedValue,
        items: widget.dropdownItems!
            .map((item) => DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        ))
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedValue = value;
            widget.controller.text = value ?? '';
          });
          if (widget.onChanged != null) {
            widget.onChanged!(value ?? '');
          }
        },
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0), // Atur padding di sini
          prefixIcon: Icon(
            widget.icon.icon,
            color: widget.isEdit ? Colors.blue : _iconColor,
          ),
          labelText: widget.labelText,
          labelStyle: TextStyle(color: Colors.grey),
          floatingLabelStyle: TextStyle(
            color: widget.isEdit ? Colors.blue : Colors.grey,
          ),
          filled: true,
          fillColor: widget.isEdit ? Colors.blue : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.0),
            borderSide: BorderSide(
                color: widget.isEdit ? Colors.blue : Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.0),
            borderSide: BorderSide(
                color: widget.isEdit ? Colors.blue : Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.0),
            borderSide: const BorderSide(color: Colors.blue),
          ),
        ),
        dropdownColor: Colors.white,
        validator: widget.validator,
      )
          : TextFormField(
        controller: widget.controller,
        focusNode: _focusNode,
        readOnly: widget.readOnly,
        onTap: widget.onTap,
        onChanged: widget.onChanged,
        obscureText: widget.obscureText,
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 12.0), // Atur padding di sini
          prefixIcon: Icon(
            widget.icon.icon,
            color: widget.isEdit ? Colors.blue : _iconColor,
          ),
          labelText: widget.labelText,
          labelStyle: TextStyle(color: Colors.grey),
          floatingLabelStyle: TextStyle(
            color: widget.isEdit ? Colors.blue : Colors.grey,
          ),
          filled: true,
          fillColor: widget.isEdit ? Colors.blue : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.0),
            borderSide: BorderSide(
                color: widget.isEdit ? Colors.blue : Colors.grey),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.0),
            borderSide: BorderSide(
                color: widget.isEdit ? Colors.blue : Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.0),
            borderSide: const BorderSide(color: Colors.blue),
          ),
        ),
        keyboardType: widget.keyboardType,
        validator: widget.validator,
      ),
    );
  }
}