// lib/screens/scan_screen.dart
import 'package:brief_ai/localization/app_localizations.dart';
import 'package:brief_ai/widgets/glass_card.dart';
import 'package:flutter/material.dart';

class ScanScreen extends StatelessWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Camera preview placeholder
            Container(
              color: Colors.black,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.document_scanner,
                      size: 80,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.tr(context, 'cameraPreview'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Edge detection overlay
            CustomPaint(
              painter: EdgeDetectionPainter(primaryColor),
              child: Container(),
            ),
            
            // Top bar
            Positioned(
              top: 20,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.flash_on,
                          color: Colors.white,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          AppLocalizations.tr(context, 'auto'),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom control panel
            Positioned(
              bottom: 30,
              left: 20,
              right: 20,
              child: GlassCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildControlButton(context, Icons.auto_awesome, AppLocalizations.tr(context, 'auto')),
                        _buildControlButton(context, Icons.crop, AppLocalizations.tr(context, 'crop')),
                        _buildControlButton(context, Icons.color_lens, AppLocalizations.tr(context, 'filter')),
                        _buildControlButton(context, Icons.rotate_right, AppLocalizations.tr(context, 'rotate')),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.photo_library,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            _showImagePickerOptions(context);
                          },
                        ),
                        Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor,
                              width: 3,
                            ),
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.camera_alt,
                              color: primaryColor,
                              size: 30,
                            ),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(AppLocalizations.tr(context, 'capturingImage')),
                                  backgroundColor: primaryColor,
                                ),
                              );
                            },
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.description_outlined,
                            color: Colors.white,
                            size: 28,
                          ),
                          onPressed: () {
                            _showMultiPageOptions(context);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${AppLocalizations.tr(context, 'multiPage')}: 2 ${AppLocalizations.tr(context, 'pages')}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(BuildContext context, IconData icon, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 12),
        ),
      ],
    );
  }

  void _showImagePickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(AppLocalizations.tr(context, 'chooseFromGallery')),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.tr(context, 'openingGallery')),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(AppLocalizations.tr(context, 'takeNewPhoto')),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.tr(context, 'openingCamera')),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showMultiPageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: Text(AppLocalizations.tr(context, 'addPage')),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.remove),
              title: Text(AppLocalizations.tr(context, 'removePage')),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.done_all),
              title: Text(AppLocalizations.tr(context, 'finishMultiPage')),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class EdgeDetectionPainter extends CustomPainter {
  final Color edgeColor;

  EdgeDetectionPainter(this.edgeColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = edgeColor.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final path = Path();
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.8,
      height: size.height * 0.5,
    );

    path.addRect(rect);
    canvas.drawPath(path, paint);

    // Draw corner markers
    final cornerPaint = Paint()
      ..color = edgeColor
      ..strokeWidth = 3;

    final corners = [
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.top),
      Offset(rect.left, rect.bottom),
      Offset(rect.right, rect.bottom),
    ];

    for (var corner in corners) {
      canvas.drawLine(
        corner - const Offset(15, 0),
        corner + const Offset(15, 0),
        cornerPaint,
      );
      canvas.drawLine(
        corner - const Offset(0, 15),
        corner + const Offset(0, 15),
        cornerPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}