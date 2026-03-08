import SwiftUI
import WebKit

// MARK: - Google Picker WKWebView Wrapper

/// WKWebView wrapper that loads the Google Picker JavaScript API to authorize
/// files for `drive.file` scope access. The Picker is the only mechanism that
/// grants per-file authorization for files the app didn't create.
struct GooglePickerWebView: UIViewRepresentable {
    let accessToken: String
    let apiKey: String
    let appId: String
    let preselectedFileIds: [String]?
    let onFilePicked: (String, String) -> Void  // (fileId, fileName)
    let onCancel: () -> Void
    let onError: (String) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onFilePicked: onFilePicked, onCancel: onCancel, onError: onError)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.userContentController.add(context.coordinator, name: "picker")
        config.userContentController.add(context.coordinator, name: "pickerLog")
        config.preferences.javaScriptCanOpenWindowsAutomatically = true

        // Allow inline media playback (prevents some WebView restrictions)
        config.allowsInlineMediaPlayback = true

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.backgroundColor = .clear
        webView.navigationDelegate = context.coordinator
        context.coordinator.webView = webView

        let html = buildPickerHTML(
            accessToken: accessToken,
            apiKey: apiKey,
            appId: appId,
            preselectedFileIds: preselectedFileIds
        )
        // Use a proper HTTPS base URL so Google's APIs see a valid origin
        // instead of about:blank / null which triggers CORS/security rejections
        webView.loadHTMLString(html, baseURL: URL(string: "https://picker.minilog.app"))
        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    // MARK: - HTML Builder

    private func buildPickerHTML(
        accessToken: String,
        apiKey: String,
        appId: String,
        preselectedFileIds: [String]?
    ) -> String {
        // setFileIds takes a comma-separated string of file IDs
        let fileIdsJS: String
        if let ids = preselectedFileIds, !ids.isEmpty {
            let joined = ids.joined(separator: ",")
            fileIdsJS = "'\(joined)'"
        } else {
            fileIdsJS = "null"
        }

        return """
        <!DOCTYPE html>
        <html>
        <head>
        <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
        <style>
            body { margin: 0; padding: 0; background: transparent; }
            #loading {
                display: flex; align-items: center; justify-content: center;
                flex-direction: column; gap: 8px;
                height: 100vh; font-family: -apple-system, sans-serif;
                color: #888; font-size: 16px;
            }
            #loading .spinner {
                width: 24px; height: 24px;
                border: 3px solid #ddd; border-top-color: #007AFF;
                border-radius: 50%; animation: spin 0.8s linear infinite;
            }
            @keyframes spin { to { transform: rotate(360deg); } }
            .picker-container { width: 100%; height: 100vh; }
        </style>
        </head>
        <body>
        <div id="loading">
            <div class="spinner"></div>
            <span>Loading file picker...</span>
        </div>
        <div class="picker-container" id="picker-container"></div>
        <script>
        var ACCESS_TOKEN = '\(accessToken)';
        var API_KEY = '\(apiKey)';
        var APP_ID = '\(appId)';
        var PRESELECTED_FILE_IDS = \(fileIdsJS);

        function log(msg) {
            try {
                window.webkit.messageHandlers.pickerLog.postMessage(msg);
            } catch(e) {}
        }

        // Catch unhandled JS errors
        window.onerror = function(msg, url, line, col, error) {
            log('JS error: ' + msg + ' at ' + url + ':' + line);
            window.webkit.messageHandlers.picker.postMessage({
                type: 'error',
                message: 'JavaScript error: ' + msg
            });
            return true;
        };

        function loadPickerApi() {
            log('Loading gapi script...');
            var script = document.createElement('script');
            script.src = 'https://apis.google.com/js/api.js';
            script.onload = function() {
                log('gapi loaded, loading picker module...');
                gapi.load('picker', {
                    callback: function() {
                        log('Picker module loaded');
                        createPicker();
                    },
                    onerror: function() {
                        log('Failed to load picker module');
                        window.webkit.messageHandlers.picker.postMessage({
                            type: 'error',
                            message: 'Failed to load Google Picker module. Please check your internet connection.'
                        });
                    }
                });
            };
            script.onerror = function() {
                log('Failed to load gapi script');
                window.webkit.messageHandlers.picker.postMessage({
                    type: 'error',
                    message: 'Failed to load Google API. Please check your internet connection.'
                });
            };
            document.head.appendChild(script);
        }

        function createPicker() {
            log('Creating picker with appId=' + APP_ID + ', hasToken=' + !!ACCESS_TOKEN + ', hasKey=' + !!API_KEY);

            try {
                document.getElementById('loading').style.display = 'none';

                var view = new google.picker.DocsView(google.picker.ViewId.SPREADSHEETS)
                    .setIncludeFolders(false)
                    .setSelectFolderEnabled(false)
                    .setMode(google.picker.DocsViewMode.LIST);

                if (PRESELECTED_FILE_IDS) {
                    log('Setting preselected file IDs: ' + PRESELECTED_FILE_IDS);
                    view.setFileIds(PRESELECTED_FILE_IDS);
                }

                var builder = new google.picker.PickerBuilder()
                    .addView(view)
                    .setOAuthToken(ACCESS_TOKEN)
                    .setDeveloperKey(API_KEY)
                    .setAppId(APP_ID)
                    .setCallback(pickerCallback)
                    .setTitle('Select a spreadsheet')
                    .setSize(window.innerWidth, window.innerHeight);

                var picker = builder.build();
                log('Picker built, setting visible...');
                picker.setVisible(true);
                log('Picker is visible');
            } catch(e) {
                log('Error creating picker: ' + e.message);
                window.webkit.messageHandlers.picker.postMessage({
                    type: 'error',
                    message: 'Failed to create picker: ' + e.message
                });
            }
        }

        function pickerCallback(data) {
            log('Picker callback: action=' + data.action);
            if (data.action === google.picker.Action.PICKED) {
                var doc = data.docs[0];
                log('File picked: ' + doc.id + ' / ' + doc.name);
                window.webkit.messageHandlers.picker.postMessage({
                    type: 'picked',
                    fileId: doc.id,
                    fileName: doc.name
                });
            } else if (data.action === google.picker.Action.CANCEL) {
                log('Picker cancelled');
                window.webkit.messageHandlers.picker.postMessage({
                    type: 'cancel'
                });
            }
        }

        loadPickerApi();
        </script>
        </body>
        </html>
        """
    }

    // MARK: - Coordinator

    class Coordinator: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
        let onFilePicked: (String, String) -> Void
        let onCancel: () -> Void
        let onError: (String) -> Void
        weak var webView: WKWebView?

        init(
            onFilePicked: @escaping (String, String) -> Void,
            onCancel: @escaping () -> Void,
            onError: @escaping (String) -> Void
        ) {
            self.onFilePicked = onFilePicked
            self.onCancel = onCancel
            self.onError = onError
        }

        func userContentController(
            _ userContentController: WKUserContentController,
            didReceive message: WKScriptMessage
        ) {
            // Debug logging channel
            if message.name == "pickerLog" {
                #if DEBUG
                if let msg = message.body as? String {
                    print("[GooglePicker] \(msg)")
                }
                #endif
                return
            }

            guard let body = message.body as? [String: Any],
                  let type = body["type"] as? String else { return }

            DispatchQueue.main.async { [self] in
                switch type {
                case "picked":
                    if let fileId = body["fileId"] as? String,
                       let fileName = body["fileName"] as? String {
                        onFilePicked(fileId, fileName)
                    }
                case "cancel":
                    onCancel()
                case "error":
                    let message = body["message"] as? String ?? "Unknown Picker error"
                    onError(message)
                default:
                    break
                }
            }
        }

        // Allow navigation to Google's Picker origin and catch failed navigations
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            decisionHandler(.allow)
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            #if DEBUG
            print("[GooglePicker] Navigation failed: \(error.localizedDescription)")
            #endif
            DispatchQueue.main.async { [self] in
                onError("Navigation failed: \(error.localizedDescription)")
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            #if DEBUG
            print("[GooglePicker] Provisional navigation failed: \(error.localizedDescription)")
            #endif
            // Don't report as error — the Picker loads iframes that may trigger this
        }
    }
}

