import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

TableCell createHeader(String cellText) {
  return _createStyledCell(cellText, const TextStyle(fontWeight: FontWeight.bold));
}

TableCell createCell(String cellText) {
  return _createStyledCell(cellText, null);
}

TableCell _createStyledCell(String cellText, TextStyle? cellStyle) {
  return TableCell(
    child: SizedBox(
      height: 24,
      child: Center(
        child: Text(
          cellText,
          textAlign: TextAlign.center,
          style: cellStyle,
        ),
      ),
    ),
  );
}

Widget circularProgressIndicatorWidget() {
  return const Center(
    child: SizedBox(width: 50, height: 50, child: CircularProgressIndicator()),
  );
}

String formatDate(DateTime? date) {
  String result = "";
  if (date != null) {
    result = DateFormat.yMd().format(date);
  }
  return result;
}

String formatDateTime(DateTime? date) {
  String result = "";
  if (date != null) {
    result = DateFormat.yMd().add_jm().format(date);
  }
  return result;
}
