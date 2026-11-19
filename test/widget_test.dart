import 'package:flutter_test/flutter_test.dart';
import 'package:sales_crm_dialer/main.dart';

void main() {
  testWidgets('App initializes test', (WidgetTester tester) async {
    expect(const SalesCrmApp(), isNotNull);
  });
}
