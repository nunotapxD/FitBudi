import 'package:flutter/material.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({Key? key}) : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para os campos
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _cardNumberController = TextEditingController();
  final TextEditingController _expiryDateController = TextEditingController();
  final TextEditingController _cvvController = TextEditingController();

  // Função de validação para o valor
  String? _validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira o valor';
    }
    if (double.tryParse(value) == null) {
      return 'Insira um valor válido';
    }
    return null;
  }

  // Função de validação para o número do cartão
  String? _validateCardNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira o número do cartão';
    }
    if (value.length != 16) {
      return 'O número do cartão deve ter 16 dígitos';
    }
    return null;
  }

  // Função de validação para a data de validade
  String? _validateExpiryDate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira a data de validade';
    }
    if (!RegExp(r'^(0[1-9]|1[0-2])/\d{2}$').hasMatch(value)) {
      return 'Data inválida, use o formato MM/AA';
    }
    return null;
  }

  // Função de validação para o CVV
  String? _validateCVV(String? value) {
    if (value == null || value.isEmpty) {
      return 'Por favor, insira o CVV';
    }
    if (value.length != 3) {
      return 'O CVV deve ter 3 dígitos';
    }
    return null;
  }

  // Função de pagamento (exemplo fictício)
  void _processPayment() {
    if (_formKey.currentState?.validate() ?? false) {
      // Aqui você pode chamar sua API de pagamento (por exemplo, Stripe, PayPal)
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Pagamento realizado com sucesso!'),
          content: const Text('O pagamento foi processado corretamente.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } else {
      // Exibe uma mensagem de erro caso a validação falhe
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha todos os campos corretamente.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pagamento'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Campo para valor do pagamento
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Valor (R\$)',
                    prefixIcon: Icon(Icons.attach_money),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateAmount,
                ),
                const SizedBox(height: 16),

                // Campo para número do cartão de crédito
                TextFormField(
                  controller: _cardNumberController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Número do Cartão',
                    prefixIcon: Icon(Icons.credit_card),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateCardNumber,
                  maxLength: 16, // Número do cartão com 16 dígitos
                ),
                const SizedBox(height: 16),

                // Campo para data de validade do cartão
                TextFormField(
                  controller: _expiryDateController,
                  decoration: const InputDecoration(
                    labelText: 'Data de Validade (MM/AA)',
                    prefixIcon: Icon(Icons.date_range),
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: _validateExpiryDate,
                ),
                const SizedBox(height: 16),

                // Campo para CVV
                TextFormField(
                  controller: _cvvController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'CVV',
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: _validateCVV,
                  maxLength: 3, // CVV com 3 dígitos
                ),
                const SizedBox(height: 32),

                // Botão para processar o pagamento
                ElevatedButton(
                  onPressed: _processPayment,
                  child: const Text('Pagar'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
