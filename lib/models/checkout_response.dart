import '../sprint_check_method_channel.dart';

class CheckoutResponse {
  /// A user readable message. If the transaction was not successful, this returns the
  /// cause of the error.
  String message;

  String? name;

  /// Transaction reference. Might be null for failed transaction transactions
  String? reference;

  /// The confidence_level of the transaction. A successful response returns 0 to 100
  /// otherwise
  double? confidenceLevel;

  /// The confidence_level of the transaction. A successful response returns 0 to 100
  /// otherwise
  String? bvn;
  String? nin;

  /// The status of the transaction. A successful response returns true and false
  /// otherwise
  bool status;

  /// The means of payment. It may return [CheckoutMethod.bank] or [CheckoutMethod.card]
  CheckoutMethod method;

  /// If the transaction should be verified. See https://developers.Duplo.co/v2.0/reference#verify-transaction.
  /// This is usually false for transactions that didn't reach Duplo before terminating
  ///
  /// It might return true regardless whether a transaction fails or not.
  bool verify;

  CheckoutResponse.defaults()
    : message = "Enter your card details to pay",
      status = false,
      verify = false,
      method = CheckoutMethod.selectable;

  CheckoutResponse({
    required this.message,
    required this.reference,
    required this.status,
    required this.method,
    required this.name,
    required this.verify,
    required this.confidenceLevel,
    required this.bvn,
    required this.nin,
  });

  @override
  String toString() {
    return 'CheckoutResponse{message: $message,reference: $reference, status: $status, method: $method, name: $name, verify: $verify, bvn: $bvn,  nin: $nin, verify: $confidenceLevel, }';
  }
}
