import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/big_bag.dart';
import '../models/chargement.dart';
import 'pdf_bon.dart';

/// Génère le PDF du bon d'expédition et ouvre la feuille de partage
/// du système (WhatsApp, email, Drive, etc.).
Future<void> shareBon({
  required Chargement chargement,
  required List<BigBag> bigBags,
}) async {
  // 1. Build PDF bytes
  final doc = await PdfBonGenerator.build(
    chargement: chargement,
    bigBags: bigBags,
  );
  final pdfBytes = await doc.save();

  // 2. Write to a temp file
  final dir = await getTemporaryDirectory();
  final fileName = 'bon-${chargement.bonNumero ?? chargement.id}.pdf';
  final file = File('${dir.path}/$fileName');
  await file.writeAsBytes(pdfBytes);

  // 3. Open system share sheet
  await Share.shareXFiles(
    [XFile(file.path, mimeType: 'application/pdf')],
    subject: "Bon d'expédition ${chargement.bonNumero ?? ''}",
    text: "Bon d'expédition ${chargement.bonNumero ?? ''} — ${chargement.client}",
  );
}
