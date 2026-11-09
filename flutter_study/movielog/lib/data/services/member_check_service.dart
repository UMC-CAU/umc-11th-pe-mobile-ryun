import 'sign_up_service.dart';
export 'sign_up_service.dart' show MemberAvailabilityService;

// Compatibility for the earlier study's capture harness.
class MemberCheckService extends SignUpService {
  MemberCheckService(super.dio);
}
