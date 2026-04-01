import 'package:mockito/annotations.dart';
import 'package:plutus_fe_prototype/services/interfaces/interfaces.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_report_ai_service.dart';
import 'package:plutus_fe_prototype/services/interfaces/i_report_pdf_service.dart';

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
  IAIService,
  IAICategoryPipeline,
  IReportAiService,
  IReportPdfService,
])
void main() {}
