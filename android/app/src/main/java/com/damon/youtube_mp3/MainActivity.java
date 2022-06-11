package com.damon.youtube_mp3;

import io.flutter.embedding.android.FlutterActivity;
import android.os.Environment;
import androidx.annotation.NonNull;
import io.flutter.embedding.engine.FlutterEngine;
import io.flutter.plugin.common.MethodChannel;

public class MainActivity extends FlutterActivity {
    private static final String CHANNEL = "com.damon.youtube/directory";
    @Override
    public void configureFlutterEngine(@NonNull FlutterEngine flutterEngine) {
    super.configureFlutterEngine(flutterEngine);
      new MethodChannel(flutterEngine.getDartExecutor().getBinaryMessenger(), CHANNEL)
          .setMethodCallHandler(
            (call, result) -> {
              if(call.method.equals("getDowload")){
                result.success(getDownloadsDirectory());
              }else{
                result.notImplemented();
              }
            }
          );
    }

    private String getDownloadsDirectory() {
        return Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS).getAbsolutePath();
    }
}
