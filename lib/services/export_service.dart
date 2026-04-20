import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/bead_placement.dart';

class ExportService {
  static Future<String> exportText(String instructions) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/bead_instructions.txt');
    await file.writeAsString(instructions);
    return file.path;
  }

  static Future<String> exportPdf(String instructions) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Bead Pattern Instructions')),
          pw.Text(instructions),
        ],
      ),
    );

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/bead_instructions.pdf');
    await file.writeAsBytes(await doc.save());
    return file.path;
  }

  // Optional export: write bead centers as OBJ vertices for external tooling.
  static Future<String> exportObj(Iterable<BeadPlacement> placements) async {
    final sb = StringBuffer();
    sb.writeln('# Bead centers exported as OBJ vertices');
    for (final bead in placements) {
      sb.writeln(
        'v ${bead.x.toDouble()} ${bead.y.toDouble()} ${bead.z.toDouble()}',
      );
    }

    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/bead_centers.obj');
    await file.writeAsString(sb.toString());
    return file.path;
  }
}
