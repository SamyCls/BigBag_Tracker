import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/big_bag.dart';
import '../models/chargement.dart';

/// Génère le PDF du bon d'expédition pour un chargement terminé —
/// contenu : numéro du bon, date, client, camion, chauffeur,
/// liste complète des Big Bags, totaux (brut, tare, net).
class PdfBonGenerator {
  static Future<pw.Document> build({
    required Chargement chargement,
    required List<BigBag> bigBags,
  }) async {
    final doc = pw.Document();
    final fmt = NumberFormat('#,##0', 'fr_FR');
    final dateFmt = DateFormat('dd/MM/yyyy à HH:mm', 'fr_FR');

    final brut = bigBags.fold(0.0, (s, b) => s + b.poidsBrut);
    final tare = bigBags.length * BigBag.tareKg;
    final net = brut - tare;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                children: [
                  pw.Container(
                    width: 40,
                    height: 40,
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromInt(0xFF1A1D1C),
                      shape: pw.BoxShape.circle,
                    ),
                    alignment: pw.Alignment.center,
                    child: pw.Text(
                      'DR',
                      style: pw.TextStyle(
                        color: PdfColors.white,
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Delta Recycl',
                        style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      pw.Text(
                        'Recyclage PET',
                        style: const pw.TextStyle(
                          fontSize: 9,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    'Bon d\'expédition',
                    style: pw.TextStyle(
                      fontSize: 20,
                      fontStyle: pw.FontStyle.italic,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    '${chargement.bonNumero ?? "—"} · ${DateFormat('dd MMM yyyy', 'fr_FR').format(chargement.closedAt ?? DateTime.now())}',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Divider(thickness: 1.4, color: PdfColors.black),
          pw.SizedBox(height: 16),
          pw.Container(
            padding: const pw.EdgeInsets.all(14),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFFAF8F2),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 6,
              children: [
                _metaCell('CLIENT', chargement.client),
                _metaCell(
                  'DATE',
                  dateFmt.format(chargement.closedAt ?? DateTime.now()),
                ),
                _metaCell('CAMION', chargement.camion ?? '—'),
                _metaCell('CHAUFFEUR', chargement.chauffeur ?? '—'),
              ],
            ),
          ),
          pw.SizedBox(height: 20),
          pw.Table(
            border: null,
            columnWidths: const {
              0: pw.FixedColumnWidth(36),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(width: 1.4)),
                ),
                children: [
                  _th('#'),
                  _th('ID BIG BAG'),
                  _th('POIDS BRUT', alignRight: true),
                ],
              ),
              ...bigBags.asMap().entries.map((e) {
                final i = e.key;
                final bb = e.value;
                return pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(
                        width: 0.5,
                        color: PdfColors.grey400,
                      ),
                    ),
                  ),
                  children: [
                    _td('${i + 1}'),
                    _td(bb.code, bold: true),
                    _td('${fmt.format(bb.poidsBrut)} kg', alignRight: true),
                  ],
                );
              }),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF1A1D1C),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              children: [
                _totalRow('Nombre de Big Bags', '${bigBags.length}'),
                _totalRow('Poids brut total', '${fmt.format(brut)} kg'),
                _totalRow(
                  'Tare totale (3 × ${bigBags.length})',
                  '− ${fmt.format(tare)} kg',
                ),
                pw.Divider(color: PdfColor.fromInt(0xFF16A34A), thickness: 1.4),
                _totalRow('Poids net', '${fmt.format(net)} kg', big: true),
              ],
            ),
          ),
          pw.SizedBox(height: 40),
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Divider(thickness: 1),
                    pw.Text(
                      'Signature Delta Recycl',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(width: 30),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Divider(thickness: 1),
                    pw.Text(
                      'Signature transporteur',
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Center(
            child: pw.Text(
              'Bon généré automatiquement — Delta Recycl · Document généré le ${dateFmt.format(DateTime.now())}',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    );

    return doc;
  }

  static pw.Widget _metaCell(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColors.grey600,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Text(
          value,
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _th(String text, {bool alignRight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  static pw.Widget _td(
    String text, {
    bool bold = false,
    bool alignRight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: alignRight ? pw.TextAlign.right : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value, {bool big = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              color: PdfColors.white,
              fontSize: big ? 13 : 11,
            ),
          ),
          pw.Text(
            value,
            style: pw.TextStyle(
              color: big ? PdfColor.fromInt(0xFF16A34A) : PdfColors.white,
              fontSize: big ? 18 : 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
