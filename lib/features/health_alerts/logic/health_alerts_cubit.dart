import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'health_alerts_state.dart';

class HealthAlertsCubit extends Cubit<HealthAlertsState> {
  HealthAlertsCubit() : super(HealthAlertsInitial());

  // Using real news from Naga City Health Department as placeholders
  final List<Map<String, dynamic>> _allAlerts = [
    {
      'title': 'DOH, NNC launch Philippine Plan of Action for Nutrition 2023-2028',
      'description': 'The Department of Health and the National Nutrition Council officially launched the PPAN in Naga City.',
      'imageUrl': 'https://images.unsplash.com/photo-1490645935967-10de6ba17061?auto=format&fit=crop&w=800&q=80',
      'url': 'https://www2.naga.gov.ph/doh-nnc-launch-philippine-plan-of-action-for-nutrition-2023-2028/',
      'category': 'Lifestyle',
      'isNew': true,
    },
    {
      'title': 'Naga City bags Galing Pook Award for Health program',
      'description': 'Naga City has been recognized for its innovative "Naga City Health Emergency Response" initiative.',
      'imageUrl': 'https://images.unsplash.com/photo-1576091160550-2173dad99961?auto=format&fit=crop&w=800&q=80',
      'url': 'https://www2.naga.gov.ph/naga-city-bags-galing-pook-award-for-health-program/',
      'category': 'All',
      'isNew': false,
    },
    {
      'title': 'Naga Intensifies Vaccination Campaign against Measles and Polio',
      'description': 'City Health Office targets 100% coverage for children aged 0-59 months in recent Chikiting Ligtas campaign.',
      'imageUrl': 'https://images.unsplash.com/photo-1584036561566-baf8f5f1b144?auto=format&fit=crop&w=800&q=80',
      'url': 'https://www2.naga.gov.ph/naga-intensifies-vaccination-campaign-against-measles-and-polio/',
      'category': 'Vaccines',
      'isNew': false,
    },
    {
      'title': 'Mental Health Awareness Month observed in Naga City',
      'description': 'Naga City conducts various seminars and activities to promote mental wellness among its residents.',
      'imageUrl': 'https://images.unsplash.com/photo-1527137341206-193427974360?auto=format&fit=crop&w=800&q=80',
      'url': 'https://www2.naga.gov.ph/mental-health-awareness-month-observed-in-naga-city/',
      'category': 'Mental Health',
      'isNew': false,
    },
  ];

  void loadAlerts({String category = 'All'}) {
    emit(HealthAlertsLoading());
    try {
      final filtered = category == 'All' 
          ? _allAlerts 
          : _allAlerts.where((a) => a['category'] == category).toList();
      emit(HealthAlertsLoaded(filtered, category));
    } catch (e) {
      emit(HealthAlertsError(e.toString()));
    }
  }
}
