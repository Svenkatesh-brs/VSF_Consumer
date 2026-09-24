import 'package:flutter_test/flutter_test.dart';

import 'package:vsf_consumer/models/home_model.dart';

void main() {
  group('HomeLoan EMI counts', () {
    Map<String, dynamic> loanJson([Map<String, dynamic>? overrides]) {
      return {
        'id': 'l1',
        'loanNo': '2AP-NV-25-00001',
        'totalEMICount': 12,
        'paidEMICount': 6,
        'upcomingEMICount': 3,
        'overDueEMICount': 3,
        ...?overrides,
      };
    }

    test('parses integer EMI counts', () {
      final loan = HomeLoan.fromJson(loanJson());

      expect(loan.totalEMICount, 12);
      expect(loan.paidEMICount, 6);
      expect(loan.upcomingEMICount, 3);
      expect(loan.overDueEMICount, 3);
    });

    test('parses numeric-string EMI counts', () {
      final loan = HomeLoan.fromJson(
        loanJson({
          'totalEMICount': '12',
          'paidEMICount': '6',
          'upcomingEMICount': '3',
          'overDueEMICount': '3',
        }),
      );

      expect(loan.totalEMICount, 12);
      expect(loan.paidEMICount, 6);
      expect(loan.upcomingEMICount, 3);
      expect(loan.overDueEMICount, 3);
    });

    test(
      'defaults to 0 when counts are missing or null (backward compatible)',
      () {
        final loan = HomeLoan.fromJson(
          loanJson({'totalEMICount': null})..remove('overDueEMICount'),
        );

        expect(loan.totalEMICount, 0);
        expect(loan.paidEMICount, 6);
        expect(loan.overDueEMICount, 0);
      },
    );

    test('guarantor-style response parses into a loadable loan list', () {
      final json = {
        'success': true,
        'message': 'Successfully got consumer information',
        'page': 1,
        'recordsPerPage': 10,
        'total': 1,
        'data': {
          'id': 'c1',
          'cifId': 'abc',
          'firstName': 'Ravi',
          'lastName': 'Kumar',
          'loans': [
            loanJson({
              'status': 1,
              'loanSchemes': [
                {'emi': 1500, 'noOfInstallments': 12},
              ],
              'principalAmount': 15000,
              'loanAmount': 18000,
              'totalEMIPaid': 9000,
              'totalLpcReceived': 920,
              'lead': {
                'branch': {'id': 'b1', 'name': 'PAYAKARAOPETA'},
                'borrowers': [
                  {
                    'id': 'b1',
                    'relation': 'Self',
                    'consumer': {'firstName': 'Ravi', 'lastName': 'Kumar'},
                  },
                ],
                'guarantors': [
                  {
                    'id': 'g1',
                    'relation': 'Sister',
                    'consumer': {'firstName': 'Priya', 'lastName': 'Devi'},
                  },
                ],
              },
            }),
          ],
        },
      };

      final response = HomeResponse.fromJson(json);

      expect(response.success, isTrue);

      final loans = response.data!.loans;
      expect(loans, hasLength(1));

      final loan = loans.first;
      expect(loan.displayStatus, 'Active');
      expect(loan.lead?.branch?.name, 'PAYAKARAOPETA');
      expect(loan.borrowerNames, contains('Ravi Kumar'));
      expect(loan.lead?.guarantors.single.relation, 'Sister');
      expect(loan.guarantorNames, contains('Priya Devi'));
      expect(loan.totalEMICount, 12);
      expect(loan.paidEMICount, 6);
      expect(loan.upcomingEMICount, 3);
      expect(loan.overDueEMICount, 3);
    });

    test('prefers fullName over nested consumer names', () {
      final json = {
        'success': true,
        'message': 'Successfully got consumer information',
        'data': {
          'loans': [
            loanJson({
              'lead': {
                'borrowers': [
                  {
                    'id': 'b1',
                    'relation': 'Self',
                    'fullName': 'GEMMELA KESHAVARAO',
                    'consumer': {'firstName': 'Ravi', 'lastName': 'Kumar'},
                  },
                ],
                'guarantors': [
                  {
                    'id': 'g1',
                    'relation': 'Sister',
                    'fullName': 'GOLLAPALLI NAGESWARI DEVI',
                    'consumer': {'firstName': 'Priya', 'lastName': 'Devi'},
                  },
                ],
              },
            }),
          ],
        },
      };

      final response = HomeResponse.fromJson(json);
      final loan = response.data!.loans.first;

      expect(loan.borrowerNames, contains('GEMMELA KESHAVARAO'));
      expect(loan.guarantorNames, contains('GOLLAPALLI NAGESWARI DEVI'));
    });

    test('falls back to nested consumer names when fullName is empty', () {
      final json = {
        'success': true,
        'message': 'Successfully got consumer information',
        'data': {
          'loans': [
            loanJson({
              'lead': {
                'borrowers': [
                  {
                    'id': 'b1',
                    'relation': 'Self',
                    'fullName': null,
                    'consumer': {'firstName': 'Ravi', 'lastName': 'Kumar'},
                  },
                ],
                'guarantors': [
                  {
                    'id': 'g1',
                    'relation': 'Sister',
                    'consumer': {'firstName': 'Priya', 'lastName': 'Devi'},
                  },
                ],
              },
            }),
          ],
        },
      };

      final response = HomeResponse.fromJson(json);
      final loan = response.data!.loans.first;

      expect(loan.borrowerNames, contains('Ravi Kumar'));
      expect(loan.guarantorNames, contains('Priya Devi'));
    });
  });
}
