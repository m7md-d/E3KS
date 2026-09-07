// يقيس كلفة مستندٍ في مراحله الخمس، ويطبع صفًّا لكل ملف.
//
// **الغرض أن يُقاس ما يُقال.** «التطبيق ثقيل على الملفات الكبيرة» حكمٌ بلا
// رقم؛ وهذه الأداة تعطي الرقم مفكَّكًا فيُعرَف أين يذهب الزمن — وقد أظهرت
// أن **البوابة أغلى من التبديل نفسه** (`00` §5: لا يُسمّى سبب لم يُقَس).
//
//   dart tool/measure_document.dart <ملف.docx> [ملفات أخرى…]
//
// ولذروة الذاكرة، لكل ملفٍّ عمليّته:
//   /usr/bin/time -l dart tool/measure_document.dart <ملف>

import 'dart:io';
import 'dart:typed_data';

import 'package:e3ks_engine/e3ks_engine.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('الاستعمال: measure_document.dart <ملف.docx> …');
    exit(64);
  }

  for (final path in args) {
    final bytes = Uint8List.fromList(File(path).readAsBytesSync());

    final watch = Stopwatch()..start();
    final opened = DocumentPackage.open(bytes);
    if (opened case Failed(:final issues)) {
      stdout.writeln('${_name(path)} | سقط: ${issues.first.code.name}');
      continue;
    }
    final package = (opened as Ok<DocumentPackage>).value;
    final open = watch.elapsedMilliseconds;

    final format = (formatFor(package) as Ok<DocumentFormat>).value;

    watch.reset();
    final report = (format.inspect(package) as Ok<InspectionReport>).value;
    final inspect = watch.elapsedMilliseconds;

    watch.reset();
    final preview = format.preview(package);
    final previewMs = watch.elapsedMilliseconds;
    final truncated = preview.sections.any((s) => s.truncated);
    final blocks = preview.sections.fold(
      0,
      (sum, section) => sum + section.blocks.length,
    );

    // خطّة واقعية: ثلاثة ألوان وخطّان — لا خطّة فارغة تتخطّى العمل كلّه.
    final plan = StylePlan(
      colors: {
        for (final usage in report.contentColors.take(3))
          // `!` مضمون: نصٌّ ثابت بصيغة `#RRGGBB`.
          usage.color: HexColor.tryParse('#0F3D3E')!,
      },
      fonts: const FontPlan(latin: 'Inter', arabic: 'Cairo'),
    );

    watch.reset();
    format.transform(package, plan);
    final transform = watch.elapsedMilliseconds;

    // البوابتان مفصولتان: المشتركة تحلّل كل جزء ممسوس، وبوابة الصيغة
    // تحلّله **مرّةً ثانية**. الفصل هنا هو ما يُظهر ثمن التكرار.
    watch.reset();
    final shared = checkPackage(package);
    final gateShared = watch.elapsedMilliseconds;

    watch.reset();
    final specific = format.validate(package);
    final gateFormat = watch.elapsedMilliseconds;

    watch.reset();
    package.build();
    final build = watch.elapsedMilliseconds;

    stdout.writeln(
      '${_name(path)} | فتح ${open}ms | فحص ${inspect}ms | '
      'معاينة ${previewMs}ms (${preview.pageCount}ص${truncated ? "+" : ""}، '
      '$blocks كتلة) | تبديل ${transform}ms | '
      'بوابة $gateShared+${gateFormat}ms | بناء ${build}ms | '
      'عوائق ${shared.length + specific.length} | '
      'ذاكرة ${(ProcessInfo.currentRss / 1e6).round()}MB',
    );
  }
}

String _name(String path) => path.split(Platform.pathSeparator).last;
