package com.example.memo

import android.app.Activity
import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.Paint
import android.graphics.RectF
import android.os.Build
import android.os.Bundle
import android.os.CancellationSignal
import android.os.ParcelFileDescriptor
import android.print.PageRange
import android.print.PrintAttributes
import android.print.PrintDocumentAdapter
import android.print.PrintDocumentInfo
import android.print.PrintManager
import android.print.pdf.PrintedPdfDocument
import java.io.FileOutputStream
import kotlin.math.min

/**
 * 把 Flutter 端渲染好的页面图片（PNG）交给安卓系统打印框架。
 *
 * 系统打印界面负责列出局域网中的打印机（由手机上的打印服务发现）、预览、
 * 选择份数等；这里默认纸张为 A4 纵向、黑白、双面，每张图片等比缩放后居中放在一页上。
 */
class PageImagePrinter(private val activity: Activity) {

    fun print(jobName: String, pages: List<ByteArray>) {
        val printManager = activity.getSystemService(Context.PRINT_SERVICE) as PrintManager
        val builder = PrintAttributes.Builder()
            .setMediaSize(PrintAttributes.MediaSize.ISO_A4)
            .setColorMode(PrintAttributes.COLOR_MODE_MONOCHROME)
        // 默认双面（长边翻转）打印；打印机不支持时系统会退回单面，用户也可在打印界面修改
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            builder.setDuplexMode(PrintAttributes.DUPLEX_MODE_LONG_EDGE)
        }
        printManager.print(jobName, Adapter(jobName, pages), builder.build())
    }

    private inner class Adapter(
        private val jobName: String,
        private val pages: List<ByteArray>,
    ) : PrintDocumentAdapter() {

        private var attributes: PrintAttributes? = null

        override fun onLayout(
            oldAttributes: PrintAttributes?,
            newAttributes: PrintAttributes,
            cancellationSignal: CancellationSignal?,
            callback: LayoutResultCallback,
            extras: Bundle?,
        ) {
            if (cancellationSignal?.isCanceled == true) {
                callback.onLayoutCancelled()
                return
            }
            attributes = newAttributes
            val info = PrintDocumentInfo.Builder("$jobName.pdf")
                .setContentType(PrintDocumentInfo.CONTENT_TYPE_DOCUMENT)
                .setPageCount(pages.size)
                .build()
            callback.onLayoutFinished(info, newAttributes != oldAttributes)
        }

        override fun onWrite(
            pageRanges: Array<out PageRange>,
            destination: ParcelFileDescriptor,
            cancellationSignal: CancellationSignal?,
            callback: WriteResultCallback,
        ) {
            val pdf = PrintedPdfDocument(activity, attributes!!)
            try {
                for ((index, png) in pages.withIndex()) {
                    if (cancellationSignal?.isCanceled == true) {
                        callback.onWriteCancelled()
                        return
                    }
                    // 只写入系统请求的页（例如预览时只请求可见页）
                    if (pageRanges.none { index in it.start..it.end }) continue

                    val page = pdf.startPage(index)
                    val bitmap = BitmapFactory.decodeByteArray(png, 0, png.size)
                    val area = page.info.contentRect
                    val scale = min(
                        area.width().toFloat() / bitmap.width,
                        area.height().toFloat() / bitmap.height,
                    )
                    val width = bitmap.width * scale
                    val height = bitmap.height * scale
                    val left = area.left + (area.width() - width) / 2
                    val top = area.top + (area.height() - height) / 2
                    page.canvas.drawBitmap(
                        bitmap,
                        null,
                        RectF(left, top, left + width, top + height),
                        Paint(Paint.FILTER_BITMAP_FLAG),
                    )
                    bitmap.recycle()
                    pdf.finishPage(page)
                }
                FileOutputStream(destination.fileDescriptor).use { pdf.writeTo(it) }
                callback.onWriteFinished(pageRanges)
            } catch (e: Exception) {
                callback.onWriteFailed(e.message)
            } finally {
                pdf.close()
            }
        }
    }
}
