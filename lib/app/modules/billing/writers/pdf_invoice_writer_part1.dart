part of 'pdf_invoice_writer.dart';

extension _WriterTail on _Writer {
  void _hsnHeader() {
    const topH = 12.0;
    const bottomH = 12.0;
    const height = topH + bottomH;
    page.rect(_margin, y, _contentW, height, _shade);
    _box(y, height);

    // Level one: the two tax groups span their pair of columns.
    page.text(
      'HSN/SAC',
      _hsnX(0) + 5,
      y + 15,
      size: 6.2,
      bold: true,
      color: _muted,
    );
    page.textRight(
      'Taxable Value',
      _hsnX(1) + _hsnCols[1] - 5,
      y + 15,
      size: 6.2,
      bold: true,
      color: _muted,
    );
    page.textCenter(
      _igst ? 'Integrated Tax' : 'Central Tax',
      _hsnX(2) + (_hsnCols[2] + _hsnCols[3]) / 2,
      y + 8,
      size: 6.2,
      bold: true,
      color: _muted,
    );
    if (!_igst) {
      page.textCenter(
        'State Tax',
        _hsnX(4) + (_hsnCols[4] + _hsnCols[5]) / 2,
        y + 8,
        size: 6.2,
        bold: true,
        color: _muted,
      );
    }
    page.textRight(
      'Total Tax Amount',
      _right - 5,
      y + 15,
      size: 6.2,
      bold: true,
      color: _muted,
    );

    // Level two: Rate | Amount under each group.
    page.line(
      _hsnX(2),
      y + topH,
      _hsnX(_hsnCols.length - 1),
      y + topH,
      color: _rule,
      strokeWidth: 0.5,
    );
    page.textRight(
      'Rate',
      _hsnX(2) + _hsnCols[2] - 5,
      y + 21,
      size: 6,
      color: _muted,
    );
    page.textRight(
      'Amount',
      _hsnX(3) + _hsnCols[3] - 5,
      y + 21,
      size: 6,
      color: _muted,
    );
    if (!_igst) {
      page.textRight(
        'Rate',
        _hsnX(4) + _hsnCols[4] - 5,
        y + 21,
        size: 6,
        color: _muted,
      );
      page.textRight(
        'Amount',
        _hsnX(5) + _hsnCols[5] - 5,
        y + 21,
        size: 6,
        color: _muted,
      );
    }

    for (var i = 1; i < _hsnCols.length; i++) {
      _vline(_hsnX(i), y, height);
    }
    y += height;
  }

  void _hsnTable() {
    _ensure(70);
    _hsnHeader();

    const rowH = 15.0;
    for (final row in totals.hsnSummary) {
      if (y + rowH > _bottomLimit) {
        _newPage();
        _hsnHeader();
      }
      _box(y, rowH);
      for (var i = 1; i < _hsnCols.length; i++) {
        _vline(_hsnX(i), y, rowH);
      }
      page.text(
        row.hsn,
        _hsnX(0) + 5,
        y + 10,
        size: 7,
        mono: true,
        color: _ink,
      );
      void cell(int col, String value, {bool mono = true}) => page.textRight(
        value,
        _hsnX(col) + _hsnCols[col] - 5,
        y + 10,
        size: 7,
        mono: mono,
        color: _ink,
      );
      cell(1, _money(row.taxableValue));
      // Each row prints its own rate — lines can carry different rates.
      if (_igst) {
        cell(2, row.fullRateText, mono: false);
        cell(3, _money(row.igst));
      } else {
        cell(2, row.halfRateText, mono: false);
        cell(3, _money(row.cgst));
        cell(4, row.halfRateText, mono: false);
        cell(5, _money(row.sgst));
      }
      cell(_hsnCols.length - 1, _money(row.totalTax));
      y += rowH;
    }

    const totalH = 16.0;
    _ensure(totalH);
    page.rect(_margin, y, _contentW, totalH, _shade);
    _box(y, totalH);
    for (var i = 1; i < _hsnCols.length; i++) {
      _vline(_hsnX(i), y, totalH);
    }
    page.text('Total', _hsnX(0) + 5, y + 11, size: 7, bold: true, color: _ink);
    void total(int col, String value) => page.textRight(
      value,
      _hsnX(col) + _hsnCols[col] - 5,
      y + 11,
      size: 7,
      bold: true,
      mono: true,
      color: _ink,
    );
    total(1, totals.taxableTotalText);
    if (_igst) {
      total(3, totals.igstTotalText);
    } else {
      total(3, totals.cgstTotalText);
      total(5, totals.sgstTotalText);
    }
    total(_hsnCols.length - 1, totals.totalTaxText);
    y += totalH;
  }

  static String _money(double v) => formatIndian2(v);

