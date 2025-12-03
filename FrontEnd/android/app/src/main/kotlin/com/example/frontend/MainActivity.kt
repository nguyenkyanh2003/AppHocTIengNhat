package com.example.frontend

import io.flutter.embedding.android.FlutterActivity
import android.view.WindowManager

class MainActivity : FlutterActivity() {
    override fun onResume() {
        super.onResume()
        // Fix for Vietnamese keyboard input
        window.setSoftInputMode(WindowManager.LayoutParams.SOFT_INPUT_ADJUST_RESIZE)
    }
}
