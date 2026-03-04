import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class RequestContactMethod extends StatelessWidget {
  final String selectedMethod; // "call", "chat", "whatsapp"
  final Function(String) onSelect;
  final String phoneNumber;
  final Function(String) onPhoneChanged;

  const RequestContactMethod({
    super.key,
    required this.selectedMethod,
    required this.onSelect,
    required this.phoneNumber,
    required this.onPhoneChanged,
  });

  @override
  Widget build(BuildContext context) {
    const kCardBg = Color(0xFF111111);
    const kBorder = Color(0xFF333333);
    const kGold = Color(0xFFFFD700);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10),
          child: Text(
            "БАЙЛАНЫС ТҮРІ",
            style: TextStyle(
              color: Color(0xFF666666),
              fontSize: 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            ),
          ),
        ),

        // ------------------------------------------
        // CONTACT BUTTONS ROW
        // ------------------------------------------
        Row(
          children: [
            Expanded(
              child: _ContactOption(
                label: "Қоңырау",
                icon: CupertinoIcons.phone,
                value: "call",
                isActive: selectedMethod == "call",
                onTap: () => onSelect("call"),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: _ContactOption(
                label: "Чат",
                icon: CupertinoIcons.chat_bubble_text,
                value: "chat",
                isActive: selectedMethod == "chat",
                onTap: () => onSelect("chat"),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: _ContactOption(
                label: "WhatsApp",
                isTextIcon: true,
                textIcon: "WA",
                value: "whatsapp",
                isActive: selectedMethod == "whatsapp",
                onTap: () => onSelect("whatsapp"),
              ),
            ),
          ],
        ),

        // ------------------------------------------
        // PHONE INPUT (only for call or whatsapp)
        // ------------------------------------------
        AnimatedCrossFade(
          firstChild: Container(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: kCardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: kBorder),
                  ),
                  child: TextField(
                    keyboardType: TextInputType.phone,
                    onChanged: onPhoneChanged,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                    decoration: const InputDecoration(
                      hintText: "+7 700 000 00 00",
                      hintStyle: TextStyle(color: Color(0xFF444444)),
                      border: InputBorder.none,
                      contentPadding:
                          EdgeInsets.fromLTRB(56, 16, 16, 16),
                    ),
                  ),
                ),
                const Positioned(
                  left: 20,
                  top: 16,
                  child: Icon(CupertinoIcons.phone, color: kGold, size: 20),
                ),
              ],
            ),
          ),
          crossFadeState: selectedMethod == "chat"
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,
          duration: const Duration(milliseconds: 300),
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

// =====================================================================
// CONTACT BUTTON WIDGET (Reusable)
// =====================================================================

class _ContactOption extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool isTextIcon;
  final String textIcon;
  final String value;
  final bool isActive;
  final VoidCallback onTap;

  const _ContactOption({
    required this.label,
    this.icon,
    this.isTextIcon = false,
    this.textIcon = "",
    required this.value,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const kCardBg = Color(0xFF111111);
    const kGold = Color(0xFFFFD700);
    const kBorder = Color(0xFF333333);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isActive ? kGold.withValues(alpha: 0.1) : kCardBg,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isActive ? kGold : kBorder),
          boxShadow: isActive
              ? [BoxShadow(color: kGold.withValues(alpha: 0.15), blurRadius: 15)]
              : [],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isTextIcon)
              Text(
                textIcon,
                style: TextStyle(
                  color: isActive ? kGold : Colors.grey[600],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              )
            else
              Icon(
                icon,
                color: isActive ? kGold : Colors.grey[600],
                size: 20,
              ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: isActive ? kGold : Colors.grey[600],
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
