import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/medical_records/data/models/referral_model.dart';
import '../../features/medical_records/data/repositories/referral_repository.dart';
import 'notification_service.dart';

class ReferralStatusService {
  final ReferralRepository _referralRepository;
  StreamSubscription<List<Referral>>? _referralSubscription;
  List<Referral> _currentReferrals = [];
  bool _isFirstLoad = true;

  ReferralStatusService(this._referralRepository);

  void start() {
    // Listen for auth changes to start/stop the service
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final session = data.session;
      if (session != null) {
        _startListening(session.user.id);
      } else {
        stop();
      }
    });

    // If user is already logged in
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      _startListening(currentUser.id);
    }
  }

  void _startListening(String userId) {
    // Stop any existing listener
    _referralSubscription?.cancel();
    _isFirstLoad = true;

    _referralSubscription =
        _referralRepository.watchMyReferrals(userId).listen(
      (newReferrals) {
        if (_isFirstLoad) {
          _currentReferrals = newReferrals;
          _isFirstLoad = false;
          return;
        }

        // Detect status changes
        for (final newReferral in newReferrals) {
          final oldReferralIndex =
              _currentReferrals.indexWhere((r) => r.id == newReferral.id);

          if (oldReferralIndex != -1) {
            final oldReferral = _currentReferrals[oldReferralIndex];
            if (oldReferral.status != newReferral.status) {
              _handleStatusChange(newReferral);
            }
          }
        }

        _currentReferrals = newReferrals;
      },
      onError: (error) {
        debugPrint('Error in referral stream: \$error');
      },
    );
  }

  void _handleStatusChange(Referral referral) {
    String title = 'Referral Status Update';
    String body =
        'Your referral to \${referral.destinationFacilityName} is now \${referral.status.name.toLowerCase()}.';

    if (referral.status == ReferralStatus.ACCEPTED) {
      body =
          'Good news! Your referral to \${referral.destinationFacilityName} has been accepted.';
    } else if (referral.status == ReferralStatus.REJECTED) {
      body =
          'Your referral to \${referral.destinationFacilityName} was rejected. Please check the app for details.';
    }

    NotificationService.showSimulatedNotification(
      title: title,
      body: body,
      payload: 'referral_id=\${referral.id}',
    );
  }

  void stop() {
    _referralSubscription?.cancel();
    _currentReferrals = [];
    _isFirstLoad = true;
    debugPrint('ReferralStatusService stopped.');
  }
}
