import 'package:diagnosify/theme/app_color.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:io';
import 'package:printing/printing.dart';

class DiseaseDetectionPage extends StatefulWidget {
  final bool isBrainTumor;
  final double confidence;
  final String imagePath;
  final String predictedClass;
  final Map<String, String> probabilities;

  const DiseaseDetectionPage({
    required this.isBrainTumor,
    required this.confidence,
    required this.imagePath,
    required this.predictedClass,
    required this.probabilities,
    super.key,
  });

  @override
  State<DiseaseDetectionPage> createState() => _DiseaseDetectionPageState();
}

class _DiseaseDetectionPageState extends State<DiseaseDetectionPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String getTumorType() {
    switch (widget.predictedClass.toLowerCase()) {
      case 'glioma':
        return 'Glioma Tumor';
      case 'meningioma':
        return 'Meningioma Tumor';
      case 'pituitary':
        return 'Pituitary Tumor';
      default:
        return 'No Tumor Detected';
    }
  }

  Future<void> generateAndDownloadPDF() async {
    setState(() => _isLoading = true);
    final pdf = pw.Document();

    // Load image
    final imageFile = File(widget.imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final image = pw.MemoryImage(imageBytes);

    // Get current date
    final now = DateTime.now();
    final dateFormat = DateFormat('MMMM d, yyyy');
    final timeFormat = DateFormat('h:mm a');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Brain MRI Analysis Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      )),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('Date: ${dateFormat.format(now)}'),
                      pw.Text('Time: ${timeFormat.format(now)}'),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DIAGNOSIS',
                      style: pw.TextStyle(
                        fontSize: 20,
                        fontWeight: pw.FontWeight.bold,
                      )),
                  pw.SizedBox(height: 10),
                  pw.Text(
                    getTumorType(),
                    style: pw.TextStyle(
                      fontSize: 18,
                      color:
                          widget.isBrainTumor ? PdfColors.red : PdfColors.green,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                      'Confidence Level: ${widget.confidence.toStringAsFixed(1)}%'),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DETAILED ANALYSIS',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      )),
                  pw.SizedBox(height: 10),
                  ...widget.probabilities.entries
                      .map((entry) => pw.Text('${entry.key}: ${entry.value}')),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Image(image, height: 200),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('OBSERVATIONS',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      )),
                  pw.SizedBox(height: 10),
                  ...getObservations().map((obs) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Text('• $obs'),
                      )),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('RECOMMENDATIONS',
                      style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                      )),
                  pw.SizedBox(height: 10),
                  ...getRecommendations().map((rec) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(vertical: 2),
                        child: pw.Text('• $rec'),
                      )),
                ],
              ),
            ),
            pw.SizedBox(height: 20),
            pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('DISCLAIMER',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      )),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    'This report is generated by an AI system and should be reviewed by a qualified healthcare professional. The results are not a substitute for professional medical advice, diagnosis, or treatment.',
                    style: const pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    // Download the PDF
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename:
          'brain_tumor_report_${DateFormat('yyyyMMdd_HHmm').format(now)}.pdf',
    );
  }

  List<String> getObservations() {
    if (widget.isBrainTumor) {
      final observations = <String>[
        'Abnormal mass detected in brain tissue',
        'Irregular shape and boundaries observed',
        'Contrast enhancement present',
      ];

      switch (widget.predictedClass.toLowerCase()) {
        case 'glioma':
          observations.addAll([
            'Infiltrative growth pattern typical of gliomas',
            'Possible presence of necrosis or cystic components',
          ]);
          break;
        case 'meningioma':
          observations.addAll([
            'Extra-axial location characteristic of meningiomas',
            'Dural tail sign may be present',
          ]);
          break;
        case 'pituitary':
          observations.addAll([
            'Located in sellar/suprasellar region',
            'Possible compression of surrounding structures',
          ]);
          break;
      }
      return observations;
    } else {
      return [
        'Normal brain tissue pattern',
        'No abnormal masses detected',
        'Regular tissue boundaries',
        'No contrast enhancement',
        'No signs of edema',
      ];
    }
  }

  List<String> getRecommendations() {
    if (widget.isBrainTumor) {
      final recommendations = <String>[
        'Immediate consultation with a neurologist',
        'Additional diagnostic imaging (MRI with contrast, CT scan)',
      ];

      switch (widget.predictedClass.toLowerCase()) {
        case 'glioma':
          recommendations.addAll([
            'Neurosurgical evaluation for potential biopsy/resection',
            'Consider molecular testing for targeted therapy',
            'Discuss radiation therapy options',
          ]);
          break;
        case 'meningioma':
          recommendations.addAll([
            'Regular monitoring of tumor size and growth rate',
            'Surgical evaluation if symptomatic',
            'Consider watchful waiting if asymptomatic',
          ]);
          break;
        case 'pituitary':
          recommendations.addAll([
            'Endocrinological evaluation',
            'Hormonal testing panel',
            'Visual field examination',
          ]);
          break;
      }
      return recommendations;
    } else {
      return [
        'Continue regular health check-ups',
        'Maintain healthy lifestyle habits',
        'Report any new neurological symptoms promptly',
        'Follow recommended screening guidelines',
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: AppColors.gradientColors,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    IconButton(
                      icon:
                          const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Brain Tumor Analysis Result',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildAnimatedResult(),
                      const SizedBox(height: 20),
                      _buildDetailedAnalysis(),
                      const SizedBox(height: 20),
                      _buildMRIImage(),
                      const SizedBox(height: 20),
                      _buildConfidenceIndicator(),
                      const SizedBox(height: 30),
                      _buildObservationsList(),
                      const SizedBox(height: 30),
                      // _buildRecommendations(),
                      const SizedBox(height: 30),
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedResult() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isBrainTumor
            ? const Color(0xFFFFEBEE)
            : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: widget.isBrainTumor ? const Color(0xffB81736) : Colors.green,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Lottie.asset(
              widget.isBrainTumor
                  ? 'assets/caringnew.json'
                  : 'assets/celebration.json',
              controller: _animationController,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            getTumorType(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color:
                  widget.isBrainTumor ? const Color(0xffB81736) : Colors.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.isBrainTumor
                ? "We understand this may be concerning. Remember, early detection and proper medical care can lead to better outcomes. You're not alone in this journey."
                : "Great news! Your brain scan appears normal. Keep up with regular check-ups!",
            style: TextStyle(
              fontSize: 16,
              color:
                  widget.isBrainTumor ? const Color(0xffB81736) : Colors.green,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedAnalysis() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detailed Analysis',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xff281537),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: widget.probabilities.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xff281537),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 16,
                        color: widget.isBrainTumor
                            ? const Color(0xffB81736)
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildMRIImage() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Image.file(
          File(widget.imagePath),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildConfidenceIndicator() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Detection Confidence',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xff281537),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: [
              LinearProgressIndicator(
                value: widget.confidence / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isBrainTumor ? const Color(0xffB81736) : Colors.green,
                ),
                minHeight: 20,
              ),
              const SizedBox(height: 10),
              Text(
                'Confidence: ${widget.confidence.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff281537),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildObservationsList() {
    final observations = getObservations();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Observations',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xff281537),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            children: observations.map((observation) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: widget.isBrainTumor
                          ? const Color(0xffB81736)
                          : Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        observation,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xff281537),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: _isLoading
              ? null // Disable button while loading
              : () async {
                  try {
                    await generateAndDownloadPDF();
                  } finally {
                    setState(() => _isLoading = false);
                  }
                },
          icon: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : const Icon(Icons.download, color: Colors.white),
          label: Text(
            _isLoading ? 'Generating PDF...' : 'Download Report',
            style: const TextStyle(color: Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xff281537),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(30),
            ),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
          ),
        ),
        if (widget.isBrainTumor) ...[
          const SizedBox(height: 15),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Treatment Information feature coming soon!'),
                ),
              );
            },
            icon: const Icon(Icons.info_outline, color: Colors.white),
            label: const Text(
              'Treatment Information',
              style: TextStyle(color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 30),
            ),
          ),
        ],
      ],
    );
  }
}
