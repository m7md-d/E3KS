/// حاوية مستند OOXML (ZIP) مقروءة بأمانة بايتية.
///
/// المبدأ الحاكم (`00` §١/١): كل جزء لم نعدّله فعليًا يُنسَخ كما هو.
///
/// التنفيذ يعتمد على أن `ZipEncoder` يمرّر التدفّق المضغوط الأصلي دون إعادة ضغط
/// للأجزاء التي لم تُستبدَل. لذلك لا نلمس محتوى أي جزء إلا عبر [putBytes]،
/// ونتتبّع في [touchedParts] ما مسسناه فعلًا — وهذا هو الفرق بين
/// «نسخ» و«إعادة بناء».
library;

import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../diagnostics/engine_issue.dart';
import '../diagnostics/engine_result.dart';

final class DocumentPackage {
  DocumentPackage._(this._archive, this._sourcePartCount);

  /// اسم جزء أنواع المحتوى. يجب أن يكون أول مُدخَل — `02` §1.
  static const String contentTypesPart = '[Content_Types].xml';

  final Archive _archive;
  final int _sourcePartCount;
  final Set<String> _touched = <String>{};

  /// يفتح الحاوية من بايتات الملف.
  ///
  /// [verifyChecksums] يفحص CRC لكل جزء: يكشف الملف المبتور أو التالف عند
  /// المدخل بدل أن ينفجر في منتصف المعالجة.
  static EngineResult<DocumentPackage> open(
    Uint8List bytes, {
    bool verifyChecksums = true,
  }) {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes, verify: verifyChecksums);
    } on Object catch (e) {
      return Failed([EngineIssue(code: IssueCode.notAnArchive, detail: '$e')]);
    }

    // محلّل ZIP متسامح: النصّ العادي يمرّ منه بأرشيف فارغ بدل أن يرمي خطأ.
    // نميّز الحالتين لأن الرسالة تختلف: «ليس أرشيفًا» غير «ينقصه جزء».
    if (archive.files.isEmpty) {
      return Failed([
        const EngineIssue(
          code: IssueCode.notAnArchive,
          detail: 'archive decoded with zero entries',
        ),
      ]);
    }

    final files = archive.files.where((f) => f.isFile).toList();
    if (!files.any((f) => f.name == contentTypesPart)) {
      return Failed([
        const EngineIssue(
          code: IssueCode.missingContentTypes,
          part: contentTypesPart,
        ),
      ]);
    }

    return Ok(DocumentPackage._(_contentTypesFirst(archive), files.length));
  }

  /// أسماء الأجزاء بترتيبها في الأرشيف، و`[Content_Types].xml` أولها.
  List<String> get partNames => [
    for (final f in _archive.files)
      if (f.isFile) f.name,
  ];

  /// الأجزاء التي استُبدل محتواها في هذه الجلسة. ما عداها يُنسخ كما ورد.
  Set<String> get touchedParts => Set.unmodifiable(_touched);

  bool contains(String name) => _archive.findFile(name) != null;

  /// بايتات جزء بعد فكّ الضغط، أو `null` إن لم يوجد.
  Uint8List? bytesOf(String name) {
    final file = _archive.findFile(name);
    if (file == null || !file.isFile) return null;
    return file.readBytes();
  }

  /// نصّ جزء XML. أجزاء OOXML كلها UTF-8.
  String? textOf(String name) {
    final data = bytesOf(name);
    return data == null ? null : utf8.decode(data);
  }

  /// يستبدل محتوى جزء قائم، محافظًا على موضعه في الترتيب وعلى زمن تعديله.
  ///
  /// لا يُنشئ أجزاء جديدة: إضافة جزء غير موجود تغيير في بنية المستند،
  /// وهي عملية مستقلّة لا تمرّ من هنا.
  EngineResult<void> putBytes(String name, Uint8List data) {
    final index = _archive.files.indexWhere((f) => f.name == name);
    if (index < 0) {
      return Failed([EngineIssue(code: IssueCode.partNotFound, part: name)]);
    }

    final old = _archive.files[index];
    final replacement = ArchiveFile.bytes(name, data)
      ..mode = old.mode
      ..lastModTime = old.lastModTime
      // نُبقي طريقة الضغط كما كانت — `02` §1.
      ..compression = old.compression;

    _archive.modifyAtIndex(index, replacement);
    _touched.add(name);
    return const Ok(null);
  }

  /// يستبدل محتوى جزء XML. لا تُضاف علامة BOM — Word لا يكتبها.
  EngineResult<void> putText(String name, String xml) =>
      putBytes(name, Uint8List.fromList(utf8.encode(xml)));

  /// يبني الأرشيف من جديد.
  ///
  /// يفحص ثوابت الحاوية قبل الإخراج (`02` §9، البندان ٤ و٥). دفاع في العمق:
  /// بوابة `validate` تفحص المحتوى، وهذه تفحص الوعاء.
  EngineResult<Uint8List> build() {
    final names = partNames;

    if (names.isEmpty || names.first != contentTypesPart) {
      return Failed([
        EngineIssue(
          code: IssueCode.contentTypesNotFirst,
          part: contentTypesPart,
          detail: 'first=${names.isEmpty ? "<empty>" : names.first}',
        ),
      ]);
    }

    if (names.length != _sourcePartCount) {
      return Failed([
        EngineIssue(
          code: IssueCode.partCountMismatch,
          args: {'found': names.length, 'expected': _sourcePartCount},
        ),
      ]);
    }

    try {
      return Ok(ZipEncoder().encodeBytes(_archive));
    } on Object catch (e) {
      return Failed([EngineIssue(code: IssueCode.encodeFailed, detail: '$e')]);
    }
  }
}

/// يقدّم `[Content_Types].xml` إلى أول الأرشيف، وبقيّة المُدخَلات بترتيبها.
///
/// **كاتبٌ غير Word يضعه آخِرًا**، ومستنداتٌ كثيرة تُولَّد بغير Word. وكنّا
/// نمرّر الترتيب كما ورد ثم نرفضه عند الكتابة (`02` §1)، فيتعذّر تصدير
/// المستند **أبدًا** بلا سبيل إلى إصلاحه — وقع هذا على مستند حقيقي.
///
/// والترتيب شأن الغلاف لا شأن الأجزاء: الغلاف يُعاد بناؤه في كل الأحوال،
/// وكل جزء يخرج ببايتاته كما دخل — حدّ الأمانة في
/// [`ADR 0002`](../../../../docs/adr/0002-حدود-الأمانة-البايتية.md).
/// والمُدخَلات تُنقَل كما هي، فيبقى تدفّقها المضغوط الأصلي بلا إعادة ضغط.
Archive _contentTypesFirst(Archive archive) {
  final entries = archive.files;
  final at = entries.indexWhere(
    (f) => f.name == DocumentPackage.contentTypesPart,
  );
  // 0 موضعه الصحيح، و-1 لا يقع: الفتح يرفض ما لا جزء أنواع محتوى فيه.
  if (at <= 0) return archive;

  final ordered = Archive()..comment = archive.comment;
  ordered.add(entries[at]);
  for (var i = 0; i < entries.length; i++) {
    if (i != at) ordered.add(entries[i]);
  }
  return ordered;
}
