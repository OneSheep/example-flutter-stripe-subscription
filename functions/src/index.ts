import * as functions from "firebase-functions";

import Stripe from "stripe";

const stripe = new Stripe(functions.config().stripe.testkey, {
  apiVersion: "2020-08-27",
});

// get the payment url to the payment session
exports.getPaymentSession = functions.https.onCall(async (data) => {
  try {
    const checkoutSession = await stripe.checkout.sessions.create({
      mode: "payment",
      line_items: [
        {
          price_data: {
            currency: 'USD',
            product_data: {
              name: "Flutter Payment",
            },
            unit_amount: data.amount * 100,
          },
          quantity: 1,
        },
      ],
      payment_method_types: ["card"],
      success_url: "https://www.success.com",
      cancel_url: "https://www.cancelled.com",
      billing_address_collection: "required"
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
      mode: "subscription",
      line_items: [
        {
          price_data: {
            currency: 'USD',
            product_data: {
              name: "Flutter Subscription",
            },
            recurring: {
              interval: "month",
              interval_count: 1,
            },
            unit_amount: data.amount * 100,
          },
          quantity: 1,
        },
      ],
      payment_method_types: ["card"],
      success_url: "https://www.success.com",
      cancel_url: "https://www.cancelled.com",
      billing_address_collection: "required"
    });

    return checkoutSession.url;
  } catch (error) {
    console.log(`error: ${error}`);
    return null;
  }
});