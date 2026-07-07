import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:resqboxvendor/Services/api.dart';

class StripeWebViewScreen extends StatefulWidget {
  final String? url;
  final String? clientSecret;
  final String? accountId;

  const StripeWebViewScreen({
    super.key,
    this.url,
    this.clientSecret,
    this.accountId,
  });

  @override
  State<StripeWebViewScreen> createState() => _StripeWebViewScreenState();
}

class _StripeWebViewScreenState extends State<StripeWebViewScreen> {
  // No loading state needed - HTML handles its own loader

  String get _embedUrl {
    final base = Api.baseUrl.endsWith('/')
        ? Api.baseUrl.substring(0, Api.baseUrl.length - 1)
        : Api.baseUrl;
    return '$base/stripe/onboarding-embed'
        '?secret=${Uri.encodeComponent(widget.clientSecret ?? "")}'
        '&key=${Uri.encodeComponent(Api.stripePublishableKey)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xffF47923),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Create Billing Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Powered by Stripe',
              style: TextStyle(
                color: Colors.white.withOpacity(0.7),
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      body: InAppWebView(
        initialUrlRequest: URLRequest(
          url: WebUri(
            widget.url != null && widget.url!.isNotEmpty
                ? widget.url!
                : _embedUrl,
          ),
        ),
        initialSettings: InAppWebViewSettings(
          javaScriptEnabled: true,
          disableDefaultErrorPage: true,
          allowUniversalAccessFromFileURLs: true,
          allowFileAccessFromFileURLs: true,
          mixedContentMode: MixedContentMode.MIXED_CONTENT_ALWAYS_ALLOW,
          useShouldInterceptRequest: true,
        ),

        // Strip CSP header from backend response
        shouldInterceptRequest: (controller, request) async {
          final urlStr = request.url.toString();
          if (urlStr.contains('onboarding-embed')) {
            try {
              final httpClient = HttpClient();
              final httpRequest = await httpClient.getUrl(Uri.parse(urlStr));
              final response = await httpRequest.close();
              final body = await consolidateHttpClientResponseBytes(response);

              final Map<String, String> headers = {};
              response.headers.forEach((name, values) {
                if (name.toLowerCase() != 'content-security-policy') {
                  headers[name] = values.join(', ');
                }
              });

              return WebResourceResponse(
                contentType: 'text/html',
                contentEncoding: 'utf-8',
                statusCode: response.statusCode,
                headers: headers,
                data: body,
              );
            } catch (e) {
              debugPrint('CSP intercept error: $e');
            }
          }
          return null;
        },

        shouldOverrideUrlLoading: (controller, navigationAction) async {
          final url = navigationAction.request.url?.toString() ?? '';

          // ✅ Block the embedded Link auth loop
          if (url.contains('embedded/loading') &&
              url.contains('link_type=embedded_auth')) {
            controller.goBack();
            return NavigationActionPolicy.CANCEL;
          }

          // Allow all Stripe domains
          if (url.contains('stripe.com') ||
              url.contains('stripecdn.com') ||
              url.contains('stripe.network')) {
            return NavigationActionPolicy.ALLOW;
          }

          // Handle exit
          if (url.startsWith('resqboxvendor://') || url.contains('success')) {
            Navigator.pop(context, true);
            return NavigationActionPolicy.CANCEL;
          }

          return NavigationActionPolicy.ALLOW;
        },
      ),
    );
  }
}
