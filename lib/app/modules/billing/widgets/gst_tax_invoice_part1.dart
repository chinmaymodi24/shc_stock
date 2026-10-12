part of 'gst_tax_invoice.dart';

extension _GstTaxInvoiceTail on GstTaxInvoice {
  // ── HSN-wise tax summary ──────────────────────────────────────────────────
  static const _hsnFlex = [17, 18, 11, 15, 11, 15, 13];

  Widget _hsnTable() {
    return InvoiceBox(
      bottom: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _hsnHeader(),
          for (final row in totals.hsnSummary)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: _hsnFlex[0],
                    child: InvoiceCell(
                      right: true,
                      bottom: true,
                      padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
                      child: Text(row.hsn, style: InvoicePaper.number(10.5)),
                    ),
                  ),
                  _numberCell(_money(row.taxableValue), _hsnFlex[1]),
                  // Each row prints its own rate — lines can differ.
                  if (totals.interState) ...[
                    _rateCell(row.fullRateText, _hsnFlex[2] + _hsnFlex[4]),
                    _numberCell(_money(row.igst), _hsnFlex[3] + _hsnFlex[5]),
                  ] else ...[
                    _rateCell(row.halfRateText, _hsnFlex[2]),
                    _numberCell(_money(row.cgst), _hsnFlex[3]),
                    _rateCell(row.halfRateText, _hsnFlex[4]),
                    _numberCell(_money(row.sgst), _hsnFlex[5]),
                  ],
                  _numberCell(_money(row.totalTax), _hsnFlex[6], right: false),
                ],
              ),
            ),
          _hsnTotalRow(),
        ],
      ),
    );
  }

  Widget _rateCell(String rate, int flex) => Expanded(
    flex: flex,
    child: InvoiceCell(
      right: true,
      bottom: true,
      padding: const EdgeInsets.fromLTRB(6, 7, 6, 7),
      align: CrossAxisAlignment.end,
      child: Text(
        rate,
        textAlign: TextAlign.right,
        style: InvoicePaper.text(10.5).copyWith(color: InvoicePaper.ink),
      ),
    ),
  );

  /// Two-level header: the tax groups span their Rate/Amount pair.
  Widget _hsnHeader() {
    Widget group(
      String label,
      int rateFlex,
      int amountFlex, {
      bool last = false,
    }) {
      return Expanded(
        flex: rateFlex + amountFlex,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InvoiceCell(
              right: !last,
              bottom: true,
              background: InvoicePaper.shade,
              padding: const EdgeInsets.symmetric(vertical: 5),
              align: CrossAxisAlignment.center,
              child: Text(label, style: _hsnHeadStyle),
            ),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: rateFlex,
                    child: InvoiceCell(
                      right: true,
                      bottom: true,
                      background: InvoicePaper.shade,
                      padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
                      align: CrossAxisAlignment.end,
                      child: Text('Rate', style: _hsnHeadStyle),
                    ),
                  ),
                  Expanded(
                    flex: amountFlex,
                    child: InvoiceCell(
                      right: !last,
                      bottom: true,
                      background: InvoicePaper.shade,
                      padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
                      align: CrossAxisAlignment.end,
                      child: Text('Amount', style: _hsnHeadStyle),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget tall(
      String label,
      int flex, {
      bool end = false,
      bool last = false,
    }) => Expanded(
      flex: flex,
      child: InvoiceCell(
        right: !last,
        bottom: true,
        background: InvoicePaper.shade,
        padding: const EdgeInsets.fromLTRB(8, 16, 6, 16),
        align: end ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        child: Text(
          label,
          textAlign: end ? TextAlign.right : TextAlign.left,
          style: _hsnHeadStyle,
        ),
      ),
    );

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          tall('HSN/SAC', _hsnFlex[0]),
          tall('Taxable Value', _hsnFlex[1], end: true),
          if (totals.interState)
            group(
              'Integrated Tax',
              _hsnFlex[2] + _hsnFlex[4],
              _hsnFlex[3] + _hsnFlex[5],
            )
          else ...[
            group('Central Tax', _hsnFlex[2], _hsnFlex[3]),
            group('State Tax', _hsnFlex[4], _hsnFlex[5]),
          ],
          tall('Total Tax Amount', _hsnFlex[6], end: true, last: true),
        ],
      ),
    );
  }

  static final _hsnHeadStyle = TextStyle(
    fontSize: 8.5,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: InvoicePaper.muted,
    fontFamily: InvoicePaper.body,
  );

  Widget _hsnTotalRow() => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: _hsnFlex[0],
          child: InvoiceCell(
            right: true,
            bottom: true,
            background: InvoicePaper.shade,
            padding: const EdgeInsets.fromLTRB(10, 8, 6, 8),
            child: Text('Total', style: InvoicePaper.value(11)),
          ),
        ),
        _totalCell(totals.taxableTotalText, _hsnFlex[1]),
        if (totals.interState) ...[
          _blankSpan(_hsnFlex[2] + _hsnFlex[4], background: InvoicePaper.shade),
          _totalCell(totals.igstTotalText, _hsnFlex[3] + _hsnFlex[5]),
        ] else ...[
          _blankSpan(_hsnFlex[2], background: InvoicePaper.shade),
          _totalCell(totals.cgstTotalText, _hsnFlex[3]),
          _blankSpan(_hsnFlex[4], background: InvoicePaper.shade),
          _totalCell(totals.sgstTotalText, _hsnFlex[5]),
        ],
        Expanded(
          flex: _hsnFlex[6],
          child: InvoiceCell(
            bottom: true,
            background: InvoicePaper.shade,
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
            align: CrossAxisAlignment.end,
            child: Text(
              totals.totalTaxText,
              textAlign: TextAlign.right,
              style: InvoicePaper.number(10.5, FontWeight.w700),
            ),
          ),
        ),
      ],
    ),
  );

  static String _money(double v) => formatIndian2(v);

  // ── Bank + declaration | e-invoice + signatory ────────────────────────────
  Widget _footerRow() {
    final showBank =
        options.showBankDetails && profile.bankName.trim().isNotEmpty;
    final showDeclaration =
        options.showDeclaration && profile.declaration.trim().isNotEmpty;

    return InvoiceBox(
      bottom: false,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 56,
              child: InvoiceCell(
                right: true,
                bottom: true,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showBank) ...[
                      Text(
                        "COMPANY'S BANK DETAILS",
                        style: InvoicePaper.sectionCaption(),
                      ),
                      const SizedBox(height: 4),
                      LabelledValue(
                        label: 'Bank Name',
                        value: profile.bankName,
                        mono: false,
                      ),
                      LabelledValue(label: 'A/c No.', value: profile.accountNo),
                      LabelledValue(
                        label: 'Branch & IFSC',
                        value: profile.branchAndIfsc,
                      ),
                      LabelledValue(label: 'UPI', value: profile.upiId),
                      const SizedBox(height: 10),
                    ],
                    if (showDeclaration) ...[
                      Text('DECLARATION', style: InvoicePaper.sectionCaption()),
                      const SizedBox(height: 4),
                      Text(profile.declaration, style: InvoicePaper.text(9.5)),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 44,
              child: InvoiceCell(
                bottom: true,
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (options.showEInvoice || options.showUpiQr)
                      _eInvoiceBlock(),
                    const SizedBox(height: 22),
                    _signatory(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _eInvoiceBlock() {
    final info = bill?.eInvoice;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (options.showUpiQr) ...[_qrPlaceholder(), const SizedBox(width: 12)],
        if (options.showEInvoice)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('E-INVOICE', style: InvoicePaper.sectionCaption()),
                const SizedBox(height: 4),
                if (info != null && info.isRegistered) ...[
                  Text('IRN', style: InvoicePaper.caption(9)),
                  Text(info.irn!, style: InvoicePaper.number(8.5)),
                  LabelledValue(label: 'Ack No.', value: info.ackNo ?? ''),
                  if (info.ackDate != null)
                    LabelledValue(
                      label: 'Ack Date',
                      value: GstTaxInvoice.formatDate(info.ackDate!),
                    ),
                ] else
                  // No IRP integration exists in this system, so the document
                  // says so rather than showing a registration it never got.
                  Text(
                    'Not registered with the IRP',
                    style: InvoicePaper.text(9.5),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _qrPlaceholder() => Container(
    width: 62,
    height: 62,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border.all(color: InvoicePaper.faint, width: 0.8),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.qr_code_2_rounded,
          size: 26,
          color: InvoicePaper.faint,
        ),
        const SizedBox(height: 2),
        Text('UPI QR', style: InvoicePaper.caption(7)),
      ],
    ),
  );

  Widget _signatory() => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    mainAxisSize: MainAxisSize.min,
    children: [
      Align(
        alignment: Alignment.centerRight,
        child: Text('for $sellerName', style: InvoicePaper.value(11)),
      ),
      const SizedBox(height: 6),
      // The uploaded signature, or the whitespace a pen would use. Both
      // reserve the same height so the rule sits in the same place either way.
      SizedBox(height: 34, child: _signatureImage()),
      const SizedBox(height: 4),
      Container(width: 170, height: 0.7, color: InvoicePaper.faint),
      const SizedBox(height: 4),
      Text('Authorised Signatory', style: InvoicePaper.caption(9)),
    ],
  );

  Widget _signatureImage() {
    final encoded = profile.signatureBase64;
    if (encoded == null || encoded.isEmpty) return const SizedBox.shrink();
    try {
      return Align(
        alignment: Alignment.bottomRight,
        child: Image.memory(
          base64Decode(encoded),
          // Keyed so a test can assert the signature specifically, rather than
          // matching whichever Image happens to be on the page.
          key: const ValueKey('invoice-signature'),
          height: 34,
          fit: BoxFit.contain,
          // A signature that will not decode must leave the blank space a
          // pen can still use, not a broken-image box on an invoice.
          errorBuilder: (_, _, _) => const SizedBox.shrink(),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }

  Widget _footNote() => InvoiceBox(
    child: InvoiceCell(
      padding: const EdgeInsets.symmetric(vertical: 7),
      align: CrossAxisAlignment.center,
      child: Text(
        '${profile.footerNote} · Generated by Godaam',
        style: InvoicePaper.caption(9),
      ),
    ),
  );
}
