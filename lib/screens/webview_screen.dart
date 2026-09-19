import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../services/auth_service.dart';
import '../config/app_config.dart';

class WebViewScreen extends StatefulWidget {
  const WebViewScreen({super.key});

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> with WidgetsBindingObserver {
  late WebViewController _controller;
  final AuthService _auth = AuthService();
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  int _loadProgress = 0;
  DateTime? _lastBackPressed;
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initWebView();
    _listenConnectivity();
  }

  void _listenConnectivity() {
    _connectivitySub = _connectivity.onConnectivityChanged.listen((result) {
      if (result != ConnectivityResult.none && _hasError) {
        _reload();
      }
    });
  }

  void _initWebView() {
    final params = WebViewWidgetCreationParams(
      platform: WebKitWebViewPlatform(),
      webViewController: WebViewController(
        onNavigationRequest: _onNavigationRequest,
      ),
    );
    _controller = WebViewController(params: params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF071126))
      ..setUserAgent(_buildUserAgent())
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: _onPageStarted,
        onPageFinished: _onPageFinished,
        onProgress: (p) => setState(() => _loadProgress = p),
        onWebResourceError: _onWebResourceError,
      ));

    _loadUrl();
  }

  String _buildUserAgent() {
    return 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) '
        'Beta/1.0.0 Mobile/15E148 Safari/604.1 '
        'BetaApp-iOS/1.0.0';
  }

  void _loadUrl() async {
    final token = _auth.sessionToken;
    final url = AppConfig.serverUrl;

    if (token != null) {
      await _controller.loadFlutterAsset('assets/inject_session.html');
      await Future.delayed(const Duration(milliseconds: 200));
    }

    await _controller.loadRequest(
      Uri.parse('$url/app'),
      headers: {
        'Authorization': 'Bearer ${token ?? ''}',
        'X-Client': 'ios',
      },
    );
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final url = request.url;

    if (url.contains('auth/google') ||
        url.contains('auth/microsoft') ||
        url.contains('auth/apple')) {
      return NavigationDecision.navigate;
    }

    if (url.startsWith('tel:') ||
        url.startsWith('mailto:') ||
        url.startsWith('sms:')) {
      return NavigationDecision.navigate;
    }

    if (!url.startsWith(AppConfig.serverUrl) &&
        !url.startsWith('file://') &&
        !url.contains('socket.io') &&
        !url.contains('googleapis.com')) {
      return NavigationDecision.navigate;
    }

    return NavigationDecision.navigate;
  }

  void _onPageStarted(String url) {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
    }
  }

  void _onPageFinished(String url) async {
    if (!mounted) return;

    await _injectSessionData();
    await _injectMobileStyles();
    await _injectFileChooserHandler();
    await _injectPushNotificationSetup();

    if (mounted) {
      setState(() {
        _isLoading = false;
        _loadProgress = 0;
      });
    }
  }

  void _onWebResourceError(WebResourceError error) {
    if (mounted) {
      setState(() {
        _hasError = true;
        _errorMessage = error.description;
        _isLoading = false;
      });
    }
  }

  Future<void> _injectSessionData() async {
    final token = _auth.sessionToken;
    final user = _auth.currentUser;
    if (token == null) return;

    final userJson = user != null ? jsonEncode(user) : '{}';
    await _controller.runJavaScript('''
      try {
        localStorage.setItem('beta_session_token', '$token');
        localStorage.setItem('beta_user', '$userJson');
      } catch(e) { console.log('session inject error:', e); }
    ''');
  }

  Future<void> _injectMobileStyles() async {
    await _controller.runJavaScript('''
      (function() {
        if (document.getElementById('beta-ios-styles')) return;
        const style = document.createElement('style');
        style.id = 'beta-ios-styles';
        style.textContent = \`
          * { -webkit-tap-highlight-color: transparent; }
          body { -webkit-overflow-scrolling: touch; }
          .nav-rail { display: none !important; }
          .folder-rail { display: none !important; }
          .chat-list { min-width: 100vw !important; max-width: 100vw !important; }
          .chat-panel { position: fixed !important; inset: 0 !important; z-index: 100 !important;
            transform: translateX(100vw) !important; transition: transform 0.3s ease !important; }
          .chat-panel.active { transform: translateX(0) !important; }
          .details { display: none !important; }
          .app-shell { grid-template-columns: 1fr !important; }
          .settings-screen { grid-template-columns: 1fr !important; }
          @supports (-webkit-touch-callout: none) {
            .chat-list { padding-top: env(safe-area-inset-top) !important; }
          }
          .beta-mob-back { display: inline-flex !important; align-items: center;
            justify-content: center; width: 36px; height: 36px; border-radius: 10px;
            background: rgba(255,255,255,.06); border: none; cursor: pointer;
            margin-right: 8px; flex-shrink: 0; }
          .beta-mob-back svg { width: 18px; height: 18px; fill: #fff; }
        \`;
        document.head.appendChild(style);
      })();
    ''');
  }

  Future<void> _injectFileChooserHandler() async {
    await _controller.runJavaScript('''
      (function() {
        if (window._betaIOSHandler) return;
        window._betaIOSHandler = true;
        window.openFilePicker = function(accept, multiple) {
          return new Promise((resolve) => {
            const input = document.createElement('input');
            input.type = 'file';
            input.accept = accept || '*/*';
            input.multiple = multiple || false;
            input.onchange = () => resolve(Array.from(input.files));
            input.click();
          });
        };
      })();
    ''');
  }

  Future<void> _injectPushNotificationSetup() async {
    await _controller.runJavaScript('''
      (function() {
        window._betaIsIOS = true;
        window._betaPushToken = null;
      })();
    ''');
  }

  void _reload() {
    setState(() {
      _hasError = false;
      _errorMessage = null;
    });
    _controller.reload();
  }

  Future<bool> _onWillPop() async {
    final canGoBack = await _controller.canGoBack();
    if (canGoBack) {
      _controller.goBack();
      return false;
    }

    final now = DateTime.now();
    if (_lastBackPressed != null &&
        now.difference(_lastBackPressed!) < const Duration(seconds: 2)) {
      return true;
    }

    _lastBackPressed = now;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Нажмите ещё раз для выхода'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF0D1B2A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    return false;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _controller.runJavaScript('''
        if (typeof window.dispatchEvent === 'function') {
          window.dispatchEvent(new Event('focus'));
        }
      ''');
      _auth.sendHeartbeat();
    } else if (state == AppLifecycleState.paused) {
      _auth.sendHeartbeat();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connectivitySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).maybePop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF071126),
        body: SafeArea(
          top: false,
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading && _loadProgress < 100)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Column(
                    children: [
                      LinearProgressIndicator(
                        value: _loadProgress / 100,
                        backgroundColor: const Color(0xFF0D1B2A),
                        valueColor:
                            const AlwaysStoppedAnimation(Color(0xFF4DC8F0)),
                        minHeight: 2,
                      ),
                    ],
                  ),
                ),
              if (_hasError)
                Positioned.fill(
                  child: Container(
                    color: const Color(0xFF071126),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 64,
                              color: Colors.white.withOpacity(0.15),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Нет подключения',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white.withOpacity(0.7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _errorMessage ?? 'Проверьте подключение к интернету',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.4),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _reload,
                              icon: const Icon(Icons.refresh, size: 18),
                              label: const Text('Повторить'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color(0xFF4DC8F0).withOpacity(0.15),
                                foregroundColor: const Color(0xFF4DC8F0),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
