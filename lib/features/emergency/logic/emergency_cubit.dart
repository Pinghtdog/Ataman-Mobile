import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ataman/core/services/local_storage_service.dart';
import 'package:ataman/injector.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/models/emergency_request_model.dart';
import '../data/repositories/emergency_repository.dart';
import 'emergency_state.dart';

class EmergencyCubit extends Cubit<EmergencyState> {
  final EmergencyRepository _emergencyRepository;
  StreamSubscription? _requestSubscription;
  StreamSubscription? _ambulanceSubscription;

  // Naga City Emergency Hotline (Example number, adjust as needed)
  static const String emergencyHotline = "09452235495";

  EmergencyCubit({required EmergencyRepository emergencyRepository})
      : _emergencyRepository = emergencyRepository,
        super(EmergencyInitial());

  Future<void> requestEmergency(EmergencyRequest request) async {
    emit(EmergencyLoading());

    // Check connectivity first
    final connectivityResults = await Connectivity().checkConnectivity();
    final hasNoInternet = connectivityResults.contains(ConnectivityResult.none);

    if (hasNoInternet) {
      await _handleOfflineEmergency(request);
      return;
    }

    try {
      // 1. Create the request
      final newRequest = await _emergencyRepository.createEmergencyRequest(request);
      emit(EmergencyActive(newRequest));
      _startWatchingRequest(newRequest.id);

      // 2. Automatically trigger Intelligent AI Assignment
      try {
        await _emergencyRepository.assignBestAmbulance(
          requestId: newRequest.id,
          userLat: request.latitude,
          userLong: request.longitude,
          emergencyType: request.type,
        );
      } catch (aiError) {
        print('AI Assignment failed: $aiError');
      }
      
    } catch (e) {
      // On failure (likely network), save to local queue and handle offline
      await _handleOfflineEmergency(request);
    }
  }

  Future<void> _handleOfflineEmergency(EmergencyRequest request) async {
    try {
      // Save to local queue for SyncService to pick up later
      await getIt<LocalStorageService>().savePendingEmergency(request.toJson());
      
      // Generate SMS payload
      final String payload = _generateSmsPayload(request);
      
      emit(EmergencyOffline(
        request: request,
        smsPayload: payload,
      ));
    } catch (e) {
      emit(EmergencyError("Offline error: ${e.toString()}"));
    }
  }

  String _generateSmsPayload(EmergencyRequest request) {
    // Format: ATAMAN-SOS: [TYPE] @ [LAT],[LONG] (Shortened for SMS limits)
    final type = request.type.name.toUpperCase();
    final coords = "${request.latitude.toStringAsFixed(5)},${request.longitude.toStringAsFixed(5)}";
    final time = DateTime.now().millisecondsSinceEpoch.toString().substring(7);
    return "ATAMAN SOS: $type at $coords (Ref:$time)";
  }

  Future<void> sendSmsSos(String payload) async {
    final Uri smsUri = Uri(
      scheme: 'sms',
      path: emergencyHotline,
      queryParameters: <String, String>{
        'body': payload,
      },
    );

    try {
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
      } else {
        emit(const EmergencyError("Could not launch SMS app. Please text the hotline manually."));
      }
    } catch (e) {
      emit(EmergencyError("SMS Error: ${e.toString()}"));
    }
  }

  void _startWatchingRequest(String requestId) {
    _requestSubscription?.cancel();
    _requestSubscription = _emergencyRepository.watchEmergencyRequest(requestId).listen(
      (request) {
        if (request != null) {
          final currentState = state;
          if (currentState is EmergencyActive) {
             emit(currentState.copyWith(request: request));
          } else {
             emit(EmergencyActive(request));
          }

          if (request.status == EmergencyStatus.completed) {
            _ambulanceSubscription?.cancel();
            emit(EmergencySuccess());
          }

          if (request.assignedAmbulanceId != null) {
             _startWatchingAmbulance(request.assignedAmbulanceId!);
          }
        }
      },
      onError: (error) {
        emit(EmergencyError(error.toString()));
      },
    );
  }

  void _startWatchingAmbulance(String ambulanceId) {
    _ambulanceSubscription?.cancel();
    _ambulanceSubscription = _emergencyRepository.watchAmbulanceLocation(ambulanceId).listen(
      (ambulance) {
        final currentState = state;
        if (currentState is EmergencyActive) {
          emit(currentState.copyWith(ambulance: ambulance));
        }
      },
      onError: (error) {
        print('Ambulance tracking error: $error');
      },
    );
  }

  Future<void> cancelRequest(String requestId) async {
    try {
      await _emergencyRepository.cancelEmergencyRequest(requestId);
      _requestSubscription?.cancel();
      _ambulanceSubscription?.cancel();
      emit(EmergencyInitial());
    } catch (e) {
      emit(EmergencyError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _requestSubscription?.cancel();
    _ambulanceSubscription?.cancel();
    return super.close();
  }
}