// MARK: - SwiftUI Picker Sheet

/// Full-screen sheet that presents Google Picker for file authorization.
/// Use `preselectedFileIds` to pre-navigate to a specific file (deep link / 403 recovery).
/// Pass `nil` for open browsing (Find Shared Sheet).
struct GooglePickerSheet: View {
    let storageService: GoogleSheetsStorageService
    let preselectedFileIds: [String]?
    let onComplete: (String, String) -> Void  // (fileId, fileName)

    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var apiKey: String {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let key = plist["PICKER_API_KEY"] as? String else {
            return ""
        }
        return key
    }

    private var appId: String {
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let key = plist["APP_ID"] as? String else {
            return ""
        }
        return key
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if let errorMessage {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                            .symbolRenderingMode(.hierarchical)
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)

                        if errorMessage.contains("share") {
                            Text("Ask the sheet owner to share it with your Google account, then try again.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }

                        Button("Dismiss") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let token = storageService.getAccessToken(), !apiKey.isEmpty, !appId.isEmpty {
                    GooglePickerWebView(
                        accessToken: token,
                        apiKey: apiKey,
                        appId: appId,
                        preselectedFileIds: preselectedFileIds,
                        onFilePicked: { fileId, fileName in
                            HapticHelper.shared.success(enabled: true)
                            onComplete(fileId, fileName)
                            dismiss()
                        },
                        onCancel: {
                            dismiss()
                        },
                        onError: { message in
                            errorMessage = message
                        }
                    )
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundStyle(.orange)
                            .symbolRenderingMode(.hierarchical)
                        Text("Unable to load file picker. Please sign in and try again.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)

                        Button("Dismiss") {
                            dismiss()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                if isLoading && errorMessage == nil {
                    ProgressView("Loading picker...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(.ultraThinMaterial)
                        .onAppear {
                            // Auto-dismiss loading after Picker JS loads
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                isLoading = false
                            }
                        }
                }
            }
            .navigationTitle("Select Spreadsheet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(.ultraThinMaterial)
    }
}
