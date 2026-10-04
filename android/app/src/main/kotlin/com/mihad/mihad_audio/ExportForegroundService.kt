package com.mihad.mihad_audio

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.IBinder

class ExportForegroundService : Service() {
    companion object {
        private const val CHANNEL_ID = "mihad_audio_export"
        private const val NOTIFICATION_ID = 2001
        private const val ACTION_START = "com.mihad.mihad_audio.export.START"
        private const val ACTION_UPDATE = "com.mihad.mihad_audio.export.UPDATE"
        private const val ACTION_FINISH = "com.mihad.mihad_audio.export.FINISH"
        private const val EXTRA_PROGRESS = "progress"
        private const val EXTRA_STATUS = "status"

        fun start(context: Context) {
            val intent = Intent(context, ExportForegroundService::class.java).apply {
                action = ACTION_START
            }
            startServiceCompat(context, intent)
        }

        fun update(context: Context, progress: Int) {
            val intent = Intent(context, ExportForegroundService::class.java).apply {
                action = ACTION_UPDATE
                putExtra(EXTRA_PROGRESS, progress.coerceIn(0, 100))
            }
            startServiceCompat(context, intent)
        }

        fun finish(context: Context, status: String) {
            val intent = Intent(context, ExportForegroundService::class.java).apply {
                action = ACTION_FINISH
                putExtra(EXTRA_STATUS, status)
            }
            startServiceCompat(context, intent)
        }

        private fun startServiceCompat(context: Context, intent: Intent) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
        }
    }

    private var foregroundStarted = false

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        ensureNotificationChannel()
        when (intent?.action) {
            ACTION_START -> startForegroundNotification(0)
            ACTION_UPDATE -> {
                val progress = intent.getIntExtra(EXTRA_PROGRESS, 0).coerceIn(0, 100)
                if (!foregroundStarted) {
                    startForegroundNotification(progress)
                } else {
                    notificationManager().notify(
                        NOTIFICATION_ID,
                        buildNotification("Exporting video", progress, ongoing = true),
                    )
                }
            }
            ACTION_FINISH -> {
                val status = intent.getStringExtra(EXTRA_STATUS) ?: "complete"
                val text = when (status) {
                    "failed" -> "Export failed"
                    "cancelled" -> "Export cancelled"
                    else -> "Export complete"
                }
                notificationManager().notify(
                    NOTIFICATION_ID,
                    buildNotification(text, null, ongoing = false),
                )
                stopForegroundCompat()
                foregroundStarted = false
                stopSelf(startId)
            }
            else -> startForegroundNotification(0)
        }
        return START_NOT_STICKY
    }

    private fun startForegroundNotification(progress: Int) {
        val notification = buildNotification("Exporting video", progress.coerceIn(0, 100), ongoing = true)
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                startForeground(
                    NOTIFICATION_ID,
                    notification,
                    ServiceInfo.FOREGROUND_SERVICE_TYPE_DATA_SYNC,
                )
            } else {
                startForeground(NOTIFICATION_ID, notification)
            }
            foregroundStarted = true
        } catch (_: Exception) {
            // If Android refuses foreground start (for example due to device
            // policy), keep export alive in-app and avoid crashing the user.
            notificationManager().notify(NOTIFICATION_ID, notification)
        }
    }

    private fun buildNotification(text: String, progress: Int?, ongoing: Boolean): Notification {
        val launchIntent = packageManager.getLaunchIntentForPackage(packageName)
            ?: Intent(this, MainActivity::class.java)
        val pendingIntent = PendingIntent.getActivity(
            this,
            0,
            launchIntent,
            PendingIntent.FLAG_UPDATE_CURRENT or immutableFlag(),
        )
        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }
        builder
            .setSmallIcon(R.mipmap.ic_launcher)
            .setContentTitle("MIHAD AUDIO")
            .setContentText(text)
            .setContentIntent(pendingIntent)
            .setOnlyAlertOnce(true)
            .setOngoing(ongoing)
            .setAutoCancel(!ongoing)
            .setShowWhen(false)
        if (progress != null) {
            builder.setProgress(100, progress.coerceIn(0, 100), false)
        } else {
            builder.setProgress(0, 0, false)
        }
        return builder.build()
    }

    private fun ensureNotificationChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val channel = NotificationChannel(
            CHANNEL_ID,
            "MIHAD AUDIO Export",
            NotificationManager.IMPORTANCE_LOW,
        ).apply {
            description = "Shows video export progress"
            setShowBadge(false)
        }
        notificationManager().createNotificationChannel(channel)
    }

    private fun notificationManager(): NotificationManager =
        getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    private fun immutableFlag(): Int =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) PendingIntent.FLAG_IMMUTABLE else 0

    private fun stopForegroundCompat() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            stopForeground(STOP_FOREGROUND_DETACH)
        } else {
            @Suppress("DEPRECATION")
            stopForeground(false)
        }
    }
}