  // ── Footer: bank + declaration | e-invoice + signatory ────────────────────
  void _footerRow() {
    final height = options.showDeclaration ? 126.0 : 100.0;
    _ensure(height);
    final splitX = _margin + _contentW * 0.56;
    _box(y, height);
    _vline(splitX, y, height);

    var cursor = y + 12;
    if (options.showBankDetails && profile.bankName.trim().isNotEmpty) {
      page.text(
        "COMPANY'S BANK DETAILS",
        _margin + 8,
        cursor,
        size: 5.8,
        color: _faint,
      );
      cursor += 11;
      for (final row in [
        ('Bank Name: ', profile.bankName),
        ('A/c No.: ', profile.accountNo),
        ('Branch & IFSC: ', profile.branchAndIfsc),
        ('UPI: ', profile.upiId),
      ]) {
        if (row.$2.trim().isEmpty) continue;
        _labelled(row.$1, row.$2, _margin + 8, cursor);
        cursor += 9.5;
      }
      cursor += 4;
    }

    if (options.showDeclaration && profile.declaration.trim().isNotEmpty) {
      page.text('DECLARATION', _margin + 8, cursor, size: 5.8, color: _faint);
      cursor += 10;
      final width = splitX - _margin - 16;
      for (final line in PdfText.wrap(
        profile.declaration,
        width,
        6.3,
      ).take(6)) {
        page.text(line, _margin + 8, cursor, size: 6.3, color: _muted);
        cursor += 8;
      }
    }

    // Right cell — e-Invoice registration, then the signatory block pinned to
    // the bottom right.
    var rightCursor = y + 12;
    if (options.showEInvoice) {
      page.text('E-INVOICE', splitX + 8, rightCursor, size: 5.8, color: _faint);
      rightCursor += 11;
      final info = bill?.eInvoice;
      if (info != null && info.isRegistered) {
        page.text('IRN', splitX + 8, rightCursor, size: 6, color: _faint);
        rightCursor += 8;
        final width = _right - splitX - 16;
        for (final line in _chunk(info.irn!, width, 6)) {
          page.text(
            line,
            splitX + 8,
            rightCursor,
            size: 6,
            mono: true,
            color: _ink,
          );
          rightCursor += 7.5;
        }
        if ((info.ackNo ?? '').isNotEmpty) {
          _labelled('Ack No.: ', info.ackNo!, splitX + 8, rightCursor);
          rightCursor += 9;
        }
        if (info.ackDate != null) {
          _labelled(
            'Ack Date: ',
            _date(info.ackDate!),
            splitX + 8,
            rightCursor,
          );
        }
      } else {
        // No IRP integration exists, so the document says so rather than
        // showing a registration number it does not have.
        page.text(
          'Not registered with the IRP',
          splitX + 8,
          rightCursor,
          size: 6.5,
          color: _faint,
        );
        rightCursor += 9;
        if (options.showUpiQr && profile.upiId.trim().isNotEmpty) {
          page.text(
            'UPI QR: pay to ${profile.upiId}',
            splitX + 8,
            rightCursor,
            size: 6.5,
            color: _faint,
          );
        }
      }
    }

    final signBase = y + height - 10;
    page.textRight(
      'for $sellerName',
      _right - 8,
      signBase - 46,
      size: 7.5,
      bold: true,
      color: _ink,
    );

    // The uploaded signature goes in the whitespace a hand-signed invoice
    // leaves between the company line and the rule — scaled to fit that gap
    // rather than to its own size, so a big scan cannot push the rule off.
    final sign = signature;
    if (sign != null && signatureSlot >= 0) {
      const boxW = 130.0;
      const boxH = 30.0;
      final scale = (boxW / sign.width) < (boxH / sign.height)
          ? boxW / sign.width
          : boxH / sign.height;
      final w = sign.width * scale;
      final h = sign.height * scale;
      page.image(
        signatureSlot,
        _right - 8 - w,
        signBase - 40 + (boxH - h),
        w,
        h,
      );
    }

    page.line(
      _right - 150,
      signBase - 8,
      _right - 8,
      signBase - 8,
      color: _faint,
      strokeWidth: 0.5,
    );
    page.textRight(
      'Authorised Signatory',
      _right - 8,
      signBase,
      size: 6.4,
      color: _faint,
    );
    y += height;
  }

  /// Splits a long unbroken token (an IRN hash) into lines that fit [width].
  List<String> _chunk(String value, double width, double size) {
    final perLine = (width / (0.6 * size)).floor().clamp(8, 200);
    final lines = <String>[];
    for (var i = 0; i < value.length; i += perLine) {
      lines.add(value.substring(i, (i + perLine).clamp(0, value.length)));
    }
    return lines.take(3).toList();
  }

  void _footNote() {
    _ensure(16);
    page.textCenter(
      '${profile.footerNote} · Generated by Godaam',
      _pageW / 2,
      y + 11,
      size: 6.2,
      color: _faint,
    );
    y += 16;
  }

  void _pageNumbers(String generatedLine) {
    for (var i = 0; i < doc.pages.length; i++) {
      final p = doc.pages[i];
      final base = _pageH - 10;
      p.text(generatedLine, _margin, base, size: 5.8, color: _faint);
      p.textRight(
        'Page ${i + 1} of ${doc.pages.length}',
        _right,
        base,
        size: 5.8,
        color: _faint,
      );
    }
  }

  static String _date(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day.toString().padLeft(2, '0')}-${months[d.month - 1]}-${d.year}';
  }
}
