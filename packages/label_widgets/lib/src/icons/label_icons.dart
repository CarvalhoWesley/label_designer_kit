import 'package:flutter/material.dart' show Icons;
import 'package:flutter/widgets.dart';

/// Semantic icon set for the editor's toolbar, layer panel and property
/// panel — callers reference `LabelIcons.rotate`, not `Icons.rotate_right`,
/// so the whole workspace can swap to a custom icon font later without
/// touching every call site.
abstract final class LabelIcons {
  static const IconData select = Icons.near_me_outlined;
  static const IconData move = Icons.open_with;
  static const IconData resize = Icons.aspect_ratio;
  static const IconData rotate = Icons.rotate_right;

  static const IconData group = Icons.group_work_outlined;
  static const IconData ungroup = Icons.call_split;
  static const IconData bringToFront = Icons.flip_to_front;
  static const IconData sendToBack = Icons.flip_to_back;

  static const IconData lock = Icons.lock_outline;
  static const IconData unlock = Icons.lock_open_outlined;
  static const IconData visible = Icons.visibility_outlined;
  static const IconData hidden = Icons.visibility_off_outlined;

  static const IconData undo = Icons.undo;
  static const IconData redo = Icons.redo;
  static const IconData delete = Icons.delete_outline;
  static const IconData duplicate = Icons.copy_outlined;

  static const IconData zoomIn = Icons.zoom_in;
  static const IconData zoomOut = Icons.zoom_out;
  static const IconData grid = Icons.grid_on_outlined;
  static const IconData ruler = Icons.straighten;
  static const IconData snap = Icons.push_pin_outlined;

  static const IconData textElement = Icons.text_fields;
  static const IconData barcodeElement = Icons.view_week_outlined;
  static const IconData qrCodeElement = Icons.qr_code_2_outlined;
  static const IconData imageElement = Icons.image_outlined;
  static const IconData rectangleElement = Icons.crop_square;
  static const IconData ellipseElement = Icons.circle_outlined;
  static const IconData lineElement = Icons.horizontal_rule;
  static const IconData tableElement = Icons.table_chart_outlined;
}
