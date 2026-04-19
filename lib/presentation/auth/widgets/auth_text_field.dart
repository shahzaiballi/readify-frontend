import 'package:flutter/material.dart';

class AuthTextField extends StatefulWidget {
  final String label;
  final String hint;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final bool enabled;

  const AuthTextField({
    super.key,
    required this.label,
    required this.hint,
    required this.icon,
    this.isPassword = false,
    this.controller,
    this.focusNode,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscure = true;
  bool _focused = false;
  String? _errorText;

  late final FocusNode _effectiveFocus;

  @override
  void initState() {
    super.initState();
    _obscure = widget.isPassword;
    _effectiveFocus = widget.focusNode ?? FocusNode();
    _effectiveFocus.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _effectiveFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    setState(() => _focused = _effectiveFocus.hasFocus);
  }

  Color get _borderColor {
    if (_errorText != null) return Colors.redAccent.withOpacity(0.8);
    if (_focused) return const Color(0xFFB062FF);
    return Colors.white.withOpacity(0.1);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Text(
          widget.label,
          style: TextStyle(
            color: _errorText != null ? Colors.redAccent : Colors.white70,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),

        // Input container
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _focused
                ? const Color(0xFF1E233D)
                : const Color(0xFF161B2E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor, width: _focused ? 1.5 : 1),
            boxShadow: _focused && _errorText == null
                ? [
                    BoxShadow(
                      color: const Color(0xFFB062FF).withOpacity(0.08),
                      blurRadius: 10,
                    )
                  ]
                : [],
          ),
          child: TextFormField(
            controller: widget.controller,
            focusNode: _effectiveFocus,
            obscureText: _obscure,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            enabled: widget.enabled,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle:
                  const TextStyle(color: Colors.white30, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  vertical: 16, horizontal: 4),
              prefixIcon: Icon(
                widget.icon,
                color: _focused ? const Color(0xFFB062FF) : Colors.white38,
                size: 20,
              ),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white38,
                        size: 20,
                      ),
                    )
                  : null,
            ),
            onChanged: widget.onChanged,
            onFieldSubmitted: widget.onSubmitted,
            validator: (value) {
              final error = widget.validator?.call(value);
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && _errorText != error) {
                  setState(() => _errorText = error);
                }
              });
              return null; // We show error ourselves below
            },
          ),
        ),

        // Animated inline error message
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topLeft,
          child: _errorText != null
              ? Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.redAccent, size: 12),
                      const SizedBox(width: 5),
                      Text(
                        _errorText!,
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
