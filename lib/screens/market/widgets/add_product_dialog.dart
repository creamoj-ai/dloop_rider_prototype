import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/market_products_service.dart';
import '../../../theme/tokens.dart';

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const AddProductDialog(),
    );
  }

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _costCtrl = TextEditingController(text: '0');
  final _stockCtrl = TextEditingController(text: '10');
  final _descCtrl = TextEditingController();
  String _category = 'bevande';
  bool _loading = false;

  static const _categories = ['bevande', 'food', 'integratori', 'altro'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _priceCtrl.dispose();
    _costCtrl.dispose();
    _stockCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1E),
      title: Text(
        'Nuovo prodotto',
        style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_nameCtrl, 'Nome prodotto'),
            const SizedBox(height: 8),
            _field(_descCtrl, 'Descrizione'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _field(_priceCtrl, 'Prezzo (\u20AC)', isNumber: true)),
                const SizedBox(width: 8),
                Expanded(child: _field(_costCtrl, 'Costo (\u20AC)', isNumber: true)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _field(_stockCtrl, 'Stock', isNumber: true)),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _category,
                    dropdownColor: const Color(0xFF2A2A2E),
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Categoria',
                      labelStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
                      enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                    ),
                    items: _categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v ?? 'bevande'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annulla', style: GoogleFonts.inter(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.turboOrange),
          onPressed: _loading ? null : _save,
          child: _loading
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text('Salva', style: GoogleFonts.inter(color: Colors.white)),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    if (name.isEmpty || price == null || price <= 0) return;

    setState(() => _loading = true);
    try {
      await MarketProductsService.addProduct(
        name: name,
        price: price,
        costPrice: double.tryParse(_costCtrl.text.trim()) ?? 0,
        category: _category,
        stock: int.tryParse(_stockCtrl.text.trim()) ?? 0,
        description: _descCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Errore: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Widget _field(TextEditingController ctrl, String label, {bool isNumber = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 12, color: Colors.white38),
        enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
        focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: AppColors.turboOrange)),
      ),
    );
  }
}
