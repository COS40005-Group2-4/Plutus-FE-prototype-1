import 'package:mockito/annotations.dart';
import 'package:plutus_fe_prototype/services/interfaces/interfaces.dart';

@GenerateMocks([
  IDatabaseService,
  IBackendFfiService,
  ITransactionService,
  IBackupService,
  IBillService,
  IInvestmentService,
  IUserService,
  IProfileService,
  ISettingsService,
  IGoogleAuthService,
  IPriceApiService,
  ISyncManager,
  IBudgetService,
])
void main() {}
