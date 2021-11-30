import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:stripesubscription/checkout_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: const Color(0xffFF2274),
        body: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox.expand(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    child: TextFormField(
                      controller: _amountController,
                      style: const TextStyle(
                        color: Colors.pink,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                      decoration: InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.attach_money),
                        hintText: 'Enter Amount',
                        hintStyle: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Colors.pink.shade100,
                            width: 4,
                          ),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter the amount';
                        }

                        if (double.tryParse(value) == null) {
                          return 'Enter valid amount';
                        }

                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 50),
                  SizedBox(
                    height: 50,
                    width: 325,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: const Color(0xffFF2274),
                      ),
                      onPressed: () =>
                          _makeSinglePayment(functionName: 'getPaymentSession'),
                      child: const Text('Single payment'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    width: 325,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        primary: const Color(0xffFF2274),
                      ),
                      onPressed: () => _makeSinglePayment(
                        functionName: 'getSubscriptionSession',
                      ),
                      child: const Text('Recurring Payment'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }

  void _makeSinglePayment({required String functionName}) async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) return;

    final stripeCheckout =
        FirebaseFunctions.instance.httpsCallable(functionName);

    final response = await stripeCheckout.call(
      <String, dynamic>{
        "amount": amount,
      },
    );

    if (response.data == null) {
      print('response empty');
      return;
    }

    final sessionUrl = response.data;

    print(sessionUrl);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(url: sessionUrl),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
