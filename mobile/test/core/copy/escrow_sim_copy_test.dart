import 'package:flutter_test/flutter_test.dart';
import 'package:sakuskill/core/copy/escrow_sim_copy.dart';
import 'package:sakuskill/core/domain/status.dart';

void main() {
  final proposals = <String>[
    EscrowSimCopy.disclaimer,
    EscrowSimCopy.disclaimerShort,
    EscrowSimCopy.heldNote,
    EscrowSimCopy.bannerTitle,
    EscrowSimCopy.bannerBody,
    EscrowSimCopy.paymentTitle,
    EscrowSimCopy.payCta('Rp 150.000'),
    EscrowSimCopy.releasedNote('Salma'),
    EscrowSimCopy.complaintNote,
  ];

  test('usulan copy K-02 tidak memakai istilah penahanan uang nyata', () {
    final banned = RegExp(
      r'rekening bersama|penampungan|kunci dana|membekukan|dibekukan|'
      r'dicairkan|diteruskan ke|diamankan',
      caseSensitive: false,
    );
    for (final text in proposals) {
      expect(banned.hasMatch(text), isFalse, reason: text);
    }
  });

  test('keterangan status dana menyebut simulasi (FR-59)', () {
    for (final text in [
      EscrowSimCopy.disclaimer,
      EscrowSimCopy.disclaimerShort,
      EscrowSimCopy.heldNote,
      EscrowSimCopy.bannerBody,
      EscrowSimCopy.releasedNote('Salma'),
      EscrowSimCopy.complaintNote,
    ]) {
      expect(text.toLowerCase(), contains('simulasi'), reason: text);
    }
    expect(EscrowSimCopy.heldNote, contains(EscrowSimStatus.held.label));
  });
}
