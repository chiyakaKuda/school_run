package com.example.school_run

import io.flutter.embedding.android.FlutterFragmentActivity

// FlutterFragmentActivity, not FlutterActivity: local_auth shows the system
// biometric prompt as a fragment, and it cannot attach to a plain
// FlutterActivity. Changing this back makes authenticate() fail at runtime.
class MainActivity : FlutterFragmentActivity()
