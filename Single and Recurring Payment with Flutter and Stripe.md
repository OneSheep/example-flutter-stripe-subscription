There are several options to implement single payment in Flutter, it can be done easily with [pay](https://pub.dev/packages/pay), or [flutter_stripe](https://pub.dev/packages/flutter_stripe) package.

Both of these packages doesn't provide easy way of implementing the subscription in the app.

So, in this article we will learn how to implement Single and Recurring Payment (Subscription) with Flutter and Stripe.

We will be using the [Stripe Checkout](https://stripe.com/docs/payments/checkout) for this purpose.
Some of the benefits of using Stripe Checkout are:

1. Real-time card validation with built-in error messaging
2. Fully responsive design with Apple Pay, Google Pay and Card payment

To make payment using Stripe we need to generate a secure Session Token. Which needs to be
done in a server so that unauthorized person cannot temper with it. For that reason we are
going to use a Firebase Cloud Functions as our secure backend, you can use any backend as
you prefer. Stripe has an official libraries for these languages: Ruby Python PHP Java Node Go .NET.

First of all create a Stripe account and get the test Secret key.

We need to set this key as a firebase config in the Firebase Firestore using the following command:

```ps
firebase functions:config:set stripe.testkey=sk_test_xxxxxxxxxxxxxxxxxx
```

Now we are ready to install `stripe.js` package using `npm`

```ps
npm install stripe --save
```

Let's first create two cloud functions, one for single payment and one for recurring payment.
_Note: This would be your API endpoint if you are using REST API's to communicate with your backend_

```ts
// index.ts
import * as functions from 'firebase-functions';

import Stripe from 'stripe';

const stripe = new Stripe(functions.config().stripe.testkey, {
  apiVersion: '2020-08-27',
});

// get the payment url to the payment session
exports.getPaymentSession = functions.https.onCall(async (data) => {
  try {
    const checkoutSession = await stripe.checkout.sessions.create({
      mode: 'payment',
      line_items: [
        {
          price_data: {
            currency: 'USD',
            product_data: {
              name: 'Flutter Payment',
            },
            unit_amount: data.amount * 100,
          },
          quantity: 1,
        },
      ],
      payment_method_types: ['card'],
      success_url: 'https://www.success.com',
      cancel_url: 'https://www.cancelled.com',
      billing_address_collection: 'required',
    });

    return checkoutSession.url;
  } catch (error) {
    console.log(`error: ${error}`);
    return null;
  }
});

exports.getSubscriptionSession = functions.https.onCall(async (data) => {
  try {
    const checkoutSession = await stripe.checkout.sessions.create({
      mode: 'subscription',
      line_items: [
        {
          price_data: {
            currency: 'USD',
            product_data: {
              name: 'Flutter Subscription',
            },
            recurring: {
              interval: 'month',
              interval_count: 1,
            },
            unit_amount: data.amount * 100,
          },
          quantity: 1,
        },
      ],
      payment_method_types: ['card'],
      success_url: 'https://www.success.com',
      cancel_url: 'https://www.cancelled.com',
      billing_address_collection: 'required',
    });

    return checkoutSession.url;
  } catch (error) {
    console.log(`error: ${error}`);
    return null;
  }
});
```

We need to use WebView to be able to use the Stripe Checkout as it is not yet implemented for Flutter.

Install all the required packages:

```yml
webview_flutter: ^2.1.2
firebase_core: '^1.10.0'
cloud_functions: '^3.1.1'
```

Now into the Flutter Side:

```dart
// main.dart
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


    // Using cloud functions to get the payment url to the payment session
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


    // Open a new page with a webview
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
```

Create a `checkout_screen.dart` file with the following content:

```dart
// checkout_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CheckoutScreen extends StatefulWidget {
  final String url;

  const CheckoutScreen({required this.url, Key? key}) : super(key: key);

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffFF2274),
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 32),
            child: WebView(
              initialUrl: widget.url,
              javascriptMode: JavascriptMode.unrestricted,
              onPageFinished: (url) {
                setState(() {
                  _isLoading = false;
                });
              },
              navigationDelegate: (NavigationRequest request) {
                if (request.url.startsWith('https://www.success.com')) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment Successful'),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }

                if (request.url.startsWith('https://www.cancelled.com')) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Payment Cancelled'),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 2),
                    ),
                  );
                }

                return NavigationDecision.navigate;
              },
            ),
          ),
          if (_isLoading) _loadingSpinner,
        ],
      ),
    );
  }

  Widget get _loadingSpinner {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.pink,
      child: const Center(
        child: SizedBox(
          height: 30,
          width: 30,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      ),
    );
  }
}
```

We can use [webview_flutter](https://pub.dev/packages/webview_flutter) for Card and Apple Pay payment,
but [Google Pay doesn't work with WebView](https://stackoverflow.com/a/55911231/8468530).

So, we need to use chrome custom tabs for it.

Here comes [flutter_web_browser](https://pub.dev/packages/flutter_web_browser) to the rescue.
It uses [Chrome Custom Tabs](https://developer.chrome.com/multidevice/android/customtabs) & [SFSafariViewController](https://developer.apple.com/documentation/safariservices/sfsafariviewcontroller)
under the hood so both Apple and Google Pay works with it.
