class Api {
  static String baseUrl = "https://xapi.resqboxfood.com/api/";
  static String devUrl = "https://xapi.resqboxfood.com/api/";
  static String prodUrl = "https://api.resqboxfood.com/api/";
  static String stripePublishableKeyDev =
      "pk_test_51Sd6x1RmznpMJ3k9if9BJHeZnQeCxt131H5d1vRxCLI62FSbA8RQQBqDJAf0LOdg2WKDn5WrwiOrPfh8unppqV5300NvyO6dnq";
  static String stripePublishableKeyProd =
      "pk_live_51Sd6vJDKI2oRvm5afJi9lFmgqByJhPYUUkbhYAz5XNWJRTARMLzg6Tldk8t8w1Ln1nZtl8EW7fMPrM8LHafVi2fl00Ycqm3Fmc";

  // Socket URLs
  static String socketDevUrl = "https://xapi.resqboxfood.com";
  static String socketProdUrl = "https://api.resqboxfood.com";
  static String socketUrl = socketDevUrl;

  static String stripePublishableKey = stripePublishableKeyDev;
}

void setEnvironment({required Environment env}) {
  switch (env) {
    case Environment.dev:
      Api.baseUrl = Api.devUrl;
      Api.socketUrl = Api.socketDevUrl;
      Api.stripePublishableKey = Api.stripePublishableKeyDev;
      break;
    case Environment.prod:
      Api.baseUrl = Api.prodUrl;
      Api.socketUrl = Api.socketProdUrl;
      Api.stripePublishableKey = Api.stripePublishableKeyProd;
      break;
  }
}

enum Environment { dev, prod }
